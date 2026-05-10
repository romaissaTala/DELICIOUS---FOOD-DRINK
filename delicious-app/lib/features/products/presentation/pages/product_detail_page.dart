import 'package:Delicious_App/core/theme/app_theme.dart';
import 'package:Delicious_App/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:Delicious_App/features/cart/widgets/add_to_bag_button.dart';
import 'package:Delicious_App/features/cart/widgets/fly_to_cart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/product_bloc.dart';


class ProductDetailPage extends StatefulWidget {
  final String productId;
  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final _cartKey = GlobalKey<CartIconButtonState>();
  int _quantity = 1;
  
  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(ProductDetailRequested(widget.productId));
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<ProductBloc, ProductState>(
        builder: (context, state) {
          if (state.isLoadingDetail) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state.detailError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(state.detailError!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ProductBloc>().add(ProductDetailRequested(widget.productId));
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          final product = state.selectedProduct;
          if (product == null) {
            return const SizedBox.shrink();
          }
          
          return Stack(
            children: [
              // Background gradient
              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.getProductGradient(product.name, product.gradientColors),
                ),
              ),
              
              CustomScrollView(
                slivers: [
                  // App Bar
                  SliverAppBar(
                    expandedHeight: 300,
                    floating: false,
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Hero(
                        tag: 'product_${product.id}',
                        child: Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.image_not_supported, size: 64),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  
                  // Product Info
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Brand
                          if (product.brand != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                product.brand!,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          const SizedBox(height: 12),
                          
                          // Name
                          Text(
                            product.name,
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          
                          // Rating
                          Row(
                            children: [
                              Row(
                                children: List.generate(5, (index) {
                                  final rating = product.rating.average;
                                  if (index < rating.floor()) {
                                    return const Icon(Icons.star, size: 18, color: Colors.amber);
                                  } else if (index < rating && rating - index > 0.5) {
                                    return const Icon(Icons.star_half, size: 18, color: Colors.amber);
                                  } else {
                                    return const Icon(Icons.star_border, size: 18, color: Colors.amber);
                                  }
                                }),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '(${product.rating.count})',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Price
                          Row(
                            children: [
                              if (product.hasDiscount) ...[
                                Text(
                                  '${product.price} DZD',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                '${product.finalPrice} DZD',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Quantity Selector
                          const Text(
                            'Quantity',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, size: 20),
                                      onPressed: () {
                                        if (_quantity > 1) {
                                          setState(() => _quantity--);
                                        }
                                      },
                                    ),
                                    SizedBox(
                                      width: 40,
                                      child: Text(
                                        '$_quantity',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add, size: 20),
                                      onPressed: () {
                                        setState(() => _quantity++);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Description
                          if (product.description != null) ...[
                            const Text(
                              'Description',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              product.description!,
                              style: TextStyle(color: Colors.grey.shade700, height: 1.5),
                            ),
                          ],
                          const SizedBox(height: 24),
                          
                          // Preparation Time
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 20, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Text('Preparation time: ${product.preparationTimeMin} minutes'),
                            ],
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              // Bottom Add to Cart Button
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: AddToBagButton(
                    cartKey: _cartKey,
                    productColor: Color(int.parse(product.primaryColor.replaceFirst('#', '0xFF'))),
                    productImage: NetworkImage(product.imageUrl),
                    onAdded: () {
                      context.read<CartBloc>().add(AddToCartEvent(
                        userId: '', // Get from auth
                        productId: product.id,
                        productName: product.name,
                        productImageUrl: product.imageUrl,
                        unitPrice: product.finalPrice,
                        quantity: _quantity,
                        gradientColors: product.gradientColors,
                      ));
                    },
                  ),
                ),
              ),
              
              // Cart Icon in App Bar
              Positioned(
                top: 48,
                right: 16,
                child: CartIconButton(
                  key: _cartKey,
                  itemCount: 0,
                  onTap: () => context.push('/cart'),
                ),
              ),
              
              // Back Button
              Positioned(
                top: 48,
                left: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}