import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show ValueKey;
import 'package:flutter/material.dart' show SizedBox;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finanzas_app/database/app_database.dart';
import 'package:finanzas_app/main.dart' as app;
import 'package:finanzas_app/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('navega entre las siete secciones en móvil', (tester) async {
    await _prepareTemporaryDatabaseDirectory(tester);
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.runAsync(() async => app.main());
    await _pumpUntilFound(tester, find.text('Dinero disponible'));

    expect(find.text('Todavía no hay ingresos por aquí.'), findsNWidgets(2));
    expect(find.text('Todavía no hay gastos por aquí.'), findsOneWidget);
    expect(find.text('Todavía no hay deudas por aquí.'), findsNWidgets(2));
    expect(
      find.text('Agrega tu primer ingreso y empieza a organizar tu dinero.'),
      findsOneWidget,
    );
    _expectNoTestException(tester);

    await tester.tap(find.byTooltip('Gastos'));
    await _pumpUntilFound(tester, find.text('Gastos'));
    _expectNoTestException(tester);

    await tester.tap(find.byTooltip('Gastos futuros'));
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('future-expense-add')),
    );
    expect(find.text('Gastos futuros'), findsOneWidget);
    _expectNoTestException(tester);

    await tester.tap(find.byTooltip('Estadísticas'));
    await tester.pumpAndSettle();
    expect(find.text('Estamos preparando tus estadísticas...'), findsOneWidget);
    _expectNoTestException(tester);

    await tester.tap(find.byTooltip('Ahorros'));
    await _pumpUntilFound(tester, find.text('Tu historial'));
    _expectNoTestException(tester);

    await tester.tap(find.byTooltip('Deudas'));
    await tester.pumpAndSettle();
    expect(find.text('Estamos cargando tus deudas...'), findsOneWidget);
    _expectNoTestException(tester);

    await tester.tap(find.byTooltip('Ajustes'));
    await _pumpUntilFound(
      tester,
      find.text('Personaliza tus preferencias locales.'),
    );
    expect(find.text('Personaliza tus preferencias locales.'), findsOneWidget);
    _expectNoTestException(tester);

    await tester.tap(find.byTooltip('Inicio'));
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
      );
      await service.agregarGasto(
        nombre: 'Gasto de prueba',
        monto: 200,
        categoria: 'Prueba',
        fecha: now,
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
      );
    });
    addTearDown(() => tester.runAsync(() => service.close()));

    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app.FinanzasApp(databaseService: service));
    await _pumpUntilFound(tester, find.text('25,0%'));

    expect(find.text(r'$ 750'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-monthly-received')), findsOneWidget);
    expect(find.text(r'$ 1.000'), findsNWidgets(4));
    expect(find.text(r'$ 200'), findsOneWidget);
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
    await _pumpUntilFound(tester, find.text('Dinero disponible'));

    expect(find.text('Dinero disponible'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _unmountApp(tester);
  });
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
