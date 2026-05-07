import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/payment_request_model.dart';
import '../repositories/payment_repository.dart';

class InitiatePaymentUseCase {
  final PaymentRepository repository;
  
  const InitiatePaymentUseCase(this.repository);
  
  Future<Either<Failure, Map<String, dynamic>>> call(PaymentRequestModel request) async {
    return await repository.initiatePayment(request);
  }
}