import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/cart_models.dart';

abstract class CartRepository {
  Future<Either<Failure, CartModel>> getCart(String userId);
  Future<Either<Failure, CartModel>> addToCart({
    required String userId,
    required String productId,
    required String productName,
    required String productImageUrl,
    required double unitPrice,
    int quantity = 1,
  });
  Future<Either<Failure, CartModel>> updateCartItem({
    required String cartItemId,
    required int quantity,
  });
  Future<Either<Failure, CartModel>> removeFromCart(String cartItemId);
  Future<Either<Failure, void>> clearCart(String userId);
}