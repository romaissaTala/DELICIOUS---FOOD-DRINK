import { connectToDatabase } from '../../../lib/db.js';
import User from '../../../models/User.js';
import jwt from 'jsonwebtoken';

// Cosine similarity between two vectors
function cosineSimilarity(vectorA, vectorB) {
  if (vectorA.length !== vectorB.length) return 0;
  
  let dotProduct = 0;
  let magnitudeA = 0;
  let magnitudeB = 0;
  
  for (let i = 0; i < vectorA.length; i++) {
    dotProduct += vectorA[i] * vectorB[i];
    magnitudeA += vectorA[i] * vectorA[i];
    magnitudeB += vectorB[i] * vectorB[i];
  }
  
  magnitudeA = Math.sqrt(magnitudeA);
  magnitudeB = Math.sqrt(magnitudeB);
  
  if (magnitudeA === 0 || magnitudeB === 0) return 0;
  
  return dotProduct / (magnitudeA * magnitudeB);
}

export default async function handler(req, res) {
  // Enable CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ success: false, message: 'Method not allowed' });
  }

  try {
    const { faceVector, email } = req.body;

    if (!faceVector || !Array.isArray(faceVector) || faceVector.length !== 128) {
      return res.status(400).json({ 
        success: false, 
        message: 'Invalid face vector. Must be an array of 128 numbers.' 
      });
    }

    if (!email) {
      return res.status(400).json({ 
        success: false, 
        message: 'Email is required' 
      });
    }

    await connectToDatabase();

    // Find user by email and include faceVector
    const user = await User.findOne({ email }).select('+faceVector');

    if (!user) {
      return res.status(401).json({ success: false, message: 'User not found' });
    }

    if (!user.faceVector || user.faceVector.length !== 128) {
      return res.status(401).json({ 
        success: false, 
        message: 'Face authentication not set up for this account' 
      });
    }

    // Compare face vectors
    const similarity = cosineSimilarity(user.faceVector, faceVector);
    const MATCH_THRESHOLD = 0.92;

    if (similarity < MATCH_THRESHOLD) {
      return res.status(401).json({ 
        success: false, 
        message: 'Face not recognized. Please try again.' 
      });
    }

    // Generate JWT token
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
    console.error('Face login error:', error);
    return res.status(500).json({ success: false, message: error.message });
  }
}