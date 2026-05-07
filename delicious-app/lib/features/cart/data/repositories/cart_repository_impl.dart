import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/cart_local_datasource.dart';
import '../datasources/cart_remote_datasource.dart';
import '../models/cart_models.dart';

class CartRepositoryImpl implements CartRepository {
  final CartRemoteDataSource remoteDataSource;
  final CartLocalDataSource localDataSource;

  const CartRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, CartModel>> getCart(String userId) async {
    try {
      final cart = await remoteDataSource.getCart(userId);
      await localDataSource.cacheCart(cart);
      return Right(cart);
    } on DioException catch (e) {
      // Try to get cached cart if network fails
      final cachedCart = await localDataSource.getCachedCart();
      if (cachedCart != null) {
        return Right(cachedCart);
      }
      return Left(ServerFailure(e.message ?? 'Failed to get cart'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CartModel>> addToCart({
    required String userId,
    required String productId,
    required String productName,
    required String productImageUrl,
    required double unitPrice,
    int quantity = 1,
  }) async {
    try {
      final cart = await remoteDataSource.addToCart(
        userId: userId,
        productId: productId,
        productName: productName,
        productImageUrl: productImageUrl,
        unitPrice: unitPrice,
        quantity: quantity,
      );
      await localDataSource.cacheCart(cart);
      return Right(cart);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Failed to add to cart'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CartModel>> updateCartItem({
    required String cartItemId,
    required int quantity,
  }) async {
    try {
      final cart = await remoteDataSource.updateCartItem(cartItemId, quantity);
      await localDataSource.cacheCart(cart);
      return Right(cart);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CartModel>> removeFromCart(String cartItemId) async {
    try {
      final cart = await remoteDataSource.removeFromCart(cartItemId);
      await localDataSource.cacheCart(cart);
      return Right(cart);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearCart(String userId) async {
    try {
      await remoteDataSource.clearCart(userId);
      await localDataSource.clearCart();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}