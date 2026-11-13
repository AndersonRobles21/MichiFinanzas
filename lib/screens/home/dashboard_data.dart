import '../../database/app_database.dart';
import '../../models/future_expense.dart';
import '../../models/income_type.dart';
import '../../models/money_medium.dart';
import '../../services/database_service.dart';

enum DashboardActivityKind {
  income,
  expense,
  debtPayment,
  transfer,
  savingsContribution,
  savingsWithdrawal,
}

class DashboardActivity {
  const DashboardActivity({
    required this.kind,
    required this.title,
    required this.detail,
    required this.amount,
    required this.date,
  });

  final DashboardActivityKind kind;
  final String title;
  final String detail;
  final double amount;
  final DateTime date;
}

class DashboardData {
  const DashboardData({
    required this.totalIngresos,
    required this.ingresosDelMes,
    required this.totalRecibidoDelMes,
    required this.totalGanadoDelMes,
    required this.totalPrestamosDelMes,
    required this.totalGastos,
    required this.totalGastosDelMes,
    required this.totalPagosDeuda,
    required this.dineroDisponible,
    required this.balanceBreakdown,
    required this.userName,
    required this.digitalAccounts,
    required this.subscriptions,
    required this.totalAhorros,
    required this.recentActivities,
    required this.porcentajeGastado,
    required this.cantidadIngresos,
    required this.cantidadGastos,
    required this.cantidadGastosDelMes,
    required this.cantidadPagosDeuda,
    required this.cantidadDeudas,
    required this.deudasPendientes,
    required this.totalDeudaPendiente,
    required this.pagosProximos,
    required this.futureExpenses,
  });

