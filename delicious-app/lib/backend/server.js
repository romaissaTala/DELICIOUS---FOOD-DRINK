require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const app = express();

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' }));

// ============================================
// DATABASE CONNECTION
// ============================================
const DB_NAME = 'delicious_app';

const MONGODB_URI = process.env.MONGODB_URI ;

mongoose.connect(MONGODB_URI, {
  dbName: DB_NAME,
  serverSelectionTimeoutMS: 10000,
})
.then(() => console.log(`✅ Connected to database: ${mongoose.connection.name}`))
.catch(err => console.error('❌ MongoDB connection error:', err));

// ============================================
// MODELS (Import your existing models)
// ============================================
const User = require('./src/models/User');
const Product = require('./src/models/Product');
const Category = require('./src/models/Category');
const Cart = require('./src/models/Cart');
const Order = require('./src/models/Order');
const PaymentMethod = require('./src/models/PaymentMethod');

// ============================================
// SEED DATABASE FUNCTION
// ============================================
async function seedDatabase() {
  try {
    console.log('🌱 Starting database seeding...');
    
    // 1. Seed Categories
    await Category.seed();
    console.log('✅ Categories seeded');
    
    // 2. Seed Payment Methods
    await PaymentMethod.seed();
    console.log('✅ Payment methods seeded');
    
    // 3. Check if products exist
    const productCount = await Product.countDocuments();
    if (productCount === 0) {
      console.log('📦 Seeding products...');
      
      // Get category IDs
      const fastFoodCat = await Category.findOne({ name: 'Fast Food' });
      const sodasCat = await Category.findOne({ name: 'Sodas' });
      const juicesCat = await Category.findOne({ name: 'Natural Juices' });
      const coffeeCat = await Category.findOne({ name: 'Coffee' });
      const sweetsCat = await Category.findOne({ name: 'Sweets' });
      
      const products = [
  // Coca-Cola - FIXED
  {
    name: "Coca-Cola Classic",
    description: "Refreshing carbonated beverage with iconic taste",
    price: 150,
    categoryId: sodasCat?._id,
    brand: "Coca-Cola",
    gradientColors: ["#CC0000", "#FF4444"],  // ✅ Only 2 colors, not 3
    mood: ["cold", "sweet", "energising"],   // ✅ Removed "refreshing"
    imageUrl: "https://res.cloudinary.com/dhz6eftau/image/upload/products/coca-cola",
    isAvailable: true,
    stock: 100,
    preparationTimeMin: 2
  },
  // Pepsi - FIXED
  {
    name: "Pepsi",
    description: "Crisp, refreshing cola",
    price: 150,
    categoryId: sodasCat?._id,
    brand: "Pepsi",
    gradientColors: ["#004B93", "#0070CC"],  // ✅ Only 2 colors
    mood: ["cold", "sweet"],                 // ✅ Valid moods only
    imageUrl: "https://res.cloudinary.com/dhz6eftau/image/upload/products/pepsi",
    isAvailable: true,
    stock: 100,
    preparationTimeMin: 2
  },
  // Orange Juice - FIXED
  {
    name: "Fresh Orange Juice",
    description: "100% natural squeezed orange juice",
    price: 250,
    categoryId: juicesCat?._id,
    brand: "Fresh Daily",
    gradientColors: ["#FF6B00", "#FFA500"],  // ✅ Only 2 colors
    mood: ["cold", "fresh", "energising"],   // ✅ "fresh" is valid
    imageUrl: "https://res.cloudinary.com/dhz6eftau/image/upload/products/orange-juice",
    isAvailable: true,
    stock: 50,
    preparationTimeMin: 5
  },
  // Espresso - FIXED
  {
    name: "Espresso",
    description: "Strong Italian coffee",
    price: 180,
    categoryId: coffeeCat?._id,
    brand: "Lavazza",
    gradientColors: ["#3E2723", "#6D4C41"],  // ✅ Only 2 colors
    mood: ["hot", "energising"],             // ✅ Valid moods
    imageUrl: "https://res.cloudinary.com/dhz6eftau/image/upload/products/espresso",
    isAvailable: true,
    stock: 200,
    preparationTimeMin: 3
  },
  // Chocolate Cake - FIXED
  {
    name: "Chocolate Fudge Cake",
    description: "Rich chocolate layer cake",
    price: 450,
    categoryId: sweetsCat?._id,
    brand: "Patisserie Deluxe",
    gradientColors: ["#4E342E", "#795548"],  // ✅ Only 2 colors
    mood: ["sweet", "comforting"],           // ✅ Valid moods
    imageUrl: "https://res.cloudinary.com/dhz6eftau/image/upload/products/chocolate-cake",
    isAvailable: true,
    stock: 30,
    preparationTimeMin: 10
  },
  // Couscous - FIXED
  {
    name: "Traditional Couscous",
    description: "Semolina with vegetables and lamb",
    price: 1200,
    categoryId: fastFoodCat?._id,
    brand: "Mama's Kitchen",
    gradientColors: ["#D4A373", "#FAEDCD"],  // ✅ Only 2 colors
    mood: ["hot", "comforting", "salty"],    // ✅ Valid moods
    imageUrl: "https://res.cloudinary.com/dhz6eftau/image/upload/products/couscous",
    isAvailable: true,
    stock: 20,
    preparationTimeMin: 25
  }
];
      
      for (const product of products) {
        if (product.categoryId) {
          await Product.create(product);
        }
      }
      console.log(`✅ Seeded ${products.length} products`);
    }
    
    // 4. Create admin user if not exists
    const adminExists = await User.findOne({ email: process.env.ADMIN_EMAIL });
    if (!adminExists && process.env.ADMIN_EMAIL) {
      const hashedPassword = await bcrypt.hash(process.env.ADMIN_PASSWORD, 12);
      await User.create({
        email: process.env.ADMIN_EMAIL,
        passwordHash: hashedPassword,
        name: "Admin",
        role: "admin",
        isGuest: false
      });
      console.log('✅ Admin user created');
    }
    
    console.log('🎉 Database seeding completed!');
  } catch (error) {
    console.error('❌ Seeding error:', error);
  }
}

