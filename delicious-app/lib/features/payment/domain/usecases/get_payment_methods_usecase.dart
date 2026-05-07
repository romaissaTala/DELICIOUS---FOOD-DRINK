import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/payment_method_model.dart';
import '../repositories/payment_repository.dart';

class GetPaymentMethodsUseCase {
  final PaymentRepository repository;
  
  const GetPaymentMethodsUseCase(this.repository);
  
  Future<Either<Failure, List<PaymentMethodModel>>> call() async {
    return await repository.getPaymentMethods();
  }
}