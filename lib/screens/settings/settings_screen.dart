import 'dart:async';

import 'package:flutter/material.dart';

import '../../database/app_database.dart';
import '../../models/money_medium.dart';
import '../../services/app_settings_service.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_format.dart';
import '../../utils/money_format.dart';
import '../../utils/user_messages.dart';
import '../../widgets/cat_illustration.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    this.isActive = true,
    this.databaseService,
    this.onUserNameChanged,
  });

  final bool isActive;
  final DatabaseService? databaseService;
  final ValueChanged<String>? onUserNameChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final DatabaseService _databaseService;
  late final bool _ownsDatabaseService;
  Future<_SettingsData>? _settingsFuture;
  _SettingsData? _loadedData;
  final _nameFormKey = GlobalKey<FormState>();
  final _userNameController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _ownsDatabaseService = widget.databaseService == null;
    _databaseService = widget.databaseService ?? DatabaseService(AppDatabase());
    if (widget.isActive) _settingsFuture = _loadSettings();
  }

  @override
  void didUpdateWidget(covariant SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _settingsFuture = _loadSettings();
    }
  }

  @override
  void dispose() {
    _userNameController.dispose();
    if (_ownsDatabaseService) unawaited(_databaseService.close());
    super.dispose();
  }

  Future<_SettingsData> _loadSettings() async {
    return runWithLoggedErrors('cargar ajustes y categorías', () async {
      final settings = await const AppSettingsService().load();
      _userNameController.text = settings.userName;
      final expenses = await _databaseService.obtenerGastos();
      final accounts = await _databaseService.obtenerCuentasDigitales();
      final transfers = await _databaseService.obtenerTransferencias();
      final usageCount = <String, int>{};
      for (final expense in expenses) {
        final category = AppSettingsService.normalizeCategory(
          expense.categoria,
        );
        usageCount.update(category, (count) => count + 1, ifAbsent: () => 1);
      }
      final categories = <String>{
        ...settings.expenseCategories,
        ...usageCount.keys,
      }.toList();
      final data = _SettingsData(
        settings: settings,
        categories: categories,
        categoryUsage: usageCount,
        accounts: accounts,
        transfers: transfers,
      );
      _loadedData = data;
      return data;
    });
  }

  Future<void> _saveUserName(AppSettings settings) async {
    if (!_nameFormKey.currentState!.validate() || _isSaving) return;
    final userName = AppSettingsService.normalizeUserName(
      _userNameController.text,
    );
    if (!AppSettingsService.isValidUserName(userName)) {
      _showMessage('Escribe un nombre usando solo letras españolas.');
      return;
    }
    await _saveSettings(
      settings.copyWith(userName: userName),
      '¡Listo, $userName! Guardamos tu nombre.',
      validateUserName: true,
    );
  }

  Future<void> _saveSettings(
    AppSettings settings,
    String message, {
    bool validateUserName = false,
  }) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      if (validateUserName) {
        await const AppSettingsService().saveUserName(
          settings,
          settings.userName,
        );
      } else {
        await const AppSettingsService().save(settings);
      }
      if (!mounted) return;
      final categoryUsage = _loadedData?.categoryUsage ?? const <String, int>{};
      final updatedData = _SettingsData(
        settings: settings,
        categories: {
          ...settings.expenseCategories,
          ...categoryUsage.keys,
        }.toList(),
        categoryUsage: categoryUsage,
        accounts: _loadedData?.accounts ?? const [],
        transfers: _loadedData?.transfers ?? const [],
      );
      setState(() {
        _loadedData = updatedData;
        _settingsFuture = Future.value(updatedData);
      });
      if (validateUserName) {
        widget.onUserNameChanged?.call(settings.userName);
      }
      _showMessage(message);
    } catch (error, stackTrace) {
      logOperationFailure(error, stackTrace, operation: 'guardar los ajustes');
      if (mounted) {
        _showMessage(
          friendlyOperationError(error, action: 'guardar los ajustes'),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _addCategory(AppSettings settings) async {
    final category = await showDialog<String>(
      context: context,
      builder: (context) => const _AddCategoryDialog(),
    );
    if (category == null || !mounted) return;
    final normalizedCategory = AppSettingsService.normalizeCategory(category);
    if (settings.expenseCategories.any(
      (existing) => existing.toLowerCase() == normalizedCategory.toLowerCase(),
    )) {
      _showMessage('Esa categoría ya está en tu lista.');
      return;
    }
    await _saveSettings(
      settings.copyWith(
        expenseCategories: [...settings.expenseCategories, normalizedCategory],
      ),
      'Categoría agregada. Ya puedes usarla.',
    );
  }

  Future<void> _editCategory(AppSettings settings, String category) async {
    final updatedName = await showDialog<String>(
      context: context,
      builder: (context) => _AddCategoryDialog(initialName: category),
    );
    if (updatedName == null || !mounted || _isSaving) return;
    final normalized = AppSettingsService.normalizeCategory(updatedName);
    if (settings.expenseCategories.any(
      (existing) =>
          existing.toLowerCase() == normalized.toLowerCase() &&
          existing != category,
    )) {
      _showMessage('Ya tienes una categoría con ese nombre.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      await _databaseService.renombrarCategoriaGastos(
        nombreAnterior: category,
        nombreNuevo: normalized,
      );
      final categories = settings.expenseCategories.toList();
      final index = categories.indexOf(category);
      if (index < 0) {
        categories.add(normalized);
      } else {
        categories[index] = normalized;
      }
      final updatedSettings = settings.copyWith(expenseCategories: categories);
      await const AppSettingsService().save(updatedSettings);
      if (!mounted) return;
      await _loadSettings();
      if (mounted) {
        setState(() => _settingsFuture = Future.value(_loadedData));
        _showMessage('Categoría actualizada.');
      }
    } catch (error, stackTrace) {
      logOperationFailure(error, stackTrace, operation: 'editar una categoría');
      if (mounted) {
        _showMessage(
          friendlyOperationError(error, action: 'editar la categoría'),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _removeCategory(
    AppSettings settings,
    String category,
    int usageCount,
  ) async {
    if (category.toLowerCase() ==
        AppSettingsService.subscriptionCategory.toLowerCase()) {
      _showMessage('La categoría Suscripción se conserva para tu historial.');
      return;
    }
    if (usageCount > 0 || _isSaving) return;
    if (settings.expenseCategories.length <= 1) {
      _showMessage('Deja al menos una categoría para organizar tus gastos.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Quitar esta categoría?'),
        content: Text(
          '“$category” ya no aparecerá al crear gastos. Tus registros anteriores se quedan como están.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Conservar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Quitar categoría'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _saveSettings(
      settings.copyWith(
        expenseCategories: settings.expenseCategories
            .where((item) => item != category)
            .toList(),
      ),
      'Categoría quitada.',
    );
  }

  Future<void> _editAccount(DigitalAccountBalance account) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) =>
          _DigitalAccountDialog(initialName: account.account.nombre),
    );
    if (name == null || !mounted || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      await _databaseService.actualizarCuentaDigital(
        id: account.account.id,
        nombre: name,
      );
      await _refreshSettingsData();
      if (mounted) _showMessage('Cuenta actualizada.');
    } catch (error, stackTrace) {
      logOperationFailure(
        error,
        stackTrace,
        operation: 'actualizar una cuenta',
      );
      if (mounted) {
        _showMessage(
          friendlyOperationError(error, action: 'actualizar la cuenta'),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _addAccount() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const _DigitalAccountDialog(),
    );
    if (name == null || !mounted || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      await _databaseService.crearCuentaDigital(name);
      await _refreshSettingsData();
      if (mounted) _showMessage('Cuenta digital agregada.');
    } catch (error, stackTrace) {
      logOperationFailure(error, stackTrace, operation: 'crear una cuenta');
      if (mounted) {
        _showMessage(friendlyOperationError(error, action: 'crear la cuenta'));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _removeAccount(DigitalAccountBalance account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar esta cuenta?'),
        content: Text(
          'Se eliminará "${account.account.nombre}". El saldo debe estar en cero para conservar intacto el dinero.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Conservar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar cuenta'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      await _databaseService.eliminarCuentaDigital(account.account.id);
      await _refreshSettingsData();
      if (mounted) _showMessage('Cuenta eliminada.');
    } catch (error, stackTrace) {
      logOperationFailure(error, stackTrace, operation: 'eliminar una cuenta');
      if (mounted) {
        _showMessage(
          friendlyOperationError(error, action: 'eliminar la cuenta'),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _refreshSettingsData() async {
    final accounts = await _databaseService.obtenerCuentasDigitales();
    final transfers = await _databaseService.obtenerTransferencias();
    final old = _loadedData;
    if (old == null || !mounted) return;
    final updated = _SettingsData(
      settings: old.settings,
      categories: {
        ...old.settings.expenseCategories,
        ...old.categoryUsage.keys,
      }.toList(),
      categoryUsage: old.categoryUsage,
      accounts: accounts,
      transfers: transfers,
    );
    setState(() {
      _loadedData = updated;
      _settingsFuture = Future.value(updated);
    });
  }

  Future<void> _saveTransfer([TransferenciasDineroData? transfer]) async {
    if (_isSaving) return;
    final data = _loadedData;
    if (data == null) return;
    final draft = await showDialog<_TransferDraft>(
      context: context,
      builder: (context) => _TransferDialog(
        accounts: data.accounts.map((item) => item.account).toList(),
        transfer: transfer,
      ),
    );
    if (draft == null || !mounted) return;
    setState(() => _isSaving = true);
    try {
      if (transfer == null) {
        await _databaseService.transferirDinero(
          medioOrigen: draft.origin.medium,
          cuentaOrigenId: draft.origin.accountId,
          medioDestino: draft.destination.medium,
          cuentaDestinoId: draft.destination.accountId,
          monto: draft.amount,
          fecha: draft.date,
          nota: draft.note,
        );
      } else {
        await _databaseService.actualizarTransferencia(
          id: transfer.id,
          medioOrigen: draft.origin.medium,
          cuentaOrigenId: draft.origin.accountId,
          medioDestino: draft.destination.medium,
          cuentaDestinoId: draft.destination.accountId,
          monto: draft.amount,
          fecha: draft.date,
          nota: draft.note,
        );
      }
      await _refreshSettingsData();
      if (mounted) _showMessage('Transferencia guardada.');
    } catch (error, stackTrace) {
      logOperationFailure(
        error,
        stackTrace,
        operation: 'guardar transferencia',
      );
      if (mounted) {
        _showMessage(
          friendlyOperationError(error, action: 'guardar la transferencia'),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteTransfer(TransferenciasDineroData transfer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Revertir esta transferencia?'),
        content: const Text(
          'Se revertirán ambos movimientos y el saldo volverá al origen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Conservar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Revertir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      await _databaseService.eliminarTransferencia(transfer.id);
      await _refreshSettingsData();
      if (mounted) _showMessage('Transferencia revertida.');
    } catch (error, stackTrace) {
      logOperationFailure(
        error,
        stackTrace,
        operation: 'revertir transferencia',
      );
      if (mounted) {
        _showMessage(
          friendlyOperationError(error, action: 'revertir la transferencia'),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded),
        title: const Text('¿Borrar todos tus datos?'),
        content: const Text(
          'Se borrarán ingresos, gastos, deudas, préstamos, ahorros, planes de gastos futuros y sus reservas. '
          'Las categorías se conservarán. No podrás deshacerlo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Conservar mis datos'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF9B4355),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, borrar todo'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      await _databaseService.borrarDatosFinancieros();
      if (!mounted) return;
      final currentSettings =
          _loadedData?.settings ?? await const AppSettingsService().load();
      final updatedData = _SettingsData(
        settings: currentSettings,
        categories: currentSettings.expenseCategories,
        categoryUsage: const {},
        accounts: await _databaseService.obtenerCuentasDigitales(),
        transfers: await _databaseService.obtenerTransferencias(),
      );
      setState(() {
        _loadedData = updatedData;
        _settingsFuture = Future.value(updatedData);
      });
      _showMessage('Listo, borramos tus datos financieros.');
    } catch (error, stackTrace) {
      logOperationFailure(
        error,
        stackTrace,
        operation: 'borrar datos financieros',
      );
      if (mounted) {
        _showMessage(friendlyOperationError(error, action: 'borrar tus datos'));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _retry() async {
    setState(() {
      _settingsFuture = _loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 420 ? 20.0 : 36.0;
            return FutureBuilder<_SettingsData>(
              future: _settingsFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) return _SettingsError(onRetry: _retry);
                if (!snapshot.hasData) return const _SettingsLoading();

                final data = snapshot.data!;
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    28,
                    horizontalPadding,
                    36,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 820),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Ajustes',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium,
                                ),
                              ),
                              const AnimatedCat(
                                asset: CatAssets.icono,
                                label: 'Gato de Finanzas',
                                width: 72,
                                height: 54,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Personaliza tus preferencias locales.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 26),
                          _SettingsSection(
                            title: 'Tu nombre',
                            icon: Icons.person_outline_rounded,
                            child: Form(
                              key: _nameFormKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextFormField(
                                    key: const ValueKey('settings-user-name'),
                                    controller: _userNameController,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    decoration: const InputDecoration(
                                      labelText: 'Nombre',
                                      hintText: 'Pon tu nombre',
                                      prefixIcon: Icon(Icons.person_outline),
                                    ),
                                    validator: (value) =>
                                        AppSettingsService.isValidUserName(
                                          value ?? '',
                                        )
                                        ? null
                                        : 'Usa solo letras españolas y espacios entre nombres.',
                                  ),
                                  const SizedBox(height: 12),
                                  FilledButton.icon(
                                    key: const ValueKey(
                                      'settings-save-user-name',
                                    ),
                                    onPressed: _isSaving
                                        ? null
                                        : () => _saveUserName(data.settings),
                                    icon: const Icon(Icons.check_rounded),
                                    label: const Text('Guardar nombre'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SettingsSection(
                            title: 'Categorías de gastos',
                            icon: Icons.category_outlined,
                            trailing: IconButton(
                              tooltip: 'Agregar categoría',
                              onPressed: _isSaving
                                  ? null
                                  : () => _addCategory(data.settings),
                              icon: const Icon(Icons.add_rounded),
                            ),
                            child: Column(
                              children: [
                                for (final category in data.categories)
                                  _CategoryPreferenceTile(
                                    name: category,
                                    usageCount:
                                        data.categoryUsage[category] ?? 0,
                                    isProtected:
                                        category.toLowerCase() ==
                                        AppSettingsService.subscriptionCategory
                                            .toLowerCase(),
                                    isSaving: _isSaving,
                                    onRemove: () => _removeCategory(
                                      data.settings,
                                      category,
                                      data.categoryUsage[category] ?? 0,
                                    ),
                                    onEdit: () =>
                                        _editCategory(data.settings, category),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SettingsSection(
                            title: 'Cuentas digitales',
                            icon: Icons.account_balance_wallet_outlined,
                            trailing: IconButton(
                              tooltip: 'Agregar cuenta digital',
                              onPressed: _isSaving ? null : _addAccount,
                              icon: const Icon(Icons.add_rounded),
                            ),
                            child: data.accounts.isEmpty
                                ? Text(
                                    'Aún no tienes cuentas digitales. Agrega las que uses; no crearemos bancos por ti.',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  )
                                : Column(
                                    children: [
                                      for (final account in data.accounts)
                                        _DigitalAccountTile(
                                          account: account,
                                          isSaving: _isSaving,
                                          onEdit: () => _editAccount(account),
                                          onRemove: () =>
                                              _removeAccount(account),
                                        ),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 16),
                          _SettingsSection(
                            title: 'Transferencias internas',
                            icon: Icons.swap_horiz_rounded,
                            trailing: IconButton(
                              tooltip: 'Registrar transferencia',
                              onPressed: _isSaving
                                  ? null
                                  : () => _saveTransfer(),
                              icon: const Icon(Icons.add_rounded),
                            ),
                            child: data.transfers.isEmpty
                                ? Text(
                                    'Mueve dinero entre efectivo y tus cuentas sin registrarlo como ingreso o gasto.',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  )
                                : Column(
                                    children: [
                                      for (final transfer in data.transfers)
                                        _TransferHistoryTile(
                                          transfer: transfer,
                                          origin: _transferEndpointLabel(
                                            transfer.medioOrigen,
                                            transfer.cuentaOrigenId,
                                            data.accounts,
                                          ),
                                          destination: _transferEndpointLabel(
                                            transfer.medioDestino,
                                            transfer.cuentaDestinoId,
                                            data.accounts,
                                          ),
                                          onEdit: () => _saveTransfer(transfer),
                                          onDelete: () =>
                                              _deleteTransfer(transfer),
                                          isSaving: _isSaving,
                                        ),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 16),
                          _SettingsSection(
                            title: 'Datos locales',
                            icon: Icons.storage_outlined,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Los registros se almacenan en este dispositivo.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  key: const ValueKey('settings-clear-data'),
                                  onPressed: _isSaving ? null : _clearAllData,
                                  icon: const Icon(Icons.delete_sweep_outlined),
                                  label: const Text('Borrar todos los datos'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFE99AA6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _SettingsData {
  const _SettingsData({
    required this.settings,
    required this.categories,
    required this.categoryUsage,
    required this.accounts,
    required this.transfers,
  });

  final AppSettings settings;
  final List<String> categories;
  final Map<String, int> categoryUsage;
  final List<DigitalAccountBalance> accounts;
  final List<TransferenciasDineroData> transfers;
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppCardDecorations.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _CategoryPreferenceTile extends StatelessWidget {
  const _CategoryPreferenceTile({
    required this.name,
    required this.usageCount,
    required this.isProtected,
    required this.isSaving,
    required this.onEdit,
    required this.onRemove,
  });

  final String name;
  final int usageCount;
  final bool isProtected;
  final bool isSaving;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final inUse = usageCount > 0;
    final protected = isProtected;
    return ListTile(
      key: ValueKey('settings-category-$name'),
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(name),
      subtitle: Text(
        protected
            ? 'Necesaria para conservar el historial de suscripciones'
            : inUse
            ? 'Usada en $usageCount ${usageCount == 1 ? 'gasto' : 'gastos'}'
            : 'Disponible para nuevos gastos',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      trailing: Wrap(
        spacing: 0,
        children: [
          IconButton(
            tooltip: 'Editar categoría $name',
            onPressed: protected || isSaving ? null : onEdit,
            icon: Icon(
              protected ? Icons.lock_outline_rounded : Icons.edit_outlined,
            ),
          ),
          IconButton(
            tooltip: protected
                ? 'Esta categoría es necesaria para el historial'
                : inUse
                ? 'Esta categoría está en uso y no se puede quitar'
                : 'Quitar categoría $name',
            onPressed: protected || inUse || isSaving ? null : onRemove,
            icon: const Icon(Icons.remove_circle_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _AddCategoryDialog extends StatefulWidget {
  const _AddCategoryDialog({this.initialName});

  final String? initialName;

  @override
  State<_AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<_AddCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialName ?? '';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialName == null ? 'Agregar categoría' : 'Editar categoría',
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          key: const ValueKey('settings-new-category'),
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Nombre'),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Escribe un nombre para la categoría.'
              : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, _controller.text.trim());
          },
          child: Text(widget.initialName == null ? 'Agregar' : 'Guardar'),
        ),
      ],
    );
  }
}

class _DigitalAccountDialog extends StatefulWidget {
  const _DigitalAccountDialog({this.initialName});

  final String? initialName;

  @override
  State<_DigitalAccountDialog> createState() => _DigitalAccountDialogState();
}

class _DigitalAccountDialogState extends State<_DigitalAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialName == null ? 'Nueva cuenta digital' : 'Editar cuenta',
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          key: const ValueKey('digital-account-name'),
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nombre de la cuenta',
            hintText: 'Ej. Mi billetera',
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Escribe el nombre de la cuenta.'
              : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, _controller.text.trim());
          },
          child: Text(widget.initialName == null ? 'Agregar' : 'Guardar'),
        ),
      ],
    );
  }
}

class _DigitalAccountTile extends StatelessWidget {
  const _DigitalAccountTile({
    required this.account,
    required this.isSaving,
    required this.onEdit,
    required this.onRemove,
  });

  final DigitalAccountBalance account;
  final bool isSaving;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey('digital-account-${account.account.id}'),
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.account_balance_wallet_outlined),
      title: Text(account.account.nombre),
      subtitle: Text(formatMoney(account.balance)),
      trailing: Wrap(
        children: [
          IconButton(
            tooltip: 'Editar cuenta ${account.account.nombre}',
            onPressed: isSaving ? null : onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Eliminar cuenta ${account.account.nombre}',
            onPressed: isSaving ? null : onRemove,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _TransferEndpoint {
  const _TransferEndpoint({
    required this.key,
    required this.label,
    required this.medium,
    this.accountId,
  });

  final String key;
  final String label;
  final MoneyMedium medium;
  final int? accountId;
}

class _TransferDraft {
  const _TransferDraft({
    required this.origin,
    required this.destination,
    required this.amount,
    required this.date,
    required this.note,
  });

  final _TransferEndpoint origin;
  final _TransferEndpoint destination;
  final double amount;
  final DateTime date;
  final String? note;
}

class _TransferDialog extends StatefulWidget {
  const _TransferDialog({required this.accounts, this.transfer});

  final List<CuentasDigitale> accounts;
  final TransferenciasDineroData? transfer;

  @override
  State<_TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends State<_TransferDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late final List<_TransferEndpoint> _endpoints;
  late String _originKey;
  late String _destinationKey;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _endpoints = [
      const _TransferEndpoint(
        key: 'cash',
        label: 'Efectivo',
        medium: MoneyMedium.cash,
      ),
      const _TransferEndpoint(
        key: 'digital-unassigned',
        label: 'Digital sin cuenta',
        medium: MoneyMedium.digital,
      ),
      for (final account in widget.accounts)
        _TransferEndpoint(
          key: 'account-${account.id}',
          label: account.nombre,
          medium: MoneyMedium.digital,
          accountId: account.id,
        ),
    ];
    final transfer = widget.transfer;
    _originKey = _endpointKey(transfer?.medioOrigen, transfer?.cuentaOrigenId);
    _destinationKey = _endpointKey(
      transfer?.medioDestino,
      transfer?.cuentaDestinoId,
    );
    if (_originKey == _destinationKey) {
      _originKey = 'cash';
      _destinationKey = 'digital-unassigned';
    }
    _amountController = TextEditingController(
      text: transfer == null ? '' : formatAmount(transfer.monto),
    );
    _noteController = TextEditingController(text: transfer?.nota ?? '');
    _date = transfer?.fecha ?? DateTime.now();
  }

  String _endpointKey(String? medium, int? accountId) {
    if (accountId != null &&
        _endpoints.any((item) => item.accountId == accountId)) {
      return 'account-$accountId';
    }
    return medium == MoneyMedium.cash.storageValue
        ? 'cash'
        : 'digital-unassigned';
  }

  _TransferEndpoint _endpoint(String key) =>
      _endpoints.firstWhere((item) => item.key == key);

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null && mounted) setState(() => _date = date);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _TransferDraft(
        origin: _endpoint(_originKey),
        destination: _endpoint(_destinationKey),
        amount: parseMoney(_amountController.text),
        date: _date,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.transfer == null
            ? 'Nueva transferencia'
            : 'Editar transferencia',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _originKey,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Desde'),
                items: [
                  for (final endpoint in _endpoints)
                    DropdownMenuItem(
                      value: endpoint.key,
                      child: Text(endpoint.label),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _originKey = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _destinationKey,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Hacia'),
                items: [
                  for (final endpoint in _endpoints)
                    DropdownMenuItem(
                      value: endpoint.key,
                      child: Text(endpoint.label),
                    ),
                ],
                validator: (value) => value == _originKey
                    ? 'Elige un destino distinto al origen.'
                    : null,
                onChanged: (value) {
                  if (value != null) setState(() => _destinationKey = value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('transfer-amount'),
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: const [ThousandsInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  prefixText: r'$ ',
                ),
                validator: (value) {
                  final amount = tryParseMoney(value);
                  return amount == null || amount <= 0
                      ? 'Escribe un monto mayor que cero.'
                      : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Nota (opcional)'),
              ),
              TextButton.icon(
                onPressed: _selectDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(formatSpanishLongDate(_date)),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }
}

class _TransferHistoryTile extends StatelessWidget {
  const _TransferHistoryTile({
    required this.transfer,
    required this.origin,
    required this.destination,
    required this.onEdit,
    required this.onDelete,
    required this.isSaving,
  });

  final TransferenciasDineroData transfer;
  final String origin;
  final String destination;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey('transfer-${transfer.id}'),
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.swap_horiz_rounded),
      title: Text('$origin → $destination'),
      subtitle: Text(formatSpanishLongDate(transfer.fecha)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(formatMoney(transfer.monto)),
          PopupMenuButton<String>(
            enabled: !isSaving,
            onSelected: (action) => action == 'edit' ? onEdit() : onDelete(),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Editar')),
              PopupMenuItem(value: 'delete', child: Text('Revertir')),
            ],
          ),
        ],
      ),
    );
  }
}

String _transferEndpointLabel(
  String medium,
  int? accountId,
  List<DigitalAccountBalance> accounts,
) {
  if (accountId != null) {
    for (final account in accounts) {
      if (account.account.id == accountId) return account.account.nombre;
    }
  }
  return MoneyMedium.fromStorage(medium)?.label ?? 'Sin clasificar';
}

class _SettingsLoading extends StatelessWidget {
  const _SettingsLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Estamos cargando tus ajustes...',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _SettingsError extends StatelessWidget {
  const _SettingsError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              'Ups, tus ajustes no cargaron esta vez.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Intentar de nuevo'),
            ),
          ],
        ),
      ),
    );
  }
}
