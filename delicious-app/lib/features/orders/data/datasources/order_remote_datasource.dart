import 'package:Delicious_App/core/network/api_client.dart';
import '../models/order_models.dart';
import '../models/order_tracking_model.dart';

abstract class OrderRemoteDataSource {
  Future<OrderModel> placeOrder(Map<String, dynamic> orderData);
  Future<List<OrderModel>> getOrders(String userId);
  Future<OrderModel> getOrderById(String orderId);
  Future<OrderModel> cancelOrder(String orderId, {String? reason});
  Future<OrderTrackingModel> trackOrder(String orderId);
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final DeliciousApiClient apiClient;
  
  const OrderRemoteDataSourceImpl({required this.apiClient});
  
  @override
  Future<OrderModel> placeOrder(Map<String, dynamic> orderData) async {
    final response = await apiClient.placeOrder(orderData);
    return response;
  }
  
  @override
  Future<List<OrderModel>> getOrders(String userId) async {
    final response = await apiClient.getUserOrders(userId);
    return response;
  }
  
  @override
  Future<OrderModel> getOrderById(String orderId) async {
    final response = await apiClient.getOrderById(orderId);
    return response;
  }
  
  @override
  Future<OrderModel> cancelOrder(String orderId, {String? reason}) async {
    final response = await apiClient.updateOrderStatus(orderId, {
      'status': 'cancelled',
      if (reason != null) 'cancellationReason': reason,
    });
    return response;
  }
  
  @override
  Future<OrderTrackingModel> trackOrder(String orderId) async {
    final response = await apiClient.trackOrder(orderId);
    return response;
  }
}