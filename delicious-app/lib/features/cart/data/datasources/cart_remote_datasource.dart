import 'package:Delicious_App/core/network/api_client.dart';
import '../models/cart_models.dart';

abstract class CartRemoteDataSource {
  Future<CartModel> getCart(String userId);
  Future<CartModel> addToCart({
    required String userId,
    required String productId,
    required String productName,
    required String productImageUrl,
    required double unitPrice,
    int quantity = 1,
    List<String> gradientColors = const [],
  });
  Future<CartModel> updateCartItem(String cartItemId, int quantity);
  Future<CartModel> removeFromCart(String cartItemId);
  Future<void> clearCart(String userId);
}

class CartRemoteDataSourceImpl implements CartRemoteDataSource {
  final DeliciousApiClient apiClient;
  
  const CartRemoteDataSourceImpl({required this.apiClient});
  
  @override
  Future<CartModel> getCart(String userId) async {
    // No need for .data or parsing - the interceptor handles it!
    return await apiClient.getCart(userId);
  }
  
  @override
  Future<CartModel> addToCart({
    required String userId,
    required String productId,
    required String productName,
    required String productImageUrl,
    required double unitPrice,
    int quantity = 1,
    List<String> gradientColors = const [],
  }) async {
    return await apiClient.addToCart({
      'userId': userId,
      'productId': productId,
      'productName': productName,
      'productImageUrl': productImageUrl,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'gradientColors': gradientColors,
    });
  }
  
  @override
  Future<CartModel> updateCartItem(String cartItemId, int quantity) async {
    return await apiClient.updateCartItem({
      'cartItemId': cartItemId,
      'quantity': quantity,
    });
  }
  
  @override
  Future<CartModel> removeFromCart(String cartItemId) async {
    return await apiClient.removeFromCart(cartItemId);
  }
  
  @override
  Future<void> clearCart(String userId) async {
    await apiClient.clearCart(userId);
  }
}