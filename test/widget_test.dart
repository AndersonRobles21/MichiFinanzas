import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show ValueKey;
import 'package:flutter/material.dart'
    show Drawer, ListTile, ListView, SizedBox, Text;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finanzas_app/database/app_database.dart';
import 'package:finanzas_app/main.dart' as app;
import 'package:finanzas_app/models/money_medium.dart';
import 'package:finanzas_app/services/app_settings_service.dart';
import 'package:finanzas_app/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('navega con el menú lateral entre las secciones', (tester) async {
    final service = DatabaseService(AppDatabase(NativeDatabase.memory()));
    addTearDown(() => tester.runAsync(() => service.close()));
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app.FinanzasApp(databaseService: service));
    await _completeWelcome(tester);

    expect(find.text('Tus movimientos aparecerán aquí.'), findsOneWidget);
    expect(find.text('No tienes pagos o planes próximos.'), findsOneWidget);
    expect(
      find.text('Agrega tu primer ingreso y empieza a organizar tu dinero.'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Abrir menú'));
    await tester.pumpAndSettle();
    final homeTile = find.byKey(const ValueKey('navigation-Inicio'));
    expect(tester.widget<ListTile>(homeTile).selected, isTrue);
    for (final group in [
      'RESUMEN',
      'MI DINERO',
      'ORGANIZACIÓN',
      'MIS OBJETIVOS',
      'ANÁLISIS',
      'PREFERENCIAS',
    ]) {
      final groupHeading = find.text(group);
      await _ensureDrawerItemVisible(tester, groupHeading);
      expect(groupHeading, findsOneWidget);
    }
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(Drawer), findsNothing);
    _expectNoTestException(tester);

    await _openDrawerAndSelect(tester, 'Ingresos');
    expect(find.text('Ingresos'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-monthly-received')), findsNothing);
    _expectNoTestException(tester);

    await _openDrawerAndSelect(tester, 'Gastos');
    await _pumpUntilFound(tester, find.text('Gastos'));
    _expectNoTestException(tester);

    await _openDrawerAndSelect(tester, 'Gastos futuros');
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('future-expense-add')),
    );
    expect(find.text('Gastos futuros'), findsOneWidget);
    _expectNoTestException(tester);

    await _openDrawerAndSelect(tester, 'Estadísticas');
    await tester.pumpAndSettle();
    expect(find.text('Estamos preparando tus estadísticas...'), findsOneWidget);
    _expectNoTestException(tester);

    await _openDrawerAndSelect(tester, 'Ahorros');
    await _pumpUntilFound(tester, find.text('Tu historial'));
    _expectNoTestException(tester);

    await _openDrawerAndSelect(tester, 'Deudas y préstamos');
    await tester.pumpAndSettle();
    expect(find.text('Estamos cargando tus deudas...'), findsOneWidget);
    _expectNoTestException(tester);

    await _openDrawerAndSelect(tester, 'Configuración');
    await _pumpUntilFound(
      tester,
      find.text('Personaliza tus preferencias locales.'),
    );
    expect(find.text('Personaliza tus preferencias locales.'), findsOneWidget);
    _expectNoTestException(tester);
    await tester.tap(find.byTooltip('Abrir menú'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(Drawer), findsNothing);
    expect(find.text('Personaliza tus preferencias locales.'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Dinero disponible'), findsOneWidget);
    _expectNoTestException(tester);

    await _openDrawerAndSelect(tester, 'Suscripciones');
    await _pumpUntilFound(tester, find.text('Suscripciones'));
    expect(find.text('Todavía no tienes suscripciones.'), findsOneWidget);
    _expectNoTestException(tester);

    await _openDrawerAndSelect(tester, 'Inicio');
    expect(find.text('Dinero disponible'), findsOneWidget);
    final quickExpense = find.byKey(const ValueKey('home-quick-expense'));
    await tester.ensureVisible(quickExpense);
    await tester.tap(quickExpense);
    await tester.pumpAndSettle();
    expect(find.text('Gastos'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Dinero disponible'), findsOneWidget);

    final accountsLink = find.byKey(const ValueKey('home-view-accounts'));
    await tester.ensureVisible(accountsLink);
    await tester.tap(accountsLink);
    await tester.pumpAndSettle();
    expect(find.text('Personaliza tus preferencias locales.'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Dinero disponible'), findsOneWidget);
    _expectNoTestException(tester);
    await _unmountApp(tester);
  });

  testWidgets('calcula el resumen con registros reales de Drift', (
    tester,
  ) async {
    await _prepareTemporaryDatabaseDirectory(tester);
    late AppDatabase database;
    late DatabaseService service;
    await tester.runAsync(() async {
      database = AppDatabase(NativeDatabase.memory());
      service = DatabaseService(database);
      final now = DateTime.now();

      await service.agregarIngreso(
        monto: 1000,
        fecha: now,
        descripcion: 'Ingreso de prueba',
        medio: MoneyMedium.cash,
      );
      await service.agregarGasto(
        nombre: 'Gasto de prueba',
        monto: 200,
        categoria: 'Prueba',
        fecha: now,
        medio: MoneyMedium.cash,
      );
      final deudaId = await service.agregarDeuda(
        nombre: 'Deuda de prueba',
        montoOriginal: 500,
        cuota: 100,
        cuotasTotales: 5,
        fechaProximoPago: now.add(const Duration(days: 3)),
      );
      await service.registrarPagoDeuda(
        deudaId: deudaId,
        monto: 50,
        fecha: now,
        operationId: 'widget-payment-1',
        medio: MoneyMedium.cash,
      );
    });
    addTearDown(() => tester.runAsync(() => service.close()));

    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app.FinanzasApp(databaseService: service));
    await _completeWelcome(tester);
    await _pumpUntilFound(tester, find.text('25,0%'));

    final availableBalance = find.byKey(
      const ValueKey('home-available-balance'),
    );
    expect(availableBalance, findsOneWidget);
    expect(tester.widget<Text>(availableBalance).data, r'$ 750');
    expect(find.byKey(const ValueKey('home-monthly-received')), findsOneWidget);
    expect(find.text(r'$ 1.000'), findsOneWidget);
    expect(find.text(r'$ 250'), findsOneWidget);
    expect(find.text('25,0%'), findsOneWidget);
    expect(find.text(r'$ 450'), findsOneWidget);
    expect(find.text('Deuda de prueba'), findsOneWidget);
    expect(
      find.text('Ten presentes tus próximos pagos para llegar con calma.'),
      findsOneWidget,
    );
    _expectNoTestException(tester);
    await _unmountApp(tester);
  });

  testWidgets('se adapta a una ventana amplia', (tester) async {
    await _prepareTemporaryDatabaseDirectory(tester);
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final database = AppDatabase(NativeDatabase.memory());
    final service = DatabaseService(database);
    addTearDown(() => tester.runAsync(() => service.close()));
    await tester.pumpWidget(app.FinanzasApp(databaseService: service));
    await _completeWelcome(tester);
    await _pumpUntilFound(tester, find.text('Dinero disponible'));

    expect(find.text('Dinero disponible'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _unmountApp(tester);
  });

  testWidgets('guarda el nombre de bienvenida y no la repite al reabrir', (
    tester,
  ) async {
    await _prepareTemporaryDatabaseDirectory(tester);
    final database = AppDatabase(NativeDatabase.memory());
    final service = DatabaseService(database);
    addTearDown(() => tester.runAsync(() => service.close()));

    await tester.pumpWidget(app.FinanzasApp(databaseService: service));
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('welcome-user-name')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('welcome-user-name')),
      'María José',
    );
    await tester.tap(find.text('Continuar'));
    await _pumpUntilFound(
      tester,
      find.text('¿Qué cuentas digitales utilizas?'),
    );
    final continueWithoutAccounts = find.text('Continuar sin cuentas');
    await tester.ensureVisible(continueWithoutAccounts);
    await tester.tap(continueWithoutAccounts);
    await _pumpUntilFound(tester, find.text('Dinero disponible'));
    final settings = await tester.runAsync(
      () => const AppSettingsService().load(),
    );
    expect(settings?.hasCompletedAccountSetup, isTrue);
    expect(
      find.text('Hola, María José. Aquí ves cómo va tu dinero.'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(app.FinanzasApp(databaseService: service));
    await _pumpUntilFound(tester, find.text('Dinero disponible'));
    expect(find.byKey(const ValueKey('welcome-user-name')), findsNothing);
    expect(
      find.text('Hola, María José. Aquí ves cómo va tu dinero.'),
      findsOneWidget,
    );
    await _unmountApp(tester);
  });

  testWidgets('configura cuentas digitales sin registrar saldos', (
    tester,
  ) async {
    await _prepareTemporaryDatabaseDirectory(tester);
    final service = DatabaseService(AppDatabase(NativeDatabase.memory()));
    addTearDown(() => tester.runAsync(() => service.close()));
    late int existingAccountId;
    await tester.runAsync(() async {
      existingAccountId = await service.crearCuentaDigital('Cuenta existente');
      await service.agregarIngreso(
        monto: 500,
        fecha: DateTime(2026, 11, 6),
        descripcion: 'Ingreso existente',
        medio: MoneyMedium.digital,
        cuentaDigitalId: existingAccountId,
      );
    });
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app.FinanzasApp(databaseService: service));
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('welcome-user-name')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('welcome-user-name')),
      'Camila2',
    );
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(
      find.text('Usa solo letras y espacios; no dejes el campo vacío.'),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const ValueKey('welcome-user-name')),
      'Camila',
    );
    await tester.tap(find.text('Continuar'));
    await _pumpUntilFound(
      tester,
      find.text('¿Qué cuentas digitales utilizas?'),
    );
    expect(find.text('Cuenta existente'), findsOneWidget);

    await _unmountApp(tester);
    await tester.pumpWidget(app.FinanzasApp(databaseService: service));
    await _pumpUntilFound(
      tester,
      find.text('¿Qué cuentas digitales utilizas?'),
    );

    for (final name in ['Nequi', 'Daviplata']) {
      final option = find.byKey(ValueKey('onboarding-account-$name'));
      await tester.ensureVisible(option);
      await tester.tap(option);
    }

    final addCustom = find.byKey(const ValueKey('onboarding-add-custom'));
    await tester.ensureVisible(addCustom);
    await tester.tap(addCustom);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('onboarding-custom-account-name')),
      'Mi billetera',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Mi billetera'), findsOneWidget);

    final editCustom = find.byTooltip('Editar Mi billetera');
    await tester.ensureVisible(editCustom);
    await tester.tap(editCustom);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('onboarding-custom-account-name')),
      'Billetera personal',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Billetera personal'), findsOneWidget);

    final confirm = find.byKey(const ValueKey('onboarding-confirm'));
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await _pumpUntilFound(tester, find.text('Dinero disponible'));

    final accounts = await tester.runAsync(service.obtenerCuentasDigitales);
    final balances = {
      for (final account in accounts ?? [])
        account.account.nombre: account.balance,
    };
    expect(balances, {
      'Billetera personal': 0,
      'Cuenta existente': 500,
      'Daviplata': 0,
      'Nequi': 0,
    });
    final incomes = await tester.runAsync(service.obtenerIngresos) ?? const [];
    expect(incomes, hasLength(1));
    expect(incomes.single.descripcion, 'Ingreso existente');
    final settings = await tester.runAsync(
      () => const AppSettingsService().load(),
    );
    expect(settings?.hasCompletedAccountSetup, isTrue);

    await _unmountApp(tester);
  });
}

