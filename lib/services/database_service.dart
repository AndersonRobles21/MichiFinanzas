import 'dart:async';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/future_expense.dart';
import '../models/income_type.dart';
import '../models/money_medium.dart';
import '../models/subscription.dart';

class DatabaseService {
  DatabaseService(this._database);

  static const subscriptionCategory = 'Suscripción';
  static const aporteAhorro = 'aporte';
  static const retiroAhorro = 'retiro';
  static const entregaPrestamo = 'entrega';
  static const devolucionPrestamo = 'devolucion';
  static const reservaGastoFuturo = 'reserva';
  static const liberacionGastoFuturo = 'liberacion';

  final AppDatabase _database;
  final StreamController<void> _financialChanges =
      StreamController<void>.broadcast();

  Future<void> close() async {
    await _financialChanges.close();
    await _database.close();
  }

  Future<void> borrarDatosFinancieros() {
    return _modificar(
      'borrar datos financieros',
      () => _database.transaction(() async {
        await _database.delete(_database.suscripciones).go();
        await _database.delete(_database.transferenciasDinero).go();
        await _database.delete(_database.pagosDeuda).go();
        await _database.delete(_database.deudas).go();
        await _database.delete(_database.movimientosPrestamo).go();
        await _database.delete(_database.prestamosTerceros).go();
        await _database.delete(_database.movimientosReservaGastoFuturo).go();
        await _database.delete(_database.gastosFuturos).go();
        await _database.delete(_database.movimientosAhorro).go();
        await _database.delete(_database.gastos).go();
        await _database.delete(_database.ingresos).go();
        await _database.delete(_database.asignacionesDinero).go();
      }),
    );
  }

  Future<int> agregarIngreso({
    required double monto,
    required DateTime fecha,
    String? descripcion,
    String tipo = 'ingreso',
    MoneyMedium? medio,
    int? cuentaDigitalId,
    List<IncomeDestination>? destinos,
  }) {
    return _modificar(
      'agregar ingreso',
      () => _database.transaction(() async {
        _validarMonto(monto);
        if (destinos != null) {
          await _validarDestinosIngreso(monto, destinos);
        }
        final singleDestination = destinos?.length == 1
            ? destinos!.single
            : null;
        final storedMedium = destinos == null
            ? medio
            : singleDestination?.medio;
        final storedAccountId = destinos == null
            ? cuentaDigitalId
            : singleDestination?.cuentaDigitalId;
        await _validarCuentaDigital(storedMedium, storedAccountId);
        final id = await _insertarIngreso(
          monto: monto,
          fecha: fecha,
          descripcion: descripcion,
          tipo: tipo,
          medio: storedMedium,
          cuentaDigitalId: storedAccountId,
        );
        if (destinos != null) {
          await _guardarDestinosIngreso(id, destinos);
        } else if (medio != null) {
          await _guardarImpactoMovimiento(
            origen: 'ingreso',
            origenId: id,
            medio: medio,
            monto: monto,
            cuentaDigitalId: cuentaDigitalId,
          );
        }
        return id;
      }),
    );
  }

  Future<({int ingresoId, int deudaId})> registrarPrestamo({
    required String nombre,
    required double monto,
    required DateTime fechaRecepcion,
    required int cuotasTotales,
    required DateTime fechaPrimerPago,
    MoneyMedium? medio,
    int? cuentaDigitalId,
    List<IncomeDestination>? destinos,
  }) {
    return _modificar(
      'registrar préstamo recibido',
      () => _database.transaction(() async {
        _validarMonto(monto);
        if (nombre.trim().isEmpty) {
          throw ArgumentError.value(nombre, 'nombre', 'No puede estar vacío.');
        }
        if (cuotasTotales <= 0) {
          throw ArgumentError.value(
            cuotasTotales,
            'cuotasTotales',
            'Debe ser mayor que cero.',
          );
        }
        if (destinos != null) {
          await _validarDestinosIngreso(monto, destinos);
        }
        final singleDestination = destinos?.length == 1
            ? destinos!.single
            : null;
        final storedMedium = destinos == null
            ? medio
            : singleDestination?.medio;
        final storedAccountId = destinos == null
            ? cuentaDigitalId
            : singleDestination?.cuentaDigitalId;
        await _validarCuentaDigital(storedMedium, storedAccountId);

        final incomeId = await _insertarIngreso(
          monto: monto,
          fecha: fechaRecepcion,
          descripcion: nombre.trim(),
          tipo: IncomeType.loan.storageValue,
          medio: storedMedium,
          cuentaDigitalId: storedAccountId,
        );
        if (destinos != null) {
          await _guardarDestinosIngreso(incomeId, destinos);
        } else if (medio != null) {
          await _guardarImpactoMovimiento(
            origen: 'ingreso',
            origenId: incomeId,
            medio: medio,
            monto: monto,
            cuentaDigitalId: cuentaDigitalId,
          );
        }
        final debtId = await _database
            .into(_database.deudas)
            .insert(
              DeudasCompanion.insert(
                ingresoId: Value(incomeId),
                nombre: nombre.trim(),
                montoOriginal: monto,
                cuota: monto / cuotasTotales,
                cuotasTotales: cuotasTotales,
                fechaProximoPago: Value(fechaPrimerPago),
              ),
            );
        return (ingresoId: incomeId, deudaId: debtId);
      }),
    );
  }

  Future<List<Ingreso>> obtenerIngresos() {
    return _ejecutar(
      'obtener ingresos',
      () => _database.select(_database.ingresos).get(),
    );
  }

  Future<List<IncomeDestination>> obtenerDestinosIngreso(int incomeId) {
    return _ejecutar('obtener destinos del ingreso', () async {
      final rows =
          await (_database.select(_database.ingresoDistribuciones)
                ..where((destination) => destination.ingresoId.equals(incomeId))
                ..orderBy([(destination) => OrderingTerm.asc(destination.id)]))
              .get();
      return rows.map(_toIncomeDestination).toList();
    });
  }

  Future<List<({int ingresoId, IncomeDestination destino})>>
  obtenerTodosLosDestinosIngreso() {
    return _ejecutar('obtener destinos de ingresos', () async {
      final rows =
          await (_database.select(_database.ingresoDistribuciones)..orderBy([
                (destination) => OrderingTerm.asc(destination.ingresoId),
                (destination) => OrderingTerm.asc(destination.id),
              ]))
              .get();
      return rows
          .map(
            (row) =>
                (ingresoId: row.ingresoId, destino: _toIncomeDestination(row)),
          )
          .toList();
    });
  }

  Future<int> actualizarIngreso({
    required int id,
    required double monto,
    required DateTime fecha,
    required String? descripcion,
    required String tipo,
    MoneyMedium? medio,
    int? cuentaDigitalId,
    List<IncomeDestination>? destinos,
  }) {
    return _modificar('actualizar ingreso', () async {
      _validarMonto(monto);
      return _database.transaction(() async {
        final income = await (_database.select(
          _database.ingresos,
        )..where((item) => item.id.equals(id))).getSingleOrNull();
        if (income == null) throw StateError('El ingreso ya no existe.');
        if (destinos != null) {
          await _validarDestinosIngreso(monto, destinos);
        }
        final existingDestinations = await (_database.select(
          _database.ingresoDistribuciones,
        )..where((item) => item.ingresoId.equals(id))).get();
        if (existingDestinations.isNotEmpty && destinos == null) {
          throw ArgumentError(
            'Indica cómo distribuir el ingreso antes de actualizarlo.',
          );
        }
        final singleDestination = destinos?.length == 1
            ? destinos!.single
            : null;
        final storedMedium = destinos == null
            ? medio
            : singleDestination?.medio;
        final storedAccountId = destinos == null
            ? cuentaDigitalId
            : singleDestination?.cuentaDigitalId;
        await _validarCuentaDigital(storedMedium, storedAccountId);

        final linkedDebt = await (_database.select(
          _database.deudas,
        )..where((debt) => debt.ingresoId.equals(id))).getSingleOrNull();
        if (!IncomeType.values.any(
          (incomeType) => incomeType.storageValue == tipo,
        )) {
          throw ArgumentError.value(tipo, 'tipo', 'Tipo de ingreso no válido.');
        }
        if ((linkedDebt != null) != (tipo == IncomeType.loan.storageValue)) {
          throw ArgumentError.value(
            tipo,
            'tipo',
            'Los préstamos recibidos conservan su tipo y deuda vinculada.',
          );
        }
        if (linkedDebt != null) {
          final payments = await (_database.select(
            _database.pagosDeuda,
          )..where((payment) => payment.deudaId.equals(linkedDebt.id))).get();
          final paid = payments.fold<double>(
            0,
            (total, payment) => total + payment.monto,
          );
          if (monto < paid) {
            throw ArgumentError.value(
              monto,
              'monto',
              'No puede ser menor que los abonos ya registrados ($paid).',
            );
          }
          final cleanDescription = _cleanOptionalText(descripcion);
          final amountChanged = monto != income.monto;
          final updatedInstallment = monto / linkedDebt.cuotasTotales;
          final updatedPaidInstallments = monto - paid <= 1e-8
              ? linkedDebt.cuotasTotales
              : ((paid + 1e-8) / updatedInstallment).floor().clamp(
                  0,
                  linkedDebt.cuotasTotales,
                );
          await (_database.update(
            _database.deudas,
          )..where((debt) => debt.id.equals(linkedDebt.id))).write(
            DeudasCompanion(
              nombre: cleanDescription == null
                  ? const Value.absent()
                  : Value(cleanDescription),
              montoOriginal: amountChanged
                  ? Value(monto)
                  : const Value.absent(),
              cuota: amountChanged
                  ? Value(updatedInstallment)
                  : const Value.absent(),
              cuotasPagadas: amountChanged
                  ? Value(updatedPaidInstallments)
                  : const Value.absent(),
            ),
          );
        }

        final updated =
            await (_database.update(
              _database.ingresos,
            )..where((item) => item.id.equals(id))).write(
              IngresosCompanion(
                monto: Value(monto),
                tipo: Value(tipo),
                fecha: Value(fecha),
                descripcion: Value(_cleanOptionalText(descripcion)),
                medio: Value(storedMedium?.storageValue),
                cuentaDigitalId: Value(storedAccountId),
              ),
            );
        if (destinos != null) {
          await _eliminarDestinosIngreso(id);
          await _eliminarImpactoMovimiento(origen: 'ingreso', origenId: id);
          await _guardarDestinosIngreso(id, destinos);
        } else {
          await _guardarImpactoMovimiento(
            origen: 'ingreso',
            origenId: id,
            medio: medio,
            monto: monto,
            cuentaDigitalId: cuentaDigitalId,
          );
        }
        await _validarAsignacionDentroDelSaldo();
        return updated;
      });
    });
  }

