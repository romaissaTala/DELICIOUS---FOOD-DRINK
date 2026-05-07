// lib/features/products/presentation/widgets/glassmorphic_filter_panel.dart
//
// A full-height panel that slides in from the right edge over a frosted backdrop.
// Every section stagger-animates in on open with a 55ms offset between items.
//
// Aesthetic: dark condensation glass — like a cold drink glass on a hot day.
// Layered translucency, soft inner glows, sharp white typography.
//
// Usage in a Stack (last child so it renders on top):
//
//   final _filterCtrl = FilterPanelController();
//
//   // Open:
//   IconButton(onPressed: _filterCtrl.open, icon: Icon(Icons.tune))
//
//   // In your widget tree:
//   Stack(children: [
//     YourPageContent(),
//     FilterPanelOverlay(
//       controller:    _filterCtrl,
//       categories:    _categoriesFromBloc,
//       initialFilter: state.activeFilter,
//       onApply: (f) => context.read<ProductBloc>().add(FilterApplied(f)),
//     ),
//   ])

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'filter_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Controller — thin ChangeNotifier the page uses to open/close the panel
// ─────────────────────────────────────────────────────────────────────────────

class FilterPanelController extends ChangeNotifier {
  bool _open = false;
  bool get isOpen => _open;

  void open()   { _open = true;  notifyListeners(); }
  void close()  { _open = false; notifyListeners(); }
  void toggle() { _open ? close() : open(); }
}

// ─────────────────────────────────────────────────────────────────────────────
// FilterPanelOverlay — place as the last child of a Stack in your page
// ─────────────────────────────────────────────────────────────────────────────

class FilterPanelOverlay extends StatefulWidget {
  const FilterPanelOverlay({
    super.key,
    required this.controller,
    required this.onApply,
    this.categories    = const [],
    this.initialFilter = FilterState.empty,
  });

  final FilterPanelController                              controller;
  final void Function(FilterState)                         onApply;
  final List<({String id, String name, String icon})>      categories;
  final FilterState                                        initialFilter;

  @override
  State<FilterPanelOverlay> createState() => _FilterPanelOverlayState();
}

class _FilterPanelOverlayState extends State<FilterPanelOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _fade;
  late final Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _fade  = CurvedAnimation(parent: _ctrl,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOut));
    _slide = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    widget.controller.addListener(_sync);
  }

  void _sync() {
    widget.controller.isOpen ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_sync);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        if (_ctrl.value == 0) return const SizedBox.shrink();
        return Stack(fit: StackFit.expand, children: [
          // Frosted backdrop — tap to dismiss
          FadeTransition(
            opacity: _fade,
            child: GestureDetector(
              onTap: widget.controller.close,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: ColoredBox(color: Colors.black.withOpacity(0.50)),
              ),
            ),
          ),
          // Slide-in panel (84% screen width)
          Positioned(
            top: 0, bottom: 0, right: 0,
            width: MediaQuery.of(context).size.width * 0.84,
            child: SlideTransition(
              position: _slide,
              child: _GlassPanel(
                openAnimation: _ctrl,
                categories:    widget.categories,
                initialFilter: widget.initialFilter,
                onClose:  widget.controller.close,
                onApply:  (f) { widget.controller.close(); widget.onApply(f); },
                onReset:  ()  { widget.onApply(FilterState.empty); },
              ),
            ),
          ),
        ]);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _GlassPanel  — the actual panel body
// ─────────────────────────────────────────────────────────────────────────────

class _GlassPanel extends StatefulWidget {
  const _GlassPanel({
    required this.openAnimation,
    required this.categories,
    required this.initialFilter,
    required this.onClose,
    required this.onApply,
    required this.onReset,
  });

  final Animation<double>                             openAnimation;
  final List<({String id, String name, String icon})> categories;
  final FilterState                                   initialFilter;
  final VoidCallback                                  onClose;
  final void Function(FilterState)                    onApply;
  final VoidCallback                                  onReset;

  @override
  State<_GlassPanel> createState() => _GlassPanelState();
}

class _GlassPanelState extends State<_GlassPanel> with TickerProviderStateMixin {
  late FilterState _draft;

  final Map<String, bool> _expanded = {
    'sort': true, 'mood': true, 'category': false,
    'price': false, 'rating': false, 'options': false,
  };

