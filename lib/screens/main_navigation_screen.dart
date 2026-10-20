import 'dart:async';

import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cat_illustration.dart';
import 'debts/debts_screen.dart';
import 'expenses/expenses_screen.dart';
import 'future_expenses/future_expenses_screen.dart';
import 'home/home_screen.dart';
import 'savings/savings_screen.dart';
import 'settings/settings_screen.dart';
import 'statistics/statistics_screen.dart';
import 'subscriptions/subscriptions_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key, this.databaseService});

  final DatabaseService? databaseService;

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final DatabaseService _databaseService;
  late final bool _ownsDatabaseService;
  int _selectedPage = 0;
  int _selectedDestination = 0;

  @override
  void initState() {
    super.initState();
    _ownsDatabaseService = widget.databaseService == null;
    _databaseService = widget.databaseService ?? DatabaseService(AppDatabase());
  }

  List<Widget> get _screens => [
    HomeScreen(
      databaseService: _databaseService,
      isActive: _selectedPage == 0,
      focusIncomes: _selectedDestination == 1,
      onViewFutureExpenses: () => _selectDestination(5),
    ),
    ExpensesScreen(
      databaseService: _databaseService,
      isActive: _selectedPage == 1,
    ),
    FutureExpensesScreen(databaseService: _databaseService),
    StatisticsScreen(
      databaseService: _databaseService,
      isActive: _selectedPage == 3,
    ),
    SavingsScreen(
      databaseService: _databaseService,
      isActive: _selectedPage == 4,
    ),
    DebtsScreen(
      databaseService: _databaseService,
      isActive: _selectedPage == 5,
    ),
    SettingsScreen(
      databaseService: _databaseService,
      isActive: _selectedPage == 6,
    ),
    SubscriptionsScreen(databaseService: _databaseService),
  ];

  void _selectDestination(int destination) {
    final page = switch (destination) {
      0 || 1 => 0,
      2 => 1,
      3 => 5,
      4 => 4,
      5 => 2,
      6 => 3,
      7 => 6,
      8 => 7,
      _ => 0,
    };
    _scaffoldKey.currentState?.closeDrawer();
    setState(() {
      _selectedDestination = destination;
      _selectedPage = page;
    });
  }

  @override
  void dispose() {
    if (_ownsDatabaseService) unawaited(_databaseService.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: IndexedStack(index: _selectedPage, children: _screens),
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Abrir menú',
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          icon: const Icon(Icons.menu_rounded),
        ),
      ),
      drawer: _NavigationDrawer(
        selectedIndex: _selectedDestination,
        onSelected: _selectDestination,
      ),
    );
  }
}

class _NavigationDrawer extends StatelessWidget {
  const _NavigationDrawer({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _destinations = [
    (label: 'Inicio', icon: Icons.home_outlined),
    (label: 'Ingresos', icon: Icons.south_west_rounded),
    (label: 'Gastos', icon: Icons.receipt_long_outlined),
    (label: 'Deudas', icon: Icons.account_balance_outlined),
    (label: 'Ahorros', icon: Icons.savings_outlined),
    (label: 'Gastos futuros', icon: Icons.event_note_outlined),
    (label: 'Estadísticas', icon: Icons.insights_outlined),
    (label: 'Configuración', icon: Icons.tune_outlined),
    (label: 'Suscripciones', icon: Icons.autorenew_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Drawer(
      width: width < 380 ? width * 0.88 : 320,
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 22, 16, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.surfaceRaised, AppColors.surface],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      CatAssets.icono,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      semanticLabel: 'Gato de MichiFinanzas',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MichiFinanzas',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Tu dinero, más organizado',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: _destinations.length,
                itemBuilder: (context, index) {
                  final destination = _destinations[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: ListTile(
                      key: ValueKey('navigation-${destination.label}'),
                      selected: selectedIndex == index,
                      selectedTileColor: AppColors.primary.withValues(
                        alpha: 0.14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      leading: Icon(destination.icon),
                      title: Text(destination.label),
                      onTap: () => onSelected(index),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