  Future<List<MovimientosAhorroData>> obtenerMovimientosAhorro() {
    return _ejecutar(
      'obtener movimientos de ahorro',
      () => (_database.select(
        _database.movimientosAhorro,
      )..orderBy([(movimiento) => OrderingTerm.desc(movimiento.fecha)])).get(),
    );
  }

  Future<List<PrestamosTercero>> obtenerPrestamosTerceros() {
    return _ejecutar(
      'obtener préstamos a terceros',
      () =>
          (_database.select(_database.prestamosTerceros)..orderBy([
                (prestamo) => OrderingTerm.desc(prestamo.fechaEntrega),
              ]))
              .get(),
    );
  }

  Future<List<MovimientosPrestamoData>> obtenerMovimientosPrestamo() {
    return _ejecutar(
      'obtener movimientos de préstamos',
      () => (_database.select(
        _database.movimientosPrestamo,
      )..orderBy([(movimiento) => OrderingTerm.desc(movimiento.fecha)])).get(),
    );
  }

  Future<List<FutureExpenseSummary>> obtenerPlanesGastosFuturos() {
    return _ejecutar('obtener planes de gastos futuros', () async {
      final plans = await (_database.select(
        _database.gastosFuturos,
      )..orderBy([(plan) => OrderingTerm.asc(plan.fechaObjetivo)])).get();
      final movements = await _database
          .select(_database.movimientosReservaGastoFuturo)
          .get();
      final reservedByPlan = <int, double>{};
      for (final movement in movements) {
        final planId = movement.gastoFuturoId;
        if (planId == null) continue;
        final amount = movement.tipo == reservaGastoFuturo
            ? movement.monto
            : -movement.monto;
        reservedByPlan.update(
          planId,
          (reserved) => reserved + amount,
          ifAbsent: () => amount,
        );
      }
      return [
        for (final plan in plans)
          FutureExpenseSummary(
            plan: _toFutureExpensePlan(plan),
            reservedAmount: reservedByPlan[plan.id] ?? 0,
          ),
      ];
    });
  }

  Future<List<MovimientosReservaGastoFuturoData>>
  obtenerMovimientosReservaGastoFuturo(int planId) {
    return _ejecutar(
      'obtener movimientos del plan',
      () =>
          (_database.select(_database.movimientosReservaGastoFuturo)
                ..where((movement) => movement.gastoFuturoId.equals(planId))
                ..orderBy([(movement) => OrderingTerm.desc(movement.fecha)]))
              .get(),
    );
  }

  Future<List<MovimientosReservaGastoFuturoData>>
  obtenerTodosLosMovimientosReservaGastoFuturo() {
    return _ejecutar(
      'obtener movimientos de reservas de gastos futuros',
      () =>
          (_database.select(_database.movimientosReservaGastoFuturo)..orderBy([
                (movement) => OrderingTerm.asc(movement.fecha),
                (movement) => OrderingTerm.asc(movement.id),
              ]))
              .get(),
    );
  }

  Future<int> crearPlanGastoFuturo({
    required String nombre,
    required String categoria,
    required double montoNecesario,
    required double montoPlaneado,
    required String frecuencia,
    required DateTime fechaObjetivo,
    DateTime? fechaInicio,
    String? notas,
  }) {
    return _modificar('crear plan de gasto futuro', () {
      _validarPlanFuturo(
        nombre: nombre,
        categoria: categoria,
        montoNecesario: montoNecesario,
        montoPlaneado: montoPlaneado,
      );
      return _database
          .into(_database.gastosFuturos)
          .insert(
            GastosFuturosCompanion.insert(
              nombre: nombre.trim(),
              categoria: categoria.trim(),
              montoNecesario: montoNecesario,
              montoPlaneado: montoPlaneado,
              frecuencia: frecuencia,
              fechaObjetivo: fechaObjetivo,
              fechaInicio: Value(fechaInicio),
              notas: Value(_cleanOptionalText(notas)),
            ),
          );
    });
  }

  Future<int> actualizarPlanGastoFuturo({
    required int id,
    required String nombre,
    required String categoria,
    required double montoNecesario,
    required double montoPlaneado,
    required String frecuencia,
    required DateTime fechaObjetivo,
    DateTime? fechaInicio,
    String? notas,
  }) {
    return _modificar('actualizar plan de gasto futuro', () async {
      _validarPlanFuturo(
        nombre: nombre,
        categoria: categoria,
        montoNecesario: montoNecesario,
        montoPlaneado: montoPlaneado,
      );
      final rows =
          await (_database.update(
            _database.gastosFuturos,
          )..where((plan) => plan.id.equals(id))).write(
            GastosFuturosCompanion(
              nombre: Value(nombre.trim()),
              categoria: Value(categoria.trim()),
              montoNecesario: Value(montoNecesario),
              montoPlaneado: Value(montoPlaneado),
              frecuencia: Value(frecuencia),
              fechaObjetivo: Value(fechaObjetivo),
              fechaInicio: Value(fechaInicio),
              notas: Value(_cleanOptionalText(notas)),
            ),
          );
      if (rows == 0) throw StateError('El plan ya no existe.');
      return rows;
    });
  }

  Future<void> actualizarEstadoPlanGastoFuturo({
    required int id,
    required FutureExpenseStatus estado,
  }) {
    return _modificar('actualizar estado del plan', () async {
      final rows =
          await (_database.update(
            _database.gastosFuturos,
          )..where((plan) => plan.id.equals(id))).write(
            GastosFuturosCompanion(estado: Value(estado.storageValue)),
          );
      if (rows == 0) throw StateError('El plan ya no existe.');
    });
  }

  Future<void> eliminarPlanGastoFuturo(int id) {
    return _modificar('eliminar plan de gasto futuro', () async {
      await _database.transaction(() async {
        final reserved = await _totalReservadoPlan(id);
        if (reserved > 1e-8) {
          throw StateError(
            'Libera el dinero reservado antes de eliminar este plan.',
          );
        }
        await (_database.delete(
          _database.gastosFuturos,
        )..where((plan) => plan.id.equals(id))).go();
      });
    });
  }

  Future<int> registrarReservaGastoFuturo({
    required int planId,
    required double monto,
    required DateTime fecha,
    required String operationId,
    MoneyMedium? medio,
  }) {
    return _modificar(
      'reservar dinero para un gasto futuro',
      () => _database.transaction(() async {
        _validarMonto(monto);
        if (operationId.trim().isEmpty) {
          throw ArgumentError.value(
            operationId,
            'operationId',
            'No puede estar vacío.',
          );
        }
        final previous =
            await (_database.select(_database.movimientosReservaGastoFuturo)
                  ..where(
                    (movement) => movement.operationId.equals(operationId),
                  ))
                .getSingleOrNull();
        if (previous != null) {
          if (previous.gastoFuturoId != planId ||
              previous.tipo != reservaGastoFuturo ||
              previous.monto != monto ||
              previous.fecha != fecha ||
              previous.medio != medio?.storageValue) {
            throw ArgumentError.value(
              operationId,
              'operationId',
              'Ya se usó para otra operación.',
            );
          }
          return previous.id;
        }

        final plan = await (_database.select(
          _database.gastosFuturos,
        )..where((item) => item.id.equals(planId))).getSingleOrNull();
        if (plan == null) throw StateError('El plan ya no existe.');
        if (plan.estado != FutureExpenseStatus.active.storageValue) {
          throw StateError('Activa el plan para reservar dinero.');
        }
        final reserved = await _totalReservadoPlan(planId);
        final plannedLimit = plan.montoPlaneado < plan.montoNecesario
            ? plan.montoPlaneado
            : plan.montoNecesario;
        final remainingPlan = plannedLimit - reserved;
        if (remainingPlan <= 0 || monto > remainingPlan + 1e-8) {
          throw ArgumentError.value(
            monto,
            'monto',
            'La cantidad supera lo que falta por reservar para este plan.',
          );
        }
        final available = await _calcularSaldoDisponible();
        if (monto > available + 1e-8) {
          throw FutureExpenseInsufficientBalance(
            requested: monto,
            available: available,
          );
        }
        final reclassified = await _validarCanalDisponible(
          medio: medio,
          monto: monto,
        );
        final id = await _database
            .into(_database.movimientosReservaGastoFuturo)
            .insert(
              MovimientosReservaGastoFuturoCompanion.insert(
                gastoFuturoId: Value(planId),
                nombrePlan: plan.nombre,
                tipo: reservaGastoFuturo,
                monto: monto,
                fecha: fecha,
                operationId: operationId,
                medio: Value(medio?.storageValue),
              ),
            );
        if (medio != null) {
          await _guardarImpactoMovimiento(
            origen: 'reserva_gasto_futuro',
            origenId: id,
            medio: medio,
            monto: -monto,
            reclassified: reclassified,
          );
        }
        return id;
      }),
    );
  }

