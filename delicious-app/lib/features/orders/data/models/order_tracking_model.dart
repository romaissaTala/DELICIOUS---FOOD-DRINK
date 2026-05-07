import 'package:equatable/equatable.dart';

class OrderTrackingModel extends Equatable {
  final String orderId;
  final String status;
  final int progressPercent;
  final DateTime? estimatedDelivery;
  final List<TrackingEvent> events;
  
  const OrderTrackingModel({
    required this.orderId,
    required this.status,
    required this.progressPercent,
    this.estimatedDelivery,
    required this.events,
  });
  
  factory OrderTrackingModel.fromJson(Map<String, dynamic> json) => OrderTrackingModel(
    orderId: json['orderId'] as String,
    status: json['status'] as String,
    progressPercent: json['progressPercent'] as int,
    estimatedDelivery: json['estimatedDelivery'] != null 
        ? DateTime.parse(json['estimatedDelivery'] as String) 
        : null,
    events: (json['events'] as List?)
        ?.map((e) => TrackingEvent.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
  );
  
  @override
  List<Object?> get props => [orderId, status, progressPercent];
}

class TrackingEvent extends Equatable {
  final String status;
  final DateTime timestamp;
  final String? note;
  
  const TrackingEvent({
    required this.status,
    required this.timestamp,
    this.note,
  });
  
  factory TrackingEvent.fromJson(Map<String, dynamic> json) => TrackingEvent(
    status: json['status'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    note: json['note'] as String?,
  );
  
  @override
  List<Object?> get props => [status, timestamp];
}