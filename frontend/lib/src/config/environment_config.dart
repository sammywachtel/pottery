/// Environment configuration system for multi-environment deployment
/// Supports both build-time and runtime environment switching

enum Environment {
  development('development'),
  production('production');

  const Environment(this.name);
  final String name;

  static Environment fromString(String env) {
    switch (env.toLowerCase()) {
      case 'development':
      case 'dev':
        return Environment.development;
      case 'production':
      case 'prod':
        return Environment.production;
      default:
        return Environment.development; // Safe default
    }
  }
}

/// Central environment configuration
/// Determines current environment from build-time flags
class EnvironmentConfig {
  static Environment get current {
    // Check build-time environment flag
    const envString = String.fromEnvironment(
      'ENVIRONMENT',
      defaultValue: 'development',
    );
    return Environment.fromString(envString);
  }

  /// API base URL with override support
  static String get apiBaseUrl {
    // Check for explicit override first
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;

    // Environment-based defaults
    switch (current) {
      case Environment.development:
        return 'http://localhost:8000';
      case Environment.production:
        return 'https://pottery-api-prod.run.app';
    }
  }

  /// Storage bucket URL for direct access (if needed)
  static String get storageBucketUrl {
    const override = String.fromEnvironment('STORAGE_BUCKET_URL');
    if (override.isNotEmpty) return override;

    switch (current) {
      case Environment.development:
        return 'https://storage.googleapis.com/pottery-app-dev-456522-1759003953';
      case Environment.production:
        return 'https://storage.googleapis.com/pottery-app-prod-bucket';
    }
  }

  /// Debug logging enabled
  static bool get debugEnabled {
    const override = String.fromEnvironment('DEBUG_ENABLED');
    if (override.isNotEmpty) return override.toLowerCase() == 'true';

    return current == Environment.development;
  }

  /// Environment display name for UI
  static String get displayName {
    switch (current) {
      case Environment.development:
        return 'Development';
      case Environment.production:
        return 'Production';
    }
  }

  /// Environment color for debug UI
  static String get environmentColor {
    switch (current) {
      case Environment.development:
        return '#4CAF50'; // Green
      case Environment.production:
        return '#F44336'; // Red
    }
  }

  /// Check if running in development
  static bool get isDevelopment => current == Environment.development;

  /// Check if running in production
  static bool get isProduction => current == Environment.production;

  /// Get environment-specific configuration summary
  static Map<String, dynamic> get summary => {
    'environment': current.name,
    'displayName': displayName,
    'apiBaseUrl': apiBaseUrl,
    'storageBucketUrl': storageBucketUrl,
    'debugEnabled': debugEnabled,
    'isDevelopment': isDevelopment,
    'isProduction': isProduction,
  };
}
