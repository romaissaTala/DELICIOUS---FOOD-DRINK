import 'package:Delicious_App/features/auth/domain/usecases/auth_usecases.dart';
import 'package:Delicious_App/features/products/domain/usecases/get_categories_usecase.dart';
import 'package:Delicious_App/features/products/domain/usecases/get_featured_products_usecase.dart';
import 'package:Delicious_App/features/products/domain/usecases/get_product_by_id_usecase.dart';
import 'package:Delicious_App/features/products/domain/usecases/get_products_by_mood_usecase.dart';
import 'package:Delicious_App/features/products/domain/usecases/get_products_usecase.dart';
import 'package:Delicious_App/features/products/domain/usecases/refresh_product_cache_usecase.dart';
import 'package:Delicious_App/features/products/domain/usecases/search_products_usecase.dart';

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
import '../../features/auth/presentation/bloc/auth_bloc.dart';

// ── Products feature ──────────────────────────────────────────────────────────
import '../../features/products/data/datasources/product_local_datasource.dart';
import '../../features/products/data/datasources/product_remote_datasource.dart';
import '../../features/products/data/repositories/product_repository_impl.dart';
import '../../features/products/domain/repositories/product_repository.dart';
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
import '../../features/orders/domain/usecases/cancel_order_usecase.dart';
import '../../features/orders/domain/usecases/track_order_usecase.dart';
import '../../features/orders/presentation/bloc/order_bloc.dart';

// ── Payment feature ───────────────────────────────────────────────────────────
import '../../features/payment/data/datasources/payment_remote_datasource.dart';
import '../../features/payment/data/repositories/payment_repository_impl.dart';
import '../../features/payment/domain/repositories/payment_repository.dart';
import '../../features/payment/domain/usecases/get_payment_methods_usecase.dart';
import '../../features/payment/domain/usecases/initiate_payment_usecase.dart';
import '../../features/payment/domain/usecases/verify_payment_usecase.dart';
import '../../features/payment/presentation/bloc/payment_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────

final sl = GetIt.instance;

const String _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:5000/api',
);

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

Future<void> _registerExternal() async {
  await Hive.initFlutter();

  final cartBox = await Hive.openBox('cart_box');
  final userBox = await Hive.openBox('user_box');
  final settingsBox = await Hive.openBox('settings_box');
  final productBox = await Hive.openBox('product_box');  // ← ADDED

  sl.registerSingleton<Box>(cartBox, instanceName: 'cartBox');
  sl.registerSingleton<Box>(userBox, instanceName: 'userBox');
  sl.registerSingleton<Box>(settingsBox, instanceName: 'settingsBox');
  sl.registerSingleton<Box>(productBox, instanceName: 'productBox');

  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );

  sl.registerLazySingleton<LocalAuthentication>(() => LocalAuthentication());
}

// ─────────────────────────────────────────────────────────────────────────────

void _registerCore() {
  sl.registerLazySingleton<AuthInterceptor>(
    () => AuthInterceptor(secureStorage: sl<FlutterSecureStorage>()),
  );

  sl.registerLazySingleton<Dio>(() {
    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    dio.interceptors.addAll([
      sl<AuthInterceptor>(),
      LogInterceptor(requestBody: true, responseBody: true),
    ]);
    return dio;
  });

  sl.registerLazySingleton<DeliciousApiClient>(
    () => DeliciousApiClient(sl<Dio>()),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

void _registerAuth() {
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(dio: sl<Dio>()),
  );
  
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(
      secureStorage: sl<FlutterSecureStorage>(),
      userBox: sl<Box>(instanceName: 'userBox'),
    ),
  );

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remote: sl<AuthRemoteDataSource>(),
      local: sl<AuthLocalDataSource>(),
      localAuth: sl<LocalAuthentication>(),
    ),
  );

  sl.registerLazySingleton(() => LoginUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => RegisterUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => LogoutUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => GetCachedUserUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => GuestLoginUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => FaceAuthUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => SaveFaceVectorUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => BiometricAuthUseCase(sl<AuthRepository>()));

  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl<LoginUseCase>(),
      registerUseCase: sl<RegisterUseCase>(),
      logoutUseCase: sl<LogoutUseCase>(),
      getCachedUserUseCase: sl<GetCachedUserUseCase>(),
      biometricAuthUseCase: sl<BiometricAuthUseCase>(),
      faceAuthUseCase: sl<FaceAuthUseCase>(),
      saveFaceVectorUseCase: sl<SaveFaceVectorUseCase>(),
      guestLoginUseCase: sl<GuestLoginUseCase>(),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

