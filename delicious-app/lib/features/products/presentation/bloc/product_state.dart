// lib/features/products/presentation/bloc/product_state.dart
part of 'product_bloc.dart';

// ── Filter model — lives inside state ────────────────────────────────────────

class ProductFilter extends Equatable {
  final String? categoryId;
  final String? mood;
  final String? searchQuery;

  const ProductFilter({this.categoryId, this.mood, this.searchQuery});

  bool get isActive =>
      categoryId != null || mood != null || (searchQuery?.isNotEmpty ?? false);

  ProductFilter copyWith({
    String? categoryId,
    String? mood,
    String? searchQuery,
    bool    clearCategory  = false,
    bool    clearMood      = false,
    bool    clearSearch    = false,
  }) =>
      ProductFilter(
        categoryId:  clearCategory ? null : categoryId  ?? this.categoryId,
        mood:        clearMood     ? null : mood         ?? this.mood,
        searchQuery: clearSearch   ? null : searchQuery  ?? this.searchQuery,
      );

  @override
  List<Object?> get props => [categoryId, mood, searchQuery];
}

// ── Main state ────────────────────────────────────────────────────────────────

class ProductState extends Equatable {
  // ── Product listing ───────────────────────────────────────────────────────
  final List<Product>    products;
  final List<Product>    featuredProducts;
  final bool             isLoading;        // initial / full-screen load
  final bool             isLoadingMore;    // pagination spinner at bottom
  final bool             isRefreshing;     // pull-to-refresh indicator
  final bool             hasMore;          // more pages available
  final int              currentPage;
  final String?          errorMessage;

  // ── Detail ────────────────────────────────────────────────────────────────
  final Product?         selectedProduct;
  final bool             isLoadingDetail;
  final String?          detailError;

  // ── Carousel / UI state ───────────────────────────────────────────────────
  final int              carouselIndex;    // drives the gradient animation

  // ── Filters ───────────────────────────────────────────────────────────────
  final ProductFilter    activeFilter;

  const ProductState({
    this.products         = const [],
    this.featuredProducts = const [],
    this.isLoading        = false,
    this.isLoadingMore    = false,
    this.isRefreshing     = false,
    this.hasMore          = true,
    this.currentPage      = 1,
    this.errorMessage,
    this.selectedProduct,
    this.isLoadingDetail  = false,
    this.detailError,
    this.carouselIndex    = 0,
    this.activeFilter     = const ProductFilter(),
  });

  // ── Convenience getters ───────────────────────────────────────────────────

  bool get hasProducts => products.isNotEmpty;
  bool get hasError    => errorMessage != null;

  /// The product currently centred in the carousel.
  Product? get activeCarouselProduct =>
      products.isNotEmpty && carouselIndex < products.length
          ? products[carouselIndex]
          : null;

  /// The two gradient colours that should be animated to on the scaffold.
  List<String> get activeGradientColors =>
      activeCarouselProduct?.gradientColors ??
      ['#FF6B35', '#FF8C61'];

  ProductState copyWith({
    List<Product>?    products,
    List<Product>?    featuredProducts,
    bool?             isLoading,
    bool?             isLoadingMore,
    bool?             isRefreshing,
    bool?             hasMore,
    int?              currentPage,
    String?           errorMessage,
    bool              clearError     = false,
    Product?          selectedProduct,
    bool              clearSelected  = false,
    bool?             isLoadingDetail,
    String?           detailError,
    bool              clearDetailError = false,
    int?              carouselIndex,
    ProductFilter?    activeFilter,
  }) =>
      ProductState(
        products:         products         ?? this.products,
        featuredProducts: featuredProducts ?? this.featuredProducts,
        isLoading:        isLoading        ?? this.isLoading,
        isLoadingMore:    isLoadingMore    ?? this.isLoadingMore,
        isRefreshing:     isRefreshing     ?? this.isRefreshing,
        hasMore:          hasMore          ?? this.hasMore,
        currentPage:      currentPage      ?? this.currentPage,
        errorMessage:     clearError       ? null : errorMessage ?? this.errorMessage,
        selectedProduct:  clearSelected    ? null : selectedProduct ?? this.selectedProduct,
        isLoadingDetail:  isLoadingDetail  ?? this.isLoadingDetail,
        detailError:      clearDetailError ? null : detailError   ?? this.detailError,
        carouselIndex:    carouselIndex    ?? this.carouselIndex,
        activeFilter:     activeFilter     ?? this.activeFilter,
      );

  @override
  List<Object?> get props => [
        products,
        featuredProducts,
        isLoading,
        isLoadingMore,
        isRefreshing,
        hasMore,
        currentPage,
        errorMessage,
        selectedProduct,
        isLoadingDetail,
        detailError,
        carouselIndex,
        activeFilter,
      ];
}