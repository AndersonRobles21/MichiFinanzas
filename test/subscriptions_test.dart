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
        medio: MoneyMedium.cash,
      );
      var subscription = (await service.obtenerSuscripciones()).single;
      expect(subscription.id, id);
      expect(subscription.nombre, 'Spotify');
      expect(subscription.medio, MoneyMedium.cash.storageValue);

      await service.actualizarSuscripcion(
        id: id,
        nombre: 'Música',
        precio: 1200,
        proximoPago: date.add(const Duration(days: 2)),
        frecuencia: SubscriptionFrequency.yearly,
        medio: MoneyMedium.cash,
      );
      subscription = (await service.obtenerSuscripciones()).single;
      expect(subscription.nombre, 'Música');
      expect(subscription.precio, 1200);
      expect(
        subscription.frecuencia,
        SubscriptionFrequency.yearly.storageValue,
      );
      expect(subscription.medio, MoneyMedium.cash.storageValue);

      await service.eliminarSuscripcion(id);
      expect((await service.obtenerSuscripciones()).single.activa, isFalse);
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
        medio: MoneyMedium.cash,
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

  test(
    'distribuye un ingreso entre efectivo y cuentas y valida el total',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final service = DatabaseService(database);
      try {
        final accountId = await service.crearCuentaDigital('Nequi');
        await expectLater(
          service.agregarIngreso(
            monto: 100,
            fecha: DateTime(2026, 10, 20),
            destinos: [
              const IncomeDestination(medio: MoneyMedium.cash, monto: 40),
              IncomeDestination(
                medio: MoneyMedium.digital,
                monto: 60,
                cuentaDigitalId: accountId,
              ),
            ],
          ),
          completes,
        );
        final balance = await service.obtenerSaldosPorMedio();
        expect(balance.total, 100);
        expect(balance.cash, 40);
        expect(balance.digital, 60);
        expect((await service.obtenerCuentasDigitales()).single.balance, 60);

        await expectLater(
          service.agregarIngreso(
            monto: 100,
            fecha: DateTime(2026, 10, 21),
            destinos: const [
              IncomeDestination(medio: MoneyMedium.cash, monto: 90),
            ],
          ),
          throwsA(isA<DatabaseServiceException>()),
        );
        expect(await service.obtenerIngresos(), hasLength(1));
      } finally {
        await service.close();
      }
    },
  );

  test(
    'paga suscripción una vez y conserva gasto y vencimiento atómicos',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final service = DatabaseService(database);
      final date = DateTime(2026, 10, 20);
      try {
        final accountId = await service.crearCuentaDigital('Nequi');
        await service.agregarIngreso(
          monto: 500,
          fecha: date,
          medio: MoneyMedium.digital,
          cuentaDigitalId: accountId,
        );
        final subscriptionId = await service.agregarSuscripcion(
          nombre: 'Spotify',
          precio: 120,
          proximoPago: date,
          frecuencia: SubscriptionFrequency.monthly,
          medio: MoneyMedium.digital,
          cuentaDigitalId: accountId,
        );
        await service.pagarSuscripcion(
          suscripcionId: subscriptionId,
          periodoEsperado: date,
          medio: MoneyMedium.digital,
          cuentaDigitalId: accountId,
          fecha: date,
        );

        final balance = await service.obtenerSaldosPorMedio();
        expect(balance.total, 380);
        expect(balance.digital, 380);
        expect((await service.obtenerCuentasDigitales()).single.balance, 380);
        final payment = (await service.obtenerPagosSuscripcion(
          subscriptionId,
        )).single;
        expect(payment.nombre, 'Spotify');
        expect(payment.categoria, DatabaseService.subscriptionCategory);
        expect(payment.monto, 120);
        expect(
          (await service.obtenerSuscripciones()).single.proximoPago,
          DateTime(2026, 11, 20),
        );

        await expectLater(
          service.pagarSuscripcion(
            suscripcionId: subscriptionId,
            periodoEsperado: date,
            medio: MoneyMedium.digital,
            cuentaDigitalId: accountId,
            fecha: date,
          ),
          throwsA(isA<DatabaseServiceException>()),
        );
        expect(
          await service.obtenerPagosSuscripcion(subscriptionId),
          hasLength(1),
        );
        expect((await service.obtenerSaldosPorMedio()).total, 380);
        await service.cancelarSuscripcion(subscriptionId);
        expect((await service.obtenerSuscripciones()).single.activa, isFalse);
        expect(
          await service.obtenerPagosSuscripcion(subscriptionId),
          hasLength(1),
        );
      } finally {
        await service.close();
      }
    },
  );

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
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar suscripción').last);
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      expect((await service.obtenerSuscripciones()).single.activa, isFalse);
    });
    expect(find.text('Spotify'), findsOneWidget);
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
