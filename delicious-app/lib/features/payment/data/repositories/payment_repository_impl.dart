import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/payment_remote_datasource.dart';
import '../models/payment_method_model.dart';
import '../models/payment_request_model.dart';


class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource remoteDataSource;  // ← Match this name
  
  const PaymentRepositoryImpl({required this.remoteDataSource});  // ← Match parameter name
  
  @override
  Future<Either<Failure, List<PaymentMethodModel>>> getPaymentMethods() async {
    try {
      final methods = await remoteDataSource.getPaymentMethods();
      return Right(methods);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Failed to get payment methods'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, Map<String, dynamic>>> initiatePayment(PaymentRequestModel request) async {
    try {
      final session = await remoteDataSource.createPaymentSession(request);
      return Right(session);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Failed to initiate payment'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, PaymentResultModel>> verifyPayment(String sessionId) async {
    try {
      final result = await remoteDataSource.verifyPayment(sessionId);
      return Right(result);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Failed to verify payment'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}