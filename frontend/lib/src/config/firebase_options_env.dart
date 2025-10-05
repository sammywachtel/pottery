/// Environment-aware Firebase configuration
/// This file provides Firebase options based on the current environment
/// and can be merged with existing firebase_options.dart configurations

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'environment_config.dart';

/// Environment-aware Firebase options selector
/// Automatically chooses the correct Firebase project based on environment
class EnvironmentFirebaseOptions {

  /// Get Firebase options for current environment and platform
  static FirebaseOptions get currentPlatform {
    // Determine environment-specific options first
    final environmentOptions = _getEnvironmentOptions();

    // Then select platform-specific options
    if (kIsWeb) {
      return environmentOptions.web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return environmentOptions.android;
      case TargetPlatform.iOS:
        return environmentOptions.ios;
      case TargetPlatform.macOS:
        return environmentOptions.macos;
      case TargetPlatform.windows:
        return environmentOptions.windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'Firebase options not configured for Linux in ${EnvironmentConfig.current.name} environment',
        );
      default:
        throw UnsupportedError(
          'Firebase options not supported for this platform in ${EnvironmentConfig.current.name} environment',
        );
    }
  }

  /// Get environment-specific Firebase options
  static _EnvironmentFirebaseConfig _getEnvironmentOptions() {
    switch (EnvironmentConfig.current) {
      case Environment.development:
        return _EnvironmentFirebaseConfig.development;
      case Environment.production:
        return _EnvironmentFirebaseConfig.production;
    }
  }
}

/// Environment-specific Firebase configuration container
class _EnvironmentFirebaseConfig {
  const _EnvironmentFirebaseConfig({
    required this.web,
    required this.android,
    required this.ios,
    required this.macos,
    required this.windows,
  });

  final FirebaseOptions web;
  final FirebaseOptions android;
  final FirebaseOptions ios;
  final FirebaseOptions macos;
  final FirebaseOptions windows;

  /// Development environment Firebase options
  static const development = _EnvironmentFirebaseConfig(
    web: FirebaseOptions(
      apiKey: 'AIzaSyD9_T4dzS6pdBL5QLB6Q4X3SDr7_tH0eg0',
      appId: '1:1073709451179:web:92276550af84ff06feb4ee',
      messagingSenderId: '1073709451179',
      projectId: 'pottery-app-456522',
      authDomain: 'pottery-app-456522.firebaseapp.com',
      storageBucket: 'pottery-app-456522.firebasestorage.app',
      measurementId: 'G-7Y02GN2Q86',
    ),
    android: FirebaseOptions(
      apiKey: 'AIzaSyBBdbgkweVL7JMwZotWf2s-wYEz3paYHJk',
      appId: '1:1073709451179:android:3e9ecd43ceafa460feb4ee',
      messagingSenderId: '1073709451179',
      projectId: 'pottery-app-456522',
      storageBucket: 'pottery-app-456522.firebasestorage.app',
    ),
    ios: FirebaseOptions(
      apiKey: 'AIzaSyBOgCweIIq9qmQdOpPLE5EytPX-vI4-A5U',
      appId: '1:1073709451179:ios:6fee1ddc07108f6afeb4ee',
      messagingSenderId: '1073709451179',
      projectId: 'pottery-app-456522',
      storageBucket: 'pottery-app-456522.firebasestorage.app',
      iosBundleId: 'com.pottery.app.dev',
      iosClientId: '1073709451179-7a1ho6ods7tork3a14um4vo90tqt6vve.apps.googleusercontent.com',
    ),
    macos: FirebaseOptions(
      apiKey: 'AIzaSyBOgCweIIq9qmQdOpPLE5EytPX-vI4-A5U',
      appId: '1:1073709451179:ios:6fee1ddc07108f6afeb4ee',
      messagingSenderId: '1073709451179',
      projectId: 'pottery-app-456522',
      storageBucket: 'pottery-app-456522.firebasestorage.app',
      iosBundleId: 'com.pottery.app.dev',
      iosClientId: '1073709451179-7a1ho6ods7tork3a14um4vo90tqt6vve.apps.googleusercontent.com',
    ),
    windows: FirebaseOptions(
      apiKey: 'AIzaSyD9_T4dzS6pdBL5QLB6Q4X3SDr7_tH0eg0',
      appId: '1:1073709451179:web:92276550af84ff06feb4ee',
      messagingSenderId: '1073709451179',
      projectId: 'pottery-app-456522',
      authDomain: 'pottery-app-456522.firebaseapp.com',
      storageBucket: 'pottery-app-456522.firebasestorage.app',
    ),
  );

