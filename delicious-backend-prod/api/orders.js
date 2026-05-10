import { connectToDatabase } from '../lib/db.js';
import Order from '../models/Order.js';
import Cart from '../models/Cart.js';

export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') return res.status(200).end();

  await connectToDatabase();

  try {
    // GET orders by userId
    if (req.method === 'GET') {
      const { userId } = req.query;
      
      if (!userId) {
        return res.status(400).json({ success: false, message: 'userId is required' });
      }
      
      const orders = await Order.find({ userId }).sort({ createdAt: -1 });
      
      return res.status(200).json({ success: true, data: orders });
    }

    // POST create order
    if (req.method === 'POST') {
      const orderData = req.body;
      
      const order = new Order(orderData);
      await order.save();
      
      // Clear cart after order
      if (orderData.userId) {
        await Cart.findOneAndUpdate(
          { userId: orderData.userId },
          { items: [], updatedAt: new Date() }
        );
      }
      
      return res.status(200).json({ success: true, data: order });
    }

    return res.status(405).json({ success: false, message: 'Method not allowed' });
    
  } catch (error) {
    console.error('Orders error:', error);
    return res.status(500).json({ success: false, message: error.message });
  }
}