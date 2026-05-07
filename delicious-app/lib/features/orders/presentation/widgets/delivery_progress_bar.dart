// lib/features/orders/presentation/widgets/delivery_progress_bar.dart
//
// The animated gradient progress bar — centrepiece of the tracking page.
// Layers:
//   1. Background track   — translucent pill
//   2. Filled track       — gradient, animates to new progress on status change
//   3. Step nodes         — emoji circles that glow when reached/active
//   4. Rider dot          — white pulsing dot riding the fill edge
//   5. Particle burst     — 12-particle explosion at each new node on arrival
//   6. Step labels        — fade/weight-shift as status progresses

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/entities/order_tracking.dart';

class DeliveryProgressBar extends StatefulWidget {
  const DeliveryProgressBar({
    super.key,
    required this.status,
    required this.gradientColors,
    this.height       = 10.0,
    this.nodeSize     = 38.0,
    this.animDuration = const Duration(milliseconds: 950),
  });

  final OrderStatus status;
  final List<Color> gradientColors;
  final double      height;
  final double      nodeSize;
  final Duration    animDuration;

  @override
  State<DeliveryProgressBar> createState() => _DeliveryProgressBarState();
}

class _DeliveryProgressBarState extends State<DeliveryProgressBar>
    with TickerProviderStateMixin {

  late final AnimationController _fillCtrl;
  late       Animation<double>   _fillAnim;

  late final AnimationController _pulseCtrl;
  late final Animation<double>   _pulseAnim;

  late final AnimationController _burstCtrl;
  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();

    _fillCtrl = AnimationController(vsync: this, duration: widget.animDuration);
    _fillAnim = Tween<double>(begin: 0, end: widget.status.progress)
        .animate(CurvedAnimation(parent: _fillCtrl, curve: Curves.easeOutCubic));
    _fillCtrl.forward();

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.55, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _burstCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 720));
  }

  @override
  void didUpdateWidget(DeliveryProgressBar old) {
    super.didUpdateWidget(old);
    if (old.status != widget.status) {
      final from = _fillAnim.value;
      _fillAnim  = Tween<double>(begin: from, end: widget.status.progress)
          .animate(CurvedAnimation(parent: _fillCtrl, curve: Curves.easeOutCubic));
      _fillCtrl..reset()..forward();
      _spawnBurst();
    }
  }

  void _spawnBurst() {
    final rng = math.Random();
    _particles
      ..clear()
      ..addAll(List.generate(14, (_) => _Particle(
            angle: rng.nextDouble() * math.pi * 2,
            speed: 28 + rng.nextDouble() * 42,
            size:  3.5 + rng.nextDouble() * 5.5,
            color: widget.gradientColors[rng.nextBool() ? 0 : 1],
          )));
    _burstCtrl..reset()..forward();
  }

  @override
  void dispose() {
    _fillCtrl.dispose();
    _pulseCtrl.dispose();
    _burstCtrl.dispose();
    super.dispose();
  }

  static const _steps = kTrackingSteps;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_fillCtrl, _pulseCtrl, _burstCtrl]),
      builder: (context, _) {
        final progress = _fillAnim.value;

        return Column(children: [
          // ── Track ───────────────────────────────────────────────
          SizedBox(
            height: widget.nodeSize + 24,
            child: LayoutBuilder(builder: (context, box) {
              final w    = box.maxWidth;
              final step = w / (_steps.length - 1);

              return Stack(clipBehavior: Clip.none, children: [

                // Background track
                Positioned(
                  left: 0, right: 0,
                  top: widget.nodeSize / 2 + 5,
                  child: Container(
                    height: widget.height,
                    decoration: BoxDecoration(
                      color:        Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(widget.height),
                    ),
                  ),
                ),

                // Filled gradient track
                Positioned(
                  left: 0, top: widget.nodeSize / 2 + 5,
                  child: Container(
                    width:  (w * progress).clamp(0.0, w),
                    height: widget.height,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(widget.height),
                      gradient: LinearGradient(
                          colors: widget.gradientColors),
                      boxShadow: [BoxShadow(
                        color:      widget.gradientColors[0].withOpacity(0.55),
                        blurRadius: 14, offset: const Offset(0, 3),
                      )],
                    ),
                  ),
                ),

                // Step nodes
                ..._steps.asMap().entries.map((e) {
                  final i        = e.key;
                  final s        = e.value;
                  final reached  = s.stepIndex <= widget.status.stepIndex;
                  final isActive = s == widget.status;
                  final scale    = isActive
                      ? 1.0 + _pulseAnim.value * 0.12 : 1.0;

                  return Positioned(
                    left: i * step - widget.nodeSize / 2,
                    top: 0,
                    child: Transform.scale(
                      scale: scale,
                      child: _StepNode(
                        status:        s,
                        reached:       reached,
                        isActive:      isActive,
                        size:          widget.nodeSize,
                        colors:        widget.gradientColors,
                        glowIntensity: isActive ? _pulseAnim.value : 0,
                      ),
                    ),
                  );
                }),

                // Rider dot  — glowing white dot at fill edge
                if (!widget.status.isTerminal)
                  Positioned(
                    left: (w * progress - 12).clamp(0.0, w - 24),
                    top:  widget.nodeSize / 2 - 1,
                    child: Opacity(
                      opacity: _pulseAnim.value,
                      child: Container(
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [BoxShadow(
                            color:      widget.gradientColors[0]
                                .withOpacity(0.80),
                            blurRadius: 14, spreadRadius: 2,
                          )],
                        ),
                        child: const Center(
                            child: Text('🛵',
                                style: TextStyle(fontSize: 11))),
                      ),
                    ),
                  ),

                // Delivered checkmark dot
                if (widget.status == OrderStatus.delivered)
                  Positioned(
                    right: -10, top: widget.nodeSize / 2 - 12,
                    child: Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green.shade400,
                        boxShadow: [BoxShadow(
                          color:      Colors.green.withOpacity(0.50),
                          blurRadius: 10,
                        )],
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 14),
                    ),
                  ),

                // Particle burst at active node
                if (_burstCtrl.value > 0)
                  Positioned(
                    left: widget.status.stepIndex * step - widget.nodeSize / 2,
                    top: widget.nodeSize / 2 - widget.nodeSize / 2,
                    child: SizedBox(
                      width:  widget.nodeSize,
                      height: widget.nodeSize,
                      child: CustomPaint(
                        painter: _BurstPainter(
                          particles: _particles,
                          progress:  _burstCtrl.value,
                        ),
                      ),
                    ),
                  ),
              ]);
            }),
          ),

          const SizedBox(height: 18),

          // ── Step labels ─────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _steps.map((s) {
              final reached  = s.stepIndex <= widget.status.stepIndex;
              final isActive = s == widget.status;
              return SizedBox(
                width: 56,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    color: isActive
                        ? Colors.white
                        : reached
                            ? Colors.white.withOpacity(0.60)
                            : Colors.white.withOpacity(0.25),
                    fontSize:   isActive ? 11.0 : 10.0,
                    fontWeight: isActive
                        ? FontWeight.w700 : FontWeight.w400,
                    height: 1.3,
                  ),
                  child: Text(s.label,
                      textAlign: TextAlign.center, maxLines: 2),
                ),
              );
            }).toList(),
          ),
        ]);
      },
    );
  }
}

