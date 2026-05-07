import 'package:equatable/equatable.dart';

class CartItemModel extends Equatable {
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

  const CartItemModel({
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

  factory CartItemModel.fromJson(Map<String, dynamic> json) => CartItemModel(
    id: json['_id'] as String,
    productId: json['productId'] as String,
    productName: json['productName'] as String,
    productImageUrl: json['productImageUrl'] as String,
    gradientColors: List<String>.from(json['gradientColors'] ?? []),
    variantId: json['variantId'] as String?,
    variantLabel: json['variantLabel'] as String?,
    unitPrice: (json['unitPrice'] as num).toDouble(),
    quantity: json['quantity'] as int,
    subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    '_id': id,
    'productId': productId,
    'productName': productName,
    'productImageUrl': productImageUrl,
    'gradientColors': gradientColors,
    'variantId': variantId,
    'variantLabel': variantLabel,
    'unitPrice': unitPrice,
    'quantity': quantity,
    'subtotal': subtotal,
  };

  @override
  List<Object?> get props => [id, productId, quantity];
}

class CartModel extends Equatable {
  final String id;
  final String userId;
  final List<CartItemModel> items;
  final int itemCount;
  final double subtotal;
  final double totalPrice;

  const CartModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.itemCount,
    required this.subtotal,
    required this.totalPrice,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List?)?.map((e) => CartItemModel.fromJson(e as Map<String, dynamic>)).toList() ?? [];
    return CartModel(
      id: json['_id'] as String,
      userId: json['userId'] as String,
      items: itemsList,
      itemCount: json['itemCount'] as int? ?? itemsList.length,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'userId': userId,
    'items': items.map((item) => item.toJson()).toList(),
    'itemCount': itemCount,
    'subtotal': subtotal,
    'totalPrice': totalPrice,
  };

  CartModel copyWith({
    String? id,
    String? userId,
    List<CartItemModel>? items,
    int? itemCount,
    double? subtotal,
    double? totalPrice,
  }) {
    return CartModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      itemCount: itemCount ?? this.itemCount,
      subtotal: subtotal ?? this.subtotal,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }

  @override
  List<Object?> get props => [id, userId, items.length, totalPrice];
}