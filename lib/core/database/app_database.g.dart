// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $FormulasTable extends Formulas
    with TableInfo<$FormulasTable, FormulaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FormulasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetRgbMeta = const VerificationMeta(
    'targetRgb',
  );
  @override
  late final GeneratedColumn<int> targetRgb = GeneratedColumn<int>(
    'target_rgb',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _presetIdMeta = const VerificationMeta(
    'presetId',
  );
  @override
  late final GeneratedColumn<String> presetId = GeneratedColumn<String>(
    'preset_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDemoMeta = const VerificationMeta('isDemo');
  @override
  late final GeneratedColumn<bool> isDemo = GeneratedColumn<bool>(
    'is_demo',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_demo" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _totalDyeDgMeta = const VerificationMeta(
    'totalDyeDg',
  );
  @override
  late final GeneratedColumn<int> totalDyeDg = GeneratedColumn<int>(
    'total_dye_dg',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _developerRatioHundredthsMeta =
      const VerificationMeta('developerRatioHundredths');
  @override
  late final GeneratedColumn<int> developerRatioHundredths =
      GeneratedColumn<int>(
        'developer_ratio_hundredths',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _developerVolumeMeta = const VerificationMeta(
    'developerVolume',
  );
  @override
  late final GeneratedColumn<int> developerVolume = GeneratedColumn<int>(
    'developer_volume',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _developerDgMeta = const VerificationMeta(
    'developerDg',
  );
  @override
  late final GeneratedColumn<int> developerDg = GeneratedColumn<int>(
    'developer_dg',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalMixtureDgMeta = const VerificationMeta(
    'totalMixtureDg',
  );
  @override
  late final GeneratedColumn<int> totalMixtureDg = GeneratedColumn<int>(
    'total_mixture_dg',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    targetRgb,
    presetId,
    isDemo,
    totalDyeDg,
    developerRatioHundredths,
    developerVolume,
    developerDg,
    totalMixtureDg,
    notes,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'formulas';
  @override
  VerificationContext validateIntegrity(
    Insertable<FormulaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('target_rgb')) {
      context.handle(
        _targetRgbMeta,
        targetRgb.isAcceptableOrUnknown(data['target_rgb']!, _targetRgbMeta),
      );
    } else if (isInserting) {
      context.missing(_targetRgbMeta);
    }
    if (data.containsKey('preset_id')) {
      context.handle(
        _presetIdMeta,
        presetId.isAcceptableOrUnknown(data['preset_id']!, _presetIdMeta),
      );
    }
    if (data.containsKey('is_demo')) {
      context.handle(
        _isDemoMeta,
        isDemo.isAcceptableOrUnknown(data['is_demo']!, _isDemoMeta),
      );
    }
    if (data.containsKey('total_dye_dg')) {
      context.handle(
        _totalDyeDgMeta,
        totalDyeDg.isAcceptableOrUnknown(
          data['total_dye_dg']!,
          _totalDyeDgMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalDyeDgMeta);
    }
    if (data.containsKey('developer_ratio_hundredths')) {
      context.handle(
        _developerRatioHundredthsMeta,
        developerRatioHundredths.isAcceptableOrUnknown(
          data['developer_ratio_hundredths']!,
          _developerRatioHundredthsMeta,
        ),
      );
    }
    if (data.containsKey('developer_volume')) {
      context.handle(
        _developerVolumeMeta,
        developerVolume.isAcceptableOrUnknown(
          data['developer_volume']!,
          _developerVolumeMeta,
        ),
      );
    }
    if (data.containsKey('developer_dg')) {
      context.handle(
        _developerDgMeta,
        developerDg.isAcceptableOrUnknown(
          data['developer_dg']!,
          _developerDgMeta,
        ),
      );
    }
    if (data.containsKey('total_mixture_dg')) {
      context.handle(
        _totalMixtureDgMeta,
        totalMixtureDg.isAcceptableOrUnknown(
          data['total_mixture_dg']!,
          _totalMixtureDgMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalMixtureDgMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FormulaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FormulaRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      targetRgb: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_rgb'],
      )!,
      presetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preset_id'],
      ),
      isDemo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_demo'],
      )!,
      totalDyeDg: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_dye_dg'],
      )!,
      developerRatioHundredths: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}developer_ratio_hundredths'],
      ),
      developerVolume: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}developer_volume'],
      ),
      developerDg: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}developer_dg'],
      )!,
      totalMixtureDg: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_mixture_dg'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $FormulasTable createAlias(String alias) {
    return $FormulasTable(attachedDatabase, alias);
  }
}

