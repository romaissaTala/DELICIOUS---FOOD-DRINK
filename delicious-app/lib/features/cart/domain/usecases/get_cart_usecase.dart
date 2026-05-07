import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/cart_models.dart';
import '../repositories/cart_repository.dart';

class GetCartUseCase {
  final CartRepository repository;
  
  const GetCartUseCase(this.repository);
  
  Future<Either<Failure, CartModel>> call(String userId) async {
    return await repository.getCart(userId);
  }
}