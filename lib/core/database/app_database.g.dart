// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ScanHistoryTable extends ScanHistory
    with TableInfo<$ScanHistoryTable, ScanHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScanHistoryTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _photoNameMeta = const VerificationMeta(
    'photoName',
  );
  @override
  late final GeneratedColumn<String> photoName = GeneratedColumn<String>(
    'photo_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _viewJsonMeta = const VerificationMeta(
    'viewJson',
  );
  @override
  late final GeneratedColumn<String> viewJson = GeneratedColumn<String>(
    'view_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bestTitleMeta = const VerificationMeta(
    'bestTitle',
  );
  @override
  late final GeneratedColumn<String> bestTitle = GeneratedColumn<String>(
    'best_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bestProducerMeta = const VerificationMeta(
    'bestProducer',
  );
  @override
  late final GeneratedColumn<String> bestProducer = GeneratedColumn<String>(
    'best_producer',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bestSlugMeta = const VerificationMeta(
    'bestSlug',
  );
  @override
  late final GeneratedColumn<String> bestSlug = GeneratedColumn<String>(
    'best_slug',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bestReferenceMeta = const VerificationMeta(
    'bestReference',
  );
  @override
  late final GeneratedColumn<String> bestReference = GeneratedColumn<String>(
    'best_reference',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bottleCountMeta = const VerificationMeta(
    'bottleCount',
  );
  @override
  late final GeneratedColumn<int> bottleCount = GeneratedColumn<int>(
    'bottle_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    photoName,
    viewJson,
    bestTitle,
    bestProducer,
    bestSlug,
    bestReference,
    bottleCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scan_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScanHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('photo_name')) {
      context.handle(
        _photoNameMeta,
        photoName.isAcceptableOrUnknown(data['photo_name']!, _photoNameMeta),
      );
    } else if (isInserting) {
      context.missing(_photoNameMeta);
    }
    if (data.containsKey('view_json')) {
      context.handle(
        _viewJsonMeta,
        viewJson.isAcceptableOrUnknown(data['view_json']!, _viewJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_viewJsonMeta);
    }
    if (data.containsKey('best_title')) {
      context.handle(
        _bestTitleMeta,
        bestTitle.isAcceptableOrUnknown(data['best_title']!, _bestTitleMeta),
      );
    }
    if (data.containsKey('best_producer')) {
      context.handle(
        _bestProducerMeta,
        bestProducer.isAcceptableOrUnknown(
          data['best_producer']!,
          _bestProducerMeta,
        ),
      );
    }
    if (data.containsKey('best_slug')) {
      context.handle(
        _bestSlugMeta,
        bestSlug.isAcceptableOrUnknown(data['best_slug']!, _bestSlugMeta),
      );
    }
    if (data.containsKey('best_reference')) {
      context.handle(
        _bestReferenceMeta,
        bestReference.isAcceptableOrUnknown(
          data['best_reference']!,
          _bestReferenceMeta,
        ),
      );
    }
    if (data.containsKey('bottle_count')) {
      context.handle(
        _bottleCountMeta,
        bottleCount.isAcceptableOrUnknown(
          data['bottle_count']!,
          _bottleCountMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScanHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScanHistoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      photoName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_name'],
      )!,
      viewJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}view_json'],
      )!,
      bestTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}best_title'],
      ),
      bestProducer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}best_producer'],
      ),
      bestSlug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}best_slug'],
      ),
      bestReference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}best_reference'],
      ),
      bottleCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bottle_count'],
      )!,
    );
  }

  @override
  $ScanHistoryTable createAlias(String alias) {
    return $ScanHistoryTable(attachedDatabase, alias);
  }
}

class ScanHistoryData extends DataClass implements Insertable<ScanHistoryData> {
  final int id;
  final DateTime createdAt;

  /// File name of the photo in `ScanPhotoStore` — a name, not a path: the
  /// app's container moves between iOS updates.
  final String photoName;

  /// The `view` object of the automatic answer, JSON-encoded, re-read with
  /// `RecognitionView.fromJson` when the scan is opened again.
  final String viewJson;
  final String? bestTitle;
  final String? bestProducer;
  final String? bestSlug;

