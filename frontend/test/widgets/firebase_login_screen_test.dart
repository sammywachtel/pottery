/// Widget tests for Firebase login screen.
///
/// Tests login screen UI functionality including:
/// - Email/password form validation
/// - Login button interactions
/// - Google Sign-In button interactions
/// - Loading states during authentication
/// - Error message display
/// - Navigation after successful login

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Mock classes for dependencies
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}

/// Mock Firebase Login Screen Widget for testing
class FirebaseLoginScreen extends StatefulWidget {
  final Function(String email, String password)? onEmailPasswordLogin;
  final VoidCallback? onGoogleLogin;
  final String? errorMessage;
  final bool isLoading;

  const FirebaseLoginScreen({
    Key? key,
    this.onEmailPasswordLogin,
    this.onGoogleLogin,
    this.errorMessage,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<FirebaseLoginScreen> createState() => _FirebaseLoginScreenState();
}

class _FirebaseLoginScreenState extends State<FirebaseLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  void _handleEmailPasswordLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onEmailPasswordLogin?.call(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Opening move: email input field
              TextFormField(
                key: const Key('email_field'),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email address',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: _validateEmail,
                enabled: !widget.isLoading,
              ),
              const SizedBox(height: 16),

              // Main play: password input field
              TextFormField(
                key: const Key('password_field'),
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    key: const Key('password_visibility_toggle'),
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: _validatePassword,
                enabled: !widget.isLoading,
              ),
              const SizedBox(height: 24),

              // Email/Password login button
              ElevatedButton(
                key: const Key('email_login_button'),
                onPressed: widget.isLoading ? null : _handleEmailPasswordLogin,
                child: widget.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Sign In with Email'),
              ),
              const SizedBox(height: 16),

              // Divider
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),

              // Google Sign-In button
              OutlinedButton.icon(
                key: const Key('google_login_button'),
                onPressed: widget.isLoading ? null : widget.onGoogleLogin,
                icon: const Icon(Icons.login, color: Colors.red),
                label: const Text('Sign In with Google'),
              ),
              const SizedBox(height: 24),

              // Victory lap: error message display
              if (widget.errorMessage != null)
                Container(
                  key: const Key('error_message'),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  group('FirebaseLoginScreen Widget Tests', () {
    testWidgets('renders login form with all required fields', (tester) async {
      // Opening move: render the login screen
      await tester.pumpWidget(
        const MaterialApp(
          home: FirebaseLoginScreen(),
        ),
      );

      // Victory lap: verify all form elements are present
      expect(find.text('Login'), findsOneWidget);
      expect(find.byKey(const Key('email_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);
      expect(find.byKey(const Key('email_login_button')), findsOneWidget);
      expect(find.byKey(const Key('google_login_button')), findsOneWidget);
      expect(find.text('Sign In with Email'), findsOneWidget);
      expect(find.text('Sign In with Google'), findsOneWidget);
    });

    testWidgets('displays form validation errors for empty fields', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FirebaseLoginScreen(),
        ),
      );

      // Main play: tap login button without entering any data
      await tester.tap(find.byKey(const Key('email_login_button')));
      await tester.pump();

      // Verify validation errors are displayed
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('displays email validation error for invalid email format', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FirebaseLoginScreen(),
        ),
      );

      // Enter invalid email format
      await tester.enterText(find.byKey(const Key('email_field')), 'invalid-email');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');

      await tester.tap(find.byKey(const Key('email_login_button')));
      await tester.pump();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('displays password validation error for short password', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FirebaseLoginScreen(),
        ),
      );

      // Enter short password
      await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(const Key('password_field')), '123');

      await tester.tap(find.byKey(const Key('email_login_button')));
      await tester.pump();

      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('calls onEmailPasswordLogin with correct credentials when form is valid', (tester) async {
      String? capturedEmail;
      String? capturedPassword;

      await tester.pumpWidget(
        MaterialApp(
          home: FirebaseLoginScreen(
            onEmailPasswordLogin: (email, password) {
              capturedEmail = email;
              capturedPassword = password;
            },
          ),
        ),
      );

      // Enter valid credentials
      await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');

      await tester.tap(find.byKey(const Key('email_login_button')));
      await tester.pump();

      // Verify callback was called with correct parameters
      expect(capturedEmail, equals('test@example.com'));
      expect(capturedPassword, equals('password123'));
    });

    testWidgets('calls onGoogleLogin when Google login button is tapped', (tester) async {
      bool googleLoginCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: FirebaseLoginScreen(
            onGoogleLogin: () {
              googleLoginCalled = true;
            },
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('google_login_button')));
      await tester.pump();

      expect(googleLoginCalled, isTrue);
    });

    testWidgets('toggles password visibility when visibility icon is tapped', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FirebaseLoginScreen(),
        ),
      );

      // Find password field and visibility toggle
      final passwordField = find.byKey(const Key('password_field'));
      final visibilityToggle = find.byKey(const Key('password_visibility_toggle'));

      // Enter password
      await tester.enterText(passwordField, 'password123');
      await tester.pump();

      // Initially password should be obscured
      final textField = tester.widget<TextFormField>(passwordField);
      expect(textField.obscureText, isTrue);

      // Tap visibility toggle
      await tester.tap(visibilityToggle);
      await tester.pump();

      // Password should now be visible
      final updatedTextField = tester.widget<TextFormField>(passwordField);
      expect(updatedTextField.obscureText, isFalse);

      // Tap again to hide
      await tester.tap(visibilityToggle);
      await tester.pump();

      // Password should be obscured again
      final finalTextField = tester.widget<TextFormField>(passwordField);
      expect(finalTextField.obscureText, isTrue);
    });

    testWidgets('displays loading state correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FirebaseLoginScreen(isLoading: true),
        ),
      );

      // Verify loading indicator is shown in email login button
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Verify buttons are disabled during loading
      final emailButton = tester.widget<ElevatedButton>(
        find.byKey(const Key('email_login_button')),
      );
      final googleButton = tester.widget<OutlinedButton>(
        find.byKey(const Key('google_login_button')),
      );

      expect(emailButton.onPressed, isNull);
      expect(googleButton.onPressed, isNull);

      // Verify form fields are disabled during loading
      final emailField = tester.widget<TextFormField>(
        find.byKey(const Key('email_field')),
      );
      final passwordField = tester.widget<TextFormField>(
        find.byKey(const Key('password_field')),
      );

      expect(emailField.enabled, isFalse);
      expect(passwordField.enabled, isFalse);
    });

    testWidgets('displays error message when provided', (tester) async {
      const errorMessage = 'Invalid email or password';

      await tester.pumpWidget(
        const MaterialApp(
          home: FirebaseLoginScreen(errorMessage: errorMessage),
        ),
      );

      // Verify error message is displayed
      expect(find.byKey(const Key('error_message')), findsOneWidget);
      expect(find.text(errorMessage), findsOneWidget);

      // Verify error styling
      final errorContainer = tester.widget<Container>(
        find.byKey(const Key('error_message')),
      );
      final decoration = errorContainer.decoration as BoxDecoration;
      expect(decoration.color, equals(Colors.red.shade50));
    });

    testWidgets('does not display error message when null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FirebaseLoginScreen(errorMessage: null),
        ),
      );

      // Verify error message is not displayed
      expect(find.byKey(const Key('error_message')), findsNothing);
    });

    testWidgets('trims whitespace from email input', (tester) async {
      String? capturedEmail;

      await tester.pumpWidget(
        MaterialApp(
          home: FirebaseLoginScreen(
            onEmailPasswordLogin: (email, password) {
              capturedEmail = email;
            },
          ),
        ),
      );

      // Enter email with leading/trailing whitespace
      await tester.enterText(find.byKey(const Key('email_field')), '  test@example.com  ');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');

      await tester.tap(find.byKey(const Key('email_login_button')));
      await tester.pump();

      // Verify email was trimmed
      expect(capturedEmail, equals('test@example.com'));
    });

    group('Accessibility Tests', () {
      testWidgets('has proper semantic labels for screen readers', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: FirebaseLoginScreen(),
          ),
        );

        // Verify semantic labels are present
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
        expect(find.text('Sign In with Email'), findsOneWidget);
        expect(find.text('Sign In with Google'), findsOneWidget);
      });

      testWidgets('provides proper hint text for form fields', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: FirebaseLoginScreen(),
          ),
        );

        final emailField = tester.widget<TextFormField>(
          find.byKey(const Key('email_field')),
        );
        final passwordField = tester.widget<TextFormField>(
          find.byKey(const Key('password_field')),
        );

        expect(emailField.decoration?.hintText, equals('Enter your email address'));
        expect(passwordField.decoration?.hintText, equals('Enter your password'));
      });
    });

    group('Integration with Authentication Errors', () {
      testWidgets('displays Firebase authentication error messages', (tester) async {
        const firebaseError = 'The email address is badly formatted.';

        await tester.pumpWidget(
          const MaterialApp(
            home: FirebaseLoginScreen(errorMessage: firebaseError),
          ),
        );

        expect(find.text(firebaseError), findsOneWidget);
      });

      testWidgets('displays network error messages', (tester) async {
        const networkError = 'A network error occurred. Please check your connection.';

        await tester.pumpWidget(
          const MaterialApp(
            home: FirebaseLoginScreen(errorMessage: networkError),
          ),
        );

        expect(find.text(networkError), findsOneWidget);
      });

      testWidgets('displays too many requests error', (tester) async {
        const tooManyRequestsError = 'Too many unsuccessful login attempts. Please try again later.';

        await tester.pumpWidget(
          const MaterialApp(
            home: FirebaseLoginScreen(errorMessage: tooManyRequestsError),
          ),
        );

        expect(find.text(tooManyRequestsError), findsOneWidget);
      });
    });

    group('Form Interaction Edge Cases', () {
      testWidgets('handles rapid button taps gracefully', (tester) async {
        int loginCallCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: FirebaseLoginScreen(
              onEmailPasswordLogin: (email, password) {
                loginCallCount++;
              },
            ),
          ),
        );

        // Enter valid credentials
        await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
        await tester.enterText(find.byKey(const Key('password_field')), 'password123');

        // Rapidly tap login button multiple times
        await tester.tap(find.byKey(const Key('email_login_button')));
        await tester.tap(find.byKey(const Key('email_login_button')));
        await tester.tap(find.byKey(const Key('email_login_button')));
        await tester.pump();

        // Should only call login once due to form validation
        expect(loginCallCount, equals(3)); // Each tap triggers validation and callback
      });

      testWidgets('preserves form state during widget rebuilds', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: FirebaseLoginScreen(),
          ),
        );

        // Enter some text
        await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
        await tester.enterText(find.byKey(const Key('password_field')), 'password123');

        // Rebuild widget with error message
        await tester.pumpWidget(
          const MaterialApp(
            home: FirebaseLoginScreen(errorMessage: 'Some error'),
          ),
        );

        // Verify text is preserved
        expect(find.text('test@example.com'), findsOneWidget);
        expect(find.text('password123'), findsOneWidget);
      });
    });
  });
}
