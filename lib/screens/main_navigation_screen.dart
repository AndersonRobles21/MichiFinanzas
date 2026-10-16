import 'dart:async';

import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../services/database_service.dart';
import 'debts/debts_screen.dart';
import 'expenses/expenses_screen.dart';
import 'future_expenses/future_expenses_screen.dart';
import 'home/home_screen.dart';
import 'savings/savings_screen.dart';
import 'settings/settings_screen.dart';
import 'statistics/statistics_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key, this.databaseService});

  final DatabaseService? databaseService;

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late final DatabaseService _databaseService;
  late final bool _ownsDatabaseService;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _ownsDatabaseService = widget.databaseService == null;
    _databaseService = widget.databaseService ?? DatabaseService(AppDatabase());
  }

  List<Widget> get _screens => [
    HomeScreen(
      databaseService: _databaseService,
      isActive: _selectedIndex == 0,
      onViewFutureExpenses: () => setState(() => _selectedIndex = 2),
    ),
    ExpensesScreen(
      databaseService: _databaseService,
      isActive: _selectedIndex == 1,
    ),
    FutureExpensesScreen(databaseService: _databaseService),
    StatisticsScreen(
      databaseService: _databaseService,
      isActive: _selectedIndex == 3,
    ),
    SavingsScreen(
      databaseService: _databaseService,
      isActive: _selectedIndex == 4,
    ),
    DebtsScreen(
      databaseService: _databaseService,
      isActive: _selectedIndex == 5,
    ),
    SettingsScreen(
      databaseService: _databaseService,
      isActive: _selectedIndex == 6,
    ),
  ];

  @override
  void dispose() {
    if (_ownsDatabaseService) unawaited(_databaseService.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            label: 'Inicio',
            tooltip: 'Inicio',
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
          ),
          NavigationDestination(
            label: 'Gastos',
            tooltip: 'Gastos',
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
          ),
          NavigationDestination(
            label: 'Futuros',
            tooltip: 'Gastos futuros',
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note_rounded),
          ),
          NavigationDestination(
            label: 'Estadísticas',
            tooltip: 'Estadísticas',
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
          ),
          NavigationDestination(
            label: 'Ahorros',
            tooltip: 'Ahorros',
            icon: Icon(Icons.savings_outlined),
            selectedIcon: Icon(Icons.savings_rounded),
          ),
          NavigationDestination(
            label: 'Deudas',
            tooltip: 'Deudas',
            icon: Icon(Icons.account_balance_outlined),
            selectedIcon: Icon(Icons.account_balance_rounded),
          ),
          NavigationDestination(
            label: 'Ajustes',
            tooltip: 'Ajustes',
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune_rounded),
          ),
        ],
      ),
    );
  }
}
