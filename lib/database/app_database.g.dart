// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CuentasDigitalesTable extends CuentasDigitales
    with TableInfo<$CuentasDigitalesTable, CuentasDigitale> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CuentasDigitalesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, nombre];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cuentas_digitales';
  @override
  VerificationContext validateIntegrity(
    Insertable<CuentasDigitale> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CuentasDigitale map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CuentasDigitale(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
    );
  }

  @override
  $CuentasDigitalesTable createAlias(String alias) {
    return $CuentasDigitalesTable(attachedDatabase, alias);
  }
}

class CuentasDigitale extends DataClass implements Insertable<CuentasDigitale> {
  final int id;
  final String nombre;
  const CuentasDigitale({required this.id, required this.nombre});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['nombre'] = Variable<String>(nombre);
    return map;
  }

  CuentasDigitalesCompanion toCompanion(bool nullToAbsent) {
    return CuentasDigitalesCompanion(id: Value(id), nombre: Value(nombre));
  }

  factory CuentasDigitale.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CuentasDigitale(
      id: serializer.fromJson<int>(json['id']),
      nombre: serializer.fromJson<String>(json['nombre']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nombre': serializer.toJson<String>(nombre),
    };
  }

  CuentasDigitale copyWith({int? id, String? nombre}) =>
      CuentasDigitale(id: id ?? this.id, nombre: nombre ?? this.nombre);
  CuentasDigitale copyWithCompanion(CuentasDigitalesCompanion data) {
    return CuentasDigitale(
      id: data.id.present ? data.id.value : this.id,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CuentasDigitale(')
          ..write('id: $id, ')
          ..write('nombre: $nombre')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nombre);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CuentasDigitale &&
          other.id == this.id &&
          other.nombre == this.nombre);
}

class CuentasDigitalesCompanion extends UpdateCompanion<CuentasDigitale> {
  final Value<int> id;
  final Value<String> nombre;
  const CuentasDigitalesCompanion({
    this.id = const Value.absent(),
    this.nombre = const Value.absent(),
  });
  CuentasDigitalesCompanion.insert({
    this.id = const Value.absent(),
    required String nombre,
  }) : nombre = Value(nombre);
  static Insertable<CuentasDigitale> custom({
    Expression<int>? id,
    Expression<String>? nombre,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nombre != null) 'nombre': nombre,
    });
  }

  CuentasDigitalesCompanion copyWith({Value<int>? id, Value<String>? nombre}) {
    return CuentasDigitalesCompanion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CuentasDigitalesCompanion(')
          ..write('id: $id, ')
          ..write('nombre: $nombre')
          ..write(')'))
        .toString();
  }
}

class $IngresosTable extends Ingresos with TableInfo<$IngresosTable, Ingreso> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IngresosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _montoMeta = const VerificationMeta('monto');
  @override
  late final GeneratedColumn<double> monto = GeneratedColumn<double>(
    'monto',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ingreso'),
  );
  static const VerificationMeta _fechaMeta = const VerificationMeta('fecha');
  @override
  late final GeneratedColumn<DateTime> fecha = GeneratedColumn<DateTime>(
    'fecha',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descripcionMeta = const VerificationMeta(
    'descripcion',
  );
  @override
  late final GeneratedColumn<String> descripcion = GeneratedColumn<String>(
    'descripcion',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _medioMeta = const VerificationMeta('medio');
  @override
  late final GeneratedColumn<String> medio = GeneratedColumn<String>(
    'medio',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cuentaDigitalIdMeta = const VerificationMeta(
    'cuentaDigitalId',
  );
  @override
  late final GeneratedColumn<int> cuentaDigitalId = GeneratedColumn<int>(
    'cuenta_digital_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cuentas_digitales (id) ON DELETE SET NULL',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    monto,
    tipo,
    fecha,
    descripcion,
    medio,
    cuentaDigitalId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ingresos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Ingreso> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('monto')) {
      context.handle(
        _montoMeta,
        monto.isAcceptableOrUnknown(data['monto']!, _montoMeta),
      );
    } else if (isInserting) {
      context.missing(_montoMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    }
    if (data.containsKey('fecha')) {
      context.handle(
        _fechaMeta,
        fecha.isAcceptableOrUnknown(data['fecha']!, _fechaMeta),
      );
    } else if (isInserting) {
      context.missing(_fechaMeta);
    }
    if (data.containsKey('descripcion')) {
      context.handle(
        _descripcionMeta,
        descripcion.isAcceptableOrUnknown(
          data['descripcion']!,
          _descripcionMeta,
        ),
      );
    }
    if (data.containsKey('medio')) {
      context.handle(
        _medioMeta,
        medio.isAcceptableOrUnknown(data['medio']!, _medioMeta),
      );
    }
    if (data.containsKey('cuenta_digital_id')) {
      context.handle(
        _cuentaDigitalIdMeta,
        cuentaDigitalId.isAcceptableOrUnknown(
          data['cuenta_digital_id']!,
          _cuentaDigitalIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Ingreso map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Ingreso(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      monto: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}monto'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      )!,
      fecha: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha'],
      )!,
      descripcion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}descripcion'],
      ),
      medio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medio'],
      ),
      cuentaDigitalId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cuenta_digital_id'],
      ),
    );
  }

  @override
  $IngresosTable createAlias(String alias) {
    return $IngresosTable(attachedDatabase, alias);
  }
}