class FormulaRow extends DataClass implements Insertable<FormulaRow> {
  final String id;
  final String name;
  final int targetRgb;
  final String? presetId;
  final bool isDemo;
  final int totalDyeDg;
  final int? developerRatioHundredths;
  final int? developerVolume;
  final int developerDg;
  final int totalMixtureDg;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const FormulaRow({
    required this.id,
    required this.name,
    required this.targetRgb,
    this.presetId,
    required this.isDemo,
    required this.totalDyeDg,
    this.developerRatioHundredths,
    this.developerVolume,
    required this.developerDg,
    required this.totalMixtureDg,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['target_rgb'] = Variable<int>(targetRgb);
    if (!nullToAbsent || presetId != null) {
      map['preset_id'] = Variable<String>(presetId);
    }
    map['is_demo'] = Variable<bool>(isDemo);
    map['total_dye_dg'] = Variable<int>(totalDyeDg);
    if (!nullToAbsent || developerRatioHundredths != null) {
      map['developer_ratio_hundredths'] = Variable<int>(
        developerRatioHundredths,
      );
    }
    if (!nullToAbsent || developerVolume != null) {
      map['developer_volume'] = Variable<int>(developerVolume);
    }
    map['developer_dg'] = Variable<int>(developerDg);
    map['total_mixture_dg'] = Variable<int>(totalMixtureDg);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FormulasCompanion toCompanion(bool nullToAbsent) {
    return FormulasCompanion(
      id: Value(id),
      name: Value(name),
      targetRgb: Value(targetRgb),
      presetId: presetId == null && nullToAbsent
          ? const Value.absent()
          : Value(presetId),
      isDemo: Value(isDemo),
      totalDyeDg: Value(totalDyeDg),
      developerRatioHundredths: developerRatioHundredths == null && nullToAbsent
          ? const Value.absent()
          : Value(developerRatioHundredths),
      developerVolume: developerVolume == null && nullToAbsent
          ? const Value.absent()
          : Value(developerVolume),
      developerDg: Value(developerDg),
      totalMixtureDg: Value(totalMixtureDg),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory FormulaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FormulaRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      targetRgb: serializer.fromJson<int>(json['targetRgb']),
      presetId: serializer.fromJson<String?>(json['presetId']),
      isDemo: serializer.fromJson<bool>(json['isDemo']),
      totalDyeDg: serializer.fromJson<int>(json['totalDyeDg']),
      developerRatioHundredths: serializer.fromJson<int?>(
        json['developerRatioHundredths'],
      ),
      developerVolume: serializer.fromJson<int?>(json['developerVolume']),
      developerDg: serializer.fromJson<int>(json['developerDg']),
      totalMixtureDg: serializer.fromJson<int>(json['totalMixtureDg']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'targetRgb': serializer.toJson<int>(targetRgb),
      'presetId': serializer.toJson<String?>(presetId),
      'isDemo': serializer.toJson<bool>(isDemo),
      'totalDyeDg': serializer.toJson<int>(totalDyeDg),
      'developerRatioHundredths': serializer.toJson<int?>(
        developerRatioHundredths,
      ),
      'developerVolume': serializer.toJson<int?>(developerVolume),
      'developerDg': serializer.toJson<int>(developerDg),
      'totalMixtureDg': serializer.toJson<int>(totalMixtureDg),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  FormulaRow copyWith({
    String? id,
    String? name,
    int? targetRgb,
    Value<String?> presetId = const Value.absent(),
    bool? isDemo,
    int? totalDyeDg,
    Value<int?> developerRatioHundredths = const Value.absent(),
    Value<int?> developerVolume = const Value.absent(),
    int? developerDg,
    int? totalMixtureDg,
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => FormulaRow(
    id: id ?? this.id,
    name: name ?? this.name,
    targetRgb: targetRgb ?? this.targetRgb,
    presetId: presetId.present ? presetId.value : this.presetId,
    isDemo: isDemo ?? this.isDemo,
    totalDyeDg: totalDyeDg ?? this.totalDyeDg,
    developerRatioHundredths: developerRatioHundredths.present
        ? developerRatioHundredths.value
        : this.developerRatioHundredths,
    developerVolume: developerVolume.present
        ? developerVolume.value
        : this.developerVolume,
    developerDg: developerDg ?? this.developerDg,
    totalMixtureDg: totalMixtureDg ?? this.totalMixtureDg,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  FormulaRow copyWithCompanion(FormulasCompanion data) {
    return FormulaRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      targetRgb: data.targetRgb.present ? data.targetRgb.value : this.targetRgb,
      presetId: data.presetId.present ? data.presetId.value : this.presetId,
      isDemo: data.isDemo.present ? data.isDemo.value : this.isDemo,
      totalDyeDg: data.totalDyeDg.present
          ? data.totalDyeDg.value
          : this.totalDyeDg,
      developerRatioHundredths: data.developerRatioHundredths.present
          ? data.developerRatioHundredths.value
          : this.developerRatioHundredths,
      developerVolume: data.developerVolume.present
          ? data.developerVolume.value
          : this.developerVolume,
      developerDg: data.developerDg.present
          ? data.developerDg.value
          : this.developerDg,
      totalMixtureDg: data.totalMixtureDg.present
          ? data.totalMixtureDg.value
          : this.totalMixtureDg,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FormulaRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('targetRgb: $targetRgb, ')
          ..write('presetId: $presetId, ')
          ..write('isDemo: $isDemo, ')
          ..write('totalDyeDg: $totalDyeDg, ')
          ..write('developerRatioHundredths: $developerRatioHundredths, ')
          ..write('developerVolume: $developerVolume, ')
          ..write('developerDg: $developerDg, ')
          ..write('totalMixtureDg: $totalMixtureDg, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    targetRgb,
    presetId,
    isDemo,
    totalDyeDg,
    developerRatioHundredths,
    developerVolume,
    developerDg,
    totalMixtureDg,
    notes,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FormulaRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.targetRgb == this.targetRgb &&
          other.presetId == this.presetId &&
          other.isDemo == this.isDemo &&
          other.totalDyeDg == this.totalDyeDg &&
          other.developerRatioHundredths == this.developerRatioHundredths &&
          other.developerVolume == this.developerVolume &&
          other.developerDg == this.developerDg &&
          other.totalMixtureDg == this.totalMixtureDg &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FormulasCompanion extends UpdateCompanion<FormulaRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> targetRgb;
  final Value<String?> presetId;
  final Value<bool> isDemo;
  final Value<int> totalDyeDg;
  final Value<int?> developerRatioHundredths;
  final Value<int?> developerVolume;
  final Value<int> developerDg;
  final Value<int> totalMixtureDg;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const FormulasCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.targetRgb = const Value.absent(),
    this.presetId = const Value.absent(),
    this.isDemo = const Value.absent(),
    this.totalDyeDg = const Value.absent(),
    this.developerRatioHundredths = const Value.absent(),
    this.developerVolume = const Value.absent(),
    this.developerDg = const Value.absent(),
    this.totalMixtureDg = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FormulasCompanion.insert({
    required String id,
    required String name,
    required int targetRgb,
    this.presetId = const Value.absent(),
    this.isDemo = const Value.absent(),
    required int totalDyeDg,
    this.developerRatioHundredths = const Value.absent(),
    this.developerVolume = const Value.absent(),
    this.developerDg = const Value.absent(),
    required int totalMixtureDg,
    this.notes = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       targetRgb = Value(targetRgb),
       totalDyeDg = Value(totalDyeDg),
       totalMixtureDg = Value(totalMixtureDg),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<FormulaRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? targetRgb,
    Expression<String>? presetId,
    Expression<bool>? isDemo,
    Expression<int>? totalDyeDg,
    Expression<int>? developerRatioHundredths,
    Expression<int>? developerVolume,
    Expression<int>? developerDg,
    Expression<int>? totalMixtureDg,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (targetRgb != null) 'target_rgb': targetRgb,
      if (presetId != null) 'preset_id': presetId,
      if (isDemo != null) 'is_demo': isDemo,
      if (totalDyeDg != null) 'total_dye_dg': totalDyeDg,
      if (developerRatioHundredths != null)
        'developer_ratio_hundredths': developerRatioHundredths,
      if (developerVolume != null) 'developer_volume': developerVolume,
      if (developerDg != null) 'developer_dg': developerDg,
      if (totalMixtureDg != null) 'total_mixture_dg': totalMixtureDg,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FormulasCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? targetRgb,
    Value<String?>? presetId,
    Value<bool>? isDemo,
    Value<int>? totalDyeDg,
    Value<int?>? developerRatioHundredths,
    Value<int?>? developerVolume,
    Value<int>? developerDg,
    Value<int>? totalMixtureDg,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return FormulasCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      targetRgb: targetRgb ?? this.targetRgb,
      presetId: presetId ?? this.presetId,
      isDemo: isDemo ?? this.isDemo,
      totalDyeDg: totalDyeDg ?? this.totalDyeDg,
      developerRatioHundredths:
          developerRatioHundredths ?? this.developerRatioHundredths,
      developerVolume: developerVolume ?? this.developerVolume,
      developerDg: developerDg ?? this.developerDg,
      totalMixtureDg: totalMixtureDg ?? this.totalMixtureDg,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (targetRgb.present) {
      map['target_rgb'] = Variable<int>(targetRgb.value);
    }
    if (presetId.present) {
      map['preset_id'] = Variable<String>(presetId.value);
    }
    if (isDemo.present) {
      map['is_demo'] = Variable<bool>(isDemo.value);
    }
    if (totalDyeDg.present) {
      map['total_dye_dg'] = Variable<int>(totalDyeDg.value);
    }
    if (developerRatioHundredths.present) {
      map['developer_ratio_hundredths'] = Variable<int>(
        developerRatioHundredths.value,
      );
    }
    if (developerVolume.present) {
      map['developer_volume'] = Variable<int>(developerVolume.value);
    }
    if (developerDg.present) {
      map['developer_dg'] = Variable<int>(developerDg.value);
    }
    if (totalMixtureDg.present) {
      map['total_mixture_dg'] = Variable<int>(totalMixtureDg.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FormulasCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('targetRgb: $targetRgb, ')
          ..write('presetId: $presetId, ')
          ..write('isDemo: $isDemo, ')
          ..write('totalDyeDg: $totalDyeDg, ')
          ..write('developerRatioHundredths: $developerRatioHundredths, ')
          ..write('developerVolume: $developerVolume, ')
          ..write('developerDg: $developerDg, ')
          ..write('totalMixtureDg: $totalMixtureDg, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FormulaIngredientsTable extends FormulaIngredients
    with TableInfo<$FormulaIngredientsTable, FormulaIngredientRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FormulaIngredientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _formulaIdMeta = const VerificationMeta(
    'formulaId',
  );
  @override
  late final GeneratedColumn<String> formulaId = GeneratedColumn<String>(
    'formula_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES formulas (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _percentHundredthsMeta = const VerificationMeta(
    'percentHundredths',
  );
  @override
  late final GeneratedColumn<int> percentHundredths = GeneratedColumn<int>(
    'percent_hundredths',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _requiredDgMeta = const VerificationMeta(
    'requiredDg',
  );
  @override
  late final GeneratedColumn<int> requiredDg = GeneratedColumn<int>(
    'required_dg',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayRgbMeta = const VerificationMeta(
    'displayRgb',
  );
  @override
  late final GeneratedColumn<int> displayRgb = GeneratedColumn<int>(
    'display_rgb',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    formulaId,
    position,
    name,
    percentHundredths,
    requiredDg,
    displayRgb,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'formula_ingredients';
  @override
  VerificationContext validateIntegrity(
    Insertable<FormulaIngredientRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('formula_id')) {
      context.handle(
        _formulaIdMeta,
        formulaId.isAcceptableOrUnknown(data['formula_id']!, _formulaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_formulaIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('percent_hundredths')) {
      context.handle(
        _percentHundredthsMeta,
        percentHundredths.isAcceptableOrUnknown(
          data['percent_hundredths']!,
          _percentHundredthsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_percentHundredthsMeta);
    }
    if (data.containsKey('required_dg')) {
      context.handle(
        _requiredDgMeta,
        requiredDg.isAcceptableOrUnknown(data['required_dg']!, _requiredDgMeta),
      );
    } else if (isInserting) {
      context.missing(_requiredDgMeta);
    }
    if (data.containsKey('display_rgb')) {
      context.handle(
        _displayRgbMeta,
        displayRgb.isAcceptableOrUnknown(data['display_rgb']!, _displayRgbMeta),
      );
    } else if (isInserting) {
      context.missing(_displayRgbMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FormulaIngredientRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FormulaIngredientRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      formulaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}formula_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      percentHundredths: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}percent_hundredths'],
      )!,
      requiredDg: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}required_dg'],
      )!,
      displayRgb: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}display_rgb'],
      )!,
    );
  }

  @override
  $FormulaIngredientsTable createAlias(String alias) {
    return $FormulaIngredientsTable(attachedDatabase, alias);
  }
}

class FormulaIngredientRow extends DataClass
    implements Insertable<FormulaIngredientRow> {
  final String id;
  final String formulaId;
  final int position;
  final String name;
  final int percentHundredths;
  final int requiredDg;
  final int displayRgb;
  const FormulaIngredientRow({
    required this.id,
    required this.formulaId,
    required this.position,
    required this.name,
    required this.percentHundredths,
    required this.requiredDg,
    required this.displayRgb,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['formula_id'] = Variable<String>(formulaId);
    map['position'] = Variable<int>(position);
    map['name'] = Variable<String>(name);
    map['percent_hundredths'] = Variable<int>(percentHundredths);
    map['required_dg'] = Variable<int>(requiredDg);
    map['display_rgb'] = Variable<int>(displayRgb);
    return map;
  }

  FormulaIngredientsCompanion toCompanion(bool nullToAbsent) {
    return FormulaIngredientsCompanion(
      id: Value(id),
      formulaId: Value(formulaId),
      position: Value(position),
      name: Value(name),
      percentHundredths: Value(percentHundredths),
      requiredDg: Value(requiredDg),
      displayRgb: Value(displayRgb),
    );
  }

  factory FormulaIngredientRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FormulaIngredientRow(
      id: serializer.fromJson<String>(json['id']),
      formulaId: serializer.fromJson<String>(json['formulaId']),
      position: serializer.fromJson<int>(json['position']),
      name: serializer.fromJson<String>(json['name']),
      percentHundredths: serializer.fromJson<int>(json['percentHundredths']),
      requiredDg: serializer.fromJson<int>(json['requiredDg']),
      displayRgb: serializer.fromJson<int>(json['displayRgb']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'formulaId': serializer.toJson<String>(formulaId),
      'position': serializer.toJson<int>(position),
      'name': serializer.toJson<String>(name),
      'percentHundredths': serializer.toJson<int>(percentHundredths),
      'requiredDg': serializer.toJson<int>(requiredDg),
      'displayRgb': serializer.toJson<int>(displayRgb),
    };
  }

  FormulaIngredientRow copyWith({
    String? id,
    String? formulaId,
    int? position,
    String? name,
    int? percentHundredths,
    int? requiredDg,
    int? displayRgb,
  }) => FormulaIngredientRow(
    id: id ?? this.id,
    formulaId: formulaId ?? this.formulaId,
    position: position ?? this.position,
    name: name ?? this.name,
    percentHundredths: percentHundredths ?? this.percentHundredths,
    requiredDg: requiredDg ?? this.requiredDg,
    displayRgb: displayRgb ?? this.displayRgb,
  );
  FormulaIngredientRow copyWithCompanion(FormulaIngredientsCompanion data) {
    return FormulaIngredientRow(
      id: data.id.present ? data.id.value : this.id,
      formulaId: data.formulaId.present ? data.formulaId.value : this.formulaId,
      position: data.position.present ? data.position.value : this.position,
      name: data.name.present ? data.name.value : this.name,
      percentHundredths: data.percentHundredths.present
          ? data.percentHundredths.value
          : this.percentHundredths,
      requiredDg: data.requiredDg.present
          ? data.requiredDg.value
          : this.requiredDg,
      displayRgb: data.displayRgb.present
          ? data.displayRgb.value
          : this.displayRgb,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FormulaIngredientRow(')
          ..write('id: $id, ')
          ..write('formulaId: $formulaId, ')
          ..write('position: $position, ')
          ..write('name: $name, ')
          ..write('percentHundredths: $percentHundredths, ')
          ..write('requiredDg: $requiredDg, ')
          ..write('displayRgb: $displayRgb')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    formulaId,
    position,
    name,
    percentHundredths,
    requiredDg,
    displayRgb,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FormulaIngredientRow &&
          other.id == this.id &&
          other.formulaId == this.formulaId &&
          other.position == this.position &&
          other.name == this.name &&
          other.percentHundredths == this.percentHundredths &&
          other.requiredDg == this.requiredDg &&
          other.displayRgb == this.displayRgb);
}

class FormulaIngredientsCompanion
    extends UpdateCompanion<FormulaIngredientRow> {
  final Value<String> id;
  final Value<String> formulaId;
  final Value<int> position;
  final Value<String> name;
  final Value<int> percentHundredths;
  final Value<int> requiredDg;
  final Value<int> displayRgb;
  final Value<int> rowid;
  const FormulaIngredientsCompanion({
    this.id = const Value.absent(),
    this.formulaId = const Value.absent(),
    this.position = const Value.absent(),
    this.name = const Value.absent(),
    this.percentHundredths = const Value.absent(),
    this.requiredDg = const Value.absent(),
    this.displayRgb = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FormulaIngredientsCompanion.insert({
    required String id,
    required String formulaId,
    required int position,
    required String name,
    required int percentHundredths,
    required int requiredDg,
    required int displayRgb,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       formulaId = Value(formulaId),
       position = Value(position),
       name = Value(name),
       percentHundredths = Value(percentHundredths),
       requiredDg = Value(requiredDg),
       displayRgb = Value(displayRgb);
  static Insertable<FormulaIngredientRow> custom({
    Expression<String>? id,
    Expression<String>? formulaId,
    Expression<int>? position,
    Expression<String>? name,
    Expression<int>? percentHundredths,
    Expression<int>? requiredDg,
    Expression<int>? displayRgb,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (formulaId != null) 'formula_id': formulaId,
      if (position != null) 'position': position,
      if (name != null) 'name': name,
      if (percentHundredths != null) 'percent_hundredths': percentHundredths,
      if (requiredDg != null) 'required_dg': requiredDg,
      if (displayRgb != null) 'display_rgb': displayRgb,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FormulaIngredientsCompanion copyWith({
    Value<String>? id,
    Value<String>? formulaId,
    Value<int>? position,
    Value<String>? name,
    Value<int>? percentHundredths,
    Value<int>? requiredDg,
    Value<int>? displayRgb,
    Value<int>? rowid,
  }) {
    return FormulaIngredientsCompanion(
      id: id ?? this.id,
      formulaId: formulaId ?? this.formulaId,
      position: position ?? this.position,
      name: name ?? this.name,
      percentHundredths: percentHundredths ?? this.percentHundredths,
      requiredDg: requiredDg ?? this.requiredDg,
      displayRgb: displayRgb ?? this.displayRgb,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (formulaId.present) {
      map['formula_id'] = Variable<String>(formulaId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (percentHundredths.present) {
      map['percent_hundredths'] = Variable<int>(percentHundredths.value);
    }
    if (requiredDg.present) {
      map['required_dg'] = Variable<int>(requiredDg.value);
    }
    if (displayRgb.present) {
      map['display_rgb'] = Variable<int>(displayRgb.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FormulaIngredientsCompanion(')
          ..write('id: $id, ')
          ..write('formulaId: $formulaId, ')
          ..write('position: $position, ')
          ..write('name: $name, ')
          ..write('percentHundredths: $percentHundredths, ')
          ..write('requiredDg: $requiredDg, ')
          ..write('displayRgb: $displayRgb, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WeighingSessionsTable extends WeighingSessions
    with TableInfo<$WeighingSessionsTable, WeighingSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeighingSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _formulaIdMeta = const VerificationMeta(
    'formulaId',
  );
  @override
  late final GeneratedColumn<String> formulaId = GeneratedColumn<String>(
    'formula_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES formulas (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _formulaNameMeta = const VerificationMeta(
    'formulaName',
  );
  @override
  late final GeneratedColumn<String> formulaName = GeneratedColumn<String>(
    'formula_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scaleIdMeta = const VerificationMeta(
    'scaleId',
  );
  @override
  late final GeneratedColumn<String> scaleId = GeneratedColumn<String>(
    'scale_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scaleNameMeta = const VerificationMeta(
    'scaleName',
  );
  @override
  late final GeneratedColumn<String> scaleName = GeneratedColumn<String>(
    'scale_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentStepIndexMeta = const VerificationMeta(
    'currentStepIndex',
  );
  @override
  late final GeneratedColumn<int> currentStepIndex = GeneratedColumn<int>(
    'current_step_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _plannedTotalDgMeta = const VerificationMeta(
    'plannedTotalDg',
  );
  @override
  late final GeneratedColumn<int> plannedTotalDg = GeneratedColumn<int>(
    'planned_total_dg',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _measuredTotalMgMeta = const VerificationMeta(
    'measuredTotalMg',
  );
  @override
  late final GeneratedColumn<int> measuredTotalMg = GeneratedColumn<int>(
    'measured_total_mg',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _toleranceMgMeta = const VerificationMeta(
    'toleranceMg',
  );
  @override
  late final GeneratedColumn<int> toleranceMg = GeneratedColumn<int>(
    'tolerance_mg',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SessionStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SessionStatus>($WeighingSessionsTable.$converterstatus);
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> finishedAt = GeneratedColumn<DateTime>(
    'finished_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    formulaId,
    formulaName,
    scaleId,
    scaleName,
    currentStepIndex,
    plannedTotalDg,
    measuredTotalMg,
    toleranceMg,
    status,
    startedAt,
    finishedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weighing_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeighingSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('formula_id')) {
      context.handle(
        _formulaIdMeta,
        formulaId.isAcceptableOrUnknown(data['formula_id']!, _formulaIdMeta),
      );
    }
    if (data.containsKey('formula_name')) {
      context.handle(
        _formulaNameMeta,
        formulaName.isAcceptableOrUnknown(
          data['formula_name']!,
          _formulaNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_formulaNameMeta);
    }
    if (data.containsKey('scale_id')) {
      context.handle(
        _scaleIdMeta,
        scaleId.isAcceptableOrUnknown(data['scale_id']!, _scaleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scaleIdMeta);
    }
    if (data.containsKey('scale_name')) {
      context.handle(
        _scaleNameMeta,
        scaleName.isAcceptableOrUnknown(data['scale_name']!, _scaleNameMeta),
      );
    } else if (isInserting) {
      context.missing(_scaleNameMeta);
    }
    if (data.containsKey('current_step_index')) {
      context.handle(
        _currentStepIndexMeta,
        currentStepIndex.isAcceptableOrUnknown(
          data['current_step_index']!,
          _currentStepIndexMeta,
        ),
      );
    }
    if (data.containsKey('planned_total_dg')) {
      context.handle(
        _plannedTotalDgMeta,
        plannedTotalDg.isAcceptableOrUnknown(
          data['planned_total_dg']!,
          _plannedTotalDgMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_plannedTotalDgMeta);
    }
    if (data.containsKey('measured_total_mg')) {
      context.handle(
        _measuredTotalMgMeta,
        measuredTotalMg.isAcceptableOrUnknown(
          data['measured_total_mg']!,
          _measuredTotalMgMeta,
        ),
      );
    }
    if (data.containsKey('tolerance_mg')) {
      context.handle(
        _toleranceMgMeta,
        toleranceMg.isAcceptableOrUnknown(
          data['tolerance_mg']!,
          _toleranceMgMeta,
        ),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeighingSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeighingSessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      formulaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}formula_id'],
      ),
      formulaName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}formula_name'],
      )!,
      scaleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scale_id'],
      )!,
      scaleName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scale_name'],
      )!,
      currentStepIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_step_index'],
      )!,
      plannedTotalDg: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}planned_total_dg'],
      )!,
      measuredTotalMg: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}measured_total_mg'],
      ),
      toleranceMg: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tolerance_mg'],
      ),
      status: $WeighingSessionsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}finished_at'],
      ),
    );
  }

  @override
  $WeighingSessionsTable createAlias(String alias) {
    return $WeighingSessionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SessionStatus, String, String> $converterstatus =
      const EnumNameConverter<SessionStatus>(SessionStatus.values);
}

class WeighingSessionRow extends DataClass
    implements Insertable<WeighingSessionRow> {
  final String id;
  final String? formulaId;
  final String formulaName;
  final String scaleId;
  final String scaleName;
  final int currentStepIndex;
  final int plannedTotalDg;
  final int? measuredTotalMg;

  /// what "on target" meant for this session. null on v1 rows
  final int? toleranceMg;
  final SessionStatus status;
  final DateTime startedAt;
  final DateTime? finishedAt;
  const WeighingSessionRow({
    required this.id,
    this.formulaId,
    required this.formulaName,
    required this.scaleId,
    required this.scaleName,
    required this.currentStepIndex,
    required this.plannedTotalDg,
    this.measuredTotalMg,
    this.toleranceMg,
    required this.status,
    required this.startedAt,
    this.finishedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || formulaId != null) {
      map['formula_id'] = Variable<String>(formulaId);
    }
    map['formula_name'] = Variable<String>(formulaName);
    map['scale_id'] = Variable<String>(scaleId);
    map['scale_name'] = Variable<String>(scaleName);
    map['current_step_index'] = Variable<int>(currentStepIndex);
    map['planned_total_dg'] = Variable<int>(plannedTotalDg);
    if (!nullToAbsent || measuredTotalMg != null) {
      map['measured_total_mg'] = Variable<int>(measuredTotalMg);
    }
    if (!nullToAbsent || toleranceMg != null) {
      map['tolerance_mg'] = Variable<int>(toleranceMg);
    }
    {
      map['status'] = Variable<String>(
        $WeighingSessionsTable.$converterstatus.toSql(status),
      );
    }
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<DateTime>(finishedAt);
    }
    return map;
  }

  WeighingSessionsCompanion toCompanion(bool nullToAbsent) {
    return WeighingSessionsCompanion(
      id: Value(id),
      formulaId: formulaId == null && nullToAbsent
          ? const Value.absent()
          : Value(formulaId),
      formulaName: Value(formulaName),
      scaleId: Value(scaleId),
      scaleName: Value(scaleName),
      currentStepIndex: Value(currentStepIndex),
      plannedTotalDg: Value(plannedTotalDg),
      measuredTotalMg: measuredTotalMg == null && nullToAbsent
          ? const Value.absent()
          : Value(measuredTotalMg),
      toleranceMg: toleranceMg == null && nullToAbsent
          ? const Value.absent()
          : Value(toleranceMg),
      status: Value(status),
      startedAt: Value(startedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
    );
  }

  factory WeighingSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeighingSessionRow(
      id: serializer.fromJson<String>(json['id']),
      formulaId: serializer.fromJson<String?>(json['formulaId']),
      formulaName: serializer.fromJson<String>(json['formulaName']),
      scaleId: serializer.fromJson<String>(json['scaleId']),
      scaleName: serializer.fromJson<String>(json['scaleName']),
      currentStepIndex: serializer.fromJson<int>(json['currentStepIndex']),
      plannedTotalDg: serializer.fromJson<int>(json['plannedTotalDg']),
      measuredTotalMg: serializer.fromJson<int?>(json['measuredTotalMg']),
      toleranceMg: serializer.fromJson<int?>(json['toleranceMg']),
      status: $WeighingSessionsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      finishedAt: serializer.fromJson<DateTime?>(json['finishedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'formulaId': serializer.toJson<String?>(formulaId),
      'formulaName': serializer.toJson<String>(formulaName),
      'scaleId': serializer.toJson<String>(scaleId),
      'scaleName': serializer.toJson<String>(scaleName),
      'currentStepIndex': serializer.toJson<int>(currentStepIndex),
      'plannedTotalDg': serializer.toJson<int>(plannedTotalDg),
      'measuredTotalMg': serializer.toJson<int?>(measuredTotalMg),
      'toleranceMg': serializer.toJson<int?>(toleranceMg),
      'status': serializer.toJson<String>(
        $WeighingSessionsTable.$converterstatus.toJson(status),
      ),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'finishedAt': serializer.toJson<DateTime?>(finishedAt),
    };
  }

  WeighingSessionRow copyWith({
    String? id,
    Value<String?> formulaId = const Value.absent(),
    String? formulaName,
    String? scaleId,
    String? scaleName,
    int? currentStepIndex,
    int? plannedTotalDg,
    Value<int?> measuredTotalMg = const Value.absent(),
    Value<int?> toleranceMg = const Value.absent(),
    SessionStatus? status,
    DateTime? startedAt,
    Value<DateTime?> finishedAt = const Value.absent(),
  }) => WeighingSessionRow(
    id: id ?? this.id,
    formulaId: formulaId.present ? formulaId.value : this.formulaId,
    formulaName: formulaName ?? this.formulaName,
    scaleId: scaleId ?? this.scaleId,
    scaleName: scaleName ?? this.scaleName,
    currentStepIndex: currentStepIndex ?? this.currentStepIndex,
    plannedTotalDg: plannedTotalDg ?? this.plannedTotalDg,
    measuredTotalMg: measuredTotalMg.present
        ? measuredTotalMg.value
        : this.measuredTotalMg,
    toleranceMg: toleranceMg.present ? toleranceMg.value : this.toleranceMg,
    status: status ?? this.status,
    startedAt: startedAt ?? this.startedAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
  );
  WeighingSessionRow copyWithCompanion(WeighingSessionsCompanion data) {
    return WeighingSessionRow(
      id: data.id.present ? data.id.value : this.id,
      formulaId: data.formulaId.present ? data.formulaId.value : this.formulaId,
      formulaName: data.formulaName.present
          ? data.formulaName.value
          : this.formulaName,
      scaleId: data.scaleId.present ? data.scaleId.value : this.scaleId,
      scaleName: data.scaleName.present ? data.scaleName.value : this.scaleName,
      currentStepIndex: data.currentStepIndex.present
          ? data.currentStepIndex.value
          : this.currentStepIndex,
      plannedTotalDg: data.plannedTotalDg.present
          ? data.plannedTotalDg.value
          : this.plannedTotalDg,
      measuredTotalMg: data.measuredTotalMg.present
          ? data.measuredTotalMg.value
          : this.measuredTotalMg,
      toleranceMg: data.toleranceMg.present
          ? data.toleranceMg.value
          : this.toleranceMg,
      status: data.status.present ? data.status.value : this.status,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeighingSessionRow(')
          ..write('id: $id, ')
          ..write('formulaId: $formulaId, ')
          ..write('formulaName: $formulaName, ')
          ..write('scaleId: $scaleId, ')
          ..write('scaleName: $scaleName, ')
          ..write('currentStepIndex: $currentStepIndex, ')
          ..write('plannedTotalDg: $plannedTotalDg, ')
          ..write('measuredTotalMg: $measuredTotalMg, ')
          ..write('toleranceMg: $toleranceMg, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    formulaId,
    formulaName,
    scaleId,
    scaleName,
    currentStepIndex,
    plannedTotalDg,
    measuredTotalMg,
    toleranceMg,
    status,
    startedAt,
    finishedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeighingSessionRow &&
          other.id == this.id &&
          other.formulaId == this.formulaId &&
          other.formulaName == this.formulaName &&
          other.scaleId == this.scaleId &&
          other.scaleName == this.scaleName &&
          other.currentStepIndex == this.currentStepIndex &&
          other.plannedTotalDg == this.plannedTotalDg &&
          other.measuredTotalMg == this.measuredTotalMg &&
          other.toleranceMg == this.toleranceMg &&
          other.status == this.status &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt);
}

class WeighingSessionsCompanion extends UpdateCompanion<WeighingSessionRow> {
  final Value<String> id;
  final Value<String?> formulaId;
  final Value<String> formulaName;
  final Value<String> scaleId;
  final Value<String> scaleName;
  final Value<int> currentStepIndex;
  final Value<int> plannedTotalDg;
  final Value<int?> measuredTotalMg;
  final Value<int?> toleranceMg;
  final Value<SessionStatus> status;
  final Value<DateTime> startedAt;
  final Value<DateTime?> finishedAt;
  final Value<int> rowid;
  const WeighingSessionsCompanion({
    this.id = const Value.absent(),
    this.formulaId = const Value.absent(),
    this.formulaName = const Value.absent(),
    this.scaleId = const Value.absent(),
    this.scaleName = const Value.absent(),
    this.currentStepIndex = const Value.absent(),
    this.plannedTotalDg = const Value.absent(),
    this.measuredTotalMg = const Value.absent(),
    this.toleranceMg = const Value.absent(),
    this.status = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WeighingSessionsCompanion.insert({
    required String id,
    this.formulaId = const Value.absent(),
    required String formulaName,
    required String scaleId,
    required String scaleName,
    this.currentStepIndex = const Value.absent(),
    required int plannedTotalDg,
    this.measuredTotalMg = const Value.absent(),
    this.toleranceMg = const Value.absent(),
    required SessionStatus status,
    required DateTime startedAt,
    this.finishedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       formulaName = Value(formulaName),
       scaleId = Value(scaleId),
       scaleName = Value(scaleName),
       plannedTotalDg = Value(plannedTotalDg),
       status = Value(status),
       startedAt = Value(startedAt);
  static Insertable<WeighingSessionRow> custom({
    Expression<String>? id,
    Expression<String>? formulaId,
    Expression<String>? formulaName,
    Expression<String>? scaleId,
    Expression<String>? scaleName,
    Expression<int>? currentStepIndex,
    Expression<int>? plannedTotalDg,
    Expression<int>? measuredTotalMg,
    Expression<int>? toleranceMg,
    Expression<String>? status,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? finishedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (formulaId != null) 'formula_id': formulaId,
      if (formulaName != null) 'formula_name': formulaName,
      if (scaleId != null) 'scale_id': scaleId,
      if (scaleName != null) 'scale_name': scaleName,
      if (currentStepIndex != null) 'current_step_index': currentStepIndex,
      if (plannedTotalDg != null) 'planned_total_dg': plannedTotalDg,
      if (measuredTotalMg != null) 'measured_total_mg': measuredTotalMg,
      if (toleranceMg != null) 'tolerance_mg': toleranceMg,
      if (status != null) 'status': status,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WeighingSessionsCompanion copyWith({
    Value<String>? id,
    Value<String?>? formulaId,
    Value<String>? formulaName,
    Value<String>? scaleId,
    Value<String>? scaleName,
    Value<int>? currentStepIndex,
    Value<int>? plannedTotalDg,
    Value<int?>? measuredTotalMg,
    Value<int?>? toleranceMg,
    Value<SessionStatus>? status,
    Value<DateTime>? startedAt,
    Value<DateTime?>? finishedAt,
    Value<int>? rowid,
  }) {
    return WeighingSessionsCompanion(
      id: id ?? this.id,
      formulaId: formulaId ?? this.formulaId,
      formulaName: formulaName ?? this.formulaName,
      scaleId: scaleId ?? this.scaleId,
      scaleName: scaleName ?? this.scaleName,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      plannedTotalDg: plannedTotalDg ?? this.plannedTotalDg,
      measuredTotalMg: measuredTotalMg ?? this.measuredTotalMg,
      toleranceMg: toleranceMg ?? this.toleranceMg,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (formulaId.present) {
      map['formula_id'] = Variable<String>(formulaId.value);
    }
    if (formulaName.present) {
      map['formula_name'] = Variable<String>(formulaName.value);
    }
    if (scaleId.present) {
      map['scale_id'] = Variable<String>(scaleId.value);
    }
    if (scaleName.present) {
      map['scale_name'] = Variable<String>(scaleName.value);
    }
    if (currentStepIndex.present) {
      map['current_step_index'] = Variable<int>(currentStepIndex.value);
    }
    if (plannedTotalDg.present) {
      map['planned_total_dg'] = Variable<int>(plannedTotalDg.value);
    }
    if (measuredTotalMg.present) {
      map['measured_total_mg'] = Variable<int>(measuredTotalMg.value);
    }
    if (toleranceMg.present) {
      map['tolerance_mg'] = Variable<int>(toleranceMg.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $WeighingSessionsTable.$converterstatus.toSql(status.value),
      );
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<DateTime>(finishedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeighingSessionsCompanion(')
          ..write('id: $id, ')
          ..write('formulaId: $formulaId, ')
          ..write('formulaName: $formulaName, ')
          ..write('scaleId: $scaleId, ')
          ..write('scaleName: $scaleName, ')
          ..write('currentStepIndex: $currentStepIndex, ')
          ..write('plannedTotalDg: $plannedTotalDg, ')
          ..write('measuredTotalMg: $measuredTotalMg, ')
          ..write('toleranceMg: $toleranceMg, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WeighingStepsTable extends WeighingSteps
    with TableInfo<$WeighingStepsTable, WeighingStepRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeighingStepsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES weighing_sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ingredientNameMeta = const VerificationMeta(
    'ingredientName',
  );
  @override
  late final GeneratedColumn<String> ingredientName = GeneratedColumn<String>(
    'ingredient_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayRgbMeta = const VerificationMeta(
    'displayRgb',
  );
  @override
  late final GeneratedColumn<int> displayRgb = GeneratedColumn<int>(
    'display_rgb',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDeveloperMeta = const VerificationMeta(
    'isDeveloper',
  );
  @override
  late final GeneratedColumn<bool> isDeveloper = GeneratedColumn<bool>(
    'is_developer',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_developer" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _targetAddedDgMeta = const VerificationMeta(
    'targetAddedDg',
  );
  @override
  late final GeneratedColumn<int> targetAddedDg = GeneratedColumn<int>(
    'target_added_dg',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetCumulativeDgMeta =
      const VerificationMeta('targetCumulativeDg');
  @override
  late final GeneratedColumn<int> targetCumulativeDg = GeneratedColumn<int>(
    'target_cumulative_dg',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actualCumulativeMgMeta =
      const VerificationMeta('actualCumulativeMg');
  @override
  late final GeneratedColumn<int> actualCumulativeMg = GeneratedColumn<int>(
    'actual_cumulative_mg',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actualAddedMgMeta = const VerificationMeta(
    'actualAddedMg',
  );
  @override
  late final GeneratedColumn<int> actualAddedMg = GeneratedColumn<int>(
    'actual_added_mg',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _confirmedStableMeta = const VerificationMeta(
    'confirmedStable',
  );
  @override
  late final GeneratedColumn<bool> confirmedStable = GeneratedColumn<bool>(
    'confirmed_stable',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("confirmed_stable" IN (0, 1))',
    ),
  );
  static const VerificationMeta _confirmedAtMeta = const VerificationMeta(
    'confirmedAt',
  );
  @override
  late final GeneratedColumn<DateTime> confirmedAt = GeneratedColumn<DateTime>(
    'confirmed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    position,
    ingredientName,
    displayRgb,
    isDeveloper,
    targetAddedDg,
    targetCumulativeDg,
    actualCumulativeMg,
    actualAddedMg,
    confirmedStable,
    confirmedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weighing_steps';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeighingStepRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('ingredient_name')) {
      context.handle(
        _ingredientNameMeta,
        ingredientName.isAcceptableOrUnknown(
          data['ingredient_name']!,
          _ingredientNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ingredientNameMeta);
    }
    if (data.containsKey('display_rgb')) {
      context.handle(
        _displayRgbMeta,
        displayRgb.isAcceptableOrUnknown(data['display_rgb']!, _displayRgbMeta),
      );
    } else if (isInserting) {
      context.missing(_displayRgbMeta);
    }
    if (data.containsKey('is_developer')) {
      context.handle(
        _isDeveloperMeta,
        isDeveloper.isAcceptableOrUnknown(
          data['is_developer']!,
          _isDeveloperMeta,
        ),
      );
    }
    if (data.containsKey('target_added_dg')) {
      context.handle(
        _targetAddedDgMeta,
        targetAddedDg.isAcceptableOrUnknown(
          data['target_added_dg']!,
          _targetAddedDgMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetAddedDgMeta);
    }
    if (data.containsKey('target_cumulative_dg')) {
      context.handle(
        _targetCumulativeDgMeta,
        targetCumulativeDg.isAcceptableOrUnknown(
          data['target_cumulative_dg']!,
          _targetCumulativeDgMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetCumulativeDgMeta);
    }
    if (data.containsKey('actual_cumulative_mg')) {
      context.handle(
        _actualCumulativeMgMeta,
        actualCumulativeMg.isAcceptableOrUnknown(
          data['actual_cumulative_mg']!,
          _actualCumulativeMgMeta,
        ),
      );
    }
    if (data.containsKey('actual_added_mg')) {
      context.handle(
        _actualAddedMgMeta,
        actualAddedMg.isAcceptableOrUnknown(
          data['actual_added_mg']!,
          _actualAddedMgMeta,
        ),
      );
    }
    if (data.containsKey('confirmed_stable')) {
      context.handle(
        _confirmedStableMeta,
        confirmedStable.isAcceptableOrUnknown(
          data['confirmed_stable']!,
          _confirmedStableMeta,
        ),
      );
    }
    if (data.containsKey('confirmed_at')) {
      context.handle(
        _confirmedAtMeta,
        confirmedAt.isAcceptableOrUnknown(
          data['confirmed_at']!,
          _confirmedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeighingStepRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeighingStepRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      ingredientName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ingredient_name'],
      )!,
      displayRgb: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}display_rgb'],
      )!,
      isDeveloper: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_developer'],
      )!,
      targetAddedDg: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_added_dg'],
      )!,
      targetCumulativeDg: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_cumulative_dg'],
      )!,
      actualCumulativeMg: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}actual_cumulative_mg'],
      ),
      actualAddedMg: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}actual_added_mg'],
      ),
      confirmedStable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}confirmed_stable'],
      ),
      confirmedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}confirmed_at'],
      ),
    );
  }

  @override
  $WeighingStepsTable createAlias(String alias) {
    return $WeighingStepsTable(attachedDatabase, alias);
  }
}

class WeighingStepRow extends DataClass implements Insertable<WeighingStepRow> {
  final String id;
  final String sessionId;
  final int position;
  final String ingredientName;
  final int displayRgb;
  final bool isDeveloper;
  final int targetAddedDg;
  final int targetCumulativeDg;
  final int? actualCumulativeMg;
  final int? actualAddedMg;
  final bool? confirmedStable;
  final DateTime? confirmedAt;
  const WeighingStepRow({
    required this.id,
    required this.sessionId,
    required this.position,
    required this.ingredientName,
    required this.displayRgb,
    required this.isDeveloper,
    required this.targetAddedDg,
    required this.targetCumulativeDg,
    this.actualCumulativeMg,
    this.actualAddedMg,
    this.confirmedStable,
    this.confirmedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['position'] = Variable<int>(position);
    map['ingredient_name'] = Variable<String>(ingredientName);
    map['display_rgb'] = Variable<int>(displayRgb);
    map['is_developer'] = Variable<bool>(isDeveloper);
    map['target_added_dg'] = Variable<int>(targetAddedDg);
    map['target_cumulative_dg'] = Variable<int>(targetCumulativeDg);
    if (!nullToAbsent || actualCumulativeMg != null) {
      map['actual_cumulative_mg'] = Variable<int>(actualCumulativeMg);
    }
    if (!nullToAbsent || actualAddedMg != null) {
      map['actual_added_mg'] = Variable<int>(actualAddedMg);
    }
    if (!nullToAbsent || confirmedStable != null) {
      map['confirmed_stable'] = Variable<bool>(confirmedStable);
    }
    if (!nullToAbsent || confirmedAt != null) {
      map['confirmed_at'] = Variable<DateTime>(confirmedAt);
    }
    return map;
  }

  WeighingStepsCompanion toCompanion(bool nullToAbsent) {
    return WeighingStepsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      position: Value(position),
      ingredientName: Value(ingredientName),
      displayRgb: Value(displayRgb),
      isDeveloper: Value(isDeveloper),
      targetAddedDg: Value(targetAddedDg),
      targetCumulativeDg: Value(targetCumulativeDg),
      actualCumulativeMg: actualCumulativeMg == null && nullToAbsent
          ? const Value.absent()
          : Value(actualCumulativeMg),
      actualAddedMg: actualAddedMg == null && nullToAbsent
          ? const Value.absent()
          : Value(actualAddedMg),
      confirmedStable: confirmedStable == null && nullToAbsent
          ? const Value.absent()
          : Value(confirmedStable),
      confirmedAt: confirmedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(confirmedAt),
    );
  }

  factory WeighingStepRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeighingStepRow(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      position: serializer.fromJson<int>(json['position']),
      ingredientName: serializer.fromJson<String>(json['ingredientName']),
      displayRgb: serializer.fromJson<int>(json['displayRgb']),
      isDeveloper: serializer.fromJson<bool>(json['isDeveloper']),
      targetAddedDg: serializer.fromJson<int>(json['targetAddedDg']),
      targetCumulativeDg: serializer.fromJson<int>(json['targetCumulativeDg']),
      actualCumulativeMg: serializer.fromJson<int?>(json['actualCumulativeMg']),
      actualAddedMg: serializer.fromJson<int?>(json['actualAddedMg']),
      confirmedStable: serializer.fromJson<bool?>(json['confirmedStable']),
      confirmedAt: serializer.fromJson<DateTime?>(json['confirmedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'position': serializer.toJson<int>(position),
      'ingredientName': serializer.toJson<String>(ingredientName),
      'displayRgb': serializer.toJson<int>(displayRgb),
      'isDeveloper': serializer.toJson<bool>(isDeveloper),
      'targetAddedDg': serializer.toJson<int>(targetAddedDg),
      'targetCumulativeDg': serializer.toJson<int>(targetCumulativeDg),
      'actualCumulativeMg': serializer.toJson<int?>(actualCumulativeMg),
      'actualAddedMg': serializer.toJson<int?>(actualAddedMg),
      'confirmedStable': serializer.toJson<bool?>(confirmedStable),
      'confirmedAt': serializer.toJson<DateTime?>(confirmedAt),
    };
  }

  WeighingStepRow copyWith({
    String? id,
    String? sessionId,
    int? position,
    String? ingredientName,
    int? displayRgb,
    bool? isDeveloper,
    int? targetAddedDg,
    int? targetCumulativeDg,
    Value<int?> actualCumulativeMg = const Value.absent(),
    Value<int?> actualAddedMg = const Value.absent(),
    Value<bool?> confirmedStable = const Value.absent(),
    Value<DateTime?> confirmedAt = const Value.absent(),
  }) => WeighingStepRow(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    position: position ?? this.position,
    ingredientName: ingredientName ?? this.ingredientName,
    displayRgb: displayRgb ?? this.displayRgb,
    isDeveloper: isDeveloper ?? this.isDeveloper,
    targetAddedDg: targetAddedDg ?? this.targetAddedDg,
    targetCumulativeDg: targetCumulativeDg ?? this.targetCumulativeDg,
    actualCumulativeMg: actualCumulativeMg.present
        ? actualCumulativeMg.value
        : this.actualCumulativeMg,
    actualAddedMg: actualAddedMg.present
        ? actualAddedMg.value
        : this.actualAddedMg,
    confirmedStable: confirmedStable.present
        ? confirmedStable.value
        : this.confirmedStable,
    confirmedAt: confirmedAt.present ? confirmedAt.value : this.confirmedAt,
  );
  WeighingStepRow copyWithCompanion(WeighingStepsCompanion data) {
    return WeighingStepRow(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      position: data.position.present ? data.position.value : this.position,
      ingredientName: data.ingredientName.present
          ? data.ingredientName.value
          : this.ingredientName,
      displayRgb: data.displayRgb.present
          ? data.displayRgb.value
          : this.displayRgb,
      isDeveloper: data.isDeveloper.present
          ? data.isDeveloper.value
          : this.isDeveloper,
      targetAddedDg: data.targetAddedDg.present
          ? data.targetAddedDg.value
          : this.targetAddedDg,
      targetCumulativeDg: data.targetCumulativeDg.present
          ? data.targetCumulativeDg.value
          : this.targetCumulativeDg,
      actualCumulativeMg: data.actualCumulativeMg.present
          ? data.actualCumulativeMg.value
          : this.actualCumulativeMg,
      actualAddedMg: data.actualAddedMg.present
          ? data.actualAddedMg.value
          : this.actualAddedMg,
      confirmedStable: data.confirmedStable.present
          ? data.confirmedStable.value
          : this.confirmedStable,
      confirmedAt: data.confirmedAt.present
          ? data.confirmedAt.value
          : this.confirmedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeighingStepRow(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('position: $position, ')
          ..write('ingredientName: $ingredientName, ')
          ..write('displayRgb: $displayRgb, ')
          ..write('isDeveloper: $isDeveloper, ')
          ..write('targetAddedDg: $targetAddedDg, ')
          ..write('targetCumulativeDg: $targetCumulativeDg, ')
          ..write('actualCumulativeMg: $actualCumulativeMg, ')
          ..write('actualAddedMg: $actualAddedMg, ')
          ..write('confirmedStable: $confirmedStable, ')
          ..write('confirmedAt: $confirmedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    position,
    ingredientName,
    displayRgb,
    isDeveloper,
    targetAddedDg,
    targetCumulativeDg,
    actualCumulativeMg,
    actualAddedMg,
    confirmedStable,
    confirmedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeighingStepRow &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.position == this.position &&
          other.ingredientName == this.ingredientName &&
          other.displayRgb == this.displayRgb &&
          other.isDeveloper == this.isDeveloper &&
          other.targetAddedDg == this.targetAddedDg &&
          other.targetCumulativeDg == this.targetCumulativeDg &&
          other.actualCumulativeMg == this.actualCumulativeMg &&
          other.actualAddedMg == this.actualAddedMg &&
          other.confirmedStable == this.confirmedStable &&
          other.confirmedAt == this.confirmedAt);
}

class WeighingStepsCompanion extends UpdateCompanion<WeighingStepRow> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<int> position;
  final Value<String> ingredientName;
  final Value<int> displayRgb;
  final Value<bool> isDeveloper;
  final Value<int> targetAddedDg;
  final Value<int> targetCumulativeDg;
  final Value<int?> actualCumulativeMg;
  final Value<int?> actualAddedMg;
  final Value<bool?> confirmedStable;
  final Value<DateTime?> confirmedAt;
  final Value<int> rowid;
  const WeighingStepsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.position = const Value.absent(),
    this.ingredientName = const Value.absent(),
    this.displayRgb = const Value.absent(),
    this.isDeveloper = const Value.absent(),
    this.targetAddedDg = const Value.absent(),
    this.targetCumulativeDg = const Value.absent(),
    this.actualCumulativeMg = const Value.absent(),
    this.actualAddedMg = const Value.absent(),
    this.confirmedStable = const Value.absent(),
    this.confirmedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WeighingStepsCompanion.insert({
    required String id,
    required String sessionId,
    required int position,
    required String ingredientName,
    required int displayRgb,
    this.isDeveloper = const Value.absent(),
    required int targetAddedDg,
    required int targetCumulativeDg,
    this.actualCumulativeMg = const Value.absent(),
    this.actualAddedMg = const Value.absent(),
    this.confirmedStable = const Value.absent(),
    this.confirmedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       position = Value(position),
       ingredientName = Value(ingredientName),
       displayRgb = Value(displayRgb),
       targetAddedDg = Value(targetAddedDg),
       targetCumulativeDg = Value(targetCumulativeDg);
  static Insertable<WeighingStepRow> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<int>? position,
    Expression<String>? ingredientName,
    Expression<int>? displayRgb,
    Expression<bool>? isDeveloper,
    Expression<int>? targetAddedDg,
    Expression<int>? targetCumulativeDg,
    Expression<int>? actualCumulativeMg,
    Expression<int>? actualAddedMg,
    Expression<bool>? confirmedStable,
    Expression<DateTime>? confirmedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (position != null) 'position': position,
      if (ingredientName != null) 'ingredient_name': ingredientName,
      if (displayRgb != null) 'display_rgb': displayRgb,
      if (isDeveloper != null) 'is_developer': isDeveloper,
      if (targetAddedDg != null) 'target_added_dg': targetAddedDg,
      if (targetCumulativeDg != null)
        'target_cumulative_dg': targetCumulativeDg,
      if (actualCumulativeMg != null)
        'actual_cumulative_mg': actualCumulativeMg,
      if (actualAddedMg != null) 'actual_added_mg': actualAddedMg,
      if (confirmedStable != null) 'confirmed_stable': confirmedStable,
      if (confirmedAt != null) 'confirmed_at': confirmedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WeighingStepsCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<int>? position,
    Value<String>? ingredientName,
    Value<int>? displayRgb,
    Value<bool>? isDeveloper,
    Value<int>? targetAddedDg,
    Value<int>? targetCumulativeDg,
    Value<int?>? actualCumulativeMg,
    Value<int?>? actualAddedMg,
    Value<bool?>? confirmedStable,
    Value<DateTime?>? confirmedAt,
    Value<int>? rowid,
  }) {
    return WeighingStepsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      position: position ?? this.position,
      ingredientName: ingredientName ?? this.ingredientName,
      displayRgb: displayRgb ?? this.displayRgb,
      isDeveloper: isDeveloper ?? this.isDeveloper,
      targetAddedDg: targetAddedDg ?? this.targetAddedDg,
      targetCumulativeDg: targetCumulativeDg ?? this.targetCumulativeDg,
      actualCumulativeMg: actualCumulativeMg ?? this.actualCumulativeMg,
      actualAddedMg: actualAddedMg ?? this.actualAddedMg,
      confirmedStable: confirmedStable ?? this.confirmedStable,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (ingredientName.present) {
      map['ingredient_name'] = Variable<String>(ingredientName.value);
    }
    if (displayRgb.present) {
      map['display_rgb'] = Variable<int>(displayRgb.value);
    }
    if (isDeveloper.present) {
      map['is_developer'] = Variable<bool>(isDeveloper.value);
    }
    if (targetAddedDg.present) {
      map['target_added_dg'] = Variable<int>(targetAddedDg.value);
    }
    if (targetCumulativeDg.present) {
      map['target_cumulative_dg'] = Variable<int>(targetCumulativeDg.value);
    }
    if (actualCumulativeMg.present) {
      map['actual_cumulative_mg'] = Variable<int>(actualCumulativeMg.value);
    }
    if (actualAddedMg.present) {
      map['actual_added_mg'] = Variable<int>(actualAddedMg.value);
    }
    if (confirmedStable.present) {
      map['confirmed_stable'] = Variable<bool>(confirmedStable.value);
    }
    if (confirmedAt.present) {
      map['confirmed_at'] = Variable<DateTime>(confirmedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeighingStepsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('position: $position, ')
          ..write('ingredientName: $ingredientName, ')
          ..write('displayRgb: $displayRgb, ')
          ..write('isDeveloper: $isDeveloper, ')
          ..write('targetAddedDg: $targetAddedDg, ')
          ..write('targetCumulativeDg: $targetCumulativeDg, ')
          ..write('actualCumulativeMg: $actualCumulativeMg, ')
          ..write('actualAddedMg: $actualAddedMg, ')
          ..write('confirmedStable: $confirmedStable, ')
          ..write('confirmedAt: $confirmedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTableTable extends AppSettingsTable
    with TableInfo<$AppSettingsTableTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTableTable createAlias(String alias) {
    return $AppSettingsTableTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;
  final String value;
  const SettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsTableCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsTableCompanion(key: Value(key), value: Value(value));
  }

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingRow copyWith({String? key, String? value}) =>
      SettingRow(key: key ?? this.key, value: value ?? this.value);
  SettingRow copyWithCompanion(AppSettingsTableCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsTableCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsTableCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsTableCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsTableCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsTableCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsTableCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FormulasTable formulas = $FormulasTable(this);
  late final $FormulaIngredientsTable formulaIngredients =
      $FormulaIngredientsTable(this);
  late final $WeighingSessionsTable weighingSessions = $WeighingSessionsTable(
    this,
  );
  late final $WeighingStepsTable weighingSteps = $WeighingStepsTable(this);
  late final $AppSettingsTableTable appSettingsTable = $AppSettingsTableTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    formulas,
    formulaIngredients,
    weighingSessions,
    weighingSteps,
    appSettingsTable,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'formulas',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('formula_ingredients', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'formulas',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('weighing_sessions', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'weighing_sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('weighing_steps', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$FormulasTableCreateCompanionBuilder = FormulasCompanion Function({
  required String id,
  required String name,
  required int targetRgb,
  Value<String?> presetId,
  Value<bool> isDemo,
  required int totalDyeDg,
  Value<int?> developerRatioHundredths,
  Value<int?> developerVolume,
  Value<int> developerDg,
  required int totalMixtureDg,
  Value<String?> notes,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$FormulasTableUpdateCompanionBuilder = FormulasCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<int> targetRgb,
  Value<String?> presetId,
  Value<bool> isDemo,
  Value<int> totalDyeDg,
  Value<int?> developerRatioHundredths,
  Value<int?> developerVolume,
  Value<int> developerDg,
  Value<int> totalMixtureDg,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$FormulasTableReferences
    extends BaseReferences<_$AppDatabase, $FormulasTable, FormulaRow> {
  $$FormulasTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $FormulaIngredientsTable,
    List<FormulaIngredientRow>
  >
  _formulaIngredientsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.formulaIngredients,
        aliasName: 'formulas__id__formula_ingredients__formula_id',
      );

  $$FormulaIngredientsTableProcessedTableManager get formulaIngredientsRefs {
    final manager = $$FormulaIngredientsTableTableManager(
      $_db,
      $_db.formulaIngredients,
    ).filter((f) => f.formulaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _formulaIngredientsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$WeighingSessionsTable, List<WeighingSessionRow>>
  _weighingSessionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.weighingSessions,
    aliasName: 'formulas__id__weighing_sessions__formula_id',
  );

  $$WeighingSessionsTableProcessedTableManager get weighingSessionsRefs {
    final manager = $$WeighingSessionsTableTableManager(
      $_db,
      $_db.weighingSessions,
    ).filter((f) => f.formulaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _weighingSessionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FormulasTableFilterComposer
    extends Composer<_$AppDatabase, $FormulasTable> {
  $$FormulasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetRgb => $composableBuilder(
    column: $table.targetRgb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get presetId => $composableBuilder(
    column: $table.presetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDemo => $composableBuilder(
    column: $table.isDemo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalDyeDg => $composableBuilder(
    column: $table.totalDyeDg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get developerRatioHundredths => $composableBuilder(
    column: $table.developerRatioHundredths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get developerVolume => $composableBuilder(
    column: $table.developerVolume,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get developerDg => $composableBuilder(
    column: $table.developerDg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalMixtureDg => $composableBuilder(
    column: $table.totalMixtureDg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> formulaIngredientsRefs(
    Expression<bool> Function($$FormulaIngredientsTableFilterComposer f) f,
  ) {
    final $$FormulaIngredientsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.formulaIngredients,
      getReferencedColumn: (t) => t.formulaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FormulaIngredientsTableFilterComposer(
            $db: $db,
            $table: $db.formulaIngredients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> weighingSessionsRefs(
    Expression<bool> Function($$WeighingSessionsTableFilterComposer f) f,
  ) {
    final $$WeighingSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.weighingSessions,
      getReferencedColumn: (t) => t.formulaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WeighingSessionsTableFilterComposer(
            $db: $db,
            $table: $db.weighingSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FormulasTableOrderingComposer
    extends Composer<_$AppDatabase, $FormulasTable> {
  $$FormulasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetRgb => $composableBuilder(
    column: $table.targetRgb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get presetId => $composableBuilder(
    column: $table.presetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDemo => $composableBuilder(
    column: $table.isDemo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalDyeDg => $composableBuilder(
    column: $table.totalDyeDg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get developerRatioHundredths => $composableBuilder(
    column: $table.developerRatioHundredths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get developerVolume => $composableBuilder(
    column: $table.developerVolume,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get developerDg => $composableBuilder(
    column: $table.developerDg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalMixtureDg => $composableBuilder(
    column: $table.totalMixtureDg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FormulasTableAnnotationComposer
    extends Composer<_$AppDatabase, $FormulasTable> {
  $$FormulasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get targetRgb =>
      $composableBuilder(column: $table.targetRgb, builder: (column) => column);

  GeneratedColumn<String> get presetId =>
      $composableBuilder(column: $table.presetId, builder: (column) => column);

  GeneratedColumn<bool> get isDemo =>
      $composableBuilder(column: $table.isDemo, builder: (column) => column);

  GeneratedColumn<int> get totalDyeDg => $composableBuilder(
    column: $table.totalDyeDg,
    builder: (column) => column,
  );

  GeneratedColumn<int> get developerRatioHundredths => $composableBuilder(
    column: $table.developerRatioHundredths,
    builder: (column) => column,
  );

  GeneratedColumn<int> get developerVolume => $composableBuilder(
    column: $table.developerVolume,
    builder: (column) => column,
  );

  GeneratedColumn<int> get developerDg => $composableBuilder(
    column: $table.developerDg,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalMixtureDg => $composableBuilder(
    column: $table.totalMixtureDg,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> formulaIngredientsRefs<T extends Object>(
    Expression<T> Function($$FormulaIngredientsTableAnnotationComposer a) f,
  ) {
    final $$FormulaIngredientsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.formulaIngredients,
          getReferencedColumn: (t) => t.formulaId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FormulaIngredientsTableAnnotationComposer(
                $db: $db,
                $table: $db.formulaIngredients,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> weighingSessionsRefs<T extends Object>(
    Expression<T> Function($$WeighingSessionsTableAnnotationComposer a) f,
  ) {
    final $$WeighingSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.weighingSessions,
      getReferencedColumn: (t) => t.formulaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WeighingSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.weighingSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FormulasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FormulasTable,
          FormulaRow,
          $$FormulasTableFilterComposer,
          $$FormulasTableOrderingComposer,
          $$FormulasTableAnnotationComposer,
          $$FormulasTableCreateCompanionBuilder,
          $$FormulasTableUpdateCompanionBuilder,
          (FormulaRow, $$FormulasTableReferences),
          FormulaRow,
          PrefetchHooks Function({
            bool formulaIngredientsRefs,
            bool weighingSessionsRefs,
          })
        > {
  $$FormulasTableTableManager(_$AppDatabase db, $FormulasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FormulasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FormulasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FormulasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> targetRgb = const Value.absent(),
                Value<String?> presetId = const Value.absent(),
                Value<bool> isDemo = const Value.absent(),
                Value<int> totalDyeDg = const Value.absent(),
                Value<int?> developerRatioHundredths = const Value.absent(),
                Value<int?> developerVolume = const Value.absent(),
                Value<int> developerDg = const Value.absent(),
                Value<int> totalMixtureDg = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FormulasCompanion(
                id: id,
                name: name,
                targetRgb: targetRgb,
                presetId: presetId,
                isDemo: isDemo,
                totalDyeDg: totalDyeDg,
                developerRatioHundredths: developerRatioHundredths,
                developerVolume: developerVolume,
                developerDg: developerDg,
                totalMixtureDg: totalMixtureDg,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required int targetRgb,
                Value<String?> presetId = const Value.absent(),
                Value<bool> isDemo = const Value.absent(),
                required int totalDyeDg,
                Value<int?> developerRatioHundredths = const Value.absent(),
                Value<int?> developerVolume = const Value.absent(),
                Value<int> developerDg = const Value.absent(),
                required int totalMixtureDg,
                Value<String?> notes = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => FormulasCompanion.insert(
                id: id,
                name: name,
                targetRgb: targetRgb,
                presetId: presetId,
                isDemo: isDemo,
                totalDyeDg: totalDyeDg,
                developerRatioHundredths: developerRatioHundredths,
                developerVolume: developerVolume,
                developerDg: developerDg,
                totalMixtureDg: totalMixtureDg,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FormulasTable, FormulaRow>(table),
                  $$FormulasTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({formulaIngredientsRefs = false, weighingSessionsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (formulaIngredientsRefs) db.formulaIngredients,
                    if (weighingSessionsRefs) db.weighingSessions,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (formulaIngredientsRefs)
                        await $_getPrefetchedDataByColumns<
                          FormulaRow,
                          $FormulasTable,
                          FormulaIngredientRow,
                          $FormulaIngredientsTable
                        >(
                          currentTable: table,
                          referencedTable: $$FormulasTableReferences
                              ._formulaIngredientsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FormulasTableReferences(
                                db,
                                table,
                                p0,
                              ).formulaIngredientsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'formula_id',
                          typedResults: items,
                        ),
                      if (weighingSessionsRefs)
                        await $_getPrefetchedDataByColumns<
                          FormulaRow,
                          $FormulasTable,
                          WeighingSessionRow,
                          $WeighingSessionsTable
                        >(
                          currentTable: table,
                          referencedTable: $$FormulasTableReferences
                              ._weighingSessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FormulasTableReferences(
                                db,
                                table,
                                p0,
                              ).weighingSessionsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'formula_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$FormulasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FormulasTable,
      FormulaRow,
      $$FormulasTableFilterComposer,
      $$FormulasTableOrderingComposer,
      $$FormulasTableAnnotationComposer,
      $$FormulasTableCreateCompanionBuilder,
      $$FormulasTableUpdateCompanionBuilder,
      (FormulaRow, $$FormulasTableReferences),
      FormulaRow,
      PrefetchHooks Function({
        bool formulaIngredientsRefs,
        bool weighingSessionsRefs,
      })
    >;
typedef $$FormulaIngredientsTableCreateCompanionBuilder =
    FormulaIngredientsCompanion Function({
      required String id,
      required String formulaId,
      required int position,
      required String name,
      required int percentHundredths,
      required int requiredDg,
      required int displayRgb,
      Value<int> rowid,
    });
typedef $$FormulaIngredientsTableUpdateCompanionBuilder =
    FormulaIngredientsCompanion Function({
      Value<String> id,
      Value<String> formulaId,
      Value<int> position,
      Value<String> name,
      Value<int> percentHundredths,
      Value<int> requiredDg,
      Value<int> displayRgb,
      Value<int> rowid,
    });

final class $$FormulaIngredientsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $FormulaIngredientsTable,
          FormulaIngredientRow
        > {
  $$FormulaIngredientsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $FormulasTable _formulaIdTable(_$AppDatabase db) =>
      db.formulas.createAlias('formula_ingredients__formula_id__formulas__id');

  $$FormulasTableProcessedTableManager get formulaId {
    final $_column = $_itemColumn<String>('formula_id')!;

    final manager = $$FormulasTableTableManager(
      $_db,
      $_db.formulas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_formulaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FormulaIngredientsTableFilterComposer
    extends Composer<_$AppDatabase, $FormulaIngredientsTable> {
  $$FormulaIngredientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get percentHundredths => $composableBuilder(
    column: $table.percentHundredths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get requiredDg => $composableBuilder(
    column: $table.requiredDg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get displayRgb => $composableBuilder(
    column: $table.displayRgb,
    builder: (column) => ColumnFilters(column),
  );

  $$FormulasTableFilterComposer get formulaId {
    final $$FormulasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.formulaId,
      referencedTable: $db.formulas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FormulasTableFilterComposer(
            $db: $db,
            $table: $db.formulas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FormulaIngredientsTableOrderingComposer
    extends Composer<_$AppDatabase, $FormulaIngredientsTable> {
  $$FormulaIngredientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get percentHundredths => $composableBuilder(
    column: $table.percentHundredths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get requiredDg => $composableBuilder(
    column: $table.requiredDg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get displayRgb => $composableBuilder(
    column: $table.displayRgb,
    builder: (column) => ColumnOrderings(column),
  );

  $$FormulasTableOrderingComposer get formulaId {
    final $$FormulasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.formulaId,
      referencedTable: $db.formulas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FormulasTableOrderingComposer(
            $db: $db,
            $table: $db.formulas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FormulaIngredientsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FormulaIngredientsTable> {
  $$FormulaIngredientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get percentHundredths => $composableBuilder(
    column: $table.percentHundredths,
    builder: (column) => column,
  );

  GeneratedColumn<int> get requiredDg => $composableBuilder(
    column: $table.requiredDg,
    builder: (column) => column,
  );

  GeneratedColumn<int> get displayRgb => $composableBuilder(
    column: $table.displayRgb,
    builder: (column) => column,
  );

  $$FormulasTableAnnotationComposer get formulaId {
    final $$FormulasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.formulaId,
      referencedTable: $db.formulas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FormulasTableAnnotationComposer(
            $db: $db,
            $table: $db.formulas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FormulaIngredientsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FormulaIngredientsTable,
          FormulaIngredientRow,
          $$FormulaIngredientsTableFilterComposer,
          $$FormulaIngredientsTableOrderingComposer,
          $$FormulaIngredientsTableAnnotationComposer,
          $$FormulaIngredientsTableCreateCompanionBuilder,
          $$FormulaIngredientsTableUpdateCompanionBuilder,
          (FormulaIngredientRow, $$FormulaIngredientsTableReferences),
          FormulaIngredientRow,
          PrefetchHooks Function({bool formulaId})
        > {
  $$FormulaIngredientsTableTableManager(
    _$AppDatabase db,
    $FormulaIngredientsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FormulaIngredientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FormulaIngredientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FormulaIngredientsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> formulaId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> percentHundredths = const Value.absent(),
                Value<int> requiredDg = const Value.absent(),
                Value<int> displayRgb = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FormulaIngredientsCompanion(
                id: id,
                formulaId: formulaId,
                position: position,
                name: name,
                percentHundredths: percentHundredths,
                requiredDg: requiredDg,
                displayRgb: displayRgb,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String formulaId,
                required int position,
                required String name,
                required int percentHundredths,
                required int requiredDg,
                required int displayRgb,
                Value<int> rowid = const Value.absent(),
              }) => FormulaIngredientsCompanion.insert(
                id: id,
                formulaId: formulaId,
                position: position,
                name: name,
                percentHundredths: percentHundredths,
                requiredDg: requiredDg,
                displayRgb: displayRgb,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FormulaIngredientsTable, FormulaIngredientRow>(
                    table,
                  ),
                  $$FormulaIngredientsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({formulaId = false}) {
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
                    if (formulaId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.formulaId,
                        referencedTable: $$FormulaIngredientsTableReferences
                            ._formulaIdTable(db),
                        referencedColumn: $$FormulaIngredientsTableReferences
                            ._formulaIdTable(db)
                            .id,
                      ) as T;
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

typedef $$FormulaIngredientsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FormulaIngredientsTable,
      FormulaIngredientRow,
      $$FormulaIngredientsTableFilterComposer,
      $$FormulaIngredientsTableOrderingComposer,
      $$FormulaIngredientsTableAnnotationComposer,
      $$FormulaIngredientsTableCreateCompanionBuilder,
      $$FormulaIngredientsTableUpdateCompanionBuilder,
      (FormulaIngredientRow, $$FormulaIngredientsTableReferences),
      FormulaIngredientRow,
      PrefetchHooks Function({bool formulaId})
    >;
typedef $$WeighingSessionsTableCreateCompanionBuilder =
    WeighingSessionsCompanion Function({
      required String id,
      Value<String?> formulaId,
      required String formulaName,
      required String scaleId,
      required String scaleName,
      Value<int> currentStepIndex,
      required int plannedTotalDg,
      Value<int?> measuredTotalMg,
      Value<int?> toleranceMg,
      required SessionStatus status,
      required DateTime startedAt,
      Value<DateTime?> finishedAt,
      Value<int> rowid,
    });
typedef $$WeighingSessionsTableUpdateCompanionBuilder =
    WeighingSessionsCompanion Function({
      Value<String> id,
      Value<String?> formulaId,
      Value<String> formulaName,
      Value<String> scaleId,
      Value<String> scaleName,
      Value<int> currentStepIndex,
      Value<int> plannedTotalDg,
      Value<int?> measuredTotalMg,
      Value<int?> toleranceMg,
      Value<SessionStatus> status,
      Value<DateTime> startedAt,
      Value<DateTime?> finishedAt,
      Value<int> rowid,
    });

final class $$WeighingSessionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $WeighingSessionsTable,
          WeighingSessionRow
        > {
  $$WeighingSessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $FormulasTable _formulaIdTable(_$AppDatabase db) =>
      db.formulas.createAlias('weighing_sessions__formula_id__formulas__id');

  $$FormulasTableProcessedTableManager? get formulaId {
    final $_column = $_itemColumn<String>('formula_id');
    if ($_column == null) return null;
    final manager = $$FormulasTableTableManager(
      $_db,
      $_db.formulas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_formulaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$WeighingStepsTable, List<WeighingStepRow>>
  _weighingStepsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.weighingSteps,
    aliasName: 'weighing_sessions__id__weighing_steps__session_id',
  );

  $$WeighingStepsTableProcessedTableManager get weighingStepsRefs {
    final manager = $$WeighingStepsTableTableManager(
      $_db,
      $_db.weighingSteps,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_weighingStepsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WeighingSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $WeighingSessionsTable> {
  $$WeighingSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get formulaName => $composableBuilder(
    column: $table.formulaName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scaleId => $composableBuilder(
    column: $table.scaleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scaleName => $composableBuilder(
    column: $table.scaleName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentStepIndex => $composableBuilder(
    column: $table.currentStepIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get plannedTotalDg => $composableBuilder(
    column: $table.plannedTotalDg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get measuredTotalMg => $composableBuilder(
    column: $table.measuredTotalMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get toleranceMg => $composableBuilder(
    column: $table.toleranceMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SessionStatus, SessionStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$FormulasTableFilterComposer get formulaId {
    final $$FormulasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.formulaId,
      referencedTable: $db.formulas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FormulasTableFilterComposer(
            $db: $db,
            $table: $db.formulas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> weighingStepsRefs(
    Expression<bool> Function($$WeighingStepsTableFilterComposer f) f,
  ) {
    final $$WeighingStepsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.weighingSteps,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WeighingStepsTableFilterComposer(
            $db: $db,
            $table: $db.weighingSteps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WeighingSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $WeighingSessionsTable> {
  $$WeighingSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get formulaName => $composableBuilder(
    column: $table.formulaName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scaleId => $composableBuilder(
    column: $table.scaleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scaleName => $composableBuilder(
    column: $table.scaleName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentStepIndex => $composableBuilder(
    column: $table.currentStepIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get plannedTotalDg => $composableBuilder(
    column: $table.plannedTotalDg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get measuredTotalMg => $composableBuilder(
    column: $table.measuredTotalMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get toleranceMg => $composableBuilder(
    column: $table.toleranceMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$FormulasTableOrderingComposer get formulaId {
    final $$FormulasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.formulaId,
      referencedTable: $db.formulas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FormulasTableOrderingComposer(
            $db: $db,
            $table: $db.formulas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WeighingSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeighingSessionsTable> {
  $$WeighingSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get formulaName => $composableBuilder(
    column: $table.formulaName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get scaleId =>
      $composableBuilder(column: $table.scaleId, builder: (column) => column);

  GeneratedColumn<String> get scaleName =>
      $composableBuilder(column: $table.scaleName, builder: (column) => column);

  GeneratedColumn<int> get currentStepIndex => $composableBuilder(
    column: $table.currentStepIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get plannedTotalDg => $composableBuilder(
    column: $table.plannedTotalDg,
    builder: (column) => column,
  );

  GeneratedColumn<int> get measuredTotalMg => $composableBuilder(
    column: $table.measuredTotalMg,
    builder: (column) => column,
  );

  GeneratedColumn<int> get toleranceMg => $composableBuilder(
    column: $table.toleranceMg,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<SessionStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );

  $$FormulasTableAnnotationComposer get formulaId {
    final $$FormulasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.formulaId,
      referencedTable: $db.formulas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FormulasTableAnnotationComposer(
            $db: $db,
            $table: $db.formulas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> weighingStepsRefs<T extends Object>(
    Expression<T> Function($$WeighingStepsTableAnnotationComposer a) f,
  ) {
    final $$WeighingStepsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.weighingSteps,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WeighingStepsTableAnnotationComposer(
            $db: $db,
            $table: $db.weighingSteps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WeighingSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeighingSessionsTable,
          WeighingSessionRow,
          $$WeighingSessionsTableFilterComposer,
          $$WeighingSessionsTableOrderingComposer,
          $$WeighingSessionsTableAnnotationComposer,
          $$WeighingSessionsTableCreateCompanionBuilder,
          $$WeighingSessionsTableUpdateCompanionBuilder,
          (WeighingSessionRow, $$WeighingSessionsTableReferences),
          WeighingSessionRow,
          PrefetchHooks Function({bool formulaId, bool weighingStepsRefs})
        > {
  $$WeighingSessionsTableTableManager(
    _$AppDatabase db,
    $WeighingSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeighingSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeighingSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeighingSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> formulaId = const Value.absent(),
                Value<String> formulaName = const Value.absent(),
                Value<String> scaleId = const Value.absent(),
                Value<String> scaleName = const Value.absent(),
                Value<int> currentStepIndex = const Value.absent(),
                Value<int> plannedTotalDg = const Value.absent(),
                Value<int?> measuredTotalMg = const Value.absent(),
                Value<int?> toleranceMg = const Value.absent(),
                Value<SessionStatus> status = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeighingSessionsCompanion(
                id: id,
                formulaId: formulaId,
                formulaName: formulaName,
                scaleId: scaleId,
                scaleName: scaleName,
                currentStepIndex: currentStepIndex,
                plannedTotalDg: plannedTotalDg,
                measuredTotalMg: measuredTotalMg,
                toleranceMg: toleranceMg,
                status: status,
                startedAt: startedAt,
                finishedAt: finishedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> formulaId = const Value.absent(),
                required String formulaName,
                required String scaleId,
                required String scaleName,
                Value<int> currentStepIndex = const Value.absent(),
                required int plannedTotalDg,
                Value<int?> measuredTotalMg = const Value.absent(),
                Value<int?> toleranceMg = const Value.absent(),
                required SessionStatus status,
                required DateTime startedAt,
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeighingSessionsCompanion.insert(
                id: id,
                formulaId: formulaId,
                formulaName: formulaName,
                scaleId: scaleId,
                scaleName: scaleName,
                currentStepIndex: currentStepIndex,
                plannedTotalDg: plannedTotalDg,
                measuredTotalMg: measuredTotalMg,
                toleranceMg: toleranceMg,
                status: status,
                startedAt: startedAt,
                finishedAt: finishedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WeighingSessionsTable, WeighingSessionRow>(
                    table,
                  ),
                  $$WeighingSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({formulaId = false, weighingStepsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (weighingStepsRefs) db.weighingSteps,
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
                        if (formulaId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.formulaId,
                            referencedTable: $$WeighingSessionsTableReferences
                                ._formulaIdTable(db),
                            referencedColumn: $$WeighingSessionsTableReferences
                                ._formulaIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (weighingStepsRefs)
                        await $_getPrefetchedDataByColumns<
                          WeighingSessionRow,
                          $WeighingSessionsTable,
                          WeighingStepRow,
                          $WeighingStepsTable
                        >(
                          currentTable: table,
                          referencedTable: $$WeighingSessionsTableReferences
                              ._weighingStepsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WeighingSessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).weighingStepsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'session_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$WeighingSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeighingSessionsTable,
      WeighingSessionRow,
      $$WeighingSessionsTableFilterComposer,
      $$WeighingSessionsTableOrderingComposer,
      $$WeighingSessionsTableAnnotationComposer,
      $$WeighingSessionsTableCreateCompanionBuilder,
      $$WeighingSessionsTableUpdateCompanionBuilder,
      (WeighingSessionRow, $$WeighingSessionsTableReferences),
      WeighingSessionRow,
      PrefetchHooks Function({bool formulaId, bool weighingStepsRefs})
    >;
typedef $$WeighingStepsTableCreateCompanionBuilder =
    WeighingStepsCompanion Function({
      required String id,
      required String sessionId,
      required int position,
      required String ingredientName,
      required int displayRgb,
      Value<bool> isDeveloper,
      required int targetAddedDg,
      required int targetCumulativeDg,
      Value<int?> actualCumulativeMg,
      Value<int?> actualAddedMg,
      Value<bool?> confirmedStable,
      Value<DateTime?> confirmedAt,
      Value<int> rowid,
    });
typedef $$WeighingStepsTableUpdateCompanionBuilder =
    WeighingStepsCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<int> position,
      Value<String> ingredientName,
      Value<int> displayRgb,
      Value<bool> isDeveloper,
      Value<int> targetAddedDg,
      Value<int> targetCumulativeDg,
      Value<int?> actualCumulativeMg,
      Value<int?> actualAddedMg,
      Value<bool?> confirmedStable,
      Value<DateTime?> confirmedAt,
      Value<int> rowid,
    });

final class $$WeighingStepsTableReferences
    extends
        BaseReferences<_$AppDatabase, $WeighingStepsTable, WeighingStepRow> {
  $$WeighingStepsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WeighingSessionsTable _sessionIdTable(_$AppDatabase db) => db
      .weighingSessions
      .createAlias('weighing_steps__session_id__weighing_sessions__id');

  $$WeighingSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$WeighingSessionsTableTableManager(
      $_db,
      $_db.weighingSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WeighingStepsTableFilterComposer
    extends Composer<_$AppDatabase, $WeighingStepsTable> {
  $$WeighingStepsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ingredientName => $composableBuilder(
    column: $table.ingredientName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get displayRgb => $composableBuilder(
    column: $table.displayRgb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeveloper => $composableBuilder(
    column: $table.isDeveloper,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetAddedDg => $composableBuilder(
    column: $table.targetAddedDg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetCumulativeDg => $composableBuilder(
    column: $table.targetCumulativeDg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get actualCumulativeMg => $composableBuilder(
    column: $table.actualCumulativeMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get actualAddedMg => $composableBuilder(
    column: $table.actualAddedMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get confirmedStable => $composableBuilder(
    column: $table.confirmedStable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WeighingSessionsTableFilterComposer get sessionId {
    final $$WeighingSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.weighingSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WeighingSessionsTableFilterComposer(
            $db: $db,
            $table: $db.weighingSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WeighingStepsTableOrderingComposer
    extends Composer<_$AppDatabase, $WeighingStepsTable> {
  $$WeighingStepsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ingredientName => $composableBuilder(
    column: $table.ingredientName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get displayRgb => $composableBuilder(
    column: $table.displayRgb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeveloper => $composableBuilder(
    column: $table.isDeveloper,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetAddedDg => $composableBuilder(
    column: $table.targetAddedDg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetCumulativeDg => $composableBuilder(
    column: $table.targetCumulativeDg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get actualCumulativeMg => $composableBuilder(
    column: $table.actualCumulativeMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get actualAddedMg => $composableBuilder(
    column: $table.actualAddedMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get confirmedStable => $composableBuilder(
    column: $table.confirmedStable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WeighingSessionsTableOrderingComposer get sessionId {
    final $$WeighingSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.weighingSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WeighingSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.weighingSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WeighingStepsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeighingStepsTable> {
  $$WeighingStepsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get ingredientName => $composableBuilder(
    column: $table.ingredientName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get displayRgb => $composableBuilder(
    column: $table.displayRgb,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeveloper => $composableBuilder(
    column: $table.isDeveloper,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetAddedDg => $composableBuilder(
    column: $table.targetAddedDg,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetCumulativeDg => $composableBuilder(
    column: $table.targetCumulativeDg,
    builder: (column) => column,
  );

  GeneratedColumn<int> get actualCumulativeMg => $composableBuilder(
    column: $table.actualCumulativeMg,
    builder: (column) => column,
  );

  GeneratedColumn<int> get actualAddedMg => $composableBuilder(
    column: $table.actualAddedMg,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get confirmedStable => $composableBuilder(
    column: $table.confirmedStable,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => column,
  );

  $$WeighingSessionsTableAnnotationComposer get sessionId {
    final $$WeighingSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.weighingSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WeighingSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.weighingSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WeighingStepsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeighingStepsTable,
          WeighingStepRow,
          $$WeighingStepsTableFilterComposer,
          $$WeighingStepsTableOrderingComposer,
          $$WeighingStepsTableAnnotationComposer,
          $$WeighingStepsTableCreateCompanionBuilder,
          $$WeighingStepsTableUpdateCompanionBuilder,
          (WeighingStepRow, $$WeighingStepsTableReferences),
          WeighingStepRow,
          PrefetchHooks Function({bool sessionId})
        > {
  $$WeighingStepsTableTableManager(_$AppDatabase db, $WeighingStepsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeighingStepsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeighingStepsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeighingStepsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> ingredientName = const Value.absent(),
                Value<int> displayRgb = const Value.absent(),
                Value<bool> isDeveloper = const Value.absent(),
                Value<int> targetAddedDg = const Value.absent(),
                Value<int> targetCumulativeDg = const Value.absent(),
                Value<int?> actualCumulativeMg = const Value.absent(),
                Value<int?> actualAddedMg = const Value.absent(),
                Value<bool?> confirmedStable = const Value.absent(),
                Value<DateTime?> confirmedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeighingStepsCompanion(
                id: id,
                sessionId: sessionId,
                position: position,
                ingredientName: ingredientName,
                displayRgb: displayRgb,
                isDeveloper: isDeveloper,
                targetAddedDg: targetAddedDg,
                targetCumulativeDg: targetCumulativeDg,
                actualCumulativeMg: actualCumulativeMg,
                actualAddedMg: actualAddedMg,
                confirmedStable: confirmedStable,
                confirmedAt: confirmedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required int position,
                required String ingredientName,
                required int displayRgb,
                Value<bool> isDeveloper = const Value.absent(),
                required int targetAddedDg,
                required int targetCumulativeDg,
                Value<int?> actualCumulativeMg = const Value.absent(),
                Value<int?> actualAddedMg = const Value.absent(),
                Value<bool?> confirmedStable = const Value.absent(),
                Value<DateTime?> confirmedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeighingStepsCompanion.insert(
                id: id,
                sessionId: sessionId,
                position: position,
                ingredientName: ingredientName,
                displayRgb: displayRgb,
                isDeveloper: isDeveloper,
                targetAddedDg: targetAddedDg,
                targetCumulativeDg: targetCumulativeDg,
                actualCumulativeMg: actualCumulativeMg,
                actualAddedMg: actualAddedMg,
                confirmedStable: confirmedStable,
                confirmedAt: confirmedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WeighingStepsTable, WeighingStepRow>(table),
                  $$WeighingStepsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
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
                    if (sessionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sessionId,
                        referencedTable: $$WeighingStepsTableReferences
                            ._sessionIdTable(db),
                        referencedColumn: $$WeighingStepsTableReferences
                            ._sessionIdTable(db)
                            .id,
                      ) as T;
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

typedef $$WeighingStepsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeighingStepsTable,
      WeighingStepRow,
      $$WeighingStepsTableFilterComposer,
      $$WeighingStepsTableOrderingComposer,
      $$WeighingStepsTableAnnotationComposer,
      $$WeighingStepsTableCreateCompanionBuilder,
      $$WeighingStepsTableUpdateCompanionBuilder,
      (WeighingStepRow, $$WeighingStepsTableReferences),
      WeighingStepRow,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$AppSettingsTableTableCreateCompanionBuilder =
    AppSettingsTableCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableTableUpdateCompanionBuilder =
    AppSettingsTableCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTableTable> {
  $$AppSettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTableTable> {
  $$AppSettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTableTable> {
  $$AppSettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTableTable,
          SettingRow,
          $$AppSettingsTableTableFilterComposer,
          $$AppSettingsTableTableOrderingComposer,
          $$AppSettingsTableTableAnnotationComposer,
          $$AppSettingsTableTableCreateCompanionBuilder,
          $$AppSettingsTableTableUpdateCompanionBuilder,
          (
            SettingRow,
            BaseReferences<_$AppDatabase, $AppSettingsTableTable, SettingRow>,
          ),
          SettingRow,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableTableManager(
    _$AppDatabase db,
    $AppSettingsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AppSettingsTableCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsTableCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTableTable, SettingRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AppSettingsTableTable,
                    SettingRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTableTable,
      SettingRow,
      $$AppSettingsTableTableFilterComposer,
      $$AppSettingsTableTableOrderingComposer,
      $$AppSettingsTableTableAnnotationComposer,
      $$AppSettingsTableTableCreateCompanionBuilder,
      $$AppSettingsTableTableUpdateCompanionBuilder,
      (
        SettingRow,
        BaseReferences<_$AppDatabase, $AppSettingsTableTable, SettingRow>,
      ),
      SettingRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FormulasTableTableManager get formulas =>
      $$FormulasTableTableManager(_db, _db.formulas);
  $$FormulaIngredientsTableTableManager get formulaIngredients =>
      $$FormulaIngredientsTableTableManager(_db, _db.formulaIngredients);
  $$WeighingSessionsTableTableManager get weighingSessions =>
      $$WeighingSessionsTableTableManager(_db, _db.weighingSessions);
  $$WeighingStepsTableTableManager get weighingSteps =>
      $$WeighingStepsTableTableManager(_db, _db.weighingSteps);
  $$AppSettingsTableTableTableManager get appSettingsTable =>
      $$AppSettingsTableTableTableManager(_db, _db.appSettingsTable);
}
