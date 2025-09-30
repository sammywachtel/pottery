import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart'; // Legacy options - kept for backward compatibility
import 'src/app.dart';
import 'src/config/app_config.dart';
import 'src/config/environment_config.dart';
import 'src/config/firebase_options_env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize environment configuration
  final config = AppConfig.fromEnv();

  // Log environment information in debug mode
  if (config.debugEnabled && kDebugMode) {
    debugPrint('🌍 Environment: ${config.environmentName}');
    debugPrint('🔗 API Base URL: ${config.apiBaseUrl}');
    debugPrint('🗄️ Storage URL: ${config.storageBucketUrl}');
    debugPrint('🐛 Debug Mode: ${config.debugEnabled}');
  }

  // Initialize Firebase with environment-aware options
  await _initializeFirebase(config);

  runApp(ProviderScope(
    overrides: [appConfigProvider.overrideWithValue(config)],
    child: const PotteryApp(),
  ));
}

/// Initialize Firebase with environment awareness and fallback support
Future<void> _initializeFirebase(AppConfig config) async {
  try {
    FirebaseOptions options;

    // Try environment-aware Firebase options first
    if (FirebaseEnvironment.isProductionConfigured || config.isDevelopment) {
      options = EnvironmentFirebaseOptions.currentPlatform;
      if (config.debugEnabled && kDebugMode) {
        debugPrint('🔥 Using environment-aware Firebase options for ${config.environmentName}');
        debugPrint('📦 Firebase Project: ${options.projectId}');
      }
    } else {
      // Fallback to legacy Firebase options if production not configured
      options = DefaultFirebaseOptions.currentPlatform;
      if (config.debugEnabled && kDebugMode) {
        debugPrint('🔥 Using legacy Firebase options (production not configured)');
        debugPrint('📦 Firebase Project: ${options.projectId}');
      }
    }

    await Firebase.initializeApp(options: options);

    if (config.debugEnabled && kDebugMode) {
      debugPrint('✅ Firebase initialized successfully');
    }
  } catch (e) {
    // Detailed error logging in debug mode
    if (config.debugEnabled && kDebugMode) {
      debugPrint('❌ Firebase initialization failed: $e');
    }

    // In production, try fallback initialization
    if (config.isProduction) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        if (kDebugMode) {
          debugPrint('✅ Firebase initialized with fallback options');
        }
      } catch (fallbackError) {
        if (kDebugMode) {
          debugPrint('❌ Firebase fallback initialization also failed: $fallbackError');
        }
        rethrow; // Let the app handle this appropriately
      }
    } else {
      rethrow; // Re-throw in development for proper debugging
    }
  }
}
