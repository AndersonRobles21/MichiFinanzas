import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finanzas_app/database/app_database.dart';
import 'package:finanzas_app/models/money_medium.dart';
import 'package:finanzas_app/models/subscription.dart';
import 'package:finanzas_app/screens/subscriptions/subscriptions_screen.dart';
import 'package:finanzas_app/services/database_service.dart';
import 'package:finanzas_app/theme/app_theme.dart';

void main() {
  test('convierte cada frecuencia a su equivalente mensual', () {
    expect(SubscriptionFrequency.weekly.monthlyCost(120), 520);
    expect(SubscriptionFrequency.monthly.monthlyCost(120), 120);
    expect(SubscriptionFrequency.quarterly.monthlyCost(120), 40);
    expect(SubscriptionFrequency.yearly.monthlyCost(1200), 100);
  });

  test('crea, edita, elimina y conserva suscripciones en Drift', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final service = DatabaseService(database);
    final date = DateTime(2026, 11, 5);
    try {
      final id = await service.agregarSuscripcion(
        nombre: 'Spotify',
        precio: 100,
        proximoPago: date,
        frecuencia: SubscriptionFrequency.monthly,
        medio: MoneyMedium.digital,
      );
      var subscription = (await service.obtenerSuscripciones()).single;
      expect(subscription.id, id);
      expect(subscription.nombre, 'Spotify');
      expect(subscription.medio, MoneyMedium.digital.storageValue);

      await service.actualizarSuscripcion(
        id: id,
        nombre: 'Música',
        precio: 1200,
        proximoPago: date.add(const Duration(days: 2)),
        frecuencia: SubscriptionFrequency.yearly,
      );
      subscription = (await service.obtenerSuscripciones()).single;
      expect(subscription.nombre, 'Música');
      expect(subscription.precio, 1200);
      expect(
        subscription.frecuencia,
        SubscriptionFrequency.yearly.storageValue,
      );
      expect(subscription.medio, isNull);

      await service.eliminarSuscripcion(id);
      expect(await service.obtenerSuscripciones(), isEmpty);
    } finally {
      await service.close();
    }
  });

  test('la migración v10 agrega suscripciones sin perder ingresos', () async {
    final date = DateTime(2026, 10, 15).millisecondsSinceEpoch;
    final executor = NativeDatabase.memory(
      setup: (database) {
        database.execute('''
          CREATE TABLE ingresos (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            monto REAL NOT NULL,
            tipo TEXT NOT NULL DEFAULT 'ingreso',
            fecha INTEGER NOT NULL,
            descripcion TEXT,
            medio TEXT
          )
        ''');
        database.execute(
          "INSERT INTO ingresos (monto, fecha, descripcion) "
          "VALUES (500, $date, 'Ingreso conservado')",
        );
        database.execute('PRAGMA user_version = 10');
      },
    );
    final database = AppDatabase(executor);
    final service = DatabaseService(database);
    try {
      expect((await service.obtenerIngresos()).single.monto, 500);
      await service.agregarSuscripcion(
        nombre: 'Servicio anual',
        precio: 1200,
        proximoPago: DateTime(2027, 10, 15),
        frecuencia: SubscriptionFrequency.yearly,
      );
      expect(await service.obtenerSuscripciones(), hasLength(1));
      expect(
        (await service.obtenerIngresos()).single.descripcion,
        'Ingreso conservado',
      );
    } finally {
      await service.close();
    }
  });

  testWidgets('permite crear, editar y eliminar desde Suscripciones', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final service = DatabaseService(database);
    addTearDown(service.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(body: SubscriptionsScreen(databaseService: service)),
      ),
    );
    await _pumpUntilFound(
      tester,
      find.text('Todavía no tienes suscripciones.'),
    );

    await tester.tap(find.byKey(const ValueKey('subscription-add')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('subscription-name')),
      'Spotify',
    );
    await tester.enterText(
      find.byKey(const ValueKey('subscription-price')),
      '120',
    );
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    await _pumpUntilFound(tester, find.text('Spotify'));
    expect(find.textContaining(r'$ 120 por cobro'), findsOneWidget);
    expect(find.textContaining(r'$ 120 / mes'), findsOneWidget);

    await tester.tap(find.byTooltip('Acciones de Spotify'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('subscription-price')),
      '1.200',
    );
    await tester.tap(
      find.byType(DropdownButtonFormField<SubscriptionFrequency>),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anual').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Guardar cambios'));
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
    await _pumpUntilFound(tester, find.textContaining(r'$ 100 / mes'));
    expect(find.textContaining('Anual'), findsOneWidget);

    await tester.tap(find.byTooltip('Acciones de Spotify'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar').last);
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      expect(await service.obtenerSuscripciones(), isEmpty);
    });
    await _pumpUntilFound(
      tester,
      find.text('Todavía no tienes suscripciones.'),
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int attempts = 30,
}) async {
  for (var attempt = 0; attempt < attempts; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsWidgets);
}
