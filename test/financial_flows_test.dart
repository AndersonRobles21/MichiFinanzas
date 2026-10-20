import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show ValueKey;
import 'package:flutter/material.dart'
    show MaterialApp, Scaffold, Size, SizedBox, Text;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:finanzas_app/database/app_database.dart';
import 'package:finanzas_app/models/future_expense.dart';
import 'package:finanzas_app/models/income_type.dart';
import 'package:finanzas_app/models/money_medium.dart';
import 'package:finanzas_app/screens/home/home_screen.dart';
import 'package:finanzas_app/screens/savings/savings_screen.dart';
import 'package:finanzas_app/services/app_settings_service.dart';
import 'package:finanzas_app/services/database_service.dart';
import 'package:finanzas_app/utils/date_format.dart';
import 'package:finanzas_app/utils/money_format.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('formatea miles y convierte el texto a valores numéricos', () {
    expect(formatAmount(1500), '1.500');
    expect(formatAmount(50000), '50.000');
    expect(formatAmount(600000), '600.000');
    expect(formatAmount(1250000), '1.250.000');
    expect(formatAmount(25.75), '25,75');
    expect(tryParseMoney('1.250.000'), 1250000);
    expect(tryParseMoney('1.250.000,50'), 1250000.5);
    expect(tryParseMoney('25,75'), 25.75);
    expect(tryParseMoney('1,234'), isNull);
    expect(tryParseMoney(List.filled(400, '9').join()), isNull);

    const formatter = ThousandsInputFormatter();
    final formatted = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(
        text: '1250000',
        selection: TextSelection.collapsed(offset: 7),
      ),
    );
    expect(formatted.text, '1.250.000');
    expect(parseMoney(formatted.text), 1250000);
    final edited = formatter.formatEditUpdate(
      formatted,
      const TextEditingValue(
        text: '1250000',
        selection: TextSelection.collapsed(offset: 3),
      ),
    );
    expect(edited.text, '1.250.000');
    expect(edited.selection.extentOffset, 4);
    final cursorAtStart = formatter.formatEditUpdate(
      formatted,
      const TextEditingValue(
        text: '1.250.000',
        selection: TextSelection.collapsed(offset: 0),
      ),
    );
    expect(cursorAtStart.selection.extentOffset, 0);
  });

  test('formatea la fecha local en español', () {
    expect(
      formatSpanishLongDate(DateTime(2026, 10, 13)),
      'Martes, 13 de octubre de 2026',
    );
  });

  test('migra de esquema 3 conservando los registros financieros', () async {
    final existingExecutor = NativeDatabase.memory(
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
          CREATE TABLE deudas (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            ingreso_id INTEGER REFERENCES ingresos(id) ON DELETE SET NULL,
            nombre TEXT NOT NULL,
            monto_original REAL NOT NULL,
            cuota REAL NOT NULL,
            cuotas_totales INTEGER NOT NULL,
            cuotas_pagadas INTEGER NOT NULL DEFAULT 0,
            fecha_proximo_pago INTEGER
          )
        ''');
        database.execute('''
          CREATE TABLE pagos_deuda (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            deuda_id INTEGER NOT NULL REFERENCES deudas(id) ON DELETE CASCADE,
            monto REAL NOT NULL,
            fecha INTEGER NOT NULL
          )
        ''');
        final date = DateTime(2026, 10, 13).millisecondsSinceEpoch;
        database.execute(
          "INSERT INTO ingresos (monto, tipo, fecha, descripcion) "
          "VALUES (600, 'sueldo', $date, 'Quincena')",
        );
        database.execute(
          "INSERT INTO gastos (nombre, monto, categoria, fecha) "
          "VALUES ('Mercado', 50, 'Comida', $date)",
        );
        database.execute(
          "INSERT INTO gastos (nombre, monto, categoria, fecha) "
          "VALUES ('Arena', 25, 'Mascotas', $date)",
        );
        database.execute(
          "INSERT INTO deudas "
          "(nombre, monto_original, cuota, cuotas_totales, cuotas_pagadas) "
          "VALUES ('Cuota antigua', 100, 10, 10, 4)",
        );
        database.execute(
          "INSERT INTO pagos_deuda (deuda_id, monto, fecha) "
          "VALUES (1, 10, $date)",
        );
        database.execute('PRAGMA user_version = 3');
      },
    );
    final database = AppDatabase(existingExecutor);
    final service = DatabaseService(database);
    try {
      expect((await service.obtenerIngresos()).single.descripcion, 'Quincena');
      final migratedExpenses = await service.obtenerGastos();
      expect(migratedExpenses, hasLength(2));
      final migratedFood = migratedExpenses.singleWhere((item) => item.id == 1);
      expect(migratedFood.nombre, 'Mercado');
      expect(migratedFood.monto, 50);
      expect(migratedFood.categoria, 'Comidaaaa');
      final storedDate =
          (await database
                  .customSelect(
                    "SELECT fecha FROM gastos WHERE nombre = 'Mercado'",
                  )
                  .getSingle())
              .read<int>('fecha');
      expect(storedDate, DateTime(2026, 10, 13).millisecondsSinceEpoch);
      final customExpense = migratedExpenses.singleWhere(
        (item) => item.id == 2,
      );
      expect(customExpense.nombre, 'Arena');
      expect(customExpense.monto, 25);
      expect(customExpense.categoria, 'Mascotas');
      expect((await service.obtenerDeudas()).single.nombre, 'Cuota antigua');
      expect((await service.obtenerDeudas()).single.cuotasPagadasDeclaradas, 4);
      expect(await service.obtenerTodosLosPagosDeuda(), hasLength(1));
      expect(await service.obtenerPrestamosTerceros(), isEmpty);
      expect(await service.obtenerMovimientosPrestamo(), isEmpty);
      expect(await service.obtenerSaldoDisponible(), 515);

      await service.registrarAporteAhorro(
        monto: 100,
        fecha: DateTime(2026, 10, 13),
      );
      expect(await service.obtenerTotalAhorros(), 100);
      expect(await service.obtenerSaldoDisponible(), 415);
      expect(await service.obtenerIngresos(), hasLength(1));
      expect(await service.obtenerGastos(), hasLength(2));
    } finally {
      await database.close();
    }
  });

  test('migra v8 sin asignar medios a movimientos históricos', () async {
    final date = DateTime(2026, 10, 13).millisecondsSinceEpoch;
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
          CREATE TABLE movimientos_prestamo (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            prestamo_id INTEGER NOT NULL,
            tipo TEXT NOT NULL,
            monto REAL NOT NULL,
            fecha INTEGER NOT NULL,
            operation_id TEXT NOT NULL
          )
        ''');
        database.execute('''
          CREATE TABLE movimientos_reserva_gasto_futuro (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            gasto_futuro_id INTEGER,
            nombre_plan TEXT NOT NULL,
            tipo TEXT NOT NULL,
            monto REAL NOT NULL,
            fecha INTEGER NOT NULL,
            operation_id TEXT NOT NULL
          )
        ''');
        database.execute(
          "INSERT INTO ingresos (monto, tipo, fecha, descripcion) "
          "VALUES (1000, 'sueldo', $date, 'Histórico')",
        );
        database.execute(
          "INSERT INTO gastos (nombre, monto, categoria, fecha) "
          "VALUES ('Compra', 20, 'Otros', $date)",
        );
        database.execute(
          "INSERT INTO pagos_deuda (deuda_id, monto, fecha) "
          "VALUES (1, 30, $date)",
        );
        database.execute(
          "INSERT INTO movimientos_ahorro (monto, tipo, fecha) "
          "VALUES (40, 'aporte', $date)",
        );
        database.execute(
          "INSERT INTO movimientos_prestamo "
          "(prestamo_id, tipo, monto, fecha, operation_id) "
          "VALUES (1, 'entrega', 50, $date, 'legacy-loan')",
        );
        database.execute(
          "INSERT INTO movimientos_reserva_gasto_futuro "
          "(nombre_plan, tipo, monto, fecha, operation_id) "
          "VALUES ('Meta', 'reserva', 60, $date, 'legacy-reserve')",
        );
        database.execute('PRAGMA user_version = 8');
      },
    );
    final database = AppDatabase(executor);
    final service = DatabaseService(database);
    try {
      final incomes = await service.obtenerIngresos();
      final expenses = await service.obtenerGastos();
      final payments = await service.obtenerTodosLosPagosDeuda();
      final savings = await service.obtenerMovimientosAhorro();
      final loans = await service.obtenerMovimientosPrestamo();
      final reservations = await service
          .obtenerTodosLosMovimientosReservaGastoFuturo();
      expect(incomes.single.monto, 1000);
      expect(expenses.single.monto, 20);
      expect(payments.single.monto, 30);
      expect(savings.single.monto, 40);
      expect(loans.single.monto, 50);
      expect(reservations.single.monto, 60);
      expect(incomes.single.medio, isNull);
      expect(expenses.single.medio, isNull);
      expect(payments.single.medio, isNull);
      expect(savings.single.medio, isNull);
      expect(loans.single.medio, isNull);
      expect(reservations.single.medio, isNull);

      final balances = await service.obtenerSaldosPorMedio();
      expect(balances.cash, 0);
      expect(balances.digital, 0);
      expect(balances.unclassified, 800);
      expect(balances.total, 800);
      expect(await service.obtenerSaldoDisponible(), balances.total);
    } finally {
      await database.close();
    }
  });

  test(
    'actualiza y elimina ingresos sin duplicarlos ni desincronizar préstamos',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final service = DatabaseService(database);
      final date = DateTime(2026, 10, 15);
      try {
        final salaryId = await service.agregarIngreso(
          monto: 1000,
          fecha: date,
          descripcion: 'Sueldo',
          tipo: IncomeType.salary.storageValue,
          medio: MoneyMedium.cash,
        );
        final extraId = await service.agregarIngreso(
          monto: 500,
          fecha: date,
          descripcion: 'Venta',
          tipo: IncomeType.extra.storageValue,
          medio: MoneyMedium.digital,
        );
        expect(await service.obtenerSaldoDisponible(), 1500);
        var balances = await service.obtenerSaldosPorMedio();
        expect(balances.cash, 0);
        expect(balances.digital, 0);
        expect(balances.unclassified, 1500);
        await service.distribuirSaldoDisponible(efectivo: 1000, digital: 500);

        await service.actualizarIngreso(
          id: salaryId,
          monto: 1200,
          fecha: date.add(const Duration(days: 1)),
          descripcion: 'Sueldo actualizado',
          tipo: IncomeType.salary.storageValue,
          medio: MoneyMedium.digital,
        );
        var incomes = await service.obtenerIngresos();
        expect(incomes, hasLength(2));
        expect(
          incomes.singleWhere((item) => item.id == salaryId).tipo,
          IncomeType.salary.storageValue,
        );
        balances = await service.obtenerSaldosPorMedio();
        expect(balances.cash, 1000);
        expect(balances.digital, 500);
        expect(balances.unclassified, 200);
        expect(balances.total, 1700);

        await expectLater(
          service.eliminarIngreso(extraId),
          throwsA(isA<DatabaseServiceException>()),
        );
        await service.distribuirSaldoDisponible(efectivo: 1000, digital: 200);
        await service.eliminarIngreso(extraId);
        incomes = await service.obtenerIngresos();
        expect(incomes, hasLength(1));
        expect(incomes.single.id, salaryId);
        expect(await service.obtenerSaldoDisponible(), 1200);

        final loan = await service.registrarPrestamo(
          nombre: 'Crédito personal',
          monto: 400,
          fechaRecepcion: date,
          cuotasTotales: 2,
          fechaPrimerPago: date.add(const Duration(days: 30)),
          medio: MoneyMedium.cash,
        );
        await service.registrarPagoDeuda(
          deudaId: loan.deudaId,
          monto: 100,
          fecha: date,
          operationId: 'income-edit-payment',
          medio: MoneyMedium.cash,
        );
        await service.actualizarIngreso(
          id: loan.ingresoId,
          monto: 450,
          fecha: date,
          descripcion: 'Crédito actualizado',
          tipo: IncomeType.loan.storageValue,
          medio: MoneyMedium.digital,
        );
        final debt = (await service.obtenerDeudas()).single;
        expect(debt.montoOriginal, 450);
        expect(debt.cuota, 225);
        expect(debt.cuotasPagadas, 0);
        expect(debt.nombre, 'Crédito actualizado');
        expect(await service.obtenerSaldoDisponible(), 1550);

        await expectLater(
          service.actualizarIngreso(
            id: loan.ingresoId,
            monto: 90,
            fecha: date,
            descripcion: 'Demasiado bajo',
            tipo: IncomeType.loan.storageValue,
            medio: MoneyMedium.cash,
          ),
          throwsA(isA<DatabaseServiceException>()),
        );
        expect((await service.obtenerIngresos()).last.monto, 450);

        await service.eliminarIngreso(loan.ingresoId);
        expect(await service.obtenerIngresos(), hasLength(1));
        expect(await service.obtenerDeudas(), isEmpty);
        expect(await service.obtenerTodosLosPagosDeuda(), isEmpty);
        expect(await service.obtenerSaldoDisponible(), 1200);
      } finally {
        await database.close();
      }
    },
  );

  testWidgets('crea, edita y elimina ingresos desde el historial de Inicio', (
    tester,
  ) async {
    await _prepareTemporaryStorage(tester);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final database = AppDatabase(NativeDatabase.memory());
    final service = DatabaseService(database);
    await tester.runAsync(
      () => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: HomeScreen(databaseService: service)),
        ),
      ),
    );
    await _pumpUntilFound(tester, find.text('Dinero disponible'));

    await _recordIncome(tester, 'Sueldo', 'Quincena', '600');
    await _pumpUntilMonthlyReceived(tester, 600);
    final incomeActions = find.byTooltip('Acciones del ingreso');
    await tester.ensureVisible(incomeActions);
    await tester.tap(incomeActions);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('income-description')),
      'Sueldo corregido',
    );
    await tester.enterText(find.byKey(const ValueKey('income-amount')), '800');
    await tester.tap(find.byKey(const ValueKey('income-type')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(IncomeType.extra.label).last);
    await tester.pumpAndSettle();
    final saveChanges = find.text('Guardar cambios');
    await tester.ensureVisible(saveChanges);
    await tester.tap(saveChanges);
    await tester.pumpAndSettle();
    await _pumpUntilMonthlyReceived(tester, 800);

    await tester.runAsync(() async {
      final incomes = await service.obtenerIngresos();
      expect(incomes, hasLength(1));
      expect(incomes.single.descripcion, 'Sueldo corregido');
      expect(incomes.single.monto, 800);
      expect(incomes.single.tipo, IncomeType.extra.storageValue);
      expect(await service.obtenerSaldoDisponible(), 800);
    });

    await tester.ensureVisible(incomeActions);
    await tester.tap(incomeActions);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    expect(find.text('¿Eliminar este ingreso?'), findsOneWidget);
    await tester.tap(find.text('Eliminar ingreso'));
    await tester.pumpAndSettle();
    await _pumpUntilMonthlyReceived(tester, 0);
    await tester.runAsync(() async {
      expect(await service.obtenerIngresos(), isEmpty);
      expect(await service.obtenerSaldoDisponible(), 0);
    });
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() => service.close());
  });

  testWidgets('distribuye el saldo desde Inicio y persiste la asignación', (
    tester,
  ) async {
    await _prepareTemporaryStorage(tester);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final database = AppDatabase(NativeDatabase.memory());
    final service = DatabaseService(database);
    await tester.runAsync(
      () => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: HomeScreen(databaseService: service)),
        ),
      ),
    );
    await _pumpUntilFound(tester, find.text('Dinero disponible'));
    await _recordIncome(tester, 'Sueldo', 'Quincena', '600');
    await _pumpUntilMonthlyReceived(tester, 600);
    expect(find.text('Medio de recepción'), findsNothing);

    final distributeButton = find.byKey(
      const ValueKey('distribute-available-balance'),
    );
    await tester.ensureVisible(distributeButton);
    await tester.tap(distributeButton);
    await tester.pumpAndSettle();
    await _pumpUntilFound(tester, find.text('Distribuir dinero disponible'));
    await tester.enterText(
      find.byKey(const ValueKey('distribution-cash')),
      '601',
    );
    await tester.enterText(
      find.byKey(const ValueKey('distribution-digital')),
      '0',
    );
    await tester.ensureVisible(find.text('Guardar distribución'));
    await tester.tap(find.text('Guardar distribución'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.text('La suma no puede superar el total disponible.'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('distribution-cash')),
      '400',
    );
    await tester.enterText(
      find.byKey(const ValueKey('distribution-digital')),
      '200',
    );
    await tester.ensureVisible(find.text('Guardar distribución'));
    await tester.tap(find.text('Guardar distribución'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.runAsync(() async {
      final balances = await service.obtenerSaldosPorMedio();
      expect(balances.cash, 400);
      expect(balances.digital, 200);
      expect(balances.unclassified, 0);
      expect(await service.obtenerIngresos(), hasLength(1));
      expect(await service.obtenerGastos(), isEmpty);
    });
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() => service.close());
    expect(tester.takeException(), isNull);
  });

  testWidgets('conserva la distribución al reabrir la base local', (
    tester,
  ) async {
    await _prepareTemporaryStorage(tester);
    await tester.runAsync(() async {
      var service = DatabaseService(AppDatabase());
      await service.agregarIngreso(monto: 600, fecha: DateTime(2026, 10, 15));
      await service.distribuirSaldoDisponible(efectivo: 400, digital: 200);
      await service.close();

      service = DatabaseService(AppDatabase());
      final balances = await service.obtenerSaldosPorMedio();
      expect(balances.cash, 400);
      expect(balances.digital, 200);
      expect(balances.total, 600);
      await service.close();
    });
  });

  test('distribuye el saldo y concilia los movimientos por canal', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final service = DatabaseService(database);
    final date = DateTime(2026, 10, 15);
    try {
      await service.agregarIngreso(
        monto: 1000,
        fecha: date,
        medio: MoneyMedium.cash,
      );
      await service.agregarIngreso(
        monto: 500,
        fecha: date,
        medio: MoneyMedium.digital,
      );
      await service.distribuirSaldoDisponible(efectivo: 1000, digital: 500);
      await expectLater(
        service.distribuirSaldoDisponible(efectivo: 1000, digital: 501),
        throwsA(isA<DatabaseServiceException>()),
      );
      await service.agregarGasto(
        nombre: 'Compra en efectivo',
        monto: 50,
        categoria: 'Otros',
        fecha: date,
        medio: MoneyMedium.cash,
      );
      await service.agregarGasto(
        nombre: 'Compra digital',
        monto: 100,
        categoria: 'Otros',
        fecha: date,
        medio: MoneyMedium.digital,
      );
      final debtId = await service.agregarDeuda(
        nombre: 'Deuda',
        montoOriginal: 300,
        cuota: 100,
        cuotasTotales: 3,
      );
      await service.registrarPagoDeuda(
        deudaId: debtId,
        monto: 25,
        fecha: date,
        operationId: 'medium-payment',
        medio: MoneyMedium.digital,
      );
      await service.registrarAporteAhorro(
        monto: 75,
        fecha: date,
        medio: MoneyMedium.cash,
      );
      await service.retirarAhorro(
        monto: 25,
        fecha: date,
        medio: MoneyMedium.digital,
      );
      final loanId = await service.registrarPrestamoTercero(
        persona: 'Amiga',
        monto: 100,
        fechaEntrega: date,
        fechaDevolucionAcordada: date.add(const Duration(days: 30)),
        operationId: 'medium-loan',
        medio: MoneyMedium.cash,
      );
      await service.registrarDevolucionPrestamo(
        prestamoId: loanId,
        monto: 40,
        fecha: date,
        operationId: 'medium-return',
        medio: MoneyMedium.digital,
      );
      final planId = await service.crearPlanGastoFuturo(
        nombre: 'Meta',
        categoria: 'Otros',
        montoNecesario: 200,
        montoPlaneado: 200,
        frecuencia: FutureExpenseFrequency.monthly.storageValue,
        fechaObjetivo: date.add(const Duration(days: 30)),
      );
      await service.registrarReservaGastoFuturo(
        planId: planId,
        monto: 50,
        fecha: date,
        operationId: 'medium-reserve',
        medio: MoneyMedium.digital,
      );
      await service.liberarReservaGastoFuturo(
        planId: planId,
        monto: 10,
        fecha: date,
        operationId: 'medium-release',
        medio: MoneyMedium.cash,
      );

      final balances = await service.obtenerSaldosPorMedio();
      expect(balances.cash, 785);
      expect(balances.digital, 390);
      expect(balances.unclassified, 0);
      expect(balances.cash + balances.digital, 1175);
      expect(balances.total, 1175);
      expect(await service.obtenerSaldoDisponible(), balances.total);
    } finally {
      await database.close();
    }
  });

  test(
    'cuenta cuatro abonos reales y hace idempotentes los reintentos',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final service = DatabaseService(database);
      final paymentDate = DateTime(2026, 10, 15);
      try {
        await service.agregarIngreso(monto: 2000000, fecha: paymentDate);
        await service.distribuirSaldoDisponible(efectivo: 2000000, digital: 0);
        final debtId = await service.agregarDeuda(
          nombre: 'Crédito de prueba',
          montoOriginal: 1700000,
          cuota: 170000,
          cuotasTotales: 10,
        );

        for (var index = 0; index < 4; index++) {
          await service.registrarPagoDeuda(
            deudaId: debtId,
            monto: 170000,
            fecha: paymentDate.add(Duration(days: index)),
            operationId: 'installment-$index',
            medio: MoneyMedium.cash,
          );
        }

        var payments = await service.obtenerPagosDeuda(debtId);
        var debt = (await service.obtenerDeudas()).single;
        expect(
          payments.fold<double>(0, (sum, payment) => sum + payment.monto),
          680000,
        );
        expect(debt.cuotasPagadas, 4);
        expect(debt.montoOriginal - 680000, 1020000);
        expect(await service.obtenerSaldoDisponible(), 1320000);

        final originalPaymentId = payments.first.id;
        final replayedPaymentId = await service.registrarPagoDeuda(
          deudaId: debtId,
          monto: payments.first.monto,
          fecha: payments.first.fecha,
          operationId: 'installment-0',
          medio: MoneyMedium.cash,
        );
        expect(replayedPaymentId, originalPaymentId);
        expect(await service.obtenerPagosDeuda(debtId), hasLength(4));
        expect(await service.obtenerSaldoDisponible(), 1320000);

        await expectLater(
          service.registrarPagoDeuda(
            deudaId: debtId,
            monto: 160000,
            fecha: payments.first.fecha,
            operationId: 'installment-0',
            medio: MoneyMedium.cash,
          ),
          throwsA(isA<DatabaseServiceException>()),
        );

        await service.registrarPagoDeuda(
          deudaId: debtId,
          monto: 170000,
          fecha: payments.first.fecha,
          operationId: 'distinct-payment-same-amount-and-date',
          medio: MoneyMedium.cash,
        );
        payments = await service.obtenerPagosDeuda(debtId);
        expect(payments, hasLength(5));
        expect(await service.obtenerSaldoDisponible(), 1150000);
      } finally {
        await database.close();
      }
    },
  );

  test(
    'calcula abonos parciales e irregulares desde sus importes reales',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final service = DatabaseService(database);
      final date = DateTime(2026, 10, 15);
      try {
        await service.agregarIngreso(monto: 1000, fecha: date);
        await service.distribuirSaldoDisponible(efectivo: 1000, digital: 0);
        final debtId = await service.agregarDeuda(
          nombre: 'Deuda irregular',
          montoOriginal: 500,
          cuota: 120,
          cuotasTotales: 4,
        );
        const installments = [50.0, 70.0, 90.0];
        for (var index = 0; index < installments.length; index++) {
          await service.registrarPagoDeuda(
            deudaId: debtId,
            monto: installments[index],
            fecha: date.add(Duration(days: index)),
            operationId: 'irregular-$index',
            medio: MoneyMedium.cash,
          );
        }

        var debt = (await service.obtenerDeudas()).single;
        expect(debt.cuotasPagadas, 1);
        expect(debt.montoOriginal - 210, 290);
        expect(await service.obtenerSaldoDisponible(), 790);

        await service.registrarPagoDeuda(
          deudaId: debtId,
          monto: 290,
          fecha: date.add(const Duration(days: 3)),
          operationId: 'irregular-final',
          medio: MoneyMedium.cash,
        );
        debt = (await service.obtenerDeudas()).single;
        expect(debt.cuotasPagadas, 4);
        expect(await service.obtenerSaldoDisponible(), 500);
      } finally {
        await database.close();
      }
    },
  );

  test('conserva y marca como revisada una referencia histórica', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final service = DatabaseService(database);
    try {
      final debtId = await service.agregarDeuda(
        nombre: 'Deuda con dato anterior',
        montoOriginal: 1000,
        cuota: 100,
        cuotasTotales: 10,
        cuotasPagadas: 2,
      );
      await service.confirmarRevisionCuotasLegadas(debtId);

      final debt = (await service.obtenerDeudas()).single;
      expect(debt.cuotasPagadasDeclaradas, 2);
      expect(debt.cuotasLegadasRevisadas, isTrue);
      expect(await service.obtenerPagosDeuda(debtId), isEmpty);
      expect(await service.obtenerSaldoDisponible(), 0);
    } finally {
      await database.close();
    }
  });

  test(
    'presta a terceros y registra devoluciones parciales sin ingresos falsos',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final service = DatabaseService(database);
      final date = DateTime(2026, 10, 15);
      final dueDate = DateTime(2026, 11, 15);
      try {
        await service.agregarIngreso(monto: 1000, fecha: date);
        final loanId = await service.registrarPrestamoTercero(
          persona: 'María',
          monto: 400,
          fechaEntrega: date,
          fechaDevolucionAcordada: dueDate,
          operationId: 'loan-delivery-1',
        );
        expect(await service.obtenerSaldoDisponible(), 600);

        final replayedLoanId = await service.registrarPrestamoTercero(
          persona: 'María',
          monto: 400,
          fechaEntrega: date,
          fechaDevolucionAcordada: dueDate,
          operationId: 'loan-delivery-1',
        );
        expect(replayedLoanId, loanId);
        expect(await service.obtenerPrestamosTerceros(), hasLength(1));
        expect(await service.obtenerMovimientosPrestamo(), hasLength(1));
        await expectLater(
          service.registrarPrestamoTercero(
            persona: 'María',
            monto: 300,
            fechaEntrega: date,
            fechaDevolucionAcordada: dueDate,
            operationId: 'loan-delivery-1',
          ),
          throwsA(isA<DatabaseServiceException>()),
        );

        final firstReturnId = await service.registrarDevolucionPrestamo(
          prestamoId: loanId,
          monto: 100,
          fecha: dueDate,
          operationId: 'loan-return-1',
        );
        expect(await service.obtenerSaldoDisponible(), 700);
        final replayedReturnId = await service.registrarDevolucionPrestamo(
          prestamoId: loanId,
          monto: 100,
          fecha: dueDate,
          operationId: 'loan-return-1',
        );
        expect(replayedReturnId, firstReturnId);
        expect(await service.obtenerSaldoDisponible(), 700);

        await service.registrarDevolucionPrestamo(
          prestamoId: loanId,
          monto: 100,
          fecha: dueDate,
          operationId: 'loan-return-2-same-date',
        );
        await service.registrarDevolucionPrestamo(
          prestamoId: loanId,
          monto: 50,
          fecha: dueDate.add(const Duration(days: 1)),
          operationId: 'loan-return-3',
        );
        var movements = await service.obtenerMovimientosPrestamo();
        var loan = (await service.obtenerPrestamosTerceros()).single;
        final returned = movements
            .where((item) => item.tipo == DatabaseService.devolucionPrestamo)
            .fold<double>(0, (total, item) => total + item.monto);
        expect(loan.persona, 'María');
        expect(loan.montoPrincipal, 400);
        expect(loan.fechaEntrega, date);
        expect(loan.fechaDevolucionAcordada, dueDate);
        expect(returned, 250);
        expect(loan.montoPrincipal - returned, 150);
        expect(await service.obtenerSaldoDisponible(), 850);

        await service.registrarDevolucionPrestamo(
          prestamoId: loanId,
          monto: 150,
          fecha: dueDate.add(const Duration(days: 2)),
          operationId: 'loan-return-final',
        );
        movements = await service.obtenerMovimientosPrestamo();
        loan = (await service.obtenerPrestamosTerceros()).single;
        expect(movements, hasLength(5));
        expect(
          movements
              .where((item) => item.tipo == DatabaseService.devolucionPrestamo)
              .fold<double>(0, (total, item) => total + item.monto),
          400,
        );
        expect(await service.obtenerSaldoDisponible(), 1000);
        expect(await service.obtenerIngresos(), hasLength(1));
        expect((await service.obtenerIngresos()).single.monto, 1000);
        expect(await service.obtenerGastos(), isEmpty);

        await expectLater(
          service.registrarDevolucionPrestamo(
            prestamoId: loan.id,
            monto: 1,
            fecha: dueDate,
            operationId: 'loan-return-after-paid',
          ),
          throwsA(isA<DatabaseServiceException>()),
        );
        await service.borrarDatosFinancieros();
        expect(await service.obtenerPrestamosTerceros(), isEmpty);
        expect(await service.obtenerMovimientosPrestamo(), isEmpty);
        expect(await service.obtenerSaldoDisponible(), 0);
      } finally {
        await database.close();
      }
    },
  );

  testWidgets('revisa y confirma préstamos sin descontar al cancelar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final database = AppDatabase(NativeDatabase.memory());
    final service = DatabaseService(database);
    addTearDown(database.close);
    await service.agregarIngreso(monto: 1000, fecha: DateTime(2026, 10, 15));
    await service.distribuirSaldoDisponible(efectivo: 1000, digital: 0);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SavingsScreen(databaseService: service)),
      ),
    );
    await _pumpUntilFound(tester, find.text('Préstamos'));
    expect(find.byKey(const ValueKey('third-party-loan-add')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('third-party-loan-add')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('third-party-loan-person')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('third-party-loan-amount')),
      findsOneWidget,
    );
    expect(find.text('Revisar entrega'), findsOneWidget);

    await tester.tap(find.text('Revisar entrega'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe el nombre de la persona.'), findsOneWidget);
    expect(find.text('Escribe un monto mayor que cero.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('third-party-loan-person')),
      'María',
    );
    await tester.enterText(
      find.byKey(const ValueKey('third-party-loan-amount')),
      '1001',
    );
    await tester.tap(find.text('Revisar entrega'));
    await tester.pumpAndSettle();
    expect(
      find.text('Uy, parece que no alcanza la platica para eso.'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('third-party-loan-amount')),
      '400',
    );
    await tester.tap(find.text('Revisar entrega'));
    await tester.pumpAndSettle();
    expect(find.text('Revisar entrega'), findsOneWidget);
    expect(find.text('Persona: María'), findsOneWidget);
    expect(find.text('Monto: ${formatMoney(400)}'), findsOneWidget);
    expect(find.textContaining('Fecha de entrega:'), findsOneWidget);
    expect(find.textContaining('Fecha límite de pago:'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(await service.obtenerPrestamosTerceros(), isEmpty);
    expect(await service.obtenerMovimientosPrestamo(), isEmpty);
    expect(await service.obtenerSaldoDisponible(), 1000);

    await tester.tap(find.byKey(const ValueKey('third-party-loan-add')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('third-party-loan-person')),
      'María',
    );
    await tester.enterText(
      find.byKey(const ValueKey('third-party-loan-amount')),
      '400',
    );
    await tester.tap(find.text('Revisar entrega'));
    await tester.pumpAndSettle();
    final confirmCenter = tester.getCenter(find.text('Confirmar entrega'));
    await tester.tapAt(confirmCenter);
    await tester.tapAt(confirmCenter);
    await _pumpUntilFound(
      tester,
      find.text('¡Listo! El préstamo quedó registrado.'),
    );

    final loans = await service.obtenerPrestamosTerceros();
    final movements = await service.obtenerMovimientosPrestamo();
    expect(loans, hasLength(1));
    expect(loans.single.persona, 'María');
    expect(loans.single.montoPrincipal, 400);
    expect(movements, hasLength(1));
    expect(movements.single.tipo, DatabaseService.entregaPrestamo);
    expect(movements.single.monto, 400);
    expect(await service.obtenerSaldoDisponible(), 600);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('suma sueldo, extra y préstamo desde Agregar dinero', (
    tester,
  ) async {
    await _prepareTemporaryStorage(tester);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    late AppDatabase database;
    late DatabaseService service;
    await tester.runAsync(() async {
      database = AppDatabase();
      service = DatabaseService(database);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: HomeScreen(databaseService: service)),
        ),
      );
    });
    await _pumpUntilFound(tester, find.text('Dinero disponible'));
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('home-current-date')),
    );
    expect(find.text('Agregar dinero'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _recordIncome(tester, 'Sueldo', 'Quincena', '600000');
    await _pumpUntilMonthlyReceived(tester, 600000);
    await tester.runAsync(() async {
      expect(await service.obtenerDeudas(), isEmpty);
    });

    await _recordIncome(tester, 'Dinero extra', 'Venta', '50000');
    await _pumpUntilMonthlyReceived(tester, 650000);
    await tester.runAsync(() async {
      expect(await service.obtenerDeudas(), isEmpty);
    });

    await _recordIncome(tester, 'Préstamo recibido', 'Préstamo', '50000');
    await _pumpUntilMonthlyReceived(tester, 700000);
    await tester.runAsync(() async {
      final incomes = await service.obtenerIngresos();
      final debts = await service.obtenerDeudas();
      expect(incomes, hasLength(3));
      expect(debts, hasLength(1));
      expect(debts.single.ingresoId, loanIdFromIncome(incomes));
      expect(debts.single.cuota, 10000);
      expect(debts.single.cuotasTotales, 5);
      await service.distribuirSaldoDisponible(efectivo: 700000, digital: 0);
      await service.registrarPagoDeuda(
        deudaId: debts.single.id,
        monto: 10000,
        fecha: DateTime(2026, 10, 13),
        operationId: 'home-payment-1',
        medio: MoneyMedium.cash,
      );
    });
    await _pumpUntilKeyText(
      tester,
      const ValueKey('home-available-balance'),
      r'$ 690.000',
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('home-monthly-received')))
          .data,
      r'$ 700.000',
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() => database.close());
  });

  test(
    'conserva categorías guardadas y agrega defaults solo a settings nuevos',
    () {
      const savedCategories = [
        'Comida',
        'Transporte',
        'Mascotas',
        'Comidas',
        'Comida para gatos',
        'Comida para los bichos',
        'Comidaaaa',
        'Comida para bichos',
      ];
      final savedSettings = AppSettings.fromJson({
        'currencyCode': 'COP',
        'expenseCategories': savedCategories,
      });

      const normalizedCategories = [
        'Comidaaaa',
        'Transporte',
        'Mascotas',
        'Comida para bichos',
      ];
      expect(savedSettings.expenseCategories, normalizedCategories);
      expect(savedSettings.toJson()['expenseCategories'], normalizedCategories);

      final defaults = AppSettings.defaults().expenseCategories;
      expect(
        defaults,
        containsAll([
          'Comidaaaa',
          'Comida para bichos',
          'Transportes',
          'Cineeeee',
          'Compraaaas',
          'Aceo Personal',
          'Resivos xd',
          'Otros',
        ]),
      );
      expect(defaults, hasLength(8));

      final legacySettingsWithoutCategories = AppSettings.fromJson({
        'currencyCode': 'COP',
      });
      expect(legacySettingsWithoutCategories.expenseCategories, defaults);

      final savedEmptyCategories = AppSettings.fromJson({
        'currencyCode': 'COP',
        'expenseCategories': <String>[],
      });
      expect(savedEmptyCategories.expenseCategories, isEmpty);
    },
  );

  testWidgets(
    'normaliza alias en ajustes persistidos sin perder personalizadas',
    (tester) async {
      final directory = await _prepareTemporaryStorage(tester);
      final settingsFile = File(
        '${directory.path}${Platform.pathSeparator}finanzas_app_settings.json',
      );
      const expected = [
        'Comidaaaa',
        'Comida para bichos',
        'Transporte personalizado',
        'Mascotas',
      ];
      late AppSettings settings;
      late Map<String, dynamic> persisted;
      await tester.runAsync(() async {
        await settingsFile.writeAsString(
          jsonEncode({
            'currencyCode': 'COP',
            'expenseCategories': [
              'Comidas',
              'Comida',
              'Comida para gatos',
              'Comida para los bichos',
              'Transporte personalizado',
              'Mascotas',
            ],
          }),
          flush: true,
        );
        settings = await const AppSettingsService().load();
        persisted =
            jsonDecode(await settingsFile.readAsString())
                as Map<String, dynamic>;
      });
      expect(settings.expenseCategories, expected);
      expect(persisted['expenseCategories'], expected);
    },
  );

  testWidgets(
    'acumula ingresos, vincula el préstamo y descuenta cada pago una vez',
    (tester) async {
      await _prepareTemporaryStorage(tester);
      await tester.runAsync(() async {
        final database = AppDatabase();
        final service = DatabaseService(database);
        final receivedDate = DateTime(2026, 10, 1);
        try {
          await service.agregarIngreso(
            monto: 600000,
            fecha: receivedDate,
            descripcion: 'Quincena',
            tipo: IncomeType.salary.storageValue,
          );
          expect(await service.obtenerDeudas(), isEmpty);
          await service.agregarIngreso(
            monto: 50000,
            fecha: DateTime(2026, 10, 5),
            descripcion: 'Venta',
            tipo: IncomeType.extra.storageValue,
          );
          expect(await service.obtenerDeudas(), isEmpty);

          final loan = await service.registrarPrestamo(
            nombre: 'Préstamo familiar',
            monto: 50000,
            fechaRecepcion: DateTime(2026, 10, 8),
            cuotasTotales: 5,
            fechaPrimerPago: DateTime(2026, 11, 8),
          );

          final incomesBeforePayment = await service.obtenerIngresos();
          expect(incomesBeforePayment, hasLength(3));
          expect(
            incomesBeforePayment.fold<double>(
              0,
              (total, income) => total + income.monto,
            ),
            700000,
          );
          expect(
            incomesBeforePayment
                .singleWhere((income) => income.id == loan.ingresoId)
                .tipo,
            IncomeType.loan.storageValue,
          );

          final debts = await service.obtenerDeudas();
          expect(debts, hasLength(1));
          final debt = debts.single;
          expect(debt.ingresoId, loan.ingresoId);
          expect(debt.id, loan.deudaId);
          expect(debt.montoOriginal, 50000);
          expect(debt.cuota, 10000);
          expect(debt.cuotasTotales, 5);
          expect(debt.cuotasPagadas, 0);
          expect(debt.fechaProximoPago, DateTime(2026, 11, 8));

          await service.distribuirSaldoDisponible(efectivo: 700000, digital: 0);
          await service.registrarPagoDeuda(
            deudaId: loan.deudaId,
            monto: 10000,
            fecha: DateTime(2026, 11, 8),
            operationId: 'received-loan-payment-1',
            medio: MoneyMedium.cash,
          );
          final incomesAfterPayment = await service.obtenerIngresos();
          expect(incomesAfterPayment, hasLength(3));
          expect(
            incomesAfterPayment.fold<double>(
              0,
              (total, income) => total + income.monto,
            ),
            700000,
          );
          final paidDebt = (await service.obtenerDeudas()).single;
          final payments = await service.obtenerPagosDeuda(loan.deudaId);
          expect(paidDebt.cuotasPagadas, 1);
          expect(
            paidDebt.montoOriginal -
                payments.fold<double>(0, (sum, payment) => sum + payment.monto),
            40000,
          );
          expect(
            incomesAfterPayment.fold<double>(
                  0,
                  (total, income) => total + income.monto,
                ) -
                payments.fold<double>(0, (sum, payment) => sum + payment.monto),
            690000,
          );
        } finally {
          await database.close();
        }

        final reopened = AppDatabase();
        try {
          final incomes = await DatabaseService(reopened).obtenerIngresos();
          final debts = await DatabaseService(reopened).obtenerDeudas();
          expect(incomes, hasLength(3));
          expect(debts, hasLength(1));
          expect(debts.single.ingresoId, loanIdFromIncome(incomes));
        } finally {
          await reopened.close();
        }
      });
    },
  );

  testWidgets('ahorrar y retirar mueve saldo sin crear ingresos ni gastos', (
    tester,
  ) async {
    await _prepareTemporaryStorage(tester);
    await tester.runAsync(() async {
      final database = AppDatabase();
      final service = DatabaseService(database);
      final date = DateTime(2026, 10, 13);
      try {
        await service.agregarIngreso(monto: 1000, fecha: date);
        await service.distribuirSaldoDisponible(efectivo: 1000, digital: 0);
        await service.agregarGasto(
          nombre: 'Compra',
          monto: 200,
          categoria: 'Compras',
          fecha: date,
          medio: MoneyMedium.cash,
        );
        await service.agregarDeuda(
          nombre: 'Cuota',
          montoOriginal: 100,
          cuota: 100,
          cuotasTotales: 1,
        );
        final debt = (await service.obtenerDeudas()).single;
        await service.registrarPagoDeuda(
          deudaId: debt.id,
          monto: 100,
          fecha: date,
          operationId: 'savings-flow-payment-1',
          medio: MoneyMedium.cash,
        );
        expect(await service.obtenerSaldoDisponible(), 700);

        await service.registrarAporteAhorro(
          monto: 300,
          fecha: date,
          medio: MoneyMedium.cash,
        );
        expect(await service.obtenerSaldoDisponible(), 400);
        expect(await service.obtenerTotalAhorros(), 300);
        await expectLater(
          service.registrarAporteAhorro(
            monto: 401,
            fecha: date,
            medio: MoneyMedium.cash,
          ),
          throwsA(isA<DatabaseServiceException>()),
        );

        await service.retirarAhorro(
          monto: 100,
          fecha: date,
          medio: MoneyMedium.cash,
        );
        expect(await service.obtenerSaldoDisponible(), 500);
        expect(await service.obtenerTotalAhorros(), 200);
        await expectLater(
          service.retirarAhorro(
            monto: 201,
            fecha: date,
            medio: MoneyMedium.cash,
          ),
          throwsA(isA<DatabaseServiceException>()),
        );
        expect(await service.obtenerIngresos(), hasLength(1));
        expect(await service.obtenerGastos(), hasLength(1));
        expect(await service.obtenerTodosLosPagosDeuda(), hasLength(1));
        expect(await service.obtenerMovimientosAhorro(), hasLength(2));
        expect(
          await service.obtenerSaldoDisponible() +
              await service.obtenerTotalAhorros(),
          700,
        );
      } finally {
        await database.close();
      }

      final reopened = AppDatabase();
      try {
        final reopenedService = DatabaseService(reopened);
        expect(await reopenedService.obtenerMovimientosAhorro(), hasLength(2));
        expect(await reopenedService.obtenerTotalAhorros(), 200);
        expect(await reopenedService.obtenerSaldoDisponible(), 500);
        expect(await reopenedService.obtenerIngresos(), hasLength(1));
        expect(await reopenedService.obtenerGastos(), hasLength(1));

        await reopenedService.borrarDatosFinancieros();
        expect(await reopenedService.obtenerMovimientosAhorro(), isEmpty);
        expect(await reopenedService.obtenerIngresos(), isEmpty);
        expect(await reopenedService.obtenerGastos(), isEmpty);
      } finally {
        await reopened.close();
      }
    });
  });

  testWidgets('actualiza un gasto existente sin crear otro registro', (
    tester,
  ) async {
    await _prepareTemporaryStorage(tester);
    await tester.runAsync(() async {
      final database = AppDatabase();
      final service = DatabaseService(database);
      try {
        await service.agregarIngreso(
          monto: 2000000,
          fecha: DateTime(2026, 10, 1),
        );
        await service.distribuirSaldoDisponible(efectivo: 2000000, digital: 0);
        final id = await service.agregarGasto(
          nombre: 'Comida anterior',
          monto: 1500,
          categoria: 'Comida',
          fecha: DateTime(2026, 10, 1),
          medio: MoneyMedium.cash,
        );
        await service.actualizarGasto(
          id: id,
          nombre: 'Comida actualizada',
          monto: 1250000,
          categoria: 'Comida para gatos',
          fecha: DateTime(2026, 10, 13),
          nota: 'Alimento',
          medio: MoneyMedium.cash,
        );

        final expenses = await service.obtenerGastos();
        expect(expenses, hasLength(1));
        expect(expenses.single.id, id);
        expect(expenses.single.nombre, 'Comida actualizada');
        expect(expenses.single.monto, 1250000);
        expect(expenses.single.categoria, 'Comida para gatos');
        expect(expenses.single.nota, 'Alimento');
      } finally {
        await database.close();
      }
    });
  });
}

