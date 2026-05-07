import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/payment_request_model.dart';
import '../repositories/payment_repository.dart';

class VerifyPaymentUseCase {
  final PaymentRepository repository;
  
  const VerifyPaymentUseCase(this.repository);
  
  Future<Either<Failure, PaymentResultModel>> call(String sessionId) async {
    return await repository.verifyPayment(sessionId);
  }
}