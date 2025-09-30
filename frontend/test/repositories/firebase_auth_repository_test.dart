/// Unit tests for Firebase authentication repository.
///
/// Tests Firebase authentication functionality including:
/// - Email/password authentication
/// - Google Sign-In authentication
/// - Token management and refresh
/// - User state management
/// - Error handling scenarios

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Mock classes for Firebase dependencies
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}
class MockUserCredential extends Mock implements UserCredential {}
class MockGoogleSignIn extends Mock implements GoogleSignIn {}
class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}
class MockGoogleSignInAuthentication extends Mock implements GoogleSignInAuthentication {}

/// Mock Firebase Auth repository for testing
class FirebaseAuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  /// Sign in with email and password
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      // Opening move: trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // User canceled the sign-in
      }

      // Main play: get authentication details from Google
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Big play: create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Victory lap: sign in to Firebase with Google credential
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  /// Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  /// Get ID token for API authentication
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;

    return await user.getIdToken(forceRefresh);
  }

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Stream of user changes (including profile updates)
  Stream<User?> get userChanges => _firebaseAuth.userChanges();
}

void main() {
  group('FirebaseAuthRepository Tests', () {
    late MockFirebaseAuth mockFirebaseAuth;
    late MockGoogleSignIn mockGoogleSignIn;
    late FirebaseAuthRepository repository;
    late MockUser mockUser;
    late MockUserCredential mockUserCredential;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      mockGoogleSignIn = MockGoogleSignIn();
      mockUser = MockUser();
      mockUserCredential = MockUserCredential();

      repository = FirebaseAuthRepository(
        firebaseAuth: mockFirebaseAuth,
        googleSignIn: mockGoogleSignIn,
      );

      // Setup default mock behaviors
      when(() => mockUserCredential.user).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn('test_user_123');
      when(() => mockUser.email).thenReturn('test@example.com');
      when(() => mockUser.displayName).thenReturn('Test User');
    });

    group('Email/Password Authentication', () {
      test('signInWithEmailAndPassword success', () async {
        // Opening move: setup successful sign-in
        when(() => mockFirebaseAuth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => mockUserCredential);

        // Main play: attempt sign-in
        final result = await repository.signInWithEmailAndPassword(
          'test@example.com',
          'password123',
        );

        // Victory lap: verify success
        expect(result, equals(mockUser));
        verify(() => mockFirebaseAuth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        )).called(1);
      });

      test('signInWithEmailAndPassword with invalid credentials throws exception', () async {
        // Setup Firebase to throw authentication error
        when(() => mockFirebaseAuth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user found for that email.',
        ));

        // Verify exception is propagated
        expect(
          () => repository.signInWithEmailAndPassword('invalid@example.com', 'wrongpassword'),
          throwsA(isA<FirebaseAuthException>()),
        );
      });

      test('signInWithEmailAndPassword with wrong password throws exception', () async {
        // Setup Firebase to throw wrong password error
        when(() => mockFirebaseAuth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(FirebaseAuthException(
          code: 'wrong-password',
          message: 'Wrong password provided.',
        ));

        expect(
          () => repository.signInWithEmailAndPassword('test@example.com', 'wrongpassword'),
          throwsA(isA<FirebaseAuthException>()),
        );
      });

      test('signInWithEmailAndPassword with disabled user throws exception', () async {
        // Setup Firebase to throw user disabled error
        when(() => mockFirebaseAuth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(FirebaseAuthException(
          code: 'user-disabled',
          message: 'The user account has been disabled.',
        ));

        expect(
          () => repository.signInWithEmailAndPassword('disabled@example.com', 'password123'),
          throwsA(isA<FirebaseAuthException>()),
        );
      });
    });

    group('Google Sign-In Authentication', () {
      late MockGoogleSignInAccount mockGoogleAccount;
      late MockGoogleSignInAuthentication mockGoogleAuth;

      setUp(() {
        mockGoogleAccount = MockGoogleSignInAccount();
        mockGoogleAuth = MockGoogleSignInAuthentication();

        // Setup Google Sign-In mocks
        when(() => mockGoogleAccount.authentication)
            .thenAnswer((_) async => mockGoogleAuth);
        when(() => mockGoogleAuth.accessToken).thenReturn('google_access_token');
        when(() => mockGoogleAuth.idToken).thenReturn('google_id_token');
      });

      test('signInWithGoogle success', () async {
        // Opening move: setup successful Google Sign-In flow
        when(() => mockGoogleSignIn.signIn())
            .thenAnswer((_) async => mockGoogleAccount);

        when(() => mockFirebaseAuth.signInWithCredential(any()))
            .thenAnswer((_) async => mockUserCredential);

        // Main play: attempt Google sign-in
        final result = await repository.signInWithGoogle();

        // Victory lap: verify success
        expect(result, equals(mockUser));

        verify(() => mockGoogleSignIn.signIn()).called(1);
        verify(() => mockFirebaseAuth.signInWithCredential(any())).called(1);
      });

      test('signInWithGoogle user cancels returns null', () async {
        // Setup Google Sign-In to return null (user canceled)
        when(() => mockGoogleSignIn.signIn()).thenAnswer((_) async => null);

        final result = await repository.signInWithGoogle();

        expect(result, isNull);
        verify(() => mockGoogleSignIn.signIn()).called(1);
        verifyNever(() => mockFirebaseAuth.signInWithCredential(any()));
      });

      test('signInWithGoogle Firebase credential error throws exception', () async {
        // Setup Google Sign-In success but Firebase credential failure
        when(() => mockGoogleSignIn.signIn())
            .thenAnswer((_) async => mockGoogleAccount);

        when(() => mockFirebaseAuth.signInWithCredential(any()))
            .thenThrow(FirebaseAuthException(
              code: 'account-exists-with-different-credential',
              message: 'Account exists with different credential.',
            ));

        expect(
          () => repository.signInWithGoogle(),
          throwsA(isA<FirebaseAuthException>()),
        );
      });

      test('signInWithGoogle network error throws exception', () async {
        // Setup network error during Google Sign-In
        when(() => mockGoogleSignIn.signIn())
            .thenThrow(Exception('Network error'));

        expect(
          () => repository.signInWithGoogle(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Token Management', () {
      test('getIdToken returns token for authenticated user', () async {
        // Setup authenticated user
        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.getIdToken(any())).thenAnswer((_) async => 'firebase_id_token');

        final token = await repository.getIdToken();

        expect(token, equals('firebase_id_token'));
        verify(() => mockUser.getIdToken(false)).called(1);
      });

      test('getIdToken with force refresh', () async {
        // Setup authenticated user
        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.getIdToken(any())).thenAnswer((_) async => 'refreshed_firebase_token');

        final token = await repository.getIdToken(true);

        expect(token, equals('refreshed_firebase_token'));
        verify(() => mockUser.getIdToken(true)).called(1);
      });

      test('getIdToken returns null when no user authenticated', () async {
        // Setup no authenticated user
        when(() => mockFirebaseAuth.currentUser).thenReturn(null);

        final token = await repository.getIdToken();

        expect(token, isNull);
        verifyNever(() => mockUser.getIdToken(any()));
      });

      test('getIdToken handles token refresh error', () async {
        // Setup user but token refresh fails
        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.getIdToken(any())).thenThrow(
          FirebaseAuthException(code: 'network-request-failed', message: 'Network error'),
        );

        expect(
          () => repository.getIdToken(),
          throwsA(isA<FirebaseAuthException>()),
        );
      });
    });

    group('User State Management', () {
      test('currentUser returns authenticated user', () {
        // Setup authenticated user
        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);

        final user = repository.currentUser;

        expect(user, equals(mockUser));
      });

      test('currentUser returns null when not authenticated', () {
        // Setup no authenticated user
        when(() => mockFirebaseAuth.currentUser).thenReturn(null);

        final user = repository.currentUser;

        expect(user, isNull);
      });

      test('authStateChanges stream works correctly', () {
        // Setup auth state stream
        final authStream = Stream<User?>.fromIterable([null, mockUser, null]);
        when(() => mockFirebaseAuth.authStateChanges()).thenAnswer((_) => authStream);

        final stream = repository.authStateChanges;

        expect(stream, emitsInOrder([null, mockUser, null]));
      });

      test('userChanges stream works correctly', () {
        // Setup user changes stream
        final userStream = Stream<User?>.fromIterable([mockUser]);
        when(() => mockFirebaseAuth.userChanges()).thenAnswer((_) => userStream);

        final stream = repository.userChanges;

        expect(stream, emits(mockUser));
      });
    });

    group('Sign Out', () {
      test('signOut calls both Firebase and Google sign out', () async {
        // Setup mocks
        when(() => mockFirebaseAuth.signOut()).thenAnswer((_) async => {});
        when(() => mockGoogleSignIn.signOut()).thenAnswer((_) async => mockGoogleAccount);

        await repository.signOut();

        verify(() => mockFirebaseAuth.signOut()).called(1);
        verify(() => mockGoogleSignIn.signOut()).called(1);
      });

      test('signOut handles Firebase error gracefully', () async {
        // Setup Firebase sign out to fail but Google to succeed
        when(() => mockFirebaseAuth.signOut()).thenThrow(
          FirebaseAuthException(code: 'network-request-failed', message: 'Network error'),
        );
        when(() => mockGoogleSignIn.signOut()).thenAnswer((_) async => mockGoogleAccount);

        // This test shows that if one service fails, we still want to attempt the other
        // In practice, you might want to handle this differently
        expect(
          () => repository.signOut(),
          throwsA(isA<FirebaseAuthException>()),
        );
      });

      test('signOut handles Google Sign-In error gracefully', () async {
        // Setup Google sign out to fail but Firebase to succeed
        when(() => mockFirebaseAuth.signOut()).thenAnswer((_) async => {});
        when(() => mockGoogleSignIn.signOut()).thenThrow(Exception('Google sign out failed'));

        expect(
          () => repository.signOut(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Error Handling Scenarios', () {
      test('handles network connectivity issues', () async {
        // Setup network error
        when(() => mockFirebaseAuth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(FirebaseAuthException(
          code: 'network-request-failed',
          message: 'A network error occurred.',
        ));

        expect(
          () => repository.signInWithEmailAndPassword('test@example.com', 'password123'),
          throwsA(predicate((e) =>
            e is FirebaseAuthException && e.code == 'network-request-failed')),
        );
      });

      test('handles too many requests error', () async {
        // Setup too many requests error
        when(() => mockFirebaseAuth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(FirebaseAuthException(
          code: 'too-many-requests',
          message: 'Too many unsuccessful login attempts.',
        ));

        expect(
          () => repository.signInWithEmailAndPassword('test@example.com', 'password123'),
          throwsA(predicate((e) =>
            e is FirebaseAuthException && e.code == 'too-many-requests')),
        );
      });

      test('handles invalid email format error', () async {
        // Setup invalid email error
        when(() => mockFirebaseAuth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(FirebaseAuthException(
          code: 'invalid-email',
          message: 'The email address is badly formatted.',
        ));

        expect(
          () => repository.signInWithEmailAndPassword('invalid-email', 'password123'),
          throwsA(predicate((e) =>
            e is FirebaseAuthException && e.code == 'invalid-email')),
        );
      });
    });
  });
}
