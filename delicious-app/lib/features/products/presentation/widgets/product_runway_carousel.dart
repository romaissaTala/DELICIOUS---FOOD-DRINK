// lib/features/products/presentation/widgets/product_runway_carousel.dart
//
// The signature UI widget of Delicious.
//
// Layout: a PageView with viewportFraction < 1, so neighbouring cards
// peek in from the sides. Each card is scaled and faded based on its
// distance from the centre — giving a "runway" depth effect.
//
//   prev (0.65×, 40% opacity) ← [ACTIVE (1.0×, full)] → next (0.65×, 40%)
//
// On every page change:
//   • HapticFeedback.lightImpact()
//   • ProductCarouselIndexChanged(i) is dispatched to ProductBloc
//   • GradientScaffold receives new colours via BlocBuilder upstream

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../domain/entities/product.dart';
import '../bloc/product_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public widget
// ─────────────────────────────────────────────────────────────────────────────

class ProductRunwayCarousel extends StatefulWidget {
  const ProductRunwayCarousel({
    super.key,
    required this.products,
    required this.onAddToCart,
    this.onProductTap,
    this.initialIndex     = 0,
    this.viewportFraction = 0.72,
  });

  final List<Product>            products;
  final void Function(Product)   onAddToCart;
  final void Function(Product)?  onProductTap;
  final int                      initialIndex;
  final double                   viewportFraction;

  @override
  State<ProductRunwayCarousel> createState() => _ProductRunwayCarouselState();
}

