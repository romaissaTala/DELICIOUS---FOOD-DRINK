import 'package:Delicious_App/features/orders/data/models/order_tracking_model.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/order_models.dart';

abstract class OrderRepository {
  /// Place a new order
  Future<Either<Failure, OrderModel>> placeOrder(Map<String, dynamic> orderData);
  
  /// Get all orders for a user
  Future<Either<Failure, List<OrderModel>>> getOrders(String userId);
  
  /// Get a single order by ID
  Future<Either<Failure, OrderModel>> getOrderById(String orderId);
  
  /// Cancel an order (if status allows)
  Future<Either<Failure, OrderModel>> cancelOrder(String orderId, {String? reason});
  
  /// Track order status
  Future<Either<Failure, OrderTrackingModel>> trackOrder(String orderId);
}