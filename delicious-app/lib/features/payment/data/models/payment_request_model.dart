import 'package:equatable/equatable.dart';

enum PaymentGateway {
  chargily,   // EDAHABIA / CIB (Algeria)
  stripe,     // International cards (for learning)
  ccp,        // Manual CCP transfer
  dzmobpay,   // QR code (coming soon)
}

class PaymentRequestModel extends Equatable {
  final String orderId;
  final String orderNumber;
  final double amount;
  final String currency;
  final String description;
  final String customerEmail;
  final String? customerName;
  final String? customerPhone;
  final PaymentGateway gateway;
  final String successUrl;
  final String failureUrl;
  
  const PaymentRequestModel({
    required this.orderId,
    required this.orderNumber,
    required this.amount,
    this.currency = 'dzd',
    required this.description,
    required this.customerEmail,
    this.customerName,
    this.customerPhone,
    required this.gateway,
    required this.successUrl,
    required this.failureUrl,
  });
  
  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'orderNumber': orderNumber,
    'amount': amount,
    'currency': currency,
    'description': description,
    'customerEmail': customerEmail,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'gateway': gateway.name,
    'successUrl': successUrl,
    'failureUrl': failureUrl,
  };
  
  @override
  List<Object?> get props => [orderId, amount, gateway];
}

class PaymentResultModel extends Equatable {
  final bool success;
  final String? transactionId;
  final String? orderId;
  final String? message;
  final Map<String, dynamic>? additionalData;
  
  const PaymentResultModel({
    required this.success,
    this.transactionId,
    this.orderId,
    this.message,
    this.additionalData,
  });
  
  factory PaymentResultModel.fromJson(Map<String, dynamic> json) => PaymentResultModel(
    success: json['success'] as bool,
    transactionId: json['transactionId'] as String?,
    orderId: json['orderId'] as String?,
    message: json['message'] as String?,
    additionalData: json['additionalData'] as Map<String, dynamic>?,
  );
  
  @override
  List<Object?> get props => [success, transactionId, orderId];
}