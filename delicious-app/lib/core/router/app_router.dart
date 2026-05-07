import 'package:Delicious_App/features/payment/presentation/pages/payment_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Import all your pages
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/auth_page.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/products/presentation/pages/home_page.dart';
import '../../features/products/presentation/pages/product_detail_page.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/orders/presentation/pages/orders_page.dart';
import '../../features/orders/presentation/pages/order_detail_page.dart';
import '../../features/orders/presentation/pages/delivery_tracking_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/face_setup_page.dart';
import '../../features/checkout/presentation/pages/checkout_page.dart';
import '../../features/checkout/presentation/pages/payment_page.dart';
import '../../features/checkout/presentation/pages/order_confirmation_page.dart';

// ============================================
// ROUTE NAMES
// ============================================
class RouteNames {
  static const auth = '/';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const productDetail = '/product/:id';
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const payment = '/payment';
  static const orderConfirmation = '/order-confirmation';
  static const orders = '/orders';
  static const orderDetail = '/orders/:id';
  static const deliveryTracking = '/delivery-tracking/:id';
  static const profile = '/profile';
  static const faceSetup = '/face-setup';
}

// ============================================
// REDIRECT LOGIC (Authentication-aware)
// ============================================
String _redirectLogic(BuildContext context, GoRouterState state) {
  // Get auth state from Bloc
  final authState = context.read<AuthBloc>().state;
  
  final isAuthenticated = authState is AuthAuthenticated;
  final isGuest = authState is AuthGuest;
  final isLoggedIn = isAuthenticated || isGuest;
  
  final isGoingToAuthPage = state.matchedLocation == RouteNames.auth ||
                            state.matchedLocation == RouteNames.login ||
                            state.matchedLocation == RouteNames.register;
  
  // If logged in and trying to go to auth page -> redirect to home
  if (isLoggedIn && isGoingToAuthPage) {
    return RouteNames.home;
  }
  
  // If not logged in and trying to go to protected page -> redirect to auth
  if (!isLoggedIn && !isGoingToAuthPage && state.matchedLocation != RouteNames.auth) {
    return RouteNames.auth;
  }
  
  // Otherwise, no redirect
  return '';
}

// ============================================
// MAIN ROUTER CONFIGURATION
// ============================================
final GoRouter appRouter = GoRouter(
  initialLocation: RouteNames.auth,
  debugLogDiagnostics: true,
  redirect: _redirectLogic,
  
  routes: [
    // ============================================
    // AUTH ROUTES
    // ============================================
    GoRoute(
      path: RouteNames.auth,
      name: 'auth',
      builder: (context, state) => const AuthPage(),
    ),
    
    GoRoute(
      path: RouteNames.login,
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    
    GoRoute(
      path: RouteNames.register,
      name: 'register',
      builder: (context, state) => const RegisterPage(),
    ),
    
    // ============================================
    // MAIN APP ROUTES (with ShellRoute)
    // ============================================
    ShellRoute(
      builder: (context, state, child) {
        return MainShell(child: child);
      },
      routes: [
        // Home
        GoRoute(
          path: RouteNames.home,
          name: 'home',
          builder: (context, state) => const HomePage(),
          routes: [
            GoRoute(
              path: 'product/:id',
              name: 'productDetail',
              builder: (context, state) {
                final productId = state.pathParameters['id']!;
                return ProductDetailPage(productId: productId);
              },
            ),
          ],
        ),
        
        // Cart
        GoRoute(
          path: RouteNames.cart,
          name: 'cart',
          builder: (context, state) => const CartPage(),
        ),
        
        // Orders
        GoRoute(
          path: RouteNames.orders,
          name: 'orders',
          builder: (context, state) => const OrdersPage(),
          routes: [
            GoRoute(
              path: ':id',
              name: 'orderDetail',
              builder: (context, state) {
                final orderId = state.pathParameters['id']!;
                return OrderDetailPage(orderId: orderId);
              },
            ),
            GoRoute(
              path: ':id/track',
              name: 'deliveryTracking',
              builder: (context, state) {
                final orderId = state.pathParameters['id']!;
                return DeliveryTrackingPage(orderId: orderId);
              },
            ),
          ],
        ),
        
        // Profile
        GoRoute(
          path: RouteNames.profile,
          name: 'profile',
          builder: (context, state) => const ProfilePage(),
          routes: [
            GoRoute(
              path: 'face-setup',
              name: 'faceSetup',
              builder: (context, state) => const FaceSetupPage(),
            ),
          ],
        ),
      ],
    ),
    
    // ============================================
    // CHECKOUT FLOW
    // ============================================
    GoRoute(
      path: RouteNames.checkout,
      name: 'checkout',
      builder: (context, state) => const CheckoutPage(),
      routes: [
        GoRoute(
          path: 'payment',
          name: 'payment',
          builder: (context, state) => const PaymentPage(),
          routes: [
            GoRoute(
              path: 'confirmation',
              name: 'orderConfirmation',
              builder: (context, state) {
                final extra = state.extra as Map<String, dynamic>?;
                return OrderConfirmationPage(
                  orderId: extra?['orderId'] as String? ?? '',
                  orderNumber: extra?['orderNumber'] as String? ?? '',
                );
              },
            ),
          ],
        ),
      ],
    ),
  ],
);

// ============================================
// SHELL WIDGET
// ============================================
class MainShell extends StatelessWidget {
  final Widget child;
  
  const MainShell({super.key, required this.child});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _getSelectedIndex(context),
        onTap: (index) => _onTabTapped(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
  
  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith(RouteNames.cart)) return 1;
    if (location.startsWith(RouteNames.orders)) return 2;
    if (location.startsWith(RouteNames.profile)) return 3;
    return 0;
  }
  
  void _onTabTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(RouteNames.home);
        break;
      case 1:
        context.go(RouteNames.cart);
        break;
      case 2:
        context.go(RouteNames.orders);
        break;
      case 3:
        context.go(RouteNames.profile);
        break;
    }
  }
}