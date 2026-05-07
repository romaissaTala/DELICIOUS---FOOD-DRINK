// lib/core/di/injection.dart
//
// Service locator setup for the Delicious app.
// Run `flutter pub run build_runner build` after adding @injectable
// annotations to auto-generate injection.config.dart.
//
// Usage in main.dart:
//   await configureDependencies();
//   runApp(const DeliciousApp());

import 'package:Delicious_App/features/auth/domain/usecases/auth_usecases.dart';
import 'package:Delicious_App/features/orders/domain/usecases/cancel_order_usecase.dart';
import 'package:Delicious_App/features/orders/domain/usecases/track_order_usecase.dart';
import 'package:Delicious_App/features/payment/domain/usecases/initiate_payment_usecase.dart';
import 'package:Delicious_App/features/payment/domain/usecases/verify_payment_usecase.dart';
import 'package:Delicious_App/features/payment/presentation/bloc/payment_bloc.dart';
import 'package:Delicious_App/features/products/domain/usecases/product_usecases.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';

// Core
import '../network/api_client.dart';
import '../network/dio_interceptor.dart';

// ── Auth feature ──────────────────────────────────────────────────────────────
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/domain/usecases/face_auth_usecase.dart';
import '../../features/auth/domain/usecases/biometric_auth_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

// ── Products feature ──────────────────────────────────────────────────────────
import '../../features/products/data/datasources/product_local_datasource.dart';
import '../../features/products/data/datasources/product_remote_datasource.dart';
import '../../features/products/data/repositories/product_repository_impl.dart';
import '../../features/products/domain/repositories/product_repository.dart';
import '../../features/products/domain/usecases/get_products_usecase.dart' hide GetProductsUseCase;
import '../../features/products/domain/usecases/get_products_by_mood_usecase.dart';
import '../../features/products/domain/usecases/get_product_by_id_usecase.dart';
import '../../features/products/domain/usecases/get_categories_usecase.dart';
import '../../features/products/presentation/bloc/product_bloc.dart';
import '../../features/products/presentation/bloc/category_bloc.dart';

// ── Cart feature ──────────────────────────────────────────────────────────────
import '../../features/cart/data/datasources/cart_local_datasource.dart';
import '../../features/cart/data/datasources/cart_remote_datasource.dart';
import '../../features/cart/data/repositories/cart_repository_impl.dart';
import '../../features/cart/domain/repositories/cart_repository.dart';
import '../../features/cart/domain/usecases/get_cart_usecase.dart';
import '../../features/cart/domain/usecases/add_to_cart_usecase.dart';
import '../../features/cart/domain/usecases/remove_from_cart_usecase.dart';
import '../../features/cart/domain/usecases/update_cart_item_usecase.dart';
import '../../features/cart/domain/usecases/clear_cart_usecase.dart';
import '../../features/cart/presentation/bloc/cart_bloc.dart';

// ── Orders feature ────────────────────────────────────────────────────────────
import '../../features/orders/data/datasources/order_remote_datasource.dart';
import '../../features/orders/data/repositories/order_repository_impl.dart';
import '../../features/orders/domain/repositories/order_repository.dart';
import '../../features/orders/domain/usecases/place_order_usecase.dart';
import '../../features/orders/domain/usecases/get_orders_usecase.dart';
import '../../features/orders/domain/usecases/get_order_by_id_usecase.dart';
import '../../features/orders/presentation/bloc/order_bloc.dart';

// ── Payment feature ───────────────────────────────────────────────────────────
import '../../features/payment/data/datasources/payment_remote_datasource.dart';
import '../../features/payment/data/repositories/payment_repository_impl.dart';
import '../../features/payment/domain/repositories/payment_repository.dart';
import '../../features/payment/domain/usecases/get_payment_methods_usecase.dart';

// ─────────────────────────────────────────────────────────────────────────────

/// Global service locator instance.
/// Access anywhere: `sl<AuthBloc>()`, `sl<Dio>()`, etc.
final sl = GetIt.instance;

/// API base URL — change per environment.
const String _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:5000/api', // Android emulator localhost
);

