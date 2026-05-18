import { connectToDatabase } from '../../../lib/db.js';
import User from '../../../models/User.js';

export default async function handler(req, res) {
  // Enable CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ success: false, message: 'Method not allowed' });
  }

  try {
    
    
    const decoded = verifyToken(req);
    if (!decoded) {
      return res.status(401).json({ success: false, message: 'Unauthorized' });
    }
    
    // Get the user ID from the JWT token (set by your auth middleware)
    const userId = req.user?.userId;
    
    if (!userId) {
      return res.status(401).json({ success: false, message: 'Unauthorized' });
    }

    const { faceVector } = req.body;

    if (!faceVector || !Array.isArray(faceVector) || faceVector.length !== 128) {
      return res.status(400).json({ 
        success: false, 
        message: 'Invalid face vector. Must be an array of 128 numbers.' 
      });
    }

    await connectToDatabase();

    // Update user with face vector
    const user = await User.findByIdAndUpdate(
      userId,
      { 
        faceVector: faceVector,
        hasFaceAuth: true 
      },
      { new: true }
    );

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    return res.status(200).json({ 
      success: true, 
      message: 'Face vector saved successfully' 
    });

  } catch (error) {
    console.error('Face save error:', error);
    return res.status(500).json({ success: false, message: error.message });
  }
}