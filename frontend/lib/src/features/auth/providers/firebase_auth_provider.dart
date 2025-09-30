import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/services/firebase_auth_service.dart';

/// Provider for Firebase Auth Service
/// Single instance for the entire app
final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

/// Stream provider for Firebase auth state changes
/// Automatically updates when user signs in/out
final firebaseAuthStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  return authService.authStateChanges;
});

/// Provider for current Firebase user
/// Returns null if not authenticated
final currentFirebaseUserProvider = Provider<User?>((ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  return authService.currentUser;
});
