const express = require('express');
const { ChargilyClient } = require('@chargily/chargily-pay');
require('dotenv').config();

const router = express.Router();

// Use the official Chargily Client [citation:4]
const chargilyClient = new ChargilyClient({
  api_key: process.env.CHARGILY_API_KEY,
  mode: process.env.CHARGILY_MODE, // 'test' or 'live'
});

// 1. Endpoint to create a payment session
router.post('/create-checkout', async (req, res) => {
  try {
    const { orderId, amount, customerName, customerEmail } = req.body;

    // Prepare the checkout data for Chargily API
    const checkoutData = {
      amount: amount,
      currency: 'dzd', // Algerian Dinar [citation:5]
      success_url: 'https://yourapp.com/payment/success',
      failure_url: 'https://yourapp.com/payment/failure',
      webhook_endpoint: 'https://your-backend.com/api/payment-webhook', // VERY IMPORTANT!
      description: `Order #${orderId} - ${customerName}`,
      locale: 'en', // or 'ar' for Arabic, 'fr' for French
    };
    
    // POST request to Chargily's API
    const response = await chargilyClient.checkouts.create(checkoutData);
    
    // Send the checkout URL back to your Flutter app
    res.json({
      success: true,
      checkout_url: response.checkout_url,
      checkout_id: response.id
    });

  } catch (error) {
    console.error('Chargily API Error:', error);
    res.status(500).json({ success: false, error: 'Payment creation failed' });
  }
});

// 2. VERY IMPORTANT: Webhook to listen for payment confirmation
router.post('/payment-webhook', async (req, res) => {
  const event = req.body;
  
  // Check if the payment was successful
  if (event.entity === 'invoice' && event.status === 'paid') {
    const orderId = event.metadata.order_id;
    const transactionId = event.id;
    
    // Update your Order in the `delicious_app` DB to 'paid'
    console.log(`✅ Payment confirmed for Order: ${orderId}`);
    // Here you would update your Order collection in MongoDB
  }
  
  res.status(200).send('OK');
});

module.exports = router;