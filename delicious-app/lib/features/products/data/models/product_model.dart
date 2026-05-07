// lib/features/products/data/models/product_model.dart
//
// Data-layer models with full JSON (de)serialisation and
// toEntity() mappers to the pure domain entities.

import '../../domain/entities/product.dart';
import '../../domain/entities/category.dart';

// ── ProductModel ──────────────────────────────────────────────────────────────

class ProductModel {
  final String              id;
  final String              name;
  final String?             description;
  final String?             brand;
  final double              price;
  final double              discountPercent;
  final String              categoryId;
  final List<String>        gradientColors;
  final List<String>        mood;
  final String              imageUrl;
  final String?             thumbnailUrl;
  final List<String>        imageGallery;
  final List<VariantModel>  variants;
  final NutritionModel?     nutrition;
  final bool                isAvailable;
  final int                 stock;
  final int                 preparationTimeMin;
  final bool                isFeatured;
  final RatingModel         rating;
  final List<String>        tags;

  const ProductModel({
    required this.id,
    required this.name,
    this.description,
    this.brand,
    required this.price,
    this.discountPercent    = 0,
    required this.categoryId,
    required this.gradientColors,
    this.mood               = const [],
    required this.imageUrl,
    this.thumbnailUrl,
    this.imageGallery       = const [],
    this.variants           = const [],
    this.nutrition,
    this.isAvailable        = true,
    this.stock              = 0,
    this.preparationTimeMin = 10,
    this.isFeatured         = false,
    this.rating             = const RatingModel(),
    this.tags               = const [],
  });

  factory ProductModel.fromJson(Map<String, dynamic> j) => ProductModel(
        id:              (j['_id'] ?? j['id']) as String,
        name:            j['name']             as String,
        description:     j['description']      as String?,
        brand:           j['brand']            as String?,
        price:           (j['price'] as num).toDouble(),
        discountPercent: (j['discountPercent'] as num?)?.toDouble() ?? 0,
        categoryId:      _extractId(j['categoryId']),
        gradientColors:  List<String>.from(j['gradientColors'] as List? ?? []),
        mood:            List<String>.from(j['mood']           as List? ?? []),
        imageUrl:        j['imageUrl']         as String,
        thumbnailUrl:    j['thumbnailUrl']     as String?,
        imageGallery:    List<String>.from(j['imageGallery']   as List? ?? []),
        variants:        (j['variants'] as List? ?? [])
            .map((v) => VariantModel.fromJson(v as Map<String, dynamic>))
            .toList(),
        nutrition: j['nutrition'] != null
            ? NutritionModel.fromJson(j['nutrition'] as Map<String, dynamic>)
            : null,
        isAvailable:        (j['isAvailable']        as bool?) ?? true,
        stock:              (j['stock']               as num?)?.toInt() ?? 0,
        preparationTimeMin: (j['preparationTimeMin']  as num?)?.toInt() ?? 10,
        isFeatured:         (j['isFeatured']          as bool?) ?? false,
        rating: j['rating'] != null
            ? RatingModel.fromJson(j['rating'] as Map<String, dynamic>)
            : const RatingModel(),
        tags: List<String>.from(j['tags'] as List? ?? []),
      );

  /// MongoDB can return categoryId as either a plain String or a populated Object.
  static String _extractId(dynamic value) {
    if (value is String) return value;
    if (value is Map)    return value['_id'] as String? ?? '';
    return '';
  }

  Product toEntity() => Product(
        id:                 id,
        name:               name,
        description:        description,
        brand:              brand,
        price:              price,
        discountPercent:    discountPercent,
        categoryId:         categoryId,
        gradientColors:     gradientColors,
        mood:               mood,
        imageUrl:           imageUrl,
        thumbnailUrl:       thumbnailUrl,
        imageGallery:       imageGallery,
        variants:           variants.map((v) => v.toEntity()).toList(),
        nutrition:          nutrition?.toEntity(),
        isAvailable:        isAvailable,
        stock:              stock,
        preparationTimeMin: preparationTimeMin,
        isFeatured:         isFeatured,
        rating:             rating.toEntity(),
        tags:               tags,
      );
}

