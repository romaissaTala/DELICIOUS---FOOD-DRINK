// lib/features/orders/presentation/bloc/tracking_state.dart
part of 'tracking_bloc.dart';

class TrackingState extends Equatable {
  final String?        orderId;
  final OrderTracking? tracking;
  final bool           isLoading;
  final bool           isRefreshing;
  final bool           isSimulating;
  final String?        errorMessage;

  const TrackingState({
    this.orderId,
    this.tracking,
    this.isLoading      = false,
    this.isRefreshing   = false,
    this.isSimulating   = false,
    this.errorMessage,
  });

  OrderStatus get currentStatus =>
      tracking?.currentStatus ?? OrderStatus.placed;

  double get progress => currentStatus.progress;

  bool get hasTracking => tracking != null;

  TrackingState copyWith({
    String?        orderId,
    OrderTracking? tracking,
    bool?          isLoading,
    bool?          isRefreshing,
    bool?          isSimulating,
    String?        errorMessage,
    bool           clearError = false,
  }) =>
      TrackingState(
        orderId:      orderId      ?? this.orderId,
        tracking:     tracking     ?? this.tracking,
        isLoading:    isLoading    ?? this.isLoading,
        isRefreshing: isRefreshing ?? this.isRefreshing,
        isSimulating: isSimulating ?? this.isSimulating,
        errorMessage: clearError   ? null : errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props =>
      [orderId, tracking, isLoading, isRefreshing, isSimulating, errorMessage];
}