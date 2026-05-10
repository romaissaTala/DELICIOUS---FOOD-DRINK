import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';
import 'get_products_params.dart';  // ← Import the params class

class GetProductsUseCase {
  final ProductRepository repository;
  
  const GetProductsUseCase(this.repository);
  
  // ✅ CHANGE: Accept GetProductsParams object
  Future<Either<Failure, ProductPage>> call(GetProductsParams params) async {
    return await repository.getProducts(
      categoryId: params.categoryId,
      mood: params.mood,
      searchQuery: params.searchQuery,
      page: params.page,
      limit: params.limit,
    );
  }
}