// ── Nested models ─────────────────────────────────────────────────────────────

class VariantModel {
  final String id;
  final String label;
  final double price;
  final int    stock;

  const VariantModel({
    required this.id,
    required this.label,
    required this.price,
    required this.stock,
  });

  factory VariantModel.fromJson(Map<String, dynamic> j) => VariantModel(
        id:    (j['_id'] ?? j['id']) as String,
        label: j['label']            as String,
        price: (j['price'] as num).toDouble(),
        stock: (j['stock'] as num?)?.toInt() ?? 0,
      );

  ProductVariant toEntity() =>
      ProductVariant(id: id, label: label, price: price, stock: stock);
}

class RatingModel {
  final double average;
  final int    count;

  const RatingModel({this.average = 0, this.count = 0});

  factory RatingModel.fromJson(Map<String, dynamic> j) => RatingModel(
        average: (j['average'] as num?)?.toDouble() ?? 0,
        count:   (j['count']   as num?)?.toInt()    ?? 0,
      );

  ProductRating toEntity() => ProductRating(average: average, count: count);
}

class NutritionModel {
  final int?    calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final double? sugar;
  final String? servingSize;

  const NutritionModel({
    this.calories, this.protein, this.carbs,
    this.fat, this.sugar, this.servingSize,
  });

  factory NutritionModel.fromJson(Map<String, dynamic> j) => NutritionModel(
        calories:    (j['calories']    as num?)?.toInt(),
        protein:     (j['protein']     as num?)?.toDouble(),
        carbs:       (j['carbs']       as num?)?.toDouble(),
        fat:         (j['fat']         as num?)?.toDouble(),
        sugar:       (j['sugar']       as num?)?.toDouble(),
        servingSize: j['servingSize']  as String?,
      );

  ProductNutrition toEntity() => ProductNutrition(
        calories: calories, protein: protein, carbs: carbs,
        fat: fat, sugar: sugar, servingSize: servingSize,
      );
}

// ── CategoryModel ─────────────────────────────────────────────────────────────

class CategoryModel {
  final String       id;
  final String       name;
  final String       type;
  final String       icon;
  final int          sortOrder;
  final bool         isActive;
  final List<String> gradientColors;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    this.sortOrder      = 0,
    this.isActive       = true,
    this.gradientColors = const ['#FF6B35', '#FF8C61'],
  });

  factory CategoryModel.fromJson(Map<String, dynamic> j) => CategoryModel(
        id:             (j['_id'] ?? j['id']) as String,
        name:           j['name']             as String,
        type:           j['type']             as String,
        icon:           j['icon']             as String,
        sortOrder:      (j['sortOrder']  as num?)?.toInt() ?? 0,
        isActive:       (j['isActive']   as bool?) ?? true,
        gradientColors: List<String>.from(j['gradientColors'] as List? ?? []),
      );

  Category toEntity() => Category(
        id:             id,
        name:           name,
        type:           type,
        icon:           icon,
        sortOrder:      sortOrder,
        isActive:       isActive,
        gradientColors: gradientColors,
      );
}

// ── Paginated response wrapper ────────────────────────────────────────────────

class ProductPageModel {
  final List<ProductModel> products;
  final int                total;
  final int                page;
  final int                limit;
  final bool               hasMore;

  const ProductPageModel({
    required this.products,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasMore,
  });

  factory ProductPageModel.fromJson(Map<String, dynamic> j) {
    final items = (j['products'] as List? ?? [])
        .map((p) => ProductModel.fromJson(p as Map<String, dynamic>))
        .toList();
    final total = (j['total'] as num?)?.toInt() ?? items.length;
    final page  = (j['page']  as num?)?.toInt() ?? 1;
    final limit = (j['limit'] as num?)?.toInt() ?? 20;
    return ProductPageModel(
      products: items,
      total:    total,
      page:     page,
      limit:    limit,
      hasMore:  (page * limit) < total,
    );
  }
}