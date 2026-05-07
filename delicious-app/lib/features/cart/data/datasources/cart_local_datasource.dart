import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/cart_models.dart';

abstract class CartLocalDataSource {
  Future<void> cacheCart(CartModel cart);
  Future<CartModel?> getCachedCart();
  Future<void> clearCart();
  Future<void> addItemToLocalCart(CartItemModel item);
  Future<void> removeItemFromLocalCart(String itemId);
  Future<void> updateItemQuantity(String itemId, int quantity);
}

class CartLocalDataSourceImpl implements CartLocalDataSource {
  final Box _cartBox;
  
  CartLocalDataSourceImpl({required Box cartBox}) : _cartBox = cartBox;
  
  static const String _cartKey = 'cached_cart';
  
  @override
  Future<void> cacheCart(CartModel cart) async {
    // Now toJson() exists
    await _cartBox.put(_cartKey, jsonEncode(cart.toJson()));
  }
  
  @override
  Future<CartModel?> getCachedCart() async {
    final raw = _cartBox.get(_cartKey) as String?;
    if (raw == null) return null;
    try {
      return CartModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<void> clearCart() async {
    await _cartBox.delete(_cartKey);
  }
  
  @override
  Future<void> addItemToLocalCart(CartItemModel item) async {
    final cart = await getCachedCart();
    if (cart != null) {
      final updatedItems = [...cart.items, item];
      // Fixed null safety - items is never null
      final newSubtotal = updatedItems.fold<double>(
        0, 
        (sum, i) => sum + (i.subtotal)
      );
      final updatedCart = cart.copyWith(
        items: updatedItems,
        itemCount: updatedItems.length,
        subtotal: newSubtotal,
        totalPrice: newSubtotal,
      );
      await cacheCart(updatedCart);
    }
  }
  
  @override
  Future<void> removeItemFromLocalCart(String itemId) async {
    final cart = await getCachedCart();
    if (cart != null) {
      final updatedItems = cart.items.where((i) => i.id != itemId).toList();
      final newSubtotal = updatedItems.fold<double>(
        0, 
        (sum, i) => sum + i.subtotal
      );
      final updatedCart = cart.copyWith(
        items: updatedItems,
        itemCount: updatedItems.length,
        subtotal: newSubtotal,
        totalPrice: newSubtotal,
      );
      await cacheCart(updatedCart);
    }
  }
  
  @override
  Future<void> updateItemQuantity(String itemId, int quantity) async {
    final cart = await getCachedCart();
    if (cart != null) {
      final updatedItems = cart.items.map((item) {
        if (item.id == itemId) {
          return CartItemModel(
            id: item.id,
            productId: item.productId,
            productName: item.productName,
            productImageUrl: item.productImageUrl,
            gradientColors: item.gradientColors,
            variantId: item.variantId,
            variantLabel: item.variantLabel,
            unitPrice: item.unitPrice,
            quantity: quantity,
            subtotal: item.unitPrice * quantity,
          );
        }
        return item;
      }).toList();
      
      final newSubtotal = updatedItems.fold<double>(
        0, 
        (sum, i) => sum + i.subtotal
      );
      final updatedCart = cart.copyWith(
        items: updatedItems,
        itemCount: updatedItems.length,
        subtotal: newSubtotal,
        totalPrice: newSubtotal,
      );
      await cacheCart(updatedCart);
    }
  }
}