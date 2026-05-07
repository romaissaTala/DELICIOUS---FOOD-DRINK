// lib/features/products/domain/usecases/product_usecases.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../entities/category.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

// ── Params ────────────────────────────────────────────────────────────────────

class GetProductsParams extends Equatable {
  final String? categoryId;
  final String? mood;
  final String? searchQuery;
  final int     page;
  final int     limit;

  const GetProductsParams({
    this.categoryId,
    this.mood,
    this.searchQuery,
    this.page  = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [categoryId, mood, searchQuery, page, limit];
}

class GetProductsByMoodParams extends Equatable {
  final List<String> moods;
  const GetProductsByMoodParams(this.moods);
  @override
  List<Object> get props => [moods];
}

// ── Use cases ─────────────────────────────────────────────────────────────────

class GetProductsUseCase {
  final ProductRepository _repo;
  const GetProductsUseCase(this._repo);

  Future<Either<Failure, ProductPage>> call(GetProductsParams p) =>
      _repo.getProducts(
        categoryId:  p.categoryId,
        mood:        p.mood,
        searchQuery: p.searchQuery,
        page:        p.page,
        limit:       p.limit,
      );
}

class GetProductByIdUseCase {
  final ProductRepository _repo;
  const GetProductByIdUseCase(this._repo);

  Future<Either<Failure, Product>> call(String id) =>
      _repo.getProductById(id);
}

class GetProductsByMoodUseCase {
  final ProductRepository _repo;
  const GetProductsByMoodUseCase(this._repo);

  Future<Either<Failure, List<Product>>> call(GetProductsByMoodParams p) =>
      _repo.getProductsByMood(p.moods);
}

class GetFeaturedProductsUseCase {
  final ProductRepository _repo;
  const GetFeaturedProductsUseCase(this._repo);

  Future<Either<Failure, List<Product>>> call() =>
      _repo.getFeaturedProducts();
}

class SearchProductsUseCase {
  final ProductRepository _repo;
  const SearchProductsUseCase(this._repo);

  Future<Either<Failure, List<Product>>> call(String query) =>
      _repo.searchProducts(query);
}

class GetCategoriesUseCase {
  final ProductRepository _repo;
  const GetCategoriesUseCase(this._repo);

  Future<Either<Failure, List<Category>>> call() =>
      _repo.getCategories();
}

class RefreshProductCacheUseCase {
  final ProductRepository _repo;
  const RefreshProductCacheUseCase(this._repo);

  Future<Either<Failure, void>> call() => _repo.refreshCache();
}