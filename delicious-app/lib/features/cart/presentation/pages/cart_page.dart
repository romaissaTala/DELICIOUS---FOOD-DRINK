import 'package:Delicious_App/features/cart/data/models/cart_models.dart';
import 'package:Delicious_App/features/cart/widgets/cart_item_widget.dart';
import 'package:Delicious_App/features/cart/widgets/cart_summary_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/cart_bloc.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              _showClearCartDialog();
            },
          ),
        ],
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state is CartLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CartError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final userId = 'get from auth';
                      context.read<CartBloc>().add(LoadCart(userId));
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is CartLoaded ||
              state is CartItemAdded ||
              state is CartItemRemoved) {
            final cart = state is CartLoaded
                ? state.cart
                : state is CartItemAdded
                    ? state.cart
                    : (state as CartItemRemoved).cart;

            if (cart.items.isEmpty) {
              return _buildEmptyCart();
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return CartItemWidget(
                        item: item,
                        onQuantityChanged: (quantity) {
                          if (quantity <= 0) {
                            context
                                .read<CartBloc>()
                                .add(RemoveFromCartEvent(item.id));
                          } else {
                            context.read<CartBloc>().add(UpdateCartItemEvent(
                                  cartItemId: item.id,
                                  quantity: quantity,
                                ));
                          }
                        },
                        onRemove: () {
                          context
                              .read<CartBloc>()
                              .add(RemoveFromCartEvent(item.id));
                        },
                      );
                    },
                  ),
                ),
                CartSummaryWidget(
                  subtotal: cart.subtotal,
                  deliveryFee: 200,
                  total: cart.totalPrice + 200,
                  onCheckout: () {
                    Navigator.pushNamed(context, '/checkout');
                  },
                ),
              ],
            );
          }

          return _buildEmptyCart();
        },
      ),
    );
  }

  // ✅ No need to pass context in StatefulWidget - use widget.context
  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined,
              size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items to get started',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // In StatefulWidget, you can access context from widget
              Navigator.pushReplacementNamed(context, '/home');
            },
            child: const Text('Browse Products'),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog() {
    showDialog(
      context: context, // ✅ context available in StatefulWidget
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text(
            'Are you sure you want to remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final userId = 'get from auth';
              context.read<CartBloc>().add(ClearCartEvent(userId));
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
