import { connectToDatabase } from '../../lib/db.js';
import User from '../../models/User.js';
import jwt from 'jsonwebtoken';

export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') {
    return res.status(405).json({ success: false, message: 'Method not allowed' });
  }

  try {
    await connectToDatabase();
    
    const { email, password, name, phone } = req.body;
    
    if (!email || !password) {
      return res.status(400).json({ success: false, message: 'Email and password required' });
    }
    
    const existingUser = await User.findOne({ email });
    
    if (existingUser) {
      return res.status(400).json({ success: false, message: 'Email already exists' });
    }
    
    // ✅ FIX: Don't hash here! Let the model's pre('save') middleware handle it
    const user = new User({
      email,
      passwordHash: password,  // ← Pass plain password, model will hash it
      name,
      phone,
      isGuest: false
    });
    
    await user.save();  // ← pre('save') middleware will hash it once
    
    const token = jwt.sign(
      { userId: user._id, email: user.email, role: user.role },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '7d' }
    );
    
    return res.status(200).json({
      success: true,
      data: {
        accessToken: token,
        refreshToken: token,
        user: {
          id: user._id,
          email: user.email,
          name: user.name,
          phone: user.phone,
          isGuest: user.isGuest,
          hasFaceAuth: user.hasFaceAuth,
          role: user.role
        }
      }
    });
    
  } catch (error) {
    console.error('Register error:', error);
    return res.status(500).json({ success: false, message: error.message });
  }
}