  factory DashboardData.fromRecords({
    required List<Ingreso> ingresos,
    required List<Gasto> gastos,
    required List<Deuda> deudas,
    required List<PagosDeudaData> pagos,
    required List<FutureExpenseSummary> futureExpenses,
    required AvailableBalanceBreakdown balanceBreakdown,
    required String userName,
    required List<DigitalAccountBalance> digitalAccounts,
    required List<Suscripcion> subscriptions,
    required double totalAhorros,
    required List<MovimientosAhorroData> savingsMovements,
    required List<TransferenciasDineroData> transfers,
  }) {
    final totalIngresos = ingresos.fold<double>(
      0,
      (total, ingreso) => total + ingreso.monto,
    );
    final now = DateTime.now();
    final ingresosDelMes =
        ingresos
            .where(
              (ingreso) =>
                  ingreso.fecha.year == now.year &&
                  ingreso.fecha.month == now.month,
            )
            .toList()
          ..sort((a, b) => b.fecha.compareTo(a.fecha));
    final totalRecibidoDelMes = ingresosDelMes.fold<double>(
      0,
      (total, ingreso) => total + ingreso.monto,
    );
    final totalPrestamosDelMes = ingresosDelMes
        .where(
          (ingreso) => IncomeType.fromStorage(ingreso.tipo) == IncomeType.loan,
        )
        .fold<double>(0, (total, ingreso) => total + ingreso.monto);
    final totalGanadoDelMes = totalRecibidoDelMes - totalPrestamosDelMes;
    final totalGastos = gastos.fold<double>(
      0,
      (total, gasto) => total + gasto.monto,
    );
    final upcomingSubscriptions =
        subscriptions.where((item) => item.activa).toList()..sort(
          (first, second) => first.proximoPago.compareTo(second.proximoPago),
        );
    final gastosDelMes = gastos
        .where(
          (gasto) =>
              gasto.fecha.year == now.year && gasto.fecha.month == now.month,
        )
        .toList();
    final totalGastosDelMes = gastosDelMes.fold<double>(
      0,
      (total, gasto) => total + gasto.monto,
    );
    final expensesWithDebtPayment = gastos
        .map((expense) => expense.pagoDeudaId)
        .whereType<int>()
        .toSet();
    final unrepresentedPayments = pagos
        .where((payment) => !expensesWithDebtPayment.contains(payment.id))
        .toList();
    final totalPagosDeuda = unrepresentedPayments.fold<double>(
      0,
      (total, pago) => total + pago.monto,
    );
    final totalGastado = totalGastos + totalPagosDeuda;
    final porcentajeGastado = totalIngresos > 0
        ? totalGastado / totalIngresos * 100
        : null;

    final pagosPorDeuda = <int, double>{};
    for (final pago in pagos) {
      pagosPorDeuda.update(
        pago.deudaId,
        (total) => total + pago.monto,
        ifAbsent: () => pago.monto,
      );
    }

    final pagosProximos = <DashboardPendingDebt>[];
    for (final deuda in deudas) {
      final saldoPendiente =
          deuda.montoOriginal - (pagosPorDeuda[deuda.id] ?? 0);
      if (saldoPendiente <= 0) continue;

      pagosProximos.add(
        DashboardPendingDebt(
          deuda: deuda,
          saldoPendiente: saldoPendiente,
          montoProximoPago: deuda.cuota < saldoPendiente
              ? deuda.cuota
              : saldoPendiente,
        ),
      );
    }
    pagosProximos.sort(
      (a, b) => (a.deuda.fechaProximoPago ?? DateTime(9999)).compareTo(
        b.deuda.fechaProximoPago ?? DateTime(9999),
      ),
    );

    final accountNames = {
      for (final account in digitalAccounts)
        account.account.id: account.account.nombre,
    };
    final debtNames = {for (final debt in deudas) debt.id: debt.nombre};
    String endpoint(String mediumValue, int? accountId) {
      if (accountId != null) {
        return accountNames[accountId] ?? 'Cuenta digital';
      }
      return MoneyMedium.fromStorage(mediumValue)?.label ??
          'Medio sin clasificar';
    }

    final activities = <DashboardActivity>[
      for (final income in ingresos)
        DashboardActivity(
          kind: DashboardActivityKind.income,
          title: income.tipo == IncomeType.loan.storageValue
              ? IncomeType.loan.label
              : (income.descripcion?.trim().isNotEmpty ?? false)
              ? income.descripcion!.trim()
              : IncomeType.fromStorage(income.tipo).label,
          detail: IncomeType.fromStorage(income.tipo).label,
          amount: income.monto,
          date: income.fecha,
        ),
      for (final expense in gastos)
        DashboardActivity(
          kind: DashboardActivityKind.expense,
          title: expense.nombre,
          detail:
              '${expense.categoria} · '
              '${MoneyMedium.fromStorage(expense.medio)?.label ?? 'Sin clasificar'}',
          amount: expense.monto,
          date: expense.fecha,
        ),
      for (final payment in unrepresentedPayments)
        DashboardActivity(
          kind: DashboardActivityKind.debtPayment,
          title: 'Abono · ${debtNames[payment.deudaId] ?? 'Deuda'}',
          detail:
              'Pago de deuda · '
              '${MoneyMedium.fromStorage(payment.medio)?.label ?? 'Medio sin clasificar'}',
          amount: payment.monto,
          date: payment.fecha,
        ),
      for (final transfer in transfers)
        DashboardActivity(
          kind: DashboardActivityKind.transfer,
          title: 'Transferencia',
          detail:
              '${endpoint(transfer.medioOrigen, transfer.cuentaOrigenId)} → '
              '${endpoint(transfer.medioDestino, transfer.cuentaDestinoId)}'
              '${transfer.nota?.trim().isNotEmpty ?? false ? ' · ${transfer.nota!.trim()}' : ''}',
          amount: transfer.monto,
          date: transfer.fecha,
        ),
      for (final movement in savingsMovements)
        DashboardActivity(
          kind: movement.tipo == DatabaseService.aporteAhorro
              ? DashboardActivityKind.savingsContribution
              : DashboardActivityKind.savingsWithdrawal,
          title: movement.tipo == DatabaseService.aporteAhorro
              ? 'Aporte a ahorros'
              : 'Retiro de ahorros',
          detail:
              'Ahorros · '
              '${MoneyMedium.fromStorage(movement.medio)?.label ?? 'Medio sin clasificar'}',
          amount: movement.monto,
          date: movement.fecha,
        ),
    ]..sort((first, second) => second.date.compareTo(first.date));

    return DashboardData(
      totalIngresos: totalIngresos,
      ingresosDelMes: ingresosDelMes,
      totalRecibidoDelMes: totalRecibidoDelMes,
      totalGanadoDelMes: totalGanadoDelMes,
      totalPrestamosDelMes: totalPrestamosDelMes,
      totalGastos: totalGastos,
      totalGastosDelMes: totalGastosDelMes,
      totalPagosDeuda: totalPagosDeuda,
      dineroDisponible: balanceBreakdown.total,
      balanceBreakdown: balanceBreakdown,
      userName: userName,
      digitalAccounts: digitalAccounts,
      subscriptions: upcomingSubscriptions,
      totalAhorros: totalAhorros,
      recentActivities: activities.take(5).toList(),
      porcentajeGastado: porcentajeGastado,
      cantidadIngresos: ingresos.length,
      cantidadGastos: gastos.length,
      cantidadGastosDelMes: gastosDelMes.length,
      cantidadPagosDeuda: unrepresentedPayments.length,
      cantidadDeudas: deudas.length,
      deudasPendientes: pagosProximos.length,
      totalDeudaPendiente: pagosProximos.fold<double>(
        0,
        (total, deuda) => total + deuda.saldoPendiente,
      ),
      pagosProximos: pagosProximos,
      futureExpenses: futureExpenses,
    );
  }