  // 6 stagger controllers — one per section row
  static const _sectionCount = 6;
  late final List<AnimationController> _stC;
  late final List<Animation<double>>   _stA;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialFilter;
    _stC = List.generate(_sectionCount, (_) => AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300)));
    _stA = _stC.map((c) =>
        CurvedAnimation(parent: c, curve: Curves.easeOutCubic)).toList();
    widget.openAnimation.addStatusListener(_onSlideStatus);
    if (widget.openAnimation.value > 0) _runStagger();
  }

  void _onSlideStatus(AnimationStatus s) {
    if (s == AnimationStatus.forward || s == AnimationStatus.completed) {
      _runStagger();
    } else if (s == AnimationStatus.reverse || s == AnimationStatus.dismissed) {
      for (final c in _stC) c.reset();
    }
  }

  Future<void> _runStagger() async {
    for (var i = 0; i < _sectionCount; i++) {
      await Future.delayed(Duration(milliseconds: 55 * i));
      if (mounted) _stC[i].forward(from: 0);
    }
  }

  @override
  void dispose() {
    widget.openAnimation.removeStatusListener(_onSlideStatus);
    for (final c in _stC) c.dispose();
    super.dispose();
  }

  void _toggle(String key) {
    HapticFeedback.selectionClick();
    setState(() => _expanded[key] = !(_expanded[key] ?? false));
  }

  Widget _stagger(int i, Widget child) => FadeTransition(
    opacity: _stA[i],
    child: SlideTransition(
      position: _stA[i].drive(
          Tween(begin: const Offset(0.14, 0), end: Offset.zero)),
      child: child,
    ),
  );

  static Widget _divider() => Container(
    height: 0.5,
    margin: const EdgeInsets.symmetric(horizontal: 20),
    color: Colors.white.withOpacity(0.07),
  );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(28)),
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: const [Color(0xCC0C0C0C), Color(0xB5131313), Color(0x991A1A1A)],
              stops: const [0.0, 0.5, 1.0],
            ),
            border: const Border(
              left: BorderSide(color: Color(0x28FFFFFF), width: 0.8),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.55),
                blurRadius: 40, offset: const Offset(-8, 0),
              ),
            ],
          ),
          child: Column(children: [
            _PanelHeader(filter: _draft, onClose: widget.onClose, onReset: () {
              setState(() => _draft = FilterState.empty);
              widget.onReset();
            }),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
                children: [
                  // ── Sort ──────────────────────────────────────────────
                  _stagger(0, _SortSection(
                    selected: _draft.sortBy,
                    onChanged: (v) => setState(() =>
                        _draft = _draft.copyWith(sortBy: v)),
                  )),
                  _divider(),
                  // ── Mood ──────────────────────────────────────────────
                  _stagger(1, _MoodSection(
                    selected: _draft.selectedMoods,
                    onToggle: (m) => setState(() =>
                        _draft = _draft.toggleMood(m)),
                  )),
                  _divider(),
                  // ── Categories ────────────────────────────────────────
                  _stagger(2, _CollapsibleSection(
                    title: 'Categories', icon: '◈',
                    isExpanded: _expanded['category']!,
                    onToggle: () => _toggle('category'),
                    child: _CategorySection(
                      categories: widget.categories,
                      selected:   _draft.selectedCategories,
                      onToggle: (id) => setState(() =>
                          _draft = _draft.toggleCategory(id)),
                    ),
                  )),
                  _divider(),
                  // ── Price ─────────────────────────────────────────────
                  _stagger(3, _CollapsibleSection(
                    title: 'Price Range', icon: '◎',
                    isExpanded: _expanded['price']!,
                    onToggle: () => _toggle('price'),
                    child: _PriceSection(
                      selected:  _draft.priceRange,
                      onChanged: (v) => setState(() =>
                          _draft = _draft.copyWith(priceRange: v)),
                    ),
                  )),
                  _divider(),
                  // ── Rating ────────────────────────────────────────────
                  _stagger(4, _CollapsibleSection(
                    title: 'Min Rating', icon: '★',
                    isExpanded: _expanded['rating']!,
                    onToggle: () => _toggle('rating'),
                    child: _RatingSection(
                      minRating: _draft.minRating,
                      onChanged: (v) => setState(() =>
                          _draft = _draft.copyWith(minRating: v)),
                      onClear:  () => setState(() =>
                          _draft = _draft.copyWith(clearMinRating: true)),
                    ),
                  )),
                  _divider(),
                  // ── Options ───────────────────────────────────────────
                  _stagger(5, _OptionsSection(
                    onlyAvailable:  _draft.onlyAvailable,
                    onlyFeatured:   _draft.onlyFeatured,
                    onlyDiscounted: _draft.onlyDiscounted,
                    onAvailableChanged:  (v) => setState(() =>
                        _draft = _draft.copyWith(onlyAvailable: v)),
                    onFeaturedChanged:   (v) => setState(() =>
                        _draft = _draft.copyWith(onlyFeatured: v)),
                    onDiscountedChanged: (v) => setState(() =>
                        _draft = _draft.copyWith(onlyDiscounted: v)),
                  )),
                ],
              ),
            ),
            _ApplyButton(filter: _draft, onApply: () => widget.onApply(_draft)),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.filter, required this.onClose, required this.onReset});
  final FilterState  filter;
  final VoidCallback onClose;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top + 14;
    return Container(
      padding: EdgeInsets.fromLTRB(20, top, 14, 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.09))),
      ),
      child: Row(children: [
        // Close
        _IconBtn(icon: Icons.close_rounded, onTap: onClose),
        const SizedBox(width: 14),
        // Title
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Filter & Sort',
              style: TextStyle(color: Colors.white, fontSize: 18,
                  fontWeight: FontWeight.w700, letterSpacing: -0.4)),
            if (filter.isActive)
              Text('${filter.activeCount} active',
                style: TextStyle(color: Colors.white.withOpacity(0.45),
                    fontSize: 11.5)),
          ],
        )),
        // Reset
        if (filter.isActive)
          GestureDetector(
            onTap: onReset,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.14)),
              ),
              child: const Text('Reset',
                style: TextStyle(color: Colors.white70, fontSize: 12,
                    fontWeight: FontWeight.w600)),
            ),
          ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sort section — pill wrap