// ── Step node ─────────────────────────────────────────────────────────────────

class _StepNode extends StatelessWidget {
  const _StepNode({
    required this.status, required this.reached,
    required this.isActive, required this.size,
    required this.colors, required this.glowIntensity,
  });

  final OrderStatus status;
  final bool        reached, isActive;
  final double      size;
  final List<Color> colors;
  final double      glowIntensity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: reached
            ? LinearGradient(colors: colors) : null,
        color:  reached ? null : Colors.white.withOpacity(0.08),
        border: Border.all(
          color: reached
              ? Colors.transparent
              : Colors.white.withOpacity(0.18),
          width: 1.5,
        ),
        boxShadow: isActive && glowIntensity > 0
            ? [
                BoxShadow(
                  color:      colors[0].withOpacity(0.60 * glowIntensity),
                  blurRadius: 20, spreadRadius: 3),
                BoxShadow(
                  color:      Colors.white.withOpacity(0.18 * glowIntensity),
                  blurRadius: 8),
              ]
            : reached
                ? [BoxShadow(
                    color: colors[0].withOpacity(0.30),
                    blurRadius: 8)]
                : null,
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: Text(
            status.emoji,
            key: ValueKey('${status.name}_$reached'),
            style: TextStyle(
              fontSize: size * (reached ? 0.44 : 0.36),
              color: reached ? null : Colors.white.withOpacity(0.25),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Burst painter ─────────────────────────────────────────────────────────────

class _Particle {
  final double angle, speed, size;
  final Color  color;
  const _Particle({required this.angle, required this.speed,
      required this.size, required this.color});
}

class _BurstPainter extends CustomPainter {
  const _BurstPainter({required this.particles, required this.progress});
  final List<_Particle> particles;
  final double          progress;

  @override
  void paint(Canvas canvas, Size size) {
    final cx   = size.width / 2;
    final cy   = size.height / 2;
    final fade = math.sin(progress * math.pi);

    for (final p in particles) {
      final d = p.speed * progress;
      canvas.drawCircle(
        Offset(cx + math.cos(p.angle) * d, cy + math.sin(p.angle) * d),
        (p.size * (1 - progress * 0.55)).clamp(0.5, 20),
        Paint()..color = p.color.withOpacity((fade * 0.85).clamp(0, 1)),
      );
    }
  }

  @override
  bool shouldRepaint(_BurstPainter o) => o.progress != progress;
}