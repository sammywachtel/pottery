import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'design_system/pottery_theme.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/views/login_view.dart';
import 'features/items/views/items_home_page.dart';
import 'features/version_check/version_guard.dart';
import 'widgets/splash_screen.dart';

class PotteryApp extends ConsumerWidget {
  const PotteryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    final theme = PotteryTheme.light();

    Widget home;
    if (authState.isInitializing) {
      home = const SplashScreen();
    } else if (!authState.isAuthenticated) {
      home = const LoginView();
    } else {
      // Big play: Wrap home page with version check guard
      // This checks backend version on app startup and shows update dialog if needed
      home = const VersionGuard(child: ItemsHomePage());
    }

    return MaterialApp(
      title: 'Pottery Studio Catalog',
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: PotteryTheme.dark(),
      themeMode: ThemeMode.system,
      home: home,
    );
  }
}