  Future<int> liberarReservaGastoFuturo({
    required int planId,
    required double monto,
    required DateTime fecha,
    required String operationId,
    MoneyMedium? medio,
  }) {
    return _modificar(
      'liberar dinero reservado para un gasto futuro',
      () => _database.transaction(() async {
        _validarMonto(monto);
        if (operationId.trim().isEmpty) {
          throw ArgumentError.value(
            operationId,
            'operationId',
            'No puede estar vacío.',
          );
        }
        final previous =
            await (_database.select(_database.movimientosReservaGastoFuturo)
                  ..where(
                    (movement) => movement.operationId.equals(operationId),
                  ))
                .getSingleOrNull();
        if (previous != null) {
          if (previous.gastoFuturoId != planId ||
              previous.tipo != liberacionGastoFuturo ||
              previous.monto != monto ||
              previous.fecha != fecha ||
              previous.medio != medio?.storageValue) {
            throw ArgumentError.value(
              operationId,
              'operationId',
              'Ya se usó para otra operación.',
            );
          }
          return previous.id;
        }
        final plan = await (_database.select(
          _database.gastosFuturos,
        )..where((item) => item.id.equals(planId))).getSingleOrNull();
        if (plan == null) throw StateError('El plan ya no existe.');
        final reserved = await _totalReservadoPlan(planId);
        if (monto > reserved + 1e-8) {
          throw ArgumentError.value(
            monto,
            'monto',
            'No puedes liberar más dinero del que está reservado.',
          );
        }
        final id = await _database
            .into(_database.movimientosReservaGastoFuturo)
            .insert(
              MovimientosReservaGastoFuturoCompanion.insert(
                gastoFuturoId: Value(planId),
                nombrePlan: plan.nombre,
                tipo: liberacionGastoFuturo,
                monto: monto,
                fecha: fecha,
                operationId: operationId,
                medio: Value(medio?.storageValue),
              ),
            );
        if (medio != null) {
          await _guardarImpactoMovimiento(
            origen: 'liberacion_gasto_futuro',
            origenId: id,
            medio: medio,
            monto: monto,
          );
        }
        return id;
      }),
    );
  }

  Future<int> registrarPrestamoTercero({
    required String persona,
    required double monto,
    required DateTime fechaEntrega,
    required DateTime fechaDevolucionAcordada,
    required String operationId,
    MoneyMedium? medio,
  }) {
    return _modificar(
      'registrar préstamo a terceros',
      () => _database.transaction(() async {
        _validarMonto(monto);
        if (persona.trim().isEmpty || operationId.trim().isEmpty) {
          throw ArgumentError(
            'La persona y la clave de operación son obligatorias.',
          );
        }

        final previousMovement =
            await (_database.select(_database.movimientosPrestamo)
                  ..where((item) => item.operationId.equals(operationId)))
                .getSingleOrNull();
        if (previousMovement != null) {
          final previousLoan =
              await (_database.select(_database.prestamosTerceros)..where(
                    (item) => item.id.equals(previousMovement.prestamoId),
                  ))
                  .getSingleOrNull();
          if (previousMovement.tipo != entregaPrestamo ||
              previousMovement.monto != monto ||
              previousMovement.fecha != fechaEntrega ||
              previousMovement.medio != medio?.storageValue ||
              previousLoan?.persona != persona.trim() ||
              previousLoan?.fechaDevolucionAcordada !=
                  fechaDevolucionAcordada) {
            throw ArgumentError.value(
              operationId,
              'operationId',
              'Ya se usó para una operación diferente.',
            );
          }
          return previousMovement.prestamoId;
        }

        final disponible = await _calcularSaldoDisponible();
        if (monto > disponible + 1e-8) {
          throw ArgumentError.value(
            monto,
            'monto',
            'No puedes prestar más que tu saldo disponible ($disponible).',
          );
        }
        final reclassified = await _validarCanalDisponible(
          medio: medio,
          monto: monto,
        );

        final loanId = await _database
            .into(_database.prestamosTerceros)
            .insert(
              PrestamosTercerosCompanion.insert(
                persona: persona.trim(),
                montoPrincipal: monto,
                fechaEntrega: fechaEntrega,
                fechaDevolucionAcordada: fechaDevolucionAcordada,
              ),
            );
        final movementId = await _database
            .into(_database.movimientosPrestamo)
            .insert(
              MovimientosPrestamoCompanion.insert(
                prestamoId: loanId,
                tipo: entregaPrestamo,
                monto: monto,
                fecha: fechaEntrega,
                operationId: operationId,
                medio: Value(medio?.storageValue),
              ),
            );
        if (medio != null) {
          await _guardarImpactoMovimiento(
            origen: 'entrega_prestamo',
            origenId: movementId,
            medio: medio,
            monto: -monto,
            reclassified: reclassified,
          );
        }
        return loanId;
      }),
    );
  }

  Future<int> registrarDevolucionPrestamo({
    required int prestamoId,
    required double monto,
    required DateTime fecha,
    required String operationId,
    MoneyMedium? medio,
  }) {
    return _modificar(
      'registrar devolución de préstamo',
      () => _database.transaction(() async {
        _validarMonto(monto);
        if (operationId.trim().isEmpty) {
          throw ArgumentError.value(
            operationId,
            'operationId',
            'No puede estar vacío.',
          );
        }

        final previousMovement =
            await (_database.select(_database.movimientosPrestamo)
                  ..where((item) => item.operationId.equals(operationId)))
                .getSingleOrNull();
        if (previousMovement != null) {
          if (previousMovement.prestamoId != prestamoId ||
              previousMovement.tipo != devolucionPrestamo ||
              previousMovement.monto != monto ||
              previousMovement.fecha != fecha ||
              previousMovement.medio != medio?.storageValue) {
            throw ArgumentError.value(
              operationId,
              'operationId',
              'Ya se usó para una operación diferente.',
            );
          }
          return previousMovement.id;
        }

        final loan = await (_database.select(
          _database.prestamosTerceros,
        )..where((item) => item.id.equals(prestamoId))).getSingleOrNull();
        if (loan == null) throw StateError('El préstamo ya no existe.');

        final movements = await (_database.select(
          _database.movimientosPrestamo,
        )..where((item) => item.prestamoId.equals(prestamoId))).get();
        final returned = movements
            .where((item) => item.tipo == devolucionPrestamo)
            .fold<double>(0, (total, item) => total + item.monto);
        final remaining = loan.montoPrincipal - returned;
        if (monto > remaining) {
          throw ArgumentError.value(
            monto,
            'monto',
            'La devolución supera el saldo pendiente de $remaining.',
          );
        }

        final movementId = await _database
            .into(_database.movimientosPrestamo)
            .insert(
              MovimientosPrestamoCompanion.insert(
                prestamoId: prestamoId,
                tipo: devolucionPrestamo,
                monto: monto,
                fecha: fecha,
                operationId: operationId,
                medio: Value(medio?.storageValue),
              ),
            );
        if (medio != null) {
          await _guardarImpactoMovimiento(
            origen: 'devolucion_prestamo',
            origenId: movementId,
            medio: medio,
            monto: monto,
          );
        }
        return movementId;
      }),
    );
  }

  Future<double> obtenerTotalAhorros() {
    return _ejecutar('obtener total de ahorros', _calcularTotalAhorros);
  }

  Future<double> obtenerSaldoDisponible() {
    return _ejecutar('obtener saldo disponible', _calcularSaldoDisponible);
  }

  Future<AvailableBalanceBreakdown> obtenerSaldosPorMedio() {
    return _ejecutar('obtener saldos por medio', _calcularDesgloseSaldos);
  }

  Future<List<DigitalAccountBalance>> obtenerCuentasDigitales() {
    return _ejecutar('obtener cuentas digitales', () async {
      final accounts = await (_database.select(
        _database.cuentasDigitales,
      )..orderBy([(account) => OrderingTerm.asc(account.nombre)])).get();
      final assignments = await _database
          .select(_database.asignacionesDinero)
          .get();
      final balances = <int, double>{};
      for (final assignment in assignments) {
        final accountId = assignment.cuentaDigitalId;
        if (accountId == null) continue;
        balances.update(
          accountId,
          (balance) => balance + assignment.monto,
          ifAbsent: () => assignment.monto,
        );
      }
      return accounts
          .map(
            (account) => DigitalAccountBalance(
              account: account,
              balance: balances[account.id] ?? 0,
            ),
          )
          .toList();
    });
  }

  Future<int> crearCuentaDigital(String nombre) {
    return _modificar('crear cuenta digital', () async {
      final cleanName = nombre.trim();
      if (cleanName.isEmpty) {
        throw ArgumentError.value(nombre, 'nombre', 'No puede estar vacío.');
      }
      final existing = await _database.select(_database.cuentasDigitales).get();
      if (existing.any(
        (account) => account.nombre.toLowerCase() == cleanName.toLowerCase(),
      )) {
        throw ArgumentError.value(
          nombre,
          'nombre',
          'Ya existe una cuenta con ese nombre.',
        );
      }
      return _database
          .into(_database.cuentasDigitales)
          .insert(CuentasDigitalesCompanion.insert(nombre: cleanName));
    });
  }

