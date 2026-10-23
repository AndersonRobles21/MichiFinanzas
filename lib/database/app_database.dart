import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Ingresos extends Table {
  IntColumn get id => integer().autoIncrement()();

  RealColumn get monto => real()();

  TextColumn get tipo => text().withDefault(const Constant('ingreso'))();

  DateTimeColumn get fecha => dateTime()();

  TextColumn get descripcion => text().nullable()();

  TextColumn get medio => text().nullable()();

  IntColumn get cuentaDigitalId => integer().nullable().references(
    CuentasDigitales,
    #id,
    onDelete: KeyAction.setNull,
  )();
}

class Gastos extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get nombre => text()();

  RealColumn get monto => real()();

  TextColumn get categoria => text()();

  DateTimeColumn get fecha => dateTime()();

  TextColumn get nota => text().nullable()();

  TextColumn get medio => text().nullable()();

  IntColumn get cuentaDigitalId => integer().nullable().references(
    CuentasDigitales,
    #id,
    onDelete: KeyAction.setNull,
  )();

  IntColumn get suscripcionId => integer().nullable().references(
    Suscripciones,
    #id,
    onDelete: KeyAction.setNull,
  )();

  DateTimeColumn get suscripcionPeriodo => dateTime().nullable()();
}

class Deudas extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get ingresoId => integer().nullable().references(
    Ingresos,
    #id,
    onDelete: KeyAction.setNull,
  )();

  TextColumn get nombre => text()();

  RealColumn get montoOriginal => real()();

  RealColumn get cuota => real()();

  IntColumn get cuotasTotales => integer()();

  IntColumn get cuotasPagadas => integer().withDefault(const Constant(0))();

  IntColumn get cuotasPagadasDeclaradas =>
      integer().withDefault(const Constant(0))();

  BoolColumn get cuotasLegadasRevisadas =>
      boolean().withDefault(const Constant(false))();

  DateTimeColumn get fechaProximoPago => dateTime().nullable()();
}

class PagosDeuda extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get deudaId =>
      integer().references(Deudas, #id, onDelete: KeyAction.cascade)();

  RealColumn get monto => real()();

  DateTimeColumn get fecha => dateTime()();

  TextColumn get operationId => text().nullable()();

  TextColumn get medio => text().nullable()();
}

class MovimientosAhorro extends Table {
  IntColumn get id => integer().autoIncrement()();

  RealColumn get monto => real()();

  TextColumn get tipo => text()();

  DateTimeColumn get fecha => dateTime()();

  TextColumn get medio => text().nullable()();
}

class PrestamosTerceros extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get persona => text()();

  RealColumn get montoPrincipal => real()();

  DateTimeColumn get fechaEntrega => dateTime()();

  DateTimeColumn get fechaDevolucionAcordada => dateTime()();
}

class MovimientosPrestamo extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get prestamoId => integer().references(
    PrestamosTerceros,
    #id,
    onDelete: KeyAction.cascade,
  )();

  TextColumn get tipo => text()();

  RealColumn get monto => real()();

  DateTimeColumn get fecha => dateTime()();

  TextColumn get operationId => text().unique()();

  TextColumn get medio => text().nullable()();
}

class GastosFuturos extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get nombre => text()();

  TextColumn get categoria => text()();

  RealColumn get montoNecesario => real()();

  RealColumn get montoPlaneado => real()();

  TextColumn get frecuencia => text()();

  DateTimeColumn get fechaObjetivo => dateTime()();

  DateTimeColumn get fechaInicio => dateTime().nullable()();

  TextColumn get notas => text().nullable()();

  TextColumn get estado => text().withDefault(const Constant('activo'))();
}

class MovimientosReservaGastoFuturo extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get gastoFuturoId => integer().nullable().references(
    GastosFuturos,
    #id,
    onDelete: KeyAction.setNull,
  )();

  TextColumn get nombrePlan => text()();

  TextColumn get tipo => text()();

  RealColumn get monto => real()();

  DateTimeColumn get fecha => dateTime()();

  TextColumn get operationId => text().unique()();

  TextColumn get medio => text().nullable()();
}

class AsignacionesDinero extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get medio => text()();

  RealColumn get monto => real()();

  IntColumn get cuentaDigitalId => integer().nullable().references(
    CuentasDigitales,
    #id,
    onDelete: KeyAction.setNull,
  )();

  TextColumn get origen => text().nullable()();

  IntColumn get origenId => integer().nullable()();
}

class CuentasDigitales extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get nombre => text()();
}

