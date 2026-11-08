import 'package:flutter/material.dart';

import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/user_messages.dart';
import '../../widgets/app_page_header.dart';
import '../../widgets/cat_illustration.dart';

class DigitalAccountsSetupScreen extends StatefulWidget {
  const DigitalAccountsSetupScreen({
    super.key,
    required this.databaseService,
    required this.onComplete,
  });

  final DatabaseService databaseService;
  final Future<void> Function() onComplete;

  @override
  State<DigitalAccountsSetupScreen> createState() =>
      _DigitalAccountsSetupScreenState();
}

class _DigitalAccountsSetupScreenState
    extends State<DigitalAccountsSetupScreen> {
  static const _suggestedAccounts = [
    'Nequi',
    'Daviplata',
    'Bancolombia',
    'Davivienda',
    'Nu',
    'BBVA',
    'Lulo Bank',
    'dale!',
    'Movii',
    'RappiPay',
  ];

  final List<String> _selectedAccounts = [];
  final Set<String> _existingAccounts = {};
  late Future<void> _loadFuture;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadExistingAccounts();
  }

  Future<void> _loadExistingAccounts() async {
    final accounts = await widget.databaseService.obtenerCuentasDigitales();
    if (!mounted) return;
    setState(() {
      _existingAccounts.clear();
      _selectedAccounts.clear();
      for (final account in accounts) {
        _existingAccounts.add(_accountKey(account.account.nombre));
        _selectedAccounts.add(account.account.nombre);
      }
    });
  }

  bool _isSelected(String name) => _selectedAccounts.any(
    (selected) => _accountKey(selected) == _accountKey(name),
  );

  bool _isExisting(String name) =>
      _existingAccounts.contains(_accountKey(name));

  void _toggleSuggested(String name, bool selected) {
    if (_isExisting(name)) return;
    setState(() {
      if (selected) {
        if (!_isSelected(name)) _selectedAccounts.add(name);
      } else {
        _selectedAccounts.removeWhere(
          (item) => _accountKey(item) == _accountKey(name),
        );
      }
    });
  }

  Future<void> _addCustomAccount() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const _CustomAccountDialog(),
    );
    if (name == null || !mounted) return;
    if (_isSelected(name) || _isExisting(name)) {
      _showMessage('Ya agregaste una cuenta con ese nombre.');
      return;
    }
    setState(() => _selectedAccounts.add(name));
  }

  Future<void> _editAccount(String oldName) async {
    if (_isExisting(oldName)) return;
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _CustomAccountDialog(initialName: oldName),
    );
    if (name == null || !mounted) return;
    if (_accountKey(name) != _accountKey(oldName) &&
        (_isSelected(name) || _isExisting(name))) {
      _showMessage('Ya agregaste una cuenta con ese nombre.');
      return;
    }
    setState(() {
      final index = _selectedAccounts.indexWhere(
        (item) => _accountKey(item) == _accountKey(oldName),
      );
      if (index >= 0) _selectedAccounts[index] = name;
    });
  }

  void _removeAccount(String name) {
    if (_isExisting(name)) return;
    setState(() {
      _selectedAccounts.removeWhere(
        (item) => _accountKey(item) == _accountKey(name),
      );
    });
  }

  Future<void> _completeSetup() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final existing = await widget.databaseService.obtenerCuentasDigitales();
      final existingNames = existing
          .map((account) => _accountKey(account.account.nombre))
          .toSet();
      for (final name in _selectedAccounts) {
        if (existingNames.add(_accountKey(name))) {
          await widget.databaseService.crearCuentaDigital(name);
        }
      }
      await widget.onComplete();
    } catch (error, stackTrace) {
      logOperationFailure(
        error,
        stackTrace,
        operation: 'guardar las cuentas digitales iniciales',
      );
      if (mounted) {
        _showMessage(
          friendlyOperationError(
            error,
            action: 'guardar las cuentas digitales',
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<void>(
          future: _loadFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No pudimos cargar tus cuentas digitales.'),
                    TextButton(
                      onPressed: () => setState(() {
                        _loadFuture = _loadExistingAccounts();
                      }),
                      child: const Text('Intentar de nuevo'),
                    ),
                  ],
                ),
              );
            }
            if (!snapshot.hasData &&
                snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding = constraints.maxWidth < 420
                    ? AppSpacing.pageHorizontal
                    : AppSpacing.pageHorizontalWide;
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    AppSpacing.pageTop,
                    horizontalPadding,
                    36,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: AnimatedCat(
                              asset: CatAssets.icono,
                              label: 'Gato de MichiFinanzas',
                              width: 84,
                              height: 72,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.section),
                          const AppPageHeader(
                            title: '¿Qué cuentas digitales utilizas?',
                            subtitle:
                                'Elige las que usas. No registraremos saldos ni movimientos.',
                          ),
                          const SizedBox(height: AppSpacing.section),
                          Text(
                            'Bancos y billeteras',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final name in _suggestedAccounts)
                                FilterChip(
                                  key: ValueKey('onboarding-account-$name'),
                                  avatar: Icon(
                                    _isSelected(name)
                                        ? Icons.check_circle_rounded
                                        : Icons.account_balance_wallet_outlined,
                                    size: 18,
                                  ),
                                  label: Text(name),
                                  selected: _isSelected(name),
                                  onSelected: _isExisting(name)
                                      ? null
                                      : (selected) =>
                                            _toggleSuggested(name, selected),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          OutlinedButton.icon(
                            key: const ValueKey('onboarding-add-custom'),
                            onPressed: _isSaving ? null : _addCustomAccount,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Agregar cuenta personalizada'),
                          ),
                          const SizedBox(height: AppSpacing.section),
                          _SelectedAccountsPanel(
                            accounts: _selectedAccounts,
                            isExisting: _isExisting,
                            onEdit: _editAccount,
                            onRemove: _removeAccount,
                          ),
                          const SizedBox(height: AppSpacing.section),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              key: const ValueKey('onboarding-confirm'),
                              onPressed: _isSaving ? null : _completeSetup,
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _selectedAccounts.isEmpty
                                          ? 'Continuar sin cuentas'
                                          : 'Confirmar y continuar',
                                    ),
                            ),
                          ),
                          if (_selectedAccounts.isEmpty) ...[
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                'Podrás agregar cuentas más adelante en Configuración.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
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

class _SelectedAccountsPanel extends StatelessWidget {
  const _SelectedAccountsPanel({
    required this.accounts,
    required this.isExisting,
    required this.onEdit,
    required this.onRemove,
  });

  final List<String> accounts;
  final bool Function(String name) isExisting;
  final ValueChanged<String> onEdit;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.card),
      decoration: AppCardDecorations.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confirma tus cuentas',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            accounts.isEmpty
                ? 'Aún no seleccionaste ninguna cuenta.'
                : 'Revisa la lista; puedes editarla antes de continuar.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (accounts.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final name in accounts)
              ListTile(
                key: ValueKey('onboarding-selected-$name'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.primary,
                ),
                title: Text(name),
                subtitle: isExisting(name)
                    ? const Text('Ya está en tu app')
                    : null,
                trailing: isExisting(name)
                    ? const Icon(Icons.verified_outlined)
                    : Wrap(
                        spacing: 0,
                        children: [
                          IconButton(
                            tooltip: 'Editar $name',
                            onPressed: () => onEdit(name),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: 'Quitar $name',
                            onPressed: () => onRemove(name),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
              ),
          ],
        ],
      ),
    );
  }
}

class _CustomAccountDialog extends StatefulWidget {
  const _CustomAccountDialog({this.initialName});

  final String? initialName;

  @override
  State<_CustomAccountDialog> createState() => _CustomAccountDialogState();
}

class _CustomAccountDialogState extends State<_CustomAccountDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
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
        widget.initialName == null
            ? 'Agregar cuenta digital'
            : 'Editar cuenta digital',
      ),
      content: TextField(
        key: const ValueKey('onboarding-custom-account-name'),
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        maxLength: 40,
        decoration: const InputDecoration(labelText: 'Nombre de la cuenta'),
        onSubmitted: (value) {
          final name = value.trim();
          if (name.isNotEmpty) Navigator.pop(context, name);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final name = _controller.text.trim();
            if (name.isNotEmpty) Navigator.pop(context, name);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

String _accountKey(String name) =>
    name.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
