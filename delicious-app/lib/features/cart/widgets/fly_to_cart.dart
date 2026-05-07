// lib/features/cart/presentation/widgets/fly_to_cart.dart
//
// Fly-to-cart animation system for the Delicious app.
//
// How it works:
//   1. A product image thumbnail is captured at its screen position.
//   2. An overlay is inserted above everything else via an OverlayEntry.
//   3. The thumbnail flies along a cubic Bézier arc toward the cart icon,
//      shrinking and fading as it arrives.
//   4. On arrival the cart icon does a bounce + badge-count pulse.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public API
// ─────────────────────────────────────────────────────────────────────────────

class FlyToCart {
  /// Launch a flying particle from [sourceRect] toward the widget identified
  /// by [cartKey]. Calls [onComplete] when the particle reaches the target.
  static void launch({
    required BuildContext   context,
    required Rect           sourceRect,
    required GlobalKey      cartKey,
    required Color          productColor,
    ImageProvider?          productImage,
    String?                 productEmoji,
    VoidCallback?           onComplete,
  }) {
    // Resolve the cart icon's current position on screen
    final cartBox = cartKey.currentContext?.findRenderObject() as RenderBox?;
    if (cartBox == null) return;
    final cartRect = cartBox.localToGlobal(Offset.zero) & cartBox.size;

    OverlayEntry? entry;
    entry = OverlayEntry(
      builder: (_) => _FlyingParticleOverlay(
        sourceRect:   sourceRect,
        targetRect:   cartRect,
        productColor: productColor,
        productImage: productImage,
        productEmoji: productEmoji,
        onComplete: () {
          entry?.remove();
          onComplete?.call();
        },
      ),
    );
    Overlay.of(context).insert(entry);
    HapticFeedback.lightImpact();
  }

  /// Helper: get the screen Rect of a widget by its GlobalKey.
  static Rect rectOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return Rect.zero;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overlay  — renders the particle and drives its animation
// ─────────────────────────────────────────────────────────────────────────────

class _FlyingParticleOverlay extends StatefulWidget {
  const _FlyingParticleOverlay({
    required this.sourceRect,
    required this.targetRect,
    required this.productColor,
    required this.onComplete,
    this.productImage,
    this.productEmoji,
  });

  final Rect          sourceRect;
  final Rect          targetRect;
  final Color         productColor;
  final ImageProvider? productImage;
  final String?        productEmoji;
  final VoidCallback   onComplete;

  @override
  State<_FlyingParticleOverlay> createState() =>
      _FlyingParticleOverlayState();
}

class _FlyingParticleOverlayState extends State<_FlyingParticleOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // ── Particle position along cubic Bézier ─────────────────────────────────
  late final Animation<double> _progress;   // 0 → 1 along the path
  late final Animation<double> _scale;      // 1 → 0.15 (shrinks to cart size)
  late final Animation<double> _opacity;    // 1 → 0 in the final 15%
  late final Animation<double> _rotation;  // gentle tumble

  // Bézier control points (computed once)
  late final Offset _p0;   // start  = centre of source
  late final Offset _p3;   // end    = centre of target (cart icon)
  late final Offset _p1;   // ctrl 1 = up-and-slightly-toward-target
  late final Offset _p2;   // ctrl 2 = just before target, coming from above

  // Trail particles for sparkle effect
  // ✅ FIXED: Not final - can be modified in initState
  late List<_TrailParticle> _trail;  // Changed from final to late

