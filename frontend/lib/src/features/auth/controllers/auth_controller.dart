import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_exception.dart';
import '../../../data/models/auth_session.dart';
import '../../../data/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository) : super(AuthState.initial()) {
    _initialize();
  }

  final AuthRepository _repository;

  Future<void> _initialize() async {
    try {
      final session = await _repository.loadPersistedSession();
      if (session != null) {
        _setAuthenticated(session);
      } else {
        state = state.copyWith(
          isInitializing: false,
          isLoading: false,
          isAuthenticated: false,
        );
      }
    } catch (error) {
      state = state.copyWith(
        isInitializing: false,
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  /// Sign in with email and password using Firebase Auth
  Future<void> login({required String username, required String password}) async {
    state = state.copyWith(
      isInitializing: false,
      isLoading: true,
      errorMessage: null,
    );
    try {
      final session = await _repository.login(
        username: username,
        password: password,
      );
      _setAuthenticated(session);
    } on AppException catch (error) {
      state = state.copyWith(
        isInitializing: false,
        isLoading: false,
        isAuthenticated: false,
        errorMessage: error.message,
      );
    } catch (error) {
      state = state.copyWith(
        isInitializing: false,
        isLoading: false,
        isAuthenticated: false,
        errorMessage: error.toString(),
      );
    }
  }

  /// Sign in with Google OAuth
  Future<void> signInWithGoogle() async {
    state = state.copyWith(
      isInitializing: false,
      isLoading: true,
      errorMessage: null,
    );
    try {
      final session = await _repository.signInWithGoogle();
      _setAuthenticated(session);
    } on AppException catch (error) {
      state = state.copyWith(
        isInitializing: false,
        isLoading: false,
        isAuthenticated: false,
        errorMessage: error.message,
      );
    } catch (error) {
      state = state.copyWith(
        isInitializing: false,
        isLoading: false,
        isAuthenticated: false,
        errorMessage: error.toString(),
      );
    }
  }

  /// Sign out and clear all authentication state
  Future<void> logout() async {
    await _repository.logout();
    state = state.copyWith(
      isInitializing: false,
      isLoading: false,
      isAuthenticated: false,
      username: null,
      token: null,
      userId: null,
      email: null,
      displayName: null,
      photoUrl: null,
    );
  }

  void _setAuthenticated(AuthSession session) {
    state = state.copyWith(
      isInitializing: false,
      isLoading: false,
      isAuthenticated: true,
      username: session.username,
      token: session.token,
      userId: session.userId,
      email: session.email,
      displayName: session.displayName,
      photoUrl: session.photoUrl,
      errorMessage: null,
    );
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthController(repository);
});
