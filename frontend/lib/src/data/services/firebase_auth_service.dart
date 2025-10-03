import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../core/app_exception.dart';
import '../models/auth_session.dart';

/// Service for handling Firebase Authentication operations
/// Wraps Firebase Auth with pottery app-specific logic and error handling
class FirebaseAuthService {
  FirebaseAuthService() : _auth = FirebaseAuth.instance;

  final FirebaseAuth _auth;

  // Configure GoogleSignIn with explicit iOS client ID for macOS
  // On macOS, we need to use the iOS OAuth client for Google Sign-In
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: (!kIsWeb && Platform.isMacOS)
        ? '1073709451179-7a1ho6ods7tork3a14um4vo90tqt6vve.apps.googleusercontent.com'
        : null, // Auto-detect for other platforms
  );

  /// Stream of authentication state changes
  /// Emits User when authenticated, null when not
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current authenticated user, null if not signed in
  User? get currentUser => _auth.currentUser;

  /// Sign in with email and password
  /// Returns AuthSession with Firebase ID token for backend auth
  Future<AuthSession> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Main play: authenticate with Firebase
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const AppException('Authentication failed - no user returned');
      }

      // Victory lap: get fresh ID token for backend
      final idToken = await user.getIdToken();
      if (idToken == null) {
        throw const AppException('Failed to get authentication token');
      }

      return AuthSession(
        token: idToken,
        username: user.email ?? email,
        userId: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoUrl: user.photoURL,
      );
    } on FirebaseAuthException catch (error) {
      // Here's where we translate Firebase errors to user-friendly messages
      throw AppException(_mapFirebaseError(error));
    } catch (error) {
      throw AppException('Sign in failed: ${error.toString()}');
    }
  }

  /// Sign in with Google OAuth
  /// Handles the OAuth flow and returns Firebase auth session
  Future<AuthSession> signInWithGoogle() async {
    try {
      // Opening move: initiate Google sign-in flow
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const AppException('Google sign-in was cancelled');
      }

      // Get Google auth details
      final googleAuth = await googleUser.authentication;

      // Create Firebase credential from Google tokens
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Main play: authenticate with Firebase using Google credential
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        throw const AppException('Google authentication failed');
      }

      // Victory lap: get Firebase ID token for backend
      final idToken = await user.getIdToken();
      if (idToken == null) {
        throw const AppException('Failed to get authentication token');
      }

      return AuthSession(
        token: idToken,
        username: user.email ?? user.displayName ?? 'Google User',
        userId: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoUrl: user.photoURL,
      );
    } on FirebaseAuthException catch (error) {
      throw AppException(_mapFirebaseError(error));
    } catch (error) {
      throw AppException('Google sign-in failed: ${error.toString()}');
    }
  }

  /// Sign out from both Firebase and Google
  /// Clears all authentication state
  Future<void> signOut() async {
    try {
      // Sign out from both services to ensure clean state
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (error) {
      // Log error but don't throw - sign out should always succeed
      // TODO: Use proper logging instead of print in production
    }
  }

  /// Get fresh ID token for API authentication
  /// Forces refresh if token is close to expiry
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    try {
      final user = currentUser;
      if (user == null) return null;

      return await user.getIdToken(forceRefresh);
    } catch (error) {
      // Token refresh failed - return null
      // TODO: Use proper logging instead of print in production
      return null;
    }
  }

  /// Check if current token is still valid
  /// Returns false if user is null or token is expired
  Future<bool> isTokenValid() async {
    try {
      final user = currentUser;
      if (user == null) return false;

      // This will throw if token is invalid/expired
      await user.getIdToken();
      return true;
    } catch (error) {
      return false;
    }
  }

  /// Convert Firebase auth errors to user-friendly messages
  /// This saves users from seeing cryptic Firebase error codes
  String _mapFirebaseError(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return 'No account found with this email address';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Please enter a valid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password';
      case 'email-already-in-use':
        return 'An account already exists with this email address';
      case 'invalid-credential':
        return 'Invalid email or password';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      default:
        return error.message ?? 'Authentication failed';
    }
  }
}
