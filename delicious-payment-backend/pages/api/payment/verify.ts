import type { NextApiRequest, NextApiResponse } from 'next';
import { MongoClient, Db } from 'mongodb';

// Database connection cache with health check
let cachedDb: MongoClient | null = null;
let connectionPromise: Promise<MongoClient> | null = null;

async function connectToDatabase(): Promise<MongoClient> {
  // If we already have a connection, return it
  if (cachedDb) {
    try {
      await cachedDb.db().command({ ping: 1 });
      return cachedDb;
    } catch (err) {
      console.warn('Database connection lost, reconnecting...');
      cachedDb = null;
      connectionPromise = null;
    }
  }

  // Prevent multiple simultaneous connection attempts
  if (!connectionPromise) {
    const MONGODB_URI = process.env.MONGODB_URI;
    if (!MONGODB_URI) {
      throw new Error('MONGODB_URI environment variable is not defined');
    }

    connectionPromise = MongoClient.connect(MONGODB_URI, {
      maxPoolSize: 10,
      minPoolSize: 2,
      maxIdleTimeMS: 60000,
      serverSelectionTimeoutMS: 5000,
      socketTimeoutMS: 10000,
    });
  }

  try {
    cachedDb = await connectionPromise;
    return cachedDb;
  } finally {
    connectionPromise = null;
  }
}

// Ensure collection exists
async function ensureCollection(db: Db): Promise<void> {
  const collections = await db.listCollections({ name: 'payment_sessions' }).toArray();
  if (collections.length === 0) {
    await db.createCollection('payment_sessions');
    console.log('✅ Created payment_sessions collection');
  }
}

interface PaymentSession {
  sessionId: string;
  orderId: string;
  orderNumber: string;
  amount: number;
  status: string;
  transactionId?: string;
  createdAt: Date;
}

// Timeout helper
function withTimeout<T>(promise: Promise<T>, ms: number): Promise<T> {
  return Promise.race([
    promise,
    new Promise<T>((_, reject) => 
      setTimeout(() => reject(new Error(`Operation timed out after ${ms}ms`)), ms)
    )
  ]);
}

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  // Only allow GET requests
  if (req.method !== 'GET') {
    return res.status(405).json({ 
      success: false, 
      message: 'Method not allowed. Use GET.' 
    });
  }

  const { sessionId } = req.query;

  // Validate sessionId
  if (!sessionId || typeof sessionId !== 'string') {
    return res.status(400).json({ 
      success: false, 
      message: 'Session ID is required' 
    });
  }

  // Validate sessionId format (basic security)
  if (!sessionId.match(/^[a-zA-Z0-9_-]+$/)) {
    return res.status(400).json({ 
      success: false, 
      message: 'Invalid session ID format' 
    });
  }

  try {
    // Connect to database with timeout
    const client = await withTimeout(connectToDatabase(), 5000);
    const db = client.db('delicious_app');
    
    // Ensure collection exists
    await ensureCollection(db);
    
    // Query with timeout
    const session = await withTimeout(
      db.collection<PaymentSession>('payment_sessions').findOne({ sessionId }),
      5000
    );

    if (!session) {
      return res.status(404).json({ 
        success: false, 
        message: 'Payment session not found' 
      });
    }

    // Return success response
    return res.status(200).json({
      success: session.status === 'paid',
      transactionId: session.transactionId || null,
      orderId: session.orderId,
      status: session.status,
    });

  } catch (error) {
    console.error('Verification error:', error);
    
    // Determine appropriate error message based on error type
    let message = 'Payment verification failed';
    let statusCode = 500;
    
    if (error instanceof Error) {
      if (error.message.includes('timeout')) {
        message = 'Database operation timed out';
        statusCode = 504;
      } else if (error.message.includes('MONGODB_URI')) {
        message = 'Server configuration error';
        statusCode = 500;
      } else {
        message = error.message;
      }
    }
    
    return res.status(statusCode).json({ 
      success: false, 
      message 
    });
  }
}