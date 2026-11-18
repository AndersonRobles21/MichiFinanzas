import 'package:flutter/material.dart';

import 'services/app_settings_service.dart';
import 'services/database_service.dart';
import 'screens/main_navigation_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const FinanzasApp());
}

class FinanzasApp extends StatefulWidget {
  const FinanzasApp({super.key, this.databaseService});

  final DatabaseService? databaseService;

  @override
  State<FinanzasApp> createState() => _FinanzasAppState();
}

class _FinanzasAppState extends State<FinanzasApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Michi Finanzas',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      builder: (context, child) {
        AppColors.setBrightness(Theme.of(context).brightness);
        return child!;
      },
      home: MainNavigationScreen(
        databaseService: widget.databaseService,
        onThemeModeChanged: (mode) {
          if (_themeMode != mode) setState(() => _themeMode = mode);
        },
      ),
    );
  }
}
