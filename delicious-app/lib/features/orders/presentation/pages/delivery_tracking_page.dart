// lib/features/orders/presentation/pages/delivery_tracking_page.dart
//
// The full delivery tracking screen.
// Aesthetic direction: dark glass + neon gradient fills —
// feels like a night-mode premium delivery app.
// The entire page background shifts colour to match the current status.
//
// Sections (top → bottom):
//   1. Animated gradient background (status-reactive)
//   2. AppBar with order number + elapsed time
//   3. Status hero — big emoji + label + description
//   4. DeliveryProgressBar (the centrepiece widget)
//   5. ETA card — countdown + "running late" indicator
//   6. Rider card — avatar, name, call/chat buttons (onTheWay+)
//   7. Order summary — item list + total
//   8. Address card
//   9. History timeline
//  10. Demo controls (simulator — only visible in debug mode)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/order_tracking.dart';
import '../bloc/tracking_bloc.dart';
import '../widgets/delivery_progress_bar.dart';

// ── Status → gradient palette ─────────────────────────────────────────────────
Color _h(String hex) =>
    Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));

const _statusGradients = <OrderStatus, List<String>>{
  OrderStatus.placed:    ['#334155', '#1E293B'],
  OrderStatus.confirmed: ['#1D4ED8', '#2563EB'],
  OrderStatus.preparing: ['#B45309', '#D97706'],
  OrderStatus.onTheWay:  ['#0F766E', '#14B8A6'],
  OrderStatus.delivered: ['#15803D', '#22C55E'],
  OrderStatus.cancelled: ['#7F1D1D', '#DC2626'],
};

List<Color> _gradientFor(OrderStatus s) {
  final hex = _statusGradients[s] ?? ['#FF6B35', '#FF8C61'];
  return [_h(hex[0]), _h(hex[1])];
}

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class DeliveryTrackingPage extends StatefulWidget {
  const DeliveryTrackingPage({
    super.key,
    required this.orderId,
    this.initialStatus = OrderStatus.placed,
    this.showSimControls = true,   // set false in production
  });

  final String      orderId;
  final OrderStatus initialStatus;
  final bool        showSimControls;

  @override
  State<DeliveryTrackingPage> createState() => _DeliveryTrackingPageState();
}

