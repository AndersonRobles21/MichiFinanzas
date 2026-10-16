import 'package:flutter/material.dart';

import 'services/database_service.dart';
import 'screens/main_navigation_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const FinanzasApp());
}

class FinanzasApp extends StatelessWidget {
  const FinanzasApp({super.key, this.databaseService});

  final DatabaseService? databaseService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Michi Finanzas',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: MainNavigationScreen(databaseService: databaseService),
    );
  }
}
