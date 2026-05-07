import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/cart_models.dart';
import '../repositories/cart_repository.dart';

class RemoveFromCartUseCase {
  final CartRepository repository;
  
  const RemoveFromCartUseCase(this.repository);
  
  Future<Either<Failure, CartModel>> call(String cartItemId) async {
    return await repository.removeFromCart(cartItemId);
  }
}