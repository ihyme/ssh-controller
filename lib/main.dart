import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'core/constants/app_colors.dart';
import 'providers/auth_provider.dart';
import 'providers/category_provider.dart';
import 'providers/server_provider.dart';
import 'providers/snippet_provider.dart';
import 'providers/terminal_provider.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/lock_screen.dart';
import 'ui/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Desktop Window Management Configuration
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    try {
      await windowManager.ensureInitialized();

      const windowOptions = WindowOptions(
        size: Size(1280, 820),
        minimumSize: Size(940, 640),
        center: true,
        backgroundColor: AppColors.darkBg,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.hidden,
        title: 'RoPi SSH Manager',
      );

      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    } catch (e) {
      debugPrint('WindowManager init warning: $e');
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => ServerProvider()),
        ChangeNotifierProvider(create: (_) => TerminalProvider()),
        ChangeNotifierProvider(create: (_) => SnippetProvider()),
      ],
      child: const SshManagerApp(),
    ),
  );
}

class SshManagerApp extends StatelessWidget {
  const SshManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoPi SSH Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AppRootView(),
    );
  }
}

class AppRootView extends StatelessWidget {
  const AppRootView({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.darkBg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                'Şifreli Veritabanı Yükleniyor...',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (!authProvider.isUnlocked) {
      return const LockScreen();
    }

    return const HomeScreen();
  }
}
