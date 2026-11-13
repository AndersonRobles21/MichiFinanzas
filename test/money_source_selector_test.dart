import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finanzas_app/database/app_database.dart';
import 'package:finanzas_app/models/money_medium.dart';
import 'package:finanzas_app/services/database_service.dart';
import 'package:finanzas_app/theme/app_theme.dart';
import 'package:finanzas_app/utils/money_format.dart';
import 'package:finanzas_app/widgets/money_source_selector.dart';
import 'package:finanzas_app/widgets/transfer_money_dialog.dart';

void main() {
  testWidgets('muestra saldo y remanente actualizado por cuenta', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final service = DatabaseService(database);
    addTearDown(service.close);
    final date = DateTime(2026, 11, 11);
    final accountId = await service.crearCuentaDigital('Nequi');
    await service.agregarIngreso(
      monto: 350000,
      fecha: date,
      medio: MoneyMedium.digital,
      cuentaDigitalId: accountId,
    );
    await service.agregarIngreso(
      monto: 120000,
      fecha: date,
      medio: MoneyMedium.cash,
    );
    MoneyMedium? selectedMedium = MoneyMedium.cash;
    int? selectedAccountId;
    var amount = 25000.0;

    Future<void> pumpSelector() async {
      final values = await Future.wait<Object>([
        service.obtenerCuentasDigitales(),
        service.obtenerSaldosPorMedio(),
      ]);
      final balance = values[1] as AvailableBalanceBreakdown;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: SingleChildScrollView(
                child: MoneySourceSelector(
                  selectedMedium: selectedMedium,
                  selectedAccountId: selectedAccountId,
                  digitalAccounts: values[0] as List<DigitalAccountBalance>,
                  cashBalance: balance.cash,
                  amount: amount,
                  title: '¿Desde dónde quieres pagar?',
                  onChanged: (medium, accountId) => setState(() {
                    selectedMedium = medium;
                    selectedAccountId = accountId;
                  }),
                ),
              ),
            ),
          ),
        ),
      );
    }

    await pumpSelector();
    expect(find.text('Nequi'), findsOneWidget);
    expect(find.textContaining(formatMoney(350000)), findsOneWidget);
    await tester.tap(
      find.ancestor(of: find.text('Nequi'), matching: find.byType(InkWell)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Te quedarán: ${formatMoney(325000)}'), findsOneWidget);

    amount = 30000;
    await pumpSelector();
    expect(find.text('Te quedarán: ${formatMoney(320000)}'), findsOneWidget);

    await service.agregarGasto(
      nombre: 'Pago digital',
      monto: 30000,
      categoria: 'Compras',
      fecha: date,
      medio: MoneyMedium.digital,
      cuentaDigitalId: accountId,
    );
    await pumpSelector();
    expect(find.text('Te quedarán: ${formatMoney(290000)}'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('previsualiza saldos y bloquea transferir más del disponible', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final service = DatabaseService(database);
    addTearDown(service.close);
    final date = DateTime(2026, 11, 11);
    final accountId = await service.crearCuentaDigital('Nequi');
    await service.agregarIngreso(
      monto: 350000,
      fecha: date,
      medio: MoneyMedium.digital,
      cuentaDigitalId: accountId,
    );
    await service.agregarIngreso(
      monto: 120000,
      fecha: date,
      medio: MoneyMedium.cash,
    );
    final accounts = await service.obtenerCuentasDigitales();
    final balances = await service.obtenerSaldosPorMedio();
    TransferMoneyDraft? result;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                result = await showDialog<TransferMoneyDraft>(
                  context: context,
                  builder: (context) => TransferMoneyDialog(
                    accounts: accounts,
                    balances: balances,
                  ),
                );
              },
              child: const Text('Abrir transferencia'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir transferencia'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Nequi').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Efectivo').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('transfer-amount')),
      '400000',
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('${formatMoney(350000)}  →  ${formatMoney(-50000)}'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Confirmar transferencia'));
    await tester.tap(find.text('Confirmar transferencia'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No alcanza el saldo de Nequi'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('transfer-amount')),
      '50000',
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('${formatMoney(350000)}  →  ${formatMoney(300000)}'),
      findsOneWidget,
    );
    expect(
      find.textContaining('${formatMoney(120000)}  →  ${formatMoney(170000)}'),
      findsOneWidget,
    );
    await tester.tap(find.text('Confirmar transferencia'));
    await tester.pumpAndSettle();
    expect(result?.amount, 50000);
    expect(result?.origin.accountId, accountId);
    expect(result?.destination.medium, MoneyMedium.cash);
    expect(tester.takeException(), isNull);
  });
}
