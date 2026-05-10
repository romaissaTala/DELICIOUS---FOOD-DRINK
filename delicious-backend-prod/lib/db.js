import mongoose from 'mongoose';
import Category from '../models/Category.js';
import PaymentMethod from '../models/PaymentMethod.js';
import Product from '../models/Product.js';
import User from '../models/User.js';

let cachedConnection = null;
let isSeeded = false;

/**
 * Connect to MongoDB Atlas
 */
export async function connectToDatabase() {
  if (cachedConnection) {
    return cachedConnection;
  }

  const MONGODB_URI = process.env.MONGODB_URI;
  
  if (!MONGODB_URI) {
    throw new Error('MONGODB_URI is not defined in environment variables');
  }

  console.log('📡 Connecting to MongoDB...');
  
  const connection = await mongoose.connect(MONGODB_URI, {
    dbName: 'delicious_app',
    serverSelectionTimeoutMS: 5000,
    socketTimeoutMS: 10000,
    maxPoolSize: 10,
  });

  cachedConnection = connection;
  console.log('✅ MongoDB connected');
  
  return connection;
}

/**
 * Seed database with initial data (runs only once)
 */
export async function seedDatabase() {
  if (isSeeded) return;
  
  try {
    console.log('🌱 Checking database seeding...');
    
    // Seed Categories
    const categoryCount = await Category.countDocuments();
    if (categoryCount === 0) {
      await Category.seed();
      console.log('✅ Categories seeded');
    } else {
      console.log('✅ Categories already exist');
    }
    
    // Seed Payment Methods
    const paymentCount = await PaymentMethod.countDocuments();
    if (paymentCount === 0) {
      await PaymentMethod.seed();
      console.log('✅ Payment methods seeded');
    } else {
      console.log('✅ Payment methods already exist');
    }
    
    // Seed Products (only if no products exist)
    const productCount = await Product.countDocuments();
    if (productCount === 0) {
      await seedProducts();
      console.log('✅ Products seeded');
    } else {
      console.log('✅ Products already exist');
    }
    
    // Create admin user
    const adminExists = await User.findOne({ email: process.env.ADMIN_EMAIL });
    if (!adminExists && process.env.ADMIN_EMAIL) {
      const bcrypt = await import('bcryptjs');
      const hashedPassword = await bcrypt.hash(process.env.ADMIN_PASSWORD, 10);
      await User.create({
        email: process.env.ADMIN_EMAIL,
        passwordHash: hashedPassword,
        name: "Admin",
        role: "admin",
        isGuest: false
      });
      console.log('✅ Admin user created');
    }
    
    isSeeded = true;
    console.log('🎉 Database seeding completed!');
    
  } catch (error) {
    console.error('❌ Seeding error:', error);
  }
}

/**
 * Seed products
 */
async function seedProducts() {
  const fastFoodCat = await Category.findOne({ name: 'Fast Food' });
  const sodasCat = await Category.findOne({ name: 'Sodas' });
  const juicesCat = await Category.findOne({ name: 'Natural Juices' });
  const coffeeCat = await Category.findOne({ name: 'Coffee' });
  const sweetsCat = await Category.findOne({ name: 'Sweets' });
  
  const products = [
    {
      name: "Coca-Cola Classic",
      description: "Refreshing carbonated beverage with iconic taste",
      price: 150,
      categoryId: sodasCat?._id,
      brand: "Coca-Cola",
      gradientColors: ["#CC0000", "#FF4444"],
      mood: ["cold", "sweet", "energising"],
      imageUrl: "https://res.cloudinary.com/dhz6eftau/image/upload/products/coca-cola",
      isAvailable: true,
      stock: 100,
      preparationTimeMin: 2
    },
    {
      name: "Pepsi",
      description: "Crisp, refreshing cola",
      price: 150,
      categoryId: sodasCat?._id,
      brand: "Pepsi",
      gradientColors: ["#004B93", "#0070CC"],
      mood: ["cold", "sweet"],
      imageUrl: "https://res.cloudinary.com/dhz6eftau/image/upload/products/pepsi",
      isAvailable: true,
      stock: 100,
      preparationTimeMin: 2
    },
    {
      name: "Fresh Orange Juice",
      description: "100% natural squeezed orange juice",
      price: 250,
      categoryId: juicesCat?._id,
      brand: "Fresh Daily",
      gradientColors: ["#FF6B00", "#FFA500"],
      mood: ["cold", "fresh", "energising"],
      imageUrl: "https://res.cloudinary.com/dhz6eftau/image/upload/products/orange-juice",
      isAvailable: true,
      stock: 50,
      preparationTimeMin: 5
    },
    {
      name: "Espresso",
      description: "Strong Italian coffee",
      price: 180,
      categoryId: coffeeCat?._id,
      brand: "Lavazza",
      gradientColors: ["#3E2723", "#6D4C41"],
      mood: ["hot", "energising"],
      imageUrl: "https://res.cloudinary.com/dhz6eftau/image/upload/products/espresso",
      isAvailable: true,
      stock: 200,
      preparationTimeMin: 3
    },
    {
      name: "Chocolate Fudge Cake",
      description: "Rich chocolate layer cake",
      price: 450,
      categoryId: sweetsCat?._id,
      brand: "Patisserie Deluxe",
      gradientColors: ["#4E342E", "#795548"],
      mood: ["sweet", "comforting"],
      imageUrl: "https://res.cloudinary.com/dhz6eftau/image/upload/products/chocolate-cake",
      isAvailable: true,
      stock: 30,
      preparationTimeMin: 10
    },
    {
      name: "Traditional Couscous",
      description: "Semolina with vegetables and lamb",
      price: 1200,
      categoryId: fastFoodCat?._id,
      brand: "Mama's Kitchen",
      gradientColors: ["#D4A373", "#FAEDCD"],
      mood: ["hot", "comforting", "salty"],
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
}

/**
 * Get database instance
 */
export async function getDb() {
  const connection = await connectToDatabase();
  return connection.connection.db;
}