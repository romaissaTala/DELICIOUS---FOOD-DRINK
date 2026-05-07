// lib/features/orders/presentation/bloc/tracking_event.dart
part of 'tracking_bloc.dart';

abstract class TrackingEvent extends Equatable {
  const TrackingEvent();
  @override
  List<Object?> get props => [];
}

class TrackingStarted extends TrackingEvent {
  final String      orderId;
  final OrderStatus initialStatus;
  const TrackingStarted({
    required this.orderId,
    this.initialStatus = OrderStatus.placed,
  });
  @override
  List<Object> get props => [orderId, initialStatus];
}

class TrackingRefreshed extends TrackingEvent {
  const TrackingRefreshed();
}

class TrackingPolled extends TrackingEvent {
  const TrackingPolled();
}

/// Advance to next status — used by the demo simulator and unit tests.
class TrackingStatusAdvanced extends TrackingEvent {
  const TrackingStatusAdvanced();
}

class TrackingStopped extends TrackingEvent {
  const TrackingStopped();
}

class TrackingSimulateMode extends TrackingEvent {
  final bool enabled;
  final int  intervalSeconds;
  const TrackingSimulateMode({
    required this.enabled,
    this.intervalSeconds = 3,
  });
  @override
  List<Object> get props => [enabled, intervalSeconds];
}