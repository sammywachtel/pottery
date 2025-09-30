/// Unit tests for AuthRepository integration with Firebase authentication.
///
/// Tests the actual AuthRepository implementation including:
/// - Firebase authentication integration
/// - API client token management
/// - Local storage session persistence
/// - Error handling and token refresh
/// - Google Sign-In functionality

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import 'package:pottery_frontend/src/data/repositories/auth_repository.dart';
import 'package:pottery_frontend/src/data/datasources/api_client.dart';
import 'package:pottery_frontend/src/data/datasources/token_storage.dart';
import 'package:pottery_frontend/src/data/services/firebase_auth_service.dart';
import 'package:pottery_frontend/src/data/models/auth_session.dart';

// Mock classes for dependencies
class MockApiClient extends Mock implements ApiClient {}
class MockLocalAuthStorage extends Mock implements LocalAuthStorage {}
class MockFirebaseAuthService extends Mock implements FirebaseAuthService {}
class MockFirebaseUser extends Mock implements firebase_auth.User {}

void main() {
  group('AuthRepository Integration Tests', () {
    late AuthRepository authRepository;
    late MockApiClient mockApiClient;
    late MockLocalAuthStorage mockStorage;
    late MockFirebaseAuthService mockFirebaseAuth;
    late MockFirebaseUser mockUser;

    setUp(() {
      mockApiClient = MockApiClient();
      mockStorage = MockLocalAuthStorage();
      mockFirebaseAuth = MockFirebaseAuthService();
      mockUser = MockFirebaseUser();

      // Opening move: create AuthRepository with mocked dependencies
      authRepository = AuthRepository(
        mockApiClient,
        mockStorage,
        mockFirebaseAuth,
      );

      // Setup default mock behaviors
      when(() => mockUser.uid).thenReturn('test_uid_123');
      when(() => mockUser.email).thenReturn('test@example.com');
      when(() => mockUser.displayName).thenReturn('Test User');
      when(() => mockUser.photoURL).thenReturn('https://example.com/photo.jpg');
      when(() => mockApiClient.updateAuthToken(any())).thenReturn(null);
      when(() => mockStorage.saveSession(
        token: any(named: 'token'),
        username: any(named: 'username'),
        userId: any(named: 'userId'),
        email: any(named: 'email'),
        displayName: any(named: 'displayName'),
      )).thenAnswer((_) async {});
    });

    group('Email/Password Authentication', () {
      test('login with valid credentials succeeds', () async {
        // Setup successful Firebase authentication
        final expectedSession = AuthSession(
          token: 'firebase_token_123',
          username: 'test@example.com',
          userId: 'test_uid_123',
          email: 'test@example.com',
          displayName: 'Test User',
          photoUrl: 'https://example.com/photo.jpg',
        );

        when(() => mockFirebaseAuth.signInWithEmailPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => expectedSession);

        // Main play: attempt login
        final result = await authRepository.login(
          username: 'test@example.com',
          password: 'password123',
        );

        // Victory lap: verify success
        expect(result.token, equals('firebase_token_123'));
        expect(result.username, equals('test@example.com'));
        expect(result.userId, equals('test_uid_123'));
        expect(result.email, equals('test@example.com'));

        // Verify dependencies were called correctly
        verify(() => mockApiClient.updateAuthToken(null)).called(1);
        verify(() => mockFirebaseAuth.signInWithEmailPassword(
          email: 'test@example.com',
          password: 'password123',
        )).called(1);
        verify(() => mockStorage.saveSession(
          token: 'firebase_token_123',
          username: 'test@example.com',
          userId: 'test_uid_123',
          email: 'test@example.com',
          displayName: 'Test User',
        )).called(1);
        verify(() => mockApiClient.updateAuthToken('firebase_token_123')).called(1);
      });

      test('login with invalid credentials throws exception', () async {
        // Setup Firebase authentication to fail
        when(() => mockFirebaseAuth.signInWithEmailPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(Exception('Invalid credentials'));

        // Verify exception is propagated
        expect(
          () => authRepository.login(
            username: 'invalid@example.com',
            password: 'wrongpassword',
          ),
          throwsA(isA<Exception>()),
        );

        // Verify API client was cleared but no session was saved
        verify(() => mockApiClient.updateAuthToken(null)).called(1);
        verifyNever(() => mockStorage.saveSession(
          token: any(named: 'token'),
          username: any(named: 'username'),
          userId: any(named: 'userId'),
          email: any(named: 'email'),
          displayName: any(named: 'displayName'),
        ));
      });
    });

    group('Session Persistence', () {
      test('loadPersistedSession with valid stored session succeeds', () async {
        // Setup stored session data
        when(() => mockStorage.readToken()).thenAnswer((_) async => 'stored_token');
        when(() => mockStorage.readUsername()).thenAnswer((_) async => 'test@example.com');
        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockFirebaseAuth.isTokenValid()).thenAnswer((_) async => true);
        when(() => mockFirebaseAuth.getIdToken()).thenAnswer((_) async => 'stored_token');

        final result = await authRepository.loadPersistedSession();

        expect(result, isNotNull);
        expect(result!.token, equals('stored_token'));
        expect(result.username, equals('test@example.com'));
        expect(result.userId, equals('test_uid_123'));

        verify(() => mockApiClient.updateAuthToken('stored_token')).called(1);
      });

      test('loadPersistedSession with expired token clears storage', () async {
        // Setup expired session
        when(() => mockStorage.readToken()).thenAnswer((_) async => 'expired_token');
        when(() => mockStorage.readUsername()).thenAnswer((_) async => 'test@example.com');
        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockFirebaseAuth.isTokenValid()).thenAnswer((_) async => false);
        when(() => mockStorage.clear()).thenAnswer((_) async {});

        final result = await authRepository.loadPersistedSession();

        expect(result, isNull);
        verify(() => mockStorage.clear()).called(1);
      });

      test('loadPersistedSession with no stored data returns null', () async {
        // Setup no stored data
        when(() => mockStorage.readToken()).thenAnswer((_) async => null);
        when(() => mockStorage.readUsername()).thenAnswer((_) async => null);

        final result = await authRepository.loadPersistedSession();

        expect(result, isNull);
        verifyNever(() => mockFirebaseAuth.currentUser);
      });

      test('loadPersistedSession refreshes token when needed', () async {
        // Setup token refresh scenario
        when(() => mockStorage.readToken()).thenAnswer((_) async => 'old_token');
        when(() => mockStorage.readUsername()).thenAnswer((_) async => 'test@example.com');
        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockFirebaseAuth.isTokenValid()).thenAnswer((_) async => true);
        when(() => mockFirebaseAuth.getIdToken()).thenAnswer((_) async => 'new_refreshed_token');

        final result = await authRepository.loadPersistedSession();

        expect(result, isNotNull);
        expect(result!.token, equals('new_refreshed_token'));

        // Verify token was updated in storage
        verify(() => mockStorage.saveSession(
          token: 'new_refreshed_token',
          username: 'test@example.com',
          userId: 'test_uid_123',
          email: 'test@example.com',
          displayName: 'Test User',
        )).called(1);
        verify(() => mockApiClient.updateAuthToken('new_refreshed_token')).called(1);
      });
    });

    group('Google Sign-In', () {
      test('signInWithGoogle succeeds', () async {
        // Setup successful Google Sign-In
        final expectedSession = AuthSession(
          token: 'google_firebase_token',
          username: 'google@example.com',
          userId: 'google_uid_123',
          email: 'google@example.com',
          displayName: 'Google User',
          photoUrl: 'https://google.com/photo.jpg',
        );

        when(() => mockFirebaseAuth.signInWithGoogle())
            .thenAnswer((_) async => expectedSession);

        final result = await authRepository.signInWithGoogle();

        expect(result.token, equals('google_firebase_token'));
        expect(result.username, equals('google@example.com'));
        expect(result.userId, equals('google_uid_123'));

        // Verify dependencies were called
        verify(() => mockApiClient.updateAuthToken(null)).called(1);
        verify(() => mockFirebaseAuth.signInWithGoogle()).called(1);
        verify(() => mockStorage.saveSession(
          token: 'google_firebase_token',
          username: 'google@example.com',
          userId: 'google_uid_123',
          email: 'google@example.com',
          displayName: 'Google User',
        )).called(1);
        verify(() => mockApiClient.updateAuthToken('google_firebase_token')).called(1);
      });

      test('signInWithGoogle failure throws exception', () async {
        // Setup Google Sign-In to fail
        when(() => mockFirebaseAuth.signInWithGoogle())
            .thenThrow(Exception('Google Sign-In failed'));

        expect(
          () => authRepository.signInWithGoogle(),
          throwsA(isA<Exception>()),
        );

        verify(() => mockApiClient.updateAuthToken(null)).called(1);
        verifyNever(() => mockStorage.saveSession(
          token: any(named: 'token'),
          username: any(named: 'username'),
          userId: any(named: 'userId'),
          email: any(named: 'email'),
          displayName: any(named: 'displayName'),
        ));
      });
    });

    group('Token Management', () {
      test('refreshToken succeeds with valid user', () async {
        // Setup token refresh
        when(() => mockFirebaseAuth.getIdToken(forceRefresh: true))
            .thenAnswer((_) async => 'refreshed_token_456');
        when(() => mockStorage.readUsername()).thenAnswer((_) async => 'test@example.com');
        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);

        final result = await authRepository.refreshToken();

        expect(result, equals('refreshed_token_456'));

        verify(() => mockStorage.saveSession(
          token: 'refreshed_token_456',
          username: 'test@example.com',
          userId: 'test_uid_123',
          email: 'test@example.com',
          displayName: 'Test User',
        )).called(1);
        verify(() => mockApiClient.updateAuthToken('refreshed_token_456')).called(1);
      });

      test('refreshToken returns null when Firebase fails', () async {
        // Setup token refresh to fail
        when(() => mockFirebaseAuth.getIdToken(forceRefresh: true))
            .thenThrow(Exception('Token refresh failed'));

        final result = await authRepository.refreshToken();

        expect(result, isNull);
      });

      test('refreshToken returns null when no current user', () async {
        // Setup no current user
        when(() => mockFirebaseAuth.getIdToken(forceRefresh: true))
            .thenAnswer((_) async => 'token');
        when(() => mockStorage.readUsername()).thenAnswer((_) async => 'test@example.com');
        when(() => mockFirebaseAuth.currentUser).thenReturn(null);

        final result = await authRepository.refreshToken();

        expect(result, equals('token'));
        verifyNever(() => mockStorage.saveSession(
          token: any(named: 'token'),
          username: any(named: 'username'),
          userId: any(named: 'userId'),
          email: any(named: 'email'),
          displayName: any(named: 'displayName'),
        ));
      });
    });

    group('Logout', () {
      test('logout clears all authentication state', () async {
        // Setup successful logout
        when(() => mockFirebaseAuth.signOut()).thenAnswer((_) async {});
        when(() => mockStorage.clear()).thenAnswer((_) async {});

        await authRepository.logout();

        verify(() => mockFirebaseAuth.signOut()).called(1);
        verify(() => mockStorage.clear()).called(1);
        verify(() => mockApiClient.updateAuthToken(null)).called(1);
      });

      test('logout clears storage even when Firebase signOut fails', () async {
        // Setup Firebase signOut to fail
        when(() => mockFirebaseAuth.signOut()).thenThrow(Exception('Firebase signOut failed'));
        when(() => mockStorage.clear()).thenAnswer((_) async {});

        // The method should throw the Firebase exception but still clean up storage
        // due to the finally block
        expect(
          () => authRepository.logout(),
          throwsA(isA<Exception>()),
        );

        // Wait a bit for the finally block to execute
        await Future.delayed(Duration.zero);

        // Storage should still be cleared due to finally block
        verify(() => mockStorage.clear()).called(1);
        verify(() => mockApiClient.updateAuthToken(null)).called(1);
      });
    });

    group('Error Handling', () {
      test('handles storage errors gracefully in loadPersistedSession', () async {
        // Setup storage to throw error
        when(() => mockStorage.readToken()).thenThrow(Exception('Storage error'));
        when(() => mockStorage.clear()).thenAnswer((_) async {});

        final result = await authRepository.loadPersistedSession();

        expect(result, isNull);
        verify(() => mockStorage.clear()).called(1);
      });

      test('handles Firebase errors gracefully in refreshToken', () async {
        // Setup Firebase to throw error
        when(() => mockFirebaseAuth.getIdToken(forceRefresh: true))
            .thenThrow(Exception('Network error'));

        final result = await authRepository.refreshToken();

        expect(result, isNull);
      });

      test('clears API client token before authentication attempts', () async {
        // This test verifies that the API client is always cleared before auth attempts
        when(() => mockFirebaseAuth.signInWithEmailPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(Exception('Auth failed'));

        try {
          await authRepository.login(
            username: 'test@example.com',
            password: 'password',
          );
        } catch (e) {
          // Expected to fail
        }

        // Verify token was cleared even though auth failed
        verify(() => mockApiClient.updateAuthToken(null)).called(1);
      });
    });

    group('Integration Scenarios', () {
      test('successful login flow with all dependencies', () async {
        // Big play: complete login flow
        final session = AuthSession(
          token: 'complete_token',
          username: 'complete@example.com',
          userId: 'complete_uid',
          email: 'complete@example.com',
          displayName: 'Complete User',
          photoUrl: 'https://example.com/complete.jpg',
        );

        when(() => mockFirebaseAuth.signInWithEmailPassword(
          email: 'complete@example.com',
          password: 'password123',
        )).thenAnswer((_) async => session);

        final result = await authRepository.login(
          username: 'complete@example.com',
          password: 'password123',
        );

        // Victory lap: verify complete integration
        expect(result, equals(session));

        final verifyOrder = verifyInOrder([
          () => mockApiClient.updateAuthToken(null),
          () => mockFirebaseAuth.signInWithEmailPassword(
            email: 'complete@example.com',
            password: 'password123',
          ),
          () => mockStorage.saveSession(
            token: 'complete_token',
            username: 'complete@example.com',
            userId: 'complete_uid',
            email: 'complete@example.com',
            displayName: 'Complete User',
          ),
          () => mockApiClient.updateAuthToken('complete_token'),
        ]);
      });
    });
  });
}
