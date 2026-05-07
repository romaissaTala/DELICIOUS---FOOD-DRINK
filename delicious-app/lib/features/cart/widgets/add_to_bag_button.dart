// lib/features/cart/presentation/widgets/add_to_bag_button.dart
//
// A self-contained "Add to bag" button that:
//   1. Captures its own Rect on tap.
//   2. Fires FlyToCart.launch() toward the cart icon.
//   3. Plays a local press → confirm state sequence.
//
// Drop this wherever you need an add-to-bag action — product cards,
// detail pages, quick-add sheets.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'fly_to_cart.dart';

class AddToBagButton extends StatefulWidget {
  const AddToBagButton({
    super.key,
    required this.cartKey,
    required this.productColor,
    this.productImage,
    this.productEmoji,
    this.label        = 'Add to bag',
    this.confirmedLabel = 'Added!',
    this.height       = 52.0,
    this.borderRadius = 16.0,
    this.onAdded,
  });

  /// The GlobalKey on your CartIconButton — needed to resolve its position.
  final GlobalKey          cartKey;
  final Color              productColor;
  final ImageProvider?     productImage;
  final String?            productEmoji;
  final String             label;
  final String             confirmedLabel;
  final double             height;
  final double             borderRadius;
  final VoidCallback?      onAdded;

  @override
  State<AddToBagButton> createState() => _AddToBagButtonState();
}

class _AddToBagButtonState extends State<AddToBagButton>
    with SingleTickerProviderStateMixin {
  final _buttonKey = GlobalKey();

  late final AnimationController _ctrl;
  late final Animation<double>   _pressScale;

  // State machine: idle → flying → confirmed → idle
  _BtnState _state = _BtnState.idle;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 160));
    _pressScale = Tween<double>(begin: 1.0, end: 0.94)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    if (_state != _BtnState.idle) return;
    HapticFeedback.lightImpact();

    // Quick press animation
    await _ctrl.forward();
    await _ctrl.reverse();

    setState(() => _state = _BtnState.flying);

    // Source rect = this button's position on screen
    final sourceRect = FlyToCart.rectOf(_buttonKey);

    FlyToCart.launch(
      context:      context,
      sourceRect:   sourceRect,
      cartKey:      widget.cartKey,
      productColor: widget.productColor,
      productImage: widget.productImage,
      productEmoji: widget.productEmoji,
      onComplete: () {
        if (!mounted) return;
        widget.onAdded?.call();
        setState(() => _state = _BtnState.confirmed);
        Future.delayed(const Duration(milliseconds: 1600), () {
          if (mounted) setState(() => _state = _BtnState.idle);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pressScale,
      child: GestureDetector(
        key:   _buttonKey,
        onTap: _onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve:    Curves.easeOutCubic,
          height:   widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            color: switch (_state) {
              _BtnState.idle      => Colors.white,
              _BtnState.flying    => Colors.white.withOpacity(0.70),
              _BtnState.confirmed => Colors.green.shade400,
            },
            boxShadow: [
              BoxShadow(
                color: switch (_state) {
                  _BtnState.confirmed => Colors.green.withOpacity(0.35),
                  _               => Colors.white.withOpacity(0.20),
                },
                blurRadius: 20, offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve:  Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim, child: child),
              child: switch (_state) {
                _BtnState.idle => Row(
                  key: const ValueKey('idle'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shopping_bag_outlined,
                        color: Color(0xFF0C0C0C), size: 18),
                    const SizedBox(width: 8),
                    Text(widget.label,
                      style: const TextStyle(
                        color:      Color(0xFF0C0C0C),
                        fontSize:   15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      )),
                  ],
                ),
                _BtnState.flying => Row(
                  key: const ValueKey('flying'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        color: const Color(0xFF0C0C0C).withOpacity(0.50),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('Adding…', style: TextStyle(
                      color: const Color(0xFF0C0C0C).withOpacity(0.55),
                      fontSize: 15, fontWeight: FontWeight.w700)),
                  ],
                ),
                _BtnState.confirmed => Row(
                  key: const ValueKey('confirmed'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(widget.confirmedLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15, fontWeight: FontWeight.w800)),
                  ],
                ),
              },
            ),
          ),
        ),
      ),
    );
  }
}

enum _BtnState { idle, flying, confirmed }