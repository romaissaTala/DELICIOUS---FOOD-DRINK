import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/order_models.dart';
import '../repositories/order_repository.dart';

class PlaceOrderUseCase {
  final OrderRepository repository;
  
  const PlaceOrderUseCase(this.repository);
  
  Future<Either<Failure, OrderModel>> call(Map<String, dynamic> orderData) async {
    return await repository.placeOrder(orderData);
  }
}