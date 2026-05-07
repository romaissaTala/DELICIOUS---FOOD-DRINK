import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/order_tracking_model.dart';
import '../repositories/order_repository.dart';

class TrackOrderUseCase {
  final OrderRepository repository;
  
  const TrackOrderUseCase(this.repository);
  
  Future<Either<Failure, OrderTrackingModel>> call(String orderId) async {
    return await repository.trackOrder(orderId);
  }
}