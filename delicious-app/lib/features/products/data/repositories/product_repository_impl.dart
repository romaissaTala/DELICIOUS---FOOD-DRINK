import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../../../cart/data/models/cart_models.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_local_datasource.dart';
import '../datasources/product_remote_datasource.dart';
import '../models/product_model.dart';


class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;
  final ProductLocalDataSource localDataSource;
  
  const ProductRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });
  
  @override
  Future<Either<Failure, ProductPage>> getProducts({
    String? categoryId,
    String? mood,
    String? searchQuery,
    int page = 1,
    int limit = 20,
  }) async {
    // Create cache key based on filters
    final cacheKey = '${categoryId ?? 'all'}_${mood ?? 'all'}_$page';
    
    try {
      final products = await remoteDataSource.getProducts(
        category: categoryId,
        mood: mood,
      );
      
      final productModels = products;
      final productEntities = productModels.map((p) => _mapToEntity(p)).toList();
      
      final productPage = ProductPage(
        products: productEntities,
        total: productEntities.length,
        page: page,
        limit: limit,
        hasMore: false,
      );
      
      // Cache the results
      final pageModel = ProductPageModel(
        products: productModels,
        total: productEntities.length,
        page: page,
        limit: limit,
        hasMore: false,
      );
      await localDataSource.cacheProducts(cacheKey, pageModel);
      
      return Right(productPage);
    } on DioException catch (e) {
      // Try to get cached data
      final cachedPage = await localDataSource.getCachedProducts(cacheKey);
      if (cachedPage != null) {
        final cachedEntities = cachedPage.products.map((p) => _mapToEntity(p)).toList();
        return Right(ProductPage(
          products: cachedEntities,
          total: cachedPage.total,
          page: cachedPage.page,
          limit: cachedPage.limit,
          hasMore: cachedPage.hasMore,
        ));
      }
      return Left(ServerFailure(e.message ?? 'Failed to get products'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, Product>> getProductById(String id) async {
    try {
      final product = await remoteDataSource.getProductById(id);
      await localDataSource.cacheProduct(product);
      return Right(_mapToEntity(product));
    } on DioException catch (e) {
      final cachedProduct = await localDataSource.getCachedProduct(id);
      if (cachedProduct != null) {
        return Right(_mapToEntity(cachedProduct));
      }
      return Left(ServerFailure(e.message ?? 'Failed to get product'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, List<Product>>> getProductsByMood(List<String> moods) async {
    try {
      final allProducts = await remoteDataSource.getProducts();
      final filtered = allProducts.where((p) => p.mood.any((m) => moods.contains(m))).toList();
      return Right(filtered.map((p) => _mapToEntity(p)).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Failed to get products by mood'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, List<Product>>> getFeaturedProducts() async {
    try {
      final products = await remoteDataSource.getProducts();
      final featured = products.where((p) => p.isFeatured).toList();
      await localDataSource.cacheFeaturedProducts(featured);
      return Right(featured.map((p) => _mapToEntity(p)).toList());
    } on DioException catch (e) {
      final cached = await localDataSource.getCachedFeaturedProducts();
      if (cached != null) {
        return Right(cached.map((p) => _mapToEntity(p)).toList());
      }
      return Left(ServerFailure(e.message ?? 'Failed to get featured products'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, List<Product>>> searchProducts(String query) async {
    try {
      final products = await remoteDataSource.getProducts();
      final filtered = products.where((p) =>
        p.name.toLowerCase().contains(query.toLowerCase()) ||
        (p.description?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
        (p.brand?.toLowerCase().contains(query.toLowerCase()) ?? false)
      ).toList();
      return Right(filtered.map((p) => _mapToEntity(p)).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Failed to search products'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, List<Category>>> getCategories() async {
    try {
      final categories = await remoteDataSource.getCategories();
      final cached = await localDataSource.getCachedCategories();
      
      if (cached == null) {
        await localDataSource.cacheCategories(categories);
      }
      
      return Right(categories.map((c) => c.toEntity()).toList());
    } on DioException catch (e) {
      final cached = await localDataSource.getCachedCategories();
      if (cached != null) {
        return Right(cached.map((c) => c.toEntity()).toList());
      }
      return Left(ServerFailure(e.message ?? 'Failed to get categories'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, void>> refreshCache() async {
    try {
      await localDataSource.clearCache();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
  
  Product _mapToEntity(ProductModel model) {
    return Product(
      id: model.id,
      name: model.name,
      description: model.description,
      brand: model.brand,
      price: model.price,
      discountPercent: model.discountPercent,
      categoryId: model.categoryId,
      gradientColors: model.gradientColors,
      mood: model.mood,
      imageUrl: model.imageUrl,
      thumbnailUrl: model.thumbnailUrl,
      imageGallery: model.imageGallery,
      variants: model.variants.map((v) => ProductVariant(
        id: v.id,
        label: v.label,
        price: v.price,
        stock: v.stock,
      )).toList(),
      nutrition: model.nutrition != null ? ProductNutrition(
        calories: model.nutrition!.calories,
        protein: model.nutrition!.protein,
        carbs: model.nutrition!.carbs,
        fat: model.nutrition!.fat,
        sugar: model.nutrition!.sugar,
        servingSize: model.nutrition!.servingSize,
      ) : null,
      isAvailable: model.isAvailable,
      stock: model.stock,
      preparationTimeMin: model.preparationTimeMin,
      isFeatured: model.isFeatured,
      rating: ProductRating(average: model.rating.average, count: model.rating.count),
      tags: model.tags,
    );
  }
}