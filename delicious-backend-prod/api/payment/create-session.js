import { connectToDatabase, getDb } from '../../lib/db.js';

const CHARGILY_API_KEY = process.env.CHARGILY_API_KEY;
const CHARGILY_MODE = process.env.CHARGILY_MODE || 'test';
const CHARGILY_API_URL = CHARGILY_MODE === 'test' 
  ? 'https://pay.chargily.net/test/api/v2'
  : 'https://pay.chargily.net/api/v2';

export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { orderId, amount, customerEmail, customerName, orderNumber } = req.body;

    if (!orderId || !amount || !customerEmail) {
      return res.status(400).json({ success: false, error: 'Missing required fields' });
    }

    const baseUrl = process.env.VERCEL_URL 
      ? `https://${process.env.VERCEL_URL}`
      : 'http://localhost:3000';

    const checkoutData = {
      amount: amount,
      currency: 'dzd',
      success_url: `${baseUrl}/api/payment/success?orderId=${orderId}`,
      failure_url: `${baseUrl}/api/payment/failure?orderId=${orderId}`,
      webhook_endpoint: `${baseUrl}/api/payment/webhook`,
      description: `Order #${orderNumber}`,
      locale: 'en',
      metadata: {
        order_id: orderId,
        order_number: orderNumber,
        customer_email: customerEmail,
      },
    };

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

    await connectToDatabase();
    const db = await getDb();
    
    await db.collection('payment_sessions').insertOne({
      sessionId: responseData.id,
      orderId: orderId,
      orderNumber: orderNumber,
      amount: amount,
      status: 'pending',
      createdAt: new Date(),
      checkoutUrl: responseData.checkout_url,
    });

    return res.status(200).json({
      success: true,
      checkout_url: responseData.checkout_url,
      checkout_id: responseData.id,
    });

  } catch (error) {
    console.error('Chargily API Error:', error);
    return res.status(500).json({
      success: false,
      error: error.message || 'Payment creation failed'
    });
  }
}