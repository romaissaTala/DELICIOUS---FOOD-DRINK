import 'package:equatable/equatable.dart';

enum OrderStatus {
  placed,
  confirmed,
  preparing,
  onTheWay,
  delivered,
  cancelled,
}

extension OrderStatusExtension on OrderStatus {
  String get value {
    switch (this) {
      case OrderStatus.placed: return 'placed';
      case OrderStatus.confirmed: return 'confirmed';
      case OrderStatus.preparing: return 'preparing';
      case OrderStatus.onTheWay: return 'on_the_way';
      case OrderStatus.delivered: return 'delivered';
      case OrderStatus.cancelled: return 'cancelled';
    }
  }

  static OrderStatus fromString(String value) {
    switch (value) {
      case 'placed': return OrderStatus.placed;
      case 'confirmed': return OrderStatus.confirmed;
      case 'preparing': return OrderStatus.preparing;
      case 'on_the_way': return OrderStatus.onTheWay;
      case 'delivered': return OrderStatus.delivered;
      case 'cancelled': return OrderStatus.cancelled;
      default: return OrderStatus.placed;
    }
  }

  int get progressPercent {
    const steps = {
      OrderStatus.placed: 10,
      OrderStatus.confirmed: 30,
      OrderStatus.preparing: 55,
      OrderStatus.onTheWay: 80,
      OrderStatus.delivered: 100,
      OrderStatus.cancelled: 0,
    };
    return steps[this] ?? 0;
  }
}

class OrderItemModel extends Equatable {
  final String productId;
  final String productName;
  final String productImageUrl;
  final List<String> gradientColors;
  final double unitPrice;
  final int quantity;
  final double subtotal;

  const OrderItemModel({
    required this.productId,
    required this.productName,
    required this.productImageUrl,
    required this.gradientColors,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) => OrderItemModel(
    productId: json['productId'] as String,
    productName: json['productName'] as String,
    productImageUrl: json['productImageUrl'] as String,
    gradientColors: List<String>.from(json['gradientColors'] ?? []),
    unitPrice: (json['unitPrice'] as num).toDouble(),
    quantity: json['quantity'] as int,
    subtotal: (json['subtotal'] as num).toDouble(),
  );

  @override
  List<Object?> get props => [productId, quantity];
}

class OrderModel extends Equatable {
  final String id;
  final String orderNumber;
  final List<OrderItemModel> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String paymentMethod;
  final OrderStatus status;
  final String deliveryAddress;
  final DateTime createdAt;
  final DateTime? deliveredAt;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.paymentMethod,
    required this.status,
    required this.deliveryAddress,
    required this.createdAt,
    this.deliveredAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
    id: json['_id'] as String,
    orderNumber: json['orderNumber'] as String,
    items: (json['items'] as List).map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>)).toList(),
    subtotal: (json['subtotal'] as num).toDouble(),
    deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0,
    total: (json['total'] as num).toDouble(),
    paymentMethod: json['payment']['method'] as String,
    status: OrderStatusExtension.fromString(json['status'] as String),
    deliveryAddress: json['deliveryAddress']['street'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    deliveredAt: json['deliveredAt'] != null ? DateTime.parse(json['deliveredAt'] as String) : null,
  );

  @override
  List<Object?> get props => [id, orderNumber, status, total];
}