// Run seeding after connection
mongoose.connection.once('open', () => {
  seedDatabase();
});

// ============================================
// AUTH ROUTES
// ============================================

// Register
app.post('/api/auth/register', async (req, res) => {
  try {
    const { email, password, name, phone } = req.body;
    
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ success: false, message: 'Email already exists' });
    }
    
    const user = new User({ email, passwordHash: password, name, phone, isGuest: false });
    await user.save();
    
    const token = jwt.sign(
      { userId: user._id, email: user.email },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '7d' }
    );
    
    res.json({
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
    res.status(500).json({ success: false, message: error.message });
  }
});

// Login
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    const user = await User.findOne({ email }).select('+passwordHash');
    if (!user) {
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }
    
    const isValid = await user.comparePassword(password);
    if (!isValid) {
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }
    
    const token = jwt.sign(
      { userId: user._id, email: user.email },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '7d' }
    );
    
    res.json({
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
    res.status(500).json({ success: false, message: error.message });
  }
});

// Get products
app.get('/api/products', async (req, res) => {
  try {
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
    res.json({ success: true, data: products });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// Get cart
app.get('/api/cart/:userId', async (req, res) => {
  try {
    let cart = await Cart.findOne({ userId: req.params.userId });
    if (!cart) {
      cart = new Cart({ userId: req.params.userId, items: [] });
      await cart.save();
    }
    res.json({ success: true, data: cart });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// Add to cart
app.post('/api/cart/add', async (req, res) => {
  try {
    const { userId, productId, quantity, productName, productImageUrl, unitPrice } = req.body;
    
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
    res.json({ success: true, data: cart });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📊 Database: ${DB_NAME}`);
});