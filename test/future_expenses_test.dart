import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart'
    show
        IconButton,
        MaterialApp,
        Scaffold,
        Scrollable,
        Size,
        SizedBox,
        TextFormField,
        ValueKey;
import 'package:flutter_test/flutter_test.dart';

import 'package:finanzas_app/database/app_database.dart';
import 'package:finanzas_app/models/future_expense.dart';
import 'package:finanzas_app/screens/future_expenses/future_expenses_screen.dart';
import 'package:finanzas_app/screens/home/home_screen.dart';
import 'package:finanzas_app/services/database_service.dart';
import 'package:finanzas_app/utils/future_expense_calculator.dart';
import 'package:finanzas_app/utils/money_format.dart';

void main() {
  test('calcula recomendaciones por frecuencia y no excede la meta', () {
    final now = DateTime(2026, 10, 1);
    final daily = calculateFutureExpenseProgress(
      targetAmount: 160000,
      reservedAmount: 0,
      frequency: FutureExpenseFrequency.daily,
      targetDate: DateTime(2026, 10, 21),
      now: now,
    );
    final weekly = calculateFutureExpenseProgress(
      targetAmount: 210,
      reservedAmount: 0,
      frequency: FutureExpenseFrequency.weekly,
      targetDate: DateTime(2026, 10, 16),
      now: now,
    );
    final fortnightly = calculateFutureExpenseProgress(
      targetAmount: 200,
      reservedAmount: 50,
      frequency: FutureExpenseFrequency.fortnightly,
      targetDate: DateTime(2026, 10, 31),
      now: now,
    );
    final monthly = calculateFutureExpenseProgress(
      targetAmount: 300,
      reservedAmount: 0,
      frequency: FutureExpenseFrequency.monthly,
      targetDate: DateTime(2027, 1, 1),
      now: now,
    );
    final once = calculateFutureExpenseProgress(
      targetAmount: 250,
      reservedAmount: 25,
      frequency: FutureExpenseFrequency.once,
      targetDate: DateTime(2026, 10, 21),
      now: now,
    );
    final complete = calculateFutureExpenseProgress(
      targetAmount: 160000,
      reservedAmount: 180000,
      frequency: FutureExpenseFrequency.daily,
      targetDate: DateTime(2026, 9, 1),
      now: now,
    );
    final overdue = calculateFutureExpenseProgress(
      targetAmount: 300,
      reservedAmount: 100,
      frequency: FutureExpenseFrequency.weekly,
      targetDate: DateTime(2026, 9, 30),
      now: now,
    );

    expect(daily.periodsRemaining, 20);
    expect(daily.recommendedPerPeriod, 8000);
    expect(weekly.periodsRemaining, 3);
    expect(weekly.recommendedPerPeriod, 70);
    expect(fortnightly.periodsRemaining, 2);
    expect(fortnightly.recommendedPerPeriod, 75);
    expect(monthly.periodsRemaining, 3);
    expect(monthly.recommendedPerPeriod, 100);
    expect(once.recommendedPerPeriod, 225);
    expect(complete.isComplete, isTrue);
    expect(complete.isOverdue, isFalse);
    expect(complete.recommendedPerPeriod, 0);
    expect(overdue.isOverdue, isTrue);
    expect(overdue.recommendedPerPeriod, 200);
  });

  test('migra v7 sin perder ingresos existentes', () async {
    final executor = NativeDatabase.memory(
      setup: (database) {
        database.execute('''
          CREATE TABLE ingresos (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            monto REAL NOT NULL,
            tipo TEXT NOT NULL DEFAULT 'ingreso',
            fecha INTEGER NOT NULL,
            descripcion TEXT
          )
        ''');
        database.execute('''
          CREATE TABLE gastos (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            monto REAL NOT NULL,
            categoria TEXT NOT NULL,
            fecha INTEGER NOT NULL,
            nota TEXT
          )
        ''');
        database.execute('''
          CREATE TABLE pagos_deuda (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            deuda_id INTEGER NOT NULL,
            monto REAL NOT NULL,
            fecha INTEGER NOT NULL,
            operation_id TEXT
          )
        ''');
        database.execute('''
          CREATE TABLE movimientos_ahorro (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            monto REAL NOT NULL,
            tipo TEXT NOT NULL,
            fecha INTEGER NOT NULL
          )
        ''');
        database.execute('''
          CREATE TABLE prestamos_terceros (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            persona TEXT NOT NULL,
            monto_principal REAL NOT NULL,
            fecha_entrega INTEGER NOT NULL,
            fecha_devolucion_acordada INTEGER NOT NULL
          )
        ''');
        database.execute('''
          CREATE TABLE movimientos_prestamo (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            prestamo_id INTEGER NOT NULL,
            tipo TEXT NOT NULL,
            monto REAL NOT NULL,
            fecha INTEGER NOT NULL,
            operation_id TEXT NOT NULL UNIQUE
          )
        ''');
        final date = DateTime(2026, 10, 1).millisecondsSinceEpoch;
        database.execute(
          "INSERT INTO ingresos (monto, tipo, fecha, descripcion) "
          "VALUES (500, 'ingreso', $date, 'Guardado antes de migrar')",
        );
        database.execute('PRAGMA user_version = 7');
      },
    );
    final database = AppDatabase(executor);
    final service = DatabaseService(database);
    try {
      expect(
        (await service.obtenerIngresos()).single.descripcion,
        'Guardado antes de migrar',
      );
      final planId = await service.crearPlanGastoFuturo(
        nombre: 'Pasajes',
        categoria: 'Transportes',
        montoNecesario: 100,
        montoPlaneado: 100,
        frecuencia: FutureExpenseFrequency.daily.storageValue,
        fechaObjetivo: DateTime(2026, 10, 10),
      );
      expect(
        (await service.obtenerPlanesGastosFuturos()).single.plan.id,
        planId,
      );
    } finally {
      await database.close();
    }
  });

  test(
    'reserva transaccional, idempotencia, liberación y saldo insuficiente',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final service = DatabaseService(database);
      addTearDown(database.close);
      final today = DateTime(2026, 10, 15);
      await service.agregarIngreso(monto: 1000, fecha: today);
      final planId = await service.crearPlanGastoFuturo(
        nombre: 'Almuerzos',
        categoria: 'Comidaaaa',
        montoNecesario: 200,
        montoPlaneado: 200,
        frecuencia: FutureExpenseFrequency.weekly.storageValue,
        fechaObjetivo: DateTime(2026, 11, 1),
        fechaInicio: today,
        notas: 'Días de oficina',
      );

      expect(await service.obtenerSaldoDisponible(), 1000);
      await service.actualizarPlanGastoFuturo(
        id: planId,
        nombre: 'Almuerzos de oficina',
        categoria: 'Comidaaaa',
        montoNecesario: 240,
        montoPlaneado: 200,
        frecuencia: FutureExpenseFrequency.weekly.storageValue,
        fechaObjetivo: DateTime(2026, 11, 8),
        fechaInicio: today,
        notas: 'Con postre',
      );
      var summary = (await service.obtenerPlanesGastosFuturos()).single;
      expect(summary.plan.name, 'Almuerzos de oficina');
      expect(summary.plan.targetAmount, 240);
      expect(summary.plan.notes, 'Con postre');
      expect(summary.reservedAmount, 0);
      expect(await service.obtenerSaldoDisponible(), 1000);

      final reservationId = await service.registrarReservaGastoFuturo(
        planId: planId,
        monto: 100,
        fecha: today,
        operationId: 'future-reserve-1',
      );
      expect(
        await service.registrarReservaGastoFuturo(
          planId: planId,
          monto: 100,
          fecha: today,
          operationId: 'future-reserve-1',
        ),
        reservationId,
      );
      summary = (await service.obtenerPlanesGastosFuturos()).single;
      expect(summary.reservedAmount, 100);
      expect(summary.amountMissing, 140);
      expect(await service.obtenerSaldoDisponible(), 900);

      final otherPlan = await service.crearPlanGastoFuturo(
        nombre: 'Servicios',
        categoria: 'Otros',
        montoNecesario: 1000,
        montoPlaneado: 1000,
        frecuencia: FutureExpenseFrequency.once.storageValue,
        fechaObjetivo: DateTime(2026, 11, 1),
      );
      await expectLater(
        service.registrarReservaGastoFuturo(
          planId: otherPlan,
          monto: 901,
          fecha: today,
          operationId: 'future-reserve-insufficient',
        ),
        throwsA(
          isA<DatabaseServiceException>().having(
            (error) => error.causa,
            'causa',
            isA<FutureExpenseInsufficientBalance>(),
          ),
        ),
      );
      expect(await service.obtenerSaldoDisponible(), 900);
      expect(
        await service.obtenerMovimientosReservaGastoFuturo(otherPlan),
        isEmpty,
      );

      await expectLater(
        service.eliminarPlanGastoFuturo(planId),
        throwsA(isA<DatabaseServiceException>()),
      );
      await service.liberarReservaGastoFuturo(
        planId: planId,
        monto: 40,
        fecha: today,
        operationId: 'future-release-1',
      );
      expect(await service.obtenerSaldoDisponible(), 940);
      await service.liberarReservaGastoFuturo(
        planId: planId,
        monto: 60,
        fecha: today,
        operationId: 'future-release-2',
      );
      expect(await service.obtenerSaldoDisponible(), 1000);
      await service.actualizarEstadoPlanGastoFuturo(
        id: planId,
        estado: FutureExpenseStatus.archived,
      );
      expect(
        (await service.obtenerPlanesGastosFuturos())
            .singleWhere((item) => item.plan.id == planId)
            .plan
            .status,
        FutureExpenseStatus.archived,
      );
      await service.eliminarPlanGastoFuturo(planId);
      final movements = await database
          .select(database.movimientosReservaGastoFuturo)
          .get();
      expect(movements, hasLength(3));
      expect(movements.every((item) => item.gastoFuturoId == null), isTrue);
      expect(await service.obtenerSaldoDisponible(), 1000);
    },
  );

  test('conserva planes y reservas al reabrir la base de datos', () async {
    final directory = await Directory.systemTemp.createTemp(
      'finanzas_app_future_expenses_',
    );
    final file = File('${directory.path}${Platform.pathSeparator}future.db');
    final today = DateTime(2026, 10, 15);
    var database = AppDatabase(NativeDatabase(file));
    var service = DatabaseService(database);
    await service.agregarIngreso(monto: 600, fecha: today);
    final planId = await service.crearPlanGastoFuturo(
      nombre: 'Pasajes',
      categoria: 'Transportes',
      montoNecesario: 300,
      montoPlaneado: 300,
      frecuencia: FutureExpenseFrequency.daily.storageValue,
      fechaObjetivo: DateTime(2026, 11, 1),
    );
    await service.registrarReservaGastoFuturo(
      planId: planId,
      monto: 50,
      fecha: today,
      operationId: 'future-persistent-reservation',
    );
    await service.close();

    database = AppDatabase(NativeDatabase(file));
    service = DatabaseService(database);
    try {
      final summary = (await service.obtenerPlanesGastosFuturos()).single;
      expect(summary.plan.name, 'Pasajes');
      expect(summary.reservedAmount, 50);
      expect(
        await service.obtenerMovimientosReservaGastoFuturo(summary.plan.id),
        hasLength(1),
      );
      expect(await service.obtenerSaldoDisponible(), 550);
    } finally {
      await service.close();
      await directory.delete(recursive: true);
    }
  });

  testWidgets('crea un plan y reserva solo tras confirmar', (tester) async {
    _setMobileSize(tester);
    final database = AppDatabase(NativeDatabase.memory());
    final service = DatabaseService(database);
    addTearDown(database.close);
    final today = DateTime.now();
    await service.agregarIngreso(monto: 1000, fecha: today);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FutureExpensesScreen(databaseService: service)),
      ),
    );
    await _pumpUntilFound(
      tester,
      find.text('Todavía no hay planes por aquí. Crea uno para empezar.'),
    );

    await tester.tap(find.byKey(const ValueKey('future-expense-add')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('future-expense-name')),
      'Pasajes',
    );
    await tester.enterText(
      find.byKey(const ValueKey('future-expense-target')),
      '160000',
    );
    await tester.ensureVisible(find.text('Guardar plan'));
    await tester.tap(find.text('Guardar plan'));
    await tester.pumpAndSettle();
    await _pumpUntilFound(tester, find.text('Pasajes'));

    final savedPlan = (await service.obtenerPlanesGastosFuturos()).single.plan;
    final planId = savedPlan.id;
    expect(savedPlan.plannedAmount, 160000);
    expect(await service.obtenerSaldoDisponible(), 1000);
    expect(await service.obtenerIngresos(), hasLength(1));
    expect(await service.obtenerGastos(), isEmpty);

    final reserveButton = find.byKey(
      ValueKey('future-expense-reserve-$planId'),
    );
    expect(reserveButton, findsOneWidget);
    expect(find.text('Hacer simulación'), findsNothing);
    expect(find.text('Solo simular'), findsNothing);
    await tester.scrollUntilVisible(
      reserveButton,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(reserveButton);
    await tester.pumpAndSettle();
    expect(find.text('Confirmar reserva'), findsNWidgets(2));
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('future-expense-reservation-dialog')),
        matching: find.text('Pasajes'),
      ),
      findsNWidgets(2),
    );
    expect(find.text('Dinero disponible antes de reservar'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('future-expense-reserve-amount')),
      '1000',
    );
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(await service.obtenerSaldoDisponible(), 1000);
    expect(await service.obtenerMovimientosReservaGastoFuturo(planId), isEmpty);
    expect(await service.obtenerIngresos(), hasLength(1));
    expect(await service.obtenerGastos(), isEmpty);

    await tester.scrollUntilVisible(
      reserveButton,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(reserveButton);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('future-expense-reserve-amount')),
      '1001',
    );
    final confirmReservation = find.byKey(
      const ValueKey('future-expense-confirm-reservation'),
    );
    final reserveAmount = find.byKey(
      const ValueKey('future-expense-reserve-amount'),
    );
    await tester.ensureVisible(confirmReservation);
    await tester.tap(confirmReservation);
    await tester.pumpAndSettle();
    expect(find.textContaining('Te faltan'), findsWidgets);
    expect(await service.obtenerSaldoDisponible(), 1000);
    expect(await service.obtenerMovimientosReservaGastoFuturo(planId), isEmpty);

    await tester.enterText(reserveAmount, '1000');
    expect(
      tester.widget<TextFormField>(reserveAmount).controller!.text,
      '1.000',
    );
    await tester.ensureVisible(confirmReservation);
    await tester.tap(confirmReservation);
    await tester.tap(confirmReservation);
    await tester.pumpAndSettle();
    await _pumpUntilFound(
      tester,
      find.text('Reserva confirmada. El dinero ya está apartado.'),
    );

    final movements = await service.obtenerMovimientosReservaGastoFuturo(
      planId,
    );
    expect(movements, hasLength(1));
    expect(movements.single.monto, 1000);
    expect(
      (await service.obtenerPlanesGastosFuturos()).single.reservedAmount,
      1000,
    );
    expect(await service.obtenerSaldoDisponible(), 0);
    expect(await service.obtenerIngresos(), hasLength(1));
    expect(await service.obtenerGastos(), isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('edita y archiva planes desde Gastos futuros', (tester) async {
    _setMobileSize(tester);
    final database = AppDatabase(NativeDatabase.memory());
    final service = DatabaseService(database);
    addTearDown(database.close);
    final planId = await service.crearPlanGastoFuturo(
      nombre: 'Salida',
      categoria: 'Otros',
      montoNecesario: 100,
      montoPlaneado: 100,
      frecuencia: FutureExpenseFrequency.once.storageValue,
      fechaObjetivo: DateTime(2026, 11, 15),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FutureExpensesScreen(databaseService: service)),
      ),
    );
    await _pumpUntilFound(tester, find.text('Salida'));

    final editOptions = find.byTooltip('Más opciones para Salida');
    await tester.ensureVisible(editOptions);
    await tester.tap(editOptions);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar plan'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('future-expense-name')),
      'Salida de sábado',
    );
    await tester.ensureVisible(find.text('Guardar cambios'));
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
    await _pumpUntilFound(
      tester,
      find.byTooltip('Más opciones para Salida de sábado'),
    );
    expect(
      (await service.obtenerPlanesGastosFuturos()).single.plan.name,
      'Salida de sábado',
    );

    final updatedOptions = find.byTooltip('Más opciones para Salida de sábado');
    await tester.ensureVisible(updatedOptions);
    await tester.tap(updatedOptions);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archivar'));
    await tester.pumpAndSettle();
    expect(
      (await service.obtenerPlanesGastosFuturos())
          .singleWhere((item) => item.plan.id == planId)
          .plan
          .status,
      FutureExpenseStatus.archived,
    );
    await tester.ensureVisible(find.text('Archivados'));
    await tester.tap(find.text('Archivados'));
    await tester.pumpAndSettle();
    await _pumpUntilFound(tester, find.text('Salida de sábado'));
    final archivedPlan = find.byKey(ValueKey('future-expense-$planId'));
    await tester.scrollUntilVisible(
      archivedPlan,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(archivedPlan, findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('el dashboard informa y solo ofrece ir a todos los planes', (
    tester,
  ) async {
    _setMobileSize(tester);
    final database = AppDatabase(NativeDatabase.memory());
    final service = DatabaseService(database);
    addTearDown(database.close);
    await service.crearPlanGastoFuturo(
      nombre: 'Comida para gatos',
      categoria: 'Comida para bichos',
      montoNecesario: 80000,
      montoPlaneado: 60000,
      frecuencia: FutureExpenseFrequency.monthly.storageValue,
      fechaObjetivo: DateTime(2026, 11, 15),
    );
    var visits = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeScreen(
            databaseService: service,
            onViewFutureExpenses: () => visits++,
          ),
        ),
      ),
    );
    await _pumpUntilFound(tester, find.text('Comida para gatos'));
    final summary = find.byKey(const ValueKey('home-future-expenses'));
    expect(
      find.descendant(of: summary, matching: find.byType(IconButton)),
      findsNothing,
    );
    expect(find.text('Reservado: ${formatMoney(0)}'), findsOneWidget);
    expect(find.text('Falta: ${formatMoney(80000)}'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const ValueKey('home-future-expenses-see-all')),
    );
    await tester.tap(
      find.byKey(const ValueKey('home-future-expenses-see-all')),
    );
    expect(visits, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
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

void _setMobileSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
