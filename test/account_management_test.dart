import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_app/database/app_database.dart';
import 'package:finanzas_app/models/money_medium.dart';
import 'package:finanzas_app/services/database_service.dart';

void main() {
  test(
    'administra cuentas y actualiza saldos en altas, edición y eliminación',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final service = DatabaseService(database);
      final date = DateTime(2026, 10, 20);
      try {
        final accountId = await service.crearCuentaDigital('Mi billetera');
        await expectLater(
          service.crearCuentaDigital('mi BILLETERA'),
          throwsA(isA<DatabaseServiceException>()),
        );
        final incomeId = await service.agregarIngreso(
          monto: 500,
          fecha: date,
          tipo: 'extra',
          medio: MoneyMedium.digital,
          cuentaDigitalId: accountId,
        );
        expect((await service.obtenerCuentasDigitales()).single.balance, 500);

        await expectLater(
          service.agregarGasto(
            nombre: 'Excede la cuenta',
            monto: 501,
            categoria: 'Otros',
            fecha: date,
            medio: MoneyMedium.digital,
            cuentaDigitalId: accountId,
          ),
          throwsA(isA<DatabaseServiceException>()),
        );

        final expenseId = await service.agregarGasto(
          nombre: 'Compra',
          monto: 150,
          categoria: 'Otros',
          fecha: date,
          medio: MoneyMedium.digital,
          cuentaDigitalId: accountId,
        );
        expect((await service.obtenerCuentasDigitales()).single.balance, 350);
        expect((await service.obtenerSaldosPorMedio()).digital, 350);

        await service.actualizarGasto(
          id: expenseId,
          nombre: 'Compra ajustada',
          monto: 200,
          categoria: 'Otros',
          fecha: date,
          medio: MoneyMedium.digital,
          cuentaDigitalId: accountId,
        );
        expect((await service.obtenerCuentasDigitales()).single.balance, 300);
        await expectLater(
          service.distribuirSaldoDisponible(efectivo: 700, digital: 0),
          throwsA(isA<DatabaseServiceException>()),
        );
        expect((await service.obtenerCuentasDigitales()).single.balance, 300);
        await service.eliminarGasto(expenseId);
        expect((await service.obtenerCuentasDigitales()).single.balance, 500);

        await service.actualizarIngreso(
          id: incomeId,
          monto: 600,
          fecha: date,
          descripcion: 'Ingreso editado',
          tipo: 'extra',
          medio: MoneyMedium.digital,
          cuentaDigitalId: accountId,
        );
        expect((await service.obtenerSaldosPorMedio()).total, 600);
        expect((await service.obtenerCuentasDigitales()).single.balance, 600);
        await service.eliminarIngreso(incomeId);
        expect((await service.obtenerSaldosPorMedio()).total, 0);
        expect((await service.obtenerCuentasDigitales()).single.balance, 0);

        await service.actualizarCuentaDigital(
          id: accountId,
          nombre: 'Cuenta propia',
        );
        expect(
          (await service.obtenerCuentasDigitales()).single.account.nombre,
          'Cuenta propia',
        );
        await service.eliminarCuentaDigital(accountId);
        expect(await service.obtenerCuentasDigitales(), isEmpty);
      } finally {
        await database.close();
      }
    },
  );

  test('clasifica ingresos históricos solo cuando se editan', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final service = DatabaseService(database);
    try {
      final accountId = await service.crearCuentaDigital('Billetera');
      final incomeId = await service.agregarIngreso(
        monto: 250,
        fecha: DateTime(2026, 10, 20),
        tipo: 'extra',
      );

      expect((await service.obtenerSaldosPorMedio()).unclassified, 250);

      await service.actualizarIngreso(
        id: incomeId,
        monto: 250,
        fecha: DateTime(2026, 10, 20),
        descripcion: 'Ingreso histórico',
        tipo: 'extra',
        medio: MoneyMedium.digital,
        cuentaDigitalId: accountId,
      );
      var balances = await service.obtenerSaldosPorMedio();
      expect((balances.digital, balances.unclassified), (250, 0));
      expect((await service.obtenerCuentasDigitales()).single.balance, 250);

      await service.actualizarIngreso(
        id: incomeId,
        monto: 300,
        fecha: DateTime(2026, 10, 20),
        descripcion: 'Ingreso histórico actualizado',
        tipo: 'extra',
        medio: MoneyMedium.digital,
        cuentaDigitalId: accountId,
      );
      balances = await service.obtenerSaldosPorMedio();
      expect((balances.digital, balances.unclassified), (300, 0));
      expect((await service.obtenerCuentasDigitales()).single.balance, 300);
    } finally {
      await database.close();
    }
  });

  test('las transferencias son internas, editables y reversibles', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final service = DatabaseService(database);
    final date = DateTime(2026, 10, 20);
    try {
      final accountId = await service.crearCuentaDigital('Billetera');
      await service.agregarIngreso(
        monto: 1000,
        fecha: date,
        medio: MoneyMedium.cash,
      );
      final transferId = await service.transferirDinero(
        medioOrigen: MoneyMedium.cash,
        medioDestino: MoneyMedium.digital,
        cuentaDestinoId: accountId,
        monto: 400,
        fecha: date,
        nota: 'Recarga',
      );
      var balances = await service.obtenerSaldosPorMedio();
      expect(
        (balances.cash, balances.digital, balances.total),
        (600, 400, 1000),
      );
      expect((await service.obtenerCuentasDigitales()).single.balance, 400);

      await service.actualizarTransferencia(
        id: transferId,
        medioOrigen: MoneyMedium.cash,
        medioDestino: MoneyMedium.digital,
        cuentaDestinoId: accountId,
        monto: 300,
        fecha: date,
        nota: 'Recarga corregida',
      );
      balances = await service.obtenerSaldosPorMedio();
      expect(
        (balances.cash, balances.digital, balances.total),
        (700, 300, 1000),
      );
      expect((await service.obtenerCuentasDigitales()).single.balance, 300);
      expect(await service.obtenerIngresos(), hasLength(1));
      expect(await service.obtenerGastos(), isEmpty);

      await service.eliminarTransferencia(transferId);
      balances = await service.obtenerSaldosPorMedio();
      expect(
        (balances.cash, balances.digital, balances.total),
        (1000, 0, 1000),
      );
      expect(await service.obtenerTransferencias(), isEmpty);
    } finally {
      await database.close();
    }
  });
}
