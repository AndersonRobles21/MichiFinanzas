import 'dart:io';

import 'package:flutter/foundation.dart' show ValueKey;
import 'package:flutter/material.dart'
    show MaterialApp, Scrollable, Size, TextFormField;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finanzas_app/database/app_database.dart';
import 'package:finanzas_app/screens/expenses/expenses_screen.dart';
import 'package:finanzas_app/services/database_service.dart';
import 'package:finanzas_app/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('valida, crea, muestra y elimina gastos en 360 px', (
    tester,
  ) async {
    await _prepareTemporaryDatabaseDirectory(tester);
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _mountExpensesScreen(tester);
    await _pumpUntilFound(tester, find.text('Todavía no hay gastos por aquí.'));

    expect(find.text(r'$ 0'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));
    _expectNoTestException(tester);

    await tester.tap(find.byTooltip('Agregar gasto'));
    await tester.pumpAndSettle();
    expect(find.text('Nuevo gasto'), findsOneWidget);

    await tester.tap(find.text('Guardar gasto'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe el nombre del gasto.'), findsOneWidget);
    expect(find.text('Escribe un monto mayor que cero.'), findsOneWidget);
    expect(find.text('Elige una categoría.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('expense-name')),
      'Compra mercado',
    );
    await tester.enterText(find.byKey(const ValueKey('expense-amount')), '0');
    await tester.tap(find.text('Guardar gasto'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe un monto mayor que cero.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('expense-amount')),
      '25.75',
    );
    await tester.tap(find.byKey(const ValueKey('expense-category')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Comidaaaa'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Comidaaaa').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('expense-note')),
      'Frutas y verduras',
    );
    await tester.ensureVisible(find.text('Guardar gasto'));
    await tester.tap(find.text('Guardar gasto'));
    await tester.pumpAndSettle();

    await _pumpUntilFound(tester, find.text('Compra mercado'));
    expect(find.text(r'$ 25,75'), findsNWidgets(2));
    expect(find.text('Comidaaaa'), findsOneWidget);
    expect(find.text('Frutas y verduras'), findsOneWidget);
    expect(find.text('1'), findsNWidgets(2));
    _expectNoTestException(tester);

    await tester.tap(find.byTooltip('Editar gasto'));
    await tester.pumpAndSettle();
    expect(find.text('Editar gasto'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('expense-name')))
          .controller!
          .text,
      'Compra mercado',
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('expense-amount')))
          .controller!
          .text,
      '25,75',
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('expense-note')))
          .controller!
          .text,
      'Frutas y verduras',
    );
    await tester.enterText(
      find.byKey(const ValueKey('expense-name')),
      'Compra actualizada',
    );
    await tester.enterText(
      find.byKey(const ValueKey('expense-amount')),
      '1250000',
    );
    await tester.tap(find.byKey(const ValueKey('expense-category')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Comida para bichos'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Comida para bichos').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
    await _pumpUntilFound(tester, find.text('Compra actualizada'));
    expect(find.text(r'$ 1.250.000'), findsNWidgets(2));
    expect(find.text('Comida para bichos'), findsOneWidget);
    expect(find.text('Compra mercado'), findsNothing);

    await tester.tap(find.byTooltip('Editar gasto'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('expense-name')),
      'Cambio cancelado',
    );
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('Compra actualizada'), findsOneWidget);
    expect(find.text('Cambio cancelado'), findsNothing);

    await tester.tap(find.byTooltip('Eliminar gasto'));
    await tester.pumpAndSettle();
    expect(find.text('¿Borrar este gasto?'), findsOneWidget);
    await tester.tap(find.text('Conservar'));
    await tester.pumpAndSettle();
    expect(find.text('Compra actualizada'), findsOneWidget);

    await tester.tap(find.byTooltip('Eliminar gasto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Borrar gasto'));
    await tester.pumpAndSettle();
    await _pumpUntilFound(tester, find.text('Todavía no hay gastos por aquí.'));
    expect(find.text(r'$ 0'), findsOneWidget);
    _expectNoTestException(tester);
  });

  testWidgets('ordena los gastos del más reciente al más antiguo', (
    tester,
  ) async {
    await _prepareTemporaryDatabaseDirectory(tester);
    await tester.runAsync(() async {
      final database = AppDatabase();
      final service = DatabaseService(database);
      final now = DateTime.now();
      await service.agregarGasto(
        nombre: 'Gasto anterior',
        monto: 10,
        categoria: 'Otros',
        fecha: now.subtract(const Duration(days: 2)),
      );
      await service.agregarGasto(
        nombre: 'Gasto reciente',
        monto: 20,
        categoria: 'Otros',
        fecha: now,
      );
      await database.close();
    });

    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _mountExpensesScreen(tester);
    await _pumpUntilFound(tester, find.text('Gasto reciente'));

    final recentPosition = tester.getTopLeft(find.text('Gasto reciente')).dy;
    final olderPosition = tester.getTopLeft(find.text('Gasto anterior')).dy;
    expect(recentPosition, lessThan(olderPosition));
    _expectNoTestException(tester);
  });

  testWidgets('no revive alias de comida desde gastos históricos', (
    tester,
  ) async {
    await _prepareTemporaryDatabaseDirectory(tester);
    await tester.runAsync(() async {
      final database = AppDatabase();
      final service = DatabaseService(database);
      try {
        await service.agregarGasto(
          nombre: 'Compra anterior',
          monto: 20,
          categoria: 'Comidas',
          fecha: DateTime(2026, 10, 1),
        );
        await service.agregarGasto(
          nombre: 'Alimento anterior',
          monto: 30,
          categoria: 'Comida para gatos',
          fecha: DateTime(2026, 10, 2),
        );
        await service.agregarGasto(
          nombre: 'Arena',
          monto: 40,
          categoria: 'Mascotas',
          fecha: DateTime(2026, 10, 3),
        );
      } finally {
        await database.close();
      }
    });

    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _mountExpensesScreen(tester);
    await _pumpUntilFound(tester, find.text('Compra anterior'));
    await tester.tap(find.byTooltip('Agregar gasto'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('expense-category')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('expense-category-option-Comidaaaa')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('expense-category-option-Comida para bichos')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('expense-category-option-Comida')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('expense-category-option-Comidas')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('expense-category-option-Comida para gatos')),
      findsNothing,
    );
    expect(
      find.byKey(
        const ValueKey('expense-category-option-Comida para los bichos'),
      ),
      findsNothing,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('expense-category-option-Mascotas')),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    expect(
      find.byKey(const ValueKey('expense-category-option-Mascotas')),
      findsOneWidget,
    );
    _expectNoTestException(tester);
  });
}

Future<void> _mountExpensesScreen(WidgetTester tester) async {
  await tester.runAsync(
    () => tester.pumpWidget(
      MaterialApp(theme: AppTheme.darkTheme, home: const ExpensesScreen()),
    ),
  );
}

Future<void> _prepareTemporaryDatabaseDirectory(WidgetTester tester) async {
  late Directory directory;
  await tester.runAsync(() async {
    directory = await Directory.systemTemp.createTemp(
      'finanzas_app_expenses_test_',
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
