// lib/features/orders/domain/entities/order_tracking.dart
import 'package:equatable/equatable.dart';

// ── Order status enum ─────────────────────────────────────────────────────────

enum OrderStatus {
  placed,
  confirmed,
  preparing,
  onTheWay,
  delivered,
  cancelled;

  String get label {
    switch (this) {
      case OrderStatus.placed:    return 'Order Placed';
      case OrderStatus.confirmed: return 'Confirmed';
      case OrderStatus.preparing: return 'Being Prepared';
      case OrderStatus.onTheWay:  return 'On the Way';
      case OrderStatus.delivered: return 'Delivered';
      case OrderStatus.cancelled: return 'Cancelled';
    }
  }

  String get emoji {
    switch (this) {
      case OrderStatus.placed:    return '📋';
      case OrderStatus.confirmed: return '✅';
      case OrderStatus.preparing: return '👨‍🍳';
      case OrderStatus.onTheWay:  return '🛵';
      case OrderStatus.delivered: return '🎉';
      case OrderStatus.cancelled: return '❌';
    }
  }

  String get description {
    switch (this) {
      case OrderStatus.placed:    return 'We received your order';
      case OrderStatus.confirmed: return 'Restaurant confirmed your order';
      case OrderStatus.preparing: return 'Chef is preparing your meal';
      case OrderStatus.onTheWay:  return 'Rider is heading your way';
      case OrderStatus.delivered: return 'Enjoy your meal!';
      case OrderStatus.cancelled: return 'Your order was cancelled';
    }
  }

  // Progress 0.0 → 1.0 along the animated bar
  double get progress {
    switch (this) {
      case OrderStatus.placed:    return 0.05;
      case OrderStatus.confirmed: return 0.25;
      case OrderStatus.preparing: return 0.52;
      case OrderStatus.onTheWay:  return 0.78;
      case OrderStatus.delivered: return 1.00;
      case OrderStatus.cancelled: return 0.00;
    }
  }

  // Index for the step indicator (active steps list)
  int get stepIndex {
    const map = {
      OrderStatus.placed:    0,
      OrderStatus.confirmed: 1,
      OrderStatus.preparing: 2,
      OrderStatus.onTheWay:  3,
      OrderStatus.delivered: 4,
    };
    return map[this] ?? 0;
  }

  bool get isTerminal => this == OrderStatus.delivered ||
                         this == OrderStatus.cancelled;
  bool get isActive   => this != OrderStatus.cancelled;
}

// ── Active status entries (excludes cancelled for the step list) ─────────────
const kTrackingSteps = [
  OrderStatus.placed,
  OrderStatus.confirmed,
  OrderStatus.preparing,
  OrderStatus.onTheWay,
  OrderStatus.delivered,
];

// ── Status event (one entry in the history timeline) ─────────────────────────

class StatusEvent extends Equatable {
  final OrderStatus status;
  final DateTime    timestamp;
  final String?     note;

  const StatusEvent({
    required this.status,
    required this.timestamp,
    this.note,
  });

  @override
  List<Object?> get props => [status, timestamp];
}

// ── Full order tracking model ─────────────────────────────────────────────────

class OrderTracking extends Equatable {
  final String         orderId;
  final String         orderNumber;
  final OrderStatus    currentStatus;
  final List<StatusEvent> history;
  final DateTime       placedAt;
  final DateTime?      estimatedDelivery;
  final DateTime?      deliveredAt;
  final String         restaurantName;
  final String?        riderName;
  final String?        riderPhone;
  final String?        riderAvatarUrl;
  final DeliveryAddress address;
  final List<TrackingItem> items;
  final double         totalAmount;

  const OrderTracking({
    required this.orderId,
    required this.orderNumber,
    required this.currentStatus,
    required this.history,
    required this.placedAt,
    required this.restaurantName,
    required this.address,
    required this.items,
    required this.totalAmount,
    this.estimatedDelivery,
    this.deliveredAt,
    this.riderName,
    this.riderPhone,
    this.riderAvatarUrl,
  });

  int get minutesRemaining {
    if (estimatedDelivery == null) return 0;
    final diff = estimatedDelivery!.difference(DateTime.now());
    return diff.inMinutes.clamp(0, 999);
  }

  bool get isLate => estimatedDelivery != null &&
      DateTime.now().isAfter(estimatedDelivery!) &&
      currentStatus != OrderStatus.delivered;

  @override
  List<Object?> get props => [orderId, currentStatus];
}

class DeliveryAddress extends Equatable {
  final String wilaya;
  final String commune;
  final String street;
  final String? apartment;

  const DeliveryAddress({
    required this.wilaya,
    required this.commune,
    required this.street,
    this.apartment,
  });

  String get full => '$street${apartment != null ? ", $apartment" : ""}, $commune, $wilaya';

  @override
  List<Object?> get props => [wilaya, commune, street];
}

class TrackingItem extends Equatable {
  final String  name;
  final int     quantity;
  final double  price;
  final String? emoji;

  const TrackingItem({
    required this.name,
    required this.quantity,
    required this.price,
    this.emoji,
  });

  @override
  List<Object> get props => [name, quantity, price];
}