class _ProductRunwayCarouselState extends State<ProductRunwayCarousel> {
  late final PageController _pageCtrl;
  double _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialIndex.toDouble();
    _pageCtrl = PageController(
      initialPage:      widget.initialIndex,
      viewportFraction: widget.viewportFraction,
    )..addListener(_onScroll);
  }

  void _onScroll() {
    setState(() => _currentPage = _pageCtrl.page ?? _currentPage);
  }

  void _onPageChanged(int index) {
    HapticFeedback.lightImpact();
    context.read<ProductBloc>().add(ProductCarouselIndexChanged(index));
  }

  @override
  void dispose() {
    _pageCtrl
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.products.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 480,
      child: PageView.builder(
        controller:  _pageCtrl,
        onPageChanged: _onPageChanged,
        itemCount:   widget.products.length,
        itemBuilder: (context, index) {
          // Distance from the centre card (0.0 = active, 1.0 = one full page away)
          final distance = (_currentPage - index).abs().clamp(0.0, 1.0);
          return _CarouselCard(
            product:   widget.products[index],
            distance:  distance,
            isActive:  distance < 0.5,
            onAddToCart: widget.onAddToCart,
            onTap:     () => widget.onProductTap?.call(widget.products[index]),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual card
// ─────────────────────────────────────────────────────────────────────────────

class _CarouselCard extends StatelessWidget {
  const _CarouselCard({
    required this.product,
    required this.distance,
    required this.isActive,
    required this.onAddToCart,
    required this.onTap,
  });

  final Product  product;
  final double   distance;   // 0 = centre, 1 = far
  final bool     isActive;
  final void Function(Product) onAddToCart;
  final VoidCallback           onTap;

  // Interpolated values based on distance from centre
  double get _scale   => 1.0 - (distance * 0.30);
  double get _opacity => 1.0 - (distance * 0.60);
  double get _yShift  => distance * 28.0;  // side cards sink slightly

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: _scale),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) {
        return Transform.translate(
          offset: Offset(0, _yShift),
          child: Transform.scale(
            scale: scale,
            child: Opacity(opacity: _opacity.clamp(0.35, 1.0), child: child),
          ),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: _CardBody(
            product:     product,
            isActive:    isActive,
            onAddToCart: onAddToCart,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card body — glass morphic container with product info
// ─────────────────────────────────────────────────────────────────────────────

class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.product,
    required this.isActive,
    required this.onAddToCart,
  });

  final Product  product;
  final bool     isActive;
  final void Function(Product) onAddToCart;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: Colors.white.withOpacity(0.12),
        border: Border.all(
          color: Colors.white.withOpacity(isActive ? 0.40 : 0.18),
          width: isActive ? 1.5 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.22),
            blurRadius: isActive ? 40 : 16,
            offset:     const Offset(0, 12),
          ),
          if (isActive)
            BoxShadow(
              color:      Colors.white.withOpacity(0.08),
              blurRadius: 1,
              offset:     const Offset(0, -1),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            // ── Frosted-glass inner fill ─────────────────────────────────
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end:   Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.18),
                      Colors.white.withOpacity(0.04),
                    ],
                  ),
                ),
              ),
            ),

            // ── Content ──────────────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProductImage(product: product, isActive: isActive),
                _ProductInfo(
                  product:     product,
                  isActive:    isActive,
                  onAddToCart: onAddToCart,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product image — top portion of card, with tag badges
// ─────────────────────────────────────────────────────────────────────────────

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.product, required this.isActive});

  final Product product;
  final bool    isActive;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Hero-wrapped product image ──────────────────────────────
          Hero(
            tag: 'product_image_${product.id}',
            child: CachedNetworkImage(
              imageUrl: product.thumbnailUrl ?? product.imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => _ImagePlaceholder(product: product),
              errorWidget:  (_, __, ___) => _ImagePlaceholder(product: product),
            ),
          ),

          // ── Gradient fade at the bottom of the image ────────────────
          Positioned(
            left: 0, right: 0, bottom: 0,
            height: 80,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin:  Alignment.topCenter,
                  end:    Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.30)],
                ),
              ),
            ),
          ),

          // ── Discount badge ───────────────────────────────────────────
          if (product.hasDiscount)
            Positioned(
              top: 14, left: 14,
              child: _Badge(
                label: '−${product.discountPercent.toInt()}%',
                color: Colors.red.shade600,
              ),
            ),

          // ── Mood tags ────────────────────────────────────────────────
          if (product.mood.isNotEmpty)
            Positioned(
              top: 14, right: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: product.mood.take(2).map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _Badge(
                    label: _moodEmoji(m),
                    color: Colors.black.withOpacity(0.45),
                    fontSize: 13,
                  ),
                )).toList(),
              ),
            ),

          // ── "Featured" star ──────────────────────────────────────────
          if (product.isFeatured)
            Positioned(
              bottom: 12, left: 14,
              child: Row(children: [
                Icon(Icons.star_rounded, color: Colors.amber.shade300, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Popular',
                  style: TextStyle(
                    color:      Colors.white.withOpacity(0.90),
                    fontSize:   11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ]),
            ),
        ],
      ),
    );
  }

  static String _moodEmoji(String mood) {
    const map = {
      'cold': '🧊', 'hot': '🔥', 'sweet': '🍬',
      'salty': '🧂', 'spicy': '🌶', 'fresh': '🌿',
      'energising': '⚡', 'comforting': '🤗',
    };
    return map[mood] ?? mood;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product info — bottom portion of card
// ─────────────────────────────────────────────────────────────────────────────

class _ProductInfo extends StatelessWidget {
  const _ProductInfo({
    required this.product,
    required this.isActive,
    required this.onAddToCart,
  });

  final Product  product;
  final bool     isActive;
  final void Function(Product) onAddToCart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand
          if (product.brand != null)
            Text(
              product.brand!.toUpperCase(),
              style: TextStyle(
                color:         Colors.white.withOpacity(0.60),
                fontSize:      10,
                fontWeight:    FontWeight.w700,
                letterSpacing: 2.4,
              ),
            ),
          if (product.brand != null) const SizedBox(height: 4),

          // Product name
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            style: TextStyle(
              color:      Colors.white,
              fontSize:   isActive ? 22 : 17,
              fontWeight: FontWeight.w700,
              height:     1.15,
              letterSpacing: -0.3,
            ),
            child: Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(height: 6),

          // Description — only shown on active card
          if (isActive && product.description != null)
            AnimatedOpacity(
              opacity:  isActive ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Text(
                product.description!,
                maxLines:  2,
                overflow:  TextOverflow.ellipsis,
                style: TextStyle(
                  color:    Colors.white.withOpacity(0.68),
                  fontSize: 12.5,
                  height:   1.5,
                ),
              ),
            ),
          if (isActive && product.description != null) const SizedBox(height: 14),

          // Price row + Add button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${product.finalPrice.toStringAsFixed(0)} DA',
                    style: const TextStyle(
                      color:      Colors.white,
                      fontSize:   20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (product.hasDiscount)
                    Text(
                      '${product.price.toStringAsFixed(0)} DA',
                      style: TextStyle(
                        color:          Colors.white.withOpacity(0.50),
                        fontSize:       12,
                        decoration:     TextDecoration.lineThrough,
                        decorationColor: Colors.white.withOpacity(0.50),
                      ),
                    ),
                ],
              ),

              // Add to cart button — only active card shows it
              if (isActive)
                _AddToCartButton(
                  product:     product,
                  onAddToCart: onAddToCart,
                ),
            ],
          ),

          // Prep time
          const SizedBox(height: 10),
          Row(children: [
            Icon(Icons.schedule_rounded,
                size: 13, color: Colors.white.withOpacity(0.50)),
            const SizedBox(width: 4),
            Text(
              '${product.preparationTimeMin} min',
              style: TextStyle(
                color:    Colors.white.withOpacity(0.50),
                fontSize: 11.5,
              ),
            ),
            if (product.rating.count > 0) ...[
              const SizedBox(width: 14),
              Icon(Icons.star_rounded,
                  size: 13, color: Colors.amber.shade300),
              const SizedBox(width: 3),
              Text(
                '${product.rating.average.toStringAsFixed(1)} (${product.rating.count})',
                style: TextStyle(
                  color:    Colors.white.withOpacity(0.55),
                  fontSize: 11.5,
                ),
              ),
            ],
          ]),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add to cart button with bounce animation
