import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show ValueKey;
import 'package:flutter/material.dart' show MaterialApp, Size, SizedBox;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finanzas_app/database/app_database.dart';
import 'package:finanzas_app/screens/settings/settings_screen.dart';
import 'package:finanzas_app/services/app_settings_service.dart';
import 'package:finanzas_app/services/database_service.dart';
import 'package:finanzas_app/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('persiste categorías sin mostrar presupuesto mensual', (
    tester,
  ) async {
    final service = DatabaseService(AppDatabase(NativeDatabase.memory()));
    await _prepareTemporaryStorage(tester);
    _setMobileSize(tester);
    await _mountSettingsScreen(tester, service);
    await _pumpUntilFound(
      tester,
      find.text('Personaliza tus preferencias locales.'),
    );

    expect(find.text('Moneda principal'), findsNothing);
    expect(find.text('Apariencia'), findsNothing);
    expect(find.text('Presupuesto mensual'), findsNothing);
    expect(find.byKey(const ValueKey('settings-monthly-budget')), findsNothing);
    expect(find.text('Comidaaaa'), findsOneWidget);
    expect(find.text('Comida para bichos'), findsOneWidget);
    expect(find.text('Comida'), findsNothing);

    await tester.tap(find.byTooltip('Agregar categoría'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('settings-new-category')),
      'Mascotas',
    );
    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();
    await _pumpUntilFound(tester, find.text('Mascotas'));

    final removeCustomCategory = find.byTooltip('Quitar categoría Mascotas');
    await tester.ensureVisible(removeCustomCategory);
    await tester.tap(removeCustomCategory);
    await tester.pumpAndSettle();
    expect(find.text('¿Quitar esta categoría?'), findsOneWidget);
    await tester.tap(find.text('Quitar categoría'));
    await tester.pumpAndSettle();
    await _pumpUntilSettings(tester, (settings) {
      return settings.expenseCategories.contains('Mascotas') &&
          settings.expenseCategories.contains('Comidaaaa') &&
          settings.expenseCategories.contains('Comida para bichos');
    });
    await _pumpUntilAbsent(
      tester,
      find.byKey(const ValueKey('settings-category-Mascotas')),
    );
    expect(find.text('Comidaaaa'), findsOneWidget);
    expect(find.text('Comida para bichos'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await _mountSettingsScreen(tester, service);
    await _pumpUntilFound(
      tester,
      find.text('Personaliza tus preferencias locales.'),
    );
    expect(find.text('Moneda principal'), findsNothing);
    expect(find.text('Apariencia'), findsNothing);
    expect(find.text('Presupuesto mensual'), findsNothing);
    expect(find.text('Mascotas'), findsNothing);
    expect(find.text('Comidaaaa'), findsOneWidget);
    expect(find.text('Comida para bichos'), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-monthly-budget')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() => service.close());
  });

  testWidgets('conserva y protege categorías que ya tienen gastos', (
    tester,
  ) async {
    final service = DatabaseService(AppDatabase(NativeDatabase.memory()));
    await _prepareTemporaryStorage(tester);
    await tester.runAsync(
      () => service.agregarGasto(
        nombre: 'Mercado',
        monto: 25,
        categoria: 'Comida',
        fecha: DateTime.now(),
      ),
    );
    _setMobileSize(tester);
    await _mountSettingsScreen(tester, service);
    await _pumpUntilFound(tester, find.text('Usada en 1 gasto'));

    expect(find.text('Comidaaaa'), findsOneWidget);
    expect(find.text('Comida'), findsNothing);
    expect(
      find.byTooltip('Esta categoría está en uso y no se puede quitar'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() => service.close());
  });

  testWidgets('confirma y borra todos los registros financieros', (
    tester,
  ) async {
    final service = DatabaseService(AppDatabase(NativeDatabase.memory()));
    await _prepareTemporaryStorage(tester);
    await tester.runAsync(() async {
      await service.agregarIngreso(monto: 900, fecha: DateTime.now());
      await service.agregarGasto(
        nombre: 'Compra',
        monto: 25,
        categoria: 'Compras',
        fecha: DateTime.now(),
      );
      final debtId = await service.agregarDeuda(
        nombre: 'Préstamo',
        montoOriginal: 500,
        cuota: 100,
        cuotasTotales: 5,
      );
      await service.registrarPagoDeuda(
        deudaId: debtId,
        monto: 40,
        fecha: DateTime.now(),
        operationId: 'settings-test-payment-1',
      );
    });
    _setMobileSize(tester);
    await _mountSettingsScreen(tester, service);
    await _pumpUntilFound(
      tester,
      find.text('Personaliza tus preferencias locales.'),
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('settings-clear-data')),
    );
    await tester.tap(find.byKey(const ValueKey('settings-clear-data')));
    await tester.pumpAndSettle();

    expect(find.text('¿Borrar todos tus datos?'), findsOneWidget);
    expect(
      find.textContaining('Las categorías se conservarán'),
      findsOneWidget,
    );
    await tester.tap(find.text('Conservar mis datos'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('settings-clear-data')),
    );
    await tester.tap(find.byKey(const ValueKey('settings-clear-data')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sí, borrar todo'));
    await _pumpUntilAny(
      tester,
      find.text('Listo, borramos tus datos financieros.'),
      find.textContaining('Ups, no se pudo borrar tus datos.'),
    );
    expect(
      find.textContaining('Ups, no se pudo borrar tus datos.'),
      findsNothing,
    );

    await tester.runAsync(() async {
      expect(await service.obtenerIngresos(), isEmpty);
      expect(await service.obtenerGastos(), isEmpty);
      expect(await service.obtenerDeudas(), isEmpty);
      expect(await service.obtenerTodosLosPagosDeuda(), isEmpty);
    });
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() => service.close());
  });
}

Future<void> _mountSettingsScreen(
  WidgetTester tester,
  DatabaseService service,
) async {
  await tester.runAsync(
    () => tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: SettingsScreen(databaseService: service),
      ),
    ),
  );
}

void _setMobileSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _prepareTemporaryStorage(WidgetTester tester) async {
  late Directory directory;
  await tester.runAsync(() async {
    directory = await Directory.systemTemp.createTemp(
      'finanzas_app_settings_test_',
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

Future<void> _pumpUntilAny(
  WidgetTester tester,
  Finder first,
  Finder second,
) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
    if (first.evaluate().isNotEmpty || second.evaluate().isNotEmpty) return;
  }
  fail('No se encontró ninguno de los resultados esperados.');
}

Future<void> _pumpUntilSettings(
  WidgetTester tester,
  bool Function(AppSettings) condition,
) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    late AppSettings settings;
    await tester.runAsync(() async {
      settings = await const AppSettingsService().load();
    });
    if (condition(settings)) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
  fail('Los ajustes no alcanzaron el estado persistido esperado.');
}

Future<void> _pumpUntilAbsent(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
    if (finder.evaluate().isEmpty) return;
  }
  fail('El widget no desapareció como se esperaba: $finder');
}
