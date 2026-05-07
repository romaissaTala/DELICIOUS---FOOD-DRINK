import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/order_models.dart';
import '../repositories/order_repository.dart';

class GetOrderByIdUseCase {
  final OrderRepository repository;
  
  const GetOrderByIdUseCase(this.repository);
  
  Future<Either<Failure, OrderModel>> call(String orderId) async {
    return await repository.getOrderById(orderId);
  }
}