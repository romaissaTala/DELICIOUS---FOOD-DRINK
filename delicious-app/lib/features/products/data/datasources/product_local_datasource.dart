// lib/features/products/data/datasources/product_local_datasource.dart
//
// Caches product and category data in Hive so the app works offline
// and the first paint is instant (stale-while-revalidate pattern).

import 'dart:convert';

import 'package:hive/hive.dart';

import '../models/product_model.dart';

// ── Cache keys ────────────────────────────────────────────────────────────────

abstract class _K {
  static const categories       = 'categories';
  static const featuredProducts = 'featured_products';
  static const cacheTimestamp   = 'cache_timestamp';
  static String products(String suffix) => 'products_$suffix';
  static String product(String id)      => 'product_$id';
}

const _cacheTtlMinutes = 15;

// ── Contract ──────────────────────────────────────────────────────────────────

abstract class ProductLocalDataSource {
  Future<void>                cacheProducts(String key, ProductPageModel page);
  Future<ProductPageModel?>   getCachedProducts(String key);
  Future<void>                cacheProduct(ProductModel product);
  Future<ProductModel?>       getCachedProduct(String id);
  Future<void>                cacheCategories(List<CategoryModel> categories);
  Future<List<CategoryModel>?> getCachedCategories();
  Future<void>                cacheFeaturedProducts(List<ProductModel> products);
  Future<List<ProductModel>?> getCachedFeaturedProducts();
  Future<bool>                isCacheValid();
  Future<void>                clearCache();
}

// ── Implementation ────────────────────────────────────────────────────────────

class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  final Box _box;
  const ProductLocalDataSourceImpl({required Box productBox}) : _box = productBox;

  // ── TTL check ─────────────────────────────────────────────────────────────

  @override
  Future<bool> isCacheValid() async {
    final ts = _box.get(_K.cacheTimestamp) as int?;
    if (ts == null) return false;
    final age = DateTime.now().millisecondsSinceEpoch - ts;
    return age < _cacheTtlMinutes * 60 * 1000;
  }

  void _touch() => _box.put(_K.cacheTimestamp, DateTime.now().millisecondsSinceEpoch);

  // ── Products page ─────────────────────────────────────────────────────────

  @override
  Future<void> cacheProducts(String key, ProductPageModel page) async {
    final json = {
      'products': page.products.map(_productToMap).toList(),
      'total':    page.total,
      'page':     page.page,
      'limit':    page.limit,
      'hasMore':  page.hasMore,
    };
    await _box.put(_K.products(key), jsonEncode(json));
    _touch();
  }

  @override
  Future<ProductPageModel?> getCachedProducts(String key) async {
    final raw = _box.get(_K.products(key)) as String?;
    if (raw == null) return null;
    return ProductPageModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  // ── Single product ────────────────────────────────────────────────────────

  @override
  Future<void> cacheProduct(ProductModel product) async {
    await _box.put(_K.product(product.id), jsonEncode(_productToMap(product)));
  }

  @override
  Future<ProductModel?> getCachedProduct(String id) async {
    final raw = _box.get(_K.product(id)) as String?;
    if (raw == null) return null;
    return ProductModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  // ── Categories ────────────────────────────────────────────────────────────

  @override
  Future<void> cacheCategories(List<CategoryModel> categories) async {
    final list = categories.map(_categoryToMap).toList();
    await _box.put(_K.categories, jsonEncode(list));
    _touch();
  }

  @override
  Future<List<CategoryModel>?> getCachedCategories() async {
    final raw = _box.get(_K.categories) as String?;
    if (raw == null) return null;
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Featured products ─────────────────────────────────────────────────────

  @override
  Future<void> cacheFeaturedProducts(List<ProductModel> products) async {
    final list = products.map(_productToMap).toList();
    await _box.put(_K.featuredProducts, jsonEncode(list));
    _touch();
  }

  @override
  Future<List<ProductModel>?> getCachedFeaturedProducts() async {
    final raw = _box.get(_K.featuredProducts) as String?;
    if (raw == null) return null;
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Clear ─────────────────────────────────────────────────────────────────

  @override
  Future<void> clearCache() async {
    await _box.clear();
  }

  // ── Private serialisers ───────────────────────────────────────────────────
  // Simple Map builders — in production replace with freezed toJson().

  Map<String, dynamic> _productToMap(ProductModel p) => {
        '_id':                 p.id,
        'name':                p.name,
        'description':         p.description,
        'brand':               p.brand,
        'price':               p.price,
        'discountPercent':     p.discountPercent,
        'categoryId':          p.categoryId,
        'gradientColors':      p.gradientColors,
        'mood':                p.mood,
        'imageUrl':            p.imageUrl,
        'thumbnailUrl':        p.thumbnailUrl,
        'imageGallery':        p.imageGallery,
        'isAvailable':         p.isAvailable,
        'stock':               p.stock,
        'preparationTimeMin':  p.preparationTimeMin,
        'isFeatured':          p.isFeatured,
        'tags':                p.tags,
        'rating': {
          'average': p.rating.average,
          'count':   p.rating.count,
        },
      };

  Map<String, dynamic> _categoryToMap(CategoryModel c) => {
        '_id':            c.id,
        'name':           c.name,
        'type':           c.type,
        'icon':           c.icon,
        'sortOrder':      c.sortOrder,
        'isActive':       c.isActive,
        'gradientColors': c.gradientColors,
      };
}