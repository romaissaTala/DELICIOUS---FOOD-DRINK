// lib/features/products/presentation/widgets/filter_state.dart
import 'package:flutter/foundation.dart';

enum SortOption { recommended, priceLow, priceHigh, rating, newest, prepTime }
enum PriceRange  { any, under500, under1000, under2000, above2000 }

@immutable
class FilterState {
  final Set<String>  selectedMoods;
  final Set<String>  selectedCategories;
  final PriceRange   priceRange;
  final SortOption   sortBy;
  final bool         onlyAvailable;
  final bool         onlyFeatured;
  final bool         onlyDiscounted;
  final double?      minRating;

  const FilterState({
    this.selectedMoods      = const {},
    this.selectedCategories = const {},
    this.priceRange         = PriceRange.any,
    this.sortBy             = SortOption.recommended,
    this.onlyAvailable      = true,
    this.onlyFeatured       = false,
    this.onlyDiscounted     = false,
    this.minRating,
  });

  static const empty = FilterState();

  bool get isActive =>
      selectedMoods.isNotEmpty || selectedCategories.isNotEmpty ||
      priceRange != PriceRange.any || sortBy != SortOption.recommended ||
      onlyFeatured || onlyDiscounted || minRating != null;

  int get activeCount {
    var n = 0;
    if (selectedMoods.isNotEmpty)       n++;
    if (selectedCategories.isNotEmpty)  n++;
    if (priceRange != PriceRange.any)   n++;
    if (sortBy != SortOption.recommended) n++;
    if (onlyFeatured)   n++;
    if (onlyDiscounted) n++;
    if (minRating != null) n++;
    return n;
  }

  FilterState copyWith({
    Set<String>? selectedMoods, Set<String>? selectedCategories,
    PriceRange? priceRange, SortOption? sortBy,
    bool? onlyAvailable, bool? onlyFeatured, bool? onlyDiscounted,
    double? minRating, bool clearMinRating = false,
  }) => FilterState(
    selectedMoods:      selectedMoods      ?? this.selectedMoods,
    selectedCategories: selectedCategories ?? this.selectedCategories,
    priceRange:         priceRange         ?? this.priceRange,
    sortBy:             sortBy             ?? this.sortBy,
    onlyAvailable:      onlyAvailable      ?? this.onlyAvailable,
    onlyFeatured:       onlyFeatured       ?? this.onlyFeatured,
    onlyDiscounted:     onlyDiscounted     ?? this.onlyDiscounted,
    minRating:          clearMinRating ? null : minRating ?? this.minRating,
  );

  FilterState toggleMood(String mood) {
    final n = Set<String>.from(selectedMoods);
    n.contains(mood) ? n.remove(mood) : n.add(mood);
    return copyWith(selectedMoods: n);
  }

  FilterState toggleCategory(String id) {
    final n = Set<String>.from(selectedCategories);
    n.contains(id) ? n.remove(id) : n.add(id);
    return copyWith(selectedCategories: n);
  }

  @override
  bool operator ==(Object o) =>
      identical(this, o) || o is FilterState &&
      setEquals(o.selectedMoods, selectedMoods) &&
      setEquals(o.selectedCategories, selectedCategories) &&
      o.priceRange == priceRange && o.sortBy == sortBy &&
      o.onlyAvailable == onlyAvailable && o.onlyFeatured == onlyFeatured &&
      o.onlyDiscounted == onlyDiscounted && o.minRating == minRating;

  @override
  int get hashCode => Object.hash(selectedMoods, selectedCategories,
      priceRange, sortBy, onlyAvailable, onlyFeatured, onlyDiscounted, minRating);
}

extension SortOptionX on SortOption {
  String get label {
    switch (this) {
      case SortOption.recommended: return 'Recommended';
      case SortOption.priceLow:    return 'Price: Low → High';
      case SortOption.priceHigh:   return 'Price: High → Low';
      case SortOption.rating:      return 'Top Rated';
      case SortOption.newest:      return 'Newest';
      case SortOption.prepTime:    return 'Fastest';
    }
  }
  String get icon {
    switch (this) {
      case SortOption.recommended: return '✦';
      case SortOption.priceLow:    return '↑';
      case SortOption.priceHigh:   return '↓';
      case SortOption.rating:      return '★';
      case SortOption.newest:      return '◈';
      case SortOption.prepTime:    return '⚡';
    }
  }
}

extension PriceRangeX on PriceRange {
  String get label {
    switch (this) {
      case PriceRange.any:       return 'Any price';
      case PriceRange.under500:  return 'Under 500 DA';
      case PriceRange.under1000: return 'Under 1 000 DA';
      case PriceRange.under2000: return 'Under 2 000 DA';
      case PriceRange.above2000: return 'Above 2 000 DA';
    }
  }
}