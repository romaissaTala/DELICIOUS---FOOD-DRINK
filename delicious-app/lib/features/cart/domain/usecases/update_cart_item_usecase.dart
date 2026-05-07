import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/cart_models.dart';
import '../repositories/cart_repository.dart';

class UpdateCartItemUseCase {
  final CartRepository repository;
  
  const UpdateCartItemUseCase(this.repository);
  
  Future<Either<Failure, CartModel>> call({
    required String cartItemId,
    required int quantity,
  }) async {
    return await repository.updateCartItem(
      cartItemId: cartItemId,
      quantity: quantity,
    );
  }
}