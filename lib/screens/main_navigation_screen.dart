import 'dart:async';

import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../services/app_settings_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../utils/user_messages.dart';
import '../widgets/cat_illustration.dart';
import '../widgets/transfer_money_dialog.dart';
import 'debts/debts_screen.dart';
import 'credits/credits_screen.dart';
import 'future_expenses/future_expenses_screen.dart';
import 'home/home_screen.dart';
import 'navigation_hubs.dart';
import 'onboarding/digital_accounts_setup_screen.dart';
import 'savings/savings_screen.dart';
import 'settings/settings_screen.dart';
import 'statistics/statistics_screen.dart';
import 'subscriptions/subscriptions_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({
    super.key,
    this.databaseService,
    this.onThemeModeChanged,
  });

  final DatabaseService? databaseService;
  final ValueChanged<ThemeMode>? onThemeModeChanged;

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late final DatabaseService _databaseService;
  late final bool _ownsDatabaseService;
  int _selectedIndex = 0;
  int _movementTab = 0;
  int _expenseRegisterRequestId = 0;
  int _incomeRegisterRequestId = 0;
  int? _creditDebtEntityId;
  bool _isTransferring = false;
  bool _isEditingWelcomeStep = false;
  late Future<AppSettings> _settingsFuture;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _ownsDatabaseService = widget.databaseService == null;
    _databaseService = widget.databaseService ?? DatabaseService(AppDatabase());
    _settingsFuture = _loadSettings();
  }

  Future<AppSettings> _loadSettings() async {
    final settings = await const AppSettingsService().load();
    widget.onThemeModeChanged?.call(
      settings.themeMode == 'dark' ? ThemeMode.dark : ThemeMode.light,
    );
    return settings;
  }

  List<Widget> get _screens => [
    HomeScreen(
      databaseService: _databaseService,
      isActive: _selectedIndex == 0,
      onViewStatistics: () => _selectDestination(8),
      onViewCommitments: () => _selectDestination(2),
      onViewFutureExpenses: () => _selectDestination(3),
      onViewExpenses: () => _openMovements(0),
      onViewIncomes: () => _openMovements(1),
      onRegisterExpense: () => _openMovements(0, register: true),
      onViewSubscriptions: () => _selectDestination(4),
      onViewDebts: () => _selectDestination(6),
      onViewSavings: () => _selectDestination(5),
      onViewAccounts: () => _selectDestination(11),
      onTransferMoney: _transferMoney,
    ),
    MovementsScreen(
      databaseService: _databaseService,
      initialTab: _movementTab,
      expenseRegisterRequestId: _expenseRegisterRequestId,
      incomeRegisterRequestId: _incomeRegisterRequestId,
    ),
    CommitmentsHubScreen(
      databaseService: _databaseService,
      onSubscriptions: () => _selectDestination(4),
      onFutureExpenses: () => _selectDestination(3),
      onDebts: () => _selectDestination(6),
      onCredits: () => _selectDestination(7),
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
      creditEntityId: _creditDebtEntityId,
    ),
    CreditsScreen(
      databaseService: _databaseService,
      onViewDebts: _viewCreditDebts,
    ),
    StatisticsScreen(
      databaseService: _databaseService,
      isActive: _selectedIndex == 8,
    ),
    SettingsScreen(
      databaseService: _databaseService,
      isActive: _selectedIndex == 9,
      onThemeModeChanged: widget.onThemeModeChanged,
      onUserNameChanged: (name) => setState(() {
        _userName = name;
        _settingsFuture = const AppSettingsService().load();
      }),
    ),
    MoreHubScreen(
      databaseService: _databaseService,
      onAccounts: () => _selectDestination(11),
      onStatistics: () => _selectDestination(8),
      onSavings: () => _selectDestination(5),
      onSettings: () => _selectDestination(9),
    ),
    AccountsScreen(
      databaseService: _databaseService,
      onTransfer: _transferMoney,
      onSettings: () => _selectDestination(9),
    ),
  ];

  void _selectDestination(int destination) {
    if (destination < 0 || destination > 11) return;
    setState(() {
      _selectedIndex = destination;
      if (destination == 6) _creditDebtEntityId = null;
    });
  }

  void _openMovements(int tab, {bool register = false}) {
    setState(() {
      _movementTab = tab;
      _selectedIndex = 1;
      if (register && tab == 0) _expenseRegisterRequestId++;
      if (register && tab == 1) _incomeRegisterRequestId++;
    });
  }

  void _viewCreditDebts(int entityId) {
    setState(() {
      _creditDebtEntityId = entityId;
      _selectedIndex = 6;
    });
  }

  void _selectBottomDestination(int destination) {
    switch (destination) {
      case 0:
        _selectDestination(0);
        break;
      case 1:
        _selectDestination(1);
        break;
      case 2:
        _showRegisterSheet();
        break;
      case 3:
        _selectDestination(2);
        break;
      case 4:
        _selectDestination(10);
        break;
    }
  }

  Future<void> _showRegisterSheet() async {
    final action = await showModalBottomSheet<_RegisterAction>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Qué quieres registrar?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _RegisterActionTile(
                icon: Icons.south_west_rounded,
                title: 'Ingreso',
                subtitle: 'Sueldo, dinero extra o préstamo recibido',
                color: AppColors.positive,
                onTap: () => Navigator.pop(context, _RegisterAction.income),
              ),
              _RegisterActionTile(
                icon: Icons.receipt_long_outlined,
                title: 'Gasto',
                subtitle: 'Compras, servicios y pagos del día',
                color: AppColors.negative,
                onTap: () => Navigator.pop(context, _RegisterAction.expense),
              ),
              _RegisterActionTile(
                icon: Icons.swap_horiz_rounded,
                title: 'Transferencia',
                subtitle:
                    'Mover dinero entre efectivo y cuentas; no es ingreso ni gasto',
                color: AppColors.primary,
                onTap: () => Navigator.pop(context, _RegisterAction.transfer),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case _RegisterAction.income:
        _openMovements(1, register: true);
        break;
      case _RegisterAction.expense:
        _openMovements(0, register: true);
        break;
      case _RegisterAction.transfer:
        await _transferMoney();
        break;
    }
  }

  Future<void> _transferMoney() async {
    if (_isTransferring) return;
    setState(() => _isTransferring = true);
    try {
      final values = await Future.wait<Object>([
        _databaseService.obtenerCuentasDigitales(),
        _databaseService.obtenerSaldosPorMedio(),
      ]);
      if (!mounted) return;
      final draft = await showDialog<TransferMoneyDraft>(
        context: context,
        builder: (context) => TransferMoneyDialog(
          accounts: values[0] as List<DigitalAccountBalance>,
          balances: values[1] as AvailableBalanceBreakdown,
        ),
      );
      if (draft == null || !mounted) return;
      await _databaseService.transferirDinero(
        medioOrigen: draft.origin.medium,
        cuentaOrigenId: draft.origin.accountId,
        medioDestino: draft.destination.medium,
        cuentaDestinoId: draft.destination.accountId,
        monto: draft.amount,
        fecha: draft.date,
        nota: draft.note,
      );
      if (mounted) {
        showCatMessage(
          context,
          'Transferencia lista. Tus saldos ya están actualizados.',
          isSuccess: true,
        );
      }
    } catch (error, stackTrace) {
      logOperationFailure(
        error,
        stackTrace,
        operation: 'transferir dinero desde el acceso rápido',
      );
      if (mounted) {
        showCatMessage(
          context,
          friendlyOperationError(error, action: 'guardar la transferencia'),
        );
      }
    } finally {
      if (mounted) setState(() => _isTransferring = false);
    }
  }

  void _handleBackNavigation() {
    final destination = switch (_selectedIndex) {
      3 || 4 || 6 || 7 => 2,
      5 || 8 || 9 || 11 => 10,
      _ => 0,
    };
    if (_selectedIndex != destination) _selectDestination(destination);
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
                      () => _settingsFuture = _loadSettings(),
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
        if (_userName.isEmpty || _isEditingWelcomeStep) {
          return WelcomeScreen(
            initialName: _userName,
            onContinue: (name) => setState(() {
              _userName = name;
              _isEditingWelcomeStep = false;
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
            onBack: () => setState(() => _isEditingWelcomeStep = true),
          );
        }
        return PopScope(
          canPop: _selectedIndex == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _handleBackNavigation();
          },
          child: Scaffold(
            body: IndexedStack(index: _selectedIndex, children: _screens),
            bottomNavigationBar: _AppBottomNavigationBar(
              selectedIndex: _bottomNavigationIndex,
              onSelected: _selectBottomDestination,
            ),
          ),
        );
      },
    );
  }

  int get _bottomNavigationIndex {
    if (_selectedIndex == 0) return 0;
    if (_selectedIndex == 1) return 1;
    if (_selectedIndex == 2 ||
        _selectedIndex == 3 ||
        _selectedIndex == 4 ||
        _selectedIndex == 6 ||
        _selectedIndex == 7) {
      return 3;
    }
    return 4;
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
  const WelcomeScreen({
    super.key,
    required this.onContinue,
    this.initialName = '',
  });

  final ValueChanged<String> onContinue;
  final String initialName;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialName;
  }

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
        child: LayoutBuilder(
          builder: (context, constraints) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 393),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        Form(
                          key: _formKey,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'MichiFinanzas',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: AppColors.primary,
                                          ),
                                    ),
                                    const Spacer(),
                                    const _OnboardingStep(
                                      label: 'Paso 1 de 2',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  height: 240,
                                  width: double.infinity,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 210,
                                        height: 210,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFFBE3C6),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const Positioned(
                                        left: 16,
                                        top: 43,
                                        child: _OnboardingDecoration(
                                          size: 30,
                                          color: Color(0xFFF2994A),
                                        ),
                                      ),
                                      const Positioned(
                                        right: 18,
                                        top: 34,
                                        child: _OnboardingDecoration(
                                          size: 16,
                                          color: Color(0xFFF6C744),
                                        ),
                                      ),
                                      const Positioned(
                                        right: 12,
                                        bottom: 42,
                                        child: _OnboardingDecoration(
                                          size: 22,
                                          color: Color(0xFFB48AD8),
                                          outlined: true,
                                        ),
                                      ),
                                      Image.asset(
                                        CatAssets.icono,
                                        width: 148,
                                        height: 132,
                                        fit: BoxFit.contain,
                                        semanticLabel:
                                            'Gato de MichiFinanzas',
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '¡Hola! Antes de empezar, pon tu nombre para que podamos organizar tu dinero juntos.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontSize: 25, height: 1.2),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  key: const ValueKey('welcome-user-name'),
                                  controller: _controller,
                                  textCapitalization:
                                      TextCapitalization.words,
                                  decoration: const InputDecoration(
                                    labelText: 'Tu nombre',
                                  ),
                                  validator: (value) => AppSettingsService
                                          .isValidOnboardingUserName(
                                            value ?? '',
                                          )
                                      ? null
                                      : 'Usa solo letras y espacios; no dejes el campo vacío.',
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Solo letras y espacios. Se guarda únicamente en este celular.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            border: Border(
                              top: BorderSide(
                                color: AppColors.outline.withValues(
                                  alpha: 0.24,
                                ),
                              ),
                            ),
                          ),
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
        ),
      ),
    );
  }
}

