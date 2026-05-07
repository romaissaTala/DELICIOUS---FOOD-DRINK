import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/order_models.dart';
import '../repositories/order_repository.dart';

class CancelOrderUseCase {
  final OrderRepository repository;
  
  const CancelOrderUseCase(this.repository);
  
  Future<Either<Failure, OrderModel>> call(String orderId, {String? reason}) async {
    return await repository.cancelOrder(orderId, reason: reason);
  }
}