  final double totalIngresos;
  final List<Ingreso> ingresosDelMes;
  final double totalRecibidoDelMes;
  final double totalGanadoDelMes;
  final double totalPrestamosDelMes;
  final double totalGastos;
  final double totalGastosDelMes;
  final double totalPagosDeuda;
  final double dineroDisponible;
  final AvailableBalanceBreakdown balanceBreakdown;
  final String userName;
  final List<DigitalAccountBalance> digitalAccounts;
  final List<Suscripcion> subscriptions;
  final double totalAhorros;
  final List<DashboardActivity> recentActivities;
  final double? porcentajeGastado;
  final int cantidadIngresos;
  final int cantidadGastos;
  final int cantidadGastosDelMes;
  final int cantidadPagosDeuda;
  final int cantidadDeudas;
  final int deudasPendientes;
  final double totalDeudaPendiente;
  final List<DashboardPendingDebt> pagosProximos;
  final List<FutureExpenseSummary> futureExpenses;

  bool get tieneMovimientos =>
      cantidadIngresos > 0 || cantidadGastos > 0 || cantidadPagosDeuda > 0;

  String get consejo {
    if (totalIngresos <= 0) {
      return 'Agrega tu primer ingreso y empieza a organizar tu dinero.';
    }

    final porcentaje = porcentajeGastado ?? 0;
    if (porcentaje >= 80) {
      return '¡Ojo con los gastos! Revisa cuáles están pesando más.';
    }
    if (dineroDisponible <= totalIngresos * 0.1) {
      return 'Te queda poquito disponible. Prioriza lo más importante.';
    }
    if (pagosProximos.isNotEmpty) {
      return 'Ten presentes tus próximos pagos para llegar con calma.';
    }
    if (porcentaje <= 50) {
      return 'Vas muy bien; todavía tienes margen para tus planes.';
    }
    return 'Sigue llevando el control de lo que entra y sale.';
  }
}

class DashboardPendingDebt {
  const DashboardPendingDebt({
    required this.deuda,
    required this.saldoPendiente,
    required this.montoProximoPago,
  });

  final Deuda deuda;
  final double saldoPendiente;
  final double montoProximoPago;
}