// ─────────────────────────────────────────────────────────────────────────────

class _SortSection extends StatelessWidget {
  const _SortSection({required this.selected, required this.onChanged});
  final SortOption selected;
  final void Function(SortOption) onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _SectionLabel(label: 'Sort by', icon: '↕'),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8,
        children: SortOption.values.map((opt) => _FilterPill(
          label:    '${opt.icon}  ${opt.label}',
          isActive: opt == selected,
          onTap:    () { HapticFeedback.selectionClick(); onChanged(opt); },
        )).toList()),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Mood section — emoji grid 4×2
// ─────────────────────────────────────────────────────────────────────────────

class _MoodSection extends StatelessWidget {
  const _MoodSection({required this.selected, required this.onToggle});
  final Set<String> selected;
  final void Function(String) onToggle;

  static const _moods = [
    (tag: 'cold',       emoji: '🧊', label: 'Cold'),
    (tag: 'hot',        emoji: '🔥', label: 'Hot'),
    (tag: 'sweet',      emoji: '🍬', label: 'Sweet'),
    (tag: 'salty',      emoji: '🧂', label: 'Salty'),
    (tag: 'spicy',      emoji: '🌶', label: 'Spicy'),
    (tag: 'fresh',      emoji: '🌿', label: 'Fresh'),
    (tag: 'energising', emoji: '⚡', label: 'Energy'),
    (tag: 'comforting', emoji: '🤗', label: 'Comfort'),
  ];

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _SectionLabel(label: 'Mood', icon: '◉'),
      const SizedBox(height: 12),
      GridView.count(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4, mainAxisSpacing: 8, crossAxisSpacing: 8,
        childAspectRatio: 0.88,
        children: _moods.map((m) => _MoodTile(
          emoji: m.emoji, label: m.label,
          isActive: selected.contains(m.tag),
          onTap: () { HapticFeedback.selectionClick(); onToggle(m.tag); },
        )).toList(),
      ),
    ]),
  );
}

class _MoodTile extends StatelessWidget {
  const _MoodTile({required this.emoji, required this.label,
    required this.isActive, required this.onTap});
  final String emoji, label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isActive ? Colors.white.withOpacity(0.18) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? Colors.white.withOpacity(0.50) : Colors.white.withOpacity(0.10),
          width: isActive ? 1.2 : 0.6,
        ),
        boxShadow: isActive ? [BoxShadow(
          color: Colors.white.withOpacity(0.07), blurRadius: 10)] : null,
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 5),
        Text(label, style: TextStyle(
          color: isActive ? Colors.white : Colors.white54,
          fontSize: 10.5,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
          letterSpacing: 0.1,
        )),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Category section
