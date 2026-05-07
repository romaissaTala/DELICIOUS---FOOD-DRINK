// lib/features/cart/presentation/widgets/fly_to_cart_demo.dart
//
// Self-contained demo page — no Bloc needed. 
// Shows the full animation system in isolation so you can tweak
// timing, arc shape, and particle appearance before wiring into
// the real ProductsPage.
//
// Run standalone: Navigator.push(context,
//   MaterialPageRoute(builder: (_) => FlyToCartDemoPage()));

import 'package:flutter/material.dart';
import 'fly_to_cart.dart';
import 'add_to_bag_button.dart';

class FlyToCartDemoPage extends StatefulWidget {
  const FlyToCartDemoPage({super.key});

  @override
  State<FlyToCartDemoPage> createState() => _FlyToCartDemoPageState();
}

class _FlyToCartDemoPageState extends State<FlyToCartDemoPage> {
  final _cartKey  = GlobalKey<CartIconButtonState>();
  int   _count    = 0;
  int   _selected = 0;

  static const _products = [
    (name: 'Coca‑Cola',    emoji: '🥤', color: Color(0xFFCC0000), bg: Color(0xFFFF3333)),
    (name: 'Baklava',      emoji: '🍯', color: Color(0xFFC89B3C), bg: Color(0xFFE8B84B)),
    (name: 'Espresso',     emoji: '☕', color: Color(0xFF4A2C2A), bg: Color(0xFF8B5E52)),
    (name: 'Orange Juice', emoji: '🍊', color: Color(0xFFE87722), bg: Color(0xFFFF9A40)),
    (name: 'Couscous',     emoji: '🫕', color: Color(0xFFB8860B), bg: Color(0xFFDAA520)),
    (name: 'Pepsi',        emoji: '🫙', color: Color(0xFF004B93), bg: Color(0xFF0070CC)),
  ];

  void _addToCart(int index) {
    setState(() => _count++);
    _cartKey.currentState?.triggerBounce();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // ── Background gradient reacts to selected product ─────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve:    Curves.easeInOutCubic,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin:  Alignment.topLeft,
                end:    Alignment.bottomRight,
                colors: [
                  _products[_selected].bg.withOpacity(0.55),
                  const Color(0xFF0A0A0A),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(children: [
              // ── App bar ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Delicious',
                      style: TextStyle(
                        color: Colors.white, fontSize: 24,
                        fontWeight: FontWeight.w900, letterSpacing: -0.8)),
                    CartIconButton(
                      key:       _cartKey,
                      itemCount: _count,
                      onTap:     () {},
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Product grid ─────────────────────────────────────
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:   2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing:  12,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: _products.length,
                  itemBuilder: (context, i) {
                    final p = _products[i];
                    return _DemoCard(
                      name:    p.name,
                      emoji:   p.emoji,
                      color:   p.color,
                      bgColor: p.bg,
                      isSelected: _selected == i,
                      onSelect: () => setState(() => _selected = i),
                      onAdd: () {
                        // Fire the fly animation
                        final cardKey = GlobalKey();
                        FlyToCart.launch(
                          context:      context,
                          sourceRect:   FlyToCart.rectOf(
                              _DemoCard.keyOf(context, i)),
                          cartKey:      _cartKey,
                          productColor: p.color,
                          productEmoji: p.emoji,
                          onComplete:   () => _addToCart(i),
                        );
                      },
                    );
                  },
                ),
              ),

              // ── Bottom CTA using AddToBagButton ──────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: AddToBagButton(
                  cartKey:      _cartKey,
                  productColor: _products[_selected].color,
                  productEmoji: _products[_selected].emoji,
                  onAdded:      () => setState(() => _count++),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Demo product card
// ─────────────────────────────────────────────────────────────────────────────

class _DemoCard extends StatefulWidget {
  const _DemoCard({
    required this.name,
    required this.emoji,
    required this.color,
    required this.bgColor,
    required this.isSelected,
    required this.onSelect,
    required this.onAdd,
  });

  final String name;
  final String emoji;
  final Color  color;
  final Color  bgColor;
  final bool   isSelected;
  final VoidCallback onSelect;
  final VoidCallback onAdd;

  // Static key registry so FlyToCart can resolve position by index
  static final _keys = <int, GlobalKey>{};
  static GlobalKey keyOf(BuildContext context, int i) =>
      _keys.putIfAbsent(i, () => GlobalKey());

  @override
  State<_DemoCard> createState() => _DemoCardState();
}

class _DemoCardState extends State<_DemoCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 180));
    _scale = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => _ctrl.forward(),
      onTapUp:     (_) { _ctrl.reverse(); widget.onSelect(); },
      onTapCancel: ()  => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(widget.isSelected ? 0.14 : 0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isSelected
                  ? widget.color.withOpacity(0.60)
                  : Colors.white.withOpacity(0.10),
              width: widget.isSelected ? 1.5 : 0.6,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Emoji
                Expanded(
                  child: Center(
                    child: Text(widget.emoji,
                        style: const TextStyle(fontSize: 52)),
                  ),
                ),
                // Name
                Text(widget.name,
                  style: const TextStyle(
                    color: Colors.white, fontSize: 13,
                    fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                // Mini add button
                GestureDetector(
                  onTap: widget.onAdd,
                  child: Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color:        widget.color.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: widget.color.withOpacity(0.45), width: 0.8),
                    ),
                    child: Center(
                      child: Text('+ Add',
                        style: TextStyle(
                          color: widget.color.withOpacity(0.95),
                          fontSize: 12, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}