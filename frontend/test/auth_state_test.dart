import 'package:flutter_test/flutter_test.dart';

import 'package:pottery_frontend/src/features/auth/controllers/auth_state.dart';

void main() {
  test('copyWith preserves existing values by default', () {
    const initial = AuthState(
      isInitializing: false,
      isLoading: false,
      isAuthenticated: true,
      username: 'sam',
      token: 'abc',
      userId: 'user123',
      email: 'sam@example.com',
      displayName: 'Sam Smith',
      photoUrl: 'https://example.com/photo.jpg',
    );

    final updated = initial.copyWith();

    expect(updated.isInitializing, initial.isInitializing);
    expect(updated.isLoading, initial.isLoading);
    expect(updated.isAuthenticated, initial.isAuthenticated);
    expect(updated.username, initial.username);
    expect(updated.token, initial.token);
    expect(updated.userId, initial.userId);
    expect(updated.email, initial.email);
    expect(updated.displayName, initial.displayName);
    expect(updated.photoUrl, initial.photoUrl);
  });

  test('copyWith can reset nullable fields', () {
    const initial = AuthState(
      isInitializing: false,
      isLoading: false,
      isAuthenticated: true,
      username: 'sam',
      token: 'abc',
      userId: 'user123',
      email: 'sam@example.com',
      displayName: 'Sam Smith',
      photoUrl: 'https://example.com/photo.jpg',
    );

    final updated = initial.copyWith(
      username: null,
      token: null,
      userId: null,
      email: null,
      displayName: null,
      photoUrl: null,
    );

    expect(updated.username, isNull);
    expect(updated.token, isNull);
    expect(updated.userId, isNull);
    expect(updated.email, isNull);
    expect(updated.displayName, isNull);
    expect(updated.photoUrl, isNull);
  });
}
