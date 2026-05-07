import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/usecases/get_payment_methods_usecase.dart';
import '../../domain/usecases/initiate_payment_usecase.dart';
import '../../domain/usecases/verify_payment_usecase.dart';
import '../../data/models/payment_request_model.dart';
import '../../data/models/payment_method_model.dart';

part 'payment_event.dart';
part 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final GetPaymentMethodsUseCase getPaymentMethods;
  final InitiatePaymentUseCase initiatePayment;
  final VerifyPaymentUseCase verifyPayment;
  
  PaymentBloc({
    required this.getPaymentMethods,
    required this.initiatePayment,
    required this.verifyPayment,
  }) : super(PaymentInitial()) {
    on<GetPaymentMethodsEvent>(_onGetPaymentMethods);
    on<InitiatePaymentEvent>(_onInitiatePayment);
    on<VerifyPaymentEvent>(_onVerifyPayment);
  }
  
  Future<void> _onGetPaymentMethods(
    GetPaymentMethodsEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    final result = await getPaymentMethods();
    result.fold(
      (failure) => emit(PaymentFailure(failure.message)),
      (methods) => emit(PaymentMethodsLoaded(methods)),
    );
  }
  
  Future<void> _onInitiatePayment(
    InitiatePaymentEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    
    final request = PaymentRequestModel(
      orderId: event.orderId,
      orderNumber: event.orderNumber,
      amount: event.amount,
      description: 'Order #${event.orderNumber}',
      customerEmail: event.customerEmail,
      gateway: PaymentGateway.chargily,
      successUrl: 'https://yourapp.com/success',
      failureUrl: 'https://yourapp.com/failure',
    );
    
    final result = await initiatePayment(request);
    
    result.fold(
      (failure) => emit(PaymentFailure(failure.message)),
      (session) {
        final checkoutUrl = session['checkout_url'] as String?;
        if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
          emit(PaymentWebViewRequired(checkoutUrl));
        } else {
          emit(PaymentFailure('Failed to get payment URL'));
        }
      },
    );
  }
  
  Future<void> _onVerifyPayment(
    VerifyPaymentEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    final result = await verifyPayment(event.sessionId);
    result.fold(
      (failure) => emit(PaymentFailure(failure.message)),
      (result) {
        if (result.success) {
          emit(PaymentSuccess());
        } else {
          emit(PaymentFailure(result.message ?? 'Payment verification failed'));
        }
      },
    );
  }
}