  Future<int> actualizarCuentaDigital({
    required int id,
    required String nombre,
  }) {
    return _modificar('actualizar cuenta digital', () async {
      final cleanName = nombre.trim();
      if (cleanName.isEmpty) {
        throw ArgumentError.value(nombre, 'nombre', 'No puede estar vacío.');
      }
      final existing = await _database.select(_database.cuentasDigitales).get();
      if (existing.any(
        (account) =>
            account.id != id &&
            account.nombre.toLowerCase() == cleanName.toLowerCase(),
      )) {
        throw ArgumentError.value(
          nombre,
          'nombre',
          'Ya existe una cuenta con ese nombre.',
        );
      }
      final updated =
          await (_database.update(_database.cuentasDigitales)
                ..where((account) => account.id.equals(id)))
              .write(CuentasDigitalesCompanion(nombre: Value(cleanName)));
      if (updated == 0) throw StateError('La cuenta ya no existe.');
      return updated;
    });
  }

  Future<int> eliminarCuentaDigital(int id) {
    return _modificar('eliminar cuenta digital', () async {
      final history = await (_database.select(
        _database.asignacionesDinero,
      )..where((event) => event.cuentaDigitalId.equals(id))).get();
      if (history.isNotEmpty) {
        throw StateError(
          'Esta cuenta tiene movimientos asociados. Conserva su historial o transfiere el saldo antes de eliminarla.',
        );
      }
      final balance = await _calcularSaldoCuentaDigital(id);
      if (balance.abs() > 1e-8) {
        throw StateError(
          'Mueve el saldo de esta cuenta antes de eliminarla '
          '(${balance.toStringAsFixed(2)} disponibles).',
        );
      }
      return (_database.delete(
        _database.cuentasDigitales,
      )..where((account) => account.id.equals(id))).go();
    });
  }

  Future<List<TransferenciasDineroData>> obtenerTransferencias() {
    return _ejecutar(
      'obtener transferencias',
      () => (_database.select(
        _database.transferenciasDinero,
      )..orderBy([(transfer) => OrderingTerm.desc(transfer.fecha)])).get(),
    );
  }

  Future<int> transferirDinero({
    required MoneyMedium medioOrigen,
    int? cuentaOrigenId,
    required MoneyMedium medioDestino,
    int? cuentaDestinoId,
    required double monto,
    required DateTime fecha,
    String? nota,
  }) {
    return _modificar(
      'transferir dinero',
      () => _database.transaction(
        () => _guardarTransferencia(
          medioOrigen: medioOrigen,
          cuentaOrigenId: cuentaOrigenId,
          medioDestino: medioDestino,
          cuentaDestinoId: cuentaDestinoId,
          monto: monto,
          fecha: fecha,
          nota: nota,
        ),
      ),
    );
  }

  Future<int> actualizarTransferencia({
    required int id,
    required MoneyMedium medioOrigen,
    int? cuentaOrigenId,
    required MoneyMedium medioDestino,
    int? cuentaDestinoId,
    required double monto,
    required DateTime fecha,
    String? nota,
  }) {
    return _modificar(
      'actualizar transferencia',
      () => _database.transaction(() async {
        final existing = await (_database.select(
          _database.transferenciasDinero,
        )..where((transfer) => transfer.id.equals(id))).getSingleOrNull();
        if (existing == null) {
          throw StateError('La transferencia ya no existe.');
        }
        await _eliminarImpactoMovimiento(
          origen: 'transferencia_salida',
          origenId: id,
        );
        await _eliminarImpactoMovimiento(
          origen: 'transferencia_entrada',
          origenId: id,
        );
        await (_database.update(
          _database.transferenciasDinero,
        )..where((transfer) => transfer.id.equals(id))).write(
          TransferenciasDineroCompanion(
            medioOrigen: Value(medioOrigen.storageValue),
            cuentaOrigenId: Value(cuentaOrigenId),
            medioDestino: Value(medioDestino.storageValue),
            cuentaDestinoId: Value(cuentaDestinoId),
            monto: Value(monto),
            fecha: Value(fecha),
            nota: Value(_cleanOptionalText(nota)),
          ),
        );
        return _guardarImpactosTransferencia(
          id: id,
          medioOrigen: medioOrigen,
          cuentaOrigenId: cuentaOrigenId,
          medioDestino: medioDestino,
          cuentaDestinoId: cuentaDestinoId,
          monto: monto,
        );
      }),
    );
  }

  Future<int> eliminarTransferencia(int id) {
    return _modificar(
      'eliminar transferencia',
      () => _database.transaction(() async {
        await _eliminarImpactoMovimiento(
          origen: 'transferencia_salida',
          origenId: id,
        );
        await _eliminarImpactoMovimiento(
          origen: 'transferencia_entrada',
          origenId: id,
        );
        return (_database.delete(
          _database.transferenciasDinero,
        )..where((transfer) => transfer.id.equals(id))).go();
      }),
    );
  }

  Future<List<Suscripcion>> obtenerSuscripciones() {
    return _ejecutar(
      'obtener suscripciones',
      () =>
          (_database.select(_database.suscripciones)..orderBy([
                (subscription) => OrderingTerm.asc(subscription.proximoPago),
                (subscription) => OrderingTerm.asc(subscription.nombre),
              ]))
              .get(),
    );
  }

  Future<int> agregarSuscripcion({
    required String nombre,
    required double precio,
    required DateTime proximoPago,
    required SubscriptionFrequency frecuencia,
    required MoneyMedium medio,
    int? cuentaDigitalId,
  }) {
    return _ejecutar('agregar suscripción', () async {
      _validarMonto(precio);
      if (nombre.trim().isEmpty) {
        throw ArgumentError.value(nombre, 'nombre', 'No puede estar vacío.');
      }
      await _validarCuentaDigital(medio, cuentaDigitalId);
      if (medio == MoneyMedium.digital && cuentaDigitalId == null) {
        throw ArgumentError('Elige la cuenta digital de la suscripción.');
      }
      if (medio != MoneyMedium.digital && cuentaDigitalId != null) {
        throw ArgumentError('La cuenta digital debe usar el medio digital.');
      }
      return _database
          .into(_database.suscripciones)
          .insert(
            SuscripcionesCompanion.insert(
              nombre: nombre.trim(),
              precio: precio,
              proximoPago: proximoPago,
              frecuencia: frecuencia.storageValue,
              medio: Value(medio.storageValue),
              cuentaDigitalId: Value(cuentaDigitalId),
            ),
          );
    });
  }

  Future<int> actualizarSuscripcion({
    required int id,
    required String nombre,
    required double precio,
    required DateTime proximoPago,
    required SubscriptionFrequency frecuencia,
    required MoneyMedium medio,
    int? cuentaDigitalId,
  }) {
    return _ejecutar('actualizar suscripción', () async {
      _validarMonto(precio);
      if (nombre.trim().isEmpty) {
        throw ArgumentError.value(nombre, 'nombre', 'No puede estar vacío.');
      }
      await _validarCuentaDigital(medio, cuentaDigitalId);
      if (medio == MoneyMedium.digital && cuentaDigitalId == null) {
        throw ArgumentError('Elige la cuenta digital de la suscripción.');
      }
      if (medio != MoneyMedium.digital && cuentaDigitalId != null) {
        throw ArgumentError('La cuenta digital debe usar el medio digital.');
      }
      final updated =
          await (_database.update(
            _database.suscripciones,
          )..where((subscription) => subscription.id.equals(id))).write(
            SuscripcionesCompanion(
              nombre: Value(nombre.trim()),
              precio: Value(precio),
              proximoPago: Value(proximoPago),
              frecuencia: Value(frecuencia.storageValue),
              medio: Value(medio.storageValue),
              cuentaDigitalId: Value(cuentaDigitalId),
            ),
          );
      if (updated == 0) throw StateError('La suscripción ya no existe.');
      return updated;
    });
  }

  Future<int> eliminarSuscripcion(int id) {
    return cancelarSuscripcion(id);
  }

  Future<int> cancelarSuscripcion(int id) {
    return _modificar(
      'cancelar suscripción',
      () =>
          (_database.update(_database.suscripciones)
                ..where((subscription) => subscription.id.equals(id)))
              .write(const SuscripcionesCompanion(activa: Value(false))),
    );
  }

  Future<int> reactivarSuscripcion(int id) {
    return _modificar(
      'reactivar suscripción',
      () =>
          (_database.update(_database.suscripciones)
                ..where((subscription) => subscription.id.equals(id)))
              .write(const SuscripcionesCompanion(activa: Value(true))),
    );
  }

  Future<List<Gasto>> obtenerPagosSuscripcion(int suscripcionId) {
    return _ejecutar('obtener pagos de suscripción', () {
      return (_database.select(_database.gastos)
            ..where((expense) => expense.suscripcionId.equals(suscripcionId))
            ..orderBy([(expense) => OrderingTerm.desc(expense.fecha)]))
          .get();
    });
  }

