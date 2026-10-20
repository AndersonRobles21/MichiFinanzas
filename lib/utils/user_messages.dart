import 'dart:developer' as developer;

import '../models/future_expense.dart';
import '../services/database_service.dart';
import 'money_format.dart';

String friendlyOperationError(Object error, {required String action}) {
  final cause = error is DatabaseServiceException ? error.causa : error;
  if (cause is FutureExpenseInsufficientBalance) {
    return 'Te faltan ${formatMoney(cause.missing)} para reservar esa cantidad.';
  }
  final details = cause.toString().toLowerCase();
  if (details.contains('saldo disponible') ||
      details.contains('más que tu saldo')) {
    return 'Uy, parece que no alcanza la platica para eso.';
  }
  if (details.contains('saldo restante') ||
      details.contains('supera lo pendiente')) {
    return 'Uy, ese abono pasa lo que todavía falta por pagar.';
  }
  if (cause is StateError && details.contains('libera el dinero reservado')) {
    return 'Libera primero el dinero reservado para poder borrar el plan.';
  }
  return 'Ups, no se pudo $action. Inténtalo otra vez.';
}

void logOperationFailure(
  Object error,
  StackTrace stackTrace, {
  required String operation,
}) {
  developer.log(
    'Falló la operación: $operation',
    name: 'finanzas_app',
    error: error,
    stackTrace: stackTrace,
  );
}

Future<T> runWithLoggedErrors<T>(
  String operation,
  Future<T> Function() action,
) async {
  try {
    return await action();
  } catch (error, stackTrace) {
    logOperationFailure(error, stackTrace, operation: operation);
    rethrow;
  }
}
