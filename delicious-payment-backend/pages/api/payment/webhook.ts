import type { NextApiRequest, NextApiResponse } from 'next';
import { MongoClient, ObjectId } from 'mongodb';

// Database connection cache
let cachedDb: MongoClient | null = null;

async function connectToDatabase(): Promise<MongoClient> {
  if (cachedDb) return cachedDb;
  
  const client = await MongoClient.connect(process.env.MONGODB_URI as string);
  cachedDb = client;
  return client;
}

// Define webhook event types
interface WebhookEvent {
  entity: string;
  status: string;
  id: string;
  metadata: {
    order_id: string;
    order_number: string;
    customer_email: string;
  };
  amount: number;
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
    const event = req.body as WebhookEvent;

    // Verify this is a payment confirmation
    if (event.entity === 'invoice' && event.status === 'paid') {
      const orderId = event.metadata.order_id;
      const transactionId = event.id;
      
      const client = await connectToDatabase();
      const db = client.db('delicious_app');
      
      // Update order status in database
      await db.collection('orders').updateOne(
        { _id: new ObjectId(orderId) },
        {
          $set: {
            paymentStatus: 'paid',
            transactionId: transactionId,
            paidAt: new Date(),
            updatedAt: new Date(),
          },
        }
      );
      
      // Update payment session status
      await db.collection('payment_sessions').updateOne(
        { orderId: orderId },
        {
          $set: {
            status: 'paid',
            transactionId: transactionId,
            paidAt: new Date(),
          },
        }
      );
      
      console.log(`✅ Payment confirmed for Order: ${orderId}`);
    }
    
    // Always return 200 to acknowledge receipt
    return res.status(200).send('OK');
    
  } catch (error) {
    console.error('Webhook error:', error);
    return res.status(500).json({ error: 'Webhook processing failed' });
  }
}