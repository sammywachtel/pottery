import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'version_check_provider.dart';

/// Opening move: Wraps a widget and checks version on mount
/// Shows update dialog if app is outdated
class VersionGuard extends ConsumerStatefulWidget {
  const VersionGuard({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<VersionGuard> createState() => _VersionGuardState();
}

class _VersionGuardState extends ConsumerState<VersionGuard> {
  bool _hasShownDialog = false;

  @override
  Widget build(BuildContext context) {
    final versionCheckAsync = ref.watch(versionCheckProvider);

    // Big play: Show dialog once when version check completes
    versionCheckAsync.whenData((result) {
      if (result != null && result.needsUpdate && !_hasShownDialog) {
        _hasShownDialog = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showUpdateDialog(context, result);
        });
      }
    });

    return widget.child;
  }

  /// Victory lap: Show update required dialog
  void _showUpdateDialog(BuildContext context, result) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap button
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.update, color: Colors.orange),
            SizedBox(width: 12),
            Text('Update Required'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A new version of Pottery Studio is available.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'Your version: ${result.currentVersion}\n'
              'Required version: ${result.minRequiredVersion}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please update to the latest version to continue using the app. '
              'The backend has been updated and your current version may not work correctly.',
            ),
          ],
        ),
        actions: [
          FilledButton.icon(
            onPressed: () => _openPlayStore(context),
            icon: const Icon(Icons.shop),
            label: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  /// Here's where we send users to Play Store
  /// May not work for sideloaded apps, but will work for Play Store installs
  Future<void> _openPlayStore(BuildContext context) async {
    const packageName = 'com.pottery.app'; // Production package
    final uri = Uri.parse('market://details?id=$packageName');
    final fallbackUri = Uri.parse(
      'https://play.google.com/store/apps/details?id=$packageName',
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fall back to browser if Play Store not available
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open Play Store: $e'),
            action: SnackBarAction(
              label: 'Copy Link',
              onPressed: () {
                // User can manually paste the link
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Play Store link: $packageName'),
                  ),
                );
              },
            ),
          ),
        );
      }
    }
  }
}
