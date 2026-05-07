// lib/features/products/presentation/pages/products_page.dart
//
// The main product discovery screen.
// Wires GradientScaffold + ProductRunwayCarousel with the ProductBloc
// and CategoryBloc. Acts only as a composition layer — all logic lives
// in the Blocs and widgets.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/category_bloc.dart';
import '../bloc/product_bloc.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/product_runway_carousel.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final _scrollCtrl = ScrollController();
  bool  _appBarCollapsed = false;

  @override
  void initState() {
    super.initState();
    // Trigger initial data loads
    context.read<ProductBloc>()
      ..add(const ProductsLoadRequested())
      ..add(const FeaturedProductsRequested());
    context.read<CategoryBloc>().add(const CategoriesLoadRequested());

    _scrollCtrl.addListener(() {
      final collapsed = _scrollCtrl.position.userScrollDirection
          == ScrollDirection.reverse;
      if (collapsed != _appBarCollapsed) {
        setState(() => _appBarCollapsed = collapsed);
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      // Only rebuild scaffold when gradient colours change
      buildWhen: (p, c) =>
          p.activeGradientColors != c.activeGradientColors ||
          p.isLoading != c.isLoading,
      builder: (context, state) {
        return GradientScaffold(
          gradientColors: state.activeGradientColors,
          appBar: _DeliciousAppBar(collapsed: _appBarCollapsed),
          child: SafeArea(
            child: RefreshIndicator(
              color:       Colors.white,
              strokeWidth: 2,
              onRefresh: () async {
                context.read<ProductBloc>().add(const ProductRefreshRequested());
                // Wait for refresh to complete
                await Future.delayed(const Duration(milliseconds: 800));
              },
              child: CustomScrollView(
                controller: _scrollCtrl,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── Search bar ───────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: _SearchBar(),
                    ),
                  ),

                  // ── Category rail ────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: _CategoryRail(),
                    ),
                  ),

                  // ── Carousel or loading ──────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: _CarouselSection(),
                    ),
                  ),

                  // ── Pagination indicator ─────────────────────────────
                  SliverToBoxAdapter(
                    child: BlocBuilder<ProductBloc, ProductState>(
                      buildWhen: (p, c) =>
                          p.carouselIndex != c.carouselIndex ||
                          p.products.length != c.products.length,
                      builder: (_, state) => Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 32),
                        child: _DotIndicator(
                          count:   state.products.length,
                          current: state.carouselIndex,
                        ),
                      ),
                    ),
                  ),

                  // ── Load more trigger ────────────────────────────────
                  SliverToBoxAdapter(
                    child: BlocBuilder<ProductBloc, ProductState>(
                      buildWhen: (p, c) =>
                          p.isLoadingMore != c.isLoadingMore ||
                          p.hasMore != c.hasMore,
                      builder: (context, state) {
                        if (state.isLoadingMore) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(
                                color: Colors.white70, strokeWidth: 2,
                              ),
                            ),
                          );
                        }
                        if (state.hasMore && state.products.isNotEmpty) {
                          return Center(
                            child: TextButton(
                              onPressed: () => context
                                  .read<ProductBloc>()
                                  .add(const ProductsNextPageRequested()),
                              child: Text(
                                'Load more',
                                style: TextStyle(
                                  color:    Colors.white.withOpacity(0.70),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        }
                        return const SizedBox(height: 80);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppBar
// ─────────────────────────────────────────────────────────────────────────────

class _DeliciousAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _DeliciousAppBar({required this.collapsed});

  final bool collapsed;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      color: Colors.black.withOpacity(collapsed ? 0.20 : 0.0),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo / title
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Delicious',
                    style: const TextStyle(
                      color:      Colors.white,
                      fontSize:   26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      height:     1.0,
                    ),
                  ),
                  Text(
                    'What are you craving?',
                    style: TextStyle(
                      color:    Colors.white.withOpacity(0.60),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              // Cart icon
              BlocBuilder<ProductBloc, ProductState>(
                buildWhen: (_, __) => false,
                builder: (context, _) => _CartButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Carousel section with loading / error states
// ─────────────────────────────────────────────────────────────────────────────

class _CarouselSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      buildWhen: (p, c) =>
          p.isLoading != c.isLoading ||
          p.products  != c.products  ||
          p.errorMessage != c.errorMessage,
      builder: (context, state) {
        if (state.isLoading && state.products.isEmpty) {
          return const _CarouselSkeleton();
        }

        if (state.hasError && state.products.isEmpty) {
          return _ErrorCard(
            message:   state.errorMessage!,
            onRetry:   () => context.read<ProductBloc>()
                .add(const ProductsLoadRequested()),
          );
        }

        if (state.products.isEmpty) {
          return const _EmptyState();
        }

        return ProductRunwayCarousel(
          products:     state.products,
          initialIndex: state.carouselIndex,
          onAddToCart:  (product) {
            // Dispatch to CartBloc (injected separately)
            // context.read<CartBloc>().add(CartAddRequested(product));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${product.name} added to cart'),
                behavior:         SnackBarBehavior.floating,
                backgroundColor:  Colors.black87,
                duration:         const Duration(milliseconds: 1800),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            );
          },
          onProductTap: (product) {
            context.read<ProductBloc>().add(
                ProductDetailRequested(product.id));
            // Navigate: context.push('/product/${product.id}');
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category rail
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryRail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, state) {
        if (state is! CategoryLoaded) {
          return const SizedBox(height: 40);
        }

        final selected = (state as CategoryLoaded).selectedId;

        return SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding:         const EdgeInsets.symmetric(horizontal: 20),
            itemCount:       state.categories.length + 1, // +1 for "All"
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              if (i == 0) {
                return _CategoryChip(
                  label:      'All',
                  isSelected: selected == null,
                  onTap: () {
                    context.read<CategoryBloc>().add(
                        const CategoriesLoadRequested());
                    context.read<ProductBloc>().add(
                        const ProductCategoryChanged(null));
                  },
                );
              }
              final cat = state.categories[i - 1];
              return _CategoryChip(
                label:      cat.name,
                isSelected: selected == cat.id,
                onTap: () {
                  context.read<ProductBloc>().add(
                      ProductCategoryChanged(cat.id));
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String   label;
  final bool     isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding:  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(isSelected ? 0.0 : 0.25),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:      isSelected ? const Color(0xFF1A1A1A) : Colors.white,
            fontSize:   13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search bar
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color:        Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(
          color: Colors.white.withOpacity(0.25), width: 0.8),
      ),
      child: Row(children: [
        const SizedBox(width: 14),
        Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.60), size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _ctrl,
            style:     const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText:  'Search products...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 14),
              border:    InputBorder.none,
              isDense:   true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (q) => context.read<ProductBloc>().add(
                ProductSearchQueryChanged(q)),
          ),
        ),
        BlocBuilder<ProductBloc, ProductState>(
          buildWhen: (p, c) =>
              (p.activeFilter.searchQuery?.isNotEmpty ?? false) !=
              (c.activeFilter.searchQuery?.isNotEmpty ?? false),
          builder: (context, state) {
            if (!(state.activeFilter.searchQuery?.isNotEmpty ?? false)) {
              return const SizedBox(width: 14);
            }
            return GestureDetector(
              onTap: () {
                _ctrl.clear();
                context.read<ProductBloc>().add(const ProductSearchCleared());
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(Icons.close_rounded,
                    color: Colors.white.withOpacity(0.60), size: 18),
              ),
            );
          },
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dot page indicator
// ─────────────────────────────────────────────────────────────────────────────

class _DotIndicator extends StatelessWidget {
  const _DotIndicator({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final visible = count.clamp(0, 8); // show max 8 dots
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(visible, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve:    Curves.easeOutCubic,
          margin:   const EdgeInsets.symmetric(horizontal: 3),
          width:    isActive ? 22 : 6,
          height:   6,
          decoration: BoxDecoration(
            color:        Colors.white.withOpacity(isActive ? 0.95 : 0.35),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading skeleton
// ─────────────────────────────────────────────────────────────────────────────

class _CarouselSkeleton extends StatefulWidget {
  const _CarouselSkeleton();

  @override
  State<_CarouselSkeleton> createState() => _CarouselSkeletonState();
}

class _CarouselSkeletonState extends State<_CarouselSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _shimmer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _shimmer = Tween<double>(begin: 0.2, end: 0.50).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, __) => Container(
        height:  460,
        margin:  const EdgeInsets.symmetric(horizontal: 40),
        decoration: BoxDecoration(
          color:        Colors.white.withOpacity(_shimmer.value),
          borderRadius: BorderRadius.circular(32),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error card
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String     message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color:        Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, color: Colors.white70, size: 36),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onRetry,
            child: const Text('Try again',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🍽️', style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('No products found',
              style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 15)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cart button — placeholder (CartBloc wires in separately)
// ─────────────────────────────────────────────────────────────────────────────

class _CartButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color:        Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: const Icon(Icons.shopping_bag_outlined,
          color: Colors.white, size: 22),
    );
  }
}