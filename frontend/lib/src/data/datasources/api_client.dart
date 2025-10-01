import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_config.dart';
import '../../core/app_exception.dart';

class ApiClient {
  ApiClient(this._dio, {Function()? onTokenExpired});

  final Dio _dio;
  Function()? _onTokenExpired;

  Dio get dio => _dio;

  void setTokenExpiredCallback(Function() callback) {
    _onTokenExpired = callback;
  }

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

      // Opening move: check for 401 - token expired
      if (response?.statusCode == 401) {
        // Trigger token refresh callback
        _onTokenExpired?.call();
      }

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

/// Interceptor that automatically refreshes tokens on 401 errors
/// This saves users from losing their form data when tokens expire
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._refreshToken);

  final Future<String?> Function() _refreshToken;
  bool _isRefreshing = false;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Main play: detect 401 unauthorized (token expired)
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;

      try {
        // Time to tackle the tricky bit: refresh the token
        final newToken = await _refreshToken();

        if (newToken != null) {
          // Victory lap: retry the request with fresh token
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $newToken';

          final dio = Dio(BaseOptions(
            baseUrl: options.baseUrl,
            headers: options.headers,
          ));

          final response = await dio.fetch(options);
          return handler.resolve(response);
        }
      } catch (e) {
        // Token refresh failed - let the error propagate
        // User will be logged out by the auth controller
      } finally {
        _isRefreshing = false;
      }
    }

    // Pass through to next handler
    super.onError(err, handler);
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
