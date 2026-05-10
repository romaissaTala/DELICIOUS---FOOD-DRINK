import type { NextApiRequest, NextApiResponse } from 'next';
import { MongoClient } from 'mongodb';

// Chargily API configuration
const CHARGILY_API_KEY = process.env.CHARGILY_API_KEY;
const CHARGILY_MODE = process.env.CHARGILY_MODE || 'test';

// Chargily API endpoint
const CHARGILY_API_URL = CHARGILY_MODE === 'test' 
  ? 'https://pay.chargily.net/test/api/v2'
  : 'https://pay.chargily.net/api/v2';

// Database connection cache
let cachedDb: MongoClient | null = null;

async function connectToDatabase(): Promise<MongoClient> {
  if (cachedDb) return cachedDb;
  
  const client = await MongoClient.connect(process.env.MONGODB_URI as string);
  cachedDb = client;
  return client;
}

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  // Only allow POST requests
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { orderId, amount, customerEmail, customerName, orderNumber } = req.body;

    // Validate required fields
    if (!orderId || !amount || !customerEmail) {
      return res.status(400).json({ 
        success: false, 
        error: 'Missing required fields' 
      });
    }

    // Get base URL (Vercel provides this automatically)
    const baseUrl = process.env.VERCEL_URL 
      ? `https://${process.env.VERCEL_URL}`
      : 'http://localhost:3000';

    // Prepare checkout data for Chargily API
    const checkoutData = {
      amount: amount,
      currency: 'dzd',
      success_url: `${baseUrl}/payment/success?orderId=${orderId}`,
      failure_url: `${baseUrl}/payment/failure?orderId=${orderId}`,
      webhook_endpoint: `${baseUrl}/api/payment/webhook`,
      description: `Order #${orderNumber}`,
      locale: 'en',
      metadata: {
        order_id: orderId,
        order_number: orderNumber,
        customer_email: customerEmail,
      },
    };

    // Make request to Chargily API
    const response = await fetch(`${CHARGILY_API_URL}/checkouts`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${CHARGILY_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(checkoutData),
    });

    const responseData = await response.json();

    if (!response.ok) {
      throw new Error(responseData.message || 'Failed to create checkout');
    }

    // Save payment session to database
    const db = await connectToDatabase();
    const database = db.db('delicious_app');
    
    await database.collection('payment_sessions').insertOne({
      sessionId: responseData.id,
      orderId: orderId,
      orderNumber: orderNumber,
      amount: amount,
      status: 'pending',
      createdAt: new Date(),
      checkoutUrl: responseData.checkout_url,
    });

    // Return checkout URL to Flutter app
    return res.status(200).json({
      success: true,
      checkout_url: responseData.checkout_url,
      checkout_id: responseData.id,
    });

  } catch (error) {
    console.error('Chargily API Error:', error);
    return res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : 'Payment creation failed'
    });
  }
}