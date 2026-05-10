import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { connectToDatabase, seedDatabase } from '../lib/db.js';

// Import models
import User from '../models/User.js';
import Product from '../models/Product.js';
import Category from '../models/Category.js';
import Cart from '../models/Cart.js';
import Order from '../models/Order.js';
import PaymentMethod from '../models/PaymentMethod.js';

// Import route handlers
import productsHandler from './products.js';
import categoriesHandler from './Category.js';
import cartHandler from './cart.js';
import ordersHandler from './orders.js';
import loginHandler from './auth/login.js';
import registerHandler from './auth/register.js';
import createSessionHandler from './payment/create-session.js';
import webhookHandler from './payment/webhook.js';

dotenv.config();

const app = express();

// Middleware
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
app.use(express.json({ limit: '10mb' }));

// Database initialization flag
let isDatabaseInitialized = false;

// Initialize database once
async function initializeDatabase() {
  if (isDatabaseInitialized) return;
  
  await connectToDatabase();
  await seedDatabase();
  isDatabaseInitialized = true;
}

// ============================================
// HEALTH CHECK ENDPOINT
// ============================================
app.get('/api/health', async (req, res) => {
  res.json({ 
    status: 'OK', 
    message: 'Delicious Backend is running',
    database: isDatabaseInitialized ? 'connected' : 'connecting'
  });
});

// ============================================
// WRAPPER FUNCTIONS TO CONVERT VERCEL HANDLERS TO EXPRESS
// ============================================

function wrapHandler(handler) {
  return async (req, res) => {
    await initializeDatabase();
    
    // Create a mock Next.js req/res wrapper
    const mockReq = {
      method: req.method,
      query: req.query,
      body: req.body,
      headers: req.headers,
    };
    
    const mockRes = {
      status: (code) => {
        res.statusCode = code;
        return {
          json: (data) => res.json(data),
          send: (data) => res.send(data),
          end: () => res.end(),
        };
      },
      json: (data) => res.json(data),
      send: (data) => res.send(data),
      setHeader: (key, value) => res.setHeader(key, value),
    };
    
    return handler(mockReq, mockRes);
  };
}

// ============================================
// REGISTER ROUTES
// ============================================

// Public routes
app.get('/api/products', wrapHandler(productsHandler));
app.get('/api/categories', wrapHandler(categoriesHandler));

// Auth routes
app.post('/api/auth/register', wrapHandler(registerHandler));
app.post('/api/auth/login', wrapHandler(loginHandler));

// Cart routes
app.get('/api/cart', wrapHandler(cartHandler));
app.post('/api/cart', wrapHandler(cartHandler));
app.put('/api/cart', wrapHandler(cartHandler));
app.delete('/api/cart', wrapHandler(cartHandler));

// Orders routes
app.get('/api/orders', wrapHandler(ordersHandler));
app.post('/api/orders', wrapHandler(ordersHandler));

// Payment routes
app.post('/api/payment/create-session', wrapHandler(createSessionHandler));
app.post('/api/payment/webhook', wrapHandler(webhookHandler));

// ============================================
// FALLBACK ROUTE
// ============================================
app.use('*', (req, res) => {
  res.status(404).json({ 
    success: false, 
    message: `Route ${req.method} ${req.url} not found` 
  });
});

// ============================================
// START SERVER
// ============================================
const PORT = process.env.PORT || 5000;

app.listen(PORT, '0.0.0.0', async () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📍 Local: http://localhost:${PORT}`);
  console.log(`📍 Network: http://0.0.0.0:${PORT}`);
  
  // Initialize database on startup
  try {
    await initializeDatabase();
    console.log('✅ Database initialized');
  } catch (error) {
    console.error('❌ Database initialization error:', error.message);
  }
});

export default app;