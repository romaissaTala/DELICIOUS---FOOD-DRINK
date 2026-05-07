part of 'cart_bloc.dart';

abstract class CartState extends Equatable {
  const CartState();
  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {}

class CartLoading extends CartState {}

class CartLoaded extends CartState {
  final CartModel cart;
  const CartLoaded(this.cart);
  @override
  List<Object> get props => [cart];
}

class CartError extends CartState {
  final String message;
  const CartError(this.message);
  @override
  List<Object> get props => [message];
}

class CartItemAdded extends CartState {
  final CartModel cart;
  const CartItemAdded(this.cart);
  @override
  List<Object> get props => [cart];
}

class CartItemRemoved extends CartState {
  final CartModel cart;
  const CartItemRemoved(this.cart);
  @override
  List<Object> get props => [cart];
}

class CartCleared extends CartState {}