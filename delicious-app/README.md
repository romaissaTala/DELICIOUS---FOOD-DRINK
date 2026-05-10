# Delicious - Food & Drink E-commerce App

A modern Flutter e-commerce application for food and beverage delivery in Algeria.

## 🚀 Features

### Authentication
- ✅ Email/Password Login
- ✅ Guest Mode
- ✅ Biometric Authentication (Face ID/Fingerprint)
- ✅ Face Recognition with ML Kit

### Shopping
- ✅ Dynamic Gradient Product Carousel
- ✅ Category Filtering
- ✅ Mood-Based Ordering (hot, cold, sweet, etc.)
- ✅ Search with Voice Input
- ✅ Shopping Cart with Fly Animation

### Payments
- ✅ EDAHABIA (Algerie Poste)
- ✅ CIB (SATIM)
- ✅ CCP
- ✅ Cash on Delivery

### Orders
- ✅ Order History
- ✅ Real-time Delivery Tracking
- ✅ Order Status Timeline
- ✅ SMS/Email Notifications

### Profile
- ✅ Order History
- ✅ Saved Addresses
- ✅ Face Recognition Setup
- ✅ Payment Methods

## 🛠️ Tech Stack

- Flutter 3.x
- BLoC State Management
- GoRouter Navigation
- Hive Local Storage
- MongoDB Atlas
- Chargily Payment Gateway
- Google ML Kit (Face Recognition)

## 📱 Screens

1. **Login/Register** - Email, biometric, face recognition
2. **Home** - Product carousel, categories, search
3. **Product Detail** - Product info, quantity selector
4. **Cart** - Items, quantity adjustment, checkout
5. **Checkout** - Address, delivery options
6. **Payment** - Multiple payment methods
7. **Order Tracking** - Real-time status
8. **Profile** - User info, settings

## 🏠 Local Development

### Prerequisites

- Flutter SDK 3.x
- Android Studio / VS Code
- Android Emulator or Physical Device
- MongoDB Atlas account
- Chargily account

### Installation

```bash
# Clone the repository
git clone https://github.com/romaissaTala/DELICIOUS---FOOD-DRINK.git
cd delicious-app

# Get dependencies
flutter pub get

# Run the app
flutter run
```

### Configuration

Update API base URLs in `lib/core/di/injection.dart`:

```dart
// Production
const String _baseUrl = 'https://delicious-backend-prod.vercel.app/api';

// Local development with ADB reverse
// const String _baseUrl = 'http://localhost:5000/api';
```

## 🚀 Building for Production

### Android APK

```bash
flutter build apk --release
```

### Android App Bundle (Play Store)

```bash
flutter build appbundle --release
```

### iOS (requires Mac)

```bash
flutter build ios --release
```

## 📁 Project Structure

```
lib/
├── core/
│   ├── di/           # Dependency Injection
│   ├── router/       # GoRouter configuration
│   ├── theme/        # App Theme
│   └── network/      # API Client
├── features/
│   ├── auth/         # Authentication
│   ├── products/     # Products & Categories
│   ├── cart/         # Shopping Cart
│   ├── orders/       # Orders & Tracking
│   ├── payment/      # Payment Processing
│   ├── checkout/     # Checkout Flow
│   └── profile/      # User Profile
└── main.dart
```

## 🔗 Related Repositories

- [Main Backend API](https://github.com/romaissaTala/DELICIOUS---FOOD-DRINK/tree/main/delicious-backend-prod)
- [Payment Backend](https://github.com/romaissaTala/DELICIOUS---FOOD-DRINK/tree/main/delicious-payment-backend)

## 📝 License

MIT

## 👤 Author

Romaissa Tala - [GitHub](https://github.com/romaissaTala)
