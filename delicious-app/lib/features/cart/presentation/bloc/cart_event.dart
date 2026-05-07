part of 'cart_bloc.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();
  @override
  List<Object?> get props => [];
}

class LoadCart extends CartEvent {
  final String userId;
  const LoadCart(this.userId);
  @override
  List<Object> get props => [userId];
}

class AddToCartEvent extends CartEvent {
  final String userId;
  final String productId;
  final String productName;
  final String productImageUrl;
  final double unitPrice;
  final int quantity;
  final List<String> gradientColors;
  
  const AddToCartEvent({
    required this.userId,
    required this.productId,
    required this.productName,
    required this.productImageUrl,
    required this.unitPrice,
    this.quantity = 1,
    this.gradientColors = const [],
  });
  
  @override
  List<Object> get props => [userId, productId, quantity];
}

class RemoveFromCartEvent extends CartEvent {
  final String cartItemId;
  const RemoveFromCartEvent(this.cartItemId);
  @override
  List<Object> get props => [cartItemId];
}

class UpdateCartItemEvent extends CartEvent {
  final String cartItemId;
  final int quantity;
  const UpdateCartItemEvent({required this.cartItemId, required this.quantity});
  @override
  List<Object> get props => [cartItemId, quantity];
}

class ClearCartEvent extends CartEvent {
  final String userId;
  const ClearCartEvent(this.userId);
  @override
  List<Object> get props => [userId];
}