import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_config.dart';
import '../../core/app_exception.dart';

class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Dio get dio => _dio;

  void updateAuthToken(String? token) {
    if (token == null || token.isEmpty) {
      _dio.options.headers.remove('Authorization');
    } else {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Never handleError(Object error) {
    if (error is DioException) {
      final response = error.response;
      final message = response?.data is Map<String, dynamic>
          ? response?.data['detail']?.toString() ?? error.message
          : error.message;
      throw AppException(
        message ?? 'Unexpected API error',
        statusCode: response?.statusCode,
      );
    }
    throw AppException(error.toString());
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(appConfigProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    LogInterceptor(
      requestBody: true,
      responseBody: false,
    ),
  );

  final client = ApiClient(dio);
  ref.onDispose(dio.close);
  return client;
});
