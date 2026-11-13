import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finanzas_app/database/app_database.dart';
import 'package:finanzas_app/screens/credits/credits_screen.dart';
import 'package:finanzas_app/services/database_service.dart';
import 'package:finanzas_app/theme/app_theme.dart';

void main() {
  testWidgets('crea y abre una entidad de crédito', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    final service = DatabaseService(database);
    addTearDown(service.close);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: CreditsScreen(databaseService: service),
      ),
    );
    await _pumpUntil(
      tester,
      find.text('Todavía no hay entidades registradas.'),
    );

    await tester.tap(find.byTooltip('Agregar entidad de crédito'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('credit-entity-name')),
      'Entidad de prueba',
    );
    await tester.enterText(
      find.byKey(const ValueKey('credit-entity-limit')),
      '200000',
    );
    await tester.ensureVisible(find.text('Guardar entidad'));
    await tester.tap(find.text('Guardar entidad'));
    await tester.pumpAndSettle();
    expect(await service.obtenerEntidadesCredito(), hasLength(1));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
    await _pumpUntil(tester, find.text('Entidad de prueba'));
    expect(find.text('Entidad de prueba'), findsOneWidget);
    await tester.tap(find.text('Entidad de prueba'));
    await tester.pumpAndSettle();
    await _pumpUntil(tester, find.text('Detalle de crédito'));

    expect(find.text('Detalle de crédito'), findsOneWidget);
    expect(find.text('Entidad de prueba'), findsOneWidget);
    expect(find.text('Nueva compra'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 30; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('No apareció el elemento esperado.');
}
