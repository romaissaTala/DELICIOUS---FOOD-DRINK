// lib/features/mood/presentation/widgets/mood_selector.dart
//
// MoodSelector — a bottom-sheet style mood picker with:
//
//   • MoodSelectorBar   — a compact pill row always visible in the page.
//     Tapping "What are you in the mood for?" opens the full sheet.
//     When a mood is active it shows the emoji + label + a clear ×.
//
//   • MoodSelectorSheet — the full-height draggable bottom sheet.
//     8 mood tiles arranged in a 4×2 grid.
//     Each tile: emoji (animated float), label, description line.
//     Active tile: glowing border + scale pop + floating particles.
//     Background gradient shifts to match the hovered/selected mood.
//
//   • _MoodParticles    — decorative floating emoji particles on active tile.
//   • _MoodTile         — individual tile with entrance stagger animation.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/mood_bloc.dart';
import '../../domain/entities/mood.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MoodSelectorBar  — the always-visible compact trigger in the page
// ─────────────────────────────────────────────────────────────────────────────

class MoodSelectorBar extends StatelessWidget {
  const MoodSelectorBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MoodBloc, MoodState>(
      buildWhen: (p, c) =>
          p.activeMoodTag    != c.activeMoodTag ||
          p.hasActiveMood    != c.hasActiveMood,
      builder: (context, state) {
        return GestureDetector(
          onTap: () => _openSheet(context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve:    Curves.easeOutCubic,
            height:   46,
            decoration: BoxDecoration(
              color:        Colors.white.withOpacity(state.hasActiveMood ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(23),
              border: Border.all(
                color: Colors.white.withOpacity(state.hasActiveMood ? 0.45 : 0.22),
                width: state.hasActiveMood ? 1.2 : 0.7,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                // Left icon / emoji
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: state.hasActiveMood
                      ? Text(state.activeMood!.emoji,
                          key: ValueKey(state.activeMoodTag),
                          style: const TextStyle(fontSize: 18))
                      : Icon(Icons.mood_outlined,
                          key: const ValueKey('default'),
                          color: Colors.white.withOpacity(0.65), size: 18),
                ),
                const SizedBox(width: 10),
                // Label
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: state.hasActiveMood
                        ? Text(
                            state.activeMood!.label,
                            key: ValueKey('label_${state.activeMoodTag}'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.5, fontWeight: FontWeight.w700),
                          )
                        : Text(
                            'What are you craving?',
                            key: const ValueKey('prompt'),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.55),
                              fontSize: 13),
                          ),
                  ),
                ),
                // Right: chevron or clear button
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: state.hasActiveMood
                      ? GestureDetector(
                          key: const ValueKey('clear'),
                          onTap: () {
                            context.read<MoodBloc>().add(const MoodCleared());
                          },
                          child: Container(
                            width: 22, height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.20),
                            ),
                            child: Icon(Icons.close_rounded,
                                size: 13, color: Colors.white.withOpacity(0.80)),
                          ),
                        )
                      : Icon(Icons.keyboard_arrow_down_rounded,
                          key: const ValueKey('chevron'),
                          color: Colors.white.withOpacity(0.45), size: 20),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }

  void _openSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    context.read<MoodBloc>().add(const MoodSelectorOpened());
    showModalBottomSheet(
      context:          context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor:    Colors.black.withOpacity(0.55),
      builder: (sheetCtx) => BlocProvider.value(
        value: context.read<MoodBloc>(),
        child: const MoodSelectorSheet(),
      ),
    ).then((_) {
      if (context.mounted) {
        context.read<MoodBloc>().add(const MoodSelectorClosed());
      }
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MoodSelectorSheet  — the full bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class MoodSelectorSheet extends StatefulWidget {
  const MoodSelectorSheet({super.key});

  @override
  State<MoodSelectorSheet> createState() => _MoodSelectorSheetState();
}

class _MoodSelectorSheetState extends State<MoodSelectorSheet>
    with TickerProviderStateMixin {

  // Hover state — which tile the user's finger is over (for gradient preview)
  String? _hoveredTag;

  // Sheet-level entrance animation
  late final AnimationController _sheetCtrl;
  late final Animation<double>   _sheetFade;

  // 8 tile stagger controllers
  static const _tileCount = 8;
  late final List<AnimationController> _tileC;
  late final List<Animation<double>>   _tileA;

  @override
  void initState() {
    super.initState();

    _sheetCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _sheetFade = CurvedAnimation(parent: _sheetCtrl, curve: Curves.easeOut);

    _tileC = List.generate(_tileCount, (_) => AnimationController(
        vsync: this, duration: const Duration(milliseconds: 340)));
    _tileA = _tileC.map((c) =>
        CurvedAnimation(parent: c, curve: Curves.easeOutBack)).toList();

    _sheetCtrl.forward();
    _fireStagger();
  }

  Future<void> _fireStagger() async {
    for (var i = 0; i < _tileCount; i++) {
      await Future.delayed(Duration(milliseconds: 45 * i));
      if (mounted) _tileC[i].forward(from: 0);
    }
  }

  @override
  void dispose() {
    _sheetCtrl.dispose();
    for (final c in _tileC) c.dispose();
    super.dispose();
  }

  // Resolve gradient for the current hover/selection state
  List<Color> _resolveGradient(MoodState state) {
    final tag = _hoveredTag ?? state.activeMoodTag;
    final mood = tag != null ? MoodCatalogue.byTag(tag) : null;
    final hex  = mood?.gradientColors ?? ['#1A1A2E', '#16213E'];
    return [_h(hex[0]), _h(hex[1])];
  }

  static Color _h(String hex) {
    final s = hex.replaceAll('#', '');
    return Color(int.parse('FF$s', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MoodBloc, MoodState>(
      builder: (context, state) {
        final moods    = state.moods;
        final gradient = _resolveGradient(state);

        return FadeTransition(
          opacity: _sheetFade,
          child: DraggableScrollableSheet(
            initialChildSize: 0.72,
            minChildSize:     0.50,
            maxChildSize:     0.92,
            builder: (_, scrollCtrl) => AnimatedContainer(
              duration: const Duration(milliseconds: 450),
              curve:    Curves.easeInOutCubic,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [
                    gradient[0].withOpacity(0.95),
                    gradient[1].withOpacity(0.88),
                    const Color(0xFF0A0A0A),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: Column(children: [
                // ── Drag handle ──────────────────────────────────────
                const SizedBox(height: 10),
                Center(child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color:        Colors.white.withOpacity(0.30),
                    borderRadius: BorderRadius.circular(2),
                  ),
                )),
                const SizedBox(height: 18),

                // ── Header ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text("I'm in the mood for…",
                          style: TextStyle(
                            color: Colors.white, fontSize: 22,
                            fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                        const SizedBox(height: 2),
                        Text('Pick a feeling, get matched products',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.50), fontSize: 12.5)),
                      ]),
                      if (state.hasActiveMood)
                        GestureDetector(
                          onTap: () {
                            context.read<MoodBloc>().add(const MoodCleared());
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color:        Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.20)),
                            ),
                            child: const Text('Clear',
                              style: TextStyle(
                                color: Colors.white70, fontSize: 12,
                                fontWeight: FontWeight.w600)),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Mood grid ────────────────────────────────────────
                Expanded(
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator(
                          color: Colors.white54, strokeWidth: 2))
                      : GridView.builder(
                          controller:    scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:   2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing:  14,
                            childAspectRatio: 1.20,
                          ),
                          itemCount: moods.length,
                          itemBuilder: (_, i) {
                            final mood = moods[i];
                            final isActive = mood.tag == state.activeMoodTag;
                            final idx = i.clamp(0, _tileCount - 1);
                            return FadeTransition(
                              opacity: _tileA[idx],
                              child: SlideTransition(
                                position: _tileA[idx].drive(
                                    Tween(begin: const Offset(0, 0.18),
                                        end: Offset.zero)),
                                child: _MoodTile(
                                  mood:     mood,
                                  isActive: isActive,
                                  onTap: () {
                                    context.read<MoodBloc>()
                                        .add(MoodSelected(mood.tag));
                                    Navigator.pop(context);
                                  },
                                  onHover: (hovering) => setState(() =>
                                      _hoveredTag = hovering ? mood.tag : null),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MoodTile  — individual tile with emoji float + glow + particles
// ─────────────────────────────────────────────────────────────────────────────

class _MoodTile extends StatefulWidget {
  const _MoodTile({
    required this.mood,
    required this.isActive,
    required this.onTap,
    required this.onHover,
  });

  final Mood     mood;
  final bool     isActive;
  final VoidCallback           onTap;
  final void Function(bool)    onHover;

  @override
  State<_MoodTile> createState() => _MoodTileState();
}

class _MoodTileState extends State<_MoodTile>
    with TickerProviderStateMixin {

  // Emoji float oscillation
  late final AnimationController _floatCtrl;
  late final Animation<double>   _floatAnim;

  // Press scale
  late final AnimationController _pressCtrl;
  late final Animation<double>   _pressScale;

  // Active glow pulse
  late final AnimationController _glowCtrl;
  late final Animation<double>   _glowAnim;

  static Color _h(String hex) {
    final s = hex.replaceAll('#', '');
    return Color(int.parse('FF$s', radix: 16));
  }

  @override
  void initState() {
    super.initState();

    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -5.0, end: 5.0)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _pressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 140));
    _pressScale = Tween<double>(begin: 1.0, end: 0.93)
        .animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut));

    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    // Randomise float phase so tiles don't all bob in sync
    final phase = (widget.mood.sortOrder * 0.31) % 1.0;
    _floatCtrl.value = phase;
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _pressCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c1 = _h(widget.mood.gradientColors[0]);
    final c2 = _h(widget.mood.gradientColors[1]);

    return GestureDetector(
      onTapDown:   (_) { _pressCtrl.forward(); widget.onHover(true); },
      onTapUp:     (_) { _pressCtrl.reverse(); widget.onTap(); },
      onTapCancel: ()  { _pressCtrl.reverse(); widget.onHover(false); },
      child: ScaleTransition(
        scale: _pressScale,
        child: AnimatedBuilder(
          animation: Listenable.merge([_floatAnim, _glowAnim]),
          builder: (context, child) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                // ── Tile body ────────────────────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve:    Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: widget.isActive
                          ? [c1.withOpacity(0.75), c2.withOpacity(0.55)]
                          : [
                              Colors.white.withOpacity(0.10),
                              Colors.white.withOpacity(0.05),
                            ],
                    ),
                    border: Border.all(
                      color: widget.isActive
                          ? c1.withOpacity(0.80 * _glowAnim.value)
                          : Colors.white.withOpacity(0.14),
                      width: widget.isActive ? 1.8 : 0.7,
                    ),
                    boxShadow: widget.isActive
                        ? [
                            BoxShadow(
                              color:      c1.withOpacity(0.50 * _glowAnim.value),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color:      c2.withOpacity(0.25 * _glowAnim.value),
                              blurRadius: 40,
                            ),
                          ]
                        : [
                            BoxShadow(
                              color:      Colors.black.withOpacity(0.18),
                              blurRadius: 12, offset: const Offset(0, 4)),
                          ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment:  MainAxisAlignment.spaceBetween,
                      children: [
                        // Emoji — floats vertically
                        Transform.translate(
                          offset: Offset(0, _floatAnim.value),
                          child: Text(widget.mood.emoji,
                              style: const TextStyle(fontSize: 36)),
                        ),
                        // Text info
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.mood.label,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: widget.isActive
                                    ? FontWeight.w800 : FontWeight.w600,
                                letterSpacing: -0.2,
                              )),
                            const SizedBox(height: 2),
                            Text(widget.mood.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(
                                    widget.isActive ? 0.75 : 0.45),
                                fontSize: 10.5,
                              )),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Active checkmark badge ────────────────────────────
                if (widget.isActive)
                  Positioned(
                    top: 10, right: 10,
                    child: AnimatedScale(
                      scale:    1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle, color: Colors.white,
                          boxShadow: [BoxShadow(
                            color:      c1.withOpacity(0.50),
                            blurRadius: 8)],
                        ),
                        child: Icon(Icons.check_rounded,
                            size: 14,
                            color: c1),
                      ),
                    ),
                  ),

                // ── Floating particles (active tile only) ─────────────
                if (widget.isActive)
                  ..._buildParticles(c1),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildParticles(Color baseColor) {
    final particles = widget.mood.particleEmojis.take(3).toList();
    return List.generate(particles.length, (i) {
      // Each particle has a unique orbit using its index as phase
      final phase  = (i / particles.length) * math.pi * 2;
      final radius = 18.0 + i * 8.0;
      final t      = _floatCtrl.value * math.pi * 2;
      final x      = math.cos(t + phase) * radius * 0.6;
      final y      = math.sin(t + phase) * radius * 0.3;
      return Positioned(
        right: 8.0 + i * 14.0,
        top:   -8.0 + y,
        child: Transform.translate(
          offset: Offset(x, 0),
          child: Opacity(
            opacity: (0.55 + 0.35 * math.sin(t + phase)).clamp(0.0, 1.0),
            child: Text(particles[i],
                style: TextStyle(fontSize: 11.0 + i * 1.5)),
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MoodActiveChip  — tiny inline chip shown in the AppBar / product page header
// when a mood is active. Tapping it clears the mood.
// ─────────────────────────────────────────────────────────────────────────────

class MoodActiveChip extends StatelessWidget {
  const MoodActiveChip({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MoodBloc, MoodState>(
      buildWhen: (p, c) => p.activeMoodTag != c.activeMoodTag,
      builder: (context, state) {
        if (!state.hasActiveMood) return const SizedBox.shrink();
        final mood = state.activeMood!;
        final c1 = _h(mood.gradientColors[0]);

        return GestureDetector(
          onTap: () => context.read<MoodBloc>().add(const MoodCleared()),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color:        c1.withOpacity(0.25),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c1.withOpacity(0.55), width: 1.0),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(mood.emoji, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 5),
              Text(mood.label,
                style: const TextStyle(
                  color: Colors.white, fontSize: 11.5,
                  fontWeight: FontWeight.w700)),
              const SizedBox(width: 6),
              Icon(Icons.close_rounded,
                  size: 12, color: Colors.white.withOpacity(0.65)),
            ]),
          ),
        );
      },
    );
  }

  static Color _h(String hex) {
    final s = hex.replaceAll('#', '');
    return Color(int.parse('FF$s', radix: 16));
  }
}