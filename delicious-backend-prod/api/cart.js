import { connectToDatabase } from '../lib/db.js';
import Cart from '../models/Cart.js';

export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') return res.status(200).end();

  await connectToDatabase();

  try {
    const { userId } = req.query;
    
    if (!userId) {
      return res.status(400).json({ success: false, message: 'userId is required' });
    }

    // GET cart
    if (req.method === 'GET') {
      let cart = await Cart.findOne({ userId });
      
      if (!cart) {
        cart = new Cart({ userId, items: [] });
        await cart.save();
      }
      
      return res.status(200).json({ success: true, data: cart });
    }

    // POST add to cart
    if (req.method === 'POST') {
      const { productId, quantity, productName, productImageUrl, unitPrice } = req.body;
      
      let cart = await Cart.findOne({ userId });
      
      if (!cart) {
        cart = new Cart({ userId, items: [] });
      }
      
      cart.upsertItem({
        productId,
        productName,
        productImageUrl,
        unitPrice,
        quantity
      });
      
      await cart.save();
      
      return res.status(200).json({ success: true, data: cart });
    }

    // PUT update quantity
    if (req.method === 'PUT') {
      const { cartItemId, quantity } = req.body;
      
      let cart = await Cart.findOne({ userId });
      
      if (!cart) {
        return res.status(404).json({ success: false, message: 'Cart not found' });
      }
      
      cart.updateQuantity(cartItemId, quantity);
      await cart.save();
      
      return res.status(200).json({ success: true, data: cart });
    }

    // DELETE remove item
    if (req.method === 'DELETE') {
      const { cartItemId } = req.body;
      
      let cart = await Cart.findOne({ userId });
      
      if (!cart) {
        return res.status(404).json({ success: false, message: 'Cart not found' });
      }
      
      cart.removeItem(cartItemId);
      await cart.save();
      
      return res.status(200).json({ success: true, data: cart });
    }

    return res.status(405).json({ success: false, message: 'Method not allowed' });
    
  } catch (error) {
    console.error('Cart error:', error);
    return res.status(500).json({ success: false, message: error.message });
  }
}