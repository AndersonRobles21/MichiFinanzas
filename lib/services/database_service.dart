import 'dart:async';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/future_expense.dart';
import '../models/income_type.dart';

class DatabaseService {
  DatabaseService(this._database);

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
        await _database.delete(_database.pagosDeuda).go();
        await _database.delete(_database.deudas).go();
        await _database.delete(_database.movimientosPrestamo).go();
        await _database.delete(_database.prestamosTerceros).go();
        await _database.delete(_database.movimientosReservaGastoFuturo).go();
        await _database.delete(_database.gastosFuturos).go();
        await _database.delete(_database.movimientosAhorro).go();
        await _database.delete(_database.gastos).go();
        await _database.delete(_database.ingresos).go();
      }),
    );
  }

  Future<int> agregarIngreso({
    required double monto,
    required DateTime fecha,
    String? descripcion,
    String tipo = 'ingreso',
  }) {
    return _modificar('agregar ingreso', () async {
      _validarMonto(monto);
      return _insertarIngreso(
        monto: monto,
        fecha: fecha,
        descripcion: descripcion,
        tipo: tipo,
      );
    });
  }

  Future<({int ingresoId, int deudaId})> registrarPrestamo({
    required String nombre,
    required double monto,
    required DateTime fechaRecepcion,
    required int cuotasTotales,
    required DateTime fechaPrimerPago,
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

        final incomeId = await _insertarIngreso(
          monto: monto,
          fecha: fechaRecepcion,
          descripcion: nombre.trim(),
          tipo: IncomeType.loan.storageValue,
        );
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
              previous.fecha != fecha) {
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
        return _database
            .into(_database.movimientosReservaGastoFuturo)
            .insert(
              MovimientosReservaGastoFuturoCompanion.insert(
                gastoFuturoId: Value(planId),
                nombrePlan: plan.nombre,
                tipo: reservaGastoFuturo,
                monto: monto,
                fecha: fecha,
                operationId: operationId,
              ),
            );
      }),
    );
  }

  Future<int> liberarReservaGastoFuturo({
    required int planId,
    required double monto,
    required DateTime fecha,
    required String operationId,
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
              previous.fecha != fecha) {
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
        return _database
            .into(_database.movimientosReservaGastoFuturo)
            .insert(
              MovimientosReservaGastoFuturoCompanion.insert(
                gastoFuturoId: Value(planId),
                nombrePlan: plan.nombre,
                tipo: liberacionGastoFuturo,
                monto: monto,
                fecha: fecha,
                operationId: operationId,
              ),
            );
      }),
    );
  }

  Future<int> registrarPrestamoTercero({
    required String persona,
    required double monto,
    required DateTime fechaEntrega,
    required DateTime fechaDevolucionAcordada,
    required String operationId,
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
        if (monto > disponible) {
          throw ArgumentError.value(
            monto,
            'monto',
            'No puedes prestar más que tu saldo disponible ($disponible).',
          );
        }

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
        await _database
            .into(_database.movimientosPrestamo)
            .insert(
              MovimientosPrestamoCompanion.insert(
                prestamoId: loanId,
                tipo: entregaPrestamo,
                monto: monto,
                fecha: fechaEntrega,
                operationId: operationId,
              ),
            );
        return loanId;
      }),
    );
  }

  Future<int> registrarDevolucionPrestamo({
    required int prestamoId,
    required double monto,
    required DateTime fecha,
    required String operationId,
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
              previousMovement.fecha != fecha) {
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

        return _database
            .into(_database.movimientosPrestamo)
            .insert(
              MovimientosPrestamoCompanion.insert(
                prestamoId: prestamoId,
                tipo: devolucionPrestamo,
                monto: monto,
                fecha: fecha,
                operationId: operationId,
              ),
            );
      }),
    );
  }

  Future<double> obtenerTotalAhorros() {
    return _ejecutar('obtener total de ahorros', _calcularTotalAhorros);
  }

  Future<double> obtenerSaldoDisponible() {
    return _ejecutar('obtener saldo disponible', _calcularSaldoDisponible);
  }

  Future<int> registrarAporteAhorro({
    required double monto,
    required DateTime fecha,
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
        return _database
            .into(_database.movimientosAhorro)
            .insert(
              MovimientosAhorroCompanion.insert(
                monto: monto,
                tipo: aporteAhorro,
                fecha: fecha,
              ),
            );
      });
    });
  }

  Future<int> retirarAhorro({required double monto, required DateTime fecha}) {
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
        return _database
            .into(_database.movimientosAhorro)
            .insert(
              MovimientosAhorroCompanion.insert(
                monto: monto,
                tipo: retiroAhorro,
                fecha: fecha,
              ),
            );
      });
    });
  }

  Stream<void> observarCambiosFinancieros() => _financialChanges.stream;

  Future<int> eliminarIngreso(int id) {
    return _modificar(
      'eliminar ingreso',
      () => (_database.delete(
        _database.ingresos,
      )..where((ingreso) => ingreso.id.equals(id))).go(),
    );
  }

  Future<int> agregarGasto({
    required String nombre,
    required double monto,
    required String categoria,
    required DateTime fecha,
    String? nota,
  }) {
    return _modificar(
      'agregar gasto',
      () => _database
          .into(_database.gastos)
          .insert(
            GastosCompanion.insert(
              nombre: nombre,
              monto: monto,
              categoria: categoria,
              fecha: fecha,
              nota: Value(nota),
            ),
          ),
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
      () => (_database.delete(
        _database.gastos,
      )..where((gasto) => gasto.id.equals(id))).go(),
    );
  }

  Future<int> actualizarGasto({
    required int id,
    required String nombre,
    required double monto,
    required String categoria,
    required DateTime fecha,
    String? nota,
  }) {
    return _modificar('actualizar gasto', () async {
      _validarMonto(monto);
      if (nombre.trim().isEmpty || categoria.trim().isEmpty) {
        throw ArgumentError('El nombre y la categoría son obligatorios.');
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
            ),
          );
      if (updatedRows == 0) throw StateError('El gasto ya no existe.');
      return updatedRows;
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
              previousPayment.fecha != fecha) {
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

        final paymentId = await _database
            .into(_database.pagosDeuda)
            .insert(
              PagosDeudaCompanion.insert(
                deudaId: deudaId,
                monto: monto,
                fecha: fecha,
                operationId: Value(operationId),
              ),
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
      () => (_database.delete(
        _database.deudas,
      )..where((deuda) => deuda.id.equals(id))).go(),
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
  }) {
    return _database
        .into(_database.ingresos)
        .insert(
          IngresosCompanion.insert(
            monto: monto,
            tipo: Value(tipo),
            fecha: fecha,
            descripcion: Value(descripcion),
          ),
        );
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
    final ingresos = await _database.select(_database.ingresos).get();
    final gastos = await _database.select(_database.gastos).get();
    final pagos = await _database.select(_database.pagosDeuda).get();
    final movimientosPrestamos = await _database
        .select(_database.movimientosPrestamo)
        .get();
    final movimientos = await _database
        .select(_database.movimientosAhorro)
        .get();
    final reservasGastosFuturos = await _database
        .select(_database.movimientosReservaGastoFuturo)
        .get();
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
    final reservaNeta = reservasGastosFuturos.fold<double>(
      0,
      (total, movement) => movement.tipo == reservaGastoFuturo
          ? total + movement.monto
          : movement.tipo == liberacionGastoFuturo
          ? total - movement.monto
          : total,
    );
    return totalIngresos -
        totalGastos -
        totalPagos -
        ahorroNeto +
        impactoPrestamos -
        reservaNeta;
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
