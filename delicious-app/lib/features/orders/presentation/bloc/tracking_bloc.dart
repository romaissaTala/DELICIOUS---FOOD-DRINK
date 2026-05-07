// lib/features/orders/presentation/bloc/tracking_bloc.dart
//
// Drives the delivery tracking page.
// In production: polls GET /api/orders/:id every 10 seconds.
// In this file: ships with a built-in simulator so you can
// demo the full animation sequence without a backend.

import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/order_tracking.dart';

part 'tracking_event.dart';
part 'tracking_state.dart';

class TrackingBloc extends Bloc<TrackingEvent, TrackingState> {
  Timer? _pollTimer;
  Timer? _simTimer;

  TrackingBloc() : super(const TrackingState()) {
    on<TrackingStarted>     (_onStarted);
    on<TrackingRefreshed>   (_onRefreshed);
    on<TrackingStatusAdvanced>(_onStatusAdvanced);   // used by simulator
    on<TrackingPolled>      (_onPolled);
    on<TrackingStopped>     (_onStopped);
    on<TrackingSimulateMode>(_onSimulate);
  }

  // ── Start tracking for a given order ─────────────────────────────────────

  Future<void> _onStarted(
    TrackingStarted event,
    Emitter<TrackingState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, orderId: event.orderId));

    // In production: fetch from repository.
    // Here we build a mock order immediately.
    final mock = _mockOrder(event.orderId, event.initialStatus);
    emit(state.copyWith(
      isLoading: false,
      tracking:  mock,
      clearError: true,
    ));

    // Start polling every 10s (no-op in simulator mode)
    _startPolling();
  }

  // ── Refresh (pull to refresh) ─────────────────────────────────────────────

  Future<void> _onRefreshed(
    TrackingRefreshed event,
    Emitter<TrackingState> emit,
  ) async {
    if (state.tracking == null) return;
    emit(state.copyWith(isRefreshing: true));
    await Future.delayed(const Duration(milliseconds: 800));
    emit(state.copyWith(isRefreshing: false));
  }

  // ── Poll tick ─────────────────────────────────────────────────────────────

  Future<void> _onPolled(
    TrackingPolled event,
    Emitter<TrackingState> emit,
  ) async {
    // In production: call repository and emit updated tracking.
    // No-op in this mock implementation.
  }

  // ── Advance status (simulator + manual test) ──────────────────────────────

  Future<void> _onStatusAdvanced(
    TrackingStatusAdvanced event,
    Emitter<TrackingState> emit,
  ) async {
    final current = state.tracking;
    if (current == null || current.currentStatus.isTerminal) return;

    final steps  = kTrackingSteps;
    final idx    = steps.indexOf(current.currentStatus);
    if (idx == -1 || idx >= steps.length - 1) return;

    final next   = steps[idx + 1];
    final newEvent = StatusEvent(status: next, timestamp: DateTime.now());
    final updated = OrderTracking(
      orderId:           current.orderId,
      orderNumber:       current.orderNumber,
      currentStatus:     next,
      history:           [...current.history, newEvent],
      placedAt:          current.placedAt,
      estimatedDelivery: current.estimatedDelivery,
      deliveredAt:       next == OrderStatus.delivered ? DateTime.now() : null,
      restaurantName:    current.restaurantName,
      riderName:         next.stepIndex >= OrderStatus.onTheWay.stepIndex
                             ? 'Karim B.' : null,
      riderPhone:        next.stepIndex >= OrderStatus.onTheWay.stepIndex
                             ? '+213 555 01 23 45' : null,
      address:           current.address,
      items:             current.items,
      totalAmount:       current.totalAmount,
    );

    emit(state.copyWith(tracking: updated));

    if (next.isTerminal) {
      _simTimer?.cancel();
      _pollTimer?.cancel();
    }
  }

  // ── Simulator mode — auto-advance every N seconds ────────────────────────

  Future<void> _onSimulate(
    TrackingSimulateMode event,
    Emitter<TrackingState> emit,
  ) async {
    _simTimer?.cancel();
    emit(state.copyWith(isSimulating: event.enabled));
    if (!event.enabled) return;

    _simTimer = Timer.periodic(
      Duration(seconds: event.intervalSeconds),
      (_) => add(const TrackingStatusAdvanced()),
    );
  }

  // ── Stop ──────────────────────────────────────────────────────────────────

  Future<void> _onStopped(
    TrackingStopped event,
    Emitter<TrackingState> emit,
  ) async {
    _pollTimer?.cancel();
    _simTimer?.cancel();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => add(const TrackingPolled()),
    );
  }

  OrderTracking _mockOrder(String id, OrderStatus initial) {
    final now = DateTime.now();
    final history = kTrackingSteps
        .where((s) => s.stepIndex <= initial.stepIndex)
        .map((s) => StatusEvent(
              status:    s,
              timestamp: now.subtract(
                Duration(minutes: (initial.stepIndex - s.stepIndex) * 8)),
            ))
        .toList();

    return OrderTracking(
      orderId:       id,
      orderNumber:   'DLX-${now.toString().substring(0,10).replaceAll('-','')}-0042',
      currentStatus: initial,
      history:       history,
      placedAt:      now.subtract(const Duration(minutes: 5)),
      estimatedDelivery: now.add(const Duration(minutes: 25)),
      restaurantName: 'Delicious Kitchen',
      riderName:     initial.stepIndex >= OrderStatus.onTheWay.stepIndex
                       ? 'Karim B.' : null,
      riderPhone:    initial.stepIndex >= OrderStatus.onTheWay.stepIndex
                       ? '+213 555 01 23 45' : null,
      address: const DeliveryAddress(
        wilaya:    'Blida',
        commune:   'Blida Centre',
        street:    '12 Rue des Martyrs',
        apartment: 'Apt 3',
      ),
      items: const [
        TrackingItem(name: 'Coca-Cola 330ml', quantity: 2,
            price: 180, emoji: '🥤'),
        TrackingItem(name: 'Couscous Tfaya',  quantity: 1,
            price: 850, emoji: '🫕'),
        TrackingItem(name: 'Baklava Mix',     quantity: 1,
            price: 420, emoji: '🍯'),
      ],
      totalAmount: 1630,
    );
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    _simTimer?.cancel();
    return super.close();
  }
}