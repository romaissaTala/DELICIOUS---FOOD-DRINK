# Delicious Payment Backend

Next.js payment processing backend for the Delicious Food & Drink E-commerce App.

## 🚀 Features

- ✅ Chargily Payment Integration (EDAHABIA / CIB)
- ✅ Payment Session Management
- ✅ Webhook Handling for Payment Confirmation
- ✅ Success/Failure Pages
- ✅ MongoDB Payment Sessions Storage
- ✅ Deployed on Vercel

## 📋 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/payment/create-session` | Create payment session |
| POST | `/api/payment/webhook` | Payment confirmation webhook |
| GET | `/api/payment/verify?sessionId={id}` | Verify payment status |

## 🌐 Frontend Pages

| Page | URL | Description |
|------|-----|-------------|
| Success | `/payment/success?orderId={id}` | Payment success page |
| Failure | `/payment/failure?orderId={id}` | Payment failure page |

## 🛠️ Tech Stack

- Next.js 14 (App Router)
- TypeScript
- MongoDB
- Chargily Payment API
- Tailwind CSS
- Deployed on Vercel

## 🏠 Local Development

### Prerequisites

- Node.js 18+
- MongoDB Atlas account
- Chargily account

### Installation

```bash
# Clone the repository
git clone https://github.com/romaissaTala/DELICIOUS---FOOD-DRINK.git
cd delicious-payment-backend

# Install dependencies
npm install

# Create .env.local file
cp .env.example .env.local

# Start development server
npm run dev
```

### Environment Variables

```env
CHARGILY_API_KEY=your_chargily_api_key
CHARGILY_MODE=test
MONGODB_URI=your_mongodb_connection_string
```

## 🚀 Deployment

```bash
vercel --prod
```

### Production URL

```
https://delicious-payment-backend.vercel.app
```

## 🔄 Payment Flow

1. User clicks "Pay Now" in Flutter app
2. Backend creates Chargily checkout session
3. User redirected to Chargily payment page
4. User pays with EDAHABIA or CIB card
5. Chargily sends webhook confirmation
6. Backend updates order status to "paid"
7. User redirected to success/failure page

## 🧪 Test Cards

| Card Type | Card Number | Expiry | CVV |
|-----------|-------------|--------|-----|
| EDAHABIA (Test) | `4444 4444 4444 4444` | Any future | Any |
| CIB (Test) | `5555 5555 5555 5555` | Any future | Any |

## 📝 License

MIT

## 👤 Author

Romaissa Tala - [GitHub](https://github.com/romaissaTala)