/// Call once in main() before runApp().
Future<void> configureDependencies() async {
  await _registerExternal();
  _registerCore();
  _registerAuth();
  _registerProducts();
  _registerCart();
  _registerOrders();
  _registerPayment();
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. External / third-party
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _registerExternal() async {
  // Hive boxes — opened once, reused everywhere
  await Hive.initFlutter();

  // Register Hive box adapters here before opening boxes:
  // Hive.registerAdapter(UserModelAdapter());
  // Hive.registerAdapter(CartItemModelAdapter());

  final cartBox = await Hive.openBox('cart_box');
  final userBox = await Hive.openBox('user_box');
  final settingsBox = await Hive.openBox('settings_box');

  sl.registerSingleton<Box>(cartBox, instanceName: 'cartBox');
  sl.registerSingleton<Box>(userBox, instanceName: 'userBox');
  sl.registerSingleton<Box>(settingsBox, instanceName: 'settingsBox');

  // Flutter Secure Storage — for JWT token
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );

  // Local Authentication (biometrics / Face ID)
  sl.registerLazySingleton<LocalAuthentication>(() => LocalAuthentication());
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Core (Dio, API client)
// ─────────────────────────────────────────────────────────────────────────────

void _registerCore() {
  // Dio interceptor — attaches JWT to every request
  sl.registerLazySingleton<AuthInterceptor>(
    () => AuthInterceptor(secureStorage: sl<FlutterSecureStorage>()),
  );

  // Dio instance
  sl.registerLazySingleton<Dio>(() {
    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    dio.interceptors.addAll([
      sl<AuthInterceptor>(),
      LogInterceptor(requestBody: true, responseBody: true),
    ]);
    return dio;
  });

  // Retrofit client (code-generated)
  sl.registerLazySingleton<DeliciousApiClient>(
    () => DeliciousApiClient(sl<Dio>()),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. Auth feature
// ─────────────────────────────────────────────────────────────────────────────

void _registerAuth() {
  // Datasources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(apiClient: sl<DeliciousApiClient>()),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(
      secureStorage: sl<FlutterSecureStorage>(),
      userBox: sl<Box>(instanceName: 'userBox'),
    ),
  );

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl<AuthRemoteDataSource>(),
      localDataSource: sl<AuthLocalDataSource>(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => LoginUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => RegisterUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => FaceAuthUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(
    () => BiometricAuthUseCase(
      repository: sl<AuthRepository>(),
      localAuth: sl<LocalAuthentication>(),
    ),
  );

  // Bloc — registered as Factory so a fresh instance is created per route
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl<LoginUseCase>(),
      registerUseCase: sl<RegisterUseCase>(),
      faceAuthUseCase: sl<FaceAuthUseCase>(),
      biometricAuthUseCase: sl<BiometricAuthUseCase>(),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. Products feature
// ─────────────────────────────────────────────────────────────────────────────

void _registerProducts() {
  // Datasources
  sl.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSourceImpl(apiClient: sl<DeliciousApiClient>()),
  );
  sl.registerLazySingleton<ProductLocalDataSource>(
    () => ProductLocalDataSourceImpl(
      // Hive box for cached products (open a dedicated box if needed)
      settingsBox: sl<Box>(instanceName: 'settingsBox'),
    ),
  );

  // Repository
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(
      remoteDataSource: sl<ProductRemoteDataSource>(),
      localDataSource: sl<ProductLocalDataSource>(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetProductsUseCase(sl<ProductRepository>()));
  sl.registerLazySingleton(
      () => GetProductsByMoodUseCase(sl<ProductRepository>()));
  sl.registerLazySingleton(
      () => GetProductByIdUseCase(sl<ProductRepository>()));
  sl.registerLazySingleton(() => GetCategoriesUseCase(sl<ProductRepository>()));

  // Blocs
  sl.registerFactory(
    () => ProductBloc(
      getProducts: sl<GetProductsUseCase>(),
      getProductsByMood: sl<GetProductsByMoodUseCase>(),
      getProductById: sl<GetProductByIdUseCase>(),
    ),
  );
  sl.registerFactory(
    () => CategoryBloc(getCategories: sl<GetCategoriesUseCase>()),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. Cart feature
// ─────────────────────────────────────────────────────────────────────────────

void _registerCart() {
  // Datasources
  sl.registerLazySingleton<CartRemoteDataSource>(
    () => CartRemoteDataSourceImpl(apiClient: sl<DeliciousApiClient>()),
  );
  sl.registerLazySingleton<CartLocalDataSource>(
    () => CartLocalDataSourceImpl(
      cartBox: sl<Box>(instanceName: 'cartBox'),
    ),
  );

  // Repository
  sl.registerLazySingleton<CartRepository>(
    () => CartRepositoryImpl(
      remoteDataSource: sl<CartRemoteDataSource>(),
      localDataSource: sl<CartLocalDataSource>(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetCartUseCase(sl<CartRepository>()));
  sl.registerLazySingleton(() => AddToCartUseCase(sl<CartRepository>()));
  sl.registerLazySingleton(() => RemoveFromCartUseCase(sl<CartRepository>()));
  sl.registerLazySingleton(() => UpdateCartItemUseCase(sl<CartRepository>()));
  sl.registerLazySingleton(() => ClearCartUseCase(sl<CartRepository>()));

  // Bloc — Singleton so cart state persists across pages
  sl.registerLazySingleton(
    () => CartBloc(
      getCart: sl<GetCartUseCase>(),
      addToCart: sl<AddToCartUseCase>(),
      removeFromCart: sl<RemoveFromCartUseCase>(),
      updateCartItem: sl<UpdateCartItemUseCase>(),
      clearCart: sl<ClearCartUseCase>(),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. Orders feature
// ─────────────────────────────────────────────────────────────────────────────
void _registerOrders() {
  // Datasource
  sl.registerLazySingleton<OrderRemoteDataSource>(
    () => OrderRemoteDataSourceImpl(apiClient: sl<DeliciousApiClient>()),
  );

  // Repository
  sl.registerLazySingleton<OrderRepository>(
    () => OrderRepositoryImpl(
      remoteDataSource: sl<OrderRemoteDataSource>(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => PlaceOrderUseCase(sl<OrderRepository>()));
  sl.registerLazySingleton(() => GetOrdersUseCase(sl<OrderRepository>()));
  sl.registerLazySingleton(() => GetOrderByIdUseCase(sl<OrderRepository>()));
  sl.registerLazySingleton(() => CancelOrderUseCase(sl<OrderRepository>()));
  sl.registerLazySingleton(() => TrackOrderUseCase(sl<OrderRepository>()));

  // Bloc
  sl.registerFactory(
    () => OrderBloc(
      placeOrder: sl<PlaceOrderUseCase>(),
      getOrders: sl<GetOrdersUseCase>(),
      getOrderById: sl<GetOrderByIdUseCase>(),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 7. Payment feature
// ─────────────────────────────────────────────────────────────────────────────
void _registerPayment() {
  // Datasource
  sl.registerLazySingleton<PaymentRemoteDataSource>(
    () => PaymentRemoteDataSourceImpl(
      apiClient: sl<DeliciousApiClient>(),
      dio: sl<Dio>(),
    ),
  );

  // Repository
  sl.registerLazySingleton<PaymentRepository>(
    () => PaymentRepositoryImpl(
      remoteDataSource: sl<PaymentRemoteDataSource>(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(
      () => GetPaymentMethodsUseCase(sl<PaymentRepository>()));
  sl.registerLazySingleton(
      () => InitiatePaymentUseCase(sl<PaymentRepository>()));
  sl.registerLazySingleton(() => VerifyPaymentUseCase(sl<PaymentRepository>()));

  // Bloc
  sl.registerFactory(
    () => PaymentBloc(
      getPaymentMethods: sl<GetPaymentMethodsUseCase>(),
      initiatePayment: sl<InitiatePaymentUseCase>(),
      verifyPayment: sl<VerifyPaymentUseCase>(),
    ),
  );
}