class _DeliveryTrackingPageState extends State<DeliveryTrackingPage>
    with TickerProviderStateMixin {

  // Background gradient animation
  late AnimationController _bgCtrl;
  late Animation<Color?>   _bgAnim1, _bgAnim2;
  List<Color> _fromGrad = [], _toGrad = [];

  // Status hero entrance
  late AnimationController _heroCtrl;
  late Animation<double>   _heroScale, _heroFade;

  // Elapsed time ticker
  late Timer _elapsedTimer;
  Duration   _elapsed = Duration.zero;
  DateTime?  _startTime;

  @override
  void initState() {
    super.initState();

    final initial = _gradientFor(widget.initialStatus);
    _fromGrad = _toGrad = initial;

    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _bgAnim1 = ColorTween(begin: initial[0], end: initial[0])
        .animate(CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOutCubic));
    _bgAnim2 = ColorTween(begin: initial[1], end: initial[1])
        .animate(CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOutCubic));

    _heroCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _heroScale = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOutBack));
    _heroFade  = CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut);

    _startTime = DateTime.now();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsed =
            DateTime.now().difference(_startTime!));
      }
    });

    context.read<TrackingBloc>().add(TrackingStarted(
      orderId:       widget.orderId,
      initialStatus: widget.initialStatus,
    ));

    _heroCtrl.forward();
  }

  void _onStatusChanged(OrderStatus newStatus) {
    final newGrad = _gradientFor(newStatus);
    final fromC1  = _bgAnim1.value ?? _toGrad[0];
    final fromC2  = _bgAnim2.value ?? _toGrad[1];

    _bgAnim1 = ColorTween(begin: fromC1, end: newGrad[0])
        .animate(CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOutCubic));
    _bgAnim2 = ColorTween(begin: fromC2, end: newGrad[1])
        .animate(CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOutCubic));

    _bgCtrl..reset()..forward();
    _heroCtrl..reset()..forward();

    HapticFeedback.heavyImpact();
    _toGrad = newGrad;
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _heroCtrl.dispose();
    _elapsedTimer.cancel();
    context.read<TrackingBloc>().add(const TrackingStopped());
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours > 0 ? '${d.inHours}:' : ''}$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TrackingBloc, TrackingState>(
      listenWhen: (p, c) =>
          p.tracking?.currentStatus != c.tracking?.currentStatus,
      listener: (_, state) {
        if (state.tracking != null) {
          _onStatusChanged(state.tracking!.currentStatus);
        }
      },
      builder: (context, state) {
        return AnimatedBuilder(
          animation: _bgCtrl,
          builder: (context, child) {
            final c1 = _bgAnim1.value ?? _toGrad[0];
            final c2 = _bgAnim2.value ?? _toGrad[1];

            return Scaffold(
              backgroundColor: Colors.transparent,
              extendBodyBehindAppBar: true,
              body: Stack(fit: StackFit.expand, children: [
                // ── Animated background ──────────────────────────
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end:   Alignment.bottomRight,
                      colors: [
                        c1,
                        Color.lerp(c1, c2, 0.55)!,
                        const Color(0xFF080810),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
                // Radial top glow
                Positioned(
                  top: -80, left: -60,
                  child: Container(
                    width: 300, height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        Colors.white.withOpacity(0.12),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),
                // Page content
                child!,
              ]),
            );
          },
          child: state.isLoading
              ? const _LoadingView()
              : state.tracking == null
                  ? const _ErrorView()
                  : _TrackingContent(
                      tracking:        state.tracking!,
                      elapsed:         _elapsed,
                      fmtElapsed:      _fmt,
                      heroScale:       _heroScale,
                      heroFade:        _heroFade,
                      gradientColors:  _gradientFor(
                          state.tracking!.currentStatus),
                      showSimControls: widget.showSimControls,
                    ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main scrollable content
// ─────────────────────────────────────────────────────────────────────────────

class _TrackingContent extends StatelessWidget {
  const _TrackingContent({
    required this.tracking,
    required this.elapsed,
    required this.fmtElapsed,
    required this.heroScale,
    required this.heroFade,
    required this.gradientColors,
    required this.showSimControls,
  });

  final OrderTracking      tracking;
  final Duration           elapsed;
  final String Function(Duration) fmtElapsed;
  final Animation<double>  heroScale, heroFade;
  final List<Color>        gradientColors;
  final bool               showSimControls;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [

        // ── AppBar ───────────────────────────────────────────────
        SliverAppBar(
          backgroundColor: Colors.transparent,
          elevation:       0,
          pinned:          true,
          expandedHeight:  0,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:        Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.20)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tracking.orderNumber,
                style: const TextStyle(
                  color: Colors.white, fontSize: 15,
                  fontWeight: FontWeight.w800, letterSpacing: -0.3)),
              Text('Elapsed ${fmtElapsed(elapsed)}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.50), fontSize: 11)),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color:        Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.20)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 7, height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tracking.currentStatus.isTerminal
                        ? Colors.grey : Colors.green.shade400,
                    boxShadow: tracking.currentStatus.isTerminal
                        ? null
                        : [BoxShadow(
                            color:      Colors.green.shade400,
                            blurRadius: 6, spreadRadius: 1)],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  tracking.currentStatus.isTerminal ? 'Done' : 'Live',
                  style: const TextStyle(
                    color: Colors.white, fontSize: 11,
                    fontWeight: FontWeight.w700)),
              ]),
            ),
          ],
        ),

        SliverToBoxAdapter(child: Column(children: [
          const SizedBox(height: 16),

          // ── Status hero ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _StatusHero(
              tracking:  tracking,
              heroScale: heroScale,
              heroFade:  heroFade,
              gradients: gradientColors,
            ),
          ),

          const SizedBox(height: 32),

          // ── Progress bar ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: DeliveryProgressBar(
              status:         tracking.currentStatus,
              gradientColors: gradientColors,
            ),
          ),

          const SizedBox(height: 28),

          // ── ETA card ─────────────────────────────────────────
          if (tracking.currentStatus.isActive &&
              tracking.currentStatus != OrderStatus.delivered)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _EtaCard(tracking: tracking, gradients: gradientColors),
            ),

          const SizedBox(height: 16),

          // ── Rider card ───────────────────────────────────────
          if (tracking.riderName != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _RiderCard(tracking: tracking),
            ),

          const SizedBox(height: 16),

          // ── Order summary ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _OrderSummaryCard(tracking: tracking),
          ),

          const SizedBox(height: 16),

          // ── Address ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _AddressCard(tracking: tracking),
          ),

          const SizedBox(height: 16),

          // ── History timeline ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _HistoryTimeline(tracking: tracking,
                gradients: gradientColors),
          ),

          // ── Sim controls (debug) ─────────────────────────────
          if (showSimControls)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _SimControls(gradients: gradientColors),
            ),

          const SizedBox(height: 48),
        ])),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status hero  — large emoji + animated label
