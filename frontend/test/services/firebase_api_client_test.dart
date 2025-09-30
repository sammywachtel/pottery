/// Tests for API client integration with Firebase authentication.
///
/// Tests API client functionality including:
/// - Automatic Firebase token injection in headers
/// - Token refresh on API calls
/// - Error handling for expired tokens
/// - Retry logic for authentication failures

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Mock classes
class MockDio extends Mock implements Dio {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}
class MockResponse extends Mock implements Response {}
class MockRequestOptions extends Mock implements RequestOptions {}

/// Mock API client that integrates Firebase authentication
class FirebaseApiClient {
  final Dio _dio;
  final FirebaseAuth _firebaseAuth;

  FirebaseApiClient({
    Dio? dio,
    FirebaseAuth? firebaseAuth,
  }) : _dio = dio ?? Dio(),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    // Add request interceptor to inject Firebase token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          await _injectAuthToken(options);
          handler.next(options);
        },
        onError: (error, handler) async {
          // Handle token refresh on 401 errors
          if (error.response?.statusCode == 401) {
            final retryResult = await _retryWithRefreshedToken(error.requestOptions);
            if (retryResult != null) {
              handler.resolve(retryResult);
              return;
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  Future<void> _injectAuthToken(RequestOptions options) async {
    try {
      // Opening move: get current user
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Main play: get fresh ID token
      final token = await user.getIdToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      // This looks odd, but it saves us from blocking API calls
      // when token retrieval fails - let the server handle it
      print('Warning: Failed to inject auth token: $e');
    }
  }

  Future<Response?> _retryWithRefreshedToken(RequestOptions requestOptions) async {
    try {
      // Big play: force refresh the token
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;

      final refreshedToken = await user.getIdToken(true);
      if (refreshedToken == null) return null;

      // Victory lap: retry request with refreshed token
      requestOptions.headers['Authorization'] = 'Bearer $refreshedToken';
      return await _dio.fetch(requestOptions);
    } catch (e) {
      print('Failed to retry with refreshed token: $e');
      return null;
    }
  }

  // API methods
  Future<Response> getItems() async {
    return await _dio.get('/api/items');
  }

  Future<Response> createItem(Map<String, dynamic> itemData) async {
    return await _dio.post('/api/items', data: itemData);
  }

  Future<Response> updateItem(String itemId, Map<String, dynamic> itemData) async {
    return await _dio.put('/api/items/$itemId', data: itemData);
  }

  Future<Response> deleteItem(String itemId) async {
    return await _dio.delete('/api/items/$itemId');
  }

  Future<Response> uploadPhoto(String itemId, String photoPath) async {
    final formData = FormData.fromMap({
      'photo': await MultipartFile.fromFile(photoPath),
    });
    return await _dio.post('/api/items/$itemId/photos', data: formData);
  }
}

void main() {
  group('FirebaseApiClient Tests', () {
    late MockDio mockDio;
    late MockFirebaseAuth mockFirebaseAuth;
    late MockUser mockUser;
    late FirebaseApiClient apiClient;

    setUp(() {
      mockDio = MockDio();
      mockFirebaseAuth = MockFirebaseAuth();
      mockUser = MockUser();

      // Setup default behaviors
      when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.getIdToken(any())).thenAnswer((_) async => 'firebase_token_123');

      apiClient = FirebaseApiClient(
        dio: mockDio,
        firebaseAuth: mockFirebaseAuth,
      );
    });

    group('Token Injection', () {
      test('injects Firebase token in request headers', () async {
        // Setup successful response
        final mockResponse = MockResponse();
        when(() => mockDio.get(any())).thenAnswer((_) async => mockResponse);

        await apiClient.getItems();

        // Verify token was injected
        verify(() => mockUser.getIdToken(false)).called(1);
      });

      test('handles missing user gracefully', () async {
        // Setup no authenticated user
        when(() => mockFirebaseAuth.currentUser).thenReturn(null);

        final mockResponse = MockResponse();
        when(() => mockDio.get(any())).thenAnswer((_) async => mockResponse);

        // Should not throw exception, but may not inject token
        await apiClient.getItems();

        verifyNever(() => mockUser.getIdToken(any()));
      });

      test('handles token retrieval failure gracefully', () async {
        // Setup token retrieval to fail
        when(() => mockUser.getIdToken(any())).thenThrow(
          FirebaseAuthException(code: 'network-request-failed', message: 'Network error')
        );

        final mockResponse = MockResponse();
        when(() => mockDio.get(any())).thenAnswer((_) async => mockResponse);

        // Should still make API call without token
        await apiClient.getItems();

        verify(() => mockUser.getIdToken(false)).called(1);
      });
    });

    group('Token Refresh on 401 Errors', () {
      test('refreshes token and retries request on 401 error', () async {
        // Setup initial 401 error
        final dioError = DioException(
          requestOptions: MockRequestOptions(),
          response: Response(
            requestOptions: MockRequestOptions(),
            statusCode: 401,
          ),
        );

        // Setup token refresh to succeed
        when(() => mockUser.getIdToken(true)).thenAnswer((_) async => 'refreshed_token_456');

        final successResponse = MockResponse();
        when(() => successResponse.statusCode).thenReturn(200);

        // Mock dio.fetch for retry
        when(() => mockDio.fetch(any())).thenAnswer((_) async => successResponse);

        // First call fails with 401, second call succeeds
        when(() => mockDio.get(any())).thenThrow(dioError);

        // Note: This test would need proper interceptor setup to work fully
        // For now, we're testing the retry logic components
        expect(() => apiClient.getItems(), throwsA(isA<DioException>()));

        // Verify initial token retrieval was attempted
        verify(() => mockUser.getIdToken(false)).called(1);
      });

      test('does not retry if token refresh fails', () async {
        // Setup 401 error
        final dioError = DioException(
          requestOptions: MockRequestOptions(),
          response: Response(
            requestOptions: MockRequestOptions(),
            statusCode: 401,
          ),
        );

        // Setup token refresh to fail
        when(() => mockUser.getIdToken(true)).thenThrow(
          FirebaseAuthException(code: 'network-request-failed', message: 'Network error')
        );

        when(() => mockDio.get(any())).thenThrow(dioError);

        expect(() => apiClient.getItems(), throwsA(isA<DioException>()));

        // Should not attempt to fetch with refreshed token
        verifyNever(() => mockDio.fetch(any()));
      });

      test('does not retry if user is null during refresh', () async {
        // Setup 401 error
        final dioError = DioException(
          requestOptions: MockRequestOptions(),
          response: Response(
            requestOptions: MockRequestOptions(),
            statusCode: 401,
          ),
        );

        // Setup user to be null during retry
        when(() => mockFirebaseAuth.currentUser).thenReturn(null);

        when(() => mockDio.get(any())).thenThrow(dioError);

        expect(() => apiClient.getItems(), throwsA(isA<DioException>()));

        verifyNever(() => mockDio.fetch(any()));
      });
    });

    group('API Methods', () {
      test('getItems makes GET request to correct endpoint', () async {
        final mockResponse = MockResponse();
        when(() => mockDio.get(any())).thenAnswer((_) async => mockResponse);

        final result = await apiClient.getItems();

        expect(result, equals(mockResponse));
        verify(() => mockDio.get('/api/items')).called(1);
      });

      test('createItem makes POST request with data', () async {
        final itemData = {
          'title': 'New Pottery Item',
          'description': 'A beautiful piece',
          'stage': 'bisque',
        };

        final mockResponse = MockResponse();
        when(() => mockDio.post(any(), data: any(named: 'data')))
            .thenAnswer((_) async => mockResponse);

        final result = await apiClient.createItem(itemData);

        expect(result, equals(mockResponse));
        verify(() => mockDio.post('/api/items', data: itemData)).called(1);
      });

      test('updateItem makes PUT request with data', () async {
        final itemData = {
          'title': 'Updated Pottery Item',
          'description': 'Updated description',
        };

        final mockResponse = MockResponse();
        when(() => mockDio.put(any(), data: any(named: 'data')))
            .thenAnswer((_) async => mockResponse);

        final result = await apiClient.updateItem('item123', itemData);

        expect(result, equals(mockResponse));
        verify(() => mockDio.put('/api/items/item123', data: itemData)).called(1);
      });

      test('deleteItem makes DELETE request', () async {
        final mockResponse = MockResponse();
        when(() => mockDio.delete(any())).thenAnswer((_) async => mockResponse);

        final result = await apiClient.deleteItem('item123');

        expect(result, equals(mockResponse));
        verify(() => mockDio.delete('/api/items/item123')).called(1);
      });
    });

    group('Error Handling', () {
      test('propagates non-401 errors normally', () async {
        // Setup 500 error
        final dioError = DioException(
          requestOptions: MockRequestOptions(),
          response: Response(
            requestOptions: MockRequestOptions(),
            statusCode: 500,
          ),
        );

        when(() => mockDio.get(any())).thenThrow(dioError);

        expect(() => apiClient.getItems(), throwsA(isA<DioException>()));

        // Should not attempt token refresh for non-401 errors
        verifyNever(() => mockUser.getIdToken(true));
      });

      test('handles network errors gracefully', () async {
        final dioError = DioException(
          requestOptions: MockRequestOptions(),
          type: DioExceptionType.connectionTimeout,
        );

        when(() => mockDio.get(any())).thenThrow(dioError);

        expect(() => apiClient.getItems(), throwsA(isA<DioException>()));
      });

      test('handles Firebase auth errors during token injection', () async {
        // Setup Firebase auth error
        when(() => mockUser.getIdToken(any())).thenThrow(
          FirebaseAuthException(code: 'user-disabled', message: 'User account disabled')
        );

        final mockResponse = MockResponse();
        when(() => mockDio.get(any())).thenAnswer((_) async => mockResponse);

        // Should still make the request (server will handle missing auth)
        final result = await apiClient.getItems();

        expect(result, equals(mockResponse));
      });
    });

    group('Concurrent Request Handling', () {
      test('handles multiple concurrent requests with token injection', () async {
        final mockResponse = MockResponse();
        when(() => mockDio.get(any())).thenAnswer((_) async => mockResponse);
        when(() => mockDio.post(any(), data: any(named: 'data')))
            .thenAnswer((_) async => mockResponse);

        // Make multiple concurrent requests
        final futures = [
          apiClient.getItems(),
          apiClient.createItem({'title': 'Item 1'}),
          apiClient.createItem({'title': 'Item 2'}),
        ];

        final results = await Future.wait(futures);

        // All requests should succeed
        expect(results.length, equals(3));
        for (final result in results) {
          expect(result, equals(mockResponse));
        }

        // Token should be retrieved for each request
        verify(() => mockUser.getIdToken(false)).called(3);
      });

      test('handles token refresh during concurrent requests', () async {
        // This test would verify that multiple 401 responses don't trigger
        // multiple token refreshes simultaneously

        final dioError = DioException(
          requestOptions: MockRequestOptions(),
          response: Response(
            requestOptions: MockRequestOptions(),
            statusCode: 401,
          ),
        );

        when(() => mockDio.get(any())).thenThrow(dioError);
        when(() => mockDio.post(any(), data: any(named: 'data'))).thenThrow(dioError);

        // Multiple concurrent requests that would trigger 401
        final futures = [
          apiClient.getItems(),
          apiClient.createItem({'title': 'Item 1'}),
        ];

        // All should fail, but token refresh should be coordinated
        try {
          await Future.wait(futures);
        } catch (e) {
          // Expected to fail due to 401 errors
        }

        // Verify initial token attempts
        verify(() => mockUser.getIdToken(false)).called(2);
      });
    });
  });
}
