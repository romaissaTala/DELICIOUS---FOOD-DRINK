import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/category.dart';
import '../repositories/product_repository.dart';

class GetCategoriesUseCase {
  final ProductRepository repository;
  
  const GetCategoriesUseCase(this.repository);
  
  Future<Either<Failure, List<Category>>> call() async {
    return await repository.getCategories();
  }
}