// ─────────────────────────────────────────────────────────────────────────────

class _StatusHero extends StatelessWidget {
  const _StatusHero({
    required this.tracking, required this.heroScale,
    required this.heroFade, required this.gradients,
  });
  final OrderTracking tracking;
  final Animation<double> heroScale, heroFade;
  final List<Color> gradients;

  @override
  Widget build(BuildContext context) {
    final s = tracking.currentStatus;
    return FadeTransition(
      opacity: heroFade,
      child: ScaleTransition(
        scale: heroScale,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color:        Colors.white.withOpacity(0.08),
            border: Border.all(color: Colors.white.withOpacity(0.14)),
            boxShadow: [BoxShadow(
              color:      gradients[0].withOpacity(0.20),
              blurRadius: 40,
            )],
          ),
          child: Row(children: [
            // Big emoji
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    gradients[0].withOpacity(0.60),
                    gradients[1].withOpacity(0.40),
                  ],
                ),
                border: Border.all(
                    color: gradients[0].withOpacity(0.50), width: 1.5),
              ),
              child: Center(
                child: Text(s.emoji,
                    style: const TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.label,
                  style: const TextStyle(
                    color: Colors.white, fontSize: 22,
                    fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text(s.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.60), fontSize: 13.5)),
                if (tracking.isLate) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color:        Colors.orange.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.orange.withOpacity(0.50)),
                    ),
                    child: const Text('Running late',
                      style: TextStyle(
                        color: Colors.orange, fontSize: 11,
                        fontWeight: FontWeight.w700)),
                  ),
                ],
              ],
            )),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ETA Card  — live countdown
// ─────────────────────────────────────────────────────────────────────────────

class _EtaCard extends StatefulWidget {
  const _EtaCard({required this.tracking, required this.gradients});
  final OrderTracking tracking;
  final List<Color>   gradients;

  @override
  State<_EtaCard> createState() => _EtaCardState();
}

class _EtaCardState extends State<_EtaCard> {
  late Timer _timer;
  int _remaining = 0;

  @override
  void initState() {
    super.initState();
    _update();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(_update);
    });
  }

  void _update() {
    _remaining = widget.tracking.minutesRemaining;
  }

  @override
  void dispose() { _timer.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(colors: widget.gradients),
          ),
          child: const Center(child: Text('⏱️',
              style: TextStyle(fontSize: 22))),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Estimated Arrival',
              style: TextStyle(
                color: Colors.white.withOpacity(0.55), fontSize: 11.5,
                fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _remaining <= 0 ? 'Any moment now!' : '$_remaining min',
                key: ValueKey(_remaining),
                style: const TextStyle(
                  color: Colors.white, fontSize: 22,
                  fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            ),
          ],
        )),
        if (widget.tracking.isLate)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:        Colors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: Colors.orange, size: 20),
          ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rider Card