Future<void> _openDrawerAndSelect(
  WidgetTester tester,
  String destination,
) async {
  await tester.tap(find.byTooltip('Abrir menú'));
  await tester.pumpAndSettle();
  final destinationTile = find.byKey(ValueKey('navigation-$destination'));
  final drawerList = find.descendant(
    of: find.byType(Drawer),
    matching: find.byType(ListView),
  );
  await tester.drag(drawerList, const Offset(0, 1000));
  await tester.pumpAndSettle();
  await _ensureDrawerItemVisible(tester, destinationTile);
  await tester.tap(destinationTile);
  await tester.pumpAndSettle();
  expect(find.byType(Drawer), findsNothing);
}

Future<void> _ensureDrawerItemVisible(WidgetTester tester, Finder item) async {
  final drawerList = find.descendant(
    of: find.byType(Drawer),
    matching: find.byType(ListView),
  );
  for (var attempt = 0; item.evaluate().isEmpty && attempt < 8; attempt++) {
    await tester.drag(drawerList, const Offset(0, -280));
    await tester.pumpAndSettle();
  }
  if (item.evaluate().isEmpty) {
    fail('No se encontró la opción del menú: $item');
  }
  await tester.ensureVisible(item);
}

Future<void> _prepareTemporaryDatabaseDirectory(WidgetTester tester) async {
  late Directory directory;
  await tester.runAsync(() async {
    directory = await Directory.systemTemp.createTemp(
      'finanzas_app_dashboard_test_',
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

Future<void> _completeWelcome(WidgetTester tester) async {
  final nameField = find.byKey(const ValueKey('welcome-user-name'));
  final dashboard = find.text('Dinero disponible');
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
    if (dashboard.evaluate().isNotEmpty) return;
    if (nameField.evaluate().isNotEmpty) break;
  }
  expect(nameField, findsOneWidget);
  await tester.enterText(nameField, 'Anderson');
  await tester.tap(find.text('Continuar'));
  final continueWithoutAccounts = find.text('Continuar sin cuentas');
  await _pumpUntilFound(tester, continueWithoutAccounts);
  await tester.ensureVisible(continueWithoutAccounts);
  await tester.tap(continueWithoutAccounts);
  await _pumpUntilFound(tester, dashboard);
}

void _expectNoTestException(WidgetTester tester) {
  expect(tester.takeException(), isNull);
}

Future<void> _unmountApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 10)),
  );
}
