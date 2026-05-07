import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/payment_method_model.dart';
import '../../data/models/payment_request_model.dart';

abstract class PaymentRepository {
  Future<Either<Failure, List<PaymentMethodModel>>> getPaymentMethods();
  Future<Either<Failure, Map<String, dynamic>>> initiatePayment(PaymentRequestModel request);
  Future<Either<Failure, PaymentResultModel>> verifyPayment(String sessionId);
}