  /// Relative reference path of the best card, for the row thumbnail.
  final String? bestReference;
  final int bottleCount;
  const ScanHistoryData({
    required this.id,
    required this.createdAt,
    required this.photoName,
    required this.viewJson,
    this.bestTitle,
    this.bestProducer,
    this.bestSlug,
    this.bestReference,
    required this.bottleCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['photo_name'] = Variable<String>(photoName);
    map['view_json'] = Variable<String>(viewJson);
    if (!nullToAbsent || bestTitle != null) {
      map['best_title'] = Variable<String>(bestTitle);
    }
    if (!nullToAbsent || bestProducer != null) {
      map['best_producer'] = Variable<String>(bestProducer);
    }
    if (!nullToAbsent || bestSlug != null) {
      map['best_slug'] = Variable<String>(bestSlug);
    }
    if (!nullToAbsent || bestReference != null) {
      map['best_reference'] = Variable<String>(bestReference);
    }
    map['bottle_count'] = Variable<int>(bottleCount);
    return map;
  }

  ScanHistoryCompanion toCompanion(bool nullToAbsent) {
    return ScanHistoryCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      photoName: Value(photoName),
      viewJson: Value(viewJson),
      bestTitle: bestTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(bestTitle),
      bestProducer: bestProducer == null && nullToAbsent
          ? const Value.absent()
          : Value(bestProducer),
      bestSlug: bestSlug == null && nullToAbsent
          ? const Value.absent()
          : Value(bestSlug),
      bestReference: bestReference == null && nullToAbsent
          ? const Value.absent()
          : Value(bestReference),
      bottleCount: Value(bottleCount),
    );
  }

