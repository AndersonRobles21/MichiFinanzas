import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finanzas_app/database/app_database.dart';
import 'package:finanzas_app/models/money_medium.dart';
import 'package:finanzas_app/services/database_service.dart';
import 'package:finanzas_app/utils/credit_installments.dart';

void main() {
  test('monthly due dates stay anchored to the original day', () {
    expect(monthlyInstallmentDates(DateTime(2024, 1, 31), 3), [
      DateTime(2024, 1, 31),
      DateTime(2024, 2, 29),
      DateTime(2024, 3, 31),
    ]);
    expect(monthlyInstallmentDates(DateTime(2025, 1, 31), 3), [
      DateTime(2025, 1, 31),
      DateTime(2025, 2, 28),
      DateTime(2025, 3, 31),
    ]);
  });

  test(
    'credit purchases use the limit and create only a debt until payment',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final service = DatabaseService(database);
      final date = DateTime(2026, 1, 31);
      try {
        await service.agregarIngreso(monto: 200, fecha: date);
        final entityId = await service.crearEntidadCredito(
          nombre: 'Entidad de prueba',
          cupoAprobado: 200,
          fecha: date,
        );

        final purchaseId = await service.registrarCompraCredito(
          entidadId: entityId,
          descripcion: 'Audífonos',
          monto: 100,
          categoria: 'Compras',
          fecha: date,
          cuotasTotales: 3,
          valorCuota: 40,
          primerVencimiento: date,
        );

        var summary = (await service.obtenerEntidadesCredito()).single;
        expect(summary.cupoUtilizado, 100);
        expect(summary.cupoDisponible, 100);
        expect(summary.deudaPendiente, 100);
        expect(await service.obtenerSaldoDisponible(), 200);
        expect(await service.obtenerGastos(), isEmpty);
        expect(await service.obtenerDeudas(), hasLength(1));
        expect(
          await database.customSelect('PRAGMA foreign_key_check').get(),
          isEmpty,
        );

        final detail = (await service.obtenerComprasCredito(entityId)).single;
        expect(detail.compra.id, purchaseId);
        expect(detail.cuotas.map((item) => item.monto), [40, 40, 20]);
        expect(detail.cuotas.map((item) => item.vencimiento), [
          date,
          DateTime(2026, 2, 28),
          DateTime(2026, 3, 31),
        ]);
        expect(
          detail.cuotas.fold<double>(0, (sum, item) => sum + item.monto),
          100,
        );

        await service.renombrarCategoriaGastos(
          nombreAnterior: 'Compras',
          nombreNuevo: 'Compras personales',
        );
        expect(await service.obtenerGastos(), isEmpty);
        expect(
          (await service.obtenerComprasCredito(
            entityId,
          )).single.compra.categoria,
          'Compras personales',
        );

        await expectLater(
          service.registrarCompraCredito(
            entidadId: entityId,
            descripcion: 'Compra que excede el cupo',
            monto: 101,
            categoria: 'Compras',
            fecha: date,
            cuotasTotales: 1,
            valorCuota: 101,
            primerVencimiento: date,
          ),
          throwsA(isA<DatabaseServiceException>()),
        );
        await expectLater(
          service.actualizarCupoCredito(
            entidadId: entityId,
            nuevoCupo: 99,
            fecha: date,
          ),
          throwsA(isA<DatabaseServiceException>()),
        );
        await expectLater(
          service.retirarEntidadCredito(entityId),
          throwsA(isA<DatabaseServiceException>()),
        );

        await service.actualizarCupoCredito(
          entidadId: entityId,
          nuevoCupo: 250,
          fecha: DateTime(2026, 2, 1),
        );
        await service.registrarPagoDeuda(
          deudaId: detail.compra.deudaId,
          monto: 40,
          fecha: DateTime(2026, 2, 28),
          operationId: 'credit-test-payment-1',
          medio: MoneyMedium.cash,
        );

        summary = (await service.obtenerEntidadesCredito()).single;
        expect(summary.entidad.cupoAprobado, 250);
        expect(summary.cupoUtilizado, 100);
        expect(summary.cupoDisponible, 150);
        expect(summary.deudaPendiente, 60);
        expect(await service.obtenerSaldoDisponible(), 160);
        expect(await service.obtenerGastos(), hasLength(1));
        expect((await service.obtenerGastos()).single.monto, 40);
        expect(await service.obtenerDeudasCreditoIds(), {
          detail.compra.deudaId,
        });
        expect(
          await service.obtenerHistorialCupoCredito(entityId),
          hasLength(2),
        );
        final limitHistory = await service.obtenerHistorialCupoCredito(
          entityId,
        );
        expect(limitHistory.map((change) => change.cupoAnterior), [200, 0]);
        expect(limitHistory.map((change) => change.cupoNuevo), [250, 200]);
        expect(limitHistory.map((change) => change.fecha), [
          DateTime(2026, 2, 1),
          date,
        ]);
        expect(await service.obtenerTodosLosPagosDeuda(), hasLength(1));

        final expense = (await service.obtenerGastos()).single;
        await expectLater(
          service.eliminarGasto(expense.id),
          throwsA(isA<DatabaseServiceException>()),
        );
        await expectLater(
          service.eliminarDeuda(detail.compra.deudaId),
          throwsA(isA<DatabaseServiceException>()),
        );
        await expectLater(
          service.retirarEntidadCredito(entityId),
          throwsA(isA<DatabaseServiceException>()),
        );

        await service.registrarPagoDeuda(
          deudaId: detail.compra.deudaId,
          monto: 60,
          fecha: DateTime(2026, 3, 31),
          operationId: 'credit-test-payment-2',
          medio: MoneyMedium.cash,
        );
        summary = (await service.obtenerEntidadesCredito()).single;
        expect(summary.cupoUtilizado, 100);
        expect(summary.deudaPendiente, 0);
        expect(await service.obtenerGastos(), hasLength(2));
        expect(
          (await service.obtenerGastos()).fold<double>(
            0,
            (total, expense) => total + expense.monto,
          ),
          100,
        );

        await service.retirarEntidadCredito(entityId);
        expect(await service.obtenerEntidadesCredito(), isEmpty);
        final retired = (await service.obtenerEntidadesCredito(
          incluirRetiradas: true,
        )).single;
        expect(retired.cupoUtilizado, 100);
        expect(await service.obtenerGastos(), hasLength(2));
        expect(await service.obtenerDeudas(), hasLength(1));
      } finally {
        await database.close();
      }
    },
  );

  test(
    'credit purchase payments use a digital account without releasing limit',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final service = DatabaseService(database);
      final date = DateTime(2026, 4, 10);
      try {
        final accountId = await service.crearCuentaDigital('Billetera');
        await service.agregarIngreso(
          monto: 100,
          fecha: date,
          medio: MoneyMedium.digital,
          cuentaDigitalId: accountId,
        );
        final entityId = await service.crearEntidadCredito(
          nombre: 'Entidad digital',
          cupoAprobado: 150,
          fecha: date,
        );
        final purchaseId = await service.registrarCompraCredito(
          entidadId: entityId,
          descripcion: 'Compra financiada',
          monto: 100,
          categoria: 'Compras',
          fecha: date,
          cuotasTotales: 2,
          valorCuota: 50,
          primerVencimiento: date,
        );
        final purchase = (await service.obtenerComprasCredito(entityId)).single;

        expect(purchase.compra.id, purchaseId);
        expect((await service.obtenerCuentasDigitales()).single.balance, 100);
        expect(await service.obtenerGastos(), isEmpty);
        expect(await service.obtenerDeudas(), hasLength(1));

        final paymentId = await service.registrarPagoDeuda(
          deudaId: purchase.compra.deudaId,
          monto: 40,
          fecha: date,
          operationId: 'account-payment-1',
          medio: MoneyMedium.digital,
          cuentaDigitalId: accountId,
        );
        final replayedId = await service.registrarPagoDeuda(
          deudaId: purchase.compra.deudaId,
          monto: 40,
          fecha: date,
          operationId: 'account-payment-1',
          medio: MoneyMedium.digital,
          cuentaDigitalId: accountId,
        );

        expect(replayedId, paymentId);
        expect(
          (await service.obtenerPagosDeuda(
            purchase.compra.deudaId,
          )).single.cuentaDigitalId,
          accountId,
        );
        expect((await service.obtenerCuentasDigitales()).single.balance, 60);
        final summary = (await service.obtenerEntidadesCredito()).single;
        expect(summary.entidad.cupoAprobado, 150);
        expect(summary.cupoUtilizado, 100);
        expect(summary.cupoDisponible, 50);
        expect(summary.deudaPendiente, 60);
        expect((await service.obtenerDeudas()).single.cuotasPagadas, 0);
        final expenses = await service.obtenerGastos();
        expect(expenses, hasLength(1));
        expect(expenses.single.monto, 40);
        expect(expenses.single.pagoDeudaId, paymentId);
        expect(expenses.single.cuentaDigitalId, accountId);
        expect(
          await database.customSelect('PRAGMA foreign_key_check').get(),
          isEmpty,
        );
      } finally {
        await database.close();
      }
    },
  );

  test(
    'legacy credit purchase expenses stay linked but are not expenses',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final service = DatabaseService(database);
      final date = DateTime(2026, 5, 1);
      try {
        await service.agregarIngreso(monto: 200, fecha: date);
        final entityId = await service.crearEntidadCredito(
          nombre: 'Entidad histórica',
          cupoAprobado: 200,
          fecha: date,
        );
        final debtId = await service.agregarDeuda(
          nombre: 'Compra histórica',
          montoOriginal: 100,
          cuota: 50,
          cuotasTotales: 2,
        );
        final expenseId = await database
            .into(database.gastos)
            .insert(
              GastosCompanion.insert(
                nombre: 'Compra histórica',
                monto: 100,
                categoria: 'Compras',
                fecha: date,
              ),
            );
        final purchaseId = await database
            .into(database.comprasCredito)
            .insert(
              ComprasCreditoCompanion.insert(
                entidadId: entityId,
                deudaId: debtId,
                gastoId: Value(expenseId),
                descripcion: 'Compra histórica',
                monto: 100,
                categoria: 'Compras',
                fecha: date,
                cuotasTotales: 2,
                valorCuota: 50,
                primerVencimiento: date,
              ),
            );

        expect(await service.obtenerGastos(), isEmpty);
        expect(await service.obtenerSaldoDisponible(), 200);
        final purchase = (await service.obtenerComprasCredito(entityId)).single;
        expect(purchase.compra.id, purchaseId);
        expect(purchase.compra.gastoId, expenseId);
        expect(purchase.deudaPendiente, 100);
        expect(await service.obtenerDeudas(), hasLength(1));
      } finally {
        await database.close();
      }
    },
  );
}
