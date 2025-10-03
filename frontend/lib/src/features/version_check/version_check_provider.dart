import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/api_client_provider.dart';
import '../../data/services/version_check_service.dart';

/// Opening move: Provide version check service to the app
final versionCheckServiceProvider = Provider<VersionCheckService>((ref) {
  final client = ref.watch(apiClientProvider);
  return VersionCheckService(client: client);
});

/// Main play: Provider that performs version check
/// Returns null if check hasn't run yet, otherwise returns result
final versionCheckProvider = FutureProvider<VersionCheckResult?>((ref) async {
  final service = ref.watch(versionCheckServiceProvider);
  try {
    return await service.checkVersion();
  } catch (e) {
    // If version check fails, return null (don't block app)
    return null;
  }
});
