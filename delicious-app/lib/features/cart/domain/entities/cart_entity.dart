import 'package:equatable/equatable.dart';

class CartItemEntity extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final String productImageUrl;
  final List<String> gradientColors;
  final String? variantId;
  final String? variantLabel;
  final double unitPrice;
  final int quantity;
  final double subtotal;
  
  const CartItemEntity({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productImageUrl,
    required this.gradientColors,
    this.variantId,
    this.variantLabel,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
  });
  
  @override
  List<Object?> get props => [id, productId, quantity];
}

class CartEntity extends Equatable {
  final String id;
  final String userId;
  final List<CartItemEntity> items;
  final int itemCount;
  final double subtotal;
  final double totalPrice;
  
  const CartEntity({
    required this.id,
    required this.userId,
    required this.items,
    required this.itemCount,
    required this.subtotal,
    required this.totalPrice,
  });
  
  @override
  List<Object?> get props => [id, userId, items.length, totalPrice];
}