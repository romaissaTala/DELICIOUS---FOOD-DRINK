import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/cart_models.dart';
import '../repositories/cart_repository.dart';

class AddToCartUseCase {
  final CartRepository repository;
  
  const AddToCartUseCase(this.repository);
  
  Future<Either<Failure, CartModel>> call({
    required String userId,
    required String productId,
    required String productName,
    required String productImageUrl,
    required double unitPrice,
    int quantity = 1,
  }) async {
    return await repository.addToCart(
      userId: userId,
      productId: productId,
      productName: productName,
      productImageUrl: productImageUrl,
      unitPrice: unitPrice,
      quantity: quantity,
    );
  }
}