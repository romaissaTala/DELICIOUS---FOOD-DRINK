import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/payment_bloc.dart';
import '../../data/models/payment_method_model.dart';

class PaymentPage extends StatefulWidget {
  final String orderId;
  final double amount;
  final String orderNumber;

  const PaymentPage({
    super.key,
    required this.orderId,
    required this.amount,
    required this.orderNumber,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late final WebViewController _webViewController;
  bool _isWebViewLoading = true;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _isWebViewLoading = true);
          },
          onPageFinished: (url) {
            setState(() => _isWebViewLoading = false);

            // Check if payment completed
            if (url.contains('/success') || url.contains('success')) {
              context
                  .read<PaymentBloc>()
                  .add(const VerifyPaymentEvent('session_id'));
            } else if (url.contains('/failure') || url.contains('fail')) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Payment failed. Please try again.')),
              );
            }
          },
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocConsumer<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is PaymentSuccess) {
            Navigator.pushReplacementNamed(
              context,
              '/order-confirmation',
              arguments: {
                'orderId': widget.orderId,
                'orderNumber': widget.orderNumber
              },
            );
          } else if (state is PaymentFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message), backgroundColor: Colors.red),
            );
          } else if (state is PaymentWebViewRequired) {
            _loadWebView(state.checkoutUrl);
          }
        },
        builder: (context, state) {
          if (state is PaymentLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PaymentMethodsLoaded) {
            return _buildPaymentMethodsScreen(context, state.methods);
          }

          if (state is PaymentWebViewRequired && _isWebViewLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PaymentWebViewRequired) {
            return WebViewWidget(controller: _webViewController);
          }

          return _buildInitialScreen(context);
        },
      ),
    );
  }

  void _loadWebView(String url) {
    _webViewController.loadRequest(Uri.parse(url));
  }

  Widget _buildInitialScreen(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.payment, size: 40, color: Colors.green.shade700),
          ),
          const SizedBox(height: 24),
          Text('Total Amount', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text(
            '${widget.amount.toStringAsFixed(0)} DZD',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 200,
            child: ElevatedButton.icon(
              onPressed: () {
                context.read<PaymentBloc>().add(const GetPaymentMethodsEvent());
              },
              icon: const Icon(Icons.credit_card),
              label: const Text('Choose Payment Method'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsScreen(
      BuildContext context, List<PaymentMethodModel> methods) {
    final authState = context.read<AuthBloc>().state;
    final userEmail = authState is AuthAuthenticated
        ? authState.user.email
        : 'guest@delicious.dz';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Amount Card
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text('Amount to Pay',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.amount.toStringAsFixed(0)} DZD',
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Order #${widget.orderNumber}',
                      style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Text('Select Payment Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          ...methods.map((method) => _PaymentMethodCard(
                method: method,
                onTap: () {
                  context.read<PaymentBloc>().add(InitiatePaymentEvent(
                        orderId: widget.orderId,
                        orderNumber: widget.orderNumber,
                        amount: widget.amount,
                        customerEmail: userEmail,
                      ));
                },
              )),

          const SizedBox(height: 24),
          _buildSecurityNotice(),
        ],
      ),
    );
  }

  Widget _buildSecurityNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.security, color: Colors.green.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your payment is secure. We use encryption to protect your data.',
              style: TextStyle(color: Colors.green.shade800, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final PaymentMethodModel method;
  final VoidCallback onTap;

  const _PaymentMethodCard({required this.method, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: _getMethodIcon(method.methodName)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.displayName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      method.instructions,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getMethodIcon(String methodName) {
    switch (methodName.toUpperCase()) {
      case 'EDAHABIA':
        return const Icon(Icons.credit_card, color: Colors.blue, size: 28);
      case 'CIB':
        return const Icon(Icons.business_center, color: Colors.green, size: 28);
      case 'CCP':
        return const Icon(Icons.account_balance,
            color: Colors.orange, size: 28);
      default:
        return const Icon(Icons.payment, color: Colors.purple, size: 28);
    }
  }
}
