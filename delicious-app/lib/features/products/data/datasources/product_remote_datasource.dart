import 'package:Delicious_App/core/network/api_client.dart';
import '../models/product_model.dart';

abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> getProducts({String? category, String? mood});
  Future<ProductModel> getProductById(String id);
  Future<List<CategoryModel>> getCategories();
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final DeliciousApiClient apiClient;
  
  const ProductRemoteDataSourceImpl({required this.apiClient});
  
  @override
  Future<List<ProductModel>> getProducts({String? category, String? mood}) async {
    // Response parser already extracted the data, so this is clean!
    return await apiClient.getProducts(category: category, mood: mood);
  }
  
  @override
  Future<ProductModel> getProductById(String id) async {
    return await apiClient.getProductById(id);
  }
  
  @override
  Future<List<CategoryModel>> getCategories() async {
    return await apiClient.getCategories();
  }
}