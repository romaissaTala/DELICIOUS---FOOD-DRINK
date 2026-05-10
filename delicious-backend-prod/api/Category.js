import { connectToDatabase } from '../lib/db.js';
import Category from '../models/Category.js';

export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'GET') {
    return res.status(405).json({ success: false, message: 'Method not allowed' });
  }

  try {
    await connectToDatabase();
    
    const categories = await Category.find({ isActive: true }).sort('sortOrder');
    
    return res.status(200).json({ success: true, data: categories });
    
  } catch (error) {
    console.error('Categories error:', error);
    return res.status(500).json({ success: false, message: error.message });
  }
}