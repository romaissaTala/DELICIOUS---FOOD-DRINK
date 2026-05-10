import { connectToDatabase, getDb } from '../../lib/db.js';
import { ObjectId } from 'mongodb';

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const event = req.body;

    if (event.entity === 'invoice' && event.status === 'paid') {
      const orderId = event.metadata.order_id;
      const transactionId = event.id;
      
      await connectToDatabase();
      const db = await getDb();
      
      // Update order status
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
      
      // Update payment session
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
    
    return res.status(200).send('OK');
    
  } catch (error) {
    console.error('Webhook error:', error);
    return res.status(500).json({ error: 'Webhook processing failed' });
  }
}