  Future<int> pagarSuscripcion({
    required int suscripcionId,
    required DateTime periodoEsperado,
    required MoneyMedium medio,
    required int? cuentaDigitalId,
    required DateTime fecha,
  }) {
    return _modificar(
      'pagar suscripción',
      () => _database.transaction(() async {
        final subscription = await (_database.select(
          _database.suscripciones,
        )..where((item) => item.id.equals(suscripcionId))).getSingleOrNull();
        if (subscription == null || !subscription.activa) {
          throw StateError('Esta suscripción ya no está activa.');
        }
        if (!_sameDate(subscription.proximoPago, periodoEsperado)) {
          throw StateError(
            'Este cobro ya se registró. Actualiza la lista antes de volver a pagar.',
          );
        }
        final frequency = SubscriptionFrequency.fromStorage(
          subscription.frecuencia,
        );
        if (frequency == null) {
          throw StateError('La frecuencia de esta suscripción no es válida.');
        }
        if (medio == MoneyMedium.digital && cuentaDigitalId == null) {
          throw ArgumentError('Elige la cuenta digital desde donde pagar.');
        }
        await _validarCuentaDigital(medio, cuentaDigitalId);
        final reclassified = await _validarCanalDisponible(
          medio: medio,
          monto: subscription.precio,
          cuentaDigitalId: cuentaDigitalId,
        );
        final expenseId = await _database
            .into(_database.gastos)
            .insert(
              GastosCompanion.insert(
                nombre: subscription.nombre,
                monto: subscription.precio,
                categoria: subscriptionCategory,
                fecha: fecha,
                nota: Value('Pago de suscripción'),
                medio: Value(medio.storageValue),
                cuentaDigitalId: Value(cuentaDigitalId),
                suscripcionId: Value(suscripcionId),
                suscripcionPeriodo: Value(subscription.proximoPago),
              ),
            );
        await _guardarImpactoMovimiento(
          origen: 'gasto',
          origenId: expenseId,
          medio: medio,
          monto: -subscription.precio,
          reclassified: reclassified,
          cuentaDigitalId: cuentaDigitalId,
        );
        final nextPayment = _nextSubscriptionDate(
          subscription.proximoPago,
          frequency,
        );
        await (_database.update(_database.suscripciones)
              ..where((item) => item.id.equals(suscripcionId)))
            .write(SuscripcionesCompanion(proximoPago: Value(nextPayment)));
        await _validarAsignacionDentroDelSaldo();
        return expenseId;
      }),
    );
  }

  Future<AvailableBalanceBreakdown> distribuirSaldoDisponible({
    required double efectivo,
    required double digital,
  }) {
    return _modificar(
      'distribuir saldo disponible',
      () => _database.transaction(() async {
        if (!efectivo.isFinite || efectivo < 0) {
          throw ArgumentError.value(
            efectivo,
            'efectivo',
            'No puede ser negativo ni inválido.',
          );
        }
        if (!digital.isFinite || digital < 0) {
          throw ArgumentError.value(
            digital,
            'digital',
            'No puede ser negativo ni inválido.',
          );
        }
        final total = await _calcularSaldoDisponible();
        final distributed = efectivo + digital;
        if ((distributed - total).abs() > 1e-8) {
          throw ArgumentError.value(
            distributed,
            'distribución',
            distributed < total
                ? 'Faltan ${(total - distributed).toStringAsFixed(2)} por distribuir.'
                : 'La distribución supera el saldo disponible en '
                      '${(distributed - total).toStringAsFixed(2)}.',
          );
        }

        final digitalAccounts = await obtenerCuentasDigitales();
        final assignedToAccounts = digitalAccounts.fold<double>(
          0,
          (balance, account) => balance + account.balance,
        );
        if (digital + 1e-8 < assignedToAccounts) {
          throw ArgumentError.value(
            digital,
            'digital',
            'La distribución no puede reducir el saldo que ya pertenece '
                'a cuentas digitales ($assignedToAccounts).',
          );
        }

        final current = await _calcularSaldoAsignado();
        await _insertarEventoAsignacion(
          MoneyMedium.cash,
          efectivo - current.cash,
        );
        await _insertarEventoAsignacion(
          MoneyMedium.digital,
          digital - current.digital,
        );
        return _calcularDesgloseSaldos();
      }),
    );
  }

  Future<int> registrarAporteAhorro({
    required double monto,
    required DateTime fecha,
    MoneyMedium? medio,
  }) {
    return _modificar('registrar aporte de ahorro', () async {
      _validarMonto(monto);
      return _database.transaction(() async {
        final disponible = await _calcularSaldoDisponible();
        if (monto > disponible) {
          throw ArgumentError.value(
            monto,
            'monto',
            'No puedes ahorrar más que tu saldo disponible ($disponible).',
          );
        }
        final reclassified = await _validarCanalDisponible(
          medio: medio,
          monto: monto,
        );
        final id = await _database
            .into(_database.movimientosAhorro)
            .insert(
              MovimientosAhorroCompanion.insert(
                monto: monto,
                tipo: aporteAhorro,
                fecha: fecha,
                medio: Value(medio?.storageValue),
              ),
            );
        if (medio != null) {
          await _guardarImpactoMovimiento(
            origen: 'aporte_ahorro',
            origenId: id,
            medio: medio,
            monto: -monto,
            reclassified: reclassified,
          );
        }
        return id;
      });
    });
  }

  Future<int> retirarAhorro({
    required double monto,
    required DateTime fecha,
    MoneyMedium? medio,
  }) {
    return _modificar('retirar ahorro', () async {
      _validarMonto(monto);
      return _database.transaction(() async {
        final totalAhorros = await _calcularTotalAhorros();
        if (monto > totalAhorros) {
          throw ArgumentError.value(
            monto,
            'monto',
            'No puedes retirar más que el total ahorrado ($totalAhorros).',
          );
        }
        final id = await _database
            .into(_database.movimientosAhorro)
            .insert(
              MovimientosAhorroCompanion.insert(
                monto: monto,
                tipo: retiroAhorro,
                fecha: fecha,
                medio: Value(medio?.storageValue),
              ),
            );
        if (medio != null) {
          await _guardarImpactoMovimiento(
            origen: 'retiro_ahorro',
            origenId: id,
            medio: medio,
            monto: monto,
          );
        }
        return id;
      });
    });
  }

  Stream<void> observarCambiosFinancieros() => _financialChanges.stream;

  Future<int> eliminarIngreso(int id) {
    return _modificar(
      'eliminar ingreso',
      () => _database.transaction(() async {
        final linkedDebt = await (_database.select(
          _database.deudas,
        )..where((debt) => debt.ingresoId.equals(id))).getSingleOrNull();
        if (linkedDebt != null) {
          final payments = await (_database.select(
            _database.pagosDeuda,
          )..where((payment) => payment.deudaId.equals(linkedDebt.id))).get();
          for (final payment in payments) {
            await _eliminarImpactoMovimiento(
              origen: 'pago_deuda',
              origenId: payment.id,
            );
          }
          await (_database.delete(
            _database.deudas,
          )..where((debt) => debt.id.equals(linkedDebt.id))).go();
        }
        await _eliminarDestinosIngreso(id);
        await _eliminarImpactoMovimiento(origen: 'ingreso', origenId: id);
        final deleted = await (_database.delete(
          _database.ingresos,
        )..where((income) => income.id.equals(id))).go();
        await _validarAsignacionDentroDelSaldo();
        return deleted;
      }),
    );
  }

  Future<int> agregarGasto({
    required String nombre,
    required double monto,
    required String categoria,
    required DateTime fecha,
    String? nota,
    MoneyMedium? medio,
    int? cuentaDigitalId,
  }) {
    return _modificar(
      'agregar gasto',
      () => _database.transaction(() async {
        _validarMonto(monto);
        if (nombre.trim().isEmpty || categoria.trim().isEmpty) {
          throw ArgumentError('El nombre y la categoría son obligatorios.');
        }
        await _validarCuentaDigital(medio, cuentaDigitalId);
        final reclassified = await _validarCanalDisponible(
          medio: medio,
          monto: monto,
          cuentaDigitalId: cuentaDigitalId,
        );
        final id = await _database
            .into(_database.gastos)
            .insert(
              GastosCompanion.insert(
                nombre: nombre.trim(),
                monto: monto,
                categoria: categoria,
                fecha: fecha,
                nota: Value(nota),
                medio: Value(medio?.storageValue),
                cuentaDigitalId: Value(cuentaDigitalId),
              ),
            );
        await _guardarImpactoMovimiento(
          origen: 'gasto',
          origenId: id,
          medio: medio,
          monto: -monto,
          reclassified: reclassified,
          cuentaDigitalId: cuentaDigitalId,
        );
        return id;
      }),
    );
  }

  Future<List<Gasto>> obtenerGastos() {
    return _ejecutar(
      'obtener gastos',
      () => _database.select(_database.gastos).get(),
    );
  }

  Future<int> eliminarGasto(int id) {
    return _modificar(
      'eliminar gasto',
      () => _database.transaction(() async {
        final expense = await (_database.select(
          _database.gastos,
        )..where((item) => item.id.equals(id))).getSingleOrNull();
        if (expense?.suscripcionId != null) {
          throw StateError(
            'Los pagos de suscripción se conservan en el historial financiero.',
          );
        }
        await _eliminarImpactoMovimiento(origen: 'gasto', origenId: id);
        return (_database.delete(
          _database.gastos,
        )..where((gasto) => gasto.id.equals(id))).go();
      }),
    );
  }

  Future<int> renombrarCategoriaGastos({
    required String nombreAnterior,
    required String nombreNuevo,
  }) {
    return _modificar('renombrar categoría de gastos', () async {
      if (nombreAnterior.trim().toLowerCase() ==
          subscriptionCategory.toLowerCase()) {
        throw StateError(
          'La categoría Suscripción es necesaria para el historial.',
        );
      }
      final cleanName = nombreNuevo.trim();
      if (cleanName.isEmpty) {
        throw ArgumentError.value(
          nombreNuevo,
          'nombreNuevo',
          'No puede estar vacío.',
        );
      }
      return (_database.update(_database.gastos)
            ..where((gasto) => gasto.categoria.equals(nombreAnterior)))
          .write(GastosCompanion(categoria: Value(cleanName)));
    });
  }