class IngresoDistribuciones extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get ingresoId =>
      integer().references(Ingresos, #id, onDelete: KeyAction.cascade)();

  TextColumn get medio => text()();

  RealColumn get monto => real()();

  IntColumn get cuentaDigitalId => integer().nullable().references(
    CuentasDigitales,
    #id,
    onDelete: KeyAction.setNull,
  )();
}

class TransferenciasDinero extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get medioOrigen => text()();

  @ReferenceName('sourceTransfers')
  IntColumn get cuentaOrigenId => integer().nullable().references(
    CuentasDigitales,
    #id,
    onDelete: KeyAction.setNull,
  )();

  TextColumn get medioDestino => text()();

  @ReferenceName('destinationTransfers')
  IntColumn get cuentaDestinoId => integer().nullable().references(
    CuentasDigitales,
    #id,
    onDelete: KeyAction.setNull,
  )();

  RealColumn get monto => real()();

  DateTimeColumn get fecha => dateTime()();

  TextColumn get nota => text().nullable()();
}

@DataClassName('Suscripcion')
class Suscripciones extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get nombre => text()();

  RealColumn get precio => real()();

  DateTimeColumn get proximoPago => dateTime()();

  TextColumn get frecuencia => text()();

  TextColumn get medio => text().nullable()();

  IntColumn get cuentaDigitalId => integer().nullable().references(
    CuentasDigitales,
    #id,
    onDelete: KeyAction.setNull,
  )();

  BoolColumn get activa => boolean().withDefault(const Constant(true))();
}

