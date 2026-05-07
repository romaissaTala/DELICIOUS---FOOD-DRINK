import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/cart_repository.dart';

class ClearCartUseCase {
  final CartRepository repository;
  
  const ClearCartUseCase(this.repository);
  
  Future<Either<Failure, void>> call(String userId) async {
    return await repository.clearCart(userId);
  }
}