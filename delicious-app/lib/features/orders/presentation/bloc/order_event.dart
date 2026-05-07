part of 'order_bloc.dart';

abstract class OrderEvent extends Equatable {
  const OrderEvent();
  @override
  List<Object?> get props => [];
}

class PlaceOrderEvent extends OrderEvent {
  final Map<String, dynamic> orderData;
  const PlaceOrderEvent(this.orderData);
  @override
  List<Object> get props => [orderData];
}

class GetOrdersEvent extends OrderEvent {
  final String userId;
  const GetOrdersEvent(this.userId);
  @override
  List<Object> get props => [userId];
}

class GetOrderByIdEvent extends OrderEvent {
  final String orderId;
  const GetOrderByIdEvent(this.orderId);
  @override
  List<Object> get props => [orderId];
}