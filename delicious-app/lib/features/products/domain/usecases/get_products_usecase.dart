import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetProductsUseCase {
  final ProductRepository repository;
  
  const GetProductsUseCase(this.repository);
  
  Future<Either<Failure, ProductPage>> call({
    String? categoryId,
    String? mood,
    String? searchQuery,
    int page = 1,
    int limit = 20,
  }) async {
    return await repository.getProducts(
      categoryId: categoryId,
      mood: mood,
      searchQuery: searchQuery,
      page: page,
      limit: limit,
    );
  }
}