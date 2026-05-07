import 'package:Delicious_App/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:Delicious_App/features/cart/widgets/fly_to_cart.dart';
import 'package:Delicious_App/features/products/domain/entities/product.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/product_bloc.dart';
import '../bloc/category_bloc.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/product_runway_carousel.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scrollController = ScrollController();
  final _cartKey = GlobalKey<CartIconButtonState>();
  bool _isAppBarCollapsed = false;

  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(const ProductsLoadRequested());
    context.read<ProductBloc>().add(const FeaturedProductsRequested());
    context.read<CategoryBloc>().add(const CategoriesLoadRequested());

    _scrollController.addListener(() {
      final collapsed = _scrollController.position.userScrollDirection ==
          ScrollDirection.reverse;
      if (collapsed != _isAppBarCollapsed) {
        setState(() => _isAppBarCollapsed = collapsed);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      buildWhen: (previous, current) =>
          previous.activeGradientColors != current.activeGradientColors ||
          previous.isLoading != current.isLoading,
      builder: (context, state) {
        return GradientScaffold(
          gradientColors: state.activeGradientColors,
          appBar:
              _buildAppBar(state.isLoading), // Now returns PreferredSizeWidget
          child: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                context
                    .read<ProductBloc>()
                    .add(const ProductRefreshRequested());
                await Future.delayed(const Duration(milliseconds: 800));
              },
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildSearchBar()),
                  SliverToBoxAdapter(child: _buildCategoriesRail()),
                  SliverToBoxAdapter(child: _buildFeaturedSection()),
                  SliverToBoxAdapter(child: _buildProductCarousel(state)),
                  SliverToBoxAdapter(child: _buildDotIndicator(state)),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ✅ FIXED: Returns PreferredSizeWidget (AppBar)
  PreferredSizeWidget _buildAppBar(bool isLoading) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 0,
      toolbarHeight: 80,
      automaticallyImplyLeading: false,
      flexibleSpace: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        color: Colors.black.withOpacity(_isAppBarCollapsed ? 0.2 : 0.0),
      ),
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Delicious',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
                Text(
                  isLoading ? 'Loading...' : 'What are you craving?',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            // Cart Icon with Badge
            BlocBuilder<CartBloc, CartState>(
              builder: (context, cartState) {
                int itemCount = 0;
                if (cartState is CartLoaded) {
                  itemCount = cartState.cart.itemCount;
                }
                return CartIconButton(
                  key: _cartKey,
                  itemCount: itemCount,
                  onTap: () => Navigator.pushNamed(context, '/cart'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final searchController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Icon(Icons.search_rounded,
                color: Colors.white.withOpacity(0.6), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.45)),
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: (query) {
                  context
                      .read<ProductBloc>()
                      .add(ProductSearchQueryChanged(query));
                },
              ),
            ),
            GestureDetector(
              onTap: () => _showVoiceSearchDialog(),
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(Icons.mic,
                    color: Colors.white.withOpacity(0.6), size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesRail() {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, state) {
        if (state is! CategoryLoaded) {
          return const SizedBox(height: 40);
        }

        final categories = state.categories;
        final selectedId = state.selectedId;

        return SizedBox(
          height: 50,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: categories.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _CategoryChip(
                  label: 'All',
                  icon: Icons.grid_view,
                  isSelected: selectedId == null,
                  onTap: () {
                    context
                        .read<CategoryBloc>()
                        .add(const CategoriesLoadRequested());
                    context
                        .read<ProductBloc>()
                        .add(const ProductCategoryChanged(null));
                  },
                );
              }
              final category = categories[index - 1];
              return _CategoryChip(
                label: category.name,
                icon: _getCategoryIcon(category.icon),
                isSelected: selectedId == category.id,
                onTap: () {
                  context
                      .read<ProductBloc>()
                      .add(ProductCategoryChanged(category.id));
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFeaturedSection() {
    return BlocBuilder<ProductBloc, ProductState>(
      buildWhen: (previous, current) =>
          previous.featuredProducts != current.featuredProducts,
      builder: (context, state) {
        if (state.featuredProducts.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Text(
                  'Featured 🔥',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: state.featuredProducts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final product = state.featuredProducts[index];
                    return _FeaturedCard(
                      product: product,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/product/${product.id}',
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductCarousel(ProductState state) {
    if (state.isLoading && state.products.isEmpty) {
      return const _CarouselSkeleton();
    }

    if (state.hasError && state.products.isEmpty) {
      return _ErrorCard(
        message: state.errorMessage!,
        onRetry: () =>
            context.read<ProductBloc>().add(const ProductsLoadRequested()),
      );
    }

    if (state.products.isEmpty) {
      return const _EmptyCarousel();
    }

    return ProductRunwayCarousel(
      products: state.products,
      initialIndex: state.carouselIndex,
      onAddToCart: (product) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} added to cart'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.black87,
            duration: const Duration(milliseconds: 1500),
          ),
        );

        context.read<CartBloc>().add(AddToCartEvent(
              userId: '',
              productId: product.id,
              productName: product.name,
              productImageUrl: product.imageUrl,
              unitPrice: product.finalPrice,
              quantity: 1,
              gradientColors: product.gradientColors,
            ));
      },
      onProductTap: (product) {
        Navigator.pushNamed(context, '/product/${product.id}');
      },
    );
  }

  Widget _buildDotIndicator(ProductState state) {
    if (state.products.length <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          state.products.length.clamp(0, 8),
          (index) {
            final isActive = index == state.carouselIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 22 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(isActive ? 0.95 : 0.35),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showVoiceSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Voice Search'),
        content: const Text('Voice search feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String icon) {
    switch (icon) {
      case 'burger':
        return Icons.lunch_dining;
      case 'couscous':
        return Icons.kitchen;
      case 'juice_glass':
        return Icons.local_drink;
      case 'coffee_cup':
        return Icons.coffee;
      case 'cake':
        return Icons.cake;
      default:
        return Icons.category;
    }
  }
}

// ───────────────────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(isSelected ? 0 : 0.25),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 16, color: isSelected ? Colors.black : Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _FeaturedCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                product.imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 120,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image_not_supported),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.finalPrice} DZD',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarouselSkeleton extends StatelessWidget {
  const _CarouselSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 460,
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(32),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}

class _EmptyCarousel extends StatelessWidget {
  const _EmptyCarousel();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🍽️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white70, size: 36),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onRetry,
            child:
                const Text('Try Again', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
