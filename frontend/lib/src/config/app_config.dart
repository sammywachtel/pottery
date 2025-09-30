import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'environment_config.dart';

class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.storageBucketUrl,
    required this.environment,
    required this.debugEnabled,
  });

  final String apiBaseUrl;
  final String storageBucketUrl;
  final Environment environment;
  final bool debugEnabled;

  factory AppConfig.fromEnv() {
    return AppConfig(
      apiBaseUrl: EnvironmentConfig.apiBaseUrl,
      storageBucketUrl: EnvironmentConfig.storageBucketUrl,
      environment: EnvironmentConfig.current,
      debugEnabled: EnvironmentConfig.debugEnabled,
    );
  }

  /// Legacy factory for backward compatibility
  /// Prefer AppConfig.fromEnv() for new code
  @Deprecated('Use AppConfig.fromEnv() instead')
  factory AppConfig.legacy() {
    const api = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8000',
    );
    const bucket = String.fromEnvironment(
      'STORAGE_BUCKET_URL',
      defaultValue: '',
    );
    return AppConfig(
      apiBaseUrl: api,
      storageBucketUrl: bucket,
      environment: Environment.development,
      debugEnabled: true,
    );
  }

  /// Check if running in development
  bool get isDevelopment => environment == Environment.development;

  /// Check if running in production
  bool get isProduction => environment == Environment.production;

  /// Get environment display name
  String get environmentName => environment.name;

  /// Get configuration summary for debugging
  Map<String, dynamic> get summary => {
    'environment': environmentName,
    'apiBaseUrl': apiBaseUrl,
    'storageBucketUrl': storageBucketUrl,
    'debugEnabled': debugEnabled,
    'isDevelopment': isDevelopment,
    'isProduction': isProduction,
  };
}

final appConfigProvider = Provider<AppConfig>((ref) {
  throw UnimplementedError('AppConfig not initialized');
});
