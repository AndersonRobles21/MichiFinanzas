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
}

class Gastos extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get nombre => text()();

  RealColumn get monto => real()();

  TextColumn get categoria => text()();

  DateTimeColumn get fecha => dateTime()();

  TextColumn get nota => text().nullable()();

  TextColumn get medio => text().nullable()();
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

  TextColumn get origen => text().nullable()();

  IntColumn get origenId => integer().nullable()();
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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 10;

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