class Ingreso extends DataClass implements Insertable<Ingreso> {
  final int id;
  final double monto;
  final String tipo;
  final DateTime fecha;
  final String? descripcion;
  final String? medio;
  final int? cuentaDigitalId;
  const Ingreso({
    required this.id,
    required this.monto,
    required this.tipo,
    required this.fecha,
    this.descripcion,
    this.medio,
    this.cuentaDigitalId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['monto'] = Variable<double>(monto);
    map['tipo'] = Variable<String>(tipo);
    map['fecha'] = Variable<DateTime>(fecha);
    if (!nullToAbsent || descripcion != null) {
      map['descripcion'] = Variable<String>(descripcion);
    }
    if (!nullToAbsent || medio != null) {
      map['medio'] = Variable<String>(medio);
    }
    if (!nullToAbsent || cuentaDigitalId != null) {
      map['cuenta_digital_id'] = Variable<int>(cuentaDigitalId);
    }
    return map;
  }

  IngresosCompanion toCompanion(bool nullToAbsent) {
    return IngresosCompanion(
      id: Value(id),
      monto: Value(monto),
      tipo: Value(tipo),
      fecha: Value(fecha),
      descripcion: descripcion == null && nullToAbsent
          ? const Value.absent()
          : Value(descripcion),
      medio: medio == null && nullToAbsent
          ? const Value.absent()
          : Value(medio),
      cuentaDigitalId: cuentaDigitalId == null && nullToAbsent
          ? const Value.absent()
          : Value(cuentaDigitalId),
    );
  }

  factory Ingreso.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Ingreso(
      id: serializer.fromJson<int>(json['id']),
      monto: serializer.fromJson<double>(json['monto']),
      tipo: serializer.fromJson<String>(json['tipo']),
      fecha: serializer.fromJson<DateTime>(json['fecha']),
      descripcion: serializer.fromJson<String?>(json['descripcion']),
      medio: serializer.fromJson<String?>(json['medio']),
      cuentaDigitalId: serializer.fromJson<int?>(json['cuentaDigitalId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'monto': serializer.toJson<double>(monto),
      'tipo': serializer.toJson<String>(tipo),
      'fecha': serializer.toJson<DateTime>(fecha),
      'descripcion': serializer.toJson<String?>(descripcion),
      'medio': serializer.toJson<String?>(medio),
      'cuentaDigitalId': serializer.toJson<int?>(cuentaDigitalId),
    };
  }

  Ingreso copyWith({
    int? id,
    double? monto,
    String? tipo,
    DateTime? fecha,
    Value<String?> descripcion = const Value.absent(),
    Value<String?> medio = const Value.absent(),
    Value<int?> cuentaDigitalId = const Value.absent(),
  }) => Ingreso(
    id: id ?? this.id,
    monto: monto ?? this.monto,
    tipo: tipo ?? this.tipo,
    fecha: fecha ?? this.fecha,
    descripcion: descripcion.present ? descripcion.value : this.descripcion,
    medio: medio.present ? medio.value : this.medio,
    cuentaDigitalId: cuentaDigitalId.present
        ? cuentaDigitalId.value
        : this.cuentaDigitalId,
  );
  Ingreso copyWithCompanion(IngresosCompanion data) {
    return Ingreso(
      id: data.id.present ? data.id.value : this.id,
      monto: data.monto.present ? data.monto.value : this.monto,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      fecha: data.fecha.present ? data.fecha.value : this.fecha,
      descripcion: data.descripcion.present
          ? data.descripcion.value
          : this.descripcion,
      medio: data.medio.present ? data.medio.value : this.medio,
      cuentaDigitalId: data.cuentaDigitalId.present
          ? data.cuentaDigitalId.value
          : this.cuentaDigitalId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Ingreso(')
          ..write('id: $id, ')
          ..write('monto: $monto, ')
          ..write('tipo: $tipo, ')
          ..write('fecha: $fecha, ')
          ..write('descripcion: $descripcion, ')
          ..write('medio: $medio, ')
          ..write('cuentaDigitalId: $cuentaDigitalId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, monto, tipo, fecha, descripcion, medio, cuentaDigitalId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Ingreso &&
          other.id == this.id &&
          other.monto == this.monto &&
          other.tipo == this.tipo &&
          other.fecha == this.fecha &&
          other.descripcion == this.descripcion &&
          other.medio == this.medio &&
          other.cuentaDigitalId == this.cuentaDigitalId);
}

class IngresosCompanion extends UpdateCompanion<Ingreso> {
  final Value<int> id;
  final Value<double> monto;
  final Value<String> tipo;
  final Value<DateTime> fecha;
  final Value<String?> descripcion;
  final Value<String?> medio;
  final Value<int?> cuentaDigitalId;
  const IngresosCompanion({
    this.id = const Value.absent(),
    this.monto = const Value.absent(),
    this.tipo = const Value.absent(),
    this.fecha = const Value.absent(),
    this.descripcion = const Value.absent(),
    this.medio = const Value.absent(),
    this.cuentaDigitalId = const Value.absent(),
  });
  IngresosCompanion.insert({
    this.id = const Value.absent(),
    required double monto,
    this.tipo = const Value.absent(),
    required DateTime fecha,
    this.descripcion = const Value.absent(),
    this.medio = const Value.absent(),
    this.cuentaDigitalId = const Value.absent(),
  }) : monto = Value(monto),
       fecha = Value(fecha);
  static Insertable<Ingreso> custom({
    Expression<int>? id,
    Expression<double>? monto,
    Expression<String>? tipo,
    Expression<DateTime>? fecha,
    Expression<String>? descripcion,
    Expression<String>? medio,
    Expression<int>? cuentaDigitalId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (monto != null) 'monto': monto,
      if (tipo != null) 'tipo': tipo,
      if (fecha != null) 'fecha': fecha,
      if (descripcion != null) 'descripcion': descripcion,
      if (medio != null) 'medio': medio,
      if (cuentaDigitalId != null) 'cuenta_digital_id': cuentaDigitalId,
    });
  }

  IngresosCompanion copyWith({
    Value<int>? id,
    Value<double>? monto,
    Value<String>? tipo,
    Value<DateTime>? fecha,
    Value<String?>? descripcion,
    Value<String?>? medio,
    Value<int?>? cuentaDigitalId,
  }) {
    return IngresosCompanion(
      id: id ?? this.id,
      monto: monto ?? this.monto,
      tipo: tipo ?? this.tipo,
      fecha: fecha ?? this.fecha,
      descripcion: descripcion ?? this.descripcion,
      medio: medio ?? this.medio,
      cuentaDigitalId: cuentaDigitalId ?? this.cuentaDigitalId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (monto.present) {
      map['monto'] = Variable<double>(monto.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (fecha.present) {
      map['fecha'] = Variable<DateTime>(fecha.value);
    }
    if (descripcion.present) {
      map['descripcion'] = Variable<String>(descripcion.value);
    }
    if (medio.present) {
      map['medio'] = Variable<String>(medio.value);
    }
    if (cuentaDigitalId.present) {
      map['cuenta_digital_id'] = Variable<int>(cuentaDigitalId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IngresosCompanion(')
          ..write('id: $id, ')
          ..write('monto: $monto, ')
          ..write('tipo: $tipo, ')
          ..write('fecha: $fecha, ')
          ..write('descripcion: $descripcion, ')
          ..write('medio: $medio, ')
          ..write('cuentaDigitalId: $cuentaDigitalId')
          ..write(')'))
        .toString();
  }
}

class $SuscripcionesTable extends Suscripciones
    with TableInfo<$SuscripcionesTable, Suscripcion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SuscripcionesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _precioMeta = const VerificationMeta('precio');
  @override
  late final GeneratedColumn<double> precio = GeneratedColumn<double>(
    'precio',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proximoPagoMeta = const VerificationMeta(
    'proximoPago',
  );
  @override
  late final GeneratedColumn<DateTime> proximoPago = GeneratedColumn<DateTime>(
    'proximo_pago',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _frecuenciaMeta = const VerificationMeta(
    'frecuencia',
  );
  @override
  late final GeneratedColumn<String> frecuencia = GeneratedColumn<String>(
    'frecuencia',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _medioMeta = const VerificationMeta('medio');
  @override
  late final GeneratedColumn<String> medio = GeneratedColumn<String>(
    'medio',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cuentaDigitalIdMeta = const VerificationMeta(
    'cuentaDigitalId',
  );
  @override
  late final GeneratedColumn<int> cuentaDigitalId = GeneratedColumn<int>(
    'cuenta_digital_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cuentas_digitales (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _activaMeta = const VerificationMeta('activa');
  @override
  late final GeneratedColumn<bool> activa = GeneratedColumn<bool>(
    'activa',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("activa" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nombre,
    precio,
    proximoPago,
    frecuencia,
    medio,
    cuentaDigitalId,
    activa,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'suscripciones';
  @override
  VerificationContext validateIntegrity(
    Insertable<Suscripcion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('precio')) {
      context.handle(
        _precioMeta,
        precio.isAcceptableOrUnknown(data['precio']!, _precioMeta),
      );
    } else if (isInserting) {
      context.missing(_precioMeta);
    }
    if (data.containsKey('proximo_pago')) {
      context.handle(
        _proximoPagoMeta,
        proximoPago.isAcceptableOrUnknown(
          data['proximo_pago']!,
          _proximoPagoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_proximoPagoMeta);
    }
    if (data.containsKey('frecuencia')) {
      context.handle(
        _frecuenciaMeta,
        frecuencia.isAcceptableOrUnknown(data['frecuencia']!, _frecuenciaMeta),
      );
    } else if (isInserting) {
      context.missing(_frecuenciaMeta);
    }
    if (data.containsKey('medio')) {
      context.handle(
        _medioMeta,
        medio.isAcceptableOrUnknown(data['medio']!, _medioMeta),
      );
    }
    if (data.containsKey('cuenta_digital_id')) {
      context.handle(
        _cuentaDigitalIdMeta,
        cuentaDigitalId.isAcceptableOrUnknown(
          data['cuenta_digital_id']!,
          _cuentaDigitalIdMeta,
        ),
      );
    }
    if (data.containsKey('activa')) {
      context.handle(
        _activaMeta,
        activa.isAcceptableOrUnknown(data['activa']!, _activaMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Suscripcion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Suscripcion(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      precio: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}precio'],
      )!,
      proximoPago: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}proximo_pago'],
      )!,
      frecuencia: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frecuencia'],
      )!,
      medio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medio'],
      ),
      cuentaDigitalId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cuenta_digital_id'],
      ),
      activa: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}activa'],
      )!,
    );
  }

  @override
  $SuscripcionesTable createAlias(String alias) {
    return $SuscripcionesTable(attachedDatabase, alias);
  }
}

class Suscripcion extends DataClass implements Insertable<Suscripcion> {
  final int id;
  final String nombre;
  final double precio;
  final DateTime proximoPago;
  final String frecuencia;
  final String? medio;
  final int? cuentaDigitalId;
  final bool activa;
  const Suscripcion({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.proximoPago,
    required this.frecuencia,
    this.medio,
    this.cuentaDigitalId,
    required this.activa,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['nombre'] = Variable<String>(nombre);
    map['precio'] = Variable<double>(precio);
    map['proximo_pago'] = Variable<DateTime>(proximoPago);
    map['frecuencia'] = Variable<String>(frecuencia);
    if (!nullToAbsent || medio != null) {
      map['medio'] = Variable<String>(medio);
    }
    if (!nullToAbsent || cuentaDigitalId != null) {
      map['cuenta_digital_id'] = Variable<int>(cuentaDigitalId);
    }
    map['activa'] = Variable<bool>(activa);
    return map;
  }

  SuscripcionesCompanion toCompanion(bool nullToAbsent) {
    return SuscripcionesCompanion(
      id: Value(id),
      nombre: Value(nombre),
      precio: Value(precio),
      proximoPago: Value(proximoPago),
      frecuencia: Value(frecuencia),
      medio: medio == null && nullToAbsent
          ? const Value.absent()
          : Value(medio),
      cuentaDigitalId: cuentaDigitalId == null && nullToAbsent
          ? const Value.absent()
          : Value(cuentaDigitalId),
      activa: Value(activa),
    );
  }

  factory Suscripcion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Suscripcion(
      id: serializer.fromJson<int>(json['id']),
      nombre: serializer.fromJson<String>(json['nombre']),
      precio: serializer.fromJson<double>(json['precio']),
      proximoPago: serializer.fromJson<DateTime>(json['proximoPago']),
      frecuencia: serializer.fromJson<String>(json['frecuencia']),
      medio: serializer.fromJson<String?>(json['medio']),
      cuentaDigitalId: serializer.fromJson<int?>(json['cuentaDigitalId']),
      activa: serializer.fromJson<bool>(json['activa']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nombre': serializer.toJson<String>(nombre),
      'precio': serializer.toJson<double>(precio),
      'proximoPago': serializer.toJson<DateTime>(proximoPago),
      'frecuencia': serializer.toJson<String>(frecuencia),
      'medio': serializer.toJson<String?>(medio),
      'cuentaDigitalId': serializer.toJson<int?>(cuentaDigitalId),
      'activa': serializer.toJson<bool>(activa),
    };
  }

  Suscripcion copyWith({
    int? id,
    String? nombre,
    double? precio,
    DateTime? proximoPago,
    String? frecuencia,
    Value<String?> medio = const Value.absent(),
    Value<int?> cuentaDigitalId = const Value.absent(),
    bool? activa,
  }) => Suscripcion(
    id: id ?? this.id,
    nombre: nombre ?? this.nombre,
    precio: precio ?? this.precio,
    proximoPago: proximoPago ?? this.proximoPago,
    frecuencia: frecuencia ?? this.frecuencia,
    medio: medio.present ? medio.value : this.medio,
    cuentaDigitalId: cuentaDigitalId.present
        ? cuentaDigitalId.value
        : this.cuentaDigitalId,
    activa: activa ?? this.activa,
  );
  Suscripcion copyWithCompanion(SuscripcionesCompanion data) {
    return Suscripcion(
      id: data.id.present ? data.id.value : this.id,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      precio: data.precio.present ? data.precio.value : this.precio,
      proximoPago: data.proximoPago.present
          ? data.proximoPago.value
          : this.proximoPago,
      frecuencia: data.frecuencia.present
          ? data.frecuencia.value
          : this.frecuencia,
      medio: data.medio.present ? data.medio.value : this.medio,
      cuentaDigitalId: data.cuentaDigitalId.present
          ? data.cuentaDigitalId.value
          : this.cuentaDigitalId,
      activa: data.activa.present ? data.activa.value : this.activa,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Suscripcion(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('precio: $precio, ')
          ..write('proximoPago: $proximoPago, ')
          ..write('frecuencia: $frecuencia, ')
          ..write('medio: $medio, ')
          ..write('cuentaDigitalId: $cuentaDigitalId, ')
          ..write('activa: $activa')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    nombre,
    precio,
    proximoPago,
    frecuencia,
    medio,
    cuentaDigitalId,
    activa,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Suscripcion &&
          other.id == this.id &&
          other.nombre == this.nombre &&
          other.precio == this.precio &&
          other.proximoPago == this.proximoPago &&
          other.frecuencia == this.frecuencia &&
          other.medio == this.medio &&
          other.cuentaDigitalId == this.cuentaDigitalId &&
          other.activa == this.activa);
}

class SuscripcionesCompanion extends UpdateCompanion<Suscripcion> {
  final Value<int> id;
  final Value<String> nombre;
  final Value<double> precio;
  final Value<DateTime> proximoPago;
  final Value<String> frecuencia;
  final Value<String?> medio;
  final Value<int?> cuentaDigitalId;
  final Value<bool> activa;
  const SuscripcionesCompanion({
    this.id = const Value.absent(),
    this.nombre = const Value.absent(),
    this.precio = const Value.absent(),
    this.proximoPago = const Value.absent(),
    this.frecuencia = const Value.absent(),
    this.medio = const Value.absent(),
    this.cuentaDigitalId = const Value.absent(),
    this.activa = const Value.absent(),
  });
  SuscripcionesCompanion.insert({
    this.id = const Value.absent(),
    required String nombre,
    required double precio,
    required DateTime proximoPago,
    required String frecuencia,
    this.medio = const Value.absent(),
    this.cuentaDigitalId = const Value.absent(),
    this.activa = const Value.absent(),
  }) : nombre = Value(nombre),
       precio = Value(precio),
       proximoPago = Value(proximoPago),
       frecuencia = Value(frecuencia);
  static Insertable<Suscripcion> custom({
    Expression<int>? id,
    Expression<String>? nombre,
    Expression<double>? precio,
    Expression<DateTime>? proximoPago,
    Expression<String>? frecuencia,
    Expression<String>? medio,
    Expression<int>? cuentaDigitalId,
    Expression<bool>? activa,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nombre != null) 'nombre': nombre,
      if (precio != null) 'precio': precio,
      if (proximoPago != null) 'proximo_pago': proximoPago,
      if (frecuencia != null) 'frecuencia': frecuencia,
      if (medio != null) 'medio': medio,
      if (cuentaDigitalId != null) 'cuenta_digital_id': cuentaDigitalId,
      if (activa != null) 'activa': activa,
    });
  }

  SuscripcionesCompanion copyWith({
    Value<int>? id,
    Value<String>? nombre,
    Value<double>? precio,
    Value<DateTime>? proximoPago,
    Value<String>? frecuencia,
    Value<String?>? medio,
    Value<int?>? cuentaDigitalId,
    Value<bool>? activa,
  }) {
    return SuscripcionesCompanion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      precio: precio ?? this.precio,
      proximoPago: proximoPago ?? this.proximoPago,
      frecuencia: frecuencia ?? this.frecuencia,
      medio: medio ?? this.medio,
      cuentaDigitalId: cuentaDigitalId ?? this.cuentaDigitalId,
      activa: activa ?? this.activa,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (precio.present) {
      map['precio'] = Variable<double>(precio.value);
    }
    if (proximoPago.present) {
      map['proximo_pago'] = Variable<DateTime>(proximoPago.value);
    }
    if (frecuencia.present) {
      map['frecuencia'] = Variable<String>(frecuencia.value);
    }
    if (medio.present) {
      map['medio'] = Variable<String>(medio.value);
    }
    if (cuentaDigitalId.present) {
      map['cuenta_digital_id'] = Variable<int>(cuentaDigitalId.value);
    }
    if (activa.present) {
      map['activa'] = Variable<bool>(activa.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SuscripcionesCompanion(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('precio: $precio, ')
          ..write('proximoPago: $proximoPago, ')
          ..write('frecuencia: $frecuencia, ')
          ..write('medio: $medio, ')
          ..write('cuentaDigitalId: $cuentaDigitalId, ')
          ..write('activa: $activa')
          ..write(')'))
        .toString();
  }
}

class $GastosTable extends Gastos with TableInfo<$GastosTable, Gasto> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GastosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _montoMeta = const VerificationMeta('monto');
  @override
  late final GeneratedColumn<double> monto = GeneratedColumn<double>(
    'monto',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoriaMeta = const VerificationMeta(
    'categoria',
  );
  @override
  late final GeneratedColumn<String> categoria = GeneratedColumn<String>(
    'categoria',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaMeta = const VerificationMeta('fecha');
  @override
  late final GeneratedColumn<DateTime> fecha = GeneratedColumn<DateTime>(
    'fecha',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notaMeta = const VerificationMeta('nota');
  @override
  late final GeneratedColumn<String> nota = GeneratedColumn<String>(
    'nota',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _medioMeta = const VerificationMeta('medio');
  @override
  late final GeneratedColumn<String> medio = GeneratedColumn<String>(
    'medio',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cuentaDigitalIdMeta = const VerificationMeta(
    'cuentaDigitalId',
  );
  @override
  late final GeneratedColumn<int> cuentaDigitalId = GeneratedColumn<int>(
    'cuenta_digital_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cuentas_digitales (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _suscripcionIdMeta = const VerificationMeta(
    'suscripcionId',
  );
  @override
  late final GeneratedColumn<int> suscripcionId = GeneratedColumn<int>(
    'suscripcion_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES suscripciones (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _suscripcionPeriodoMeta =
      const VerificationMeta('suscripcionPeriodo');
  @override
  late final GeneratedColumn<DateTime> suscripcionPeriodo =
      GeneratedColumn<DateTime>(
        'suscripcion_periodo',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nombre,
    monto,
    categoria,
    fecha,
    nota,
    medio,
    cuentaDigitalId,
    suscripcionId,
    suscripcionPeriodo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'gastos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Gasto> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('monto')) {
      context.handle(
        _montoMeta,
        monto.isAcceptableOrUnknown(data['monto']!, _montoMeta),
      );
    } else if (isInserting) {
      context.missing(_montoMeta);
    }
    if (data.containsKey('categoria')) {
      context.handle(
        _categoriaMeta,
        categoria.isAcceptableOrUnknown(data['categoria']!, _categoriaMeta),
      );
    } else if (isInserting) {
      context.missing(_categoriaMeta);
    }
    if (data.containsKey('fecha')) {
      context.handle(
        _fechaMeta,
        fecha.isAcceptableOrUnknown(data['fecha']!, _fechaMeta),
      );
    } else if (isInserting) {
      context.missing(_fechaMeta);
    }
    if (data.containsKey('nota')) {
      context.handle(
        _notaMeta,
        nota.isAcceptableOrUnknown(data['nota']!, _notaMeta),
      );
    }
    if (data.containsKey('medio')) {
      context.handle(
        _medioMeta,
        medio.isAcceptableOrUnknown(data['medio']!, _medioMeta),
      );
    }
    if (data.containsKey('cuenta_digital_id')) {
      context.handle(
        _cuentaDigitalIdMeta,
        cuentaDigitalId.isAcceptableOrUnknown(
          data['cuenta_digital_id']!,
          _cuentaDigitalIdMeta,
        ),
      );
    }
    if (data.containsKey('suscripcion_id')) {
      context.handle(
        _suscripcionIdMeta,
        suscripcionId.isAcceptableOrUnknown(
          data['suscripcion_id']!,
          _suscripcionIdMeta,
        ),
      );
    }
    if (data.containsKey('suscripcion_periodo')) {
      context.handle(
        _suscripcionPeriodoMeta,
        suscripcionPeriodo.isAcceptableOrUnknown(
          data['suscripcion_periodo']!,
          _suscripcionPeriodoMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Gasto map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Gasto(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      monto: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}monto'],
      )!,
      categoria: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}categoria'],
      )!,
      fecha: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha'],
      )!,
      nota: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nota'],
      ),
      medio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medio'],
      ),
      cuentaDigitalId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cuenta_digital_id'],
      ),
      suscripcionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}suscripcion_id'],
      ),
      suscripcionPeriodo: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}suscripcion_periodo'],
      ),
    );
  }

  @override
  $GastosTable createAlias(String alias) {
    return $GastosTable(attachedDatabase, alias);
  }
}

class Gasto extends DataClass implements Insertable<Gasto> {
  final int id;
  final String nombre;
  final double monto;
  final String categoria;
  final DateTime fecha;
  final String? nota;
  final String? medio;
  final int? cuentaDigitalId;
  final int? suscripcionId;
  final DateTime? suscripcionPeriodo;
  const Gasto({
    required this.id,
    required this.nombre,
    required this.monto,
    required this.categoria,
    required this.fecha,
    this.nota,
    this.medio,
    this.cuentaDigitalId,
    this.suscripcionId,
    this.suscripcionPeriodo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['nombre'] = Variable<String>(nombre);
    map['monto'] = Variable<double>(monto);
    map['categoria'] = Variable<String>(categoria);
    map['fecha'] = Variable<DateTime>(fecha);
    if (!nullToAbsent || nota != null) {
      map['nota'] = Variable<String>(nota);
    }
    if (!nullToAbsent || medio != null) {
      map['medio'] = Variable<String>(medio);
    }
    if (!nullToAbsent || cuentaDigitalId != null) {
      map['cuenta_digital_id'] = Variable<int>(cuentaDigitalId);
    }
    if (!nullToAbsent || suscripcionId != null) {
      map['suscripcion_id'] = Variable<int>(suscripcionId);
    }
    if (!nullToAbsent || suscripcionPeriodo != null) {
      map['suscripcion_periodo'] = Variable<DateTime>(suscripcionPeriodo);
    }
    return map;
  }

  GastosCompanion toCompanion(bool nullToAbsent) {
    return GastosCompanion(
      id: Value(id),
      nombre: Value(nombre),
      monto: Value(monto),
      categoria: Value(categoria),
      fecha: Value(fecha),
      nota: nota == null && nullToAbsent ? const Value.absent() : Value(nota),
      medio: medio == null && nullToAbsent
          ? const Value.absent()
          : Value(medio),
      cuentaDigitalId: cuentaDigitalId == null && nullToAbsent
          ? const Value.absent()
          : Value(cuentaDigitalId),
      suscripcionId: suscripcionId == null && nullToAbsent
          ? const Value.absent()
          : Value(suscripcionId),
      suscripcionPeriodo: suscripcionPeriodo == null && nullToAbsent
          ? const Value.absent()
          : Value(suscripcionPeriodo),
    );
  }

  factory Gasto.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Gasto(
      id: serializer.fromJson<int>(json['id']),
      nombre: serializer.fromJson<String>(json['nombre']),
      monto: serializer.fromJson<double>(json['monto']),
      categoria: serializer.fromJson<String>(json['categoria']),
      fecha: serializer.fromJson<DateTime>(json['fecha']),
      nota: serializer.fromJson<String?>(json['nota']),
      medio: serializer.fromJson<String?>(json['medio']),
      cuentaDigitalId: serializer.fromJson<int?>(json['cuentaDigitalId']),
      suscripcionId: serializer.fromJson<int?>(json['suscripcionId']),
      suscripcionPeriodo: serializer.fromJson<DateTime?>(
        json['suscripcionPeriodo'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nombre': serializer.toJson<String>(nombre),
      'monto': serializer.toJson<double>(monto),
      'categoria': serializer.toJson<String>(categoria),
      'fecha': serializer.toJson<DateTime>(fecha),
      'nota': serializer.toJson<String?>(nota),
      'medio': serializer.toJson<String?>(medio),
      'cuentaDigitalId': serializer.toJson<int?>(cuentaDigitalId),
      'suscripcionId': serializer.toJson<int?>(suscripcionId),
      'suscripcionPeriodo': serializer.toJson<DateTime?>(suscripcionPeriodo),
    };
  }

  Gasto copyWith({
    int? id,
    String? nombre,
    double? monto,
    String? categoria,
    DateTime? fecha,
    Value<String?> nota = const Value.absent(),
    Value<String?> medio = const Value.absent(),
    Value<int?> cuentaDigitalId = const Value.absent(),
    Value<int?> suscripcionId = const Value.absent(),
    Value<DateTime?> suscripcionPeriodo = const Value.absent(),
  }) => Gasto(
    id: id ?? this.id,
    nombre: nombre ?? this.nombre,
    monto: monto ?? this.monto,
    categoria: categoria ?? this.categoria,
    fecha: fecha ?? this.fecha,
    nota: nota.present ? nota.value : this.nota,
    medio: medio.present ? medio.value : this.medio,
    cuentaDigitalId: cuentaDigitalId.present
        ? cuentaDigitalId.value
        : this.cuentaDigitalId,
    suscripcionId: suscripcionId.present
        ? suscripcionId.value
        : this.suscripcionId,
    suscripcionPeriodo: suscripcionPeriodo.present
        ? suscripcionPeriodo.value
        : this.suscripcionPeriodo,
  );
  Gasto copyWithCompanion(GastosCompanion data) {
    return Gasto(
      id: data.id.present ? data.id.value : this.id,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      monto: data.monto.present ? data.monto.value : this.monto,
      categoria: data.categoria.present ? data.categoria.value : this.categoria,
      fecha: data.fecha.present ? data.fecha.value : this.fecha,
      nota: data.nota.present ? data.nota.value : this.nota,
      medio: data.medio.present ? data.medio.value : this.medio,
      cuentaDigitalId: data.cuentaDigitalId.present
          ? data.cuentaDigitalId.value
          : this.cuentaDigitalId,
      suscripcionId: data.suscripcionId.present
          ? data.suscripcionId.value
          : this.suscripcionId,
      suscripcionPeriodo: data.suscripcionPeriodo.present
          ? data.suscripcionPeriodo.value
          : this.suscripcionPeriodo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Gasto(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('monto: $monto, ')
          ..write('categoria: $categoria, ')
          ..write('fecha: $fecha, ')
          ..write('nota: $nota, ')
          ..write('medio: $medio, ')
          ..write('cuentaDigitalId: $cuentaDigitalId, ')
          ..write('suscripcionId: $suscripcionId, ')
          ..write('suscripcionPeriodo: $suscripcionPeriodo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    nombre,
    monto,
    categoria,
    fecha,
    nota,
    medio,
    cuentaDigitalId,
    suscripcionId,
    suscripcionPeriodo,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Gasto &&
          other.id == this.id &&
          other.nombre == this.nombre &&
          other.monto == this.monto &&
          other.categoria == this.categoria &&
          other.fecha == this.fecha &&
          other.nota == this.nota &&
          other.medio == this.medio &&
          other.cuentaDigitalId == this.cuentaDigitalId &&
          other.suscripcionId == this.suscripcionId &&
          other.suscripcionPeriodo == this.suscripcionPeriodo);
}

class GastosCompanion extends UpdateCompanion<Gasto> {
  final Value<int> id;
  final Value<String> nombre;
  final Value<double> monto;
  final Value<String> categoria;
  final Value<DateTime> fecha;
  final Value<String?> nota;
  final Value<String?> medio;
  final Value<int?> cuentaDigitalId;
  final Value<int?> suscripcionId;
  final Value<DateTime?> suscripcionPeriodo;
  const GastosCompanion({
    this.id = const Value.absent(),
    this.nombre = const Value.absent(),
    this.monto = const Value.absent(),
    this.categoria = const Value.absent(),
    this.fecha = const Value.absent(),
    this.nota = const Value.absent(),
    this.medio = const Value.absent(),
    this.cuentaDigitalId = const Value.absent(),
    this.suscripcionId = const Value.absent(),
    this.suscripcionPeriodo = const Value.absent(),
  });
  GastosCompanion.insert({
    this.id = const Value.absent(),
    required String nombre,
    required double monto,
    required String categoria,
    required DateTime fecha,
    this.nota = const Value.absent(),
    this.medio = const Value.absent(),
    this.cuentaDigitalId = const Value.absent(),
    this.suscripcionId = const Value.absent(),
    this.suscripcionPeriodo = const Value.absent(),
  }) : nombre = Value(nombre),
       monto = Value(monto),
       categoria = Value(categoria),
       fecha = Value(fecha);
  static Insertable<Gasto> custom({
    Expression<int>? id,
    Expression<String>? nombre,
    Expression<double>? monto,
    Expression<String>? categoria,
    Expression<DateTime>? fecha,
    Expression<String>? nota,
    Expression<String>? medio,
    Expression<int>? cuentaDigitalId,
    Expression<int>? suscripcionId,
    Expression<DateTime>? suscripcionPeriodo,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nombre != null) 'nombre': nombre,
      if (monto != null) 'monto': monto,
      if (categoria != null) 'categoria': categoria,
      if (fecha != null) 'fecha': fecha,
      if (nota != null) 'nota': nota,
      if (medio != null) 'medio': medio,
      if (cuentaDigitalId != null) 'cuenta_digital_id': cuentaDigitalId,
      if (suscripcionId != null) 'suscripcion_id': suscripcionId,
      if (suscripcionPeriodo != null) 'suscripcion_periodo': suscripcionPeriodo,
    });
  }

  GastosCompanion copyWith({
    Value<int>? id,
    Value<String>? nombre,
    Value<double>? monto,
    Value<String>? categoria,
    Value<DateTime>? fecha,
    Value<String?>? nota,
    Value<String?>? medio,
    Value<int?>? cuentaDigitalId,
    Value<int?>? suscripcionId,
    Value<DateTime?>? suscripcionPeriodo,
  }) {
    return GastosCompanion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      monto: monto ?? this.monto,
      categoria: categoria ?? this.categoria,
      fecha: fecha ?? this.fecha,
      nota: nota ?? this.nota,
      medio: medio ?? this.medio,
      cuentaDigitalId: cuentaDigitalId ?? this.cuentaDigitalId,
      suscripcionId: suscripcionId ?? this.suscripcionId,
      suscripcionPeriodo: suscripcionPeriodo ?? this.suscripcionPeriodo,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (monto.present) {
      map['monto'] = Variable<double>(monto.value);
    }
    if (categoria.present) {
      map['categoria'] = Variable<String>(categoria.value);
    }
    if (fecha.present) {
      map['fecha'] = Variable<DateTime>(fecha.value);
    }
    if (nota.present) {
      map['nota'] = Variable<String>(nota.value);
    }
    if (medio.present) {
      map['medio'] = Variable<String>(medio.value);
    }
    if (cuentaDigitalId.present) {
      map['cuenta_digital_id'] = Variable<int>(cuentaDigitalId.value);
    }
    if (suscripcionId.present) {
      map['suscripcion_id'] = Variable<int>(suscripcionId.value);
    }
    if (suscripcionPeriodo.present) {
      map['suscripcion_periodo'] = Variable<DateTime>(suscripcionPeriodo.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GastosCompanion(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('monto: $monto, ')
          ..write('categoria: $categoria, ')
          ..write('fecha: $fecha, ')
          ..write('nota: $nota, ')
          ..write('medio: $medio, ')
          ..write('cuentaDigitalId: $cuentaDigitalId, ')
          ..write('suscripcionId: $suscripcionId, ')
          ..write('suscripcionPeriodo: $suscripcionPeriodo')
          ..write(')'))
        .toString();
  }
}

class $DeudasTable extends Deudas with TableInfo<$DeudasTable, Deuda> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeudasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _ingresoIdMeta = const VerificationMeta(
    'ingresoId',
  );
  @override
  late final GeneratedColumn<int> ingresoId = GeneratedColumn<int>(
    'ingreso_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ingresos (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _montoOriginalMeta = const VerificationMeta(
    'montoOriginal',
  );
  @override
  late final GeneratedColumn<double> montoOriginal = GeneratedColumn<double>(
    'monto_original',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cuotaMeta = const VerificationMeta('cuota');
  @override
  late final GeneratedColumn<double> cuota = GeneratedColumn<double>(
    'cuota',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cuotasTotalesMeta = const VerificationMeta(
    'cuotasTotales',
  );
  @override
  late final GeneratedColumn<int> cuotasTotales = GeneratedColumn<int>(
    'cuotas_totales',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cuotasPagadasMeta = const VerificationMeta(
    'cuotasPagadas',
  );
  @override
  late final GeneratedColumn<int> cuotasPagadas = GeneratedColumn<int>(
    'cuotas_pagadas',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _cuotasPagadasDeclaradasMeta =
      const VerificationMeta('cuotasPagadasDeclaradas');
  @override
  late final GeneratedColumn<int> cuotasPagadasDeclaradas =
      GeneratedColumn<int>(
        'cuotas_pagadas_declaradas',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _cuotasLegadasRevisadasMeta =
      const VerificationMeta('cuotasLegadasRevisadas');
  @override
  late final GeneratedColumn<bool> cuotasLegadasRevisadas =
      GeneratedColumn<bool>(
        'cuotas_legadas_revisadas',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("cuotas_legadas_revisadas" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _fechaProximoPagoMeta = const VerificationMeta(
    'fechaProximoPago',
  );
  @override
  late final GeneratedColumn<DateTime> fechaProximoPago =
      GeneratedColumn<DateTime>(
        'fecha_proximo_pago',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ingresoId,
    nombre,
    montoOriginal,
    cuota,
    cuotasTotales,
    cuotasPagadas,
    cuotasPagadasDeclaradas,
    cuotasLegadasRevisadas,
    fechaProximoPago,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'deudas';
  @override
  VerificationContext validateIntegrity(
    Insertable<Deuda> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('ingreso_id')) {
      context.handle(
        _ingresoIdMeta,
        ingresoId.isAcceptableOrUnknown(data['ingreso_id']!, _ingresoIdMeta),
      );
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('monto_original')) {
      context.handle(
        _montoOriginalMeta,
        montoOriginal.isAcceptableOrUnknown(
          data['monto_original']!,
          _montoOriginalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_montoOriginalMeta);
    }
    if (data.containsKey('cuota')) {
      context.handle(
        _cuotaMeta,
        cuota.isAcceptableOrUnknown(data['cuota']!, _cuotaMeta),
      );
    } else if (isInserting) {
      context.missing(_cuotaMeta);
    }
    if (data.containsKey('cuotas_totales')) {
      context.handle(
        _cuotasTotalesMeta,
        cuotasTotales.isAcceptableOrUnknown(
          data['cuotas_totales']!,
          _cuotasTotalesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cuotasTotalesMeta);
    }
    if (data.containsKey('cuotas_pagadas')) {
      context.handle(
        _cuotasPagadasMeta,
        cuotasPagadas.isAcceptableOrUnknown(
          data['cuotas_pagadas']!,
          _cuotasPagadasMeta,
        ),
      );
    }
    if (data.containsKey('cuotas_pagadas_declaradas')) {
      context.handle(
        _cuotasPagadasDeclaradasMeta,
        cuotasPagadasDeclaradas.isAcceptableOrUnknown(
          data['cuotas_pagadas_declaradas']!,
          _cuotasPagadasDeclaradasMeta,
        ),
      );
    }
    if (data.containsKey('cuotas_legadas_revisadas')) {
      context.handle(
        _cuotasLegadasRevisadasMeta,
        cuotasLegadasRevisadas.isAcceptableOrUnknown(
          data['cuotas_legadas_revisadas']!,
          _cuotasLegadasRevisadasMeta,
        ),
      );
    }
    if (data.containsKey('fecha_proximo_pago')) {
      context.handle(
        _fechaProximoPagoMeta,
        fechaProximoPago.isAcceptableOrUnknown(
          data['fecha_proximo_pago']!,
          _fechaProximoPagoMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Deuda map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Deuda(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      ingresoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ingreso_id'],
      ),
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      montoOriginal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}monto_original'],
      )!,
      cuota: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cuota'],
      )!,
      cuotasTotales: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cuotas_totales'],
      )!,
      cuotasPagadas: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cuotas_pagadas'],
      )!,
      cuotasPagadasDeclaradas: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cuotas_pagadas_declaradas'],
      )!,
      cuotasLegadasRevisadas: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}cuotas_legadas_revisadas'],
      )!,
      fechaProximoPago: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha_proximo_pago'],
      ),
    );
  }

  @override
  $DeudasTable createAlias(String alias) {
    return $DeudasTable(attachedDatabase, alias);
  }
}

class Deuda extends DataClass implements Insertable<Deuda> {
  final int id;
  final int? ingresoId;
  final String nombre;
  final double montoOriginal;
  final double cuota;
  final int cuotasTotales;
  final int cuotasPagadas;
  final int cuotasPagadasDeclaradas;
  final bool cuotasLegadasRevisadas;
  final DateTime? fechaProximoPago;
  const Deuda({
    required this.id,
    this.ingresoId,
    required this.nombre,
    required this.montoOriginal,
    required this.cuota,
    required this.cuotasTotales,
    required this.cuotasPagadas,
    required this.cuotasPagadasDeclaradas,
    required this.cuotasLegadasRevisadas,
    this.fechaProximoPago,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || ingresoId != null) {
      map['ingreso_id'] = Variable<int>(ingresoId);
    }
    map['nombre'] = Variable<String>(nombre);
    map['monto_original'] = Variable<double>(montoOriginal);
    map['cuota'] = Variable<double>(cuota);
    map['cuotas_totales'] = Variable<int>(cuotasTotales);
    map['cuotas_pagadas'] = Variable<int>(cuotasPagadas);
    map['cuotas_pagadas_declaradas'] = Variable<int>(cuotasPagadasDeclaradas);
    map['cuotas_legadas_revisadas'] = Variable<bool>(cuotasLegadasRevisadas);
    if (!nullToAbsent || fechaProximoPago != null) {
      map['fecha_proximo_pago'] = Variable<DateTime>(fechaProximoPago);
    }
    return map;
  }

  DeudasCompanion toCompanion(bool nullToAbsent) {
    return DeudasCompanion(
      id: Value(id),
      ingresoId: ingresoId == null && nullToAbsent
          ? const Value.absent()
          : Value(ingresoId),
      nombre: Value(nombre),
      montoOriginal: Value(montoOriginal),
      cuota: Value(cuota),
      cuotasTotales: Value(cuotasTotales),
      cuotasPagadas: Value(cuotasPagadas),
      cuotasPagadasDeclaradas: Value(cuotasPagadasDeclaradas),
      cuotasLegadasRevisadas: Value(cuotasLegadasRevisadas),
      fechaProximoPago: fechaProximoPago == null && nullToAbsent
          ? const Value.absent()
          : Value(fechaProximoPago),
    );
  }

  factory Deuda.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Deuda(
      id: serializer.fromJson<int>(json['id']),
      ingresoId: serializer.fromJson<int?>(json['ingresoId']),
      nombre: serializer.fromJson<String>(json['nombre']),
      montoOriginal: serializer.fromJson<double>(json['montoOriginal']),
      cuota: serializer.fromJson<double>(json['cuota']),
      cuotasTotales: serializer.fromJson<int>(json['cuotasTotales']),
      cuotasPagadas: serializer.fromJson<int>(json['cuotasPagadas']),
      cuotasPagadasDeclaradas: serializer.fromJson<int>(
        json['cuotasPagadasDeclaradas'],
      ),
      cuotasLegadasRevisadas: serializer.fromJson<bool>(
        json['cuotasLegadasRevisadas'],
      ),
      fechaProximoPago: serializer.fromJson<DateTime?>(
        json['fechaProximoPago'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ingresoId': serializer.toJson<int?>(ingresoId),
      'nombre': serializer.toJson<String>(nombre),
      'montoOriginal': serializer.toJson<double>(montoOriginal),
      'cuota': serializer.toJson<double>(cuota),
      'cuotasTotales': serializer.toJson<int>(cuotasTotales),
      'cuotasPagadas': serializer.toJson<int>(cuotasPagadas),
      'cuotasPagadasDeclaradas': serializer.toJson<int>(
        cuotasPagadasDeclaradas,
      ),
      'cuotasLegadasRevisadas': serializer.toJson<bool>(cuotasLegadasRevisadas),
      'fechaProximoPago': serializer.toJson<DateTime?>(fechaProximoPago),
    };
  }

  Deuda copyWith({
    int? id,
    Value<int?> ingresoId = const Value.absent(),
    String? nombre,
    double? montoOriginal,
    double? cuota,
    int? cuotasTotales,
    int? cuotasPagadas,
    int? cuotasPagadasDeclaradas,
    bool? cuotasLegadasRevisadas,
    Value<DateTime?> fechaProximoPago = const Value.absent(),
  }) => Deuda(
    id: id ?? this.id,
    ingresoId: ingresoId.present ? ingresoId.value : this.ingresoId,
    nombre: nombre ?? this.nombre,
    montoOriginal: montoOriginal ?? this.montoOriginal,
    cuota: cuota ?? this.cuota,
    cuotasTotales: cuotasTotales ?? this.cuotasTotales,
    cuotasPagadas: cuotasPagadas ?? this.cuotasPagadas,
    cuotasPagadasDeclaradas:
        cuotasPagadasDeclaradas ?? this.cuotasPagadasDeclaradas,
    cuotasLegadasRevisadas:
        cuotasLegadasRevisadas ?? this.cuotasLegadasRevisadas,
    fechaProximoPago: fechaProximoPago.present
        ? fechaProximoPago.value
        : this.fechaProximoPago,
  );
  Deuda copyWithCompanion(DeudasCompanion data) {
    return Deuda(
      id: data.id.present ? data.id.value : this.id,
      ingresoId: data.ingresoId.present ? data.ingresoId.value : this.ingresoId,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      montoOriginal: data.montoOriginal.present
          ? data.montoOriginal.value
          : this.montoOriginal,
      cuota: data.cuota.present ? data.cuota.value : this.cuota,
      cuotasTotales: data.cuotasTotales.present
          ? data.cuotasTotales.value
          : this.cuotasTotales,
      cuotasPagadas: data.cuotasPagadas.present
          ? data.cuotasPagadas.value
          : this.cuotasPagadas,
      cuotasPagadasDeclaradas: data.cuotasPagadasDeclaradas.present
          ? data.cuotasPagadasDeclaradas.value
          : this.cuotasPagadasDeclaradas,
      cuotasLegadasRevisadas: data.cuotasLegadasRevisadas.present
          ? data.cuotasLegadasRevisadas.value
          : this.cuotasLegadasRevisadas,
      fechaProximoPago: data.fechaProximoPago.present
          ? data.fechaProximoPago.value
          : this.fechaProximoPago,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Deuda(')
          ..write('id: $id, ')
          ..write('ingresoId: $ingresoId, ')
          ..write('nombre: $nombre, ')
          ..write('montoOriginal: $montoOriginal, ')
          ..write('cuota: $cuota, ')
          ..write('cuotasTotales: $cuotasTotales, ')
          ..write('cuotasPagadas: $cuotasPagadas, ')
          ..write('cuotasPagadasDeclaradas: $cuotasPagadasDeclaradas, ')
          ..write('cuotasLegadasRevisadas: $cuotasLegadasRevisadas, ')
          ..write('fechaProximoPago: $fechaProximoPago')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ingresoId,
    nombre,
    montoOriginal,
    cuota,
    cuotasTotales,
    cuotasPagadas,
    cuotasPagadasDeclaradas,
    cuotasLegadasRevisadas,
    fechaProximoPago,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Deuda &&
          other.id == this.id &&
          other.ingresoId == this.ingresoId &&
          other.nombre == this.nombre &&
          other.montoOriginal == this.montoOriginal &&
          other.cuota == this.cuota &&
          other.cuotasTotales == this.cuotasTotales &&
          other.cuotasPagadas == this.cuotasPagadas &&
          other.cuotasPagadasDeclaradas == this.cuotasPagadasDeclaradas &&
          other.cuotasLegadasRevisadas == this.cuotasLegadasRevisadas &&
          other.fechaProximoPago == this.fechaProximoPago);
}

class DeudasCompanion extends UpdateCompanion<Deuda> {
  final Value<int> id;
  final Value<int?> ingresoId;
  final Value<String> nombre;
  final Value<double> montoOriginal;
  final Value<double> cuota;
  final Value<int> cuotasTotales;
  final Value<int> cuotasPagadas;
  final Value<int> cuotasPagadasDeclaradas;
  final Value<bool> cuotasLegadasRevisadas;
  final Value<DateTime?> fechaProximoPago;
  const DeudasCompanion({
    this.id = const Value.absent(),
    this.ingresoId = const Value.absent(),
    this.nombre = const Value.absent(),
    this.montoOriginal = const Value.absent(),
    this.cuota = const Value.absent(),
    this.cuotasTotales = const Value.absent(),
    this.cuotasPagadas = const Value.absent(),
    this.cuotasPagadasDeclaradas = const Value.absent(),
    this.cuotasLegadasRevisadas = const Value.absent(),
    this.fechaProximoPago = const Value.absent(),
  });
  DeudasCompanion.insert({
    this.id = const Value.absent(),
    this.ingresoId = const Value.absent(),
    required String nombre,
    required double montoOriginal,
    required double cuota,
    required int cuotasTotales,
    this.cuotasPagadas = const Value.absent(),
    this.cuotasPagadasDeclaradas = const Value.absent(),
    this.cuotasLegadasRevisadas = const Value.absent(),
    this.fechaProximoPago = const Value.absent(),
  }) : nombre = Value(nombre),
       montoOriginal = Value(montoOriginal),
       cuota = Value(cuota),
       cuotasTotales = Value(cuotasTotales);
  static Insertable<Deuda> custom({
    Expression<int>? id,
    Expression<int>? ingresoId,
    Expression<String>? nombre,
    Expression<double>? montoOriginal,
    Expression<double>? cuota,
    Expression<int>? cuotasTotales,
    Expression<int>? cuotasPagadas,
    Expression<int>? cuotasPagadasDeclaradas,
    Expression<bool>? cuotasLegadasRevisadas,
    Expression<DateTime>? fechaProximoPago,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ingresoId != null) 'ingreso_id': ingresoId,
      if (nombre != null) 'nombre': nombre,
      if (montoOriginal != null) 'monto_original': montoOriginal,
      if (cuota != null) 'cuota': cuota,
      if (cuotasTotales != null) 'cuotas_totales': cuotasTotales,
      if (cuotasPagadas != null) 'cuotas_pagadas': cuotasPagadas,
      if (cuotasPagadasDeclaradas != null)
        'cuotas_pagadas_declaradas': cuotasPagadasDeclaradas,
      if (cuotasLegadasRevisadas != null)
        'cuotas_legadas_revisadas': cuotasLegadasRevisadas,
      if (fechaProximoPago != null) 'fecha_proximo_pago': fechaProximoPago,
    });
  }

  DeudasCompanion copyWith({
    Value<int>? id,
    Value<int?>? ingresoId,
    Value<String>? nombre,
    Value<double>? montoOriginal,
    Value<double>? cuota,
    Value<int>? cuotasTotales,
    Value<int>? cuotasPagadas,
    Value<int>? cuotasPagadasDeclaradas,
    Value<bool>? cuotasLegadasRevisadas,
    Value<DateTime?>? fechaProximoPago,
  }) {
    return DeudasCompanion(
      id: id ?? this.id,
      ingresoId: ingresoId ?? this.ingresoId,
      nombre: nombre ?? this.nombre,
      montoOriginal: montoOriginal ?? this.montoOriginal,
      cuota: cuota ?? this.cuota,
      cuotasTotales: cuotasTotales ?? this.cuotasTotales,
      cuotasPagadas: cuotasPagadas ?? this.cuotasPagadas,
      cuotasPagadasDeclaradas:
          cuotasPagadasDeclaradas ?? this.cuotasPagadasDeclaradas,
      cuotasLegadasRevisadas:
          cuotasLegadasRevisadas ?? this.cuotasLegadasRevisadas,
      fechaProximoPago: fechaProximoPago ?? this.fechaProximoPago,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ingresoId.present) {
      map['ingreso_id'] = Variable<int>(ingresoId.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (montoOriginal.present) {
      map['monto_original'] = Variable<double>(montoOriginal.value);
    }
    if (cuota.present) {
      map['cuota'] = Variable<double>(cuota.value);
    }
    if (cuotasTotales.present) {
      map['cuotas_totales'] = Variable<int>(cuotasTotales.value);
    }
    if (cuotasPagadas.present) {
      map['cuotas_pagadas'] = Variable<int>(cuotasPagadas.value);
    }
    if (cuotasPagadasDeclaradas.present) {
      map['cuotas_pagadas_declaradas'] = Variable<int>(
        cuotasPagadasDeclaradas.value,
      );
    }
    if (cuotasLegadasRevisadas.present) {
      map['cuotas_legadas_revisadas'] = Variable<bool>(
        cuotasLegadasRevisadas.value,
      );
    }
    if (fechaProximoPago.present) {
      map['fecha_proximo_pago'] = Variable<DateTime>(fechaProximoPago.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeudasCompanion(')
          ..write('id: $id, ')
          ..write('ingresoId: $ingresoId, ')
          ..write('nombre: $nombre, ')
          ..write('montoOriginal: $montoOriginal, ')
          ..write('cuota: $cuota, ')
          ..write('cuotasTotales: $cuotasTotales, ')
          ..write('cuotasPagadas: $cuotasPagadas, ')
          ..write('cuotasPagadasDeclaradas: $cuotasPagadasDeclaradas, ')
          ..write('cuotasLegadasRevisadas: $cuotasLegadasRevisadas, ')
          ..write('fechaProximoPago: $fechaProximoPago')
          ..write(')'))
        .toString();
  }
}

class $PagosDeudaTable extends PagosDeuda
    with TableInfo<$PagosDeudaTable, PagosDeudaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PagosDeudaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _deudaIdMeta = const VerificationMeta(
    'deudaId',
  );
  @override
  late final GeneratedColumn<int> deudaId = GeneratedColumn<int>(
    'deuda_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES deudas (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _montoMeta = const VerificationMeta('monto');
  @override
  late final GeneratedColumn<double> monto = GeneratedColumn<double>(
    'monto',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaMeta = const VerificationMeta('fecha');
  @override
  late final GeneratedColumn<DateTime> fecha = GeneratedColumn<DateTime>(
    'fecha',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationIdMeta = const VerificationMeta(
    'operationId',
  );
  @override
  late final GeneratedColumn<String> operationId = GeneratedColumn<String>(
    'operation_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _medioMeta = const VerificationMeta('medio');
  @override
  late final GeneratedColumn<String> medio = GeneratedColumn<String>(
    'medio',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    deudaId,
    monto,
    fecha,
    operationId,
    medio,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pagos_deuda';
  @override
  VerificationContext validateIntegrity(
    Insertable<PagosDeudaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('deuda_id')) {
      context.handle(
        _deudaIdMeta,
        deudaId.isAcceptableOrUnknown(data['deuda_id']!, _deudaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deudaIdMeta);
    }
    if (data.containsKey('monto')) {
      context.handle(
        _montoMeta,
        monto.isAcceptableOrUnknown(data['monto']!, _montoMeta),
      );
    } else if (isInserting) {
      context.missing(_montoMeta);
    }
    if (data.containsKey('fecha')) {
      context.handle(
        _fechaMeta,
        fecha.isAcceptableOrUnknown(data['fecha']!, _fechaMeta),
      );
    } else if (isInserting) {
      context.missing(_fechaMeta);
    }
    if (data.containsKey('operation_id')) {
      context.handle(
        _operationIdMeta,
        operationId.isAcceptableOrUnknown(
          data['operation_id']!,
          _operationIdMeta,
        ),
      );
    }
    if (data.containsKey('medio')) {
      context.handle(
        _medioMeta,
        medio.isAcceptableOrUnknown(data['medio']!, _medioMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PagosDeudaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PagosDeudaData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      deudaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deuda_id'],
      )!,
      monto: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}monto'],
      )!,
      fecha: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha'],
      )!,
      operationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_id'],
      ),
      medio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medio'],
      ),
    );
  }

  @override
  $PagosDeudaTable createAlias(String alias) {
    return $PagosDeudaTable(attachedDatabase, alias);
  }
}

class PagosDeudaData extends DataClass implements Insertable<PagosDeudaData> {
  final int id;
  final int deudaId;
  final double monto;
  final DateTime fecha;
  final String? operationId;
  final String? medio;
  const PagosDeudaData({
    required this.id,
    required this.deudaId,
    required this.monto,
    required this.fecha,
    this.operationId,
    this.medio,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['deuda_id'] = Variable<int>(deudaId);
    map['monto'] = Variable<double>(monto);
    map['fecha'] = Variable<DateTime>(fecha);
    if (!nullToAbsent || operationId != null) {
      map['operation_id'] = Variable<String>(operationId);
    }
    if (!nullToAbsent || medio != null) {
      map['medio'] = Variable<String>(medio);
    }
    return map;
  }

  PagosDeudaCompanion toCompanion(bool nullToAbsent) {
    return PagosDeudaCompanion(
      id: Value(id),
      deudaId: Value(deudaId),
      monto: Value(monto),
      fecha: Value(fecha),
      operationId: operationId == null && nullToAbsent
          ? const Value.absent()
          : Value(operationId),
      medio: medio == null && nullToAbsent
          ? const Value.absent()
          : Value(medio),
    );
  }

  factory PagosDeudaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PagosDeudaData(
      id: serializer.fromJson<int>(json['id']),
      deudaId: serializer.fromJson<int>(json['deudaId']),
      monto: serializer.fromJson<double>(json['monto']),
      fecha: serializer.fromJson<DateTime>(json['fecha']),
      operationId: serializer.fromJson<String?>(json['operationId']),
      medio: serializer.fromJson<String?>(json['medio']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'deudaId': serializer.toJson<int>(deudaId),
      'monto': serializer.toJson<double>(monto),
      'fecha': serializer.toJson<DateTime>(fecha),
      'operationId': serializer.toJson<String?>(operationId),
      'medio': serializer.toJson<String?>(medio),
    };
  }

  PagosDeudaData copyWith({
    int? id,
    int? deudaId,
    double? monto,
    DateTime? fecha,
    Value<String?> operationId = const Value.absent(),
    Value<String?> medio = const Value.absent(),
  }) => PagosDeudaData(
    id: id ?? this.id,
    deudaId: deudaId ?? this.deudaId,
    monto: monto ?? this.monto,
    fecha: fecha ?? this.fecha,
    operationId: operationId.present ? operationId.value : this.operationId,
    medio: medio.present ? medio.value : this.medio,
  );
  PagosDeudaData copyWithCompanion(PagosDeudaCompanion data) {
    return PagosDeudaData(
      id: data.id.present ? data.id.value : this.id,
      deudaId: data.deudaId.present ? data.deudaId.value : this.deudaId,
      monto: data.monto.present ? data.monto.value : this.monto,
      fecha: data.fecha.present ? data.fecha.value : this.fecha,
      operationId: data.operationId.present
          ? data.operationId.value
          : this.operationId,
      medio: data.medio.present ? data.medio.value : this.medio,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PagosDeudaData(')
          ..write('id: $id, ')
          ..write('deudaId: $deudaId, ')
          ..write('monto: $monto, ')
          ..write('fecha: $fecha, ')
          ..write('operationId: $operationId, ')
          ..write('medio: $medio')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, deudaId, monto, fecha, operationId, medio);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PagosDeudaData &&
          other.id == this.id &&
          other.deudaId == this.deudaId &&
          other.monto == this.monto &&
          other.fecha == this.fecha &&
          other.operationId == this.operationId &&
          other.medio == this.medio);
}

class PagosDeudaCompanion extends UpdateCompanion<PagosDeudaData> {
  final Value<int> id;
  final Value<int> deudaId;
  final Value<double> monto;
  final Value<DateTime> fecha;
  final Value<String?> operationId;
  final Value<String?> medio;
  const PagosDeudaCompanion({
    this.id = const Value.absent(),
    this.deudaId = const Value.absent(),
    this.monto = const Value.absent(),
    this.fecha = const Value.absent(),
    this.operationId = const Value.absent(),
    this.medio = const Value.absent(),
  });
  PagosDeudaCompanion.insert({
    this.id = const Value.absent(),
    required int deudaId,
    required double monto,
    required DateTime fecha,
    this.operationId = const Value.absent(),
    this.medio = const Value.absent(),
  }) : deudaId = Value(deudaId),
       monto = Value(monto),
       fecha = Value(fecha);
  static Insertable<PagosDeudaData> custom({
    Expression<int>? id,
    Expression<int>? deudaId,
    Expression<double>? monto,
    Expression<DateTime>? fecha,
    Expression<String>? operationId,
    Expression<String>? medio,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deudaId != null) 'deuda_id': deudaId,
      if (monto != null) 'monto': monto,
      if (fecha != null) 'fecha': fecha,
      if (operationId != null) 'operation_id': operationId,
      if (medio != null) 'medio': medio,
    });
  }

  PagosDeudaCompanion copyWith({
    Value<int>? id,
    Value<int>? deudaId,
    Value<double>? monto,
    Value<DateTime>? fecha,
    Value<String?>? operationId,
    Value<String?>? medio,
  }) {
    return PagosDeudaCompanion(
      id: id ?? this.id,
      deudaId: deudaId ?? this.deudaId,
      monto: monto ?? this.monto,
      fecha: fecha ?? this.fecha,
      operationId: operationId ?? this.operationId,
      medio: medio ?? this.medio,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (deudaId.present) {
      map['deuda_id'] = Variable<int>(deudaId.value);
    }
    if (monto.present) {
      map['monto'] = Variable<double>(monto.value);
    }
    if (fecha.present) {
      map['fecha'] = Variable<DateTime>(fecha.value);
    }
    if (operationId.present) {
      map['operation_id'] = Variable<String>(operationId.value);
    }
    if (medio.present) {
      map['medio'] = Variable<String>(medio.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PagosDeudaCompanion(')
          ..write('id: $id, ')
          ..write('deudaId: $deudaId, ')
          ..write('monto: $monto, ')
          ..write('fecha: $fecha, ')
          ..write('operationId: $operationId, ')
          ..write('medio: $medio')
          ..write(')'))
        .toString();
  }
}

class $MovimientosAhorroTable extends MovimientosAhorro
    with TableInfo<$MovimientosAhorroTable, MovimientosAhorroData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MovimientosAhorroTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _montoMeta = const VerificationMeta('monto');
  @override
  late final GeneratedColumn<double> monto = GeneratedColumn<double>(
    'monto',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaMeta = const VerificationMeta('fecha');
  @override
  late final GeneratedColumn<DateTime> fecha = GeneratedColumn<DateTime>(
    'fecha',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _medioMeta = const VerificationMeta('medio');
  @override
  late final GeneratedColumn<String> medio = GeneratedColumn<String>(
    'medio',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, monto, tipo, fecha, medio];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'movimientos_ahorro';
  @override
  VerificationContext validateIntegrity(
    Insertable<MovimientosAhorroData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('monto')) {
      context.handle(
        _montoMeta,
        monto.isAcceptableOrUnknown(data['monto']!, _montoMeta),
      );
    } else if (isInserting) {
      context.missing(_montoMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    if (data.containsKey('fecha')) {
      context.handle(
        _fechaMeta,
        fecha.isAcceptableOrUnknown(data['fecha']!, _fechaMeta),
      );
    } else if (isInserting) {
      context.missing(_fechaMeta);
    }
    if (data.containsKey('medio')) {
      context.handle(
        _medioMeta,
        medio.isAcceptableOrUnknown(data['medio']!, _medioMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MovimientosAhorroData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MovimientosAhorroData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      monto: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}monto'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      )!,
      fecha: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha'],
      )!,
      medio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medio'],
      ),
    );
  }

  @override
  $MovimientosAhorroTable createAlias(String alias) {
    return $MovimientosAhorroTable(attachedDatabase, alias);
  }
}

class MovimientosAhorroData extends DataClass
    implements Insertable<MovimientosAhorroData> {
  final int id;
  final double monto;
  final String tipo;
  final DateTime fecha;
  final String? medio;
  const MovimientosAhorroData({
    required this.id,
    required this.monto,
    required this.tipo,
    required this.fecha,
    this.medio,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['monto'] = Variable<double>(monto);
    map['tipo'] = Variable<String>(tipo);
    map['fecha'] = Variable<DateTime>(fecha);
    if (!nullToAbsent || medio != null) {
      map['medio'] = Variable<String>(medio);
    }
    return map;
  }

  MovimientosAhorroCompanion toCompanion(bool nullToAbsent) {
    return MovimientosAhorroCompanion(
      id: Value(id),
      monto: Value(monto),
      tipo: Value(tipo),
      fecha: Value(fecha),
      medio: medio == null && nullToAbsent
          ? const Value.absent()
          : Value(medio),
    );
  }

  factory MovimientosAhorroData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MovimientosAhorroData(
      id: serializer.fromJson<int>(json['id']),
      monto: serializer.fromJson<double>(json['monto']),
      tipo: serializer.fromJson<String>(json['tipo']),
      fecha: serializer.fromJson<DateTime>(json['fecha']),
      medio: serializer.fromJson<String?>(json['medio']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'monto': serializer.toJson<double>(monto),
      'tipo': serializer.toJson<String>(tipo),
      'fecha': serializer.toJson<DateTime>(fecha),
      'medio': serializer.toJson<String?>(medio),
    };
  }

  MovimientosAhorroData copyWith({
    int? id,
    double? monto,
    String? tipo,
    DateTime? fecha,
    Value<String?> medio = const Value.absent(),
  }) => MovimientosAhorroData(
    id: id ?? this.id,
    monto: monto ?? this.monto,
    tipo: tipo ?? this.tipo,
    fecha: fecha ?? this.fecha,
    medio: medio.present ? medio.value : this.medio,
  );
  MovimientosAhorroData copyWithCompanion(MovimientosAhorroCompanion data) {
    return MovimientosAhorroData(
      id: data.id.present ? data.id.value : this.id,
      monto: data.monto.present ? data.monto.value : this.monto,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      fecha: data.fecha.present ? data.fecha.value : this.fecha,
      medio: data.medio.present ? data.medio.value : this.medio,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MovimientosAhorroData(')
          ..write('id: $id, ')
          ..write('monto: $monto, ')
          ..write('tipo: $tipo, ')
          ..write('fecha: $fecha, ')
          ..write('medio: $medio')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, monto, tipo, fecha, medio);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MovimientosAhorroData &&
          other.id == this.id &&
          other.monto == this.monto &&
          other.tipo == this.tipo &&
          other.fecha == this.fecha &&
          other.medio == this.medio);
}

class MovimientosAhorroCompanion
    extends UpdateCompanion<MovimientosAhorroData> {
  final Value<int> id;
  final Value<double> monto;
  final Value<String> tipo;
  final Value<DateTime> fecha;
  final Value<String?> medio;
  const MovimientosAhorroCompanion({
    this.id = const Value.absent(),
    this.monto = const Value.absent(),
    this.tipo = const Value.absent(),
    this.fecha = const Value.absent(),
    this.medio = const Value.absent(),
  });
  MovimientosAhorroCompanion.insert({
    this.id = const Value.absent(),
    required double monto,
    required String tipo,
    required DateTime fecha,
    this.medio = const Value.absent(),
  }) : monto = Value(monto),
       tipo = Value(tipo),
       fecha = Value(fecha);
  static Insertable<MovimientosAhorroData> custom({
    Expression<int>? id,
    Expression<double>? monto,
    Expression<String>? tipo,
    Expression<DateTime>? fecha,
    Expression<String>? medio,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (monto != null) 'monto': monto,
      if (tipo != null) 'tipo': tipo,
      if (fecha != null) 'fecha': fecha,
      if (medio != null) 'medio': medio,
    });
  }

  MovimientosAhorroCompanion copyWith({
    Value<int>? id,
    Value<double>? monto,
    Value<String>? tipo,
    Value<DateTime>? fecha,
    Value<String?>? medio,
  }) {
    return MovimientosAhorroCompanion(
      id: id ?? this.id,
      monto: monto ?? this.monto,
      tipo: tipo ?? this.tipo,
      fecha: fecha ?? this.fecha,
      medio: medio ?? this.medio,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (monto.present) {
      map['monto'] = Variable<double>(monto.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (fecha.present) {
      map['fecha'] = Variable<DateTime>(fecha.value);
    }
    if (medio.present) {
      map['medio'] = Variable<String>(medio.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MovimientosAhorroCompanion(')
          ..write('id: $id, ')
          ..write('monto: $monto, ')
          ..write('tipo: $tipo, ')
          ..write('fecha: $fecha, ')
          ..write('medio: $medio')
          ..write(')'))
        .toString();
  }
}

class $PrestamosTercerosTable extends PrestamosTerceros
    with TableInfo<$PrestamosTercerosTable, PrestamosTercero> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrestamosTercerosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _personaMeta = const VerificationMeta(
    'persona',
  );
  @override
  late final GeneratedColumn<String> persona = GeneratedColumn<String>(
    'persona',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _montoPrincipalMeta = const VerificationMeta(
    'montoPrincipal',
  );
  @override
  late final GeneratedColumn<double> montoPrincipal = GeneratedColumn<double>(
    'monto_principal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaEntregaMeta = const VerificationMeta(
    'fechaEntrega',
  );
  @override
  late final GeneratedColumn<DateTime> fechaEntrega = GeneratedColumn<DateTime>(
    'fecha_entrega',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaDevolucionAcordadaMeta =
      const VerificationMeta('fechaDevolucionAcordada');
  @override
  late final GeneratedColumn<DateTime> fechaDevolucionAcordada =
      GeneratedColumn<DateTime>(
        'fecha_devolucion_acordada',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    persona,
    montoPrincipal,
    fechaEntrega,
    fechaDevolucionAcordada,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prestamos_terceros';
  @override
  VerificationContext validateIntegrity(
    Insertable<PrestamosTercero> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('persona')) {
      context.handle(
        _personaMeta,
        persona.isAcceptableOrUnknown(data['persona']!, _personaMeta),
      );
    } else if (isInserting) {
      context.missing(_personaMeta);
    }
    if (data.containsKey('monto_principal')) {
      context.handle(
        _montoPrincipalMeta,
        montoPrincipal.isAcceptableOrUnknown(
          data['monto_principal']!,
          _montoPrincipalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_montoPrincipalMeta);
    }
    if (data.containsKey('fecha_entrega')) {
      context.handle(
        _fechaEntregaMeta,
        fechaEntrega.isAcceptableOrUnknown(
          data['fecha_entrega']!,
          _fechaEntregaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fechaEntregaMeta);
    }
    if (data.containsKey('fecha_devolucion_acordada')) {
      context.handle(
        _fechaDevolucionAcordadaMeta,
        fechaDevolucionAcordada.isAcceptableOrUnknown(
          data['fecha_devolucion_acordada']!,
          _fechaDevolucionAcordadaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fechaDevolucionAcordadaMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PrestamosTercero map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrestamosTercero(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      persona: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}persona'],
      )!,
      montoPrincipal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}monto_principal'],
      )!,
      fechaEntrega: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha_entrega'],
      )!,
      fechaDevolucionAcordada: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha_devolucion_acordada'],
      )!,
    );
  }

  @override
  $PrestamosTercerosTable createAlias(String alias) {
    return $PrestamosTercerosTable(attachedDatabase, alias);
  }
}

class PrestamosTercero extends DataClass
    implements Insertable<PrestamosTercero> {
  final int id;
  final String persona;
  final double montoPrincipal;
  final DateTime fechaEntrega;
  final DateTime fechaDevolucionAcordada;
  const PrestamosTercero({
    required this.id,
    required this.persona,
    required this.montoPrincipal,
    required this.fechaEntrega,
    required this.fechaDevolucionAcordada,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['persona'] = Variable<String>(persona);
    map['monto_principal'] = Variable<double>(montoPrincipal);
    map['fecha_entrega'] = Variable<DateTime>(fechaEntrega);
    map['fecha_devolucion_acordada'] = Variable<DateTime>(
      fechaDevolucionAcordada,
    );
    return map;
  }

  PrestamosTercerosCompanion toCompanion(bool nullToAbsent) {
    return PrestamosTercerosCompanion(
      id: Value(id),
      persona: Value(persona),
      montoPrincipal: Value(montoPrincipal),
      fechaEntrega: Value(fechaEntrega),
      fechaDevolucionAcordada: Value(fechaDevolucionAcordada),
    );
  }

  factory PrestamosTercero.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrestamosTercero(
      id: serializer.fromJson<int>(json['id']),
      persona: serializer.fromJson<String>(json['persona']),
      montoPrincipal: serializer.fromJson<double>(json['montoPrincipal']),
      fechaEntrega: serializer.fromJson<DateTime>(json['fechaEntrega']),
      fechaDevolucionAcordada: serializer.fromJson<DateTime>(
        json['fechaDevolucionAcordada'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'persona': serializer.toJson<String>(persona),
      'montoPrincipal': serializer.toJson<double>(montoPrincipal),
      'fechaEntrega': serializer.toJson<DateTime>(fechaEntrega),
      'fechaDevolucionAcordada': serializer.toJson<DateTime>(
        fechaDevolucionAcordada,
      ),
    };
  }

  PrestamosTercero copyWith({
    int? id,
    String? persona,
    double? montoPrincipal,
    DateTime? fechaEntrega,
    DateTime? fechaDevolucionAcordada,
  }) => PrestamosTercero(
    id: id ?? this.id,
    persona: persona ?? this.persona,
    montoPrincipal: montoPrincipal ?? this.montoPrincipal,
    fechaEntrega: fechaEntrega ?? this.fechaEntrega,
    fechaDevolucionAcordada:
        fechaDevolucionAcordada ?? this.fechaDevolucionAcordada,
  );
  PrestamosTercero copyWithCompanion(PrestamosTercerosCompanion data) {
    return PrestamosTercero(
      id: data.id.present ? data.id.value : this.id,
      persona: data.persona.present ? data.persona.value : this.persona,
      montoPrincipal: data.montoPrincipal.present
          ? data.montoPrincipal.value
          : this.montoPrincipal,
      fechaEntrega: data.fechaEntrega.present
          ? data.fechaEntrega.value
          : this.fechaEntrega,
      fechaDevolucionAcordada: data.fechaDevolucionAcordada.present
          ? data.fechaDevolucionAcordada.value
          : this.fechaDevolucionAcordada,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrestamosTercero(')
          ..write('id: $id, ')
          ..write('persona: $persona, ')
          ..write('montoPrincipal: $montoPrincipal, ')
          ..write('fechaEntrega: $fechaEntrega, ')
          ..write('fechaDevolucionAcordada: $fechaDevolucionAcordada')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    persona,
    montoPrincipal,
    fechaEntrega,
    fechaDevolucionAcordada,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrestamosTercero &&
          other.id == this.id &&
          other.persona == this.persona &&
          other.montoPrincipal == this.montoPrincipal &&
          other.fechaEntrega == this.fechaEntrega &&
          other.fechaDevolucionAcordada == this.fechaDevolucionAcordada);
}

class PrestamosTercerosCompanion extends UpdateCompanion<PrestamosTercero> {
  final Value<int> id;
  final Value<String> persona;
  final Value<double> montoPrincipal;
  final Value<DateTime> fechaEntrega;
  final Value<DateTime> fechaDevolucionAcordada;
  const PrestamosTercerosCompanion({
    this.id = const Value.absent(),
    this.persona = const Value.absent(),
    this.montoPrincipal = const Value.absent(),
    this.fechaEntrega = const Value.absent(),
    this.fechaDevolucionAcordada = const Value.absent(),
  });
  PrestamosTercerosCompanion.insert({
    this.id = const Value.absent(),
    required String persona,
    required double montoPrincipal,
    required DateTime fechaEntrega,
    required DateTime fechaDevolucionAcordada,
  }) : persona = Value(persona),
       montoPrincipal = Value(montoPrincipal),
       fechaEntrega = Value(fechaEntrega),
       fechaDevolucionAcordada = Value(fechaDevolucionAcordada);
  static Insertable<PrestamosTercero> custom({
    Expression<int>? id,
    Expression<String>? persona,
    Expression<double>? montoPrincipal,
    Expression<DateTime>? fechaEntrega,
    Expression<DateTime>? fechaDevolucionAcordada,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (persona != null) 'persona': persona,
      if (montoPrincipal != null) 'monto_principal': montoPrincipal,
      if (fechaEntrega != null) 'fecha_entrega': fechaEntrega,
      if (fechaDevolucionAcordada != null)
        'fecha_devolucion_acordada': fechaDevolucionAcordada,
    });
  }

  PrestamosTercerosCompanion copyWith({
    Value<int>? id,
    Value<String>? persona,
    Value<double>? montoPrincipal,
    Value<DateTime>? fechaEntrega,
    Value<DateTime>? fechaDevolucionAcordada,
  }) {
    return PrestamosTercerosCompanion(
      id: id ?? this.id,
      persona: persona ?? this.persona,
      montoPrincipal: montoPrincipal ?? this.montoPrincipal,
      fechaEntrega: fechaEntrega ?? this.fechaEntrega,
      fechaDevolucionAcordada:
          fechaDevolucionAcordada ?? this.fechaDevolucionAcordada,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (persona.present) {
      map['persona'] = Variable<String>(persona.value);
    }
    if (montoPrincipal.present) {
      map['monto_principal'] = Variable<double>(montoPrincipal.value);
    }
    if (fechaEntrega.present) {
      map['fecha_entrega'] = Variable<DateTime>(fechaEntrega.value);
    }
    if (fechaDevolucionAcordada.present) {
      map['fecha_devolucion_acordada'] = Variable<DateTime>(
        fechaDevolucionAcordada.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrestamosTercerosCompanion(')
          ..write('id: $id, ')
          ..write('persona: $persona, ')
          ..write('montoPrincipal: $montoPrincipal, ')
          ..write('fechaEntrega: $fechaEntrega, ')
          ..write('fechaDevolucionAcordada: $fechaDevolucionAcordada')
          ..write(')'))
        .toString();
  }
}

class $MovimientosPrestamoTable extends MovimientosPrestamo
    with TableInfo<$MovimientosPrestamoTable, MovimientosPrestamoData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MovimientosPrestamoTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _prestamoIdMeta = const VerificationMeta(
    'prestamoId',
  );
  @override
  late final GeneratedColumn<int> prestamoId = GeneratedColumn<int>(
    'prestamo_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES prestamos_terceros (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _montoMeta = const VerificationMeta('monto');
  @override
  late final GeneratedColumn<double> monto = GeneratedColumn<double>(
    'monto',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaMeta = const VerificationMeta('fecha');
  @override
  late final GeneratedColumn<DateTime> fecha = GeneratedColumn<DateTime>(
    'fecha',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationIdMeta = const VerificationMeta(
    'operationId',
  );
  @override
  late final GeneratedColumn<String> operationId = GeneratedColumn<String>(
    'operation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _medioMeta = const VerificationMeta('medio');
  @override
  late final GeneratedColumn<String> medio = GeneratedColumn<String>(
    'medio',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    prestamoId,
    tipo,
    monto,
    fecha,
    operationId,
    medio,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'movimientos_prestamo';
  @override
  VerificationContext validateIntegrity(
    Insertable<MovimientosPrestamoData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('prestamo_id')) {
      context.handle(
        _prestamoIdMeta,
        prestamoId.isAcceptableOrUnknown(data['prestamo_id']!, _prestamoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_prestamoIdMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    if (data.containsKey('monto')) {
      context.handle(
        _montoMeta,
        monto.isAcceptableOrUnknown(data['monto']!, _montoMeta),
      );
    } else if (isInserting) {
      context.missing(_montoMeta);
    }
    if (data.containsKey('fecha')) {
      context.handle(
        _fechaMeta,
        fecha.isAcceptableOrUnknown(data['fecha']!, _fechaMeta),
      );
    } else if (isInserting) {
      context.missing(_fechaMeta);
    }
    if (data.containsKey('operation_id')) {
      context.handle(
        _operationIdMeta,
        operationId.isAcceptableOrUnknown(
          data['operation_id']!,
          _operationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationIdMeta);
    }
    if (data.containsKey('medio')) {
      context.handle(
        _medioMeta,
        medio.isAcceptableOrUnknown(data['medio']!, _medioMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MovimientosPrestamoData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MovimientosPrestamoData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      prestamoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prestamo_id'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      )!,
      monto: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}monto'],
      )!,
      fecha: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha'],
      )!,
      operationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_id'],
      )!,
      medio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medio'],
      ),
    );
  }

  @override
  $MovimientosPrestamoTable createAlias(String alias) {
    return $MovimientosPrestamoTable(attachedDatabase, alias);
  }
}

class MovimientosPrestamoData extends DataClass
    implements Insertable<MovimientosPrestamoData> {
  final int id;
  final int prestamoId;
  final String tipo;
  final double monto;
  final DateTime fecha;
  final String operationId;
  final String? medio;
  const MovimientosPrestamoData({
    required this.id,
    required this.prestamoId,
    required this.tipo,
    required this.monto,
    required this.fecha,
    required this.operationId,
    this.medio,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['prestamo_id'] = Variable<int>(prestamoId);
    map['tipo'] = Variable<String>(tipo);
    map['monto'] = Variable<double>(monto);
    map['fecha'] = Variable<DateTime>(fecha);
    map['operation_id'] = Variable<String>(operationId);
    if (!nullToAbsent || medio != null) {
      map['medio'] = Variable<String>(medio);
    }
    return map;
  }

  MovimientosPrestamoCompanion toCompanion(bool nullToAbsent) {
    return MovimientosPrestamoCompanion(
      id: Value(id),
      prestamoId: Value(prestamoId),
      tipo: Value(tipo),
      monto: Value(monto),
      fecha: Value(fecha),
      operationId: Value(operationId),
      medio: medio == null && nullToAbsent
          ? const Value.absent()
          : Value(medio),
    );
  }

  factory MovimientosPrestamoData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MovimientosPrestamoData(
      id: serializer.fromJson<int>(json['id']),
      prestamoId: serializer.fromJson<int>(json['prestamoId']),
      tipo: serializer.fromJson<String>(json['tipo']),
      monto: serializer.fromJson<double>(json['monto']),
      fecha: serializer.fromJson<DateTime>(json['fecha']),
      operationId: serializer.fromJson<String>(json['operationId']),
      medio: serializer.fromJson<String?>(json['medio']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'prestamoId': serializer.toJson<int>(prestamoId),
      'tipo': serializer.toJson<String>(tipo),
      'monto': serializer.toJson<double>(monto),
      'fecha': serializer.toJson<DateTime>(fecha),
      'operationId': serializer.toJson<String>(operationId),
      'medio': serializer.toJson<String?>(medio),
    };
  }

  MovimientosPrestamoData copyWith({
    int? id,
    int? prestamoId,
    String? tipo,
    double? monto,
    DateTime? fecha,
    String? operationId,
    Value<String?> medio = const Value.absent(),
  }) => MovimientosPrestamoData(
    id: id ?? this.id,
    prestamoId: prestamoId ?? this.prestamoId,
    tipo: tipo ?? this.tipo,
    monto: monto ?? this.monto,
    fecha: fecha ?? this.fecha,
    operationId: operationId ?? this.operationId,
    medio: medio.present ? medio.value : this.medio,
  );
  MovimientosPrestamoData copyWithCompanion(MovimientosPrestamoCompanion data) {
    return MovimientosPrestamoData(
      id: data.id.present ? data.id.value : this.id,
      prestamoId: data.prestamoId.present
          ? data.prestamoId.value
          : this.prestamoId,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      monto: data.monto.present ? data.monto.value : this.monto,
      fecha: data.fecha.present ? data.fecha.value : this.fecha,
      operationId: data.operationId.present
          ? data.operationId.value
          : this.operationId,
      medio: data.medio.present ? data.medio.value : this.medio,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MovimientosPrestamoData(')
          ..write('id: $id, ')
          ..write('prestamoId: $prestamoId, ')
          ..write('tipo: $tipo, ')
          ..write('monto: $monto, ')
          ..write('fecha: $fecha, ')
          ..write('operationId: $operationId, ')
          ..write('medio: $medio')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, prestamoId, tipo, monto, fecha, operationId, medio);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MovimientosPrestamoData &&
          other.id == this.id &&
          other.prestamoId == this.prestamoId &&
          other.tipo == this.tipo &&
          other.monto == this.monto &&
          other.fecha == this.fecha &&
          other.operationId == this.operationId &&
          other.medio == this.medio);
}

class MovimientosPrestamoCompanion
    extends UpdateCompanion<MovimientosPrestamoData> {
  final Value<int> id;
  final Value<int> prestamoId;
  final Value<String> tipo;
  final Value<double> monto;
  final Value<DateTime> fecha;
  final Value<String> operationId;
  final Value<String?> medio;
  const MovimientosPrestamoCompanion({
    this.id = const Value.absent(),
    this.prestamoId = const Value.absent(),
    this.tipo = const Value.absent(),
    this.monto = const Value.absent(),
    this.fecha = const Value.absent(),
    this.operationId = const Value.absent(),
    this.medio = const Value.absent(),
  });
  MovimientosPrestamoCompanion.insert({
    this.id = const Value.absent(),
    required int prestamoId,
    required String tipo,
    required double monto,
    required DateTime fecha,
    required String operationId,
    this.medio = const Value.absent(),
  }) : prestamoId = Value(prestamoId),
       tipo = Value(tipo),
       monto = Value(monto),
       fecha = Value(fecha),
       operationId = Value(operationId);
  static Insertable<MovimientosPrestamoData> custom({
    Expression<int>? id,
    Expression<int>? prestamoId,
    Expression<String>? tipo,
    Expression<double>? monto,
    Expression<DateTime>? fecha,
    Expression<String>? operationId,
    Expression<String>? medio,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (prestamoId != null) 'prestamo_id': prestamoId,
      if (tipo != null) 'tipo': tipo,
      if (monto != null) 'monto': monto,
      if (fecha != null) 'fecha': fecha,
      if (operationId != null) 'operation_id': operationId,
      if (medio != null) 'medio': medio,
    });
  }

  MovimientosPrestamoCompanion copyWith({
    Value<int>? id,
    Value<int>? prestamoId,
    Value<String>? tipo,
    Value<double>? monto,
    Value<DateTime>? fecha,
    Value<String>? operationId,
    Value<String?>? medio,
  }) {
    return MovimientosPrestamoCompanion(
      id: id ?? this.id,
      prestamoId: prestamoId ?? this.prestamoId,
      tipo: tipo ?? this.tipo,
      monto: monto ?? this.monto,
      fecha: fecha ?? this.fecha,
      operationId: operationId ?? this.operationId,
      medio: medio ?? this.medio,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (prestamoId.present) {
      map['prestamo_id'] = Variable<int>(prestamoId.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (monto.present) {
      map['monto'] = Variable<double>(monto.value);
    }
    if (fecha.present) {
      map['fecha'] = Variable<DateTime>(fecha.value);
    }
    if (operationId.present) {
      map['operation_id'] = Variable<String>(operationId.value);
    }
    if (medio.present) {
      map['medio'] = Variable<String>(medio.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MovimientosPrestamoCompanion(')
          ..write('id: $id, ')
          ..write('prestamoId: $prestamoId, ')
          ..write('tipo: $tipo, ')
          ..write('monto: $monto, ')
          ..write('fecha: $fecha, ')
          ..write('operationId: $operationId, ')
          ..write('medio: $medio')
          ..write(')'))
        .toString();
  }
}

class $GastosFuturosTable extends GastosFuturos
    with TableInfo<$GastosFuturosTable, GastosFuturo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GastosFuturosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoriaMeta = const VerificationMeta(
    'categoria',
  );
  @override
  late final GeneratedColumn<String> categoria = GeneratedColumn<String>(
    'categoria',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _montoNecesarioMeta = const VerificationMeta(
    'montoNecesario',
  );
  @override
  late final GeneratedColumn<double> montoNecesario = GeneratedColumn<double>(
    'monto_necesario',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _montoPlaneadoMeta = const VerificationMeta(
    'montoPlaneado',
  );
  @override
  late final GeneratedColumn<double> montoPlaneado = GeneratedColumn<double>(
    'monto_planeado',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _frecuenciaMeta = const VerificationMeta(
    'frecuencia',
  );
  @override
  late final GeneratedColumn<String> frecuencia = GeneratedColumn<String>(
    'frecuencia',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaObjetivoMeta = const VerificationMeta(
    'fechaObjetivo',
  );
  @override
  late final GeneratedColumn<DateTime> fechaObjetivo =
      GeneratedColumn<DateTime>(
        'fecha_objetivo',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _fechaInicioMeta = const VerificationMeta(
    'fechaInicio',
  );
  @override
  late final GeneratedColumn<DateTime> fechaInicio = GeneratedColumn<DateTime>(
    'fecha_inicio',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notasMeta = const VerificationMeta('notas');
  @override
  late final GeneratedColumn<String> notas = GeneratedColumn<String>(
    'notas',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _estadoMeta = const VerificationMeta('estado');
  @override
  late final GeneratedColumn<String> estado = GeneratedColumn<String>(
    'estado',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('activo'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nombre,
    categoria,
    montoNecesario,
    montoPlaneado,
    frecuencia,
    fechaObjetivo,
    fechaInicio,
    notas,
    estado,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'gastos_futuros';
  @override
  VerificationContext validateIntegrity(
    Insertable<GastosFuturo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('categoria')) {
      context.handle(
        _categoriaMeta,
        categoria.isAcceptableOrUnknown(data['categoria']!, _categoriaMeta),
      );
    } else if (isInserting) {
      context.missing(_categoriaMeta);
    }
    if (data.containsKey('monto_necesario')) {
      context.handle(
        _montoNecesarioMeta,
        montoNecesario.isAcceptableOrUnknown(
          data['monto_necesario']!,
          _montoNecesarioMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_montoNecesarioMeta);
    }
    if (data.containsKey('monto_planeado')) {
      context.handle(
        _montoPlaneadoMeta,
        montoPlaneado.isAcceptableOrUnknown(
          data['monto_planeado']!,
          _montoPlaneadoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_montoPlaneadoMeta);
    }
    if (data.containsKey('frecuencia')) {
      context.handle(
        _frecuenciaMeta,
        frecuencia.isAcceptableOrUnknown(data['frecuencia']!, _frecuenciaMeta),
      );
    } else if (isInserting) {
      context.missing(_frecuenciaMeta);
    }
    if (data.containsKey('fecha_objetivo')) {
      context.handle(
        _fechaObjetivoMeta,
        fechaObjetivo.isAcceptableOrUnknown(
          data['fecha_objetivo']!,
          _fechaObjetivoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fechaObjetivoMeta);
    }
    if (data.containsKey('fecha_inicio')) {
      context.handle(
        _fechaInicioMeta,
        fechaInicio.isAcceptableOrUnknown(
          data['fecha_inicio']!,
          _fechaInicioMeta,
        ),
      );
    }
    if (data.containsKey('notas')) {
      context.handle(
        _notasMeta,
        notas.isAcceptableOrUnknown(data['notas']!, _notasMeta),
      );
    }
    if (data.containsKey('estado')) {
      context.handle(
        _estadoMeta,
        estado.isAcceptableOrUnknown(data['estado']!, _estadoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GastosFuturo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GastosFuturo(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      categoria: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}categoria'],
      )!,
      montoNecesario: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}monto_necesario'],
      )!,
      montoPlaneado: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}monto_planeado'],
      )!,
      frecuencia: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frecuencia'],
      )!,
      fechaObjetivo: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha_objetivo'],
      )!,
      fechaInicio: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha_inicio'],
      ),
      notas: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notas'],
      ),
      estado: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}estado'],
      )!,
    );
  }

  @override
  $GastosFuturosTable createAlias(String alias) {
    return $GastosFuturosTable(attachedDatabase, alias);
  }
}

class GastosFuturo extends DataClass implements Insertable<GastosFuturo> {
  final int id;
  final String nombre;
  final String categoria;
  final double montoNecesario;
  final double montoPlaneado;
  final String frecuencia;
  final DateTime fechaObjetivo;
  final DateTime? fechaInicio;
  final String? notas;
  final String estado;
  const GastosFuturo({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.montoNecesario,
    required this.montoPlaneado,
    required this.frecuencia,
    required this.fechaObjetivo,
    this.fechaInicio,
    this.notas,
    required this.estado,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['nombre'] = Variable<String>(nombre);
    map['categoria'] = Variable<String>(categoria);
    map['monto_necesario'] = Variable<double>(montoNecesario);
    map['monto_planeado'] = Variable<double>(montoPlaneado);
    map['frecuencia'] = Variable<String>(frecuencia);
    map['fecha_objetivo'] = Variable<DateTime>(fechaObjetivo);
    if (!nullToAbsent || fechaInicio != null) {
      map['fecha_inicio'] = Variable<DateTime>(fechaInicio);
    }
    if (!nullToAbsent || notas != null) {
      map['notas'] = Variable<String>(notas);
    }
    map['estado'] = Variable<String>(estado);
    return map;
  }

  GastosFuturosCompanion toCompanion(bool nullToAbsent) {
    return GastosFuturosCompanion(
      id: Value(id),
      nombre: Value(nombre),
      categoria: Value(categoria),
      montoNecesario: Value(montoNecesario),
      montoPlaneado: Value(montoPlaneado),
      frecuencia: Value(frecuencia),
      fechaObjetivo: Value(fechaObjetivo),
      fechaInicio: fechaInicio == null && nullToAbsent
          ? const Value.absent()
          : Value(fechaInicio),
      notas: notas == null && nullToAbsent
          ? const Value.absent()
          : Value(notas),
      estado: Value(estado),
    );
  }

  factory GastosFuturo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GastosFuturo(
      id: serializer.fromJson<int>(json['id']),
      nombre: serializer.fromJson<String>(json['nombre']),
      categoria: serializer.fromJson<String>(json['categoria']),
      montoNecesario: serializer.fromJson<double>(json['montoNecesario']),
      montoPlaneado: serializer.fromJson<double>(json['montoPlaneado']),
      frecuencia: serializer.fromJson<String>(json['frecuencia']),
      fechaObjetivo: serializer.fromJson<DateTime>(json['fechaObjetivo']),
      fechaInicio: serializer.fromJson<DateTime?>(json['fechaInicio']),
      notas: serializer.fromJson<String?>(json['notas']),
      estado: serializer.fromJson<String>(json['estado']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nombre': serializer.toJson<String>(nombre),
      'categoria': serializer.toJson<String>(categoria),
      'montoNecesario': serializer.toJson<double>(montoNecesario),
      'montoPlaneado': serializer.toJson<double>(montoPlaneado),
      'frecuencia': serializer.toJson<String>(frecuencia),
      'fechaObjetivo': serializer.toJson<DateTime>(fechaObjetivo),
      'fechaInicio': serializer.toJson<DateTime?>(fechaInicio),
      'notas': serializer.toJson<String?>(notas),
      'estado': serializer.toJson<String>(estado),
    };
  }

  GastosFuturo copyWith({
    int? id,
    String? nombre,
    String? categoria,
    double? montoNecesario,
    double? montoPlaneado,
    String? frecuencia,
    DateTime? fechaObjetivo,
    Value<DateTime?> fechaInicio = const Value.absent(),
    Value<String?> notas = const Value.absent(),
    String? estado,
  }) => GastosFuturo(
    id: id ?? this.id,
    nombre: nombre ?? this.nombre,
    categoria: categoria ?? this.categoria,
    montoNecesario: montoNecesario ?? this.montoNecesario,
    montoPlaneado: montoPlaneado ?? this.montoPlaneado,
    frecuencia: frecuencia ?? this.frecuencia,
    fechaObjetivo: fechaObjetivo ?? this.fechaObjetivo,
    fechaInicio: fechaInicio.present ? fechaInicio.value : this.fechaInicio,
    notas: notas.present ? notas.value : this.notas,
    estado: estado ?? this.estado,
  );
  GastosFuturo copyWithCompanion(GastosFuturosCompanion data) {
    return GastosFuturo(
      id: data.id.present ? data.id.value : this.id,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      categoria: data.categoria.present ? data.categoria.value : this.categoria,
      montoNecesario: data.montoNecesario.present
          ? data.montoNecesario.value
          : this.montoNecesario,
      montoPlaneado: data.montoPlaneado.present
          ? data.montoPlaneado.value
          : this.montoPlaneado,
      frecuencia: data.frecuencia.present
          ? data.frecuencia.value
          : this.frecuencia,
      fechaObjetivo: data.fechaObjetivo.present
          ? data.fechaObjetivo.value
          : this.fechaObjetivo,
      fechaInicio: data.fechaInicio.present
          ? data.fechaInicio.value
          : this.fechaInicio,
      notas: data.notas.present ? data.notas.value : this.notas,
      estado: data.estado.present ? data.estado.value : this.estado,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GastosFuturo(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('categoria: $categoria, ')
          ..write('montoNecesario: $montoNecesario, ')
          ..write('montoPlaneado: $montoPlaneado, ')
          ..write('frecuencia: $frecuencia, ')
          ..write('fechaObjetivo: $fechaObjetivo, ')
          ..write('fechaInicio: $fechaInicio, ')
          ..write('notas: $notas, ')
          ..write('estado: $estado')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    nombre,
    categoria,
    montoNecesario,
    montoPlaneado,
    frecuencia,
    fechaObjetivo,
    fechaInicio,
    notas,
    estado,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GastosFuturo &&
          other.id == this.id &&
          other.nombre == this.nombre &&
          other.categoria == this.categoria &&
          other.montoNecesario == this.montoNecesario &&
          other.montoPlaneado == this.montoPlaneado &&
          other.frecuencia == this.frecuencia &&
          other.fechaObjetivo == this.fechaObjetivo &&
          other.fechaInicio == this.fechaInicio &&
          other.notas == this.notas &&
          other.estado == this.estado);
}

class GastosFuturosCompanion extends UpdateCompanion<GastosFuturo> {
  final Value<int> id;
  final Value<String> nombre;
  final Value<String> categoria;
  final Value<double> montoNecesario;
  final Value<double> montoPlaneado;
  final Value<String> frecuencia;
  final Value<DateTime> fechaObjetivo;
  final Value<DateTime?> fechaInicio;
  final Value<String?> notas;
  final Value<String> estado;
  const GastosFuturosCompanion({
    this.id = const Value.absent(),
    this.nombre = const Value.absent(),
    this.categoria = const Value.absent(),
    this.montoNecesario = const Value.absent(),
    this.montoPlaneado = const Value.absent(),
    this.frecuencia = const Value.absent(),
    this.fechaObjetivo = const Value.absent(),
    this.fechaInicio = const Value.absent(),
    this.notas = const Value.absent(),
    this.estado = const Value.absent(),
  });
  GastosFuturosCompanion.insert({
    this.id = const Value.absent(),
    required String nombre,
    required String categoria,
    required double montoNecesario,
    required double montoPlaneado,
    required String frecuencia,
    required DateTime fechaObjetivo,
    this.fechaInicio = const Value.absent(),
    this.notas = const Value.absent(),
    this.estado = const Value.absent(),
  }) : nombre = Value(nombre),
       categoria = Value(categoria),
       montoNecesario = Value(montoNecesario),
       montoPlaneado = Value(montoPlaneado),
       frecuencia = Value(frecuencia),
       fechaObjetivo = Value(fechaObjetivo);
  static Insertable<GastosFuturo> custom({
    Expression<int>? id,
    Expression<String>? nombre,
    Expression<String>? categoria,
    Expression<double>? montoNecesario,
    Expression<double>? montoPlaneado,
    Expression<String>? frecuencia,
    Expression<DateTime>? fechaObjetivo,
    Expression<DateTime>? fechaInicio,
    Expression<String>? notas,
    Expression<String>? estado,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nombre != null) 'nombre': nombre,
      if (categoria != null) 'categoria': categoria,
      if (montoNecesario != null) 'monto_necesario': montoNecesario,
      if (montoPlaneado != null) 'monto_planeado': montoPlaneado,
      if (frecuencia != null) 'frecuencia': frecuencia,
      if (fechaObjetivo != null) 'fecha_objetivo': fechaObjetivo,
      if (fechaInicio != null) 'fecha_inicio': fechaInicio,
      if (notas != null) 'notas': notas,
      if (estado != null) 'estado': estado,
    });
  }

  GastosFuturosCompanion copyWith({
    Value<int>? id,
    Value<String>? nombre,
    Value<String>? categoria,
    Value<double>? montoNecesario,
    Value<double>? montoPlaneado,
    Value<String>? frecuencia,
    Value<DateTime>? fechaObjetivo,
    Value<DateTime?>? fechaInicio,
    Value<String?>? notas,
    Value<String>? estado,
  }) {
    return GastosFuturosCompanion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      categoria: categoria ?? this.categoria,
      montoNecesario: montoNecesario ?? this.montoNecesario,
      montoPlaneado: montoPlaneado ?? this.montoPlaneado,
      frecuencia: frecuencia ?? this.frecuencia,
      fechaObjetivo: fechaObjetivo ?? this.fechaObjetivo,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      notas: notas ?? this.notas,
      estado: estado ?? this.estado,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (categoria.present) {
      map['categoria'] = Variable<String>(categoria.value);
    }
    if (montoNecesario.present) {
      map['monto_necesario'] = Variable<double>(montoNecesario.value);
    }
    if (montoPlaneado.present) {
      map['monto_planeado'] = Variable<double>(montoPlaneado.value);
    }
    if (frecuencia.present) {
      map['frecuencia'] = Variable<String>(frecuencia.value);
    }
    if (fechaObjetivo.present) {
      map['fecha_objetivo'] = Variable<DateTime>(fechaObjetivo.value);
    }
    if (fechaInicio.present) {
      map['fecha_inicio'] = Variable<DateTime>(fechaInicio.value);
    }
    if (notas.present) {
      map['notas'] = Variable<String>(notas.value);
    }
    if (estado.present) {
      map['estado'] = Variable<String>(estado.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GastosFuturosCompanion(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('categoria: $categoria, ')
          ..write('montoNecesario: $montoNecesario, ')
          ..write('montoPlaneado: $montoPlaneado, ')
          ..write('frecuencia: $frecuencia, ')
          ..write('fechaObjetivo: $fechaObjetivo, ')
          ..write('fechaInicio: $fechaInicio, ')
          ..write('notas: $notas, ')
          ..write('estado: $estado')
          ..write(')'))
        .toString();
  }
}

class $MovimientosReservaGastoFuturoTable extends MovimientosReservaGastoFuturo
    with
        TableInfo<
          $MovimientosReservaGastoFuturoTable,
          MovimientosReservaGastoFuturoData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MovimientosReservaGastoFuturoTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _gastoFuturoIdMeta = const VerificationMeta(
    'gastoFuturoId',
  );
  @override
  late final GeneratedColumn<int> gastoFuturoId = GeneratedColumn<int>(
    'gasto_futuro_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES gastos_futuros (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _nombrePlanMeta = const VerificationMeta(
    'nombrePlan',
  );
  @override
  late final GeneratedColumn<String> nombrePlan = GeneratedColumn<String>(
    'nombre_plan',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _montoMeta = const VerificationMeta('monto');
  @override
  late final GeneratedColumn<double> monto = GeneratedColumn<double>(
    'monto',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaMeta = const VerificationMeta('fecha');
  @override
  late final GeneratedColumn<DateTime> fecha = GeneratedColumn<DateTime>(
    'fecha',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationIdMeta = const VerificationMeta(
    'operationId',
  );
  @override
  late final GeneratedColumn<String> operationId = GeneratedColumn<String>(
    'operation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _medioMeta = const VerificationMeta('medio');
  @override
  late final GeneratedColumn<String> medio = GeneratedColumn<String>(
    'medio',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    gastoFuturoId,
    nombrePlan,
    tipo,
    monto,
    fecha,
    operationId,
    medio,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'movimientos_reserva_gasto_futuro';
  @override
  VerificationContext validateIntegrity(
    Insertable<MovimientosReservaGastoFuturoData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('gasto_futuro_id')) {
      context.handle(
        _gastoFuturoIdMeta,
        gastoFuturoId.isAcceptableOrUnknown(
          data['gasto_futuro_id']!,
          _gastoFuturoIdMeta,
        ),
      );
    }
    if (data.containsKey('nombre_plan')) {
      context.handle(
        _nombrePlanMeta,
        nombrePlan.isAcceptableOrUnknown(data['nombre_plan']!, _nombrePlanMeta),
      );
    } else if (isInserting) {
      context.missing(_nombrePlanMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    if (data.containsKey('monto')) {
      context.handle(
        _montoMeta,
        monto.isAcceptableOrUnknown(data['monto']!, _montoMeta),
      );
    } else if (isInserting) {
      context.missing(_montoMeta);
    }
    if (data.containsKey('fecha')) {
      context.handle(
        _fechaMeta,
        fecha.isAcceptableOrUnknown(data['fecha']!, _fechaMeta),
      );
    } else if (isInserting) {
      context.missing(_fechaMeta);
    }
    if (data.containsKey('operation_id')) {
      context.handle(
        _operationIdMeta,
        operationId.isAcceptableOrUnknown(
          data['operation_id']!,
          _operationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationIdMeta);
    }
    if (data.containsKey('medio')) {
      context.handle(
        _medioMeta,
        medio.isAcceptableOrUnknown(data['medio']!, _medioMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MovimientosReservaGastoFuturoData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MovimientosReservaGastoFuturoData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      gastoFuturoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}gasto_futuro_id'],
      ),
      nombrePlan: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre_plan'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      )!,
      monto: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}monto'],
      )!,
      fecha: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha'],
      )!,
      operationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_id'],
      )!,
      medio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medio'],
      ),
    );
  }

  @override
  $MovimientosReservaGastoFuturoTable createAlias(String alias) {
    return $MovimientosReservaGastoFuturoTable(attachedDatabase, alias);
  }
}

class MovimientosReservaGastoFuturoData extends DataClass
    implements Insertable<MovimientosReservaGastoFuturoData> {
  final int id;
  final int? gastoFuturoId;
  final String nombrePlan;
  final String tipo;
  final double monto;
  final DateTime fecha;
  final String operationId;
  final String? medio;
  const MovimientosReservaGastoFuturoData({
    required this.id,
    this.gastoFuturoId,
    required this.nombrePlan,
    required this.tipo,
    required this.monto,
    required this.fecha,
    required this.operationId,
    this.medio,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || gastoFuturoId != null) {
      map['gasto_futuro_id'] = Variable<int>(gastoFuturoId);
    }
    map['nombre_plan'] = Variable<String>(nombrePlan);
    map['tipo'] = Variable<String>(tipo);
    map['monto'] = Variable<double>(monto);
    map['fecha'] = Variable<DateTime>(fecha);
    map['operation_id'] = Variable<String>(operationId);
    if (!nullToAbsent || medio != null) {
      map['medio'] = Variable<String>(medio);
    }
    return map;
  }

  MovimientosReservaGastoFuturoCompanion toCompanion(bool nullToAbsent) {
    return MovimientosReservaGastoFuturoCompanion(
      id: Value(id),
      gastoFuturoId: gastoFuturoId == null && nullToAbsent
          ? const Value.absent()
          : Value(gastoFuturoId),
      nombrePlan: Value(nombrePlan),
      tipo: Value(tipo),
      monto: Value(monto),
      fecha: Value(fecha),
      operationId: Value(operationId),
      medio: medio == null && nullToAbsent
          ? const Value.absent()
          : Value(medio),
    );
  }

  factory MovimientosReservaGastoFuturoData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MovimientosReservaGastoFuturoData(
      id: serializer.fromJson<int>(json['id']),
      gastoFuturoId: serializer.fromJson<int?>(json['gastoFuturoId']),
      nombrePlan: serializer.fromJson<String>(json['nombrePlan']),
      tipo: serializer.fromJson<String>(json['tipo']),
      monto: serializer.fromJson<double>(json['monto']),
      fecha: serializer.fromJson<DateTime>(json['fecha']),
      operationId: serializer.fromJson<String>(json['operationId']),
      medio: serializer.fromJson<String?>(json['medio']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'gastoFuturoId': serializer.toJson<int?>(gastoFuturoId),
      'nombrePlan': serializer.toJson<String>(nombrePlan),
      'tipo': serializer.toJson<String>(tipo),
      'monto': serializer.toJson<double>(monto),
      'fecha': serializer.toJson<DateTime>(fecha),
      'operationId': serializer.toJson<String>(operationId),
      'medio': serializer.toJson<String?>(medio),
    };
  }

  MovimientosReservaGastoFuturoData copyWith({
    int? id,
    Value<int?> gastoFuturoId = const Value.absent(),
    String? nombrePlan,
    String? tipo,
    double? monto,
    DateTime? fecha,
    String? operationId,
    Value<String?> medio = const Value.absent(),
  }) => MovimientosReservaGastoFuturoData(
    id: id ?? this.id,
    gastoFuturoId: gastoFuturoId.present
        ? gastoFuturoId.value
        : this.gastoFuturoId,
    nombrePlan: nombrePlan ?? this.nombrePlan,
    tipo: tipo ?? this.tipo,
    monto: monto ?? this.monto,
    fecha: fecha ?? this.fecha,
    operationId: operationId ?? this.operationId,
    medio: medio.present ? medio.value : this.medio,
  );
  MovimientosReservaGastoFuturoData copyWithCompanion(
    MovimientosReservaGastoFuturoCompanion data,
  ) {
    return MovimientosReservaGastoFuturoData(
      id: data.id.present ? data.id.value : this.id,
      gastoFuturoId: data.gastoFuturoId.present
          ? data.gastoFuturoId.value
          : this.gastoFuturoId,
      nombrePlan: data.nombrePlan.present
          ? data.nombrePlan.value
          : this.nombrePlan,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      monto: data.monto.present ? data.monto.value : this.monto,
      fecha: data.fecha.present ? data.fecha.value : this.fecha,
      operationId: data.operationId.present
          ? data.operationId.value
          : this.operationId,
      medio: data.medio.present ? data.medio.value : this.medio,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MovimientosReservaGastoFuturoData(')
          ..write('id: $id, ')
          ..write('gastoFuturoId: $gastoFuturoId, ')
          ..write('nombrePlan: $nombrePlan, ')
          ..write('tipo: $tipo, ')
          ..write('monto: $monto, ')
          ..write('fecha: $fecha, ')
          ..write('operationId: $operationId, ')
          ..write('medio: $medio')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    gastoFuturoId,
    nombrePlan,
    tipo,
    monto,
    fecha,
    operationId,
    medio,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MovimientosReservaGastoFuturoData &&
          other.id == this.id &&
          other.gastoFuturoId == this.gastoFuturoId &&
          other.nombrePlan == this.nombrePlan &&
          other.tipo == this.tipo &&
          other.monto == this.monto &&
          other.fecha == this.fecha &&
          other.operationId == this.operationId &&
          other.medio == this.medio);
}

class MovimientosReservaGastoFuturoCompanion
    extends UpdateCompanion<MovimientosReservaGastoFuturoData> {
  final Value<int> id;
  final Value<int?> gastoFuturoId;
  final Value<String> nombrePlan;
  final Value<String> tipo;
  final Value<double> monto;
  final Value<DateTime> fecha;
  final Value<String> operationId;
  final Value<String?> medio;
  const MovimientosReservaGastoFuturoCompanion({
    this.id = const Value.absent(),
    this.gastoFuturoId = const Value.absent(),
    this.nombrePlan = const Value.absent(),
    this.tipo = const Value.absent(),
    this.monto = const Value.absent(),
    this.fecha = const Value.absent(),
    this.operationId = const Value.absent(),
    this.medio = const Value.absent(),
  });
  MovimientosReservaGastoFuturoCompanion.insert({
    this.id = const Value.absent(),
    this.gastoFuturoId = const Value.absent(),
    required String nombrePlan,
    required String tipo,
    required double monto,
    required DateTime fecha,
    required String operationId,
    this.medio = const Value.absent(),
  }) : nombrePlan = Value(nombrePlan),
       tipo = Value(tipo),
       monto = Value(monto),
       fecha = Value(fecha),
       operationId = Value(operationId);
  static Insertable<MovimientosReservaGastoFuturoData> custom({
    Expression<int>? id,
    Expression<int>? gastoFuturoId,
    Expression<String>? nombrePlan,
    Expression<String>? tipo,
    Expression<double>? monto,
    Expression<DateTime>? fecha,
    Expression<String>? operationId,
    Expression<String>? medio,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (gastoFuturoId != null) 'gasto_futuro_id': gastoFuturoId,
      if (nombrePlan != null) 'nombre_plan': nombrePlan,
      if (tipo != null) 'tipo': tipo,
      if (monto != null) 'monto': monto,
      if (fecha != null) 'fecha': fecha,
      if (operationId != null) 'operation_id': operationId,
      if (medio != null) 'medio': medio,
    });
  }

  MovimientosReservaGastoFuturoCompanion copyWith({
    Value<int>? id,
    Value<int?>? gastoFuturoId,
    Value<String>? nombrePlan,
    Value<String>? tipo,
    Value<double>? monto,
    Value<DateTime>? fecha,
    Value<String>? operationId,
    Value<String?>? medio,
  }) {
    return MovimientosReservaGastoFuturoCompanion(
      id: id ?? this.id,
      gastoFuturoId: gastoFuturoId ?? this.gastoFuturoId,
      nombrePlan: nombrePlan ?? this.nombrePlan,
      tipo: tipo ?? this.tipo,
      monto: monto ?? this.monto,
      fecha: fecha ?? this.fecha,
      operationId: operationId ?? this.operationId,
      medio: medio ?? this.medio,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (gastoFuturoId.present) {
      map['gasto_futuro_id'] = Variable<int>(gastoFuturoId.value);
    }
    if (nombrePlan.present) {
      map['nombre_plan'] = Variable<String>(nombrePlan.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (monto.present) {
      map['monto'] = Variable<double>(monto.value);
    }
    if (fecha.present) {
      map['fecha'] = Variable<DateTime>(fecha.value);
    }
    if (operationId.present) {
      map['operation_id'] = Variable<String>(operationId.value);
    }
    if (medio.present) {
      map['medio'] = Variable<String>(medio.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MovimientosReservaGastoFuturoCompanion(')
          ..write('id: $id, ')
          ..write('gastoFuturoId: $gastoFuturoId, ')
          ..write('nombrePlan: $nombrePlan, ')
          ..write('tipo: $tipo, ')
          ..write('monto: $monto, ')
          ..write('fecha: $fecha, ')
          ..write('operationId: $operationId, ')
          ..write('medio: $medio')
          ..write(')'))
        .toString();
  }
}

class $AsignacionesDineroTable extends AsignacionesDinero
    with TableInfo<$AsignacionesDineroTable, AsignacionesDineroData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AsignacionesDineroTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _medioMeta = const VerificationMeta('medio');
  @override
  late final GeneratedColumn<String> medio = GeneratedColumn<String>(
    'medio',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _montoMeta = const VerificationMeta('monto');
  @override
  late final GeneratedColumn<double> monto = GeneratedColumn<double>(
    'monto',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cuentaDigitalIdMeta = const VerificationMeta(
    'cuentaDigitalId',
  );
  @override
  late final GeneratedColumn<int> cuentaDigitalId = GeneratedColumn<int>(
    'cuenta_digital_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cuentas_digitales (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _origenMeta = const VerificationMeta('origen');
  @override
  late final GeneratedColumn<String> origen = GeneratedColumn<String>(
    'origen',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _origenIdMeta = const VerificationMeta(
    'origenId',
  );
  @override
  late final GeneratedColumn<int> origenId = GeneratedColumn<int>(
    'origen_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    medio,
    monto,
    cuentaDigitalId,
    origen,
    origenId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'asignaciones_dinero';
  @override
  VerificationContext validateIntegrity(
    Insertable<AsignacionesDineroData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('medio')) {
      context.handle(
        _medioMeta,
        medio.isAcceptableOrUnknown(data['medio']!, _medioMeta),
      );
    } else if (isInserting) {
      context.missing(_medioMeta);
    }
    if (data.containsKey('monto')) {
      context.handle(
        _montoMeta,
        monto.isAcceptableOrUnknown(data['monto']!, _montoMeta),
      );
    } else if (isInserting) {
      context.missing(_montoMeta);
    }
    if (data.containsKey('cuenta_digital_id')) {
      context.handle(
        _cuentaDigitalIdMeta,
        cuentaDigitalId.isAcceptableOrUnknown(
          data['cuenta_digital_id']!,
          _cuentaDigitalIdMeta,
        ),
      );
    }
    if (data.containsKey('origen')) {
      context.handle(
        _origenMeta,
        origen.isAcceptableOrUnknown(data['origen']!, _origenMeta),
      );
    }
    if (data.containsKey('origen_id')) {
      context.handle(
        _origenIdMeta,
        origenId.isAcceptableOrUnknown(data['origen_id']!, _origenIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AsignacionesDineroData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AsignacionesDineroData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      medio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medio'],
      )!,
      monto: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}monto'],
      )!,
      cuentaDigitalId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cuenta_digital_id'],
      ),
      origen: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origen'],
      ),
      origenId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}origen_id'],
      ),
    );
  }

  @override
  $AsignacionesDineroTable createAlias(String alias) {
    return $AsignacionesDineroTable(attachedDatabase, alias);
  }
}

class AsignacionesDineroData extends DataClass
    implements Insertable<AsignacionesDineroData> {
  final int id;
  final String medio;
  final double monto;
  final int? cuentaDigitalId;
  final String? origen;
  final int? origenId;
  const AsignacionesDineroData({
    required this.id,
    required this.medio,
    required this.monto,
    this.cuentaDigitalId,
    this.origen,
    this.origenId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['medio'] = Variable<String>(medio);
    map['monto'] = Variable<double>(monto);
    if (!nullToAbsent || cuentaDigitalId != null) {
      map['cuenta_digital_id'] = Variable<int>(cuentaDigitalId);
    }
    if (!nullToAbsent || origen != null) {
      map['origen'] = Variable<String>(origen);
    }
    if (!nullToAbsent || origenId != null) {
      map['origen_id'] = Variable<int>(origenId);
    }
    return map;
  }

  AsignacionesDineroCompanion toCompanion(bool nullToAbsent) {
    return AsignacionesDineroCompanion(
      id: Value(id),
      medio: Value(medio),
      monto: Value(monto),
      cuentaDigitalId: cuentaDigitalId == null && nullToAbsent
          ? const Value.absent()
          : Value(cuentaDigitalId),
      origen: origen == null && nullToAbsent
          ? const Value.absent()
          : Value(origen),
      origenId: origenId == null && nullToAbsent
          ? const Value.absent()
          : Value(origenId),
    );
  }

  factory AsignacionesDineroData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AsignacionesDineroData(
      id: serializer.fromJson<int>(json['id']),
      medio: serializer.fromJson<String>(json['medio']),
      monto: serializer.fromJson<double>(json['monto']),
      cuentaDigitalId: serializer.fromJson<int?>(json['cuentaDigitalId']),
      origen: serializer.fromJson<String?>(json['origen']),
      origenId: serializer.fromJson<int?>(json['origenId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'medio': serializer.toJson<String>(medio),
      'monto': serializer.toJson<double>(monto),
      'cuentaDigitalId': serializer.toJson<int?>(cuentaDigitalId),
      'origen': serializer.toJson<String?>(origen),
      'origenId': serializer.toJson<int?>(origenId),
    };
  }

  AsignacionesDineroData copyWith({
    int? id,
    String? medio,
    double? monto,
    Value<int?> cuentaDigitalId = const Value.absent(),
    Value<String?> origen = const Value.absent(),
    Value<int?> origenId = const Value.absent(),
  }) => AsignacionesDineroData(
    id: id ?? this.id,
    medio: medio ?? this.medio,
    monto: monto ?? this.monto,
    cuentaDigitalId: cuentaDigitalId.present
        ? cuentaDigitalId.value
        : this.cuentaDigitalId,
    origen: origen.present ? origen.value : this.origen,
    origenId: origenId.present ? origenId.value : this.origenId,
  );
  AsignacionesDineroData copyWithCompanion(AsignacionesDineroCompanion data) {
    return AsignacionesDineroData(
      id: data.id.present ? data.id.value : this.id,
      medio: data.medio.present ? data.medio.value : this.medio,
      monto: data.monto.present ? data.monto.value : this.monto,
      cuentaDigitalId: data.cuentaDigitalId.present
          ? data.cuentaDigitalId.value
          : this.cuentaDigitalId,
      origen: data.origen.present ? data.origen.value : this.origen,
      origenId: data.origenId.present ? data.origenId.value : this.origenId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AsignacionesDineroData(')
          ..write('id: $id, ')
          ..write('medio: $medio, ')
          ..write('monto: $monto, ')
          ..write('cuentaDigitalId: $cuentaDigitalId, ')
          ..write('origen: $origen, ')
          ..write('origenId: $origenId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, medio, monto, cuentaDigitalId, origen, origenId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AsignacionesDineroData &&
          other.id == this.id &&
          other.medio == this.medio &&
          other.monto == this.monto &&
          other.cuentaDigitalId == this.cuentaDigitalId &&
          other.origen == this.origen &&
          other.origenId == this.origenId);
}

class AsignacionesDineroCompanion
    extends UpdateCompanion<AsignacionesDineroData> {
  final Value<int> id;
  final Value<String> medio;
  final Value<double> monto;
  final Value<int?> cuentaDigitalId;
  final Value<String?> origen;
  final Value<int?> origenId;
  const AsignacionesDineroCompanion({
    this.id = const Value.absent(),
    this.medio = const Value.absent(),
    this.monto = const Value.absent(),
    this.cuentaDigitalId = const Value.absent(),
    this.origen = const Value.absent(),
    this.origenId = const Value.absent(),
  });
  AsignacionesDineroCompanion.insert({
    this.id = const Value.absent(),
    required String medio,
    required double monto,
    this.cuentaDigitalId = const Value.absent(),
    this.origen = const Value.absent(),
    this.origenId = const Value.absent(),
  }) : medio = Value(medio),
       monto = Value(monto);
  static Insertable<AsignacionesDineroData> custom({
    Expression<int>? id,
    Expression<String>? medio,
    Expression<double>? monto,
    Expression<int>? cuentaDigitalId,
    Expression<String>? origen,
    Expression<int>? origenId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (medio != null) 'medio': medio,
      if (monto != null) 'monto': monto,
      if (cuentaDigitalId != null) 'cuenta_digital_id': cuentaDigitalId,
      if (origen != null) 'origen': origen,
      if (origenId != null) 'origen_id': origenId,
    });
  }

  AsignacionesDineroCompanion copyWith({
    Value<int>? id,
    Value<String>? medio,
    Value<double>? monto,
    Value<int?>? cuentaDigitalId,
    Value<String?>? origen,
    Value<int?>? origenId,
  }) {
    return AsignacionesDineroCompanion(
      id: id ?? this.id,
      medio: medio ?? this.medio,
      monto: monto ?? this.monto,
      cuentaDigitalId: cuentaDigitalId ?? this.cuentaDigitalId,
      origen: origen ?? this.origen,
      origenId: origenId ?? this.origenId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (medio.present) {
      map['medio'] = Variable<String>(medio.value);
    }
    if (monto.present) {
      map['monto'] = Variable<double>(monto.value);
    }
    if (cuentaDigitalId.present) {
      map['cuenta_digital_id'] = Variable<int>(cuentaDigitalId.value);
    }
    if (origen.present) {
      map['origen'] = Variable<String>(origen.value);
    }
    if (origenId.present) {
      map['origen_id'] = Variable<int>(origenId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AsignacionesDineroCompanion(')
          ..write('id: $id, ')
          ..write('medio: $medio, ')
          ..write('monto: $monto, ')
          ..write('cuentaDigitalId: $cuentaDigitalId, ')
          ..write('origen: $origen, ')
          ..write('origenId: $origenId')
          ..write(')'))
        .toString();
  }
}

class $IngresoDistribucionesTable extends IngresoDistribuciones
    with TableInfo<$IngresoDistribucionesTable, IngresoDistribucione> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IngresoDistribucionesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _ingresoIdMeta = const VerificationMeta(
    'ingresoId',
  );
  @override
  late final GeneratedColumn<int> ingresoId = GeneratedColumn<int>(
    'ingreso_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ingresos (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _medioMeta = const VerificationMeta('medio');
  @override
  late final GeneratedColumn<String> medio = GeneratedColumn<String>(
    'medio',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _montoMeta = const VerificationMeta('monto');
  @override
  late final GeneratedColumn<double> monto = GeneratedColumn<double>(
    'monto',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cuentaDigitalIdMeta = const VerificationMeta(
    'cuentaDigitalId',
  );
  @override
  late final GeneratedColumn<int> cuentaDigitalId = GeneratedColumn<int>(
    'cuenta_digital_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cuentas_digitales (id) ON DELETE SET NULL',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ingresoId,
    medio,
    monto,
    cuentaDigitalId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ingreso_distribuciones';
  @override
  VerificationContext validateIntegrity(
    Insertable<IngresoDistribucione> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('ingreso_id')) {
      context.handle(
        _ingresoIdMeta,
        ingresoId.isAcceptableOrUnknown(data['ingreso_id']!, _ingresoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ingresoIdMeta);
    }
    if (data.containsKey('medio')) {
      context.handle(
        _medioMeta,
        medio.isAcceptableOrUnknown(data['medio']!, _medioMeta),
      );
    } else if (isInserting) {
      context.missing(_medioMeta);
    }
    if (data.containsKey('monto')) {
      context.handle(
        _montoMeta,
        monto.isAcceptableOrUnknown(data['monto']!, _montoMeta),
      );
    } else if (isInserting) {
      context.missing(_montoMeta);
    }
    if (data.containsKey('cuenta_digital_id')) {
      context.handle(
        _cuentaDigitalIdMeta,
        cuentaDigitalId.isAcceptableOrUnknown(
          data['cuenta_digital_id']!,
          _cuentaDigitalIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IngresoDistribucione map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IngresoDistribucione(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      ingresoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ingreso_id'],
      )!,
      medio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medio'],
      )!,
      monto: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}monto'],
      )!,
      cuentaDigitalId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cuenta_digital_id'],
      ),
    );
  }

  @override
  $IngresoDistribucionesTable createAlias(String alias) {
    return $IngresoDistribucionesTable(attachedDatabase, alias);
  }
}

class IngresoDistribucione extends DataClass
    implements Insertable<IngresoDistribucione> {
  final int id;
  final int ingresoId;
  final String medio;
  final double monto;
  final int? cuentaDigitalId;
  const IngresoDistribucione({
    required this.id,
    required this.ingresoId,
    required this.medio,
    required this.monto,
    this.cuentaDigitalId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['ingreso_id'] = Variable<int>(ingresoId);
    map['medio'] = Variable<String>(medio);
    map['monto'] = Variable<double>(monto);
    if (!nullToAbsent || cuentaDigitalId != null) {
      map['cuenta_digital_id'] = Variable<int>(cuentaDigitalId);
    }
    return map;
  }

  IngresoDistribucionesCompanion toCompanion(bool nullToAbsent) {
    return IngresoDistribucionesCompanion(
      id: Value(id),
      ingresoId: Value(ingresoId),
      medio: Value(medio),
      monto: Value(monto),
      cuentaDigitalId: cuentaDigitalId == null && nullToAbsent
          ? const Value.absent()
          : Value(cuentaDigitalId),
    );
  }

  factory IngresoDistribucione.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IngresoDistribucione(
      id: serializer.fromJson<int>(json['id']),
      ingresoId: serializer.fromJson<int>(json['ingresoId']),
      medio: serializer.fromJson<String>(json['medio']),
      monto: serializer.fromJson<double>(json['monto']),
      cuentaDigitalId: serializer.fromJson<int?>(json['cuentaDigitalId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ingresoId': serializer.toJson<int>(ingresoId),
      'medio': serializer.toJson<String>(medio),
      'monto': serializer.toJson<double>(monto),
      'cuentaDigitalId': serializer.toJson<int?>(cuentaDigitalId),
    };
  }

  IngresoDistribucione copyWith({
    int? id,
    int? ingresoId,
    String? medio,
    double? monto,
    Value<int?> cuentaDigitalId = const Value.absent(),
  }) => IngresoDistribucione(
    id: id ?? this.id,
    ingresoId: ingresoId ?? this.ingresoId,
    medio: medio ?? this.medio,
    monto: monto ?? this.monto,
    cuentaDigitalId: cuentaDigitalId.present
        ? cuentaDigitalId.value
        : this.cuentaDigitalId,
  );
  IngresoDistribucione copyWithCompanion(IngresoDistribucionesCompanion data) {
    return IngresoDistribucione(
      id: data.id.present ? data.id.value : this.id,
      ingresoId: data.ingresoId.present ? data.ingresoId.value : this.ingresoId,
      medio: data.medio.present ? data.medio.value : this.medio,
      monto: data.monto.present ? data.monto.value : this.monto,
      cuentaDigitalId: data.cuentaDigitalId.present
          ? data.cuentaDigitalId.value
          : this.cuentaDigitalId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IngresoDistribucione(')
          ..write('id: $id, ')
          ..write('ingresoId: $ingresoId, ')
          ..write('medio: $medio, ')
          ..write('monto: $monto, ')
          ..write('cuentaDigitalId: $cuentaDigitalId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, ingresoId, medio, monto, cuentaDigitalId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IngresoDistribucione &&
          other.id == this.id &&
          other.ingresoId == this.ingresoId &&
          other.medio == this.medio &&
          other.monto == this.monto &&
          other.cuentaDigitalId == this.cuentaDigitalId);
}

class IngresoDistribucionesCompanion
    extends UpdateCompanion<IngresoDistribucione> {
  final Value<int> id;
  final Value<int> ingresoId;
  final Value<String> medio;
  final Value<double> monto;
  final Value<int?> cuentaDigitalId;
  const IngresoDistribucionesCompanion({
    this.id = const Value.absent(),
    this.ingresoId = const Value.absent(),
    this.medio = const Value.absent(),
    this.monto = const Value.absent(),
    this.cuentaDigitalId = const Value.absent(),
  });
  IngresoDistribucionesCompanion.insert({
    this.id = const Value.absent(),
    required int ingresoId,
    required String medio,
    required double monto,
    this.cuentaDigitalId = const Value.absent(),
  }) : ingresoId = Value(ingresoId),
       medio = Value(medio),
       monto = Value(monto);
  static Insertable<IngresoDistribucione> custom({
    Expression<int>? id,
    Expression<int>? ingresoId,
    Expression<String>? medio,
    Expression<double>? monto,
    Expression<int>? cuentaDigitalId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ingresoId != null) 'ingreso_id': ingresoId,
      if (medio != null) 'medio': medio,
      if (monto != null) 'monto': monto,
      if (cuentaDigitalId != null) 'cuenta_digital_id': cuentaDigitalId,
    });
  }

  IngresoDistribucionesCompanion copyWith({
    Value<int>? id,
    Value<int>? ingresoId,
    Value<String>? medio,
    Value<double>? monto,
    Value<int?>? cuentaDigitalId,
  }) {
    return IngresoDistribucionesCompanion(
      id: id ?? this.id,
      ingresoId: ingresoId ?? this.ingresoId,
      medio: medio ?? this.medio,
      monto: monto ?? this.monto,
      cuentaDigitalId: cuentaDigitalId ?? this.cuentaDigitalId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ingresoId.present) {
      map['ingreso_id'] = Variable<int>(ingresoId.value);
    }
    if (medio.present) {
      map['medio'] = Variable<String>(medio.value);
    }
    if (monto.present) {
      map['monto'] = Variable<double>(monto.value);
    }
    if (cuentaDigitalId.present) {
      map['cuenta_digital_id'] = Variable<int>(cuentaDigitalId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IngresoDistribucionesCompanion(')
          ..write('id: $id, ')
          ..write('ingresoId: $ingresoId, ')
          ..write('medio: $medio, ')
          ..write('monto: $monto, ')
          ..write('cuentaDigitalId: $cuentaDigitalId')
          ..write(')'))
        .toString();
  }
}

class $TransferenciasDineroTable extends TransferenciasDinero
    with TableInfo<$TransferenciasDineroTable, TransferenciasDineroData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransferenciasDineroTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _medioOrigenMeta = const VerificationMeta(
    'medioOrigen',
  );
  @override
  late final GeneratedColumn<String> medioOrigen = GeneratedColumn<String>(
    'medio_origen',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cuentaOrigenIdMeta = const VerificationMeta(
    'cuentaOrigenId',
  );
  @override
  late final GeneratedColumn<int> cuentaOrigenId = GeneratedColumn<int>(
    'cuenta_origen_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cuentas_digitales (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _medioDestinoMeta = const VerificationMeta(
    'medioDestino',
  );
  @override
  late final GeneratedColumn<String> medioDestino = GeneratedColumn<String>(
    'medio_destino',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cuentaDestinoIdMeta = const VerificationMeta(
    'cuentaDestinoId',
  );
  @override
  late final GeneratedColumn<int> cuentaDestinoId = GeneratedColumn<int>(
    'cuenta_destino_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cuentas_digitales (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _montoMeta = const VerificationMeta('monto');
  @override
  late final GeneratedColumn<double> monto = GeneratedColumn<double>(
    'monto',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaMeta = const VerificationMeta('fecha');
  @override
  late final GeneratedColumn<DateTime> fecha = GeneratedColumn<DateTime>(
    'fecha',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notaMeta = const VerificationMeta('nota');
  @override
  late final GeneratedColumn<String> nota = GeneratedColumn<String>(
    'nota',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    medioOrigen,
    cuentaOrigenId,
    medioDestino,
    cuentaDestinoId,
    monto,
    fecha,
    nota,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transferencias_dinero';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransferenciasDineroData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('medio_origen')) {
      context.handle(
        _medioOrigenMeta,
        medioOrigen.isAcceptableOrUnknown(
          data['medio_origen']!,
          _medioOrigenMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_medioOrigenMeta);
    }
    if (data.containsKey('cuenta_origen_id')) {
      context.handle(
        _cuentaOrigenIdMeta,
        cuentaOrigenId.isAcceptableOrUnknown(
          data['cuenta_origen_id']!,
          _cuentaOrigenIdMeta,
        ),
      );
    }
    if (data.containsKey('medio_destino')) {
      context.handle(
        _medioDestinoMeta,
        medioDestino.isAcceptableOrUnknown(
          data['medio_destino']!,
          _medioDestinoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_medioDestinoMeta);
    }
    if (data.containsKey('cuenta_destino_id')) {
      context.handle(
        _cuentaDestinoIdMeta,
        cuentaDestinoId.isAcceptableOrUnknown(
          data['cuenta_destino_id']!,
          _cuentaDestinoIdMeta,
        ),
      );
    }
    if (data.containsKey('monto')) {
      context.handle(
        _montoMeta,
        monto.isAcceptableOrUnknown(data['monto']!, _montoMeta),
      );
    } else if (isInserting) {
      context.missing(_montoMeta);
    }
    if (data.containsKey('fecha')) {
      context.handle(
        _fechaMeta,
        fecha.isAcceptableOrUnknown(data['fecha']!, _fechaMeta),
      );
    } else if (isInserting) {
      context.missing(_fechaMeta);
    }
    if (data.containsKey('nota')) {
      context.handle(
        _notaMeta,
        nota.isAcceptableOrUnknown(data['nota']!, _notaMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransferenciasDineroData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransferenciasDineroData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      medioOrigen: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medio_origen'],
      )!,
      cuentaOrigenId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cuenta_origen_id'],
      ),
      medioDestino: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medio_destino'],
      )!,
      cuentaDestinoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cuenta_destino_id'],
      ),
      monto: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}monto'],
      )!,
      fecha: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha'],
      )!,
      nota: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nota'],
      ),
    );
  }

  @override
  $TransferenciasDineroTable createAlias(String alias) {
    return $TransferenciasDineroTable(attachedDatabase, alias);
  }
}

class TransferenciasDineroData extends DataClass
    implements Insertable<TransferenciasDineroData> {
  final int id;
  final String medioOrigen;
  final int? cuentaOrigenId;
  final String medioDestino;
  final int? cuentaDestinoId;
  final double monto;
  final DateTime fecha;
  final String? nota;
  const TransferenciasDineroData({
    required this.id,
    required this.medioOrigen,
    this.cuentaOrigenId,
    required this.medioDestino,
    this.cuentaDestinoId,
    required this.monto,
    required this.fecha,
    this.nota,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['medio_origen'] = Variable<String>(medioOrigen);
    if (!nullToAbsent || cuentaOrigenId != null) {
      map['cuenta_origen_id'] = Variable<int>(cuentaOrigenId);
    }
    map['medio_destino'] = Variable<String>(medioDestino);
    if (!nullToAbsent || cuentaDestinoId != null) {
      map['cuenta_destino_id'] = Variable<int>(cuentaDestinoId);
    }
    map['monto'] = Variable<double>(monto);
    map['fecha'] = Variable<DateTime>(fecha);
    if (!nullToAbsent || nota != null) {
      map['nota'] = Variable<String>(nota);
    }
    return map;
  }

  TransferenciasDineroCompanion toCompanion(bool nullToAbsent) {
    return TransferenciasDineroCompanion(
      id: Value(id),
      medioOrigen: Value(medioOrigen),
      cuentaOrigenId: cuentaOrigenId == null && nullToAbsent
          ? const Value.absent()
          : Value(cuentaOrigenId),
      medioDestino: Value(medioDestino),
      cuentaDestinoId: cuentaDestinoId == null && nullToAbsent
          ? const Value.absent()
          : Value(cuentaDestinoId),
      monto: Value(monto),
      fecha: Value(fecha),
      nota: nota == null && nullToAbsent ? const Value.absent() : Value(nota),
    );
  }

  factory TransferenciasDineroData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransferenciasDineroData(
      id: serializer.fromJson<int>(json['id']),
      medioOrigen: serializer.fromJson<String>(json['medioOrigen']),
      cuentaOrigenId: serializer.fromJson<int?>(json['cuentaOrigenId']),
      medioDestino: serializer.fromJson<String>(json['medioDestino']),
      cuentaDestinoId: serializer.fromJson<int?>(json['cuentaDestinoId']),
      monto: serializer.fromJson<double>(json['monto']),
      fecha: serializer.fromJson<DateTime>(json['fecha']),
      nota: serializer.fromJson<String?>(json['nota']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'medioOrigen': serializer.toJson<String>(medioOrigen),
      'cuentaOrigenId': serializer.toJson<int?>(cuentaOrigenId),
      'medioDestino': serializer.toJson<String>(medioDestino),
      'cuentaDestinoId': serializer.toJson<int?>(cuentaDestinoId),
      'monto': serializer.toJson<double>(monto),
      'fecha': serializer.toJson<DateTime>(fecha),
      'nota': serializer.toJson<String?>(nota),
    };
  }

  TransferenciasDineroData copyWith({
    int? id,
    String? medioOrigen,
    Value<int?> cuentaOrigenId = const Value.absent(),
    String? medioDestino,
    Value<int?> cuentaDestinoId = const Value.absent(),
    double? monto,
    DateTime? fecha,
    Value<String?> nota = const Value.absent(),
  }) => TransferenciasDineroData(
    id: id ?? this.id,
    medioOrigen: medioOrigen ?? this.medioOrigen,
    cuentaOrigenId: cuentaOrigenId.present
        ? cuentaOrigenId.value
        : this.cuentaOrigenId,
    medioDestino: medioDestino ?? this.medioDestino,
    cuentaDestinoId: cuentaDestinoId.present
        ? cuentaDestinoId.value
        : this.cuentaDestinoId,
    monto: monto ?? this.monto,
    fecha: fecha ?? this.fecha,
    nota: nota.present ? nota.value : this.nota,
  );
  TransferenciasDineroData copyWithCompanion(
    TransferenciasDineroCompanion data,
  ) {
    return TransferenciasDineroData(
      id: data.id.present ? data.id.value : this.id,
      medioOrigen: data.medioOrigen.present
          ? data.medioOrigen.value
          : this.medioOrigen,
      cuentaOrigenId: data.cuentaOrigenId.present
          ? data.cuentaOrigenId.value
          : this.cuentaOrigenId,
      medioDestino: data.medioDestino.present
          ? data.medioDestino.value
          : this.medioDestino,
      cuentaDestinoId: data.cuentaDestinoId.present
          ? data.cuentaDestinoId.value
          : this.cuentaDestinoId,
      monto: data.monto.present ? data.monto.value : this.monto,
      fecha: data.fecha.present ? data.fecha.value : this.fecha,
      nota: data.nota.present ? data.nota.value : this.nota,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransferenciasDineroData(')
          ..write('id: $id, ')
          ..write('medioOrigen: $medioOrigen, ')
          ..write('cuentaOrigenId: $cuentaOrigenId, ')
          ..write('medioDestino: $medioDestino, ')
          ..write('cuentaDestinoId: $cuentaDestinoId, ')
          ..write('monto: $monto, ')
          ..write('fecha: $fecha, ')
          ..write('nota: $nota')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    medioOrigen,
    cuentaOrigenId,
    medioDestino,
    cuentaDestinoId,
    monto,
    fecha,
    nota,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransferenciasDineroData &&
          other.id == this.id &&
          other.medioOrigen == this.medioOrigen &&
          other.cuentaOrigenId == this.cuentaOrigenId &&
          other.medioDestino == this.medioDestino &&
          other.cuentaDestinoId == this.cuentaDestinoId &&
          other.monto == this.monto &&
          other.fecha == this.fecha &&
          other.nota == this.nota);
}

class TransferenciasDineroCompanion
    extends UpdateCompanion<TransferenciasDineroData> {
  final Value<int> id;
  final Value<String> medioOrigen;
  final Value<int?> cuentaOrigenId;
  final Value<String> medioDestino;
  final Value<int?> cuentaDestinoId;
  final Value<double> monto;
  final Value<DateTime> fecha;
  final Value<String?> nota;
  const TransferenciasDineroCompanion({
    this.id = const Value.absent(),
    this.medioOrigen = const Value.absent(),
    this.cuentaOrigenId = const Value.absent(),
    this.medioDestino = const Value.absent(),
    this.cuentaDestinoId = const Value.absent(),
    this.monto = const Value.absent(),
    this.fecha = const Value.absent(),
    this.nota = const Value.absent(),
  });
  TransferenciasDineroCompanion.insert({
    this.id = const Value.absent(),
    required String medioOrigen,
    this.cuentaOrigenId = const Value.absent(),
    required String medioDestino,
    this.cuentaDestinoId = const Value.absent(),
    required double monto,
    required DateTime fecha,
    this.nota = const Value.absent(),
  }) : medioOrigen = Value(medioOrigen),
       medioDestino = Value(medioDestino),
       monto = Value(monto),
       fecha = Value(fecha);
  static Insertable<TransferenciasDineroData> custom({
    Expression<int>? id,
    Expression<String>? medioOrigen,
    Expression<int>? cuentaOrigenId,
    Expression<String>? medioDestino,
    Expression<int>? cuentaDestinoId,
    Expression<double>? monto,
    Expression<DateTime>? fecha,
    Expression<String>? nota,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (medioOrigen != null) 'medio_origen': medioOrigen,
      if (cuentaOrigenId != null) 'cuenta_origen_id': cuentaOrigenId,
      if (medioDestino != null) 'medio_destino': medioDestino,
      if (cuentaDestinoId != null) 'cuenta_destino_id': cuentaDestinoId,
      if (monto != null) 'monto': monto,
      if (fecha != null) 'fecha': fecha,
      if (nota != null) 'nota': nota,
    });
  }

  TransferenciasDineroCompanion copyWith({
    Value<int>? id,
    Value<String>? medioOrigen,
    Value<int?>? cuentaOrigenId,
    Value<String>? medioDestino,
    Value<int?>? cuentaDestinoId,
    Value<double>? monto,
    Value<DateTime>? fecha,
    Value<String?>? nota,
  }) {
    return TransferenciasDineroCompanion(
      id: id ?? this.id,
      medioOrigen: medioOrigen ?? this.medioOrigen,
      cuentaOrigenId: cuentaOrigenId ?? this.cuentaOrigenId,
      medioDestino: medioDestino ?? this.medioDestino,
      cuentaDestinoId: cuentaDestinoId ?? this.cuentaDestinoId,
      monto: monto ?? this.monto,
      fecha: fecha ?? this.fecha,
      nota: nota ?? this.nota,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (medioOrigen.present) {
      map['medio_origen'] = Variable<String>(medioOrigen.value);
    }
    if (cuentaOrigenId.present) {
      map['cuenta_origen_id'] = Variable<int>(cuentaOrigenId.value);
    }
    if (medioDestino.present) {
      map['medio_destino'] = Variable<String>(medioDestino.value);
    }
    if (cuentaDestinoId.present) {
      map['cuenta_destino_id'] = Variable<int>(cuentaDestinoId.value);
    }
    if (monto.present) {
      map['monto'] = Variable<double>(monto.value);
    }
    if (fecha.present) {
      map['fecha'] = Variable<DateTime>(fecha.value);
    }
    if (nota.present) {
      map['nota'] = Variable<String>(nota.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransferenciasDineroCompanion(')
          ..write('id: $id, ')
          ..write('medioOrigen: $medioOrigen, ')
          ..write('cuentaOrigenId: $cuentaOrigenId, ')
          ..write('medioDestino: $medioDestino, ')
          ..write('cuentaDestinoId: $cuentaDestinoId, ')
          ..write('monto: $monto, ')
          ..write('fecha: $fecha, ')
          ..write('nota: $nota')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CuentasDigitalesTable cuentasDigitales = $CuentasDigitalesTable(
    this,
  );
  late final $IngresosTable ingresos = $IngresosTable(this);
  late final $SuscripcionesTable suscripciones = $SuscripcionesTable(this);
  late final $GastosTable gastos = $GastosTable(this);
  late final $DeudasTable deudas = $DeudasTable(this);
  late final $PagosDeudaTable pagosDeuda = $PagosDeudaTable(this);
  late final $MovimientosAhorroTable movimientosAhorro =
      $MovimientosAhorroTable(this);
  late final $PrestamosTercerosTable prestamosTerceros =
      $PrestamosTercerosTable(this);
  late final $MovimientosPrestamoTable movimientosPrestamo =
      $MovimientosPrestamoTable(this);
  late final $GastosFuturosTable gastosFuturos = $GastosFuturosTable(this);
  late final $MovimientosReservaGastoFuturoTable movimientosReservaGastoFuturo =
      $MovimientosReservaGastoFuturoTable(this);
  late final $AsignacionesDineroTable asignacionesDinero =
      $AsignacionesDineroTable(this);
  late final $IngresoDistribucionesTable ingresoDistribuciones =
      $IngresoDistribucionesTable(this);
  late final $TransferenciasDineroTable transferenciasDinero =
      $TransferenciasDineroTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cuentasDigitales,
    ingresos,
    suscripciones,
    gastos,
    deudas,
    pagosDeuda,
    movimientosAhorro,
    prestamosTerceros,
    movimientosPrestamo,
    gastosFuturos,
    movimientosReservaGastoFuturo,
    asignacionesDinero,
    ingresoDistribuciones,
    transferenciasDinero,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'cuentas_digitales',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('ingresos', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'cuentas_digitales',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('suscripciones', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'cuentas_digitales',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('gastos', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'suscripciones',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('gastos', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'ingresos',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('deudas', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'deudas',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('pagos_deuda', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'prestamos_terceros',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('movimientos_prestamo', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'gastos_futuros',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate(
          'movimientos_reserva_gasto_futuro',
          kind: UpdateKind.update,
        ),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'cuentas_digitales',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('asignaciones_dinero', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'ingresos',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('ingreso_distribuciones', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'cuentas_digitales',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('ingreso_distribuciones', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'cuentas_digitales',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('transferencias_dinero', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'cuentas_digitales',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('transferencias_dinero', kind: UpdateKind.update)],
    ),
  ]);
}

typedef $$CuentasDigitalesTableCreateCompanionBuilder =
    CuentasDigitalesCompanion Function({Value<int> id, required String nombre});
typedef $$CuentasDigitalesTableUpdateCompanionBuilder =
    CuentasDigitalesCompanion Function({Value<int> id, Value<String> nombre});

final class $$CuentasDigitalesTableReferences
    extends
        BaseReferences<_$AppDatabase, $CuentasDigitalesTable, CuentasDigitale> {
  $$CuentasDigitalesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$IngresosTable, List<Ingreso>> _ingresosRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.ingresos,
    aliasName: 'cuentas_digitales__id__ingresos__cuenta_digital_id',
  );

  $$IngresosTableProcessedTableManager get ingresosRefs {
    final manager = $$IngresosTableTableManager(
      $_db,
      $_db.ingresos,
    ).filter((f) => f.cuentaDigitalId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_ingresosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SuscripcionesTable, List<Suscripcion>>
  _suscripcionesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.suscripciones,
    aliasName: 'cuentas_digitales__id__suscripciones__cuenta_digital_id',
  );

  $$SuscripcionesTableProcessedTableManager get suscripcionesRefs {
    final manager = $$SuscripcionesTableTableManager(
      $_db,
      $_db.suscripciones,
    ).filter((f) => f.cuentaDigitalId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_suscripcionesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$GastosTable, List<Gasto>> _gastosRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.gastos,
    aliasName: 'cuentas_digitales__id__gastos__cuenta_digital_id',
  );

  $$GastosTableProcessedTableManager get gastosRefs {
    final manager = $$GastosTableTableManager(
      $_db,
      $_db.gastos,
    ).filter((f) => f.cuentaDigitalId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_gastosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $AsignacionesDineroTable,
    List<AsignacionesDineroData>
  >
  _asignacionesDineroRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.asignacionesDinero,
        aliasName:
            'cuentas_digitales__id__asignaciones_dinero__cuenta_digital_id',
      );

  $$AsignacionesDineroTableProcessedTableManager get asignacionesDineroRefs {
    final manager = $$AsignacionesDineroTableTableManager(
      $_db,
      $_db.asignacionesDinero,
    ).filter((f) => f.cuentaDigitalId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _asignacionesDineroRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $IngresoDistribucionesTable,
    List<IngresoDistribucione>
  >
  _ingresoDistribucionesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.ingresoDistribuciones,
        aliasName:
            'cuentas_digitales__id__ingreso_distribuciones__cuenta_digital_id',
      );

  $$IngresoDistribucionesTableProcessedTableManager
  get ingresoDistribucionesRefs {
    final manager = $$IngresoDistribucionesTableTableManager(
      $_db,
      $_db.ingresoDistribuciones,
    ).filter((f) => f.cuentaDigitalId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _ingresoDistribucionesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $TransferenciasDineroTable,
    List<TransferenciasDineroData>
  >
  _sourceTransfersTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transferenciasDinero,
    aliasName: 'cuentas_digitales__id__transferencias_dinero__cuenta_origen_id',
  );

  $$TransferenciasDineroTableProcessedTableManager get sourceTransfers {
    final manager = $$TransferenciasDineroTableTableManager(
      $_db,
      $_db.transferenciasDinero,
    ).filter((f) => f.cuentaOrigenId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_sourceTransfersTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $TransferenciasDineroTable,
    List<TransferenciasDineroData>
  >
  _destinationTransfersTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transferenciasDinero,
    aliasName:
        'cuentas_digitales__id__transferencias_dinero__cuenta_destino_id',
  );

  $$TransferenciasDineroTableProcessedTableManager get destinationTransfers {
    final manager = $$TransferenciasDineroTableTableManager(
      $_db,
      $_db.transferenciasDinero,
    ).filter((f) => f.cuentaDestinoId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _destinationTransfersTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CuentasDigitalesTableFilterComposer
    extends Composer<_$AppDatabase, $CuentasDigitalesTable> {
  $$CuentasDigitalesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> ingresosRefs(
    Expression<bool> Function($$IngresosTableFilterComposer f) f,
  ) {
    final $$IngresosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ingresos,
      getReferencedColumn: (t) => t.cuentaDigitalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IngresosTableFilterComposer(
            $db: $db,
            $table: $db.ingresos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> suscripcionesRefs(
    Expression<bool> Function($$SuscripcionesTableFilterComposer f) f,
  ) {
    final $$SuscripcionesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.suscripciones,
      getReferencedColumn: (t) => t.cuentaDigitalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SuscripcionesTableFilterComposer(
            $db: $db,
            $table: $db.suscripciones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> gastosRefs(
    Expression<bool> Function($$GastosTableFilterComposer f) f,
  ) {
    final $$GastosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.gastos,
      getReferencedColumn: (t) => t.cuentaDigitalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GastosTableFilterComposer(
            $db: $db,
            $table: $db.gastos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> asignacionesDineroRefs(
    Expression<bool> Function($$AsignacionesDineroTableFilterComposer f) f,
  ) {
    final $$AsignacionesDineroTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.asignacionesDinero,
      getReferencedColumn: (t) => t.cuentaDigitalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AsignacionesDineroTableFilterComposer(
            $db: $db,
            $table: $db.asignacionesDinero,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> ingresoDistribucionesRefs(
    Expression<bool> Function($$IngresoDistribucionesTableFilterComposer f) f,
  ) {
    final $$IngresoDistribucionesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.ingresoDistribuciones,
          getReferencedColumn: (t) => t.cuentaDigitalId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$IngresoDistribucionesTableFilterComposer(
                $db: $db,
                $table: $db.ingresoDistribuciones,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> sourceTransfers(
    Expression<bool> Function($$TransferenciasDineroTableFilterComposer f) f,
  ) {
    final $$TransferenciasDineroTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transferenciasDinero,
      getReferencedColumn: (t) => t.cuentaOrigenId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransferenciasDineroTableFilterComposer(
            $db: $db,
            $table: $db.transferenciasDinero,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> destinationTransfers(
    Expression<bool> Function($$TransferenciasDineroTableFilterComposer f) f,
  ) {
    final $$TransferenciasDineroTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transferenciasDinero,
      getReferencedColumn: (t) => t.cuentaDestinoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransferenciasDineroTableFilterComposer(
            $db: $db,
            $table: $db.transferenciasDinero,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CuentasDigitalesTableOrderingComposer
    extends Composer<_$AppDatabase, $CuentasDigitalesTable> {
  $$CuentasDigitalesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CuentasDigitalesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CuentasDigitalesTable> {
  $$CuentasDigitalesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  Expression<T> ingresosRefs<T extends Object>(
    Expression<T> Function($$IngresosTableAnnotationComposer a) f,
  ) {
    final $$IngresosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ingresos,
      getReferencedColumn: (t) => t.cuentaDigitalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IngresosTableAnnotationComposer(
            $db: $db,
            $table: $db.ingresos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> suscripcionesRefs<T extends Object>(
    Expression<T> Function($$SuscripcionesTableAnnotationComposer a) f,
  ) {
    final $$SuscripcionesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.suscripciones,
      getReferencedColumn: (t) => t.cuentaDigitalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SuscripcionesTableAnnotationComposer(
            $db: $db,
            $table: $db.suscripciones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> gastosRefs<T extends Object>(
    Expression<T> Function($$GastosTableAnnotationComposer a) f,
  ) {
    final $$GastosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.gastos,
      getReferencedColumn: (t) => t.cuentaDigitalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GastosTableAnnotationComposer(
            $db: $db,
            $table: $db.gastos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> asignacionesDineroRefs<T extends Object>(
    Expression<T> Function($$AsignacionesDineroTableAnnotationComposer a) f,
  ) {
    final $$AsignacionesDineroTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.asignacionesDinero,
          getReferencedColumn: (t) => t.cuentaDigitalId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AsignacionesDineroTableAnnotationComposer(
                $db: $db,
                $table: $db.asignacionesDinero,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> ingresoDistribucionesRefs<T extends Object>(
    Expression<T> Function($$IngresoDistribucionesTableAnnotationComposer a) f,
  ) {
    final $$IngresoDistribucionesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.ingresoDistribuciones,
          getReferencedColumn: (t) => t.cuentaDigitalId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$IngresoDistribucionesTableAnnotationComposer(
                $db: $db,
                $table: $db.ingresoDistribuciones,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> sourceTransfers<T extends Object>(
    Expression<T> Function($$TransferenciasDineroTableAnnotationComposer a) f,
  ) {
    final $$TransferenciasDineroTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.transferenciasDinero,
          getReferencedColumn: (t) => t.cuentaOrigenId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TransferenciasDineroTableAnnotationComposer(
                $db: $db,
                $table: $db.transferenciasDinero,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> destinationTransfers<T extends Object>(
    Expression<T> Function($$TransferenciasDineroTableAnnotationComposer a) f,
  ) {
    final $$TransferenciasDineroTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.transferenciasDinero,
          getReferencedColumn: (t) => t.cuentaDestinoId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TransferenciasDineroTableAnnotationComposer(
                $db: $db,
                $table: $db.transferenciasDinero,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CuentasDigitalesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CuentasDigitalesTable,
          CuentasDigitale,
          $$CuentasDigitalesTableFilterComposer,
          $$CuentasDigitalesTableOrderingComposer,
          $$CuentasDigitalesTableAnnotationComposer,
          $$CuentasDigitalesTableCreateCompanionBuilder,
          $$CuentasDigitalesTableUpdateCompanionBuilder,
          (CuentasDigitale, $$CuentasDigitalesTableReferences),
          CuentasDigitale,
          PrefetchHooks Function({
            bool ingresosRefs,
            bool suscripcionesRefs,
            bool gastosRefs,
            bool asignacionesDineroRefs,
            bool ingresoDistribucionesRefs,
            bool sourceTransfers,
            bool destinationTransfers,
          })
        > {
  $$CuentasDigitalesTableTableManager(
    _$AppDatabase db,
    $CuentasDigitalesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CuentasDigitalesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CuentasDigitalesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CuentasDigitalesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> nombre = const Value.absent(),
              }) => CuentasDigitalesCompanion(id: id, nombre: nombre),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String nombre,
              }) => CuentasDigitalesCompanion.insert(id: id, nombre: nombre),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CuentasDigitalesTable, CuentasDigitale>(table),
                  $$CuentasDigitalesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                ingresosRefs = false,
                suscripcionesRefs = false,
                gastosRefs = false,
                asignacionesDineroRefs = false,
                ingresoDistribucionesRefs = false,
                sourceTransfers = false,
                destinationTransfers = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (ingresosRefs) db.ingresos,
                    if (suscripcionesRefs) db.suscripciones,
                    if (gastosRefs) db.gastos,
                    if (asignacionesDineroRefs) db.asignacionesDinero,
                    if (ingresoDistribucionesRefs) db.ingresoDistribuciones,
                    if (sourceTransfers) db.transferenciasDinero,
                    if (destinationTransfers) db.transferenciasDinero,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (ingresosRefs)
                        await $_getPrefetchedData<
                          CuentasDigitale,
                          $CuentasDigitalesTable,
                          Ingreso
                        >(
                          currentTable: table,
                          referencedTable: $$CuentasDigitalesTableReferences
                              ._ingresosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CuentasDigitalesTableReferences(
                                db,
                                table,
                                p0,
                              ).ingresosRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cuentaDigitalId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (suscripcionesRefs)
                        await $_getPrefetchedData<
                          CuentasDigitale,
                          $CuentasDigitalesTable,
                          Suscripcion
                        >(
                          currentTable: table,
                          referencedTable: $$CuentasDigitalesTableReferences
                              ._suscripcionesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CuentasDigitalesTableReferences(
                                db,
                                table,
                                p0,
                              ).suscripcionesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cuentaDigitalId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (gastosRefs)
                        await $_getPrefetchedData<
                          CuentasDigitale,
                          $CuentasDigitalesTable,
                          Gasto
                        >(
                          currentTable: table,
                          referencedTable: $$CuentasDigitalesTableReferences
                              ._gastosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CuentasDigitalesTableReferences(
                                db,
                                table,
                                p0,
                              ).gastosRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cuentaDigitalId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (asignacionesDineroRefs)
                        await $_getPrefetchedData<
                          CuentasDigitale,
                          $CuentasDigitalesTable,
                          AsignacionesDineroData
                        >(
                          currentTable: table,
                          referencedTable: $$CuentasDigitalesTableReferences
                              ._asignacionesDineroRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CuentasDigitalesTableReferences(
                                db,
                                table,
                                p0,
                              ).asignacionesDineroRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cuentaDigitalId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (ingresoDistribucionesRefs)
                        await $_getPrefetchedData<
                          CuentasDigitale,
                          $CuentasDigitalesTable,
                          IngresoDistribucione
                        >(
                          currentTable: table,
                          referencedTable: $$CuentasDigitalesTableReferences
                              ._ingresoDistribucionesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CuentasDigitalesTableReferences(
                                db,
                                table,
                                p0,
                              ).ingresoDistribucionesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cuentaDigitalId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (sourceTransfers)
                        await $_getPrefetchedData<
                          CuentasDigitale,
                          $CuentasDigitalesTable,
                          TransferenciasDineroData
                        >(
                          currentTable: table,
                          referencedTable: $$CuentasDigitalesTableReferences
                              ._sourceTransfersTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CuentasDigitalesTableReferences(
                                db,
                                table,
                                p0,
                              ).sourceTransfers,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cuentaOrigenId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (destinationTransfers)
                        await $_getPrefetchedData<
                          CuentasDigitale,
                          $CuentasDigitalesTable,
                          TransferenciasDineroData
                        >(
                          currentTable: table,
                          referencedTable: $$CuentasDigitalesTableReferences
                              ._destinationTransfersTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CuentasDigitalesTableReferences(
                                db,
                                table,
                                p0,
                              ).destinationTransfers,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cuentaDestinoId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CuentasDigitalesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CuentasDigitalesTable,
      CuentasDigitale,
      $$CuentasDigitalesTableFilterComposer,
      $$CuentasDigitalesTableOrderingComposer,
      $$CuentasDigitalesTableAnnotationComposer,
      $$CuentasDigitalesTableCreateCompanionBuilder,
      $$CuentasDigitalesTableUpdateCompanionBuilder,
      (CuentasDigitale, $$CuentasDigitalesTableReferences),
      CuentasDigitale,
      PrefetchHooks Function({
        bool ingresosRefs,
        bool suscripcionesRefs,
        bool gastosRefs,
        bool asignacionesDineroRefs,
        bool ingresoDistribucionesRefs,
        bool sourceTransfers,
        bool destinationTransfers,
      })
    >;
typedef $$IngresosTableCreateCompanionBuilder =
    IngresosCompanion Function({
      Value<int> id,
      required double monto,
      Value<String> tipo,
      required DateTime fecha,
      Value<String?> descripcion,
      Value<String?> medio,
      Value<int?> cuentaDigitalId,
    });
typedef $$IngresosTableUpdateCompanionBuilder =
    IngresosCompanion Function({
      Value<int> id,
      Value<double> monto,
      Value<String> tipo,
      Value<DateTime> fecha,
      Value<String?> descripcion,
      Value<String?> medio,
      Value<int?> cuentaDigitalId,
    });

final class $$IngresosTableReferences
    extends BaseReferences<_$AppDatabase, $IngresosTable, Ingreso> {
  $$IngresosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CuentasDigitalesTable _cuentaDigitalIdTable(_$AppDatabase db) => db
      .cuentasDigitales
      .createAlias('ingresos__cuenta_digital_id__cuentas_digitales__id');

  $$CuentasDigitalesTableProcessedTableManager? get cuentaDigitalId {
    final $_column = $_itemColumn<int>('cuenta_digital_id');
    if ($_column == null) return null;
    final manager = $$CuentasDigitalesTableTableManager(
      $_db,
      $_db.cuentasDigitales,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cuentaDigitalIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$DeudasTable, List<Deuda>> _deudasRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.deudas,
    aliasName: 'ingresos__id__deudas__ingreso_id',
  );

  $$DeudasTableProcessedTableManager get deudasRefs {
    final manager = $$DeudasTableTableManager(
      $_db,
      $_db.deudas,
    ).filter((f) => f.ingresoId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_deudasRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $IngresoDistribucionesTable,
    List<IngresoDistribucione>
  >
  _ingresoDistribucionesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.ingresoDistribuciones,
        aliasName: 'ingresos__id__ingreso_distribuciones__ingreso_id',
      );

  $$IngresoDistribucionesTableProcessedTableManager
  get ingresoDistribucionesRefs {
    final manager = $$IngresoDistribucionesTableTableManager(
      $_db,
      $_db.ingresoDistribuciones,
    ).filter((f) => f.ingresoId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _ingresoDistribucionesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$IngresosTableFilterComposer
    extends Composer<_$AppDatabase, $IngresosTable> {
  $$IngresosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get monto => $composableBuilder(
    column: $table.monto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get medio => $composableBuilder(
    column: $table.medio,
    builder: (column) => ColumnFilters(column),
  );

  $$CuentasDigitalesTableFilterComposer get cuentaDigitalId {
    final $$CuentasDigitalesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cuentaDigitalId,
      referencedTable: $db.cuentasDigitales,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CuentasDigitalesTableFilterComposer(
            $db: $db,
            $table: $db.cuentasDigitales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> deudasRefs(
    Expression<bool> Function($$DeudasTableFilterComposer f) f,
  ) {
    final $$DeudasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.deudas,
      getReferencedColumn: (t) => t.ingresoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DeudasTableFilterComposer(
            $db: $db,
            $table: $db.deudas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> ingresoDistribucionesRefs(
    Expression<bool> Function($$IngresoDistribucionesTableFilterComposer f) f,
  ) {
    final $$IngresoDistribucionesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.ingresoDistribuciones,
          getReferencedColumn: (t) => t.ingresoId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$IngresoDistribucionesTableFilterComposer(
                $db: $db,
                $table: $db.ingresoDistribuciones,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$IngresosTableOrderingComposer
    extends Composer<_$AppDatabase, $IngresosTable> {
  $$IngresosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get monto => $composableBuilder(
    column: $table.monto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medio => $composableBuilder(
    column: $table.medio,
    builder: (column) => ColumnOrderings(column),
  );

  $$CuentasDigitalesTableOrderingComposer get cuentaDigitalId {
    final $$CuentasDigitalesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cuentaDigitalId,
      referencedTable: $db.cuentasDigitales,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CuentasDigitalesTableOrderingComposer(
            $db: $db,
            $table: $db.cuentasDigitales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IngresosTableAnnotationComposer
    extends Composer<_$AppDatabase, $IngresosTable> {
  $$IngresosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get monto =>
      $composableBuilder(column: $table.monto, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<DateTime> get fecha =>
      $composableBuilder(column: $table.fecha, builder: (column) => column);

  GeneratedColumn<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get medio =>
      $composableBuilder(column: $table.medio, builder: (column) => column);

  $$CuentasDigitalesTableAnnotationComposer get cuentaDigitalId {
    final $$CuentasDigitalesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cuentaDigitalId,
      referencedTable: $db.cuentasDigitales,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CuentasDigitalesTableAnnotationComposer(
            $db: $db,
            $table: $db.cuentasDigitales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> deudasRefs<T extends Object>(
    Expression<T> Function($$DeudasTableAnnotationComposer a) f,
  ) {
    final $$DeudasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.deudas,
      getReferencedColumn: (t) => t.ingresoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DeudasTableAnnotationComposer(
            $db: $db,
            $table: $db.deudas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> ingresoDistribucionesRefs<T extends Object>(
    Expression<T> Function($$IngresoDistribucionesTableAnnotationComposer a) f,
  ) {
    final $$IngresoDistribucionesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.ingresoDistribuciones,
          getReferencedColumn: (t) => t.ingresoId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$IngresoDistribucionesTableAnnotationComposer(
                $db: $db,
                $table: $db.ingresoDistribuciones,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$IngresosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IngresosTable,
          Ingreso,
          $$IngresosTableFilterComposer,
          $$IngresosTableOrderingComposer,
          $$IngresosTableAnnotationComposer,
          $$IngresosTableCreateCompanionBuilder,
          $$IngresosTableUpdateCompanionBuilder,
          (Ingreso, $$IngresosTableReferences),
          Ingreso,
          PrefetchHooks Function({
            bool cuentaDigitalId,
            bool deudasRefs,
            bool ingresoDistribucionesRefs,
          })
        > {
  $$IngresosTableTableManager(_$AppDatabase db, $IngresosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IngresosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IngresosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IngresosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<double> monto = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<DateTime> fecha = const Value.absent(),
                Value<String?> descripcion = const Value.absent(),
                Value<String?> medio = const Value.absent(),
                Value<int?> cuentaDigitalId = const Value.absent(),
              }) => IngresosCompanion(
                id: id,
                monto: monto,
                tipo: tipo,
                fecha: fecha,
                descripcion: descripcion,
                medio: medio,
                cuentaDigitalId: cuentaDigitalId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required double monto,
                Value<String> tipo = const Value.absent(),
                required DateTime fecha,
                Value<String?> descripcion = const Value.absent(),
                Value<String?> medio = const Value.absent(),
                Value<int?> cuentaDigitalId = const Value.absent(),
              }) => IngresosCompanion.insert(
                id: id,
                monto: monto,
                tipo: tipo,
                fecha: fecha,
                descripcion: descripcion,
                medio: medio,
                cuentaDigitalId: cuentaDigitalId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$IngresosTable, Ingreso>(table),
                  $$IngresosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                cuentaDigitalId = false,
                deudasRefs = false,
                ingresoDistribucionesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (deudasRefs) db.deudas,
                    if (ingresoDistribucionesRefs) db.ingresoDistribuciones,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (cuentaDigitalId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.cuentaDigitalId,
                                    referencedTable: $$IngresosTableReferences
                                        ._cuentaDigitalIdTable(db),
                                    referencedColumn: $$IngresosTableReferences
                                        ._cuentaDigitalIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (deudasRefs)
                        await $_getPrefetchedData<
                          Ingreso,
                          $IngresosTable,
                          Deuda
                        >(
                          currentTable: table,
                          referencedTable: $$IngresosTableReferences
                              ._deudasRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$IngresosTableReferences(
                                db,
                                table,
                                p0,
                              ).deudasRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.ingresoId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (ingresoDistribucionesRefs)
                        await $_getPrefetchedData<
                          Ingreso,
                          $IngresosTable,
                          IngresoDistribucione
                        >(
                          currentTable: table,
                          referencedTable: $$IngresosTableReferences
                              ._ingresoDistribucionesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$IngresosTableReferences(
                                db,
                                table,
                                p0,
                              ).ingresoDistribucionesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.ingresoId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$IngresosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IngresosTable,
      Ingreso,
      $$IngresosTableFilterComposer,
      $$IngresosTableOrderingComposer,
      $$IngresosTableAnnotationComposer,
      $$IngresosTableCreateCompanionBuilder,
      $$IngresosTableUpdateCompanionBuilder,
      (Ingreso, $$IngresosTableReferences),
      Ingreso,
      PrefetchHooks Function({
        bool cuentaDigitalId,
        bool deudasRefs,
        bool ingresoDistribucionesRefs,
      })
    >;
typedef $$SuscripcionesTableCreateCompanionBuilder =
    SuscripcionesCompanion Function({
      Value<int> id,
      required String nombre,
      required double precio,
      required DateTime proximoPago,
      required String frecuencia,
      Value<String?> medio,
      Value<int?> cuentaDigitalId,
      Value<bool> activa,
    });
typedef $$SuscripcionesTableUpdateCompanionBuilder =
    SuscripcionesCompanion Function({
      Value<int> id,
      Value<String> nombre,
      Value<double> precio,
      Value<DateTime> proximoPago,
      Value<String> frecuencia,
      Value<String?> medio,
      Value<int?> cuentaDigitalId,
      Value<bool> activa,
    });

final class $$SuscripcionesTableReferences
    extends BaseReferences<_$AppDatabase, $SuscripcionesTable, Suscripcion> {
  $$SuscripcionesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CuentasDigitalesTable _cuentaDigitalIdTable(_$AppDatabase db) => db
      .cuentasDigitales
      .createAlias('suscripciones__cuenta_digital_id__cuentas_digitales__id');

  $$CuentasDigitalesTableProcessedTableManager? get cuentaDigitalId {
    final $_column = $_itemColumn<int>('cuenta_digital_id');
    if ($_column == null) return null;
    final manager = $$CuentasDigitalesTableTableManager(
      $_db,
      $_db.cuentasDigitales,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cuentaDigitalIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$GastosTable, List<Gasto>> _gastosRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.gastos,
    aliasName: 'suscripciones__id__gastos__suscripcion_id',
  );

  $$GastosTableProcessedTableManager get gastosRefs {
    final manager = $$GastosTableTableManager(
      $_db,
      $_db.gastos,
    ).filter((f) => f.suscripcionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_gastosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SuscripcionesTableFilterComposer
    extends Composer<_$AppDatabase, $SuscripcionesTable> {
  $$SuscripcionesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get precio => $composableBuilder(
    column: $table.precio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get proximoPago => $composableBuilder(
    column: $table.proximoPago,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frecuencia => $composableBuilder(
    column: $table.frecuencia,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get medio => $composableBuilder(
    column: $table.medio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get activa => $composableBuilder(
    column: $table.activa,
    builder: (column) => ColumnFilters(column),
  );

  $$CuentasDigitalesTableFilterComposer get cuentaDigitalId {
    final $$CuentasDigitalesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cuentaDigitalId,
      referencedTable: $db.cuentasDigitales,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CuentasDigitalesTableFilterComposer(
            $db: $db,
            $table: $db.cuentasDigitales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> gastosRefs(
    Expression<bool> Function($$GastosTableFilterComposer f) f,
  ) {
    final $$GastosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.gastos,
      getReferencedColumn: (t) => t.suscripcionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GastosTableFilterComposer(
            $db: $db,
            $table: $db.gastos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SuscripcionesTableOrderingComposer
    extends Composer<_$AppDatabase, $SuscripcionesTable> {
  $$SuscripcionesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get precio => $composableBuilder(
    column: $table.precio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get proximoPago => $composableBuilder(
    column: $table.proximoPago,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frecuencia => $composableBuilder(
    column: $table.frecuencia,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medio => $composableBuilder(
    column: $table.medio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get activa => $composableBuilder(
    column: $table.activa,
    builder: (column) => ColumnOrderings(column),
  );

  $$CuentasDigitalesTableOrderingComposer get cuentaDigitalId {
    final $$CuentasDigitalesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cuentaDigitalId,
      referencedTable: $db.cuentasDigitales,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CuentasDigitalesTableOrderingComposer(
            $db: $db,
            $table: $db.cuentasDigitales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SuscripcionesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SuscripcionesTable> {
  $$SuscripcionesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<double> get precio =>
      $composableBuilder(column: $table.precio, builder: (column) => column);

  GeneratedColumn<DateTime> get proximoPago => $composableBuilder(
    column: $table.proximoPago,
    builder: (column) => column,
  );

  GeneratedColumn<String> get frecuencia => $composableBuilder(
    column: $table.frecuencia,
    builder: (column) => column,
  );

  GeneratedColumn<String> get medio =>
      $composableBuilder(column: $table.medio, builder: (column) => column);

  GeneratedColumn<bool> get activa =>
      $composableBuilder(column: $table.activa, builder: (column) => column);

  $$CuentasDigitalesTableAnnotationComposer get cuentaDigitalId {
    final $$CuentasDigitalesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cuentaDigitalId,
      referencedTable: $db.cuentasDigitales,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CuentasDigitalesTableAnnotationComposer(
            $db: $db,
            $table: $db.cuentasDigitales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> gastosRefs<T extends Object>(
    Expression<T> Function($$GastosTableAnnotationComposer a) f,
  ) {
    final $$GastosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.gastos,
      getReferencedColumn: (t) => t.suscripcionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GastosTableAnnotationComposer(
            $db: $db,
            $table: $db.gastos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SuscripcionesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SuscripcionesTable,
          Suscripcion,
          $$SuscripcionesTableFilterComposer,
          $$SuscripcionesTableOrderingComposer,
          $$SuscripcionesTableAnnotationComposer,
          $$SuscripcionesTableCreateCompanionBuilder,
          $$SuscripcionesTableUpdateCompanionBuilder,
          (Suscripcion, $$SuscripcionesTableReferences),
          Suscripcion,
          PrefetchHooks Function({bool cuentaDigitalId, bool gastosRefs})
        > {
  $$SuscripcionesTableTableManager(_$AppDatabase db, $SuscripcionesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SuscripcionesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SuscripcionesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SuscripcionesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<double> precio = const Value.absent(),
                Value<DateTime> proximoPago = const Value.absent(),
                Value<String> frecuencia = const Value.absent(),
                Value<String?> medio = const Value.absent(),
                Value<int?> cuentaDigitalId = const Value.absent(),
                Value<bool> activa = const Value.absent(),
              }) => SuscripcionesCompanion(
                id: id,
                nombre: nombre,
                precio: precio,
                proximoPago: proximoPago,
                frecuencia: frecuencia,
                medio: medio,
                cuentaDigitalId: cuentaDigitalId,
                activa: activa,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String nombre,
                required double precio,
                required DateTime proximoPago,
                required String frecuencia,
                Value<String?> medio = const Value.absent(),
                Value<int?> cuentaDigitalId = const Value.absent(),
                Value<bool> activa = const Value.absent(),
              }) => SuscripcionesCompanion.insert(
                id: id,
                nombre: nombre,
                precio: precio,
                proximoPago: proximoPago,
                frecuencia: frecuencia,
                medio: medio,
                cuentaDigitalId: cuentaDigitalId,
                activa: activa,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SuscripcionesTable, Suscripcion>(table),
                  $$SuscripcionesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({cuentaDigitalId = false, gastosRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (gastosRefs) db.gastos],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (cuentaDigitalId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.cuentaDigitalId,
                                    referencedTable:
                                        $$SuscripcionesTableReferences
                                            ._cuentaDigitalIdTable(db),
                                    referencedColumn:
                                        $$SuscripcionesTableReferences
                                            ._cuentaDigitalIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (gastosRefs)
                        await $_getPrefetchedData<
                          Suscripcion,
                          $SuscripcionesTable,
                          Gasto
                        >(
                          currentTable: table,
                          referencedTable: $$SuscripcionesTableReferences
                              ._gastosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SuscripcionesTableReferences(
                                db,
                                table,
                                p0,
                              ).gastosRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.suscripcionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SuscripcionesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SuscripcionesTable,
      Suscripcion,
      $$SuscripcionesTableFilterComposer,
      $$SuscripcionesTableOrderingComposer,
      $$SuscripcionesTableAnnotationComposer,
      $$SuscripcionesTableCreateCompanionBuilder,
      $$SuscripcionesTableUpdateCompanionBuilder,
      (Suscripcion, $$SuscripcionesTableReferences),
      Suscripcion,
      PrefetchHooks Function({bool cuentaDigitalId, bool gastosRefs})
    >;
typedef $$GastosTableCreateCompanionBuilder =
    GastosCompanion Function({
      Value<int> id,
      required String nombre,
      required double monto,
      required String categoria,
      required DateTime fecha,
      Value<String?> nota,
      Value<String?> medio,
      Value<int?> cuentaDigitalId,
      Value<int?> suscripcionId,
      Value<DateTime?> suscripcionPeriodo,
    });
typedef $$GastosTableUpdateCompanionBuilder =
    GastosCompanion Function({
      Value<int> id,
      Value<String> nombre,
      Value<double> monto,
      Value<String> categoria,
      Value<DateTime> fecha,
      Value<String?> nota,
      Value<String?> medio,
      Value<int?> cuentaDigitalId,
      Value<int?> suscripcionId,
      Value<DateTime?> suscripcionPeriodo,
    });

final class $$GastosTableReferences
    extends BaseReferences<_$AppDatabase, $GastosTable, Gasto> {
  $$GastosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CuentasDigitalesTable _cuentaDigitalIdTable(_$AppDatabase db) => db
      .cuentasDigitales
      .createAlias('gastos__cuenta_digital_id__cuentas_digitales__id');

  $$CuentasDigitalesTableProcessedTableManager? get cuentaDigitalId {
    final $_column = $_itemColumn<int>('cuenta_digital_id');
    if ($_column == null) return null;
    final manager = $$CuentasDigitalesTableTableManager(
      $_db,
      $_db.cuentasDigitales,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cuentaDigitalIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $SuscripcionesTable _suscripcionIdTable(_$AppDatabase db) =>
      db.suscripciones.createAlias('gastos__suscripcion_id__suscripciones__id');

  $$SuscripcionesTableProcessedTableManager? get suscripcionId {
    final $_column = $_itemColumn<int>('suscripcion_id');
    if ($_column == null) return null;
    final manager = $$SuscripcionesTableTableManager(
      $_db,
      $_db.suscripciones,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_suscripcionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$GastosTableFilterComposer
    extends Composer<_$AppDatabase, $GastosTable> {
  $$GastosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get monto => $composableBuilder(
    column: $table.monto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoria => $composableBuilder(
    column: $table.categoria,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nota => $composableBuilder(
    column: $table.nota,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get medio => $composableBuilder(
    column: $table.medio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get suscripcionPeriodo => $composableBuilder(
    column: $table.suscripcionPeriodo,
    builder: (column) => ColumnFilters(column),
  );

  $$CuentasDigitalesTableFilterComposer get cuentaDigitalId {
    final $$CuentasDigitalesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cuentaDigitalId,
      referencedTable: $db.cuentasDigitales,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CuentasDigitalesTableFilterComposer(
            $db: $db,
            $table: $db.cuentasDigitales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SuscripcionesTableFilterComposer get suscripcionId {
    final $$SuscripcionesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.suscripcionId,
      referencedTable: $db.suscripciones,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SuscripcionesTableFilterComposer(
            $db: $db,
            $table: $db.suscripciones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GastosTableOrderingComposer
    extends Composer<_$AppDatabase, $GastosTable> {
  $$GastosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get monto => $composableBuilder(
    column: $table.monto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoria => $composableBuilder(
    column: $table.categoria,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nota => $composableBuilder(
    column: $table.nota,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medio => $composableBuilder(
    column: $table.medio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get suscripcionPeriodo => $composableBuilder(
    column: $table.suscripcionPeriodo,
    builder: (column) => ColumnOrderings(column),
  );

  $$CuentasDigitalesTableOrderingComposer get cuentaDigitalId {
    final $$CuentasDigitalesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cuentaDigitalId,
      referencedTable: $db.cuentasDigitales,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CuentasDigitalesTableOrderingComposer(
            $db: $db,
            $table: $db.cuentasDigitales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SuscripcionesTableOrderingComposer get suscripcionId {
    final $$SuscripcionesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.suscripcionId,
      referencedTable: $db.suscripciones,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SuscripcionesTableOrderingComposer(
            $db: $db,
            $table: $db.suscripciones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GastosTableAnnotationComposer
    extends Composer<_$AppDatabase, $GastosTable> {
  $$GastosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<double> get monto =>
      $composableBuilder(column: $table.monto, builder: (column) => column);

  GeneratedColumn<String> get categoria =>
      $composableBuilder(column: $table.categoria, builder: (column) => column);

  GeneratedColumn<DateTime> get fecha =>
      $composableBuilder(column: $table.fecha, builder: (column) => column);

  GeneratedColumn<String> get nota =>
      $composableBuilder(column: $table.nota, builder: (column) => column);

  GeneratedColumn<String> get medio =>
      $composableBuilder(column: $table.medio, builder: (column) => column);

  GeneratedColumn<DateTime> get suscripcionPeriodo => $composableBuilder(
    column: $table.suscripcionPeriodo,
    builder: (column) => column,
  );

  $$CuentasDigitalesTableAnnotationComposer get cuentaDigitalId {
    final $$CuentasDigitalesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cuentaDigitalId,
      referencedTable: $db.cuentasDigitales,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CuentasDigitalesTableAnnotationComposer(
            $db: $db,
            $table: $db.cuentasDigitales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SuscripcionesTableAnnotationComposer get suscripcionId {
    final $$SuscripcionesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.suscripcionId,
      referencedTable: $db.suscripciones,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SuscripcionesTableAnnotationComposer(
            $db: $db,
            $table: $db.suscripciones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GastosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GastosTable,
          Gasto,
          $$GastosTableFilterComposer,
          $$GastosTableOrderingComposer,
          $$GastosTableAnnotationComposer,
          $$GastosTableCreateCompanionBuilder,
          $$GastosTableUpdateCompanionBuilder,
          (Gasto, $$GastosTableReferences),
          Gasto,
          PrefetchHooks Function({bool cuentaDigitalId, bool suscripcionId})
        > {
  $$GastosTableTableManager(_$AppDatabase db, $GastosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GastosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GastosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GastosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<double> monto = const Value.absent(),
                Value<String> categoria = const Value.absent(),
                Value<DateTime> fecha = const Value.absent(),
                Value<String?> nota = const Value.absent(),
                Value<String?> medio = const Value.absent(),
                Value<int?> cuentaDigitalId = const Value.absent(),
                Value<int?> suscripcionId = const Value.absent(),
                Value<DateTime?> suscripcionPeriodo = const Value.absent(),
              }) => GastosCompanion(
                id: id,
                nombre: nombre,
                monto: monto,
                categoria: categoria,
                fecha: fecha,
                nota: nota,
                medio: medio,
                cuentaDigitalId: cuentaDigitalId,
                suscripcionId: suscripcionId,
                suscripcionPeriodo: suscripcionPeriodo,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String nombre,
                required double monto,
                required String categoria,
                required DateTime fecha,
                Value<String?> nota = const Value.absent(),
                Value<String?> medio = const Value.absent(),
                Value<int?> cuentaDigitalId = const Value.absent(),
                Value<int?> suscripcionId = const Value.absent(),
                Value<DateTime?> suscripcionPeriodo = const Value.absent(),
              }) => GastosCompanion.insert(
                id: id,
                nombre: nombre,
                monto: monto,
                categoria: categoria,
                fecha: fecha,
                nota: nota,
                medio: medio,
                cuentaDigitalId: cuentaDigitalId,
                suscripcionId: suscripcionId,
                suscripcionPeriodo: suscripcionPeriodo,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GastosTable, Gasto>(table),
                  $$GastosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({cuentaDigitalId = false, suscripcionId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (cuentaDigitalId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.cuentaDigitalId,
                                    referencedTable: $$GastosTableReferences
                                        ._cuentaDigitalIdTable(db),
                                    referencedColumn: $$GastosTableReferences
                                        ._cuentaDigitalIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (suscripcionId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.suscripcionId,
                                    referencedTable: $$GastosTableReferences
                                        ._suscripcionIdTable(db),
                                    referencedColumn: $$GastosTableReferences
                                        ._suscripcionIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$GastosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GastosTable,
      Gasto,
      $$GastosTableFilterComposer,
      $$GastosTableOrderingComposer,
      $$GastosTableAnnotationComposer,
      $$GastosTableCreateCompanionBuilder,
      $$GastosTableUpdateCompanionBuilder,
      (Gasto, $$GastosTableReferences),
      Gasto,
      PrefetchHooks Function({bool cuentaDigitalId, bool suscripcionId})
    >;
typedef $$DeudasTableCreateCompanionBuilder =
    DeudasCompanion Function({
      Value<int> id,
      Value<int?> ingresoId,
      required String nombre,
      required double montoOriginal,
      required double cuota,
      required int cuotasTotales,
      Value<int> cuotasPagadas,
      Value<int> cuotasPagadasDeclaradas,
      Value<bool> cuotasLegadasRevisadas,
      Value<DateTime?> fechaProximoPago,
    });
typedef $$DeudasTableUpdateCompanionBuilder =
    DeudasCompanion Function({
      Value<int> id,
      Value<int?> ingresoId,
      Value<String> nombre,
      Value<double> montoOriginal,
      Value<double> cuota,
      Value<int> cuotasTotales,
      Value<int> cuotasPagadas,
      Value<int> cuotasPagadasDeclaradas,
      Value<bool> cuotasLegadasRevisadas,
      Value<DateTime?> fechaProximoPago,
    });

final class $$DeudasTableReferences
    extends BaseReferences<_$AppDatabase, $DeudasTable, Deuda> {
  $$DeudasTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $IngresosTable _ingresoIdTable(_$AppDatabase db) =>
      db.ingresos.createAlias('deudas__ingreso_id__ingresos__id');

  $$IngresosTableProcessedTableManager? get ingresoId {
    final $_column = $_itemColumn<int>('ingreso_id');
    if ($_column == null) return null;
    final manager = $$IngresosTableTableManager(
      $_db,
      $_db.ingresos,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ingresoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PagosDeudaTable, List<PagosDeudaData>>
  _pagosDeudaRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.pagosDeuda,
    aliasName: 'deudas__id__pagos_deuda__deuda_id',
  );

  $$PagosDeudaTableProcessedTableManager get pagosDeudaRefs {
    final manager = $$PagosDeudaTableTableManager(
      $_db,
      $_db.pagosDeuda,
    ).filter((f) => f.deudaId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_pagosDeudaRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DeudasTableFilterComposer
    extends Composer<_$AppDatabase, $DeudasTable> {
  $$DeudasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get montoOriginal => $composableBuilder(
    column: $table.montoOriginal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cuota => $composableBuilder(
    column: $table.cuota,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cuotasTotales => $composableBuilder(
    column: $table.cuotasTotales,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cuotasPagadas => $composableBuilder(
    column: $table.cuotasPagadas,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cuotasPagadasDeclaradas => $composableBuilder(
    column: $table.cuotasPagadasDeclaradas,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get cuotasLegadasRevisadas => $composableBuilder(
    column: $table.cuotasLegadasRevisadas,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fechaProximoPago => $composableBuilder(
    column: $table.fechaProximoPago,
    builder: (column) => ColumnFilters(column),
  );

  $$IngresosTableFilterComposer get ingresoId {
    final $$IngresosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ingresoId,
      referencedTable: $db.ingresos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IngresosTableFilterComposer(
            $db: $db,
            $table: $db.ingresos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> pagosDeudaRefs(
    Expression<bool> Function($$PagosDeudaTableFilterComposer f) f,
  ) {
    final $$PagosDeudaTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pagosDeuda,
      getReferencedColumn: (t) => t.deudaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagosDeudaTableFilterComposer(
            $db: $db,
            $table: $db.pagosDeuda,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DeudasTableOrderingComposer
    extends Composer<_$AppDatabase, $DeudasTable> {
  $$DeudasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get montoOriginal => $composableBuilder(
    column: $table.montoOriginal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cuota => $composableBuilder(
    column: $table.cuota,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cuotasTotales => $composableBuilder(
    column: $table.cuotasTotales,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cuotasPagadas => $composableBuilder(
    column: $table.cuotasPagadas,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cuotasPagadasDeclaradas => $composableBuilder(
    column: $table.cuotasPagadasDeclaradas,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get cuotasLegadasRevisadas => $composableBuilder(
    column: $table.cuotasLegadasRevisadas,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fechaProximoPago => $composableBuilder(
    column: $table.fechaProximoPago,
    builder: (column) => ColumnOrderings(column),
  );

  $$IngresosTableOrderingComposer get ingresoId {
    final $$IngresosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ingresoId,
      referencedTable: $db.ingresos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IngresosTableOrderingComposer(
            $db: $db,
            $table: $db.ingresos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DeudasTableAnnotationComposer
    extends Composer<_$AppDatabase, $DeudasTable> {
  $$DeudasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<double> get montoOriginal => $composableBuilder(
    column: $table.montoOriginal,
    builder: (column) => column,
  );

  GeneratedColumn<double> get cuota =>
      $composableBuilder(column: $table.cuota, builder: (column) => column);

  GeneratedColumn<int> get cuotasTotales => $composableBuilder(
    column: $table.cuotasTotales,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cuotasPagadas => $composableBuilder(
    column: $table.cuotasPagadas,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cuotasPagadasDeclaradas => $composableBuilder(
    column: $table.cuotasPagadasDeclaradas,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get cuotasLegadasRevisadas => $composableBuilder(
    column: $table.cuotasLegadasRevisadas,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fechaProximoPago => $composableBuilder(
    column: $table.fechaProximoPago,
    builder: (column) => column,
  );

  $$IngresosTableAnnotationComposer get ingresoId {
    final $$IngresosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ingresoId,
      referencedTable: $db.ingresos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IngresosTableAnnotationComposer(
            $db: $db,
            $table: $db.ingresos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> pagosDeudaRefs<T extends Object>(
    Expression<T> Function($$PagosDeudaTableAnnotationComposer a) f,
  ) {
    final $$PagosDeudaTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pagosDeuda,
      getReferencedColumn: (t) => t.deudaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagosDeudaTableAnnotationComposer(
            $db: $db,
            $table: $db.pagosDeuda,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DeudasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DeudasTable,
          Deuda,
          $$DeudasTableFilterComposer,
          $$DeudasTableOrderingComposer,
          $$DeudasTableAnnotationComposer,
          $$DeudasTableCreateCompanionBuilder,
          $$DeudasTableUpdateCompanionBuilder,
          (Deuda, $$DeudasTableReferences),
          Deuda,
          PrefetchHooks Function({bool ingresoId, bool pagosDeudaRefs})
        > {
  $$DeudasTableTableManager(_$AppDatabase db, $DeudasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeudasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeudasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeudasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> ingresoId = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<double> montoOriginal = const Value.absent(),
                Value<double> cuota = const Value.absent(),
                Value<int> cuotasTotales = const Value.absent(),
                Value<int> cuotasPagadas = const Value.absent(),
                Value<int> cuotasPagadasDeclaradas = const Value.absent(),
                Value<bool> cuotasLegadasRevisadas = const Value.absent(),
                Value<DateTime?> fechaProximoPago = const Value.absent(),
              }) => DeudasCompanion(
                id: id,
                ingresoId: ingresoId,
                nombre: nombre,
                montoOriginal: montoOriginal,
                cuota: cuota,
                cuotasTotales: cuotasTotales,
                cuotasPagadas: cuotasPagadas,
                cuotasPagadasDeclaradas: cuotasPagadasDeclaradas,
                cuotasLegadasRevisadas: cuotasLegadasRevisadas,
                fechaProximoPago: fechaProximoPago,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> ingresoId = const Value.absent(),
                required String nombre,
                required double montoOriginal,
                required double cuota,
                required int cuotasTotales,
                Value<int> cuotasPagadas = const Value.absent(),
                Value<int> cuotasPagadasDeclaradas = const Value.absent(),
                Value<bool> cuotasLegadasRevisadas = const Value.absent(),
                Value<DateTime?> fechaProximoPago = const Value.absent(),
              }) => DeudasCompanion.insert(
                id: id,
                ingresoId: ingresoId,
                nombre: nombre,
                montoOriginal: montoOriginal,
                cuota: cuota,
                cuotasTotales: cuotasTotales,
                cuotasPagadas: cuotasPagadas,
                cuotasPagadasDeclaradas: cuotasPagadasDeclaradas,
                cuotasLegadasRevisadas: cuotasLegadasRevisadas,
                fechaProximoPago: fechaProximoPago,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DeudasTable, Deuda>(table),
                  $$DeudasTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({ingresoId = false, pagosDeudaRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (pagosDeudaRefs) db.pagosDeuda],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (ingresoId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.ingresoId,
                                referencedTable: $$DeudasTableReferences
                                    ._ingresoIdTable(db),
                                referencedColumn: $$DeudasTableReferences
                                    ._ingresoIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (pagosDeudaRefs)
                    await $_getPrefetchedData<
                      Deuda,
                      $DeudasTable,
                      PagosDeudaData
                    >(
                      currentTable: table,
                      referencedTable: $$DeudasTableReferences
                          ._pagosDeudaRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$DeudasTableReferences(db, table, p0).pagosDeudaRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.deudaId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$DeudasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DeudasTable,
      Deuda,
      $$DeudasTableFilterComposer,
      $$DeudasTableOrderingComposer,
      $$DeudasTableAnnotationComposer,
      $$DeudasTableCreateCompanionBuilder,
      $$DeudasTableUpdateCompanionBuilder,
      (Deuda, $$DeudasTableReferences),
      Deuda,
      PrefetchHooks Function({bool ingresoId, bool pagosDeudaRefs})
    >;
typedef $$PagosDeudaTableCreateCompanionBuilder =
    PagosDeudaCompanion Function({
      Value<int> id,
      required int deudaId,
      required double monto,
      required DateTime fecha,
      Value<String?> operationId,
      Value<String?> medio,
    });
typedef $$PagosDeudaTableUpdateCompanionBuilder =
    PagosDeudaCompanion Function({
      Value<int> id,
      Value<int> deudaId,
      Value<double> monto,
      Value<DateTime> fecha,
      Value<String?> operationId,
      Value<String?> medio,
    });

final class $$PagosDeudaTableReferences
    extends BaseReferences<_$AppDatabase, $PagosDeudaTable, PagosDeudaData> {
  $$PagosDeudaTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DeudasTable _deudaIdTable(_$AppDatabase db) =>
      db.deudas.createAlias('pagos_deuda__deuda_id__deudas__id');

  $$DeudasTableProcessedTableManager get deudaId {
    final $_column = $_itemColumn<int>('deuda_id')!;

    final manager = $$DeudasTableTableManager(
      $_db,
      $_db.deudas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_deudaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PagosDeudaTableFilterComposer
    extends Composer<_$AppDatabase, $PagosDeudaTable> {
  $$PagosDeudaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get monto => $composableBuilder(
    column: $table.monto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get medio => $composableBuilder(
    column: $table.medio,
    builder: (column) => ColumnFilters(column),
  );

  $$DeudasTableFilterComposer get deudaId {
    final $$DeudasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deudaId,
      referencedTable: $db.deudas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DeudasTableFilterComposer(
            $db: $db,
            $table: $db.deudas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PagosDeudaTableOrderingComposer
    extends Composer<_$AppDatabase, $PagosDeudaTable> {
  $$PagosDeudaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get monto => $composableBuilder(
    column: $table.monto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medio => $composableBuilder(
    column: $table.medio,
    builder: (column) => ColumnOrderings(column),
  );

  $$DeudasTableOrderingComposer get deudaId {
    final $$DeudasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deudaId,
      referencedTable: $db.deudas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DeudasTableOrderingComposer(
            $db: $db,
            $table: $db.deudas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PagosDeudaTableAnnotationComposer
    extends Composer<_$AppDatabase, $PagosDeudaTable> {
  $$PagosDeudaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get monto =>
      $composableBuilder(column: $table.monto, builder: (column) => column);

  GeneratedColumn<DateTime> get fecha =>
      $composableBuilder(column: $table.fecha, builder: (column) => column);

  GeneratedColumn<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get medio =>
      $composableBuilder(column: $table.medio, builder: (column) => column);

  $$DeudasTableAnnotationComposer get deudaId {
    final $$DeudasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deudaId,
      referencedTable: $db.deudas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DeudasTableAnnotationComposer(
            $db: $db,
            $table: $db.deudas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PagosDeudaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PagosDeudaTable,
          PagosDeudaData,
          $$PagosDeudaTableFilterComposer,
          $$PagosDeudaTableOrderingComposer,
          $$PagosDeudaTableAnnotationComposer,
          $$PagosDeudaTableCreateCompanionBuilder,
          $$PagosDeudaTableUpdateCompanionBuilder,
          (PagosDeudaData, $$PagosDeudaTableReferences),
          PagosDeudaData,
          PrefetchHooks Function({bool deudaId})
        > {
  $$PagosDeudaTableTableManager(_$AppDatabase db, $PagosDeudaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PagosDeudaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PagosDeudaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PagosDeudaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> deudaId = const Value.absent(),
                Value<double> monto = const Value.absent(),
                Value<DateTime> fecha = const Value.absent(),
                Value<String?> operationId = const Value.absent(),
                Value<String?> medio = const Value.absent(),
              }) => PagosDeudaCompanion(
                id: id,
                deudaId: deudaId,
                monto: monto,
                fecha: fecha,
                operationId: operationId,
                medio: medio,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int deudaId,
                required double monto,
                required DateTime fecha,
                Value<String?> operationId = const Value.absent(),
                Value<String?> medio = const Value.absent(),
              }) => PagosDeudaCompanion.insert(
                id: id,
                deudaId: deudaId,
                monto: monto,
                fecha: fecha,
                operationId: operationId,
                medio: medio,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PagosDeudaTable, PagosDeudaData>(table),
                  $$PagosDeudaTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({deudaId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (deudaId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.deudaId,
                                referencedTable: $$PagosDeudaTableReferences
                                    ._deudaIdTable(db),
                                referencedColumn: $$PagosDeudaTableReferences
                                    ._deudaIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PagosDeudaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PagosDeudaTable,
      PagosDeudaData,
      $$PagosDeudaTableFilterComposer,
      $$PagosDeudaTableOrderingComposer,
      $$PagosDeudaTableAnnotationComposer,
      $$PagosDeudaTableCreateCompanionBuilder,
      $$PagosDeudaTableUpdateCompanionBuilder,
      (PagosDeudaData, $$PagosDeudaTableReferences),
      PagosDeudaData,
      PrefetchHooks Function({bool deudaId})
    >;
typedef $$MovimientosAhorroTableCreateCompanionBuilder =
    MovimientosAhorroCompanion Function({
      Value<int> id,
      required double monto,
      required String tipo,
      required DateTime fecha,
      Value<String?> medio,
    });
typedef $$MovimientosAhorroTableUpdateCompanionBuilder =
    MovimientosAhorroCompanion Function({
      Value<int> id,
      Value<double> monto,
      Value<String> tipo,
      Value<DateTime> fecha,
      Value<String?> medio,
    });

class $$MovimientosAhorroTableFilterComposer
    extends Composer<_$AppDatabase, $MovimientosAhorroTable> {
  $$MovimientosAhorroTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get monto => $composableBuilder(
    column: $table.monto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get medio => $composableBuilder(
    column: $table.medio,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MovimientosAhorroTableOrderingComposer
    extends Composer<_$AppDatabase, $MovimientosAhorroTable> {
  $$MovimientosAhorroTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get monto => $composableBuilder(
    column: $table.monto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medio => $composableBuilder(
    column: $table.medio,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MovimientosAhorroTableAnnotationComposer
    extends Composer<_$AppDatabase, $MovimientosAhorroTable> {
  $$MovimientosAhorroTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get monto =>
      $composableBuilder(column: $table.monto, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<DateTime> get fecha =>
      $composableBuilder(column: $table.fecha, builder: (column) => column);

  GeneratedColumn<String> get medio =>
      $composableBuilder(column: $table.medio, builder: (column) => column);
}

class $$MovimientosAhorroTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MovimientosAhorroTable,
          MovimientosAhorroData,
          $$MovimientosAhorroTableFilterComposer,
          $$MovimientosAhorroTableOrderingComposer,
          $$MovimientosAhorroTableAnnotationComposer,
          $$MovimientosAhorroTableCreateCompanionBuilder,
          $$MovimientosAhorroTableUpdateCompanionBuilder,
          (
            MovimientosAhorroData,
            BaseReferences<
              _$AppDatabase,
              $MovimientosAhorroTable,
              MovimientosAhorroData
            >,
          ),
          MovimientosAhorroData,
          PrefetchHooks Function()
        > {
  $$MovimientosAhorroTableTableManager(
    _$AppDatabase db,
    $MovimientosAhorroTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MovimientosAhorroTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MovimientosAhorroTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MovimientosAhorroTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<double> monto = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<DateTime> fecha = const Value.absent(),
                Value<String?> medio = const Value.absent(),
              }) => MovimientosAhorroCompanion(
                id: id,
                monto: monto,
                tipo: tipo,
                fecha: fecha,
                medio: medio,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required double monto,
                required String tipo,
                required DateTime fecha,
                Value<String?> medio = const Value.absent(),
              }) => MovimientosAhorroCompanion.insert(
                id: id,
                monto: monto,
                tipo: tipo,
                fecha: fecha,
                medio: medio,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MovimientosAhorroTable, MovimientosAhorroData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $MovimientosAhorroTable,
                    MovimientosAhorroData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MovimientosAhorroTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MovimientosAhorroTable,
      MovimientosAhorroData,
      $$MovimientosAhorroTableFilterComposer,
      $$MovimientosAhorroTableOrderingComposer,
      $$MovimientosAhorroTableAnnotationComposer,
      $$MovimientosAhorroTableCreateCompanionBuilder,
      $$MovimientosAhorroTableUpdateCompanionBuilder,
      (
        MovimientosAhorroData,
        BaseReferences<
          _$AppDatabase,
          $MovimientosAhorroTable,
          MovimientosAhorroData
        >,
      ),
      MovimientosAhorroData,
      PrefetchHooks Function()
    >;
typedef $$PrestamosTercerosTableCreateCompanionBuilder =
    PrestamosTercerosCompanion Function({
      Value<int> id,
      required String persona,
      required double montoPrincipal,
      required DateTime fechaEntrega,
      required DateTime fechaDevolucionAcordada,
    });
typedef $$PrestamosTercerosTableUpdateCompanionBuilder =
    PrestamosTercerosCompanion Function({
      Value<int> id,
      Value<String> persona,
      Value<double> montoPrincipal,
      Value<DateTime> fechaEntrega,
      Value<DateTime> fechaDevolucionAcordada,
    });

final class $$PrestamosTercerosTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $PrestamosTercerosTable,
          PrestamosTercero
        > {
  $$PrestamosTercerosTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $MovimientosPrestamoTable,
    List<MovimientosPrestamoData>
  >
  _movimientosPrestamoRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.movimientosPrestamo,
        aliasName: 'prestamos_terceros__id__movimientos_prestamo__prestamo_id',
      );

  $$MovimientosPrestamoTableProcessedTableManager get movimientosPrestamoRefs {
    final manager = $$MovimientosPrestamoTableTableManager(
      $_db,
      $_db.movimientosPrestamo,
    ).filter((f) => f.prestamoId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _movimientosPrestamoRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PrestamosTercerosTableFilterComposer
    extends Composer<_$AppDatabase, $PrestamosTercerosTable> {
  $$PrestamosTercerosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get persona => $composableBuilder(
    column: $table.persona,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get montoPrincipal => $composableBuilder(
    column: $table.montoPrincipal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fechaEntrega => $composableBuilder(
    column: $table.fechaEntrega,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fechaDevolucionAcordada => $composableBuilder(
    column: $table.fechaDevolucionAcordada,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> movimientosPrestamoRefs(
    Expression<bool> Function($$MovimientosPrestamoTableFilterComposer f) f,
  ) {
    final $$MovimientosPrestamoTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.movimientosPrestamo,
      getReferencedColumn: (t) => t.prestamoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovimientosPrestamoTableFilterComposer(
            $db: $db,
            $table: $db.movimientosPrestamo,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PrestamosTercerosTableOrderingComposer
    extends Composer<_$AppDatabase, $PrestamosTercerosTable> {
  $$PrestamosTercerosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get persona => $composableBuilder(
    column: $table.persona,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get montoPrincipal => $composableBuilder(
    column: $table.montoPrincipal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fechaEntrega => $composableBuilder(
    column: $table.fechaEntrega,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fechaDevolucionAcordada => $composableBuilder(
    column: $table.fechaDevolucionAcordada,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PrestamosTercerosTableAnnotationComposer
    extends Composer<_$AppDatabase, $PrestamosTercerosTable> {
  $$PrestamosTercerosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get persona =>
      $composableBuilder(column: $table.persona, builder: (column) => column);

  GeneratedColumn<double> get montoPrincipal => $composableBuilder(
    column: $table.montoPrincipal,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fechaEntrega => $composableBuilder(
    column: $table.fechaEntrega,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fechaDevolucionAcordada => $composableBuilder(
    column: $table.fechaDevolucionAcordada,
    builder: (column) => column,
  );

  Expression<T> movimientosPrestamoRefs<T extends Object>(
    Expression<T> Function($$MovimientosPrestamoTableAnnotationComposer a) f,
  ) {
    final $$MovimientosPrestamoTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.movimientosPrestamo,
          getReferencedColumn: (t) => t.prestamoId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MovimientosPrestamoTableAnnotationComposer(
                $db: $db,
                $table: $db.movimientosPrestamo,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$PrestamosTercerosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PrestamosTercerosTable,
          PrestamosTercero,
          $$PrestamosTercerosTableFilterComposer,
          $$PrestamosTercerosTableOrderingComposer,
          $$PrestamosTercerosTableAnnotationComposer,
          $$PrestamosTercerosTableCreateCompanionBuilder,
          $$PrestamosTercerosTableUpdateCompanionBuilder,
          (PrestamosTercero, $$PrestamosTercerosTableReferences),
          PrestamosTercero,
          PrefetchHooks Function({bool movimientosPrestamoRefs})
        > {
  $$PrestamosTercerosTableTableManager(
    _$AppDatabase db,
    $PrestamosTercerosTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrestamosTercerosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrestamosTercerosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrestamosTercerosTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> persona = const Value.absent(),
                Value<double> montoPrincipal = const Value.absent(),
                Value<DateTime> fechaEntrega = const Value.absent(),
                Value<DateTime> fechaDevolucionAcordada = const Value.absent(),
              }) => PrestamosTercerosCompanion(
                id: id,
                persona: persona,
                montoPrincipal: montoPrincipal,
                fechaEntrega: fechaEntrega,
                fechaDevolucionAcordada: fechaDevolucionAcordada,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String persona,
                required double montoPrincipal,
                required DateTime fechaEntrega,
                required DateTime fechaDevolucionAcordada,
              }) => PrestamosTercerosCompanion.insert(
                id: id,
                persona: persona,
                montoPrincipal: montoPrincipal,
                fechaEntrega: fechaEntrega,
                fechaDevolucionAcordada: fechaDevolucionAcordada,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PrestamosTercerosTable, PrestamosTercero>(table),
                  $$PrestamosTercerosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({movimientosPrestamoRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (movimientosPrestamoRefs) db.movimientosPrestamo,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (movimientosPrestamoRefs)
                    await $_getPrefetchedData<
                      PrestamosTercero,
                      $PrestamosTercerosTable,
                      MovimientosPrestamoData
                    >(
                      currentTable: table,
                      referencedTable: $$PrestamosTercerosTableReferences
                          ._movimientosPrestamoRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$PrestamosTercerosTableReferences(
                            db,
                            table,
                            p0,
                          ).movimientosPrestamoRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.prestamoId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PrestamosTercerosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PrestamosTercerosTable,
      PrestamosTercero,
      $$PrestamosTercerosTableFilterComposer,
      $$PrestamosTercerosTableOrderingComposer,
      $$PrestamosTercerosTableAnnotationComposer,
      $$PrestamosTercerosTableCreateCompanionBuilder,
      $$PrestamosTercerosTableUpdateCompanionBuilder,
      (PrestamosTercero, $$PrestamosTercerosTableReferences),
      PrestamosTercero,
      PrefetchHooks Function({bool movimientosPrestamoRefs})
    >;
typedef $$MovimientosPrestamoTableCreateCompanionBuilder =
    MovimientosPrestamoCompanion Function({
      Value<int> id,
      required int prestamoId,
      required String tipo,
      required double monto,
      required DateTime fecha,
      required String operationId,
      Value<String?> medio,
    });
typedef $$MovimientosPrestamoTableUpdateCompanionBuilder =
    MovimientosPrestamoCompanion Function({
      Value<int> id,
      Value<int> prestamoId,
      Value<String> tipo,
      Value<double> monto,
      Value<DateTime> fecha,
      Value<String> operationId,
      Value<String?> medio,
    });

final class $$MovimientosPrestamoTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $MovimientosPrestamoTable,
          MovimientosPrestamoData
        > {
  $$MovimientosPrestamoTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PrestamosTercerosTable _prestamoIdTable(_$AppDatabase db) => db
      .prestamosTerceros
      .createAlias('movimientos_prestamo__prestamo_id__prestamos_terceros__id');

  $$PrestamosTercerosTableProcessedTableManager get prestamoId {
    final $_column = $_itemColumn<int>('prestamo_id')!;

    final manager = $$PrestamosTercerosTableTableManager(
      $_db,
      $_db.prestamosTerceros,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_prestamoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MovimientosPrestamoTableFilterComposer
    extends Composer<_$AppDatabase, $MovimientosPrestamoTable> {
  $$MovimientosPrestamoTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get monto => $composableBuilder(
    column: $table.monto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get medio => $composableBuilder(
    column: $table.medio,
    builder: (column) => ColumnFilters(column),
  );

  $$PrestamosTercerosTableFilterComposer get prestamoId {
    final $$PrestamosTercerosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.prestamoId,
      referencedTable: $db.prestamosTerceros,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PrestamosTercerosTableFilterComposer(
            $db: $db,
            $table: $db.prestamosTerceros,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MovimientosPrestamoTableOrderingComposer
    extends Composer<_$AppDatabase, $MovimientosPrestamoTable> {
  $$MovimientosPrestamoTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get monto => $composableBuilder(
    column: $table.monto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medio => $composableBuilder(
    column: $table.medio,
    builder: (column) => ColumnOrderings(column),
  );

  $$PrestamosTercerosTableOrderingComposer get prestamoId {
    final $$PrestamosTercerosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.prestamoId,
      referencedTable: $db.prestamosTerceros,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PrestamosTercerosTableOrderingComposer(
            $db: $db,
            $table: $db.prestamosTerceros,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MovimientosPrestamoTableAnnotationComposer
    extends Composer<_$AppDatabase, $MovimientosPrestamoTable> {
  $$MovimientosPrestamoTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<double> get monto =>
      $composableBuilder(column: $table.monto, builder: (column) => column);

  GeneratedColumn<DateTime> get fecha =>
      $composableBuilder(column: $table.fecha, builder: (column) => column);

  GeneratedColumn<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get medio =>
      $composableBuilder(column: $table.medio, builder: (column) => column);

  $$PrestamosTercerosTableAnnotationComposer get prestamoId {
    final $$PrestamosTercerosTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.prestamoId,
          referencedTable: $db.prestamosTerceros,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PrestamosTercerosTableAnnotationComposer(
                $db: $db,
                $table: $db.prestamosTerceros,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$MovimientosPrestamoTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MovimientosPrestamoTable,
          MovimientosPrestamoData,
          $$MovimientosPrestamoTableFilterComposer,
          $$MovimientosPrestamoTableOrderingComposer,
          $$MovimientosPrestamoTableAnnotationComposer,
          $$MovimientosPrestamoTableCreateCompanionBuilder,
          $$MovimientosPrestamoTableUpdateCompanionBuilder,
          (MovimientosPrestamoData, $$MovimientosPrestamoTableReferences),
          MovimientosPrestamoData,
          PrefetchHooks Function({bool prestamoId})
        > {
  $$MovimientosPrestamoTableTableManager(
    _$AppDatabase db,
    $MovimientosPrestamoTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MovimientosPrestamoTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MovimientosPrestamoTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MovimientosPrestamoTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> prestamoId = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<double> monto = const Value.absent(),
                Value<DateTime> fecha = const Value.absent(),
                Value<String> operationId = const Value.absent(),
                Value<String?> medio = const Value.absent(),
              }) => MovimientosPrestamoCompanion(
                id: id,
                prestamoId: prestamoId,
                tipo: tipo,
                monto: monto,
                fecha: fecha,
                operationId: operationId,
                medio: medio,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int prestamoId,
                required String tipo,
                required double monto,
                required DateTime fecha,
                required String operationId,
                Value<String?> medio = const Value.absent(),
              }) => MovimientosPrestamoCompanion.insert(
                id: id,
                prestamoId: prestamoId,
                tipo: tipo,
                monto: monto,
                fecha: fecha,
                operationId: operationId,
                medio: medio,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $MovimientosPrestamoTable,
                    MovimientosPrestamoData
                  >(table),
                  $$MovimientosPrestamoTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({prestamoId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (prestamoId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.prestamoId,
                                referencedTable:
                                    $$MovimientosPrestamoTableReferences
                                        ._prestamoIdTable(db),
                                referencedColumn:
                                    $$MovimientosPrestamoTableReferences
                                        ._prestamoIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MovimientosPrestamoTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MovimientosPrestamoTable,
      MovimientosPrestamoData,
      $$MovimientosPrestamoTableFilterComposer,
      $$MovimientosPrestamoTableOrderingComposer,
      $$MovimientosPrestamoTableAnnotationComposer,
      $$MovimientosPrestamoTableCreateCompanionBuilder,
      $$MovimientosPrestamoTableUpdateCompanionBuilder,
      (MovimientosPrestamoData, $$MovimientosPrestamoTableReferences),
      MovimientosPrestamoData,
      PrefetchHooks Function({bool prestamoId})
    >;
typedef $$GastosFuturosTableCreateCompanionBuilder =
    GastosFuturosCompanion Function({
      Value<int> id,
      required String nombre,
      required String categoria,
      required double montoNecesario,
      required double montoPlaneado,
      required String frecuencia,
      required DateTime fechaObjetivo,
      Value<DateTime?> fechaInicio,
      Value<String?> notas,
      Value<String> estado,
    });
typedef $$GastosFuturosTableUpdateCompanionBuilder =
    GastosFuturosCompanion Function({
      Value<int> id,
      Value<String> nombre,
      Value<String> categoria,
      Value<double> montoNecesario,
      Value<double> montoPlaneado,
      Value<String> frecuencia,
      Value<DateTime> fechaObjetivo,
      Value<DateTime?> fechaInicio,
      Value<String?> notas,
      Value<String> estado,
    });

final class $$GastosFuturosTableReferences
    extends BaseReferences<_$AppDatabase, $GastosFuturosTable, GastosFuturo> {
  $$GastosFuturosTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $MovimientosReservaGastoFuturoTable,
    List<MovimientosReservaGastoFuturoData>
  >
  _movimientosReservaGastoFuturoRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.movimientosReservaGastoFuturo,
    aliasName:
        'gastos_futuros__id__movimientos_reserva_gasto_futuro__gasto_futuro_id',
  );

  $$MovimientosReservaGastoFuturoTableProcessedTableManager
  get movimientosReservaGastoFuturoRefs {
    final manager = $$MovimientosReservaGastoFuturoTableTableManager(
      $_db,
      $_db.movimientosReservaGastoFuturo,
    ).filter((f) => f.gastoFuturoId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _movimientosReservaGastoFuturoRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$GastosFuturosTableFilterComposer
    extends Composer<_$AppDatabase, $GastosFuturosTable> {
  $$GastosFuturosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoria => $composableBuilder(
    column: $table.categoria,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get montoNecesario => $composableBuilder(
    column: $table.montoNecesario,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get montoPlaneado => $composableBuilder(
    column: $table.montoPlaneado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frecuencia => $composableBuilder(
    column: $table.frecuencia,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fechaObjetivo => $composableBuilder(
    column: $table.fechaObjetivo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fechaInicio => $composableBuilder(
    column: $table.fechaInicio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notas => $composableBuilder(
    column: $table.notas,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> movimientosReservaGastoFuturoRefs(
    Expression<bool> Function(
      $$MovimientosReservaGastoFuturoTableFilterComposer f,
    )
    f,
  ) {
    final $$MovimientosReservaGastoFuturoTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.movimientosReservaGastoFuturo,
          getReferencedColumn: (t) => t.gastoFuturoId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MovimientosReservaGastoFuturoTableFilterComposer(
                $db: $db,
                $table: $db.movimientosReservaGastoFuturo,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$GastosFuturosTableOrderingComposer
    extends Composer<_$AppDatabase, $GastosFuturosTable> {
  $$GastosFuturosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoria => $composableBuilder(
    column: $table.categoria,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get montoNecesario => $composableBuilder(
    column: $table.montoNecesario,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get montoPlaneado => $composableBuilder(
    column: $table.montoPlaneado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frecuencia => $composableBuilder(
    column: $table.frecuencia,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fechaObjetivo => $composableBuilder(
    column: $table.fechaObjetivo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fechaInicio => $composableBuilder(
    column: $table.fechaInicio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notas => $composableBuilder(
    column: $table.notas,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GastosFuturosTableAnnotationComposer
    extends Composer<_$AppDatabase, $GastosFuturosTable> {
  $$GastosFuturosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get categoria =>
      $composableBuilder(column: $table.categoria, builder: (column) => column);

  GeneratedColumn<double> get montoNecesario => $composableBuilder(
    column: $table.montoNecesario,
    builder: (column) => column,
  );

  GeneratedColumn<double> get montoPlaneado => $composableBuilder(
    column: $table.montoPlaneado,
    builder: (column) => column,
  );

  GeneratedColumn<String> get frecuencia => $composableBuilder(
    column: $table.frecuencia,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fechaObjetivo => $composableBuilder(
    column: $table.fechaObjetivo,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fechaInicio => $composableBuilder(
    column: $table.fechaInicio,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notas =>
      $composableBuilder(column: $table.notas, builder: (column) => column);

  GeneratedColumn<String> get estado =>
      $composableBuilder(column: $table.estado, builder: (column) => column);

  Expression<T> movimientosReservaGastoFuturoRefs<T extends Object>(
    Expression<T> Function(
      $$MovimientosReservaGastoFuturoTableAnnotationComposer a,
    )
    f,
  ) {
    final $$MovimientosReservaGastoFuturoTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.movimientosReservaGastoFuturo,
          getReferencedColumn: (t) => t.gastoFuturoId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MovimientosReservaGastoFuturoTableAnnotationComposer(
                $db: $db,
                $table: $db.movimientosReservaGastoFuturo,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$GastosFuturosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GastosFuturosTable,
          GastosFuturo,
          $$GastosFuturosTableFilterComposer,
          $$GastosFuturosTableOrderingComposer,
          $$GastosFuturosTableAnnotationComposer,
          $$GastosFuturosTableCreateCompanionBuilder,
          $$GastosFuturosTableUpdateCompanionBuilder,
          (GastosFuturo, $$GastosFuturosTableReferences),
          GastosFuturo,
          PrefetchHooks Function({bool movimientosReservaGastoFuturoRefs})
        > {
  $$GastosFuturosTableTableManager(_$AppDatabase db, $GastosFuturosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GastosFuturosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GastosFuturosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GastosFuturosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<String> categoria = const Value.absent(),
                Value<double> montoNecesario = const Value.absent(),
                Value<double> montoPlaneado = const Value.absent(),
                Value<String> frecuencia = const Value.absent(),
                Value<DateTime> fechaObjetivo = const Value.absent(),
                Value<DateTime?> fechaInicio = const Value.absent(),
                Value<String?> notas = const Value.absent(),
                Value<String> estado = const Value.absent(),
              }) => GastosFuturosCompanion(
                id: id,
                nombre: nombre,
                categoria: categoria,
                montoNecesario: montoNecesario,
                montoPlaneado: montoPlaneado,
                frecuencia: frecuencia,
                fechaObjetivo: fechaObjetivo,
                fechaInicio: fechaInicio,
                notas: notas,
                estado: estado,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String nombre,
                required String categoria,
                required double montoNecesario,
                required double montoPlaneado,
                required String frecuencia,
                required DateTime fechaObjetivo,
                Value<DateTime?> fechaInicio = const Value.absent(),
                Value<String?> notas = const Value.absent(),
                Value<String> estado = const Value.absent(),
              }) => GastosFuturosCompanion.insert(
                id: id,
                nombre: nombre,
                categoria: categoria,
                montoNecesario: montoNecesario,
                montoPlaneado: montoPlaneado,
                frecuencia: frecuencia,
                fechaObjetivo: fechaObjetivo,
                fechaInicio: fechaInicio,
                notas: notas,
                estado: estado,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GastosFuturosTable, GastosFuturo>(table),
                  $$GastosFuturosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({movimientosReservaGastoFuturoRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (movimientosReservaGastoFuturoRefs)
                  db.movimientosReservaGastoFuturo,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (movimientosReservaGastoFuturoRefs)
                    await $_getPrefetchedData<
                      GastosFuturo,
                      $GastosFuturosTable,
                      MovimientosReservaGastoFuturoData
                    >(
                      currentTable: table,
                      referencedTable: $$GastosFuturosTableReferences
                          ._movimientosReservaGastoFuturoRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$GastosFuturosTableReferences(
                            db,
                            table,
                            p0,
                          ).movimientosReservaGastoFuturoRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.gastoFuturoId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$GastosFuturosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GastosFuturosTable,
      GastosFuturo,
      $$GastosFuturosTableFilterComposer,
      $$GastosFuturosTableOrderingComposer,
      $$GastosFuturosTableAnnotationComposer,
      $$GastosFuturosTableCreateCompanionBuilder,
      $$GastosFuturosTableUpdateCompanionBuilder,
      (GastosFuturo, $$GastosFuturosTableReferences),
      GastosFuturo,
      PrefetchHooks Function({bool movimientosReservaGastoFuturoRefs})
    >;
typedef $$MovimientosReservaGastoFuturoTableCreateCompanionBuilder =
    MovimientosReservaGastoFuturoCompanion Function({
      Value<int> id,
      Value<int?> gastoFuturoId,
      required String nombrePlan,
      required String tipo,
      required double monto,
      required DateTime fecha,
      required String operationId,
      Value<String?> medio,
    });
typedef $$MovimientosReservaGastoFuturoTableUpdateCompanionBuilder =
    MovimientosReservaGastoFuturoCompanion Function({
      Value<int> id,
      Value<int?> gastoFuturoId,
      Value<String> nombrePlan,
      Value<String> tipo,
      Value<double> monto,
      Value<DateTime> fecha,
      Value<String> operationId,
      Value<String?> medio,
    });

final class $$MovimientosReservaGastoFuturoTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $MovimientosReservaGastoFuturoTable,
          MovimientosReservaGastoFuturoData
        > {
  $$MovimientosReservaGastoFuturoTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $GastosFuturosTable _gastoFuturoIdTable(_$AppDatabase db) =>
      db.gastosFuturos.createAlias(
        'movimientos_reserva_gasto_futuro__gasto_futuro_id__gastos_futuros__id',
      );

  $$GastosFuturosTableProcessedTableManager? get gastoFuturoId {
    final $_column = $_itemColumn<int>('gasto_futuro_id');
    if ($_column == null) return null;
    final manager = $$GastosFuturosTableTableManager(
      $_db,
      $_db.gastosFuturos,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_gastoFuturoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MovimientosReservaGastoFuturoTableFilterComposer
    extends Composer<_$AppDatabase, $MovimientosReservaGastoFuturoTable> {
  $$MovimientosReservaGastoFuturoTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombrePlan => $composableBuilder(
    column: $table.nombrePlan,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get monto => $composableBuilder(
    column: $table.monto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get medio => $composableBuilder(
    column: $table.medio,
    builder: (column) => ColumnFilters(column),
  );

  $$GastosFuturosTableFilterComposer get gastoFuturoId {
    final $$GastosFuturosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gastoFuturoId,
      referencedTable: $db.gastosFuturos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GastosFuturosTableFilterComposer(
            $db: $db,
            $table: $db.gastosFuturos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MovimientosReservaGastoFuturoTableOrderingComposer
    extends Composer<_$AppDatabase, $MovimientosReservaGastoFuturoTable> {
  $$MovimientosReservaGastoFuturoTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombrePlan => $composableBuilder(
    column: $table.nombrePlan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get monto => $composableBuilder(
    column: $table.monto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medio => $composableBuilder(
    column: $table.medio,
    builder: (column) => ColumnOrderings(column),
  );

  $$GastosFuturosTableOrderingComposer get gastoFuturoId {
    final $$GastosFuturosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gastoFuturoId,
      referencedTable: $db.gastosFuturos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GastosFuturosTableOrderingComposer(
            $db: $db,
            $table: $db.gastosFuturos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MovimientosReservaGastoFuturoTableAnnotationComposer
    extends Composer<_$AppDatabase, $MovimientosReservaGastoFuturoTable> {
  $$MovimientosReservaGastoFuturoTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nombrePlan => $composableBuilder(
    column: $table.nombrePlan,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<double> get monto =>
      $composableBuilder(column: $table.monto, builder: (column) => column);

  GeneratedColumn<DateTime> get fecha =>
      $composableBuilder(column: $table.fecha, builder: (column) => column);

  GeneratedColumn<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get medio =>
      $composableBuilder(column: $table.medio, builder: (column) => column);

  $$GastosFuturosTableAnnotationComposer get gastoFuturoId {
    final $$GastosFuturosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gastoFuturoId,
      referencedTable: $db.gastosFuturos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GastosFuturosTableAnnotationComposer(
            $db: $db,
            $table: $db.gastosFuturos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MovimientosReservaGastoFuturoTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MovimientosReservaGastoFuturoTable,
          MovimientosReservaGastoFuturoData,
          $$MovimientosReservaGastoFuturoTableFilterComposer,
          $$MovimientosReservaGastoFuturoTableOrderingComposer,
          $$MovimientosReservaGastoFuturoTableAnnotationComposer,
          $$MovimientosReservaGastoFuturoTableCreateCompanionBuilder,
          $$MovimientosReservaGastoFuturoTableUpdateCompanionBuilder,
          (
            MovimientosReservaGastoFuturoData,
            $$MovimientosReservaGastoFuturoTableReferences,
          ),
          MovimientosReservaGastoFuturoData,
          PrefetchHooks Function({bool gastoFuturoId})
        > {
  $$MovimientosReservaGastoFuturoTableTableManager(
    _$AppDatabase db,
    $MovimientosReservaGastoFuturoTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MovimientosReservaGastoFuturoTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$MovimientosReservaGastoFuturoTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MovimientosReservaGastoFuturoTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> gastoFuturoId = const Value.absent(),
                Value<String> nombrePlan = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<double> monto = const Value.absent(),
                Value<DateTime> fecha = const Value.absent(),
                Value<String> operationId = const Value.absent(),
                Value<String?> medio = const Value.absent(),
              }) => MovimientosReservaGastoFuturoCompanion(
                id: id,
                gastoFuturoId: gastoFuturoId,
                nombrePlan: nombrePlan,
                tipo: tipo,
                monto: monto,
                fecha: fecha,
                operationId: operationId,
                medio: medio,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> gastoFuturoId = const Value.absent(),
                required String nombrePlan,
                required String tipo,
                required double monto,
                required DateTime fecha,
                required String operationId,
                Value<String?> medio = const Value.absent(),
              }) => MovimientosReservaGastoFuturoCompanion.insert(
                id: id,
                gastoFuturoId: gastoFuturoId,
                nombrePlan: nombrePlan,
                tipo: tipo,
                monto: monto,
                fecha: fecha,
                operationId: operationId,
                medio: medio,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $MovimientosReservaGastoFuturoTable,
                    MovimientosReservaGastoFuturoData
                  >(table),
                  $$MovimientosReservaGastoFuturoTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({gastoFuturoId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (gastoFuturoId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.gastoFuturoId,
                                referencedTable:
                                    $$MovimientosReservaGastoFuturoTableReferences
                                        ._gastoFuturoIdTable(db),
                                referencedColumn:
                                    $$MovimientosReservaGastoFuturoTableReferences
                                        ._gastoFuturoIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MovimientosReservaGastoFuturoTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MovimientosReservaGastoFuturoTable,
      MovimientosReservaGastoFuturoData,
      $$MovimientosReservaGastoFuturoTableFilterComposer,
      $$MovimientosReservaGastoFuturoTableOrderingComposer,
      $$MovimientosReservaGastoFuturoTableAnnotationComposer,
      $$MovimientosReservaGastoFuturoTableCreateCompanionBuilder,
      $$MovimientosReservaGastoFuturoTableUpdateCompanionBuilder,
      (
        MovimientosReservaGastoFuturoData,
        $$MovimientosReservaGastoFuturoTableReferences,
      ),
      MovimientosReservaGastoFuturoData,
      PrefetchHooks Function({bool gastoFuturoId})
    >;
typedef $$AsignacionesDineroTableCreateCompanionBuilder =
    AsignacionesDineroCompanion Function({
      Value<int> id,
      required String medio,
      required double monto,
      Value<int?> cuentaDigitalId,
      Value<String?> origen,
      Value<int?> origenId,
    });
typedef $$AsignacionesDineroTableUpdateCompanionBuilder =
    AsignacionesDineroCompanion Function({
      Value<int> id,
      Value<String> medio,
      Value<double> monto,
      Value<int?> cuentaDigitalId,
      Value<String?> origen,
      Value<int?> origenId,
    });

final class $$AsignacionesDineroTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $AsignacionesDineroTable,
          AsignacionesDineroData
        > {
  $$AsignacionesDineroTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CuentasDigitalesTable _cuentaDigitalIdTable(_$AppDatabase db) =>
      db.cuentasDigitales.createAlias(
        'asignaciones_dinero__cuenta_digital_id__cuentas_digitales__id',
      );

  $$CuentasDigitalesTableProcessedTableManager? get cuentaDigitalId {
    final $_column = $_itemColumn<int>('cuenta_digital_id');
    if ($_column == null) return null;
    final manager = $$CuentasDigitalesTableTableManager(
      $_db,
      $_db.cuentasDigitales,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cuentaDigitalIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AsignacionesDineroTableFilterComposer
    extends Composer<_$AppDatabase, $AsignacionesDineroTable> {
  $$AsignacionesDineroTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get medio => $composableBuilder(
    column: $table.medio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get monto => $composableBuilder(
    column: $table.monto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origen => $composableBuilder(
    column: $table.origen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get origenId => $composableBuilder(
    column: $table.origenId,
    builder: (column) => ColumnFilters(column),
  );

  $$CuentasDigitalesTableFilterComposer get cuentaDigitalId {
    final $$CuentasDigitalesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cuentaDigitalId,
      referencedTable: $db.cuentasDigitales,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CuentasDigitalesTableFilterComposer(
            $db: $db,
            $table: $db.cuentasDigitales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AsignacionesDineroTableOrderingComposer
    extends Composer<_$AppDatabase, $AsignacionesDineroTable> {
  $$AsignacionesDineroTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medio => $composableBuilder(
    column: $table.medio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get monto => $composableBuilder(
    column: $table.monto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origen => $composableBuilder(
    column: $table.origen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get origenId => $composableBuilder(
    column: $table.origenId,
    builder: (column) => ColumnOrderings(column),
  );

  $$CuentasDigitalesTableOrderingComposer get cuentaDigitalId {
    final $$CuentasDigitalesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cuentaDigitalId,
      referencedTable: $db.cuentasDigitales,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CuentasDigitalesTableOrderingComposer(
            $db: $db,
            $table: $db.cuentasDigitales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AsignacionesDineroTableAnnotationComposer
    extends Composer<_$AppDatabase, $AsignacionesDineroTable> {
  $$AsignacionesDineroTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get medio =>
      $composableBuilder(column: $table.medio, builder: (column) => column);

  GeneratedColumn<double> get monto =>
      $composableBuilder(column: $table.monto, builder: (column) => column);

  GeneratedColumn<String> get origen =>
      $composableBuilder(column: $table.origen, builder: (column) => column);

  GeneratedColumn<int> get origenId =>
      $composableBuilder(column: $table.origenId, builder: (column) => column);

  $$CuentasDigitalesTableAnnotationComposer get cuentaDigitalId {
    final $$CuentasDigitalesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cuentaDigitalId,
      referencedTable: $db.cuentasDigitales,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CuentasDigitalesTableAnnotationComposer(
            $db: $db,
            $table: $db.cuentasDigitales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AsignacionesDineroTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AsignacionesDineroTable,
          AsignacionesDineroData,
          $$AsignacionesDineroTableFilterComposer,
          $$AsignacionesDineroTableOrderingComposer,
          $$AsignacionesDineroTableAnnotationComposer,
          $$AsignacionesDineroTableCreateCompanionBuilder,
          $$AsignacionesDineroTableUpdateCompanionBuilder,
          (AsignacionesDineroData, $$AsignacionesDineroTableReferences),
          AsignacionesDineroData,
          PrefetchHooks Function({bool cuentaDigitalId})
        > {
  $$AsignacionesDineroTableTableManager(
    _$AppDatabase db,
    $AsignacionesDineroTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AsignacionesDineroTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AsignacionesDineroTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AsignacionesDineroTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> medio = const Value.absent(),
                Value<double> monto = const Value.absent(),
                Value<int?> cuentaDigitalId = const Value.absent(),
                Value<String?> origen = const Value.absent(),
                Value<int?> origenId = const Value.absent(),
              }) => AsignacionesDineroCompanion(
                id: id,
                medio: medio,
                monto: monto,
                cuentaDigitalId: cuentaDigitalId,
                origen: origen,
                origenId: origenId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String medio,
                required double monto,
                Value<int?> cuentaDigitalId = const Value.absent(),
                Value<String?> origen = const Value.absent(),
                Value<int?> origenId = const Value.absent(),
              }) => AsignacionesDineroCompanion.insert(
                id: id,
                medio: medio,
                monto: monto,
                cuentaDigitalId: cuentaDigitalId,
                origen: origen,
                origenId: origenId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AsignacionesDineroTable, AsignacionesDineroData>(
                    table,
                  ),
                  $$AsignacionesDineroTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({cuentaDigitalId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (cuentaDigitalId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.cuentaDigitalId,
                                referencedTable:
                                    $$AsignacionesDineroTableReferences
                                        ._cuentaDigitalIdTable(db),
                                referencedColumn:
                                    $$AsignacionesDineroTableReferences
                                        ._cuentaDigitalIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AsignacionesDineroTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AsignacionesDineroTable,
      AsignacionesDineroData,
      $$AsignacionesDineroTableFilterComposer,
      $$AsignacionesDineroTableOrderingComposer,
      $$AsignacionesDineroTableAnnotationComposer,
      $$AsignacionesDineroTableCreateCompanionBuilder,
      $$AsignacionesDineroTableUpdateCompanionBuilder,
      (AsignacionesDineroData, $$AsignacionesDineroTableReferences),
      AsignacionesDineroData,
      PrefetchHooks Function({bool cuentaDigitalId})
    >;
typedef $$IngresoDistribucionesTableCreateCompanionBuilder =
    IngresoDistribucionesCompanion Function({
      Value<int> id,
      required int ingresoId,
      required String medio,
      required double monto,
      Value<int?> cuentaDigitalId,
    });
typedef $$IngresoDistribucionesTableUpdateCompanionBuilder =
    IngresoDistribucionesCompanion Function({
      Value<int> id,
      Value<int> ingresoId,
      Value<String> medio,
      Value<double> monto,
      Value<int?> cuentaDigitalId,
    });

final class $$IngresoDistribucionesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $IngresoDistribucionesTable,
          IngresoDistribucione
        > {
  $$IngresoDistribucionesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $IngresosTable _ingresoIdTable(_$AppDatabase db) => db.ingresos
      .createAlias('ingreso_distribuciones__ingreso_id__ingresos__id');

  $$IngresosTableProcessedTableManager get ingresoId {
    final $_column = $_itemColumn<int>('ingreso_id')!;

    final manager = $$IngresosTableTableManager(
      $_db,
      $_db.ingresos,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ingresoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CuentasDigitalesTable _cuentaDigitalIdTable(_$AppDatabase db) =>
      db.cuentasDigitales.createAlias(
        'ingreso_distribuciones__cuenta_digital_id__cuentas_digitales__id',
      );

  $$CuentasDigitalesTableProcessedTableManager? get cuentaDigitalId {
    final $_column = $_itemColumn<int>('cuenta_digital_id');
    if ($_column == null) return null;
    final manager = $$CuentasDigitalesTableTableManager(
      $_db,
      $_db.cuentasDigitales,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cuentaDigitalIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$IngresoDistribucionesTableFilterComposer
    extends Composer<_$AppDatabase, $IngresoDistribucionesTable> {
  $$IngresoDistribucionesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get medio => $composableBuilder(
    column: $table.medio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get monto => $composableBuilder(
    column: $table.monto,
    builder: (column) => ColumnFilters(column),
  );

  $$IngresosTableFilterComposer get ingresoId {
    final $$IngresosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ingresoId,
      referencedTable: $db.ingresos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IngresosTableFilterComposer(
            $db: $db,
            $table: $db.ingresos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CuentasDigitalesTableFilterComposer get cuentaDigitalId {
    final $$CuentasDigitalesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cuentaDigitalId,
      referencedTable: $db.cuentasDigitales,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CuentasDigitalesTableFilterComposer(
            $db: $db,
            $table: $db.cuentasDigitales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IngresoDistribucionesTableOrderingComposer
    extends Composer<_$AppDatabase, $IngresoDistribucionesTable> {
  $$IngresoDistribucionesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medio => $composableBuilder(
    column: $table.medio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get monto => $composableBuilder(
    column: $table.monto,
    builder: (column) => ColumnOrderings(column),
  );

  $$IngresosTableOrderingComposer get ingresoId {
    final $$IngresosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ingresoId,
      referencedTable: $db.ingresos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IngresosTableOrderingComposer(
            $db: $db,
            $table: $db.ingresos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CuentasDigitalesTableOrderingComposer get cuentaDigitalId {
    final $$CuentasDigitalesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cuentaDigitalId,
      referencedTable: $db.cuentasDigitales,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CuentasDigitalesTableOrderingComposer(
            $db: $db,
            $table: $db.cuentasDigitales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IngresoDistribucionesTableAnnotationComposer
    extends Composer<_$AppDatabase, $IngresoDistribucionesTable> {
  $$IngresoDistribucionesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get medio =>
      $composableBuilder(column: $table.medio, builder: (column) => column);

  GeneratedColumn<double> get monto =>
      $composableBuilder(column: $table.monto, builder: (column) => column);

  $$IngresosTableAnnotationComposer get ingresoId {
    final $$IngresosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ingresoId,
      referencedTable: $db.ingresos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IngresosTableAnnotationComposer(
            $db: $db,
            $table: $db.ingresos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CuentasDigitalesTableAnnotationComposer get cuentaDigitalId {
    final $$CuentasDigitalesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cuentaDigitalId,
      referencedTable: $db.cuentasDigitales,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CuentasDigitalesTableAnnotationComposer(
            $db: $db,
            $table: $db.cuentasDigitales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IngresoDistribucionesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IngresoDistribucionesTable,
          IngresoDistribucione,
          $$IngresoDistribucionesTableFilterComposer,
          $$IngresoDistribucionesTableOrderingComposer,
          $$IngresoDistribucionesTableAnnotationComposer,
          $$IngresoDistribucionesTableCreateCompanionBuilder,
          $$IngresoDistribucionesTableUpdateCompanionBuilder,
          (IngresoDistribucione, $$IngresoDistribucionesTableReferences),
          IngresoDistribucione,
          PrefetchHooks Function({bool ingresoId, bool cuentaDigitalId})
        > {
  $$IngresoDistribucionesTableTableManager(
    _$AppDatabase db,
    $IngresoDistribucionesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IngresoDistribucionesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$IngresoDistribucionesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$IngresoDistribucionesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> ingresoId = const Value.absent(),
                Value<String> medio = const Value.absent(),
                Value<double> monto = const Value.absent(),
                Value<int?> cuentaDigitalId = const Value.absent(),
              }) => IngresoDistribucionesCompanion(
                id: id,
                ingresoId: ingresoId,
                medio: medio,
                monto: monto,
                cuentaDigitalId: cuentaDigitalId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int ingresoId,
                required String medio,
                required double monto,
                Value<int?> cuentaDigitalId = const Value.absent(),
              }) => IngresoDistribucionesCompanion.insert(
                id: id,
                ingresoId: ingresoId,
                medio: medio,
                monto: monto,
                cuentaDigitalId: cuentaDigitalId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $IngresoDistribucionesTable,
                    IngresoDistribucione
                  >(table),
                  $$IngresoDistribucionesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({ingresoId = false, cuentaDigitalId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (ingresoId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.ingresoId,
                                    referencedTable:
                                        $$IngresoDistribucionesTableReferences
                                            ._ingresoIdTable(db),
                                    referencedColumn:
                                        $$IngresoDistribucionesTableReferences
                                            ._ingresoIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (cuentaDigitalId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.cuentaDigitalId,
                                    referencedTable:
                                        $$IngresoDistribucionesTableReferences
                                            ._cuentaDigitalIdTable(db),
                                    referencedColumn:
                                        $$IngresoDistribucionesTableReferences
                                            ._cuentaDigitalIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$IngresoDistribucionesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IngresoDistribucionesTable,
      IngresoDistribucione,
      $$IngresoDistribucionesTableFilterComposer,
      $$IngresoDistribucionesTableOrderingComposer,
      $$IngresoDistribucionesTableAnnotationComposer,
      $$IngresoDistribucionesTableCreateCompanionBuilder,
      $$IngresoDistribucionesTableUpdateCompanionBuilder,
      (IngresoDistribucione, $$IngresoDistribucionesTableReferences),
      IngresoDistribucione,
      PrefetchHooks Function({bool ingresoId, bool cuentaDigitalId})
    >;
typedef $$TransferenciasDineroTableCreateCompanionBuilder =
    TransferenciasDineroCompanion Function({
      Value<int> id,
      required String medioOrigen,
      Value<int?> cuentaOrigenId,
      required String medioDestino,
      Value<int?> cuentaDestinoId,
      required double monto,
      required DateTime fecha,
      Value<String?> nota,
    });
typedef $$TransferenciasDineroTableUpdateCompanionBuilder =
    TransferenciasDineroCompanion Function({
      Value<int> id,
      Value<String> medioOrigen,
      Value<int?> cuentaOrigenId,
      Value<String> medioDestino,
      Value<int?> cuentaDestinoId,
      Value<double> monto,
      Value<DateTime> fecha,
      Value<String?> nota,
    });

final class $$TransferenciasDineroTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TransferenciasDineroTable,
          TransferenciasDineroData
        > {
  $$TransferenciasDineroTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CuentasDigitalesTable _cuentaOrigenIdTable(_$AppDatabase db) =>
      db.cuentasDigitales.createAlias(
        'transferencias_dinero__cuenta_origen_id__cuentas_digitales__id',
      );

  $$CuentasDigitalesTableProcessedTableManager? get cuentaOrigenId {
    final $_column = $_itemColumn<int>('cuenta_origen_id');
    if ($_column == null) return null;
    final manager = $$CuentasDigitalesTableTableManager(
      $_db,
      $_db.cuentasDigitales,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cuentaOrigenIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CuentasDigitalesTable _cuentaDestinoIdTable(_$AppDatabase db) =>
      db.cuentasDigitales.createAlias(
        'transferencias_dinero__cuenta_destino_id__cuentas_digitales__id',
      );

  $$CuentasDigitalesTableProcessedTableManager? get cuentaDestinoId {
    final $_column = $_itemColumn<int>('cuenta_destino_id');
    if ($_column == null) return null;
    final manager = $$CuentasDigitalesTableTableManager(
      $_db,
      $_db.cuentasDigitales,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cuentaDestinoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TransferenciasDineroTableFilterComposer
    extends Composer<_$AppDatabase, $TransferenciasDineroTable> {
  $$TransferenciasDineroTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get medioOrigen => $composableBuilder(
    column: $table.medioOrigen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get medioDestino => $composableBuilder(
    column: $table.medioDestino,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get monto => $composableBuilder(
    column: $table.monto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nota => $composableBuilder(
    column: $table.nota,
    builder: (column) => ColumnFilters(column),
  );

  $$CuentasDigitalesTableFilterComposer get cuentaOrigenId {
    final $$CuentasDigitalesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cuentaOrigenId,
      referencedTable: $db.cuentasDigitales,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CuentasDigitalesTableFilterComposer(
            $db: $db,
            $table: $db.cuentasDigitales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CuentasDigitalesTableFilterComposer get cuentaDestinoId {
    final $$CuentasDigitalesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cuentaDestinoId,
      referencedTable: $db.cuentasDigitales,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CuentasDigitalesTableFilterComposer(
            $db: $db,
            $table: $db.cuentasDigitales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransferenciasDineroTableOrderingComposer
    extends Composer<_$AppDatabase, $TransferenciasDineroTable> {
  $$TransferenciasDineroTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medioOrigen => $composableBuilder(
    column: $table.medioOrigen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medioDestino => $composableBuilder(
    column: $table.medioDestino,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get monto => $composableBuilder(
    column: $table.monto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nota => $composableBuilder(
    column: $table.nota,
    builder: (column) => ColumnOrderings(column),
  );

  $$CuentasDigitalesTableOrderingComposer get cuentaOrigenId {
    final $$CuentasDigitalesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cuentaOrigenId,
      referencedTable: $db.cuentasDigitales,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CuentasDigitalesTableOrderingComposer(
            $db: $db,
            $table: $db.cuentasDigitales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CuentasDigitalesTableOrderingComposer get cuentaDestinoId {
    final $$CuentasDigitalesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cuentaDestinoId,
      referencedTable: $db.cuentasDigitales,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CuentasDigitalesTableOrderingComposer(
            $db: $db,
            $table: $db.cuentasDigitales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransferenciasDineroTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransferenciasDineroTable> {
  $$TransferenciasDineroTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get medioOrigen => $composableBuilder(
    column: $table.medioOrigen,
    builder: (column) => column,
  );

  GeneratedColumn<String> get medioDestino => $composableBuilder(
    column: $table.medioDestino,
    builder: (column) => column,
  );

  GeneratedColumn<double> get monto =>
      $composableBuilder(column: $table.monto, builder: (column) => column);

  GeneratedColumn<DateTime> get fecha =>
      $composableBuilder(column: $table.fecha, builder: (column) => column);

  GeneratedColumn<String> get nota =>
      $composableBuilder(column: $table.nota, builder: (column) => column);

  $$CuentasDigitalesTableAnnotationComposer get cuentaOrigenId {
    final $$CuentasDigitalesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cuentaOrigenId,
      referencedTable: $db.cuentasDigitales,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CuentasDigitalesTableAnnotationComposer(
            $db: $db,
            $table: $db.cuentasDigitales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CuentasDigitalesTableAnnotationComposer get cuentaDestinoId {
    final $$CuentasDigitalesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cuentaDestinoId,
      referencedTable: $db.cuentasDigitales,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CuentasDigitalesTableAnnotationComposer(
            $db: $db,
            $table: $db.cuentasDigitales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransferenciasDineroTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransferenciasDineroTable,
          TransferenciasDineroData,
          $$TransferenciasDineroTableFilterComposer,
          $$TransferenciasDineroTableOrderingComposer,
          $$TransferenciasDineroTableAnnotationComposer,
          $$TransferenciasDineroTableCreateCompanionBuilder,
          $$TransferenciasDineroTableUpdateCompanionBuilder,
          (TransferenciasDineroData, $$TransferenciasDineroTableReferences),
          TransferenciasDineroData,
          PrefetchHooks Function({bool cuentaOrigenId, bool cuentaDestinoId})
        > {
  $$TransferenciasDineroTableTableManager(
    _$AppDatabase db,
    $TransferenciasDineroTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransferenciasDineroTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransferenciasDineroTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TransferenciasDineroTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> medioOrigen = const Value.absent(),
                Value<int?> cuentaOrigenId = const Value.absent(),
                Value<String> medioDestino = const Value.absent(),
                Value<int?> cuentaDestinoId = const Value.absent(),
                Value<double> monto = const Value.absent(),
                Value<DateTime> fecha = const Value.absent(),
                Value<String?> nota = const Value.absent(),
              }) => TransferenciasDineroCompanion(
                id: id,
                medioOrigen: medioOrigen,
                cuentaOrigenId: cuentaOrigenId,
                medioDestino: medioDestino,
                cuentaDestinoId: cuentaDestinoId,
                monto: monto,
                fecha: fecha,
                nota: nota,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String medioOrigen,
                Value<int?> cuentaOrigenId = const Value.absent(),
                required String medioDestino,
                Value<int?> cuentaDestinoId = const Value.absent(),
                required double monto,
                required DateTime fecha,
                Value<String?> nota = const Value.absent(),
              }) => TransferenciasDineroCompanion.insert(
                id: id,
                medioOrigen: medioOrigen,
                cuentaOrigenId: cuentaOrigenId,
                medioDestino: medioDestino,
                cuentaDestinoId: cuentaDestinoId,
                monto: monto,
                fecha: fecha,
                nota: nota,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $TransferenciasDineroTable,
                    TransferenciasDineroData
                  >(table),
                  $$TransferenciasDineroTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({cuentaOrigenId = false, cuentaDestinoId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (cuentaOrigenId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.cuentaOrigenId,
                                    referencedTable:
                                        $$TransferenciasDineroTableReferences
                                            ._cuentaOrigenIdTable(db),
                                    referencedColumn:
                                        $$TransferenciasDineroTableReferences
                                            ._cuentaOrigenIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (cuentaDestinoId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.cuentaDestinoId,
                                    referencedTable:
                                        $$TransferenciasDineroTableReferences
                                            ._cuentaDestinoIdTable(db),
                                    referencedColumn:
                                        $$TransferenciasDineroTableReferences
                                            ._cuentaDestinoIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$TransferenciasDineroTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransferenciasDineroTable,
      TransferenciasDineroData,
      $$TransferenciasDineroTableFilterComposer,
      $$TransferenciasDineroTableOrderingComposer,
      $$TransferenciasDineroTableAnnotationComposer,
      $$TransferenciasDineroTableCreateCompanionBuilder,
      $$TransferenciasDineroTableUpdateCompanionBuilder,
      (TransferenciasDineroData, $$TransferenciasDineroTableReferences),
      TransferenciasDineroData,
      PrefetchHooks Function({bool cuentaOrigenId, bool cuentaDestinoId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CuentasDigitalesTableTableManager get cuentasDigitales =>
      $$CuentasDigitalesTableTableManager(_db, _db.cuentasDigitales);
  $$IngresosTableTableManager get ingresos =>
      $$IngresosTableTableManager(_db, _db.ingresos);
  $$SuscripcionesTableTableManager get suscripciones =>
      $$SuscripcionesTableTableManager(_db, _db.suscripciones);
  $$GastosTableTableManager get gastos =>
      $$GastosTableTableManager(_db, _db.gastos);
  $$DeudasTableTableManager get deudas =>
      $$DeudasTableTableManager(_db, _db.deudas);
  $$PagosDeudaTableTableManager get pagosDeuda =>
      $$PagosDeudaTableTableManager(_db, _db.pagosDeuda);
  $$MovimientosAhorroTableTableManager get movimientosAhorro =>
      $$MovimientosAhorroTableTableManager(_db, _db.movimientosAhorro);
  $$PrestamosTercerosTableTableManager get prestamosTerceros =>
      $$PrestamosTercerosTableTableManager(_db, _db.prestamosTerceros);
  $$MovimientosPrestamoTableTableManager get movimientosPrestamo =>
      $$MovimientosPrestamoTableTableManager(_db, _db.movimientosPrestamo);
  $$GastosFuturosTableTableManager get gastosFuturos =>
      $$GastosFuturosTableTableManager(_db, _db.gastosFuturos);
  $$MovimientosReservaGastoFuturoTableTableManager
  get movimientosReservaGastoFuturo =>
      $$MovimientosReservaGastoFuturoTableTableManager(
        _db,
        _db.movimientosReservaGastoFuturo,
      );
  $$AsignacionesDineroTableTableManager get asignacionesDinero =>
      $$AsignacionesDineroTableTableManager(_db, _db.asignacionesDinero);
  $$IngresoDistribucionesTableTableManager get ingresoDistribuciones =>
      $$IngresoDistribucionesTableTableManager(_db, _db.ingresoDistribuciones);
  $$TransferenciasDineroTableTableManager get transferenciasDinero =>
      $$TransferenciasDineroTableTableManager(_db, _db.transferenciasDinero);
}
