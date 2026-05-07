import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetProductsByMoodUseCase {
  final ProductRepository repository;
  
  const GetProductsByMoodUseCase(this.repository);
  
  Future<Either<Failure, List<Product>>> call(List<String> moods) async {
    return await repository.getProductsByMood(moods);
  }
}