  Future<int> actualizarGasto({
    required int id,
    required String nombre,
    required double monto,
    required String categoria,
    required DateTime fecha,
    String? nota,
    MoneyMedium? medio,
    int? cuentaDigitalId,
  }) {
    return _modificar('actualizar gasto', () async {
      _validarMonto(monto);
      if (nombre.trim().isEmpty || categoria.trim().isEmpty) {
        throw ArgumentError('El nombre y la categoría son obligatorios.');
      }
      return _database.transaction(() async {
        final current = await (_database.select(
          _database.gastos,
        )..where((expense) => expense.id.equals(id))).getSingleOrNull();
        if (current == null) throw StateError('El gasto ya no existe.');
        if (current.suscripcionId != null &&
            categoria.trim().toLowerCase() !=
                subscriptionCategory.toLowerCase()) {
          throw StateError(
            'Los pagos de suscripción deben conservar su categoría.',
          );
        }
        await _validarCuentaDigital(medio, cuentaDigitalId);
        final allocation =
            await (_database.select(_database.asignacionesDinero)..where(
                  (event) =>
                      event.origen.equals('gasto') & event.origenId.equals(id),
                ))
                .getSingleOrNull();
        if (allocation != null) {
          final reclassified = await _validarCanalDisponible(
            medio: medio,
            monto: monto,
            cuentaDigitalId: cuentaDigitalId,
          );
          await _guardarImpactoMovimiento(
            origen: 'gasto',
            origenId: id,
            medio: medio,
            monto: -monto,
            crearSiNoExiste: false,
            reclassified: reclassified,
            cuentaDigitalId: cuentaDigitalId,
          );
        }
        final updatedRows =
            await (_database.update(
              _database.gastos,
            )..where((gasto) => gasto.id.equals(id))).write(
              GastosCompanion(
                nombre: Value(nombre.trim()),
                monto: Value(monto),
                categoria: Value(categoria),
                fecha: Value(fecha),
                nota: Value(nota),
                medio: Value(medio?.storageValue),
                cuentaDigitalId: Value(cuentaDigitalId),
              ),
            );
        await _validarAsignacionDentroDelSaldo();
        return updatedRows;
      });
    });
  }

  Future<int> agregarDeuda({
    required String nombre,
    required double montoOriginal,
    required double cuota,
    required int cuotasTotales,
    int cuotasPagadas = 0,
    DateTime? fechaProximoPago,
  }) {
    return _modificar(
      'agregar deuda',
      () => _database
          .into(_database.deudas)
          .insert(
            DeudasCompanion.insert(
              nombre: nombre,
              montoOriginal: montoOriginal,
              cuota: cuota,
              cuotasTotales: cuotasTotales,
              cuotasPagadasDeclaradas: Value(cuotasPagadas),
              fechaProximoPago: Value(fechaProximoPago),
            ),
          ),
    );
  }

  Future<List<Deuda>> obtenerDeudas() {
    return _ejecutar(
      'obtener deudas',
      () => _database.select(_database.deudas).get(),
    );
  }

  Future<int> registrarPagoDeuda({
    required int deudaId,
    required double monto,
    required DateTime fecha,
    required String operationId,
    MoneyMedium? medio,
  }) {
    return _modificar(
      'registrar pago de deuda',
      () => _database.transaction(() async {
        if (operationId.trim().isEmpty) {
          throw ArgumentError.value(
            operationId,
            'operationId',
            'No puede estar vacío.',
          );
        }
        if (!monto.isFinite || monto <= 0) {
          throw ArgumentError.value(monto, 'monto', 'Debe ser mayor que cero.');
        }
        final previousPayment =
            await (_database.select(_database.pagosDeuda)
                  ..where((pago) => pago.operationId.equals(operationId)))
                .getSingleOrNull();
        if (previousPayment != null) {
          if (previousPayment.deudaId != deudaId ||
              previousPayment.monto != monto ||
              previousPayment.fecha != fecha ||
              previousPayment.medio != medio?.storageValue) {
            throw ArgumentError.value(
              operationId,
              'operationId',
              'Ya se usó para un abono diferente.',
            );
          }
          return previousPayment.id;
        }

        final deuda = await (_database.select(
          _database.deudas,
        )..where((item) => item.id.equals(deudaId))).getSingleOrNull();
        if (deuda == null) {
          throw StateError('La deuda ya no existe.');
        }
        if (!deuda.cuota.isFinite || deuda.cuota <= 0) {
          throw StateError('La deuda tiene un valor de cuota inválido.');
        }

        final pagosPrevios = await (_database.select(
          _database.pagosDeuda,
        )..where((pago) => pago.deudaId.equals(deudaId))).get();
        final totalAbonadoAntes = pagosPrevios.fold<double>(
          0,
          (total, pago) => total + pago.monto,
        );
        final saldoRestante = (deuda.montoOriginal - totalAbonadoAntes).clamp(
          0.0,
          double.infinity,
        );
        if (saldoRestante <= 0 || monto > saldoRestante) {
          throw ArgumentError.value(
            monto,
            'monto',
            'El pago no puede superar el saldo restante de $saldoRestante.',
          );
        }

        final reclassified = await _validarCanalDisponible(
          medio: medio,
          monto: monto,
        );
        final paymentId = await _database
            .into(_database.pagosDeuda)
            .insert(
              PagosDeudaCompanion.insert(
                deudaId: deudaId,
                monto: monto,
                fecha: fecha,
                operationId: Value(operationId),
                medio: Value(medio?.storageValue),
              ),
            );
        await _guardarImpactoMovimiento(
          origen: 'pago_deuda',
          origenId: paymentId,
          medio: medio,
          monto: -monto,
          reclassified: reclassified,
        );

        final totalAbonadoDespues = totalAbonadoAntes + monto;
        final nuevoSaldo = deuda.montoOriginal - totalAbonadoDespues;
        final cuotasPagadasActualizadas = nuevoSaldo <= 1e-8
            ? deuda.cuotasTotales
            : ((totalAbonadoDespues + 1e-8) / deuda.cuota).floor().clamp(
                0,
                deuda.cuotasTotales,
              );

        await (_database.update(
          _database.deudas,
        )..where((item) => item.id.equals(deudaId))).write(
          DeudasCompanion(cuotasPagadas: Value(cuotasPagadasActualizadas)),
        );
        return paymentId;
      }),
    );
  }

  Future<void> confirmarRevisionCuotasLegadas(int deudaId) {
    return _modificar('revisar cuotas históricas', () async {
      final updatedRows =
          await (_database.update(
            _database.deudas,
          )..where((deuda) => deuda.id.equals(deudaId))).write(
            const DeudasCompanion(cuotasLegadasRevisadas: Value(true)),
          );
      if (updatedRows == 0) throw StateError('La deuda ya no existe.');
    });
  }

  Future<List<PagosDeudaData>> obtenerPagosDeuda(int deudaId) {
    return _ejecutar(
      'obtener pagos de deuda',
      () => (_database.select(
        _database.pagosDeuda,
      )..where((pago) => pago.deudaId.equals(deudaId))).get(),
    );
  }

  Future<List<PagosDeudaData>> obtenerTodosLosPagosDeuda() {
    return _ejecutar(
      'obtener todos los pagos de deuda',
      () => _database.select(_database.pagosDeuda).get(),
    );
  }

  Future<int> eliminarDeuda(int id) {
    return _modificar(
      'eliminar deuda',
      () => _database.transaction(() async {
        final payments = await (_database.select(
          _database.pagosDeuda,
        )..where((payment) => payment.deudaId.equals(id))).get();
        for (final payment in payments) {
          await _eliminarImpactoMovimiento(
            origen: 'pago_deuda',
            origenId: payment.id,
          );
        }
        final deleted = await (_database.delete(
          _database.deudas,
        )..where((deuda) => deuda.id.equals(id))).go();
        await _validarAsignacionDentroDelSaldo();
        return deleted;
      }),
    );
  }

