import 'dart:io';

import 'package:drift/native.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart' show ValueKey;
import 'package:flutter/material.dart' show MaterialApp, Size, SizedBox;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finanzas_app/database/app_database.dart';
import 'package:finanzas_app/models/future_expense.dart';
import 'package:finanzas_app/screens/statistics/statistics_screen.dart';
import 'package:finanzas_app/services/database_service.dart';
import 'package:finanzas_app/theme/app_theme.dart';
import 'package:finanzas_app/utils/money_format.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('muestra estado vacío cuando no hay gastos', (tester) async {
    await _prepareTemporaryDatabaseDirectory(tester);
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _mountStatisticsScreen(tester);
    await _pumpUntilFound(
      tester,
      find.text('Todavía no hay movimientos por aquí.'),
    );

    expect(find.text('Todavía no hay movimientos por aquí.'), findsOneWidget);
    expect(find.byKey(const ValueKey('category-pie-chart')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('calcula el resumen y dibuja gráficos con gastos reales', (
    tester,
  ) async {
    final expenses = <_ExpenseFixture>[];
    await _prepareTemporaryDatabaseDirectory(tester);
    final now = DateTime.now();
    expenses.addAll([
      _ExpenseFixture('Comida', 100, now),
      _ExpenseFixture('Comida', 50, now),
      _ExpenseFixture('Transporte', 50, now),
    ]);
    await _seedExpenses(tester, expenses);

    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _mountStatisticsScreen(tester);
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('statistics-total')),
    );

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('statistics-total')),
        matching: find.text(r'$ 200'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('statistics-count')),
        matching: find.text('3'),
      ),
      findsOneWidget,
    );
    expect(find.text('Comida'), findsNWidgets(2));
    expect(find.text(r'$ 66,67'), findsOneWidget);
    expect(find.byKey(const ValueKey('category-pie-chart')), findsOneWidget);
    expect(find.byKey(const ValueKey('trend-bar-chart')), findsOneWidget);
    expect(find.text('Transporte'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('incluye reservas netas como gastos futuros sin duplicarlas', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final service = DatabaseService(database);
    addTearDown(service.close);
    final now = DateTime.now();
    await service.agregarIngreso(monto: 1000, fecha: now);
    await service.agregarGasto(
      nombre: 'Mercado',
      monto: 50,
      categoria: 'Comida',
      fecha: now,
    );
    final currentPlanId = await service.crearPlanGastoFuturo(
      nombre: 'Pasajes',
      categoria: 'Transporte',
      montoNecesario: 300,
      montoPlaneado: 300,
      frecuencia: FutureExpenseFrequency.once.storageValue,
      fechaObjetivo: now.add(const Duration(days: 30)),
    );
    await service.registrarReservaGastoFuturo(
      planId: currentPlanId,
      monto: 200,
      fecha: now,
      operationId: 'statistics-future-reserve-1',
    );
    await service.liberarReservaGastoFuturo(
      planId: currentPlanId,
      monto: 50,
      fecha: now.add(const Duration(minutes: 1)),
      operationId: 'statistics-future-release-1',
    );
    final previousMonthPlanId = await service.crearPlanGastoFuturo(
      nombre: 'Regalo',
      categoria: 'Otros',
      montoNecesario: 100,
      montoPlaneado: 100,
      frecuencia: FutureExpenseFrequency.once.storageValue,
      fechaObjetivo: now.add(const Duration(days: 30)),
    );
    final previousMonthDate = DateTime(
      now.year,
      now.month,
      1,
    ).subtract(const Duration(days: 1));
    await service.registrarReservaGastoFuturo(
      planId: previousMonthPlanId,
      monto: 40,
      fecha: previousMonthDate,
      operationId: 'statistics-future-reserve-previous-month',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: StatisticsScreen(databaseService: service),
      ),
    );
    await _pumpUntilFound(
      tester,
      find.descendant(
        of: find.byKey(const ValueKey('statistics-total')),
        matching: find.text(r'$ 200'),
      ),
    );

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('statistics-count')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('statistics-available-balance')),
        matching: find.text(r'$ 760'),
      ),
      findsOneWidget,
    );
    final futureExpenseCategory = find.byKey(
      const ValueKey('statistics-category-Gastos futuros'),
    );
    expect(futureExpenseCategory, findsOneWidget);
    expect(
      find.descendant(of: futureExpenseCategory, matching: find.text(r'$ 150')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('category-pie-chart')), findsOneWidget);
    expect(find.byKey(const ValueKey('trend-bar-chart')), findsOneWidget);
    final trendChart = tester.widget<BarChart>(
      find.descendant(
        of: find.byKey(const ValueKey('trend-bar-chart')),
        matching: find.byType(BarChart),
      ),
    );
    expect(
      trendChart.data.barGroups.any(
        (group) => group.barRods.any((rod) => rod.toY == 200),
      ),
      isTrue,
    );

    await tester.tap(find.byKey(const ValueKey('period-previousMonth')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('statistics-total')),
        matching: find.text(r'$ 40'),
      ),
      findsOneWidget,
    );
    expect(futureExpenseCategory, findsOneWidget);
    expect(
      find.descendant(of: futureExpenseCategory, matching: find.text(r'$ 40')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('muestra ingresos registrados y actualiza sin reiniciar', (
    tester,
  ) async {
    await _prepareTemporaryDatabaseDirectory(tester);
    late AppDatabase database;
    late DatabaseService service;
    await tester.runAsync(() async {
      database = AppDatabase();
      service = DatabaseService(database);
      await service.agregarIngreso(monto: 420, fecha: DateTime.now());
    });
    addTearDown(() => tester.runAsync(() => database.close()));

    await _mountStatisticsScreen(tester, service: service);
    await _pumpUntilFound(
      tester,
      find.descendant(
        of: find.byKey(const ValueKey('statistics-income-total')),
        matching: find.text(r'$ 420'),
      ),
    );

    await tester.runAsync(
      () => service.agregarIngreso(monto: 80, fecha: DateTime.now()),
    );
    await _pumpUntilFound(
      tester,
      find.descendant(
        of: find.byKey(const ValueKey('statistics-income-total')),
        matching: find.text(r'$ 500'),
      ),
    );
    expect(find.byKey(const ValueKey('trend-bar-chart')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('filtra gastos por los cuatro períodos', (tester) async {
    final now = DateTime.now();
    final expenses = [
      _ExpenseFixture('Hoy', 80, now),
      _ExpenseFixture(
        'Hace tres días',
        40,
        now.subtract(const Duration(days: 3)),
      ),
      _ExpenseFixture(
        'Hace veinte días',
        20,
        now.subtract(const Duration(days: 20)),
      ),
      _ExpenseFixture(
        'Hace cuarenta y cinco días',
        10,
        now.subtract(const Duration(days: 45)),
      ),
    ];
    await _prepareTemporaryDatabaseDirectory(tester);
    await _seedExpenses(tester, expenses);

    await _mountStatisticsScreen(tester);
    await _pumpUntilFound(
      tester,
      find.text(
        _formatMoney(_expectedTotal(expenses, StatisticsPeriod.thisMonth, now)),
      ),
    );

    for (final period in StatisticsPeriod.values.skip(1)) {
      await tester.tap(find.byKey(ValueKey('period-${period.name}')));
      await tester.pumpAndSettle();
      final expected = _formatMoney(_expectedTotal(expenses, period, now));
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('statistics-total')),
          matching: find.text(expected),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('muestra un error de lectura con opción de reintento', (
    tester,
  ) async {
    await _prepareTemporaryDatabaseDirectory(tester, invalidPath: true);
    await _mountStatisticsScreen(tester);
    await _pumpUntilFound(
      tester,
      find.text('Ups, tus estadísticas no cargaron esta vez.'),
    );

    expect(
      find.text('Ups, tus estadísticas no cargaron esta vez.'),
      findsOneWidget,
    );
    expect(find.text('Intentar de nuevo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _ExpenseFixture {
  const _ExpenseFixture(this.category, this.amount, this.date);

  final String category;
  final double amount;
  final DateTime date;
}

Future<void> _mountStatisticsScreen(
  WidgetTester tester, {
  DatabaseService? service,
}) async {
  await tester.runAsync(
    () => tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: StatisticsScreen(databaseService: service),
      ),
    ),
  );
}

Future<void> _seedExpenses(
  WidgetTester tester,
  List<_ExpenseFixture> expenses,
) async {
  await tester.runAsync(() async {
    final database = AppDatabase();
    try {
      final service = DatabaseService(database);
      for (var index = 0; index < expenses.length; index++) {
        final expense = expenses[index];
        await service.agregarGasto(
          nombre: 'Gasto ${index + 1}',
          monto: expense.amount,
          categoria: expense.category,
          fecha: expense.date,
        );
      }
    } finally {
      await database.close();
    }
  });
}

Future<void> _prepareTemporaryDatabaseDirectory(
  WidgetTester tester, {
  bool invalidPath = false,
}) async {
  late Directory directory;
  late String documentsPath;
  await tester.runAsync(() async {
    directory = await Directory.systemTemp.createTemp(
      'finanzas_app_statistics_test_',
    );
    documentsPath = directory.path;
    if (invalidPath) {
      documentsPath =
          '${directory.path}${Platform.pathSeparator}not-a-directory';
      await File(documentsPath).writeAsString('not a directory');
    }
  });

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(pathProviderChannel, (call) async {
        switch (call.method) {
          case 'getApplicationDocumentsDirectory':
          case 'getTemporaryDirectory':
            return documentsPath;
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

double _expectedTotal(
  List<_ExpenseFixture> expenses,
  StatisticsPeriod period,
  DateTime now,
) {
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  final start = switch (period) {
    StatisticsPeriod.thisMonth => DateTime(today.year, today.month),
    StatisticsPeriod.previousMonth => DateTime(today.year, today.month - 1),
    StatisticsPeriod.last7Days => today.subtract(const Duration(days: 6)),
    StatisticsPeriod.last30Days => today.subtract(const Duration(days: 29)),
  };
  final end = period == StatisticsPeriod.previousMonth
      ? DateTime(today.year, today.month)
      : tomorrow;
  return expenses
      .where(
        (expense) =>
            !expense.date.isBefore(start) && expense.date.isBefore(end),
      )
      .fold<double>(0, (total, expense) => total + expense.amount);
}

String _formatMoney(double amount) {
  return formatMoney(amount);
}
