import 'package:Delicious_App/features/cart/data/models/cart_models.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/cart_entity.dart';
import '../../domain/usecases/get_cart_usecase.dart';
import '../../domain/usecases/add_to_cart_usecase.dart';
import '../../domain/usecases/remove_from_cart_usecase.dart';
import '../../domain/usecases/update_cart_item_usecase.dart';
import '../../domain/usecases/clear_cart_usecase.dart';

part 'cart_event.dart';
part 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final GetCartUseCase getCart;
  final AddToCartUseCase addToCart;
  final RemoveFromCartUseCase removeFromCart;
  final UpdateCartItemUseCase updateCartItem;
  final ClearCartUseCase clearCart;
  
  CartBloc({
    required this.getCart,
    required this.addToCart,
    required this.removeFromCart,
    required this.updateCartItem,
    required this.clearCart,
  }) : super(CartInitial()) {
    on<LoadCart>(_onLoadCart);
    on<AddToCartEvent>(_onAddToCart);
    on<RemoveFromCartEvent>(_onRemoveFromCart);
    on<UpdateCartItemEvent>(_onUpdateCartItem);
    on<ClearCartEvent>(_onClearCart);
  }
  
  Future<void> _onLoadCart(LoadCart event, Emitter<CartState> emit) async {
    emit(CartLoading());
    final result = await getCart(event.userId);
    result.fold(
      (failure) => emit(CartError(_mapFailureToMessage(failure))),
      (cart) => emit(CartLoaded(cart)),
    );
  }
  
  Future<void> _onAddToCart(AddToCartEvent event, Emitter<CartState> emit) async {
    emit(CartLoading());
    final result = await addToCart(
      userId: event.userId,
      productId: event.productId,
      productName: event.productName,
      productImageUrl: event.productImageUrl,
      unitPrice: event.unitPrice,
      quantity: event.quantity,
    );
    result.fold(
      (failure) => emit(CartError(_mapFailureToMessage(failure))),
      (cart) => emit(CartItemAdded(cart)),
    );
  }
  
  Future<void> _onRemoveFromCart(RemoveFromCartEvent event, Emitter<CartState> emit) async {
    emit(CartLoading());
    final result = await removeFromCart(event.cartItemId);
    result.fold(
      (failure) => emit(CartError(_mapFailureToMessage(failure))),
      (cart) => emit(CartItemRemoved(cart)),
    );
  }
  
  Future<void> _onUpdateCartItem(UpdateCartItemEvent event, Emitter<CartState> emit) async {
    emit(CartLoading());
    final result = await updateCartItem(
      cartItemId: event.cartItemId,
      quantity: event.quantity,
    );
    result.fold(
      (failure) => emit(CartError(_mapFailureToMessage(failure))),
      (cart) => emit(CartLoaded(cart)),
    );
  }
  
  Future<void> _onClearCart(ClearCartEvent event, Emitter<CartState> emit) async {
    emit(CartLoading());
    final result = await clearCart(event.userId);
    result.fold(
      (failure) => emit(CartError(_mapFailureToMessage(failure))),
      (_) => emit(CartCleared()),
    );
  }
  
  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) return failure.message;
    if (failure is NetworkFailure) return 'No internet connection';
    return 'An unexpected error occurred';
  }
}