// ─────────────────────────────────────────────────────────────────────────────

class _CategorySection extends StatelessWidget {
  const _CategorySection(
      {required this.categories, required this.selected, required this.onToggle});
  final List<({String id, String name, String icon})> categories;
  final Set<String> selected;
  final void Function(String) onToggle;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text('No categories',
          style: TextStyle(color: Colors.white38, fontSize: 13)));
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(spacing: 8, runSpacing: 8,
        children: categories.map((c) => _FilterPill(
          label: '${c.icon}  ${c.name}',
          isActive: selected.contains(c.id),
          onTap: () { HapticFeedback.selectionClick(); onToggle(c.id); },
        )).toList()),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Price range section — radio list
// ─────────────────────────────────────────────────────────────────────────────

class _PriceSection extends StatelessWidget {
  const _PriceSection({required this.selected, required this.onChanged});
  final PriceRange selected;
  final void Function(PriceRange) onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(children: PriceRange.values.map((r) {
      final active = r == selected;
      return GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); onChanged(r); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: active ? Colors.white.withOpacity(0.13) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? Colors.white.withOpacity(0.34) : Colors.white.withOpacity(0.07),
              width: active ? 1.0 : 0.5,
            ),
          ),
          child: Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 16, height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? Colors.white : Colors.transparent,
                border: Border.all(
                  color: active ? Colors.white : Colors.white38, width: 1.5),
              ),
              child: active
                  ? const Icon(Icons.check, size: 10, color: Color(0xFF0C0C0C))
                  : null,
            ),
            const SizedBox(width: 12),
            Text(r.label, style: TextStyle(
              color: active ? Colors.white : Colors.white60,
              fontSize: 13.5,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            )),
          ]),
        ),
      );
    }).toList()),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Rating section — tappable star row
// ─────────────────────────────────────────────────────────────────────────────

class _RatingSection extends StatelessWidget {
  const _RatingSection(
      {required this.minRating, required this.onChanged, required this.onClear});
  final double? minRating;
  final void Function(double) onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(
          minRating != null ? '${minRating!.toStringAsFixed(1)}+ stars' : 'Any rating',
          style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13)),
        if (minRating != null)
          GestureDetector(onTap: onClear,
            child: Text('Clear', style: TextStyle(
              color: Colors.white.withOpacity(0.40), fontSize: 12,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white24))),
      ]),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(5, (i) {
          final star = i + 1;
          final filled = minRating != null && star <= minRating!;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); onChanged(star.toDouble()); },
            child: AnimatedScale(
              scale: filled ? 1.20 : 1.0,
              duration: const Duration(milliseconds: 160),
              child: Icon(
                filled ? Icons.star_rounded : Icons.star_border_rounded,
                size: 36,
                color: filled ? const Color(0xFFF5C518) : Colors.white24,
              ),
            ),
          );
        }),
      ),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Options section — glass toggle rows
// ─────────────────────────────────────────────────────────────────────────────

class _OptionsSection extends StatelessWidget {
  const _OptionsSection({
    required this.onlyAvailable, required this.onlyFeatured,
    required this.onlyDiscounted,
    required this.onAvailableChanged, required this.onFeaturedChanged,
    required this.onDiscountedChanged,
  });
  final bool onlyAvailable, onlyFeatured, onlyDiscounted;
  final void Function(bool) onAvailableChanged, onFeaturedChanged, onDiscountedChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _SectionLabel(label: 'Options', icon: '◐'),
      const SizedBox(height: 12),
      _ToggleRow(label: 'In stock only',   emoji: '✓', value: onlyAvailable,
          onChanged: onAvailableChanged),
      const SizedBox(height: 8),
      _ToggleRow(label: 'Featured items',  emoji: '★', value: onlyFeatured,
          onChanged: onFeaturedChanged),
      const SizedBox(height: 8),
      _ToggleRow(label: 'On sale',         emoji: '％', value: onlyDiscounted,
          onChanged: onDiscountedChanged),
    ]),
  );
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.label, required this.emoji,
    required this.value, required this.onChanged});
  final String label, emoji;
  final bool value;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () { HapticFeedback.selectionClick(); onChanged(!value); },
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: value ? Colors.white.withOpacity(0.11) : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? Colors.white.withOpacity(0.28) : Colors.white.withOpacity(0.07),
          width: 0.8,
        ),
      ),
      child: Row(children: [
        Text(emoji, style: TextStyle(fontSize: 14,
            color: value ? Colors.white : Colors.white38)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: TextStyle(
          color: value ? Colors.white : Colors.white54,
          fontSize: 14,
          fontWeight: value ? FontWeight.w600 : FontWeight.w400,
        ))),
        _GlassToggle(value: value),
      ]),
    ),
  );
}

