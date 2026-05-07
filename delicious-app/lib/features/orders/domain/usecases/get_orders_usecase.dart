import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/order_models.dart';
import '../repositories/order_repository.dart';

class GetOrdersUseCase {
  final OrderRepository repository;
  
  const GetOrdersUseCase(this.repository);
  
  Future<Either<Failure, List<OrderModel>>> call(String userId) async {
    return await repository.getOrders(userId);
  }
}