  /// Production environment Firebase options
  /// Victory lap: Configured with actual production Firebase project
  static const production = _EnvironmentFirebaseConfig(
    web: FirebaseOptions(
      apiKey: 'AIzaSyCtS6iPBQV4iPv8dFqIcXx4zYJxxxCSPak',
      appId: '1:89677836881:web:892e3174c807201a647e70',
      messagingSenderId: '89677836881',
      projectId: 'pottery-app-prod',
      authDomain: 'pottery-app-prod.firebaseapp.com',
      storageBucket: 'pottery-app-prod.firebasestorage.app',
    ),
    android: FirebaseOptions(
      apiKey: 'AIzaSyCtS6iPBQV4iPv8dFqIcXx4zYJxxxCSPak',
      appId: '1:89677836881:android:3467ec7e9f6018b3647e70',
      messagingSenderId: '89677836881',
      projectId: 'pottery-app-prod',
      storageBucket: 'pottery-app-prod.firebasestorage.app',
    ),
    ios: FirebaseOptions(
      apiKey: 'AIzaSyCtS6iPBQV4iPv8dFqIcXx4zYJxxxCSPak',
      appId: '1:89677836881:android:3467ec7e9f6018b3647e70', // TODO: Create iOS app and update
      messagingSenderId: '89677836881',
      projectId: 'pottery-app-prod',
      storageBucket: 'pottery-app-prod.firebasestorage.app',
      iosBundleId: 'com.pottery.app',
    ),
    macos: FirebaseOptions(
      apiKey: 'AIzaSyCtS6iPBQV4iPv8dFqIcXx4zYJxxxCSPak',
      appId: '1:89677836881:android:3467ec7e9f6018b3647e70', // TODO: Create iOS app and update
      messagingSenderId: '89677836881',
      projectId: 'pottery-app-prod',
      storageBucket: 'pottery-app-prod.firebasestorage.app',
      iosBundleId: 'com.pottery.app',
    ),
    windows: FirebaseOptions(
      apiKey: 'AIzaSyCtS6iPBQV4iPv8dFqIcXx4zYJxxxCSPak',
      appId: '1:89677836881:web:892e3174c807201a647e70',
      messagingSenderId: '89677836881',
      projectId: 'pottery-app-prod',
      authDomain: 'pottery-app-prod.firebaseapp.com',
      storageBucket: 'pottery-app-prod.firebasestorage.app',
    ),
  );
}

/// Helper to get Firebase options with environment context
class FirebaseEnvironment {
  /// Get Firebase options for current environment
  static FirebaseOptions get currentOptions => EnvironmentFirebaseOptions.currentPlatform;

  /// Get Firebase options for specific environment (for testing)
  static FirebaseOptions getOptionsForEnvironment(Environment env, TargetPlatform platform) {
    final config = env == Environment.development
      ? _EnvironmentFirebaseConfig.development
      : _EnvironmentFirebaseConfig.production;

    switch (platform) {
      case TargetPlatform.android:
        return config.android;
      case TargetPlatform.iOS:
        return config.ios;
      case TargetPlatform.macOS:
        return config.macos;
      case TargetPlatform.windows:
        return config.windows;
      default:
        return config.web;
    }
  }

  /// Check if production Firebase configuration is properly set up
  static bool get isProductionConfigured {
    final prodWeb = _EnvironmentFirebaseConfig.production.web;
    return !prodWeb.apiKey.startsWith('PLACEHOLDER_');
  }

  /// Get current environment name for debugging
  static String get currentEnvironmentName => EnvironmentConfig.current.name;
}
