import 'package:equatable/equatable.dart';

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
  
  Map<String, dynamic> toJson() => {
    'success': success,
    if (transactionId != null) 'transactionId': transactionId,
    if (orderId != null) 'orderId': orderId,
    if (message != null) 'message': message,
    if (additionalData != null) 'additionalData': additionalData,
  };
  
  @override
  List<Object?> get props => [success, transactionId, orderId, message];
}