@DriftDatabase(
  tables: [
    Ingresos,
    Gastos,
    Deudas,
    PagosDeuda,
    MovimientosAhorro,
    PrestamosTerceros,
    MovimientosPrestamo,
    GastosFuturos,
    MovimientosReservaGastoFuturo,
    AsignacionesDinero,
    CuentasDigitales,
    IngresoDistribuciones,
    TransferenciasDinero,
    Suscripciones,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 16;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await customStatement(
        'CREATE UNIQUE INDEX pagos_deuda_operation_id_unique '
        'ON pagos_deuda (operation_id)',
      );
      await customStatement(
        'CREATE UNIQUE INDEX asignaciones_dinero_origen_unique '
        'ON asignaciones_dinero (origen, origen_id) '
        'WHERE origen IS NOT NULL AND origen_id IS NOT NULL',
      );
      await customStatement(
        'CREATE UNIQUE INDEX gastos_suscripcion_periodo_unique '
        'ON gastos (suscripcion_id, suscripcion_periodo) '
        'WHERE suscripcion_id IS NOT NULL AND suscripcion_periodo IS NOT NULL',
      );
      await customStatement(
        'CREATE INDEX ingreso_distribuciones_ingreso_id '
        'ON ingreso_distribuciones (ingreso_id)',
      );
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.alterTable(
          TableMigration(deudas, newColumns: [deudas.cuotasPagadas]),
        );
      }
      if (from < 3) {
        await migrator.addColumn(ingresos, ingresos.tipo);
        await migrator.addColumn(deudas, deudas.ingresoId);
      }
      if (from < 4) {
        await migrator.createTable(movimientosAhorro);
      }
      if (from < 5) {
        await migrator.addColumn(deudas, deudas.cuotasPagadasDeclaradas);
        await migrator.addColumn(deudas, deudas.cuotasLegadasRevisadas);
        await migrator.addColumn(pagosDeuda, pagosDeuda.operationId);
        await customStatement(
          'CREATE UNIQUE INDEX pagos_deuda_operation_id_unique '
          'ON pagos_deuda (operation_id)',
        );
        await customStatement(
          'UPDATE deudas SET cuotas_pagadas_declaradas = cuotas_pagadas',
        );
      }
      if (from < 6) {
        await migrator.createTable(prestamosTerceros);
        await migrator.createTable(movimientosPrestamo);
      }
      if (from < 7) {
        await customStatement(
          "UPDATE gastos SET categoria = 'Comidaaaa' "
          "WHERE lower(trim(categoria)) IN ('comida', 'comidas')",
        );
        await customStatement(
          "UPDATE gastos SET categoria = 'Comida para bichos' "
          "WHERE lower(trim(categoria)) IN "
          "('comida para gatos', 'comida para los bichos')",
        );
      }
      if (from < 8) {
        await migrator.createTable(gastosFuturos);
        await migrator.createTable(movimientosReservaGastoFuturo);
      }
      if (from < 9) {
        await migrator.addColumn(ingresos, ingresos.medio);
        await migrator.addColumn(gastos, gastos.medio);
        await migrator.addColumn(pagosDeuda, pagosDeuda.medio);
        if (from >= 4) {
          await migrator.addColumn(movimientosAhorro, movimientosAhorro.medio);
        }
        if (from >= 6) {
          await migrator.addColumn(
            movimientosPrestamo,
            movimientosPrestamo.medio,
          );
        }
        if (from >= 8) {
          await migrator.addColumn(
            movimientosReservaGastoFuturo,
            movimientosReservaGastoFuturo.medio,
          );
        }
      }
      if (from < 10) {
        await migrator.createTable(asignacionesDinero);
        await customStatement(
          'CREATE UNIQUE INDEX asignaciones_dinero_origen_unique '
          'ON asignaciones_dinero (origen, origen_id) '
          'WHERE origen IS NOT NULL AND origen_id IS NOT NULL',
        );
      }
      if (from < 11) {
        await migrator.createTable(suscripciones);
      }
      if (from < 12) {
        await migrator.createTable(cuentasDigitales);
        if (from >= 10) {
          final assignmentTable = await customSelect(
            "SELECT name FROM sqlite_master "
            "WHERE type = 'table' AND name = 'asignaciones_dinero'",
          ).getSingleOrNull();
          if (assignmentTable == null) {
            await migrator.createTable(asignacionesDinero);
            await customStatement(
              'CREATE UNIQUE INDEX asignaciones_dinero_origen_unique '
              'ON asignaciones_dinero (origen, origen_id) '
              'WHERE origen IS NOT NULL AND origen_id IS NOT NULL',
            );
          } else {
            await migrator.addColumn(
              asignacionesDinero,
              asignacionesDinero.cuentaDigitalId,
            );
          }
        }
      }
      if (from < 13) {
        await migrator.createTable(transferenciasDinero);
      }
      if (from < 14) {
        final incomeTable = await customSelect(
          "SELECT name FROM sqlite_master "
          "WHERE type = 'table' AND name = 'ingresos'",
        ).getSingleOrNull();
        if (incomeTable != null) {
          await migrator.addColumn(ingresos, ingresos.cuentaDigitalId);
        }
        final expenseTable = await customSelect(
          "SELECT name FROM sqlite_master "
          "WHERE type = 'table' AND name = 'gastos'",
        ).getSingleOrNull();
        if (expenseTable != null) {
          await migrator.addColumn(gastos, gastos.cuentaDigitalId);
        }
      }
      if (from < 15) {
        final expensesTable = await customSelect(
          "SELECT name FROM sqlite_master "
          "WHERE type = 'table' AND name = 'gastos'",
        ).getSingleOrNull();
        if (expensesTable != null) {
          final expenseColumns = await customSelect(
            "PRAGMA table_info('gastos')",
          ).get();
          final expenseColumnNames = expenseColumns
              .map((row) => row.read<String>('name'))
              .toSet();
          if (!expenseColumnNames.contains('suscripcion_id')) {
            await migrator.addColumn(gastos, gastos.suscripcionId);
          }
          if (!expenseColumnNames.contains('suscripcion_periodo')) {
            await migrator.addColumn(gastos, gastos.suscripcionPeriodo);
          }
          await customStatement(
            'CREATE UNIQUE INDEX gastos_suscripcion_periodo_unique '
            'ON gastos (suscripcion_id, suscripcion_periodo) '
            'WHERE suscripcion_id IS NOT NULL AND suscripcion_periodo IS NOT NULL',
          );
        }
        final subscriptionsTable = await customSelect(
          "SELECT name FROM sqlite_master "
          "WHERE type = 'table' AND name = 'suscripciones'",
        ).getSingleOrNull();
        if (subscriptionsTable != null) {
          final subscriptionColumns = await customSelect(
            "PRAGMA table_info('suscripciones')",
          ).get();
          final subscriptionColumnNames = subscriptionColumns
              .map((row) => row.read<String>('name'))
              .toSet();
          if (!subscriptionColumnNames.contains('cuenta_digital_id')) {
            await migrator.addColumn(
              suscripciones,
              suscripciones.cuentaDigitalId,
            );
          }
          if (!subscriptionColumnNames.contains('activa')) {
            await migrator.addColumn(suscripciones, suscripciones.activa);
          }
        }
      }
      if (from < 16) {
        await migrator.createTable(ingresoDistribuciones);
        await customStatement(
          'CREATE INDEX ingreso_distribuciones_ingreso_id '
          'ON ingreso_distribuciones (ingreso_id)',
        );
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'finanzas_app',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}
