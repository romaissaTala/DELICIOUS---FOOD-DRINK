import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();

  // Address fields
  String _wilaya = '';
  String _commune = '';
  String _street = '';
  String _apartment = '';
  String _phone = '';

  // Delivery options
  String _deliveryType = 'standard';
  String _notes = '';

  @override
  void initState() {
    super.initState();
    // Load cart
    _loadCart();
  }

  void _loadCart() {
    final authState = context.read<AuthBloc>().state;
    String userId = '';
    if (authState is AuthAuthenticated) {
      userId = authState.user.id;
    } else if (authState is AuthGuest) {
      userId = authState.guestUser.id;
    }
    context.read<CartBloc>().add(LoadCart(userId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, cartState) {
          if (cartState is CartLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (cartState is CartLoaded) {
            final cart = cartState.cart;

            if (cart.items.isEmpty) {
              return _buildEmptyCart(context);
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Summary Card
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Order Summary',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            ...cart.items.map((item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${item.quantity}x ${item.productName}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                      Text(
                                        '${(item.unitPrice * item.quantity).toStringAsFixed(0)} DZD',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                )),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Subtotal'),
                                Text('${cart.subtotal.toStringAsFixed(0)} DZD'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Delivery Fee'),
                                Text(
                                    '{cart.deliveryFee.toStringAsFixed(0)} DZD'),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${(cart.totalPrice + 200).toStringAsFixed(0)} DZD',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Delivery Address Section
                    const Text(
                      'Delivery Address',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Wilaya (State)
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Wilaya',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_city),
                      ),
                      onChanged: (value) => _wilaya = value,
                      validator: (value) =>
                          value?.isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    // Commune (City)
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Commune',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      onChanged: (value) => _commune = value,
                      validator: (value) =>
                          value?.isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    // Street
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Street Address',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.home),
                      ),
                      onChanged: (value) => _street = value,
                      validator: (value) =>
                          value?.isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    // Apartment (Optional)
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Apartment / Suite (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => _apartment = value,
                    ),
                    const SizedBox(height: 12),

                    // Phone
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      onChanged: (value) => _phone = value,
                      validator: (value) =>
                          value?.isEmpty == true ? 'Required' : null,
                    ),

                    const SizedBox(height: 24),

                    // Delivery Options
                    const Text(
                      'Delivery Options',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    RadioListTile(
                      title: const Text('Standard Delivery (30-45 min)'),
                      subtitle: const Text('200 DZD'),
                      value: 'standard',
                      groupValue: _deliveryType,
                      onChanged: (value) =>
                          setState(() => _deliveryType = value!),
                      secondary: const Icon(Icons.delivery_dining),
                    ),
                    RadioListTile(
                      title: const Text('Express Delivery (15-25 min)'),
                      subtitle: const Text('350 DZD'),
                      value: 'express',
                      groupValue: _deliveryType,
                      onChanged: (value) =>
                          setState(() => _deliveryType = value!),
                      secondary: const Icon(Icons.motorcycle),
                    ),

                    const SizedBox(height: 24),

                    // Order Notes
                    const Text(
                      'Order Notes (Optional)',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(
                        hintText: 'Special instructions for the restaurant...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      onChanged: (value) => _notes = value,
                    ),

                    const SizedBox(height: 32),

                    // Place Order Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _placeOrder,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Proceed to Payment',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  void _placeOrder() {
    if (_formKey.currentState!.validate()) {
      // Navigate to payment page with order details
    context.push(
        '/payment',
        extra: {
          'orderId': 'order_${DateTime.now().millisecondsSinceEpoch}',
          'orderNumber': 'DLX-${DateTime.now().millisecondsSinceEpoch}',
          'amount': 1000, // Get from cart
        },
      );
    }
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'Your cart is empty',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items to proceed to checkout',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            child: const Text('Browse Products'),
          ),
        ],
      ),
    );
  }
}