class _GlassToggle extends StatelessWidget {
  const _GlassToggle({required this.value});
  final bool value;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 220),
    width: 40, height: 22,
    decoration: BoxDecoration(
      color: value ? Colors.white.withOpacity(0.88) : Colors.white.withOpacity(0.12),
      borderRadius: BorderRadius.circular(11),
      border: Border.all(
        color: Colors.white.withOpacity(value ? 0.0 : 0.20), width: 0.8),
    ),
    child: Stack(children: [
      AnimatedPositioned(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        left: value ? 20.0 : 2.0, top: 2,
        child: Container(
          width: 18, height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: value ? const Color(0xFF0C0C0C) : Colors.white.withOpacity(0.50),
            boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.28), blurRadius: 4,
              offset: const Offset(0, 1))],
          ),
        ),
      ),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Collapsible section wrapper  (expand/collapse with AnimatedCrossFade)
// ─────────────────────────────────────────────────────────────────────────────

class _CollapsibleSection extends StatelessWidget {
  const _CollapsibleSection({
    required this.title, required this.icon,
    required this.isExpanded, required this.onToggle, required this.child,
  });
  final String title, icon;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      GestureDetector(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Row(children: [
            Text(icon, style: TextStyle(
                fontSize: 13, color: Colors.white.withOpacity(0.55))),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: const TextStyle(
              color: Colors.white, fontSize: 14,
              fontWeight: FontWeight.w600, letterSpacing: 0.1))),
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 240),
              child: Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.white38, size: 20)),
          ]),
        ),
      ),
      AnimatedCrossFade(
        firstChild:  const SizedBox(height: 6),
        secondChild: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: child),
        crossFadeState: isExpanded
            ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        duration: const Duration(milliseconds: 280),
        sizeCurve: Curves.easeOutCubic,
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Apply button — white pill with active-count badge
// ─────────────────────────────────────────────────────────────────────────────

class _ApplyButton extends StatelessWidget {
  const _ApplyButton({required this.filter, required this.onApply});
  final FilterState filter;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom + 16;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottom),
      decoration: BoxDecoration(
          border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.09)))),
      child: GestureDetector(
        onTap: () { HapticFeedback.mediumImpact(); onApply(); },
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(
              color: Colors.white.withOpacity(0.20),
              blurRadius: 24, offset: const Offset(0, 6))],
          ),
          child: Center(child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Apply filters', style: TextStyle(
                color: Color(0xFF0C0C0C), fontSize: 15,
                fontWeight: FontWeight.w800, letterSpacing: -0.3)),
              if (filter.activeCount > 0) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C0C0C),
                    borderRadius: BorderRadius.circular(8)),
                  child: Text('${filter.activeCount}', style: const TextStyle(
                    color: Colors.white, fontSize: 11,
                    fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          )),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared micro-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.icon});
  final String label, icon;

  @override
  Widget build(BuildContext context) => Row(children: [
    Text(icon, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.50))),
    const SizedBox(width: 8),
    Text(label, style: const TextStyle(
      color: Colors.white, fontSize: 14,
      fontWeight: FontWeight.w600, letterSpacing: 0.1)),
  ]);
}

class _FilterPill extends StatelessWidget {
  const _FilterPill(
      {required this.label, required this.isActive, required this.onTap});
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.white.withOpacity(0.17) : Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? Colors.white.withOpacity(0.44) : Colors.white.withOpacity(0.11),
          width: isActive ? 1.0 : 0.6),
      ),
      child: Text(label, style: TextStyle(
        color: isActive ? Colors.white : Colors.white54,
        fontSize: 12.5,
        fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
      )),
    ),
  );
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.14))),
      child: Icon(icon, color: Colors.white70, size: 18),
    ),
  );
}