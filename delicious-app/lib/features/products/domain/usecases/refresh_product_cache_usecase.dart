import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/product_repository.dart';

class RefreshProductCacheUseCase {
  final ProductRepository repository;
  
  const RefreshProductCacheUseCase(this.repository);
  
  Future<Either<Failure, void>> call() async {
    return await repository.refreshCache();
  }
}