// ─────────────────────────────────────────────────────────────────────────────

class _RiderCard extends StatelessWidget {
  const _RiderCard({required this.tracking});
  final OrderTracking tracking;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Row(children: [
        // Avatar
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:  Colors.white.withOpacity(0.15),
            border: Border.all(color: Colors.white.withOpacity(0.30)),
          ),
          child: const Center(child: Text('🧑‍🦱',
              style: TextStyle(fontSize: 26))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your rider',
              style: TextStyle(
                color: Colors.white.withOpacity(0.50), fontSize: 11)),
            const SizedBox(height: 2),
            Text(tracking.riderName!,
              style: const TextStyle(
                color: Colors.white, fontSize: 16,
                fontWeight: FontWeight.w700)),
          ],
        )),
        // Action buttons
        Row(children: [
          _CircleBtn(
            icon: Icons.call_rounded,
            onTap: () => HapticFeedback.lightImpact(),
          ),
          const SizedBox(width: 10),
          _CircleBtn(
            icon: Icons.chat_bubble_outline_rounded,
            onTap: () => HapticFeedback.lightImpact(),
          ),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Order summary
// ─────────────────────────────────────────────────────────────────────────────

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({required this.tracking});
  final OrderTracking tracking;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _CardLabel(label: 'Order Summary', icon: '🧾'),
        const SizedBox(height: 12),
        ...tracking.items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            Text(item.emoji ?? '🍽️',
                style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                  style: const TextStyle(
                    color: Colors.white, fontSize: 13.5,
                    fontWeight: FontWeight.w600)),
                Text('×${item.quantity}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45), fontSize: 11.5)),
              ],
            )),
            Text('${(item.price * item.quantity).toStringAsFixed(0)} DA',
              style: const TextStyle(
                color: Colors.white, fontSize: 13.5,
                fontWeight: FontWeight.w700)),
          ]),
        )),
        Container(
          height: 0.5,
          color: Colors.white.withOpacity(0.12),
          margin: const EdgeInsets.symmetric(vertical: 10),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total',
              style: TextStyle(
                color: Colors.white.withOpacity(0.65), fontSize: 13)),
            Text('${tracking.totalAmount.toStringAsFixed(0)} DA',
              style: const TextStyle(
                color: Colors.white, fontSize: 18,
                fontWeight: FontWeight.w800, letterSpacing: -0.3)),
          ],
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Address card
// ─────────────────────────────────────────────────────────────────────────────

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.tracking});
  final OrderTracking tracking;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color:        Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(child: Text('📍',
              style: TextStyle(fontSize: 20))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delivery Address',
              style: TextStyle(
                color: Colors.white.withOpacity(0.50), fontSize: 11)),
            const SizedBox(height: 2),
            Text(tracking.address.full,
              style: const TextStyle(
                color: Colors.white, fontSize: 13.5,
                fontWeight: FontWeight.w600, height: 1.4)),
          ],
        )),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// History timeline
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryTimeline extends StatelessWidget {
  const _HistoryTimeline({required this.tracking, required this.gradients});
  final OrderTracking tracking;
  final List<Color>   gradients;

  String _fmtTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final events = tracking.history.reversed.toList();
    return _GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _CardLabel(label: 'Activity', icon: '📜'),
        const SizedBox(height: 14),
        ...events.asMap().entries.map((e) {
          final i     = e.key;
          final ev    = e.value;
          final isLast = i == events.length - 1;
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Timeline line + dot
                SizedBox(width: 28, child: Column(children: [
                  Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: i == 0
                          ? LinearGradient(colors: gradients) : null,
                      color: i == 0 ? null : Colors.white.withOpacity(0.15),
                      border: Border.all(
                        color: i == 0
                            ? Colors.transparent
                            : Colors.white.withOpacity(0.20),
                        width: 1.5,
                      ),
                    ),
                    child: Center(child: Text(ev.status.emoji,
                        style: const TextStyle(fontSize: 10))),
                  ),
                  if (!isLast) Expanded(child: Center(
                    child: Container(
                      width: 1.5,
                      color: Colors.white.withOpacity(0.12),
                    ),
                  )),
                ])),
                const SizedBox(width: 12),
                Expanded(child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(ev.status.label,
                        style: TextStyle(
                          color: i == 0
                              ? Colors.white
                              : Colors.white.withOpacity(0.55),
                          fontSize: 13.5,
                          fontWeight: i == 0
                              ? FontWeight.w700 : FontWeight.w400)),
                      Text(_fmtTime(ev.timestamp),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.35),
                          fontSize: 11.5,
                          fontFamily: 'monospace')),
                    ],
                  ),
                )),
              ],
            ),
          );
        }),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Simulator controls  — for demo / debug
