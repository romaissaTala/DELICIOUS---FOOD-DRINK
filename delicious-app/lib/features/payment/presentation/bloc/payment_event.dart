part of 'payment_bloc.dart';

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();
  @override
  List<Object?> get props => [];
}

class GetPaymentMethodsEvent extends PaymentEvent {
  const GetPaymentMethodsEvent();
}

class InitiatePaymentEvent extends PaymentEvent {
  final String orderId;
  final String orderNumber;
  final double amount;
  final String customerEmail;
  
  const InitiatePaymentEvent({
    required this.orderId,
    required this.orderNumber,
    required this.amount,
    required this.customerEmail,
  });
  
  @override
  List<Object> get props => [orderId, orderNumber, amount, customerEmail];
}

class VerifyPaymentEvent extends PaymentEvent {
  final String sessionId;
  
  const VerifyPaymentEvent(this.sessionId);
  
  @override
  List<Object> get props => [sessionId];
}