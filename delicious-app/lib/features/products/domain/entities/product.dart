// lib/features/products/domain/entities/product.dart
import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String       id;
  final String       name;
  final String?      description;
  final String?      brand;
  final double       price;
  final double       discountPercent;
  final String       categoryId;
  final List<String> gradientColors;   // always 2 hex strings, e.g. ["#CC0000","#FF4444"]
  final List<String> mood;             // e.g. ["cold","sweet"]
  final String       imageUrl;
  final String?      thumbnailUrl;
  final List<String> imageGallery;
  final List<ProductVariant> variants;
  final ProductNutrition?    nutrition;
  final bool         isAvailable;
  final int          stock;
  final int          preparationTimeMin;
  final bool         isFeatured;
  final ProductRating rating;
  final List<String> tags;

  const Product({
    required this.id,
    required this.name,
    this.description,
    this.brand,
    required this.price,
    this.discountPercent = 0,
    required this.categoryId,
    required this.gradientColors,
    this.mood            = const [],
    required this.imageUrl,
    this.thumbnailUrl,
    this.imageGallery    = const [],
    this.variants        = const [],
    this.nutrition,
    this.isAvailable     = true,
    this.stock           = 0,
    this.preparationTimeMin = 10,
    this.isFeatured      = false,
    this.rating          = const ProductRating(),
    this.tags            = const [],
  });

  double get finalPrice =>
      double.parse((price * (1 - discountPercent / 100)).toStringAsFixed(2));

  bool get hasDiscount   => discountPercent > 0;
  bool get isInStock     => isAvailable && stock > 0;

  /// Primary gradient colour — used for the animated background tween.
  String get primaryColor   => gradientColors.isNotEmpty ? gradientColors[0] : '#FF6B35';
  String get secondaryColor => gradientColors.length > 1  ? gradientColors[1] : '#FF8C61';

  @override
  List<Object?> get props => [id, name, price, categoryId, isAvailable];
}

// ── Value objects ─────────────────────────────────────────────────────────────

class ProductVariant extends Equatable {
  final String id;
  final String label;
  final double price;
  final int    stock;
  const ProductVariant({
    required this.id,
    required this.label,
    required this.price,
    required this.stock,
  });
  @override
  List<Object> get props => [id, label, price];
}

class ProductRating extends Equatable {
  final double average;
  final int    count;
  const ProductRating({this.average = 0, this.count = 0});
  @override
  List<Object> get props => [average, count];
}

class ProductNutrition extends Equatable {
  final int?    calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final double? sugar;
  final String? servingSize;
  const ProductNutrition({
    this.calories, this.protein, this.carbs,
    this.fat, this.sugar, this.servingSize,
  });
  @override
  List<Object?> get props => [calories, protein, carbs, fat, sugar, servingSize];
}