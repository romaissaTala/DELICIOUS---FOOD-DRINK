part of 'payment_bloc.dart';

abstract class PaymentState extends Equatable {
  const PaymentState();
  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentMethodsLoaded extends PaymentState {
  final List<PaymentMethodModel> methods;
  const PaymentMethodsLoaded(this.methods);
  @override
  List<Object> get props => [methods];
}

class PaymentWebViewRequired extends PaymentState {
  final String checkoutUrl;
  const PaymentWebViewRequired(this.checkoutUrl);
  @override
  List<Object> get props => [checkoutUrl];
}

class PaymentSuccess extends PaymentState {}

class PaymentFailure extends PaymentState {
  final String message;
  const PaymentFailure(this.message);
  @override
  List<Object> get props => [message];
}