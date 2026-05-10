// lib/features/products/presentation/bloc/product_bloc.dart
import 'dart:async';

import 'package:Delicious_App/features/products/domain/usecases/get_featured_products_usecase.dart';
import 'package:Delicious_App/features/products/domain/usecases/get_product_by_id_usecase.dart';
import 'package:Delicious_App/features/products/domain/usecases/get_products_by_mood_params.dart';
import 'package:Delicious_App/features/products/domain/usecases/get_products_by_mood_usecase.dart';
import 'package:Delicious_App/features/products/domain/usecases/get_products_params.dart';
import 'package:Delicious_App/features/products/domain/usecases/get_products_usecase.dart';

import 'package:Delicious_App/features/products/domain/usecases/refresh_product_cache_usecase.dart';
import 'package:Delicious_App/features/products/domain/usecases/search_products_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/product.dart';


part 'product_event.dart';
part 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetProductsUseCase        _getProducts;
  final GetProductByIdUseCase     _getProductById;
  final GetProductsByMoodUseCase  _getProductsByMood;
  final GetFeaturedProductsUseCase _getFeatured;
  final SearchProductsUseCase     _searchProducts;
  final RefreshProductCacheUseCase _refreshCache;

  // Debounce timer for search — avoids an API call on every keystroke
  Timer? _searchDebounce;
  static const _searchDebounceMs = 400;

  ProductBloc({
    required GetProductsUseCase         getProducts,
    required GetProductByIdUseCase      getProductById,
    required GetProductsByMoodUseCase   getProductsByMood,
    required GetFeaturedProductsUseCase getFeatured,
    required SearchProductsUseCase      searchProducts,
    required RefreshProductCacheUseCase refreshCache,
  })  : _getProducts       = getProducts,
        _getProductById    = getProductById,
        _getProductsByMood = getProductsByMood,
        _getFeatured       = getFeatured,
        _searchProducts    = searchProducts,
        _refreshCache      = refreshCache,
        super(const ProductState()) {

    on<ProductsLoadRequested>       (_onLoadRequested);
    on<ProductsNextPageRequested>   (_onNextPage);
    on<ProductCategoryChanged>      (_onCategoryChanged);
    on<ProductMoodChanged>          (_onMoodChanged);
    on<ProductSearchQueryChanged>   (_onSearchQueryChanged);
    on<ProductSearchCleared>        (_onSearchCleared);
    on<ProductDetailRequested>      (_onDetailRequested);
    on<FeaturedProductsRequested>   (_onFeaturedRequested);
    on<ProductRefreshRequested>     (_onRefreshRequested);
    on<ProductCarouselIndexChanged> (_onCarouselIndexChanged);
  }

  // ── ProductsLoadRequested ──────────────────────────────────────────────────
  // Full reset: clears existing products and loads page 1.

  Future<void> _onLoadRequested(
    ProductsLoadRequested event,
    Emitter<ProductState> emit,
  ) async {
    final filter = state.activeFilter.copyWith(
      categoryId: event.categoryId,
      mood:       event.mood,
    );

    emit(state.copyWith(
      isLoading:    true,
      clearError:   true,
      currentPage:  1,
      activeFilter: filter,
    ));

    final result = await _getProducts(GetProductsParams(
      categoryId: filter.categoryId,
      mood:       filter.mood,
      page:       1,
    ));

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading:    false,
        errorMessage: failure.message,
      )),
      (page) => emit(state.copyWith(
        isLoading:    false,
        products:     page.products,
        hasMore:      page.hasMore,
        currentPage:  1,
        carouselIndex: 0,
        clearError:   true,
      )),
    );
  }

  // ── ProductsNextPageRequested ──────────────────────────────────────────────
  // Appends the next page to the existing list (infinite scroll).

  Future<void> _onNextPage(
    ProductsNextPageRequested event,
    Emitter<ProductState> emit,
  ) async {
    if (state.isLoadingMore || !state.hasMore) return;

    final nextPage = state.currentPage + 1;
    emit(state.copyWith(isLoadingMore: true));

    final result = await _getProducts(GetProductsParams(
      categoryId: state.activeFilter.categoryId,
      mood:       state.activeFilter.mood,
      page:       nextPage,
    ));

    result.fold(
      (failure) => emit(state.copyWith(
        isLoadingMore: false,
        errorMessage:  failure.message,
      )),
      (page) => emit(state.copyWith(
        isLoadingMore: false,
        products:      [...state.products, ...page.products],
        hasMore:       page.hasMore,
        currentPage:   nextPage,
      )),
    );
  }

  // ── ProductCategoryChanged ─────────────────────────────────────────────────

  Future<void> _onCategoryChanged(
    ProductCategoryChanged event,
    Emitter<ProductState> emit,
  ) async {
    final filter = state.activeFilter.copyWith(
      categoryId:   event.categoryId,
      clearCategory: event.categoryId == null,
      clearSearch:  true,
    );
    add(ProductsLoadRequested(
      categoryId: filter.categoryId,
      mood:       filter.mood,
    ));
  }

  // ── ProductMoodChanged ─────────────────────────────────────────────────────

  Future<void> _onMoodChanged(
    ProductMoodChanged event,
    Emitter<ProductState> emit,
  ) async {
    if (event.mood == null) {
      // Clear mood filter — reload with existing category
      add(ProductsLoadRequested(categoryId: state.activeFilter.categoryId));
      return;
    }

    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await _getProductsByMood(
      GetProductsByMoodParams([event.mood!]),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading:    false,
        errorMessage: failure.message,
      )),
      (products) => emit(state.copyWith(
        isLoading:    false,
        products:     products,
        hasMore:      false,           // mood results are not paginated
        currentPage:  1,
        carouselIndex: 0,
        activeFilter: state.activeFilter.copyWith(mood: event.mood),
        clearError:   true,
      )),
    );
  }

  // ── ProductSearchQueryChanged ──────────────────────────────────────────────
  // Debounced: only triggers a network call 400 ms after the user stops typing.

  Future<void> _onSearchQueryChanged(
    ProductSearchQueryChanged event,
    Emitter<ProductState> emit,
  ) async {
    _searchDebounce?.cancel();

    if (event.query.trim().isEmpty) {
      add(const ProductSearchCleared());
      return;
    }

    // Update the filter immediately so the search field reflects current text
    emit(state.copyWith(
      activeFilter: state.activeFilter.copyWith(searchQuery: event.query),
    ));

    _searchDebounce = Timer(
      const Duration(milliseconds: _searchDebounceMs),
      () => add(_SearchExecuted(event.query)),
    );
  }

  // Internal event fired after the debounce window
  Future<void> _onSearchExecuted(
    _SearchExecuted event,
    Emitter<ProductState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await _searchProducts(event.query);

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading:    false,
        errorMessage: failure.message,
      )),
      (products) => emit(state.copyWith(
        isLoading:     false,
        products:      products,
        hasMore:       false,
        currentPage:   1,
        carouselIndex: 0,
        clearError:    true,
      )),
    );
  }

  // ── ProductSearchCleared ───────────────────────────────────────────────────

  Future<void> _onSearchCleared(
    ProductSearchCleared event,
    Emitter<ProductState> emit,
  ) async {
    _searchDebounce?.cancel();
    final filter = state.activeFilter.copyWith(clearSearch: true);
    add(ProductsLoadRequested(
      categoryId: filter.categoryId,
      mood:       filter.mood,
    ));
  }

  // ── ProductDetailRequested ─────────────────────────────────────────────────

  Future<void> _onDetailRequested(
    ProductDetailRequested event,
    Emitter<ProductState> emit,
  ) async {
    // Optimistic: if already in the list, show it immediately
    final existing = state.products
        .where((p) => p.id == event.productId)
        .firstOrNull;

    emit(state.copyWith(
      selectedProduct:  existing,
      isLoadingDetail:  existing == null,
      clearDetailError: true,
    ));

    final result = await _getProductById(event.productId);

    result.fold(
      (failure) => emit(state.copyWith(
        isLoadingDetail: false,
        detailError:     failure.message,
      )),
      (product) => emit(state.copyWith(
        isLoadingDetail: false,
        selectedProduct: product,
      )),
    );
  }

  // ── FeaturedProductsRequested ──────────────────────────────────────────────

  Future<void> _onFeaturedRequested(
    FeaturedProductsRequested event,
    Emitter<ProductState> emit,
  ) async {
    final result = await _getFeatured();
    result.fold(
      (_) => null, // silent failure — featured is non-critical
      (products) => emit(state.copyWith(featuredProducts: products)),
    );
  }

  // ── ProductRefreshRequested ────────────────────────────────────────────────

  Future<void> _onRefreshRequested(
    ProductRefreshRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true));
    await _refreshCache();
    emit(state.copyWith(isRefreshing: false));
    add(ProductsLoadRequested(
      categoryId: state.activeFilter.categoryId,
      mood:       state.activeFilter.mood,
    ));
  }

  // ── ProductCarouselIndexChanged ────────────────────────────────────────────
  // Pure UI state update — no network call.
  // The ProductState.activeGradientColors getter reads this index,
  // so the animated scaffold gradient reacts instantly.

  Future<void> _onCarouselIndexChanged(
    ProductCarouselIndexChanged event,
    Emitter<ProductState> emit,
  ) async {
    emit(state.copyWith(carouselIndex: event.index));
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }
}

// ── Private internal event (search debounce) ──────────────────────────────────

class _SearchExecuted extends ProductEvent {
  final String query;
  const _SearchExecuted(this.query);
  @override
  List<Object> get props => [query];
}

// Register it in the constructor — add this inside the Bloc constructor body:
// on<_SearchExecuted>(_onSearchExecuted);