  factory ScanHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScanHistoryData(
      id: serializer.fromJson<int>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      photoName: serializer.fromJson<String>(json['photoName']),
      viewJson: serializer.fromJson<String>(json['viewJson']),
      bestTitle: serializer.fromJson<String?>(json['bestTitle']),
      bestProducer: serializer.fromJson<String?>(json['bestProducer']),
      bestSlug: serializer.fromJson<String?>(json['bestSlug']),
      bestReference: serializer.fromJson<String?>(json['bestReference']),
      bottleCount: serializer.fromJson<int>(json['bottleCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'photoName': serializer.toJson<String>(photoName),
      'viewJson': serializer.toJson<String>(viewJson),
      'bestTitle': serializer.toJson<String?>(bestTitle),
      'bestProducer': serializer.toJson<String?>(bestProducer),
      'bestSlug': serializer.toJson<String?>(bestSlug),
      'bestReference': serializer.toJson<String?>(bestReference),
      'bottleCount': serializer.toJson<int>(bottleCount),
    };
  }

  ScanHistoryData copyWith({
    int? id,
    DateTime? createdAt,
    String? photoName,
    String? viewJson,
    Value<String?> bestTitle = const Value.absent(),
    Value<String?> bestProducer = const Value.absent(),
    Value<String?> bestSlug = const Value.absent(),
    Value<String?> bestReference = const Value.absent(),
    int? bottleCount,
  }) => ScanHistoryData(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    photoName: photoName ?? this.photoName,
    viewJson: viewJson ?? this.viewJson,
    bestTitle: bestTitle.present ? bestTitle.value : this.bestTitle,
    bestProducer: bestProducer.present ? bestProducer.value : this.bestProducer,
    bestSlug: bestSlug.present ? bestSlug.value : this.bestSlug,
    bestReference: bestReference.present
        ? bestReference.value
        : this.bestReference,
    bottleCount: bottleCount ?? this.bottleCount,
  );
  ScanHistoryData copyWithCompanion(ScanHistoryCompanion data) {
    return ScanHistoryData(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      photoName: data.photoName.present ? data.photoName.value : this.photoName,
      viewJson: data.viewJson.present ? data.viewJson.value : this.viewJson,
      bestTitle: data.bestTitle.present ? data.bestTitle.value : this.bestTitle,
      bestProducer: data.bestProducer.present
          ? data.bestProducer.value
          : this.bestProducer,
      bestSlug: data.bestSlug.present ? data.bestSlug.value : this.bestSlug,
      bestReference: data.bestReference.present
          ? data.bestReference.value
          : this.bestReference,
      bottleCount: data.bottleCount.present
          ? data.bottleCount.value
          : this.bottleCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScanHistoryData(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('photoName: $photoName, ')
          ..write('viewJson: $viewJson, ')
          ..write('bestTitle: $bestTitle, ')
          ..write('bestProducer: $bestProducer, ')
          ..write('bestSlug: $bestSlug, ')
          ..write('bestReference: $bestReference, ')
          ..write('bottleCount: $bottleCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    photoName,
    viewJson,
    bestTitle,
    bestProducer,
    bestSlug,
    bestReference,
    bottleCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScanHistoryData &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.photoName == this.photoName &&
          other.viewJson == this.viewJson &&
          other.bestTitle == this.bestTitle &&
          other.bestProducer == this.bestProducer &&
          other.bestSlug == this.bestSlug &&
          other.bestReference == this.bestReference &&
          other.bottleCount == this.bottleCount);
}

class ScanHistoryCompanion extends UpdateCompanion<ScanHistoryData> {
  final Value<int> id;
  final Value<DateTime> createdAt;
  final Value<String> photoName;
  final Value<String> viewJson;
  final Value<String?> bestTitle;
  final Value<String?> bestProducer;
  final Value<String?> bestSlug;
  final Value<String?> bestReference;
  final Value<int> bottleCount;
  const ScanHistoryCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.photoName = const Value.absent(),
    this.viewJson = const Value.absent(),
    this.bestTitle = const Value.absent(),
    this.bestProducer = const Value.absent(),
    this.bestSlug = const Value.absent(),
    this.bestReference = const Value.absent(),
    this.bottleCount = const Value.absent(),
  });
  ScanHistoryCompanion.insert({
    this.id = const Value.absent(),
    required DateTime createdAt,
    required String photoName,
    required String viewJson,
    this.bestTitle = const Value.absent(),
    this.bestProducer = const Value.absent(),
    this.bestSlug = const Value.absent(),
    this.bestReference = const Value.absent(),
    this.bottleCount = const Value.absent(),
  }) : createdAt = Value(createdAt),
       photoName = Value(photoName),
       viewJson = Value(viewJson);
  static Insertable<ScanHistoryData> custom({
    Expression<int>? id,
    Expression<DateTime>? createdAt,
    Expression<String>? photoName,
    Expression<String>? viewJson,
    Expression<String>? bestTitle,
    Expression<String>? bestProducer,
    Expression<String>? bestSlug,
    Expression<String>? bestReference,
    Expression<int>? bottleCount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (photoName != null) 'photo_name': photoName,
      if (viewJson != null) 'view_json': viewJson,
      if (bestTitle != null) 'best_title': bestTitle,
      if (bestProducer != null) 'best_producer': bestProducer,
      if (bestSlug != null) 'best_slug': bestSlug,
      if (bestReference != null) 'best_reference': bestReference,
      if (bottleCount != null) 'bottle_count': bottleCount,
    });
  }

  ScanHistoryCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? createdAt,
    Value<String>? photoName,
    Value<String>? viewJson,
    Value<String?>? bestTitle,
    Value<String?>? bestProducer,
    Value<String?>? bestSlug,
    Value<String?>? bestReference,
    Value<int>? bottleCount,
  }) {
    return ScanHistoryCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      photoName: photoName ?? this.photoName,
      viewJson: viewJson ?? this.viewJson,
      bestTitle: bestTitle ?? this.bestTitle,
      bestProducer: bestProducer ?? this.bestProducer,
      bestSlug: bestSlug ?? this.bestSlug,
      bestReference: bestReference ?? this.bestReference,
      bottleCount: bottleCount ?? this.bottleCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (photoName.present) {
      map['photo_name'] = Variable<String>(photoName.value);
    }
    if (viewJson.present) {
      map['view_json'] = Variable<String>(viewJson.value);
    }
    if (bestTitle.present) {
      map['best_title'] = Variable<String>(bestTitle.value);
    }
    if (bestProducer.present) {
      map['best_producer'] = Variable<String>(bestProducer.value);
    }
    if (bestSlug.present) {
      map['best_slug'] = Variable<String>(bestSlug.value);
    }
    if (bestReference.present) {
      map['best_reference'] = Variable<String>(bestReference.value);
    }
    if (bottleCount.present) {
      map['bottle_count'] = Variable<int>(bottleCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScanHistoryCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('photoName: $photoName, ')
          ..write('viewJson: $viewJson, ')
          ..write('bestTitle: $bestTitle, ')
          ..write('bestProducer: $bestProducer, ')
          ..write('bestSlug: $bestSlug, ')
          ..write('bestReference: $bestReference, ')
          ..write('bottleCount: $bottleCount')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ScanHistoryTable scanHistory = $ScanHistoryTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [scanHistory];
}

typedef $$ScanHistoryTableCreateCompanionBuilder =
    ScanHistoryCompanion Function({
      Value<int> id,
      required DateTime createdAt,
      required String photoName,
      required String viewJson,
      Value<String?> bestTitle,
      Value<String?> bestProducer,
      Value<String?> bestSlug,
      Value<String?> bestReference,
      Value<int> bottleCount,
    });
typedef $$ScanHistoryTableUpdateCompanionBuilder =
    ScanHistoryCompanion Function({
      Value<int> id,
      Value<DateTime> createdAt,
      Value<String> photoName,
      Value<String> viewJson,
      Value<String?> bestTitle,
      Value<String?> bestProducer,
      Value<String?> bestSlug,
      Value<String?> bestReference,
      Value<int> bottleCount,
    });

class $$ScanHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $ScanHistoryTable> {
  $$ScanHistoryTableFilterComposer({
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoName => $composableBuilder(
    column: $table.photoName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get viewJson => $composableBuilder(
    column: $table.viewJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bestTitle => $composableBuilder(
    column: $table.bestTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bestProducer => $composableBuilder(
    column: $table.bestProducer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bestSlug => $composableBuilder(
    column: $table.bestSlug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bestReference => $composableBuilder(
    column: $table.bestReference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bottleCount => $composableBuilder(
    column: $table.bottleCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ScanHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $ScanHistoryTable> {
  $$ScanHistoryTableOrderingComposer({
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoName => $composableBuilder(
    column: $table.photoName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get viewJson => $composableBuilder(
    column: $table.viewJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bestTitle => $composableBuilder(
    column: $table.bestTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bestProducer => $composableBuilder(
    column: $table.bestProducer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bestSlug => $composableBuilder(
    column: $table.bestSlug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bestReference => $composableBuilder(
    column: $table.bestReference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bottleCount => $composableBuilder(
    column: $table.bottleCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ScanHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScanHistoryTable> {
  $$ScanHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get photoName =>
      $composableBuilder(column: $table.photoName, builder: (column) => column);

  GeneratedColumn<String> get viewJson =>
      $composableBuilder(column: $table.viewJson, builder: (column) => column);

  GeneratedColumn<String> get bestTitle =>
      $composableBuilder(column: $table.bestTitle, builder: (column) => column);

  GeneratedColumn<String> get bestProducer => $composableBuilder(
    column: $table.bestProducer,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bestSlug =>
      $composableBuilder(column: $table.bestSlug, builder: (column) => column);

  GeneratedColumn<String> get bestReference => $composableBuilder(
    column: $table.bestReference,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bottleCount => $composableBuilder(
    column: $table.bottleCount,
    builder: (column) => column,
  );
}

class $$ScanHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScanHistoryTable,
          ScanHistoryData,
          $$ScanHistoryTableFilterComposer,
          $$ScanHistoryTableOrderingComposer,
          $$ScanHistoryTableAnnotationComposer,
          $$ScanHistoryTableCreateCompanionBuilder,
          $$ScanHistoryTableUpdateCompanionBuilder,
          (
            ScanHistoryData,
            BaseReferences<_$AppDatabase, $ScanHistoryTable, ScanHistoryData>,
          ),
          ScanHistoryData,
          PrefetchHooks Function()
        > {
  $$ScanHistoryTableTableManager(_$AppDatabase db, $ScanHistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScanHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScanHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScanHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> photoName = const Value.absent(),
                Value<String> viewJson = const Value.absent(),
                Value<String?> bestTitle = const Value.absent(),
                Value<String?> bestProducer = const Value.absent(),
                Value<String?> bestSlug = const Value.absent(),
                Value<String?> bestReference = const Value.absent(),
                Value<int> bottleCount = const Value.absent(),
              }) => ScanHistoryCompanion(
                id: id,
                createdAt: createdAt,
                photoName: photoName,
                viewJson: viewJson,
                bestTitle: bestTitle,
                bestProducer: bestProducer,
                bestSlug: bestSlug,
                bestReference: bestReference,
                bottleCount: bottleCount,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime createdAt,
                required String photoName,
                required String viewJson,
                Value<String?> bestTitle = const Value.absent(),
                Value<String?> bestProducer = const Value.absent(),
                Value<String?> bestSlug = const Value.absent(),
                Value<String?> bestReference = const Value.absent(),
                Value<int> bottleCount = const Value.absent(),
              }) => ScanHistoryCompanion.insert(
                id: id,
                createdAt: createdAt,
                photoName: photoName,
                viewJson: viewJson,
                bestTitle: bestTitle,
                bestProducer: bestProducer,
                bestSlug: bestSlug,
                bestReference: bestReference,
                bottleCount: bottleCount,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ScanHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScanHistoryTable,
      ScanHistoryData,
      $$ScanHistoryTableFilterComposer,
      $$ScanHistoryTableOrderingComposer,
      $$ScanHistoryTableAnnotationComposer,
      $$ScanHistoryTableCreateCompanionBuilder,
      $$ScanHistoryTableUpdateCompanionBuilder,
      (
        ScanHistoryData,
        BaseReferences<_$AppDatabase, $ScanHistoryTable, ScanHistoryData>,
      ),
      ScanHistoryData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ScanHistoryTableTableManager get scanHistory =>
      $$ScanHistoryTableTableManager(_db, _db.scanHistory);
}
