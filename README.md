# Delicious - Food & Drink E-commerce App

## Project Structure

- delicious-app/ - Flutter mobile application
- delicious-backend/ - Next.js payment backend

## Setup Instructions

### Flutter App
\\\ash
cd delicious-app
flutter pub get
flutter run
\\\

### Backend
\\\ash
cd delicious-backend
npm install
npm run dev
\\\

## Environment Variables

Create .env.local in delicious-backend folder:

\\\env
CHARGILY_API_KEY=your_api_key
MONGODB_URI=your_mongodb_uri
\\\

## Deployed URLs

- Backend: https://delicious-payment-backend.vercel.app
- Success Page: /payment/success
- Failure Page: /payment/failure
