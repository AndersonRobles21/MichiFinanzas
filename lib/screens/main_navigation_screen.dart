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
      isActive: _selectedPage == 0,
      onViewFutureExpenses: () => _selectDestination(4),
      onViewExpenses: () => _selectDestination(2),
      onViewIncomes: () => _selectDestination(1),
      onViewSubscriptions: () => _selectDestination(5),
      onViewSettings: () => _selectDestination(8),
    ),
    IncomesScreen(
      databaseService: _databaseService,
      isActive: _selectedPage == 1,
    ),
    ExpensesScreen(
      databaseService: _databaseService,
      isActive: _selectedPage == 2,
    ),
    DebtsScreen(
      databaseService: _databaseService,
      isActive: _selectedPage == 3,
    ),
    FutureExpensesScreen(databaseService: _databaseService),
    SubscriptionsScreen(databaseService: _databaseService),
    SavingsScreen(
      databaseService: _databaseService,
      isActive: _selectedPage == 6,
    ),
    StatisticsScreen(
      databaseService: _databaseService,
      isActive: _selectedPage == 7,
    ),
    SettingsScreen(
      databaseService: _databaseService,
      isActive: _selectedPage == 8,
      onUserNameChanged: (name) => setState(() {
        _userName = name;
        _settingsFuture = const AppSettingsService().load();
      }),
    ),
  ];

  void _selectDestination(int destination) {
    final page = destination.clamp(0, _screens.length - 1).toInt();
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
            userName: _userName,
            onSelected: _selectDestination,
          ),
        );
      },
    );
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
                          AppSettingsService.isValidUserName(value ?? '')
                          ? null
                          : 'Usa letras, espacios y guiones; no dejes el campo vacío.',
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

  static const _destinations = [
    (label: 'Inicio', icon: Icons.home_outlined),
    (label: 'Ingresos', icon: Icons.south_west_rounded),
    (label: 'Gastos', icon: Icons.receipt_long_outlined),
    (label: 'Deudas y préstamos', icon: Icons.account_balance_outlined),
    (label: 'Gastos futuros', icon: Icons.event_note_outlined),
    (label: 'Suscripciones', icon: Icons.autorenew_rounded),
    (label: 'Ahorros', icon: Icons.savings_outlined),
    (label: 'Estadísticas', icon: Icons.insights_outlined),
    (label: 'Configuración', icon: Icons.tune_outlined),
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
                        const SizedBox(height: 3),
                        Text(
                          userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
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
                  final isSettings = destination.label == 'Configuración';
                  return Padding(
                    padding: EdgeInsets.only(
                      top: isSettings ? 12 : 2,
                      bottom: 2,
                    ),
                    child: ListTile(
                      key: ValueKey('navigation-${destination.label}'),
                      selected: selectedIndex == index,
                      selectedTileColor: AppColors.primary.withValues(
                        alpha: 0.14,
                      ),
                      leading: Icon(destination.icon),
                      title: Text(destination.label),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: isSettings
                            ? const BorderSide(color: AppColors.outline)
                            : BorderSide.none,
                      ),
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
