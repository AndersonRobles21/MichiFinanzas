import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show ValueKey;
import 'package:flutter/material.dart'
    show
        IconButton,
        MaterialApp,
        Scaffold,
        Scrollable,
        Size,
        SizedBox,
        TextFormField;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finanzas_app/database/app_database.dart';
import 'package:finanzas_app/screens/debts/debts_screen.dart';
import 'package:finanzas_app/services/database_service.dart';
import 'package:finanzas_app/theme/app_theme.dart';
import 'package:finanzas_app/utils/money_format.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('muestra el estado vacío en una pantalla de 360 px', (
    tester,
  ) async {
    await _prepareTemporaryDatabaseDirectory(tester);
    _setMobileSize(tester);
    await _mountDebtsScreen(tester);
    await _pumpUntilFound(tester, find.text('Todavía no hay deudas por aquí.'));

    expect(find.text('Todavía no hay deudas por aquí.'), findsOneWidget);
    expect(find.byTooltip('Registrar deuda'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'crea deudas, registra abonos y elimina el historial en cascada',
    (tester) async {
      await _prepareTemporaryDatabaseDirectory(tester);
      await tester.runAsync(() async {
        final database = AppDatabase();
        try {
          await DatabaseService(
            database,
          ).agregarIngreso(monto: 10000, fecha: DateTime.now());
        } finally {
          await database.close();
        }
      });
      _setMobileSize(tester);
      await _mountDebtsScreen(tester);
      await _pumpUntilFound(
        tester,
        find.text('Todavía no hay deudas por aquí.'),
      );

      await tester.tap(find.byTooltip('Registrar deuda'));
      await tester.pumpAndSettle();
      expect(find.text('Registrar deuda'), findsOneWidget);

      await tester.tap(find.text('Guardar deuda'));
      await tester.pumpAndSettle();
      expect(find.text('Escribe un nombre para la deuda.'), findsOneWidget);
      expect(find.text('Escribe un monto mayor que cero.'), findsOneWidget);
      expect(find.text('Escribe una cuota mayor que cero.'), findsOneWidget);
      expect(find.text('Indica cuántas cuotas son.'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('debt-name')),
        'Crédito tienda',
      );
      await tester.enterText(find.byKey(const ValueKey('debt-amount')), '1000');
      await tester.enterText(
        find.byKey(const ValueKey('debt-installment')),
        '100',
      );
      await tester.enterText(
        find.byKey(const ValueKey('debt-installments-total')),
        '10',
      );
      await tester.enterText(
        find.byKey(const ValueKey('debt-installments-paid')),
        '11',
      );
      await tester.tap(find.text('Guardar deuda'));
      await tester.pumpAndSettle();
      expect(
        find.text('No pueden estar pagadas más cuotas de las que hay.'),
        findsNWidgets(2),
      );

      await tester.enterText(
        find.byKey(const ValueKey('debt-installments-paid')),
        '2',
      );
      await tester.tap(find.text('Guardar deuda'));
      await tester.pumpAndSettle();
      await _pumpUntilFound(tester, find.text('Crédito tienda'));

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('debt-1')),
          matching: find.text(r'$ 1.000'),
        ),
        findsNWidgets(2),
      );
      expect(find.text('0/10'), findsOneWidget);
      expect(find.text('Revisar dato histórico'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('Fecha no definida'), findsNothing);
      expect(find.text('Historial (0)'), findsOneWidget);
      expect(find.text('Pendiente'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text('Historial (0)'));
      await tester.tap(find.text('Historial (0)'));
      await tester.pumpAndSettle();
      expect(
        find.text('Todavía no hay abonos por aquí. Cada avance cuenta.'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Cerrar historial'));
      await tester.pumpAndSettle();

      await _recordPayment(tester, '0');
      expect(find.text('Escribe un abono mayor que cero.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('debt-payment-amount')),
        '1001',
      );
      await tester.tap(find.text('Revisar abono'));
      await tester.pumpAndSettle();
      expect(
        find.text('Ese abono supera lo que todavía debes.'),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const ValueKey('debt-payment-amount')),
        '40',
      );
      await tester.tap(find.text('Revisar abono'));
      await tester.pumpAndSettle();
      expect(find.text('Revisar abono'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.text(r'$ 1.000'), findsNWidgets(3));
      expect(find.text('0/10'), findsOneWidget);

      await _recordPayment(tester, '40');
      await _confirmPayment(tester);
      await _pumpUntilFound(
        tester,
        find.text(
          '¡Buen avance! El abono quedó registrado y el saldo actualizado 😸',
        ),
      );
      await tester.runAsync(() async {
        final database = AppDatabase();
        try {
          final service = DatabaseService(database);
          final debt = (await service.obtenerDeudas()).single;
          final payments = await service.obtenerPagosDeuda(debt.id);
          expect(payments, hasLength(1));
          expect(debt.cuotasPagadas, 0);
          expect(debt.cuotasPagadasDeclaradas, 2);
        } finally {
          await database.close();
        }
      });
      await _pumpUntilFound(tester, find.text(r'$ 960'));
      expect(find.text(r'$ 960'), findsNWidgets(2));
      expect(find.text('0/10'), findsOneWidget);
      expect(find.text('Historial (1)'), findsOneWidget);

      await _recordPayment(tester, '60');
      await _confirmPayment(tester);
      await _pumpUntilFound(tester, find.text(r'$ 900'));
      expect(find.text(r'$ 900'), findsNWidgets(2));
      expect(find.text('1/10'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);

      await tester.tap(find.text('Historial (2)'));
      await tester.pumpAndSettle();
      expect(find.text(r'$ 40'), findsOneWidget);
      expect(find.text(r'$ 60'), findsOneWidget);
      expect(find.text(_formatDate(DateTime.now())), findsNWidgets(2));
      await tester.tap(find.byTooltip('Cerrar historial'));
      await tester.pumpAndSettle();

      await _recordPayment(tester, '900');
      await _confirmPayment(tester);
      await _pumpUntilFound(tester, find.text('Pagada'));
      expect(find.text(r'$ 0'), findsNWidgets(2));
      expect(find.text('10/10'), findsOneWidget);
      expect(find.text('Registrar abono'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      final deleteDebt = find.byKey(const ValueKey('debt-delete-1'));
      await tester.ensureVisible(find.byKey(const ValueKey('debt-1')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        deleteDebt,
        240,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await _pumpUntilEnabled(tester, deleteDebt);
      tester.widget<IconButton>(deleteDebt).onPressed!.call();
      await tester.pumpAndSettle();
      expect(find.text('¿Borrar esta deuda?'), findsOneWidget);
      expect(find.textContaining('historial de 3 abonos'), findsOneWidget);
      await tester.tap(find.text('Borrar deuda'));
      await tester.pumpAndSettle();
      await _pumpUntilFound(
        tester,
        find.text('Todavía no hay deudas por aquí.'),
      );

      await tester.runAsync(() async {
        final database = AppDatabase();
        try {
          final service = DatabaseService(database);
          expect(await service.obtenerDeudas(), isEmpty);
          expect(await service.obtenerTodosLosPagosDeuda(), isEmpty);
        } finally {
          await database.close();
        }
      });
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('sugiere cuota, saldo real y guarda un abono personalizado', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final service = DatabaseService(database);
    addTearDown(database.close);
    final date = DateTime(2026, 10, 15);
    await service.agregarIngreso(monto: 1000, fecha: date);
    final debtId = await service.agregarDeuda(
      nombre: 'Crédito parcial',
      montoOriginal: 250,
      cuota: 100,
      cuotasTotales: 3,
    );
    await service.registrarPagoDeuda(
      deudaId: debtId,
      monto: 80,
      fecha: date,
      operationId: 'debt-payment-before-widget',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DebtsScreen(databaseService: service)),
      ),
    );
    await _pumpUntilFound(tester, find.text('Crédito parcial'));
    await tester.tap(find.text('Registrar abono'));
    await tester.pumpAndSettle();

    final amountField = find.byKey(const ValueKey('debt-payment-amount'));
    expect(tester.widget<TextFormField>(amountField).controller!.text, '100');
    await tester.tap(find.text('Pagar todo'));
    await tester.pump();
    expect(tester.widget<TextFormField>(amountField).controller!.text, '170');
    await tester.tap(find.text('Abonar otro valor'));
    await tester.pump();
    expect(tester.widget<TextFormField>(amountField).controller!.text, isEmpty);
    await tester.enterText(amountField, '25');
    await tester.tap(find.text('Revisar abono'));
    await tester.pumpAndSettle();
    expect(find.text('Monto: ${formatMoney(25)}'), findsOneWidget);

    final saveButton = tester.getCenter(find.text('Guardar'));
    await tester.tapAt(saveButton);
    await tester.tapAt(saveButton);
    await _pumpUntilFound(
      tester,
      find.text(
        '¡Buen avance! El abono quedó registrado y el saldo actualizado 😸',
      ),
    );

    final payments = await service.obtenerPagosDeuda(debtId);
    final debt = (await service.obtenerDeudas()).single;
    expect(payments, hasLength(2));
    expect(
      payments.fold<double>(0, (sum, payment) => sum + payment.monto),
      105,
    );
    expect(debt.cuotasPagadas, 1);
    expect(debt.montoOriginal - 105, 145);
    expect(await service.obtenerSaldoDisponible(), 895);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
  });

  testWidgets('la cuota sugerida no supera el saldo pendiente', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    final service = DatabaseService(database);
    addTearDown(database.close);
    final date = DateTime(2026, 10, 15);
    await service.agregarIngreso(monto: 500, fecha: date);
    final debtId = await service.agregarDeuda(
      nombre: 'Saldo menor que cuota',
      montoOriginal: 150,
      cuota: 100,
      cuotasTotales: 2,
    );
    await service.registrarPagoDeuda(
      deudaId: debtId,
      monto: 80,
      fecha: date,
      operationId: 'debt-payment-near-finish',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DebtsScreen(databaseService: service)),
      ),
    );
    await _pumpUntilFound(tester, find.text('Saldo menor que cuota'));
    await tester.tap(find.text('Registrar abono'));
    await tester.pumpAndSettle();

    final amountField = find.byKey(const ValueKey('debt-payment-amount'));
    expect(tester.widget<TextFormField>(amountField).controller!.text, '70');
    await tester.tap(find.text('Pagar todo'));
    await tester.pump();
    expect(tester.widget<TextFormField>(amountField).controller!.text, '70');
    await tester.enterText(amountField, '71');
    await tester.tap(find.text('Revisar abono'));
    await tester.pumpAndSettle();
    expect(find.text('Ese abono supera lo que todavía debes.'), findsOneWidget);
    expect(await service.obtenerPagosDeuda(debtId), hasLength(1));
    expect(await service.obtenerSaldoDisponible(), 420);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
  });

  testWidgets('mantiene la revisión abierta si el saldo cambió', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final service = DatabaseService(database);
    addTearDown(database.close);
    final date = DateTime(2026, 10, 15);
    await service.agregarIngreso(monto: 500, fecha: date);
    final debtId = await service.agregarDeuda(
      nombre: 'Deuda concurrente',
      montoOriginal: 100,
      cuota: 100,
      cuotasTotales: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DebtsScreen(databaseService: service)),
      ),
    );
    await _pumpUntilFound(tester, find.text('Deuda concurrente'));
    await tester.tap(find.text('Registrar abono'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Revisar abono'));
    await tester.pumpAndSettle();

    await service.registrarPagoDeuda(
      deudaId: debtId,
      monto: 100,
      fecha: date,
      operationId: 'concurrent-payment',
    );
    await tester.tap(find.text('Guardar'));
    await _pumpUntilFound(
      tester,
      find.text('Uy, ese abono pasa lo que todavía falta por pagar.'),
    );

    expect(find.text('Revisar abono'), findsOneWidget);
    expect(
      find.text(
        '¡Buen avance! El abono quedó registrado y el saldo actualizado 😸',
      ),
      findsNothing,
    );
    expect(await service.obtenerPagosDeuda(debtId), hasLength(1));
    expect(await service.obtenerSaldoDisponible(), 400);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
  });
}

Future<void> _recordPayment(WidgetTester tester, String amount) async {
  await tester.ensureVisible(find.text('Registrar abono'));
  await tester.tap(find.text('Registrar abono'));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey('debt-payment-amount')),
    amount,
  );
  await tester.tap(find.text('Revisar abono'));
  await tester.pumpAndSettle();
}

Future<void> _confirmPayment(WidgetTester tester) async {
  await tester.tap(find.text('Guardar'));
  await _pumpUntilFound(
    tester,
    find.text(
      '¡Buen avance! El abono quedó registrado y el saldo actualizado 😸',
    ),
  );
}

Future<void> _mountDebtsScreen(WidgetTester tester) async {
  await tester.runAsync(
    () => tester.pumpWidget(
      MaterialApp(theme: AppTheme.darkTheme, home: const DebtsScreen()),
    ),
  );
}

void _setMobileSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _prepareTemporaryDatabaseDirectory(WidgetTester tester) async {
  late Directory directory;
  await tester.runAsync(() async {
    directory = await Directory.systemTemp.createTemp(
      'finanzas_app_debts_test_',
    );
  });
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(pathProviderChannel, (call) async {
        switch (call.method) {
          case 'getApplicationDocumentsDirectory':
          case 'getTemporaryDirectory':
            return directory.path;
          default:
            throw MissingPluginException('Método no esperado: ${call.method}');
        }
      });

  addTearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    await tester.runAsync(() => directory.delete(recursive: true));
  });
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('No se encontró el contenido esperado: $finder');
}

Future<void> _pumpUntilEnabled(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
    if (tester.widget<IconButton>(finder).onPressed != null) return;
  }
  fail('El control nunca quedó habilitado: $finder');
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
