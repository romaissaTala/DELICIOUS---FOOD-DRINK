// lib/features/products/presentation/widgets/filter_button.dart
//
// The trigger button that opens the GlassmorphicFilterPanel.
// Shows an animated badge with the count of active filters.
// Designed to live in the AppBar actions or as a floating button.
//
// Usage:
//   FilterButton(
//     controller:   _filterCtrl,
//     activeCount:  state.activeFilter.activeCount,
//   )

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'filter_state.dart';
import 'glassmorphic_filter_panel.dart';

class FilterButton extends StatefulWidget {
  const FilterButton({
    super.key,
    required this.controller,
    this.activeCount = 0,
    this.size        = 44.0,
  });

  final FilterPanelController controller;
  final int                   activeCount;
  final double                size;

  @override
  State<FilterButton> createState() => _FilterButtonState();
}

class _FilterButtonState extends State<FilterButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.88), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.08), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0),  weight: 25),
    ]).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          _pulse.forward(from: 0);
          widget.controller.toggle();
        },
        child: SizedBox(
          width:  widget.size,
          height: widget.size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Button body
              AnimatedListenableBuilder(
                listenable: widget.controller,
                builder: (context, _) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: widget.size, height: widget.size,
                  decoration: BoxDecoration(
                    color: widget.controller.isOpen
                        ? Colors.white
                        : Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(widget.size / 4),
                    border: Border.all(
                      color: Colors.white.withOpacity(
                          widget.controller.isOpen ? 0.0 : 0.28),
                      width: 0.8,
                    ),
                    boxShadow: widget.controller.isOpen ? [
                      BoxShadow(
                        color:      Colors.white.withOpacity(0.25),
                        blurRadius: 16, offset: const Offset(0, 4)),
                    ] : null,
                  ),
                  child: Icon(
                    widget.controller.isOpen
                        ? Icons.close_rounded
                        : Icons.tune_rounded,
                    color: widget.controller.isOpen
                        ? const Color(0xFF0C0C0C)
                        : Colors.white,
                    size: 20,
                  ),
                ),
              ),

              // Active-count badge
              if (widget.activeCount > 0)
                Positioned(
                  top: -4, right: -4,
                  child: AnimatedScale(
                    scale:    1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width:  18, height: 18,
                      decoration: BoxDecoration(
                        color:        Colors.white,
                        shape:        BoxShape.circle,
                        boxShadow: [BoxShadow(
                          color:      Colors.black.withOpacity(0.25),
                          blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      child: Center(
                        child: Text(
                          '${widget.activeCount}',
                          style: const TextStyle(
                            color:      Color(0xFF0C0C0C),
                            fontSize:   9.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper — like ListenableBuilder but typed for AnimatedBuilder pattern
class AnimatedListenableBuilder extends AnimatedWidget {
  const AnimatedListenableBuilder({
    super.key,
    required super.listenable,
    required this.builder,
  });
  final Widget Function(BuildContext, Widget?) builder;

  @override
  Widget build(BuildContext context) => builder(context, null);
}