import 'package:equatable/equatable.dart';

class PaymentMethodModel extends Equatable {
  final String id;
  final String methodName;
  final String displayName;
  final String instructions;
  final String? iconUrl;
  final bool isActive;
  final int sortOrder;
  
  const PaymentMethodModel({
    required this.id,
    required this.methodName,
    required this.displayName,
    required this.instructions,
    this.iconUrl,
    required this.isActive,
    required this.sortOrder,
  });
  
  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) => PaymentMethodModel(
    id: json['_id'] as String,
    methodName: json['methodName'] as String,
    displayName: json['displayName'] as String,
    instructions: json['instructions'] as String,
    iconUrl: json['iconUrl'] as String?,
    isActive: json['isActive'] as bool? ?? true,
    sortOrder: json['sortOrder'] as int? ?? 0,
  );
  
  Map<String, dynamic> toJson() => {
    '_id': id,
    'methodName': methodName,
    'displayName': displayName,
    'instructions': instructions,
    'iconUrl': iconUrl,
    'isActive': isActive,
    'sortOrder': sortOrder,
  };
  
  @override
  List<Object?> get props => [id, methodName, isActive];
}