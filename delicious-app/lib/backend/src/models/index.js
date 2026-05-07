// src/models/index.js
// Single import point for all models + DB connection helper.
//
// Usage:
//   const { connectDB, User, Product } = require('./models');
//   await connectDB();

const mongoose = require('mongoose');

const User          = require('./User');
const Category      = require('./Category');
const Product       = require('./Product');
const Cart          = require('./Cart');
const Order         = require('./Order');
const PaymentMethod = require('./PaymentMethod');

// ── MongoDB Atlas connection ──────────────────────────────────────────────────

const connectDB = async () => {
  const uri = process.env.MONGODB_URI;
  if (!uri) throw new Error('MONGODB_URI is not set in .env');

  await mongoose.connect(uri, {
    dbName: 'delicious',
  });
  console.log(`✅ MongoDB connected: ${mongoose.connection.host}`);
};

// ── Optional: seed all collections ───────────────────────────────────────────

const seedAll = async () => {
  await Category.seed();
  await PaymentMethod.seed();
};

module.exports = { connectDB, seedAll, User, Category, Product, Cart, Order, PaymentMethod };