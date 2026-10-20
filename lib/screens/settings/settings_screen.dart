import 'dart:async';

import 'package:flutter/material.dart';

import '../../database/app_database.dart';
import '../../services/app_settings_service.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/user_messages.dart';
import '../../widgets/cat_illustration.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.isActive = true, this.databaseService});

  final bool isActive;
  final DatabaseService? databaseService;

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
      );
      setState(() {
        _loadedData = updatedData;
        _settingsFuture = Future.value(updatedData);
      });
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

  Future<void> _removeCategory(
    AppSettings settings,
    String category,
    int usageCount,
  ) async {
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
                                    isSaving: _isSaving,
                                    onRemove: () => _removeCategory(
                                      data.settings,
                                      category,
                                      data.categoryUsage[category] ?? 0,
                                    ),
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
  });

  final AppSettings settings;
  final List<String> categories;
  final Map<String, int> categoryUsage;
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
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outline),
      ),
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
    required this.isSaving,
    required this.onRemove,
  });

  final String name;
  final int usageCount;
  final bool isSaving;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final inUse = usageCount > 0;
    return ListTile(
      key: ValueKey('settings-category-$name'),
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(name),
      subtitle: Text(
        inUse
            ? 'Usada en $usageCount ${usageCount == 1 ? 'gasto' : 'gastos'}'
            : 'Disponible para nuevos gastos',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      trailing: IconButton(
        tooltip: inUse
            ? 'Esta categoría está en uso y no se puede quitar'
            : 'Quitar categoría $name',
        onPressed: inUse || isSaving ? null : onRemove,
        icon: const Icon(Icons.remove_circle_outline_rounded),
      ),
    );
  }
}

class _AddCategoryDialog extends StatefulWidget {
  const _AddCategoryDialog();

  @override
  State<_AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<_AddCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar categoría'),
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
          child: const Text('Agregar'),
        ),
      ],
    );
  }
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