  @override
  void initState() {
    super.initState();

    _p0 = widget.sourceRect.center;
    _p3 = widget.targetRect.center;

    // Arc control points: lift up above mid-screen then sweep down to cart
    final dx  = _p3.dx - _p0.dx;
    final dy  = _p3.dy - _p0.dy;
    final mid = Offset(_p0.dx + dx * 0.25, _p0.dy - 180);  // high arc
    _p1 = mid;
    _p2 = Offset(_p3.dx - dx * 0.15, _p3.dy - 60);

    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 680),
    );

    final curved = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);

    _progress = curved;
    _scale    = Tween<double>(begin: 1.0, end: 0.18)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _opacity  = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 80),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_ctrl);
    _rotation = Tween<double>(begin: 0.0, end: 0.35)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

    // ✅ FIXED: Initialize _trail here (not final, so can be assigned)
    _trail = List.generate(6, (i) => _TrailParticle(
      delay:  i * 0.08,
      color:  widget.productColor,
      size:   8.0 - i * 0.8,
      offset: Offset(
        (math.Random().nextDouble() - 0.5) * 18,
        (math.Random().nextDouble() - 0.5) * 18,
      ),
    ));

    _ctrl.forward().then((_) {
      HapticFeedback.mediumImpact();
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Cubic Bézier: B(t) = (1-t)³P0 + 3(1-t)²tP1 + 3(1-t)t²P2 + t³P3
  Offset _bezier(double t) {
    final mt  = 1 - t;
    final mt2 = mt * mt;
    final t2  = t * t;
    return Offset(
      mt2 * mt * _p0.dx + 3 * mt2 * t * _p1.dx +
          3 * mt * t2 * _p2.dx + t2 * t * _p3.dx,
      mt2 * mt * _p0.dy + 3 * mt2 * t * _p1.dy +
          3 * mt * t2 * _p2.dy + t2 * t * _p3.dy,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.sourceRect.shortestSide;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t   = _progress.value;
        final pos = _bezier(t);

        return Stack(
          children: [
            // ── Trail sparkles ───────────────────────────────────────
            ..._trail.map((tp) {
              final trailT = (t - tp.delay).clamp(0.0, 1.0);
              if (trailT == 0) return const SizedBox.shrink();
              final trailPos = _bezier(trailT);
              final trailOpacity = (1.0 - trailT) * 0.7;
              final trailScale   = (1.0 - trailT) * 0.6;
              return Positioned(
                left: trailPos.dx + tp.offset.dx - tp.size / 2,
                top:  trailPos.dy + tp.offset.dy - tp.size / 2,
                child: Opacity(
                  opacity: trailOpacity.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: trailScale,
                    child: Container(
                      width: tp.size, height: tp.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: tp.color.withOpacity(0.85),
                        boxShadow: [
                          BoxShadow(
                            color:      tp.color.withOpacity(0.5),
                            blurRadius: tp.size,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),

            // ── Main flying particle ─────────────────────────────────
            Positioned(
              left: pos.dx - (size * _scale.value) / 2,
              top:  pos.dy - (size * _scale.value) / 2,
              child: Opacity(
                opacity: _opacity.value,
                child: Transform.rotate(
                  angle: _rotation.value * math.pi * 2,
                  child: _Particle(
                    size:         size * _scale.value,
                    color:        widget.productColor,
                    image:        widget.productImage,
                    emoji:        widget.productEmoji,
                    shadowRadius: 20 * _scale.value,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// The particle visual — rounded thumbnail with colour glow
// ─────────────────────────────────────────────────────────────────────────────

class _Particle extends StatelessWidget {
  const _Particle({
    required this.size,
    required this.color,
    required this.shadowRadius,
    this.image,
    this.emoji,
  });

  final double        size;
  final Color         color;
  final double        shadowRadius;
  final ImageProvider? image;
  final String?        emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        color:   color,
        border:  Border.all(color: Colors.white.withOpacity(0.50), width: 1.5),
        boxShadow: [
          BoxShadow(
            color:      color.withOpacity(0.70),
            blurRadius: shadowRadius,
            spreadRadius: shadowRadius * 0.2,
          ),
          BoxShadow(
            color:      Colors.white.withOpacity(0.20),
            blurRadius: shadowRadius * 0.5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.26),
        child: image != null
            ? Image(image: image!, fit: BoxFit.cover)
            : emoji != null
                ? Center(child: Text(emoji!,
                    style: TextStyle(fontSize: size * 0.50)))
                : _ColourFill(color: color),
      ),
    );
  }
}

class _ColourFill extends StatelessWidget {
  const _ColourFill({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: RadialGradient(colors: [
        Color.lerp(color, Colors.white, 0.30)!,
        color,
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Trail particle data
// ─────────────────────────────────────────────────────────────────────────────

class _TrailParticle {
  final double delay;
  final Color  color;
  final double size;
  final Offset offset;
  const _TrailParticle({
    required this.delay, required this.color,
    required this.size,  required this.offset,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// CartIconButton  — the destination widget with bounce + badge animation
// ─────────────────────────────────────────────────────────────────────────────

class CartIconButton extends StatefulWidget {
  const CartIconButton({
    super.key,
    required this.itemCount,
    this.onTap,
    this.size = 44.0,
    this.iconColor = Colors.white,
  });

  final int          itemCount;
  final VoidCallback? onTap;
  final double       size;
  final Color        iconColor;

  @override
  State<CartIconButton> createState() => CartIconButtonState();
}

class CartIconButtonState extends State<CartIconButton>
    with TickerProviderStateMixin {
  // Bounce on item arrival
  late final AnimationController _bounceCtrl;
  late final Animation<double>   _bounceScale;

  // Badge count pulse
  late final AnimationController _pulseCtrl;
  late final Animation<double>   _pulseScale;

  int _displayedCount = 0;

  @override
  void initState() {
    super.initState();
    _displayedCount = widget.itemCount;

    _bounceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _bounceScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.78), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.78, end: 1.22), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.22, end: 0.92), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.0),  weight: 15),
    ]).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeOut));

    _pulseCtrl  = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 340));
    _pulseScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.55), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.55, end: 1.0),  weight: 55),
    ]).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut));
  }

  /// Called by FlyToCart when a particle arrives. Public so the
  /// parent can also call it manually for testing.
  void triggerBounce() {
    _bounceCtrl.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) _pulseCtrl.forward(from: 0);
    });
  }

  @override
  void didUpdateWidget(CartIconButton old) {
    super.didUpdateWidget(old);
    if (widget.itemCount != old.itemCount) {
      setState(() => _displayedCount = widget.itemCount);
      triggerBounce();
    }
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: widget.size + 12,
        height: widget.size + 12,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // ── Cart icon with bounce ────────────────────────────────
            ScaleTransition(
              scale: _bounceScale,
              child: Container(
                width: widget.size, height: widget.size,
                decoration: BoxDecoration(
                  color:        Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(widget.size / 4),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.30), width: 0.8),
                ),
                child: Icon(
                  Icons.shopping_bag_outlined,
                  color: widget.iconColor, size: widget.size * 0.48,
                ),
              ),
            ),

            // ── Badge with pulse ─────────────────────────────────────
            if (_displayedCount > 0)
              Positioned(
                top: 2, right: 2,
                child: ScaleTransition(
                  scale: _pulseScale,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) => ScaleTransition(
                        scale: anim, child: child),
                    child: Container(
                      key: ValueKey(_displayedCount),
                      constraints: const BoxConstraints(
                          minWidth: 18, minHeight: 18),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color:        Colors.white,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: [
                          BoxShadow(
                            color:      Colors.black.withOpacity(0.22),
                            blurRadius: 6, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Text(
                        _displayedCount > 99
                            ? '99+'
                            : '$_displayedCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color:      Color(0xFF0C0C0C),
                          fontSize:   9.5,
                          fontWeight: FontWeight.w800,
                          height:     1.1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FlyToCartWrapper  — convenience widget that owns the GlobalKey and
// wires the launch call so the parent only needs one widget.
// ─────────────────────────────────────────────────────────────────────────────

typedef LaunchFlyFn = void Function({
  required Rect          sourceRect,
  required Color         productColor,
  ImageProvider?         productImage,
  String?                productEmoji,
  VoidCallback?          onComplete,
});

class FlyToCartWrapper extends StatefulWidget {
  const FlyToCartWrapper({
    super.key,
    required this.cartChild,
    required this.builder,
  });

  final Widget cartChild;
  final Widget Function(BuildContext context, LaunchFlyFn launchFly) builder;

  @override
  State<FlyToCartWrapper> createState() => _FlyToCartWrapperState();
}

class _FlyToCartWrapperState extends State<FlyToCartWrapper> {
  final _cartKey = GlobalKey<CartIconButtonState>();

  void _launch({
    required Rect          sourceRect,
    required Color         productColor,
    ImageProvider?         productImage,
    String?                productEmoji,
    VoidCallback?          onComplete,
  }) {
    FlyToCart.launch(
      context:      context,
      sourceRect:   sourceRect,
      cartKey:      _cartKey,
      productColor: productColor,
      productImage: productImage,
      productEmoji: productEmoji,
      onComplete:   () {
        _cartKey.currentState?.triggerBounce();
        onComplete?.call();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.builder(context, _launch),
        KeyedSubtree(key: _cartKey, child: widget.cartChild),
      ],
    );
  }
}