  Future<T> _ejecutar<T>(
    String operacion,
    Future<T> Function() consulta,
  ) async {
    try {
      return await consulta();
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        DatabaseServiceException(operacion, error),
        stackTrace,
      );
    }
  }

  Future<T> _modificar<T>(
    String operacion,
    Future<T> Function() mutacion,
  ) async {
    final resultado = await _ejecutar(operacion, mutacion);
    if (!_financialChanges.isClosed) _financialChanges.add(null);
    return resultado;
  }

  Future<int> _insertarIngreso({
    required double monto,
    required DateTime fecha,
    required String tipo,
    String? descripcion,
    MoneyMedium? medio,
    int? cuentaDigitalId,
  }) {
    return _database
        .into(_database.ingresos)
        .insert(
          IngresosCompanion.insert(
            monto: monto,
            tipo: Value(tipo),
            fecha: fecha,
            descripcion: Value(descripcion),
            medio: Value(medio?.storageValue),
            cuentaDigitalId: Value(cuentaDigitalId),
          ),
        );
  }

  Future<void> _validarDestinosIngreso(
    double amount,
    List<IncomeDestination> destinations,
  ) async {
    if (destinations.isEmpty) {
      throw ArgumentError('Distribuye el ingreso antes de guardarlo.');
    }
    var total = 0.0;
    final uniqueDestinations = <String>{};
    for (final destination in destinations) {
      _validarMonto(destination.monto);
      await _validarCuentaDigital(
        destination.medio,
        destination.cuentaDigitalId,
      );
      if (destination.medio == MoneyMedium.digital &&
          destination.cuentaDigitalId == null) {
        throw ArgumentError('Elige una cuenta para cada destino digital.');
      }
      if (destination.medio == MoneyMedium.cash &&
          destination.cuentaDigitalId != null) {
        throw ArgumentError('El efectivo no puede asociarse a una cuenta.');
      }
      final key =
          '${destination.medio.storageValue}:'
          '${destination.cuentaDigitalId ?? 'cash'}';
      if (!uniqueDestinations.add(key)) {
        throw ArgumentError('Cada destino debe aparecer una sola vez.');
      }
      total += destination.monto;
    }
    if ((total - amount).abs() > 1e-8) {
      throw ArgumentError.value(
        total,
        'distribución',
        total < amount
            ? 'Faltan ${(amount - total).toStringAsFixed(2)} por distribuir.'
            : 'Sobran ${(total - amount).toStringAsFixed(2)} en la distribución.',
      );
    }
  }

  IncomeDestination _toIncomeDestination(IngresoDistribucione row) {
    final medium = MoneyMedium.fromStorage(row.medio);
    if (medium == null) {
      throw StateError('El ingreso tiene un destino con medio no válido.');
    }
    return IncomeDestination(
      medio: medium,
      monto: row.monto,
      cuentaDigitalId: row.cuentaDigitalId,
    );
  }

  Future<void> _guardarDestinosIngreso(
    int incomeId,
    List<IncomeDestination> destinations,
  ) async {
    for (final destination in destinations) {
      final destinationId = await _database
          .into(_database.ingresoDistribuciones)
          .insert(
            IngresoDistribucionesCompanion.insert(
              ingresoId: incomeId,
              medio: destination.medio.storageValue,
              monto: destination.monto,
              cuentaDigitalId: Value(destination.cuentaDigitalId),
            ),
          );
      await _insertarEventoAsignacion(
        destination.medio,
        destination.monto,
        origen: 'ingreso_destino',
        origenId: destinationId,
        cuentaDigitalId: destination.cuentaDigitalId,
      );
    }
  }

  Future<void> _eliminarDestinosIngreso(int incomeId) async {
    final destinations = await (_database.select(
      _database.ingresoDistribuciones,
    )..where((item) => item.ingresoId.equals(incomeId))).get();
    for (final destination in destinations) {
      await _eliminarImpactoMovimiento(
        origen: 'ingreso_destino',
        origenId: destination.id,
      );
    }
    await (_database.delete(
      _database.ingresoDistribuciones,
    )..where((item) => item.ingresoId.equals(incomeId))).go();
  }

  Future<double> _calcularTotalAhorros() async {
    final movimientos = await _database
        .select(_database.movimientosAhorro)
        .get();
    return movimientos.fold<double>(0, (total, movimiento) {
      return movimiento.tipo == aporteAhorro
          ? total + movimiento.monto
          : total - movimiento.monto;
    });
  }

  Future<double> _calcularSaldoDisponible() async {
    return (await _calcularDesgloseSaldos()).total;
  }

  Future<AvailableBalanceBreakdown> _calcularDesgloseSaldos() async {
    final results = await Future.wait<Object>([
      _database.select(_database.ingresos).get(),
      _database.select(_database.gastos).get(),
      _database.select(_database.pagosDeuda).get(),
      _database.select(_database.movimientosPrestamo).get(),
      _database.select(_database.movimientosAhorro).get(),
      _database.select(_database.movimientosReservaGastoFuturo).get(),
    ]);
    final ingresos = results[0] as List<Ingreso>;
    final gastos = results[1] as List<Gasto>;
    final pagos = results[2] as List<PagosDeudaData>;
    final movimientosPrestamos = results[3] as List<MovimientosPrestamoData>;
    final movimientos = results[4] as List<MovimientosAhorroData>;
    final reservas = results[5] as List<MovimientosReservaGastoFuturoData>;

    final totalIngresos = ingresos.fold<double>(
      0,
      (total, ingreso) => total + ingreso.monto,
    );
    final totalGastos = gastos.fold<double>(
      0,
      (total, gasto) => total + gasto.monto,
    );
    final totalPagos = pagos.fold<double>(
      0,
      (total, pago) => total + pago.monto,
    );
    final impactoPrestamos = movimientosPrestamos.fold<double>(
      0,
      (total, movimiento) => movimiento.tipo == entregaPrestamo
          ? total - movimiento.monto
          : movimiento.tipo == devolucionPrestamo
          ? total + movimiento.monto
          : total,
    );
    final ahorroNeto = movimientos.fold<double>(0, (total, movimiento) {
      return movimiento.tipo == aporteAhorro
          ? total + movimiento.monto
          : total - movimiento.monto;
    });
    final reservaNeta = reservas.fold<double>(
      0,
      (total, movement) => movement.tipo == reservaGastoFuturo
          ? total + movement.monto
          : movement.tipo == liberacionGastoFuturo
          ? total - movement.monto
          : total,
    );
    final total =
        totalIngresos -
        totalGastos -
        totalPagos -
        ahorroNeto +
        impactoPrestamos -
        reservaNeta;

    final assigned = await _calcularSaldoAsignado();

    return AvailableBalanceBreakdown(
      cash: assigned.cash,
      digital: assigned.digital,
      unclassified: total - assigned.cash - assigned.digital,
      total: total,
    );
  }

  Future<int> _guardarTransferencia({
    required MoneyMedium medioOrigen,
    required int? cuentaOrigenId,
    required MoneyMedium medioDestino,
    required int? cuentaDestinoId,
    required double monto,
    required DateTime fecha,
    required String? nota,
  }) async {
    _validarMonto(monto);
    await _validarCuentaDigital(medioOrigen, cuentaOrigenId);
    await _validarCuentaDigital(medioDestino, cuentaDestinoId);
    if (medioOrigen == medioDestino && cuentaOrigenId == cuentaDestinoId) {
      throw ArgumentError(
        'El origen y el destino de la transferencia deben ser diferentes.',
      );
    }

    final available = cuentaOrigenId == null
        ? await _saldoDisponibleSinCuenta(medioOrigen)
        : await _calcularSaldoCuentaDigital(cuentaOrigenId);
    if (monto > available + 1e-8) {
      throw ArgumentError.value(
        monto,
        'monto',
        'No hay suficiente saldo en el origen (${available.toStringAsFixed(2)}).',
      );
    }

    final id = await _database
        .into(_database.transferenciasDinero)
        .insert(
          TransferenciasDineroCompanion.insert(
            medioOrigen: medioOrigen.storageValue,
            cuentaOrigenId: Value(cuentaOrigenId),
            medioDestino: medioDestino.storageValue,
            cuentaDestinoId: Value(cuentaDestinoId),
            monto: monto,
            fecha: fecha,
            nota: Value(_cleanOptionalText(nota)),
          ),
        );
    await _guardarImpactosTransferencia(
      id: id,
      medioOrigen: medioOrigen,
      cuentaOrigenId: cuentaOrigenId,
      medioDestino: medioDestino,
      cuentaDestinoId: cuentaDestinoId,
      monto: monto,
    );
    return id;
  }

  Future<int> _guardarImpactosTransferencia({
    required int id,
    required MoneyMedium medioOrigen,
    required int? cuentaOrigenId,
    required MoneyMedium medioDestino,
    required int? cuentaDestinoId,
    required double monto,
  }) async {
    _validarMonto(monto);
    await _validarCuentaDigital(medioOrigen, cuentaOrigenId);
    await _validarCuentaDigital(medioDestino, cuentaDestinoId);
    if (medioOrigen == medioDestino && cuentaOrigenId == cuentaDestinoId) {
      throw ArgumentError(
        'El origen y el destino de la transferencia deben ser diferentes.',
      );
    }
    final available = cuentaOrigenId == null
        ? await _saldoDisponibleSinCuenta(medioOrigen)
        : await _calcularSaldoCuentaDigital(cuentaOrigenId);
    if (monto > available + 1e-8) {
      throw ArgumentError.value(
        monto,
        'monto',
        'No hay suficiente saldo en el origen (${available.toStringAsFixed(2)}).',
      );
    }
    await _insertarEventoAsignacion(
      medioOrigen,
      -monto,
      origen: 'transferencia_salida',
      origenId: id,
      cuentaDigitalId: cuentaOrigenId,
    );
    await _insertarEventoAsignacion(
      medioDestino,
      monto,
      origen: 'transferencia_entrada',
      origenId: id,
      cuentaDigitalId: cuentaDestinoId,
    );
    await _validarAsignacionDentroDelSaldo();
    return id;
  }

  Future<double> _saldoDisponibleSinCuenta(MoneyMedium medio) async {
    final balances = await _calcularDesgloseSaldos();
    if (medio == MoneyMedium.cash) return balances.cash;
    final accounts = await obtenerCuentasDigitales();
    final accounted = accounts.fold<double>(
      0,
      (total, account) => total + account.balance,
    );
    return balances.digital - accounted;
  }

  Future<double> _calcularSaldoCuentaDigital(int accountId) async {
    final events = await (_database.select(
      _database.asignacionesDinero,
    )..where((event) => event.cuentaDigitalId.equals(accountId))).get();
    return events.fold<double>(0, (total, event) => total + event.monto);
  }

  Future<void> _validarCuentaDigital(
    MoneyMedium? medio,
    int? cuentaDigitalId,
  ) async {
    if (cuentaDigitalId == null) return;
    if (medio != MoneyMedium.digital) {
      throw ArgumentError(
        'Solo puedes asociar una cuenta a un movimiento digital.',
      );
    }
    final account = await (_database.select(
      _database.cuentasDigitales,
    )..where((item) => item.id.equals(cuentaDigitalId))).getSingleOrNull();
    if (account == null) throw StateError('La cuenta digital ya no existe.');
  }

  Future<({double cash, double digital})> _calcularSaldoAsignado() async {
    final events = await _database.select(_database.asignacionesDinero).get();
    var cash = 0.0;
    var digital = 0.0;
    for (final event in events) {
      switch (MoneyMedium.fromStorage(event.medio)) {
        case MoneyMedium.cash:
          cash += event.monto;
        case MoneyMedium.digital:
          digital += event.monto;
        case null:
          throw StateError('Hay una asignación con medio no válido.');
      }
    }
    return (cash: cash, digital: digital);
  }

  Future<void> _insertarEventoAsignacion(
    MoneyMedium medio,
    double monto, {
    String? origen,
    int? origenId,
    int? cuentaDigitalId,
  }) async {
    if (monto.abs() <= 1e-8) return;
    await _database
        .into(_database.asignacionesDinero)
        .insert(
          AsignacionesDineroCompanion.insert(
            medio: medio.storageValue,
            monto: monto,
            cuentaDigitalId: Value(cuentaDigitalId),
            origen: Value(origen),
            origenId: Value(origenId),
          ),
        );
  }

  Future<void> _guardarImpactoMovimiento({
    required String origen,
    required int origenId,
    required MoneyMedium? medio,
    required double monto,
    bool crearSiNoExiste = true,
    double reclassified = 0,
    int? cuentaDigitalId,
  }) async {
    final existing =
        await (_database.select(_database.asignacionesDinero)..where(
              (event) =>
                  event.origen.equals(origen) & event.origenId.equals(origenId),
            ))
            .getSingleOrNull();
    if (existing == null && (!crearSiNoExiste || medio == null)) return;
    if (existing == null) {
      if (medio != null && reclassified > 1e-8) {
        await _insertarEventoAsignacion(
          medio,
          reclassified,
          origen: '${origen}_asignacion',
          origenId: origenId,
          cuentaDigitalId: cuentaDigitalId,
        );
      }
      await _insertarEventoAsignacion(
        medio!,
        monto,
        origen: origen,
        origenId: origenId,
        cuentaDigitalId: cuentaDigitalId,
      );
      return;
    }
    final reclassification =
        await (_database.select(_database.asignacionesDinero)..where(
              (event) =>
                  event.origen.equals('${origen}_asignacion') &
                  event.origenId.equals(origenId),
            ))
            .getSingleOrNull();
    if (medio != null && reclassified > 1e-8) {
      if (reclassification == null) {
        await _insertarEventoAsignacion(
          medio,
          reclassified,
          origen: '${origen}_asignacion',
          origenId: origenId,
          cuentaDigitalId: cuentaDigitalId,
        );
      } else {
        await (_database.update(
          _database.asignacionesDinero,
        )..where((event) => event.id.equals(reclassification.id))).write(
          AsignacionesDineroCompanion(
            medio: Value(medio.storageValue),
            monto: Value(reclassified),
            cuentaDigitalId: Value(cuentaDigitalId),
          ),
        );
      }
    } else if (reclassification != null) {
      await (_database.delete(
        _database.asignacionesDinero,
      )..where((event) => event.id.equals(reclassification.id))).go();
    }
    if (medio == null || monto.abs() <= 1e-8) {
      await (_database.delete(
        _database.asignacionesDinero,
      )..where((event) => event.id.equals(existing.id))).go();
      return;
    }
    await (_database.update(
      _database.asignacionesDinero,
    )..where((event) => event.id.equals(existing.id))).write(
      AsignacionesDineroCompanion(
        medio: Value(medio.storageValue),
        monto: Value(monto),
        cuentaDigitalId: Value(cuentaDigitalId),
      ),
    );
  }

  Future<void> _eliminarImpactoMovimiento({
    required String origen,
    required int origenId,
  }) async {
    await (_database.delete(_database.asignacionesDinero)..where(
          (event) =>
              (event.origen.equals(origen) |
                  event.origen.equals('${origen}_asignacion')) &
              event.origenId.equals(origenId),
        ))
        .go();
  }

  Future<double> _validarCanalDisponible({
    required MoneyMedium? medio,
    required double monto,
    int? cuentaDigitalId,
  }) async {
    final balances = await _calcularDesgloseSaldos();
    if (medio == null) {
      if (monto <= balances.unclassified + 1e-8) return 0;
      throw ArgumentError.value(
        monto,
        'monto',
        'No hay suficiente dinero sin distribuir para esta operación.',
      );
    }

    final assigned = cuentaDigitalId == null
        ? medio == MoneyMedium.cash
              ? balances.cash
              : balances.digital
        : await _calcularSaldoCuentaDigital(cuentaDigitalId);
    if (cuentaDigitalId != null && monto > assigned + 1e-8) {
      throw ArgumentError.value(
        monto,
        'monto',
        'No hay suficiente saldo en esa cuenta digital ($assigned).',
      );
    }
    final reclassified = (monto - assigned).clamp(0.0, monto);
    if (reclassified > balances.unclassified + 1e-8) {
      throw ArgumentError.value(
        monto,
        'monto',
        'No hay suficiente saldo en ${medio.label.toLowerCase()} '
            '($assigned). Distribuye el dinero primero.',
      );
    }
    return reclassified;
  }

  Future<void> _validarAsignacionDentroDelSaldo() async {
    final balances = await _calcularDesgloseSaldos();
    if (balances.cash < -1e-8 ||
        balances.digital < -1e-8 ||
        balances.cash + balances.digital > balances.total + 1e-8) {
      throw StateError(
        'La operación dejaría la distribución por encima del saldo '
        'disponible. Reduce primero la distribución.',
      );
    }
  }

  Future<double> _totalReservadoPlan(int planId) async {
    final movements = await (_database.select(
      _database.movimientosReservaGastoFuturo,
    )..where((movement) => movement.gastoFuturoId.equals(planId))).get();
    return movements.fold<double>(
      0,
      (total, movement) => movement.tipo == reservaGastoFuturo
          ? total + movement.monto
          : movement.tipo == liberacionGastoFuturo
          ? total - movement.monto
          : total,
    );
  }

  FutureExpensePlan _toFutureExpensePlan(GastosFuturo row) {
    return FutureExpensePlan(
      id: row.id,
      name: row.nombre,
      category: row.categoria,
      targetAmount: row.montoNecesario,
      plannedAmount: row.montoPlaneado,
      frequency: FutureExpenseFrequency.fromStorage(row.frecuencia),
      targetDate: row.fechaObjetivo,
      startDate: row.fechaInicio,
      notes: row.notas,
      status: FutureExpenseStatus.fromStorage(row.estado),
    );
  }

  bool _sameDate(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  DateTime _nextSubscriptionDate(
    DateTime current,
    SubscriptionFrequency frequency,
  ) {
    if (frequency == SubscriptionFrequency.weekly) {
      return current.add(const Duration(days: 7));
    }
    final months = switch (frequency) {
      SubscriptionFrequency.monthly => 1,
      SubscriptionFrequency.quarterly => 3,
      SubscriptionFrequency.yearly => 12,
      SubscriptionFrequency.weekly => throw StateError(
        'La frecuencia semanal ya se resolvió.',
      ),
    };
    final monthIndex = current.month - 1 + months;
    final year = current.year + monthIndex ~/ 12;
    final month = monthIndex % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(
      year,
      month,
      current.day.clamp(1, lastDay),
      current.hour,
      current.minute,
      current.second,
      current.millisecond,
      current.microsecond,
    );
  }

  void _validarPlanFuturo({
    required String nombre,
    required String categoria,
    required double montoNecesario,
    required double montoPlaneado,
  }) {
    if (nombre.trim().isEmpty || categoria.trim().isEmpty) {
      throw ArgumentError('El nombre y la categoría son obligatorios.');
    }
    if (!montoNecesario.isFinite || montoNecesario <= 0) {
      throw ArgumentError.value(
        montoNecesario,
        'montoNecesario',
        'Debe ser mayor que cero.',
      );
    }
    if (!montoPlaneado.isFinite ||
        montoPlaneado < 0 ||
        montoPlaneado > montoNecesario) {
      throw ArgumentError.value(
        montoPlaneado,
        'montoPlaneado',
        'Debe estar entre cero y el valor necesario.',
      );
    }
  }

  String? _cleanOptionalText(String? value) {
    final cleaned = value?.trim();
    return cleaned == null || cleaned.isEmpty ? null : cleaned;
  }

  void _validarMonto(double monto) {
    if (!monto.isFinite || monto <= 0) {
      throw ArgumentError.value(monto, 'monto', 'Debe ser mayor que cero.');
    }
  }
}

class DatabaseServiceException implements Exception {
  const DatabaseServiceException(this.operacion, this.causa);

  final String operacion;
  final Object causa;

  @override
  String toString() => 'Error al $operacion: $causa';
}

class AvailableBalanceBreakdown {
  const AvailableBalanceBreakdown({
    required this.cash,
    required this.digital,
    required this.unclassified,
    required this.total,
  });

  final double cash;
  final double digital;
  final double unclassified;
  final double total;
}

class DigitalAccountBalance {
  const DigitalAccountBalance({required this.account, required this.balance});

  final CuentasDigitale account;
  final double balance;
}

class IncomeDestination {
  const IncomeDestination({
    required this.medio,
    required this.monto,
    this.cuentaDigitalId,
  });

  final MoneyMedium medio;
  final double monto;
  final int? cuentaDigitalId;
}