class _OnboardingStep extends StatelessWidget {
  const _OnboardingStep({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        child: Text(label, style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }
}

class _OnboardingDecoration extends StatelessWidget {
  const _OnboardingDecoration({
    required this.size,
    required this.color,
    this.outlined = false,
  });

  final double size;
  final Color color;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color,
        shape: BoxShape.circle,
        border: outlined ? Border.all(color: color, width: 4) : null,
      ),
    );
  }
}

enum _RegisterAction { income, expense, transfer }

class _RegisterActionTile extends StatelessWidget {
  const _RegisterActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 76),
            padding: const EdgeInsets.all(14),
            decoration: AppCardDecorations.surfaceWithBorder(),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(icon, color: color),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleMedium),
                      Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppBottomNavigationBar extends StatelessWidget {
  const _AppBottomNavigationBar({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final destinations = [
      (label: 'Inicio', icon: Icons.home_outlined),
      (label: 'Movimientos', icon: Icons.swap_vert_rounded),
      (label: 'Registrar', icon: Icons.add_rounded),
      (label: 'Compromisos', icon: Icons.event_note_outlined),
      (label: 'Más', icon: Icons.grid_view_rounded),
    ];

    return Material(
      color: theme.colorScheme.surface,
      elevation: 0,
      child: SafeArea(
        top: false,
        child: Container(
          height: 84,
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 18),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(color: AppColors.outline.withValues(alpha: 0.28)),
            ),
          ),
          child: Row(
            children: [
              for (var index = 0; index < destinations.length; index++)
                Expanded(
                  child: _BottomNavigationItem(
                    label: destinations[index].label,
                    icon: destinations[index].icon,
                    selected: selectedIndex == index,
                    isAction: index == 2,
                    key: ValueKey(
                      'bottom-navigation-${destinations[index].label}',
                    ),
                    onTap: () => onSelected(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavigationItem extends StatelessWidget {
  const _BottomNavigationItem({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.isAction,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool isAction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isAction)
                SizedBox(
                  width: 54,
                  height: 32,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        top: -22,
                        left: 0,
                        right: 0,
                        height: 54,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primaryAction,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.surface,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.28,
                                ),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Icon(
                            icon,
                            color: AppColors.actionForeground,
                            size: 26,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Icon(icon, color: color, size: 22),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isAction ? AppColors.primary : color,
                  fontSize: 12,
                  fontWeight: selected || isAction
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ],
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
              decoration: BoxDecoration(
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
            ? Icon(Icons.chevron_right_rounded, color: AppColors.accent)
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
    _NavigationDestination(8, 'Estadísticas', Icons.insights_outlined),
  ]),
  _NavigationGroup('CRÉDITOS', [
    _NavigationDestination(7, 'Créditos', Icons.credit_card_outlined),
  ]),
  _NavigationGroup('PREFERENCIAS', [
    _NavigationDestination(9, 'Configuración', Icons.tune_outlined),
  ]),
];
