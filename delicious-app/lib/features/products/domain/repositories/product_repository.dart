// lib/features/products/domain/repositories/product_repository.dart
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/category.dart';
import '../entities/product.dart';

/// Pure domain contract — zero Flutter/Dio/Hive imports.
abstract class ProductRepository {
  // ── Products ──────────────────────────────────────────────────────────────

  /// Fetch a paginated list of products.
  /// Passes optional [categoryId], [mood], [searchQuery], [page], [limit].
  Future<Either<Failure, ProductPage>> getProducts({
    String? categoryId,
    String? mood,
    String? searchQuery,
    int     page  = 1,
    int     limit = 20,
  });

  /// Fetch a single product by its ID.
  Future<Either<Failure, Product>> getProductById(String id);

  /// Fetch products matching one or more mood tags (e.g. "cold", "sweet").
  Future<Either<Failure, List<Product>>> getProductsByMood(List<String> moods);

  /// Fetch featured / trending products for the home banner.
  Future<Either<Failure, List<Product>>> getFeaturedProducts();

  /// Full-text search — delegates to the MongoDB $text index.
  Future<Either<Failure, List<Product>>> searchProducts(String query);

  // ── Categories ────────────────────────────────────────────────────────────

  Future<Either<Failure, List<Category>>> getCategories();

  // ── Cache control ─────────────────────────────────────────────────────────

  /// Invalidate and refresh the local product cache.
  Future<Either<Failure, void>> refreshCache();
}

/// Wraps a page of products with pagination metadata.
class ProductPage {
  final List<Product> products;
  final int           total;
  final int           page;
  final int           limit;
  final bool          hasMore;

  const ProductPage({
    required this.products,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasMore,
  });

  ProductPage copyWith({List<Product>? products, bool? hasMore}) => ProductPage(
        products: products ?? this.products,
        total:    total,
        page:     page,
        limit:    limit,
        hasMore:  hasMore ?? this.hasMore,
      );
}