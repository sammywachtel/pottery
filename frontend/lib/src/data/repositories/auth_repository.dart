import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../datasources/api_client.dart';
import '../datasources/token_storage.dart';
import '../models/auth_session.dart';
import '../services/firebase_auth_service.dart';

class AuthRepository {
  AuthRepository(this._client, this._storage, this._firebaseAuth);

  final ApiClient _client;
  final LocalAuthStorage _storage;
  final FirebaseAuthService _firebaseAuth;

  /// Sign in with email and password using Firebase Auth
  /// Returns session with Firebase ID token for backend authentication
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    try {
      // Clear any previous auth state
      _client.updateAuthToken(null);

      // Main play: authenticate with Firebase (username treated as email)
      final session = await _firebaseAuth.signInWithEmailPassword(
        email: username,
        password: password,
      );

      // Victory lap: save session and update API client
      await _storage.saveSession(
        token: session.token,
        username: session.username,
        userId: session.userId,
        email: session.email,
        displayName: session.displayName,
      );
      _client.updateAuthToken(session.token);

      return session;
    } catch (error) {
      // Firebase service already handles error mapping
      rethrow;
    }
  }

  /// Load persisted session and validate with Firebase
  /// Returns null if no valid session exists
  Future<AuthSession?> loadPersistedSession() async {
    try {
      // Check if we have stored session data
      final storedToken = await _storage.readToken();
      final storedUsername = await _storage.readUsername();

      if (storedToken == null || storedUsername == null) {
        return null;
      }

      // Validate that Firebase still considers us authenticated
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        // Firebase session expired, clear local storage
        await _storage.clear();
        return null;
      }

      // Check if token is still valid and refresh if needed
      final isValid = await _firebaseAuth.isTokenValid();
      if (!isValid) {
        await _storage.clear();
        return null;
      }

      // Get fresh token (this handles auto-refresh)
      final freshToken = await _firebaseAuth.getIdToken();
      if (freshToken == null) {
        await _storage.clear();
        return null;
      }

      // Update stored token if it changed
      if (freshToken != storedToken) {
        await _storage.saveSession(
          token: freshToken,
          username: storedUsername,
          userId: user.uid,
          email: user.email,
          displayName: user.displayName,
        );
      }

      _client.updateAuthToken(freshToken);

      return AuthSession(
        token: freshToken,
        username: storedUsername,
        userId: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoUrl: user.photoURL,
      );
    } catch (error) {
      // On any error, clear session and start fresh
      await _storage.clear();
      return null;
    }
  }

  /// Sign out from Firebase and clear all local session data
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } finally {
      // Always clear local storage, even if Firebase sign out fails
      await _storage.clear();
      _client.updateAuthToken(null);
    }
  }

  /// Sign in with Google OAuth
  /// Returns session with Firebase ID token
  Future<AuthSession> signInWithGoogle() async {
    try {
      _client.updateAuthToken(null);

      final session = await _firebaseAuth.signInWithGoogle();

      await _storage.saveSession(
        token: session.token,
        username: session.username,
        userId: session.userId,
        email: session.email,
        displayName: session.displayName,
      );
      _client.updateAuthToken(session.token);

      return session;
    } catch (error) {
      rethrow;
    }
  }

  /// Get fresh authentication token
  /// Handles automatic refresh when needed
  Future<String?> refreshToken() async {
    try {
      final freshToken = await _firebaseAuth.getIdToken(forceRefresh: true);
      if (freshToken != null) {
        final username = await _storage.readUsername();
        final user = _firebaseAuth.currentUser;

        if (username != null && user != null) {
          await _storage.saveSession(
            token: freshToken,
            username: username,
            userId: user.uid,
            email: user.email,
            displayName: user.displayName,
          );
          _client.updateAuthToken(freshToken);
        }
      }
      return freshToken;
    } catch (error) {
      return null;
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  final storage = LocalAuthStorage();
  final firebaseAuth = FirebaseAuthService();
  final repository = AuthRepository(client, storage, firebaseAuth);

  // Wire up the auth interceptor for automatic token refresh on 401 errors
  // This prevents users from losing form data when tokens expire
  client.dio.interceptors.add(
    AuthInterceptor(() => repository.refreshToken()),
  );

  return repository;
});
