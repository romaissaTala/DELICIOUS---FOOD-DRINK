// lib/features/products/presentation/bloc/product_event.dart
part of 'product_bloc.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();
  @override
  List<Object?> get props => [];
}

/// Load or reload the first page of products for the current filters.
class ProductsLoadRequested extends ProductEvent {
  final String? categoryId;
  final String? mood;
  const ProductsLoadRequested({this.categoryId, this.mood});
  @override
  List<Object?> get props => [categoryId, mood];
}

/// Fetch the next page — triggered by infinite scroll reaching the bottom.
class ProductsNextPageRequested extends ProductEvent {
  const ProductsNextPageRequested();
}

/// User selects a category from the filter rail.
class ProductCategoryChanged extends ProductEvent {
  final String? categoryId; // null = All
  const ProductCategoryChanged(this.categoryId);
  @override
  List<Object?> get props => [categoryId];
}

/// User picks a mood tag ("cold", "hot", "sweet"…).
class ProductMoodChanged extends ProductEvent {
  final String? mood; // null = clear mood filter
  const ProductMoodChanged(this.mood);
  @override
  List<Object?> get props => [mood];
}

/// User types in the search bar. Debounced in the Bloc.
class ProductSearchQueryChanged extends ProductEvent {
  final String query;
  const ProductSearchQueryChanged(this.query);
  @override
  List<Object> get props => [query];
}

/// Clear search text and reset to default listing.
class ProductSearchCleared extends ProductEvent {
  const ProductSearchCleared();
}

/// Tap on a product card → load its full details.
class ProductDetailRequested extends ProductEvent {
  final String productId;
  const ProductDetailRequested(this.productId);
  @override
  List<Object> get props => [productId];
}

/// Home banner requests featured products.
class FeaturedProductsRequested extends ProductEvent {
  const FeaturedProductsRequested();
}

/// Pull-to-refresh or explicit cache invalidation.
class ProductRefreshRequested extends ProductEvent {
  const ProductRefreshRequested();
}

/// Carousel page changed — used only to update the active index in state
/// so the gradient can animate. No network call.
class ProductCarouselIndexChanged extends ProductEvent {
  final int index;
  const ProductCarouselIndexChanged(this.index);
  @override
  List<Object> get props => [index];
}