// ─────────────────────────────────────────────────────────────────────────────

class _AddToCartButton extends StatefulWidget {
  const _AddToCartButton({required this.product, required this.onAddToCart});

  final Product  product;
  final void Function(Product) onAddToCart;

  @override
  State<_AddToCartButton> createState() => _AddToCartButtonState();
}

class _AddToCartButtonState extends State<_AddToCartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceCtrl;
  late final Animation<double>   _scaleAnim;
  bool _added = false;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 380),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.82), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.82, end: 1.14), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.14, end: 1.0),  weight: 30),
    ]).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (_added) return;
    HapticFeedback.mediumImpact();
    _bounceCtrl.forward(from: 0);
    widget.onAddToCart(widget.product);
    setState(() => _added = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _added = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve:    Curves.easeOutCubic,
          width:    _added ? 110 : 48,
          height:   48,
          decoration: BoxDecoration(
            color:        _added ? Colors.white : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color:      Colors.black.withOpacity(0.20),
                blurRadius: 12,
                offset:     const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: _added
                  ? Row(
                      key: const ValueKey('added'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_rounded,
                            color: Colors.green.shade600, size: 18),
                        const SizedBox(width: 6),
                        Text('Added',
                          style: TextStyle(
                            color:      Colors.green.shade600,
                            fontSize:   13,
                            fontWeight: FontWeight.w700,
                          )),
                      ],
                    )
                  : Icon(
                      Icons.add_rounded,
                      key: const ValueKey('add'),
                      color:    const Color(0xFF1A1A1A),
                      size:     22,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Placeholder shown while image loads
// ─────────────────────────────────────────────────────────────────────────────

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
          colors: [
            _hex(product.gradientColors.isNotEmpty
                ? product.gradientColors[0] : '#FF6B35').withOpacity(0.6),
            _hex(product.gradientColors.length > 1
                ? product.gradientColors[1] : '#FF8C61').withOpacity(0.6),
          ],
        ),
      ),
      child: Center(
        child: Text(
          product.name.isNotEmpty ? product.name[0].toUpperCase() : '?',
          style: const TextStyle(
            color:      Colors.white,
            fontSize:   64,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  static Color _hex(String hex) {
    final s = hex.replaceAll('#', '').trim();
    return s.length == 6
        ? Color(int.parse('FF$s', radix: 16))
        : const Color(0xFFFF6B35);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small badge chip  (discount %, mood emoji)
// ─────────────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, this.fontSize = 11.0});

  final String label;
  final Color  color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:        color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color:      Colors.white,
          fontSize:   fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}