int loanIdFromIncome(List<Ingreso> incomes) => incomes
    .singleWhere((income) => income.tipo == IncomeType.loan.storageValue)
    .id;

Future<Directory> _prepareTemporaryStorage(WidgetTester tester) async {
  late Directory directory;
  await tester.runAsync(() async {
    directory = await Directory.systemTemp.createTemp(
      'finanzas_app_financial_test_',
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
  return directory;
}

Future<void> _recordIncome(
  WidgetTester tester,
  String type,
  String description,
  String amount,
) async {
  await tester.ensureVisible(find.text('Agregar dinero'));
  await tester.tap(find.text('Agregar dinero'));
  await tester.pumpAndSettle();
  if (type != 'Sueldo') {
    await tester.tap(find.byKey(const ValueKey('income-type')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(type).last);
    await tester.pumpAndSettle();
  }
  await tester.enterText(
    find.byKey(const ValueKey('income-description')),
    description,
  );
  await tester.enterText(find.byKey(const ValueKey('income-amount')), amount);
  if (type == 'Préstamo recibido') {
    await tester.enterText(
      find.byKey(const ValueKey('income-installments')),
      '5',
    );
  }
  await tester.tap(
    find.text(
      type == 'Préstamo recibido' ? 'Registrar préstamo' : 'Guardar ingreso',
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpUntilMonthlyReceived(
  WidgetTester tester,
  double amount,
) async {
  final finder = find.byKey(const ValueKey('home-monthly-received'));
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
    if (tester.widget<Text>(finder).data == formatMoney(amount)) return;
  }
  fail('El total mensual no se actualizó a ${formatMoney(amount)}.');
}

Future<void> _pumpUntilKeyText(
  WidgetTester tester,
  ValueKey<String> key,
  String expected,
) async {
  final finder = find.byKey(key);
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
    if (tester.widget<Text>(finder).data == expected) return;
  }
  fail('El valor del resumen no se actualizó a $expected.');
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
