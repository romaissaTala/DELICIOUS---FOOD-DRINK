import 'package:dio/dio.dart';
import 'package:Delicious_App/core/network/api_client.dart';
import '../models/payment_method_model.dart';
import '../models/payment_request_model.dart';

abstract class PaymentRemoteDataSource {
  Future<List<PaymentMethodModel>> getPaymentMethods();
  Future<Map<String, dynamic>> createPaymentSession(PaymentRequestModel request);
  Future<PaymentResultModel> verifyPayment(String sessionId);
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  final DeliciousApiClient apiClient; // You already have this!
  
  PaymentRemoteDataSourceImpl({required this.apiClient});
  
  @override
  Future<List<PaymentMethodModel>> getPaymentMethods() async {
    try {
      return await apiClient.getPaymentMethods();
    } catch (e) {
      // Fallback list for development
      return _getFallbackPaymentMethods();
    }
  }
  
  @override
  Future<Map<String, dynamic>> createPaymentSession(PaymentRequestModel request) async {
    // ✅ CORRECT: Call YOUR backend endpoint (not Chargily directly)
    // The API key stays on your server, safe from exposure.
    final response = await apiClient.createPaymentSession(request.toJson());
    return response;
  }
  
  @override
  Future<PaymentResultModel> verifyPayment(String sessionId) async {
    final response = await apiClient.verifyPayment(sessionId);
    return PaymentResultModel.fromJson(response);
  }
  
  List<PaymentMethodModel> _getFallbackPaymentMethods() {
    return [
      PaymentMethodModel(
        id: '1',
        methodName: 'EDAHABIA',
        displayName: 'Edahabia - Algérie Poste',
        instructions: 'Pay with your Edahabia gold card',
        iconUrl: null,
        isActive: true,
        sortOrder: 1,
      ),
      PaymentMethodModel(
        id: '2',
        methodName: 'CIB',
        displayName: 'CIB - Cartes bancaires',
        instructions: 'Pay with your CIB bank card',
        iconUrl: null,
        isActive: true,
        sortOrder: 2,
      ),
    ];
  }
}