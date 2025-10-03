import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/app_exception.dart';
import '../datasources/api_client.dart';

/// Service to check app version compatibility with backend
class VersionCheckService {
  const VersionCheckService({required ApiClient client}) : _client = client;

  final ApiClient _client;

  /// Opening move: Check if app needs to be updated
  /// Returns true if app is outdated and needs update
  Future<VersionCheckResult> checkVersion() async {
    try {
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; // e.g., "1.2.3"

      if (kDebugMode) {
        debugPrint('📱 Current app version: $currentVersion');
      }

      // Main play: Call backend version endpoint
      final response = await _client.dio.get('/api/version');
      final data = response.data as Map<String, dynamic>;

      final backendVersion = data['backend_version'] as String;
      final minFrontendVersion = data['min_frontend_version'] as String;

      if (kDebugMode) {
        debugPrint('🔧 Backend version: $backendVersion');
        debugPrint('📋 Minimum frontend version: $minFrontendVersion');
      }

      // Victory lap: Compare versions
      final needsUpdate = _isVersionOutdated(currentVersion, minFrontendVersion);

      return VersionCheckResult(
        currentVersion: currentVersion,
        minRequiredVersion: minFrontendVersion,
        backendVersion: backendVersion,
        needsUpdate: needsUpdate,
      );
    } on DioException catch (error) {
      if (kDebugMode) {
        debugPrint('❌ Version check failed: ${error.message}');
      }
      // This looks odd, but it saves us from blocking the app on network errors
      // If version check fails, assume app is OK (don't block user)
      throw AppException(
        'Version check failed: ${error.message}',
        statusCode: error.response?.statusCode,
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('❌ Version check error: $error');
      }
      if (error is AppException) rethrow;
      throw AppException('Version check error: $error');
    }
  }

  /// Big play: Compare semantic versions (major.minor.patch)
  /// Returns true if current < required
  bool _isVersionOutdated(String current, String required) {
    try {
      final currentParts = current.split('.').map(int.parse).toList();
      final requiredParts = required.split('.').map(int.parse).toList();

      // Ensure we have at least 3 parts (major.minor.patch)
      while (currentParts.length < 3) {
        currentParts.add(0);
      }
      while (requiredParts.length < 3) {
        requiredParts.add(0);
      }

      // Compare major.minor.patch
      for (var i = 0; i < 3; i++) {
        if (currentParts[i] < requiredParts[i]) return true; // Outdated
        if (currentParts[i] > requiredParts[i]) return false; // Newer
      }

      return false; // Equal versions
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Version comparison error: $e');
      }
      // If we can't parse versions, assume app is OK
      return false;
    }
  }
}

/// Result of version check
class VersionCheckResult {
  const VersionCheckResult({
    required this.currentVersion,
    required this.minRequiredVersion,
    required this.backendVersion,
    required this.needsUpdate,
  });

  final String currentVersion;
  final String minRequiredVersion;
  final String backendVersion;
  final bool needsUpdate;

  @override
  String toString() {
    return 'VersionCheckResult('
        'current: $currentVersion, '
        'required: $minRequiredVersion, '
        'backend: $backendVersion, '
        'needsUpdate: $needsUpdate)';
  }
}
