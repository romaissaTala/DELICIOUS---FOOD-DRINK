// lib/features/products/presentation/widgets/gradient_scaffold.dart
//
// Full-screen animated gradient background.
// Every time [gradientColors] changes (driven by ProductBloc carousel index),
// the background cross-fades smoothly via ColorTween animation.
//
// Layers (bottom → top):
//   1. LinearGradient  — brand colour tween
//   2. RadialGradient  — soft top-left light glow
//   3. LinearGradient  — bottom vignette (improves text contrast)
//   4. Noise overlay   — subtle film-grain texture for depth
//   5. child           — actual page content

import 'package:flutter/material.dart';

class GradientScaffold extends StatefulWidget {
  const GradientScaffold({
    super.key,
    required this.gradientColors,
    required this.child,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.duration        = const Duration(milliseconds: 650),
    this.curve           = Curves.easeInOutCubic,
    this.vignetteOpacity = 0.42,
    this.noiseOpacity    = 0.16,
  });

  /// Two hex strings from the active product — e.g. ["#CC0000","#FF4444"].
  /// Falls back to orange if empty.
  final List<String>         gradientColors;
  final Widget               child;
  final PreferredSizeWidget? appBar;
  final Widget?              bottomNavigationBar;
  final Widget?              floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Duration             duration;
  final Curve                curve;
  final double               vignetteOpacity;
  final double               noiseOpacity;

  @override
  State<GradientScaffold> createState() => _GradientScaffoldState();
}

class _GradientScaffoldState extends State<GradientScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late Animation<Color?>          _anim1;
  late Animation<Color?>          _anim2;

  Color _from1 = const Color(0xFFFF6B35);
  Color _from2 = const Color(0xFFFF8C61);
  Color _to1   = const Color(0xFFFF6B35);
  Color _to2   = const Color(0xFFFF8C61);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _applyColors(widget.gradientColors, animate: false);
  }

  @override
  void didUpdateWidget(GradientScaffold old) {
    super.didUpdateWidget(old);
    if (old.gradientColors != widget.gradientColors) {
      _applyColors(widget.gradientColors, animate: true);
    }
  }

  void _applyColors(List<String> colors, {required bool animate}) {
    final next1 = _hex(colors.isNotEmpty ? colors[0] : '#FF6B35');
    final next2 = _hex(colors.length > 1  ? colors[1] : '#FF8C61');

    if (!animate) {
      _from1 = _to1 = next1;
      _from2 = _to2 = next2;
      return;
    }

    // Snapshot current animated colour as the new 'from'
    _from1 = _ctrl.isAnimating ? (_anim1.value ?? _to1) : _to1;
    _from2 = _ctrl.isAnimating ? (_anim2.value ?? _to2) : _to2;
    _to1   = next1;
    _to2   = next2;

    final curved = CurvedAnimation(parent: _ctrl, curve: widget.curve);
    _anim1 = ColorTween(begin: _from1, end: _to1).animate(curved);
    _anim2 = ColorTween(begin: _from2, end: _to2).animate(curved);

    _ctrl
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static Color _hex(String hex) {
    final s = hex.replaceAll('#', '').trim();
    return s.length == 6
        ? Color(int.parse('FF$s', radix: 16))
        : const Color(0xFFFF6B35);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final c1 = _ctrl.isAnimating ? (_anim1.value ?? _to1) : _to1;
        final c2 = _ctrl.isAnimating ? (_anim2.value ?? _to2) : _to2;

        return Scaffold(
          backgroundColor:          Colors.transparent,
          extendBodyBehindAppBar:   true,
          extendBody:               true,
          appBar:                   widget.appBar,
          bottomNavigationBar:      widget.bottomNavigationBar,
          floatingActionButton:     widget.floatingActionButton,
          floatingActionButtonLocation: widget.floatingActionButtonLocation,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // 1 ─ Base gradient
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin:  Alignment.topLeft,
                    end:    Alignment.bottomRight,
                    colors: [c1, Color.lerp(c1, c2, 0.55)!, c2],
                    stops:  const [0.0, 0.48, 1.0],
                  ),
                ),
              ),

              // 2 ─ Top-left radial glow
              Positioned(
                left: -80, top: -80,
                child: SizedBox(
                  width: 340, height: 340,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.20),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 3 ─ Bottom vignette
              Positioned(
                left: 0, right: 0, bottom: 0,
                height: 260,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin:  Alignment.topCenter,
                      end:    Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(widget.vignetteOpacity),
                      ],
                    ),
                  ),
                ),
              ),

              // 4 ─ Noise texture
              Opacity(
                opacity: widget.noiseOpacity,
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _NoisePainter(),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),

              // 5 ─ Page content
              child!,
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Static grain — painted once, never repainted.
class _NoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var x = 0.0; x < size.width; x += 3.5) {
      for (var y = 0.0; y < size.height; y += 3.5) {
        final v = ((x * 7 + y * 13).toInt()) % 19;
        if (v < 4) {
          paint.color = Colors.white.withOpacity(0.025 + v * 0.012);
          canvas.drawCircle(Offset(x, y), 0.75, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_NoisePainter _) => false;
}