// lib/features/products/presentation/bloc/category_bloc.dart
//
// Intentionally kept separate from ProductBloc.
// Categories are fetched once and rarely change — a dedicated tiny Bloc
// keeps the ProductBloc state lean and avoids unnecessary rebuilds in the
// category rail widget.

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/category.dart';
import '../../domain/usecases/product_usecases.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class CategoryEvent extends Equatable {
  const CategoryEvent();
  @override
  List<Object?> get props => [];
}

class CategoriesLoadRequested extends CategoryEvent {
  const CategoriesLoadRequested();
}

// ── States ────────────────────────────────────────────────────────────────────

abstract class CategoryState extends Equatable {
  const CategoryState();
  @override
  List<Object?> get props => [];
}

class CategoryInitial extends CategoryState {
  const CategoryInitial();
}

class CategoryLoading extends CategoryState {
  const CategoryLoading();
}

class CategoryLoaded extends CategoryState {
  final List<Category> categories;
  final String?        selectedId; // null = "All"
  const CategoryLoaded({required this.categories, this.selectedId});

  CategoryLoaded select(String? id) =>
      CategoryLoaded(categories: categories, selectedId: id);

  @override
  List<Object?> get props => [categories, selectedId];
}

class CategoryError extends CategoryState {
  final String message;
  const CategoryError(this.message);
  @override
  List<Object> get props => [message];
}

// ── Bloc ──────────────────────────────────────────────────────────────────────

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final GetCategoriesUseCase _getCategories;

  CategoryBloc({required GetCategoriesUseCase getCategories})
      : _getCategories = getCategories,
        super(const CategoryInitial()) {
    on<CategoriesLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    CategoriesLoadRequested event,
    Emitter<CategoryState> emit,
  ) async {
    // Don't reload if already loaded
    if (state is CategoryLoaded) return;

    emit(const CategoryLoading());

    final result = await _getCategories();
    result.fold(
      (failure) => emit(CategoryError(failure.message)),
      (cats)    => emit(CategoryLoaded(categories: cats)),
    );
  }
}