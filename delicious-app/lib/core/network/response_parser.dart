import 'package:dio/dio.dart';

/// Custom interceptor to parse MongoDB responses
/// MongoDB returns { "success": true, "data": {...} }
/// This interceptor extracts the 'data' field automatically
class ResponseParserInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    try {
      final data = response.data;
      
      // If response has { success, data } structure, extract data
      if (data is Map<String, dynamic>) {
        if (data.containsKey('data')) {
          // Replace response.data with the actual data
          response.data = data['data'];
        }
      }
      
      handler.next(response);
    } catch (e) {
      handler.reject(DioException(
        requestOptions: response.requestOptions,
        error: e,
        type: DioExceptionType.badResponse,
      ));
    }
  }
}