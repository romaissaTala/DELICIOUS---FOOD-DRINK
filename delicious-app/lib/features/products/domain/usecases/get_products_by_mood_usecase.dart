import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';
import 'get_products_by_mood_params.dart';  // ← Import the params class

class GetProductsByMoodUseCase {
  final ProductRepository repository;
  
  const GetProductsByMoodUseCase(this.repository);
  
  // ✅ CHANGE: Accept GetProductsByMoodParams object
  Future<Either<Failure, List<Product>>> call(GetProductsByMoodParams params) async {
    return await repository.getProductsByMood(params.moods);
  }
}