import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_remote_datasource.dart';
import '../models/order_models.dart';
import '../models/order_tracking_model.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource remoteDataSource;
  
  const OrderRepositoryImpl({required this.remoteDataSource});
  
  @override
  Future<Either<Failure, OrderModel>> placeOrder(Map<String, dynamic> orderData) async {
    try {
      final order = await remoteDataSource.placeOrder(orderData);
      return Right(order);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Failed to place order'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, List<OrderModel>>> getOrders(String userId) async {
    try {
      final orders = await remoteDataSource.getOrders(userId);
      return Right(orders);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Failed to get orders'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, OrderModel>> getOrderById(String orderId) async {
    try {
      final order = await remoteDataSource.getOrderById(orderId);
      return Right(order);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Failed to get order details'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, OrderModel>> cancelOrder(String orderId, {String? reason}) async {
    try {
      final order = await remoteDataSource.cancelOrder(orderId, reason: reason);
      return Right(order);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Failed to cancel order'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, OrderTrackingModel>> trackOrder(String orderId) async {
    try {
      final tracking = await remoteDataSource.trackOrder(orderId);
      return Right(tracking);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Failed to track order'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}