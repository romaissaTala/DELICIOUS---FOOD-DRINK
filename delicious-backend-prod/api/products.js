import { connectToDatabase } from '../lib/db.js';
import Product from '../models/Product.js';
import Category from '../models/Category.js';

export default async function handler(req, res) {
  // Enable CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'GET') {
    return res.status(405).json({ success: false, message: 'Method not allowed' });
  }

  try {
    await connectToDatabase();
    
    const { category, mood } = req.query;
    let query = { isAvailable: true };
    
    if (category) {
      const categoryDoc = await Category.findOne({ name: category });
      if (categoryDoc) query.categoryId = categoryDoc._id;
    }
    
    if (mood) {
      query.mood = mood;
    }
    
    const products = await Product.find(query).populate('categoryId');
    
    return res.status(200).json({ success: true, data: products });
    
  } catch (error) {
    console.error('Products error:', error);
    return res.status(500).json({ success: false, message: error.message });
  }
}