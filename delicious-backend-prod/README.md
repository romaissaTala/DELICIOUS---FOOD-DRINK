# Delicious Backend API

Production-ready REST API for the Delicious Food & Drink E-commerce App.

## 🚀 Features

- ✅ User Authentication (JWT)
- ✅ Product Management
- ✅ Category Management
- ✅ Shopping Cart
- ✅ Order Processing
- ✅ Payment Integration (Chargily)
- ✅ MongoDB Database
- ✅ Deployed on Vercel

## 📋 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/health` | Health check |
| GET | `/api/products` | Get all products |
| GET | `/api/categories` | Get all categories |
| POST | `/api/auth/register` | Register new user |
| POST | `/api/auth/login` | User login |
| GET | `/api/cart?userId={id}` | Get user cart |
| POST | `/api/cart?userId={id}` | Add to cart |
| POST | `/api/orders` | Create order |
| POST | `/api/payment/create-session` | Create payment session |
| POST | `/api/payment/webhook` | Payment webhook |

## 🛠️ Tech Stack

- Node.js / Express.js
- MongoDB with Mongoose
- JWT Authentication
- Chargily Payment Gateway
- Deployed on Vercel

## 🏠 Local Development

### Prerequisites

- Node.js 18+
- MongoDB Atlas account
- Chargily account (for payments)

### Installation

```bash
# Clone the repository
git clone https://github.com/romaissaTala/DELICIOUS---FOOD-DRINK.git
cd delicious-backend-prod

# Install dependencies
npm install

# Create .env file
cp .env.example .env

# Add your environment variables
# Edit .env with your MongoDB URI, JWT secret, etc.

# Start development server
npm run dev
```

### Environment Variables

```env
MONGODB_URI=your_mongodb_connection_string
JWT_SECRET=your_jwt_secret_key
ADMIN_EMAIL=admin@example.com
ADMIN_PASSWORD=your_admin_password
CHARGILY_API_KEY=your_chargily_api_key
CHARGILY_MODE=test
```

## 🚀 Deployment

This API is deployed on Vercel:

```bash
vercel --prod
```

### Production URL

```
https://delicious-backend-prod.vercel.app
```

## 📊 Database Schema

### Users Collection
- `email` (unique)
- `passwordHash`
- `name`
- `phone`
- `role` (customer/admin)
- `isGuest`
- `faceVector` (for facial recognition)

### Products Collection
- `name`
- `description`
- `price`
- `discountPercent`
- `gradientColors` (for UI theming)
- `mood` (cold, hot, sweet, etc.)
- `imageUrl`
- `categoryId`

### Orders Collection
- `userId`
- `orderNumber` (auto-generated)
- `items`
- `total`
- `status`
- `payment`

## 🧪 Testing

```bash
# Test health endpoint
curl https://delicious-backend-prod.vercel.app/api/health

# Test products
curl https://delicious-backend-prod.vercel.app/api/products
```

## 📝 License

MIT

## 👤 Author

Romaissa Tala - [GitHub](https://github.com/romaissaTala)