void _registerProducts() {
  sl.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSourceImpl(apiClient: sl<DeliciousApiClient>()),
  );
  
  sl.registerLazySingleton<ProductLocalDataSource>(
    () => ProductLocalDataSourceImpl(
      productBox: sl<Box>(instanceName: 'productBox'),  // ← FIXED
    ),
  );

  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(
      remoteDataSource: sl<ProductRemoteDataSource>(),
      localDataSource: sl<ProductLocalDataSource>(),
    ),
  );

  sl.registerLazySingleton(() => GetProductsUseCase(sl<ProductRepository>()));
  sl.registerLazySingleton(() => GetProductsByMoodUseCase(sl<ProductRepository>()));
  sl.registerLazySingleton(() => GetProductByIdUseCase(sl<ProductRepository>()));
  sl.registerLazySingleton(() => GetCategoriesUseCase(sl<ProductRepository>()));
  sl.registerLazySingleton(() => GetFeaturedProductsUseCase(sl<ProductRepository>()));
  sl.registerLazySingleton(() => SearchProductsUseCase(sl<ProductRepository>()));
  sl.registerLazySingleton(() => RefreshProductCacheUseCase(sl<ProductRepository>()));

  sl.registerFactory(
    () => ProductBloc(
      getProducts: sl<GetProductsUseCase>(),
      getProductsByMood: sl<GetProductsByMoodUseCase>(),
      getProductById: sl<GetProductByIdUseCase>(),
      getFeatured: sl<GetFeaturedProductsUseCase>(),
      searchProducts: sl<SearchProductsUseCase>(),
      refreshCache: sl<RefreshProductCacheUseCase>(),
    ),
  );
  
  sl.registerFactory(
    () => CategoryBloc(getCategories: sl<GetCategoriesUseCase>()),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

void _registerCart() {
  sl.registerLazySingleton<CartRemoteDataSource>(
    () => CartRemoteDataSourceImpl(apiClient: sl<DeliciousApiClient>()),
  );
  
  sl.registerLazySingleton<CartLocalDataSource>(
    () => CartLocalDataSourceImpl(
      cartBox: sl<Box>(instanceName: 'cartBox'),
    ),
  );

  sl.registerLazySingleton<CartRepository>(
    () => CartRepositoryImpl(
      remoteDataSource: sl<CartRemoteDataSource>(),
      localDataSource: sl<CartLocalDataSource>(),
    ),
  );

  sl.registerLazySingleton(() => GetCartUseCase(sl<CartRepository>()));
  sl.registerLazySingleton(() => AddToCartUseCase(sl<CartRepository>()));
  sl.registerLazySingleton(() => RemoveFromCartUseCase(sl<CartRepository>()));
  sl.registerLazySingleton(() => UpdateCartItemUseCase(sl<CartRepository>()));
  sl.registerLazySingleton(() => ClearCartUseCase(sl<CartRepository>()));

  sl.registerFactory(
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

void _registerOrders() {
  sl.registerLazySingleton<OrderRemoteDataSource>(
    () => OrderRemoteDataSourceImpl(apiClient: sl<DeliciousApiClient>()),
  );

  sl.registerLazySingleton<OrderRepository>(
    () => OrderRepositoryImpl(
      remoteDataSource: sl<OrderRemoteDataSource>(),
    ),
  );

  sl.registerLazySingleton(() => PlaceOrderUseCase(sl<OrderRepository>()));
  sl.registerLazySingleton(() => GetOrdersUseCase(sl<OrderRepository>()));
  sl.registerLazySingleton(() => GetOrderByIdUseCase(sl<OrderRepository>()));
  sl.registerLazySingleton(() => CancelOrderUseCase(sl<OrderRepository>()));
  sl.registerLazySingleton(() => TrackOrderUseCase(sl<OrderRepository>()));

  sl.registerFactory(
    () => OrderBloc(
      placeOrder: sl<PlaceOrderUseCase>(),
      getOrders: sl<GetOrdersUseCase>(),
      getOrderById: sl<GetOrderByIdUseCase>(),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

void _registerPayment() {
  sl.registerLazySingleton<PaymentRemoteDataSource>(
    () => PaymentRemoteDataSourceImpl(
      apiClient: sl<DeliciousApiClient>(),
      dio: sl<Dio>(),  // ← FIXED: Added required dio parameter
    ),
  );

  sl.registerLazySingleton<PaymentRepository>(
    () => PaymentRepositoryImpl(
      remoteDataSource: sl<PaymentRemoteDataSource>(),  // ← FIXED: Parameter name
    ),
  );

  sl.registerLazySingleton(() => GetPaymentMethodsUseCase(sl<PaymentRepository>()));
  sl.registerLazySingleton(() => InitiatePaymentUseCase(sl<PaymentRepository>()));
  sl.registerLazySingleton(() => VerifyPaymentUseCase(sl<PaymentRepository>()));

  sl.registerFactory(
    () => PaymentBloc(
      getPaymentMethods: sl<GetPaymentMethodsUseCase>(),
      initiatePayment: sl<InitiatePaymentUseCase>(),
      verifyPayment: sl<VerifyPaymentUseCase>(),
    ),
  );
}