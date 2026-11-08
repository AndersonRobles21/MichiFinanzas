import 'dart:async';

import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../services/app_settings_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../utils/user_messages.dart';
import '../widgets/cat_illustration.dart';
import 'debts/debts_screen.dart';
import 'expenses/expenses_screen.dart';
import 'future_expenses/future_expenses_screen.dart';
import 'home/home_screen.dart';
import 'onboarding/digital_accounts_setup_screen.dart';
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
  int _selectedIndex = 0;
  late Future<AppSettings> _settingsFuture;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _ownsDatabaseService = widget.databaseService == null;
    _databaseService = widget.databaseService ?? DatabaseService(AppDatabase());
    _settingsFuture = const AppSettingsService().load();
  }

  List<Widget> get _screens => [
    HomeScreen(
      databaseService: _databaseService,
      isActive: _selectedIndex == 0,
      onViewFutureExpenses: () => _selectDestination(3),
      onViewExpenses: () => _selectDestination(2),
      onViewIncomes: () => _selectDestination(1),
      onViewSubscriptions: () => _selectDestination(4),
      onViewDebts: () => _selectDestination(6),
      onViewSavings: () => _selectDestination(5),
      onViewSettings: () => _selectDestination(8),
    ),
    IncomesScreen(
      databaseService: _databaseService,
      isActive: _selectedIndex == 1,
    ),
    ExpensesScreen(
      databaseService: _databaseService,
      isActive: _selectedIndex == 2,
    ),
    FutureExpensesScreen(databaseService: _databaseService),
    SubscriptionsScreen(databaseService: _databaseService),
    SavingsScreen(
      databaseService: _databaseService,
      isActive: _selectedIndex == 5,
    ),
    DebtsScreen(
      databaseService: _databaseService,
      isActive: _selectedIndex == 6,
    ),
    StatisticsScreen(
      databaseService: _databaseService,
      isActive: _selectedIndex == 7,
    ),
    SettingsScreen(
      databaseService: _databaseService,
      isActive: _selectedIndex == 8,
      onUserNameChanged: (name) => setState(() {
        _userName = name;
        _settingsFuture = const AppSettingsService().load();
      }),
    ),
  ];

  void _selectDestination(int destination) {
    final isKnownDestination = _navigationGroups.any(
      (group) => group.destinations.any((item) => item.index == destination),
    );
    if (!isKnownDestination) {
      return;
    }
    _scaffoldKey.currentState?.closeDrawer();
    setState(() {
      _selectedIndex = destination;
    });
  }

  void _handleBackNavigation() {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      _scaffoldKey.currentState?.closeDrawer();
      return;
    }
    if (_selectedIndex != 0) _selectDestination(0);
  }

  @override
  void dispose() {
    if (_ownsDatabaseService) unawaited(_databaseService.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppSettings>(
      future: _settingsFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No pudimos cargar tus ajustes locales.'),
                  TextButton(
                    onPressed: () => setState(
                      () => _settingsFuture = const AppSettingsService().load(),
                    ),
                    child: const Text('Intentar de nuevo'),
                  ),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        _userName = snapshot.data!.userName;
        if (_userName.isEmpty) {
          return WelcomeScreen(
            onContinue: (name) => setState(() {
              _userName = name;
              _settingsFuture = Future.value(
                snapshot.data!.copyWith(userName: name),
              );
            }),
          );
        }
        if (!snapshot.data!.hasCompletedAccountSetup) {
          return DigitalAccountsSetupScreen(
            databaseService: _databaseService,
            onComplete: _completeAccountSetup,
          );
        }
        return PopScope(
          canPop: _selectedIndex == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _handleBackNavigation();
          },
          child: Scaffold(
            key: _scaffoldKey,
            body: IndexedStack(index: _selectedIndex, children: _screens),
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
              selectedIndex: _selectedIndex,
              userName: _userName,
              onSelected: _selectDestination,
            ),
          ),
        );
      },
    );
  }

  Future<void> _completeAccountSetup() async {
    final settings = await const AppSettingsService().load();
    final completedSettings = settings.copyWith(hasCompletedAccountSetup: true);
    await const AppSettingsService().save(completedSettings);
    if (!mounted) return;
    setState(() {
      _settingsFuture = Future.value(completedSettings);
    });
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.onContinue});

  final ValueChanged<String> onContinue;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    final name = AppSettingsService.normalizeUserName(_controller.text);
    try {
      final settings = await const AppSettingsService().load();
      await const AppSettingsService().saveUserName(settings, name);
      if (mounted) widget.onContinue(name);
    } catch (error, stackTrace) {
      logOperationFailure(error, stackTrace, operation: 'guardar el nombre');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No pudimos guardar tu nombre. Intenta de nuevo.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: AnimatedCat(
                        asset: CatAssets.icono,
                        label: 'Gato de MichiFinanzas',
                        width: 150,
                        height: 130,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '¡Hola! 🐱 Antes de empezar, pon tu nombre para que podamos organizar tu dinero juntos.',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      key: const ValueKey('welcome-user-name'),
                      controller: _controller,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Tu nombre',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (value) =>
                          AppSettingsService.isValidOnboardingUserName(
                            value ?? '',
                          )
                          ? null
                          : 'Usa solo letras y espacios; no dejes el campo vacío.',
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _saving ? null : _continue,
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Continuar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationDrawer extends StatelessWidget {
  const _NavigationDrawer({
    required this.selectedIndex,
    required this.userName,
    required this.onSelected,
  });

  final int selectedIndex;
  final String userName;
  final ValueChanged<int> onSelected;

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
                          userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                children: [
                  for (
                    var groupIndex = 0;
                    groupIndex < _navigationGroups.length;
                    groupIndex++
                  ) ...[
                    if (groupIndex > 0) ...[
                      const SizedBox(height: 8),
                      const Divider(height: 1, indent: 12, endIndent: 12),
                      const SizedBox(height: 6),
                    ],
                    _NavigationGroupLabel(
                      title: _navigationGroups[groupIndex].title,
                    ),
                    for (final destination
                        in _navigationGroups[groupIndex].destinations)
                      _NavigationTile(
                        destination: destination,
                        selected: selectedIndex == destination.index,
                        onTap: () => onSelected(destination.index),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationTile extends StatelessWidget {
  const _NavigationTile({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _NavigationDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        key: ValueKey('navigation-${destination.label}'),
        selected: selected,
        selectedTileColor: AppColors.primary.withValues(alpha: 0.16),
        selectedColor: AppColors.accent,
        leading: Icon(
          destination.icon,
          color: selected ? AppColors.accent : AppColors.textSecondary,
        ),
        title: Text(
          destination.label,
          style: theme.textTheme.titleSmall?.copyWith(
            color: selected ? AppColors.textPrimary : null,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        trailing: selected
            ? const Icon(Icons.chevron_right_rounded, color: AppColors.accent)
            : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.small),
          side: selected
              ? BorderSide(color: AppColors.primary.withValues(alpha: 0.55))
              : BorderSide.none,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _NavigationGroupLabel extends StatelessWidget {
  const _NavigationGroupLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.accent,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NavigationDestination {
  const _NavigationDestination(this.index, this.label, this.icon);

  final int index;
  final String label;
  final IconData icon;
}

class _NavigationGroup {
  const _NavigationGroup(this.title, this.destinations);

  final String title;
  final List<_NavigationDestination> destinations;
}

const _navigationGroups = <_NavigationGroup>[
  _NavigationGroup('RESUMEN', [
    _NavigationDestination(0, 'Inicio', Icons.home_outlined),
  ]),
  _NavigationGroup('MI DINERO', [
    _NavigationDestination(1, 'Ingresos', Icons.south_west_rounded),
    _NavigationDestination(2, 'Gastos', Icons.receipt_long_outlined),
  ]),
  _NavigationGroup('ORGANIZACIÓN', [
    _NavigationDestination(3, 'Gastos futuros', Icons.event_note_outlined),
    _NavigationDestination(4, 'Suscripciones', Icons.autorenew_rounded),
  ]),
  _NavigationGroup('MIS OBJETIVOS', [
    _NavigationDestination(5, 'Ahorros', Icons.savings_outlined),
    _NavigationDestination(
      6,
      'Deudas y préstamos',
      Icons.account_balance_outlined,
    ),
  ]),
  _NavigationGroup('ANÁLISIS', [
    _NavigationDestination(7, 'Estadísticas', Icons.insights_outlined),
  ]),
  _NavigationGroup('PREFERENCIAS', [
    _NavigationDestination(8, 'Configuración', Icons.tune_outlined),
  ]),
];