// ─────────────────────────────────────────────────────────────────────────────

class _SimControls extends StatefulWidget {
  const _SimControls({required this.gradients});
  final List<Color> gradients;

  @override
  State<_SimControls> createState() => _SimControlsState();
}

class _SimControlsState extends State<_SimControls> {
  bool _simRunning = false;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('🧪', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          const Text('Demo Controls',
            style: TextStyle(
              color: Colors.white, fontSize: 14,
              fontWeight: FontWeight.w700)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color:        Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('DEBUG',
              style: TextStyle(
                color: Colors.white38, fontSize: 9,
                fontWeight: FontWeight.w700, letterSpacing: 1)),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _SimBtn(
            label: 'Next Step',
            icon:  Icons.skip_next_rounded,
            onTap: () => context.read<TrackingBloc>()
                .add(const TrackingStatusAdvanced()),
            colors: widget.gradients,
          )),
          const SizedBox(width: 10),
          Expanded(child: _SimBtn(
            label: _simRunning ? 'Stop Auto' : 'Auto (3s)',
            icon:  _simRunning
                ? Icons.stop_rounded : Icons.play_arrow_rounded,
            onTap: () {
              setState(() => _simRunning = !_simRunning);
              context.read<TrackingBloc>().add(
                  TrackingSimulateMode(enabled: _simRunning));
            },
            colors: _simRunning
                ? [Colors.red.shade700, Colors.red.shade400]
                : widget.gradients,
          )),
        ]),
      ]),
    );
  }
}

class _SimBtn extends StatelessWidget {
  const _SimBtn({
    required this.label, required this.icon,
    required this.onTap, required this.colors,
  });
  final String     label;
  final IconData   icon;
  final VoidCallback onTap;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(colors: colors),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(
            color: Colors.white, fontSize: 13,
            fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared micro-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:        Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 0.8),
        boxShadow: [BoxShadow(
          color:      Colors.black.withOpacity(0.18),
          blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: child,
    );
  }
}

class _CardLabel extends StatelessWidget {
  const _CardLabel({required this.label, required this.icon});
  final String label, icon;

  @override
  Widget build(BuildContext context) => Row(children: [
    Text(icon, style: const TextStyle(fontSize: 14)),
    const SizedBox(width: 8),
    Text(label, style: TextStyle(
      color: Colors.white.withOpacity(0.55), fontSize: 12,
      fontWeight: FontWeight.w600, letterSpacing: 0.5)),
  ]);
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({required this.icon, required this.onTap});
  final IconData     icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:  Colors.white.withOpacity(0.12),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    ),
  );
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Colors.transparent,
    body: Center(child: CircularProgressIndicator(
        color: Colors.white54, strokeWidth: 2)),
  );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    body: Center(child: Text('Unable to load tracking',
        style: TextStyle(color: Colors.white.withOpacity(0.60)))),
  );
}