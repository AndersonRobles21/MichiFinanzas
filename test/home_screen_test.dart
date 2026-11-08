import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finanzas_app/database/app_database.dart';
import 'package:finanzas_app/models/money_medium.dart';
import 'package:finanzas_app/screens/home/home_screen.dart';
import 'package:finanzas_app/services/database_service.dart';
import 'package:finanzas_app/theme/app_theme.dart';

void main() {
  testWidgets('desglosa el dinero disponible por efectivo y cuenta', (
    tester,
  ) async {
    await _prepareTemporaryStorage(tester);
    final database = AppDatabase(NativeDatabase.memory());
    final service = DatabaseService(database);
    addTearDown(service.close);
    final date = DateTime.now();
    final nequiId = await service.crearCuentaDigital('Nequi');
    final bankId = await service.crearCuentaDigital('Bancolombia');
    final nuId = await service.crearCuentaDigital('Nu');
    await service.agregarIngreso(
      monto: 80000,
      fecha: date,
      medio: MoneyMedium.cash,
    );
    await service.agregarIngreso(
      monto: 150000,
      fecha: date,
      medio: MoneyMedium.digital,
      cuentaDigitalId: nequiId,
    );
    await service.agregarIngreso(
      monto: 320000,
      fecha: date,
      medio: MoneyMedium.digital,
      cuentaDigitalId: bankId,
    );
    await service.agregarIngreso(
      monto: 50000,
      fecha: date,
      medio: MoneyMedium.digital,
    );

    await tester.runAsync(
      () => tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(body: HomeScreen(databaseService: service)),
        ),
      ),
    );
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('home-money-location-title')),
    );

    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('home-available-balance')))
          .data,
      r'$ 600.000',
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('home-cash-balance'))).data,
      r'$ 80.000',
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(ValueKey('home-account-balance-value-$nequiId')),
          )
          .data,
      r'$ 150.000',
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(ValueKey('home-account-balance-value-$bankId')),
          )
          .data,
      r'$ 320.000',
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(ValueKey('home-account-balance-value-$nuId')),
          )
          .data,
      r'$ 0',
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('home-unassigned-digital-balance')),
          )
          .data,
      r'$ 50.000',
    );
    expect(tester.takeException(), isNull);
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

Future<void> _prepareTemporaryStorage(WidgetTester tester) async {
  late Directory directory;
  await tester.runAsync(() async {
    directory = await Directory.systemTemp.createTemp(
      'finanzas_app_home_test_',
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
    if (await directory.exists()) {
      await tester.runAsync(() => directory.delete(recursive: true));
    }
  });
}
