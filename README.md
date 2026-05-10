# 🍽️ Delicious - Complete Food & Drink E-commerce Platform

A full-stack food delivery application serving Algeria, featuring Flutter mobile app, Node.js backend API, and Next.js payment processing.

## 📦 Project Structure

```
FOOD DELEVERY APPLICATION/
├── delicious-app/              # Flutter Mobile App
├── delicious-backend-prod/     # Main API Backend (Express)
├── delicious-payment-backend/  # Payment Backend (Next.js)
└── README.md                   # This file
```

## 🎯 System Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         DELICIOUS PLATFORM                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  📱 Flutter App                    🌐 Main API (Express)                   │
│  ├── Login/Register               ├── Products & Categories                │
│  ├── Product Carousel             ├── Authentication (JWT)                 │
│  ├── Shopping Cart                ├── Cart Management                      │
│  └── Order Tracking               └── Order Processing                     │
│                                                                             │
│  💳 Payment Backend (Next.js)     🗄️ MongoDB Atlas                        │
│  ├── Create Session               ├── Users Collection                     │
│  ├── Webhook Handler              ├── Products Collection                  │
│  ├── Success/Failure Pages        ├── Orders Collection                    │
│  └── Chargily Integration         └── Payment Sessions                     │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 🚀 Live URLs

| Service | URL |
|---------|-----|
| **Main API** | https://delicious-backend-prod.vercel.app |
| **Payment API** | https://delicious-payment-backend.vercel.app |
| **Success Page** | https://delicious-payment-backend.vercel.app/payment/success |
| **Failure Page** | https://delicious-payment-backend.vercel.app/payment/failure |

## 📡 API Endpoints

### Main API (https://delicious-backend-prod.vercel.app)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/health` | Health check |
| GET | `/api/products` | All products |
| GET | `/api/products?category=Sodas` | Filter by category |
| GET | `/api/products?mood=cold` | Filter by mood |
| GET | `/api/categories` | All categories |
| POST | `/api/auth/register` | Register user |
| POST | `/api/auth/login` | Login user |
| GET | `/api/cart?userId={id}` | Get cart |
| POST | `/api/cart?userId={id}` | Add to cart |
| POST | `/api/orders` | Create order |
| GET | `/api/orders?userId={id}` | User orders |

### Payment API (https://delicious-payment-backend.vercel.app)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/payment/create-session` | Create payment |
| POST | `/api/payment/webhook` | Payment webhook |
| GET | `/api/payment/verify?sessionId={id}` | Verify payment |

## 🧪 Test Payment Cards

| Payment Method | Card Number | Expiry | CVV |
|----------------|-------------|--------|-----|
| EDAHABIA (Test) | `4444 4444 4444 4444` | Any future | Any |
| CIB (Test) | `5555 5555 5555 5555` | Any future | Any |

## 🛠️ Technology Stack

| Component | Technology |
|-----------|------------|
| **Mobile App** | Flutter 3.x, BLoC, GoRouter |
| **Main API** | Node.js, Express, MongoDB |
| **Payment API** | Next.js 14, TypeScript |
| **Database** | MongoDB Atlas |
| **Payment Gateway** | Chargily (EDAHABIA/CIB) |
| **Authentication** | JWT, Biometric, Face Recognition |
| **Storage** | Hive (local), Cloudinary (images) |
| **Deployment** | Vercel |

## 🏠 Local Development Setup

### Prerequisites

- Flutter SDK 3.x
- Node.js 18+
- MongoDB Atlas account
- Chargily account

### Step 1: Clone the Repository

```bash
git clone https://github.com/romaissaTala/DELICIOUS---FOOD-DRINK.git
cd "FOOD DELEVERY APPLICATION"
```

### Step 2: Setup Main Backend

```bash
cd delicious-backend-prod
npm install
cp .env.example .env
# Edit .env with your credentials
npm run dev
# Runs on http://localhost:5000
```

### Step 3: Setup Payment Backend

```bash
cd ../delicious-payment-backend
npm install
cp .env.example .env.local
# Edit .env.local with your credentials
npm run dev
# Runs on http://localhost:3000
```

### Step 4: Setup Flutter App

```bash
cd ../delicious-app
flutter pub get
flutter run
```

### Step 5: ADB Reverse (for Android Emulator)

```bash
adb reverse tcp:5000 tcp:5000
adb reverse tcp:3000 tcp:3000
```

## 📱 Flutter App Setup

Update API URLs in `lib/core/di/injection.dart`:

```dart
// Production
const String _baseUrl = 'https://delicious-backend-prod.vercel.app/api';

// Local Development
// const String _baseUrl = 'http://localhost:5000/api';
```

## 🚀 Deployment

### Deploy Main Backend

```bash
cd delicious-backend-prod
vercel --prod
```

### Deploy Payment Backend

```bash
cd delicious-payment-backend
vercel --prod
```

### Build Flutter App

```bash
cd delicious-app
flutter build apk --release
```

## 🔐 Environment Variables

### Main Backend (.env)

```env
MONGODB_URI=mongodb+srv://...
JWT_SECRET=your_jwt_secret
ADMIN_EMAIL=admin@example.com
ADMIN_PASSWORD=secure_password
CHARGILY_API_KEY=test_sk_...
CHARGILY_MODE=test
```

### Payment Backend (.env.local)

```env
CHARGILY_API_KEY=test_sk_...
CHARGILY_MODE=test
MONGODB_URI=mongodb+srv://...
```

## 📊 Database Collections

| Collection | Purpose |
|------------|---------|
| `users` | User accounts and authentication |
| `products` | Product catalog with gradient colors |
| `categories` | Product categories |
| `carts` | Shopping cart data |
| `orders` | Order history and tracking |
| `payment_sessions` | Payment session tracking |

## 👥 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## 📝 License

MIT License - see LICENSE file for details

## 👤 Author

**Romaissa Tala**
- GitHub: [@romaissaTala](https://github.com/romaissaTala)
- Email: talaromaissa@gmail.com

## 🙏 Acknowledgments

- Chargily for Algerian payment integration
- MongoDB Atlas for database hosting
- Vercel for hosting deployment

---

## 🎯 Quick Links

- [Main API Health](https://delicious-backend-prod.vercel.app/api/health)
- [Products API](https://delicious-backend-prod.vercel.app/api/products)
- [Categories API](https://delicious-backend-prod.vercel.app/api/categories)
- [Payment Success Page](https://delicious-payment-backend.vercel.app/payment/success?orderId=test)
- [Payment Failure Page](https://delicious-payment-backend.vercel.app/payment/failure?orderId=test)
