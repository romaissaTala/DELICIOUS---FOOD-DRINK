import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:Delicious_App/features/auth/data/models/auth_models.dart';
import 'package:Delicious_App/features/products/data/models/product_model.dart';
import 'package:Delicious_App/features/cart/data/models/cart_models.dart';
import 'package:Delicious_App/features/orders/data/models/order_models.dart';
import 'package:Delicious_App/features/orders/data/models/order_tracking_model.dart';
import 'package:Delicious_App/features/payment/data/models/payment_method_model.dart';

class DeliciousApiClient {
  final Dio _dio;

  DeliciousApiClient(this._dio);

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Handle API response and extract data
  dynamic _handleResponse(Response response) {
    final data = response.data;
    if (data is Map<String, dynamic> && data.containsKey('data')) {
      return data['data'];
    }
    return data;
  }

  /// Handle errors
  void _handleError(DioException e) {
    throw e;
  }

  // ============================================
  // AUTH ENDPOINTS
  // ============================================

  Future<AuthResponse> register(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post('/auth/register', data: body);
      final data = _handleResponse(response) as Map<String, dynamic>;
      return AuthResponse.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<AuthResponse> login(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post('/auth/login', data: body);
      final data = _handleResponse(response) as Map<String, dynamic>;
      return AuthResponse.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<void> logout(Map<String, dynamic> body) async {
    try {
      await _dio.delete('/auth/logout', data: body);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<AuthResponse> refreshToken(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post('/auth/refresh', data: body);
      final data = _handleResponse(response) as Map<String, dynamic>;
      return AuthResponse.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<UserModel> getProfile() async {
    try {
      final response = await _dio.get('/auth/me');
      final data = _handleResponse(response) as Map<String, dynamic>;
      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // ============================================
  // PRODUCTS ENDPOINTS
  // ============================================

  Future<List<ProductModel>> getProducts({
    String? category,
    String? mood,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null) queryParams['category'] = category;
      if (mood != null) queryParams['mood'] = mood;

      final response =
          await _dio.get('/products', queryParameters: queryParams);
      final data = _handleResponse(response) as List;
      return data
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<ProductModel> getProductById(String id) async {
    try {
      final response = await _dio.get('/products/$id');
      final data = _handleResponse(response) as Map<String, dynamic>;
      return ProductModel.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _dio.get('/categories');
      final data = _handleResponse(response) as List;
      return data
          .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // ============================================
  // CART ENDPOINTS
  // ============================================

  Future<CartModel> getCart(String userId) async {
    try {
      final response = await _dio.get('/cart/$userId');
      final data = _handleResponse(response) as Map<String, dynamic>;
      return CartModel.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<CartModel> addToCart(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post('/cart/add', data: body);
      final data = _handleResponse(response) as Map<String, dynamic>;
      return CartModel.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<CartModel> updateCartItem(Map<String, dynamic> body) async {
    try {
      final response = await _dio.put('/cart/update', data: body);
      final data = _handleResponse(response) as Map<String, dynamic>;
      return CartModel.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<CartModel> removeFromCart(String itemId) async {
    try {
      final response = await _dio.delete('/cart/remove/$itemId');
      final data = _handleResponse(response) as Map<String, dynamic>;
      return CartModel.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<void> clearCart(String userId) async {
    try {
      await _dio.delete('/cart/clear/$userId');
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }
  // ============================================
  // ORDERS ENDPOINTS (CONSISTENT - All using Dio)
  // ============================================

  /// Place a new order
  Future<OrderModel> placeOrder(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post('/orders', data: body);
      final data = _handleResponse(response) as Map<String, dynamic>;
      return OrderModel.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// Get all orders for a specific user
  Future<List<OrderModel>> getUserOrders(String userId) async {
    try {
      final response = await _dio.get('/orders/user/$userId');
      final data = _handleResponse(response) as List;
      return data
          .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// Get a single order by ID
  Future<OrderModel> getOrderById(String orderId) async {
    try {
      final response = await _dio.get('/orders/$orderId');
      final data = _handleResponse(response) as Map<String, dynamic>;
      return OrderModel.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// Track order status (returns tracking info)
  Future<OrderTrackingModel> trackOrder(String orderId) async {
    try {
      final response = await _dio.get('/orders/$orderId/track');
      final data = _handleResponse(response) as Map<String, dynamic>;
      return OrderTrackingModel.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// Update order status (Admin only)
  Future<OrderModel> updateOrderStatus(
      String orderId, Map<String, dynamic> body) async {
    try {
      final response = await _dio.put('/orders/$orderId/status', data: body);
      final data = _handleResponse(response) as Map<String, dynamic>;
      return OrderModel.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// Cancel an order (User can cancel only if status allows)
  Future<OrderModel> cancelOrder(String orderId, {String? reason}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (reason != null) queryParams['reason'] = reason;

      final response = await _dio.delete(
        '/orders/$orderId',
        queryParameters: queryParams,
      );
      final data = _handleResponse(response) as Map<String, dynamic>;
      return OrderModel.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }
  // ============================================
  // PAYMENT ENDPOINTS
  // ============================================

  Future<List<PaymentMethodModel>> getPaymentMethods() async {
    try {
      final response = await _dio.get('/payment/methods');
      final data = _handleResponse(response) as List;
      return data
          .map((json) =>
              PaymentMethodModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// Create a payment session via YOUR backend
  Future<Map<String, dynamic>> createPaymentSession(
      Map<String, dynamic> body) async {
    try {
      final response = await _dio.post('/payment/create-session', data: body);
      final data = _handleResponse(response);
      return data as Map<String, dynamic>;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// Verify payment status from YOUR backend
  Future<Map<String, dynamic>> verifyPayment(String sessionId) async {
    try {
      final response = await _dio.get('/payment/verify/$sessionId');
      final data = _handleResponse(response);
      return data as Map<String, dynamic>;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }
}
