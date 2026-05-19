// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'global_database.dart';

// ignore_for_file: type=lint
class $WorkspacesTableTable extends WorkspacesTable
    with TableInfo<$WorkspacesTableTable, WorkspacesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkspacesTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _logoPathMeta = const VerificationMeta(
    'logoPath',
  );
  @override
  late final GeneratedColumn<String> logoPath = GeneratedColumn<String>(
    'logo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ownerUserIdMeta = const VerificationMeta(
    'ownerUserId',
  );
  @override
  late final GeneratedColumn<String> ownerUserId = GeneratedColumn<String>(
    'owner_user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _secretExcludeGlobsMeta =
      const VerificationMeta('secretExcludeGlobs');
  @override
  late final GeneratedColumn<String> secretExcludeGlobs =
      GeneratedColumn<String>(
        'secret_exclude_globs',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _reviewConcurrencyMeta = const VerificationMeta(
    'reviewConcurrency',
  );
  @override
  late final GeneratedColumn<int> reviewConcurrency = GeneratedColumn<int>(
    'review_concurrency',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(3),
  );
  static const VerificationMeta _autoPublishReviewMeta = const VerificationMeta(
    'autoPublishReview',
  );
  @override
  late final GeneratedColumn<bool> autoPublishReview = GeneratedColumn<bool>(
    'auto_publish_review',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_publish_review" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    logoPath,
    ownerUserId,
    secretExcludeGlobs,
    reviewConcurrency,
    autoPublishReview,
    position,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workspaces';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkspacesTableData> instance, {
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
    if (data.containsKey('logo_path')) {
      context.handle(
        _logoPathMeta,
        logoPath.isAcceptableOrUnknown(data['logo_path']!, _logoPathMeta),
      );
    }
    if (data.containsKey('owner_user_id')) {
      context.handle(
        _ownerUserIdMeta,
        ownerUserId.isAcceptableOrUnknown(
          data['owner_user_id']!,
          _ownerUserIdMeta,
        ),
      );
    }
    if (data.containsKey('secret_exclude_globs')) {
      context.handle(
        _secretExcludeGlobsMeta,
        secretExcludeGlobs.isAcceptableOrUnknown(
          data['secret_exclude_globs']!,
          _secretExcludeGlobsMeta,
        ),
      );
    }
    if (data.containsKey('review_concurrency')) {
      context.handle(
        _reviewConcurrencyMeta,
        reviewConcurrency.isAcceptableOrUnknown(
          data['review_concurrency']!,
          _reviewConcurrencyMeta,
        ),
      );
    }
    if (data.containsKey('auto_publish_review')) {
      context.handle(
        _autoPublishReviewMeta,
        autoPublishReview.isAcceptableOrUnknown(
          data['auto_publish_review']!,
          _autoPublishReviewMeta,
        ),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkspacesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkspacesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      logoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}logo_path'],
      ),
      ownerUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_user_id'],
      ),
      secretExcludeGlobs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}secret_exclude_globs'],
      )!,
      reviewConcurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}review_concurrency'],
      )!,
      autoPublishReview: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_publish_review'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $WorkspacesTableTable createAlias(String alias) {
    return $WorkspacesTableTable(attachedDatabase, alias);
  }
}

class WorkspacesTableData extends DataClass
    implements Insertable<WorkspacesTableData> {
  /// Unique workspace identifier.
  final String id;

  /// Workspace display name (user-supplied at creation).
  final String name;

  /// Optional path to a local image file used as the workspace logo.
  final String? logoPath;

  /// The user who owns this workspace (holds the `owner` membership role).
  /// Nullable in SQL only until the identity bootstrap backfills it on first
  /// boot; treated as required everywhere else.
  final String? ownerUserId;

  /// JSON array of glob patterns whose matching paths are hard-blocked from
  /// guest/viewer visibility on code-bearing surfaces (secret exclusion).
  final String secretExcludeGlobs;

  /// Default fan-out for parallel reviewer dispatch on this workspace.
  /// `dispatch_reviewers` MCP tool uses this when no explicit `concurrency`
  /// argument is provided.
  final int reviewConcurrency;

  /// Whether a completed review publishes to GitHub automatically (opt-in;
  /// off by default — publishing is otherwise user-gated behind the
  /// "Publish to GitHub" action, which itself stays ActionClass-guarded).
  final bool autoPublishReview;

  /// The operator's manual order for the workspace switcher / manager
  /// (drag-to-reorder in "manage workspaces"). Lower sorts first;
  /// [createdAt] is the stable tiebreak. Mirrors `repos.position` — one manual
  /// order per list, server-owned, so every client (desktop/web/phone) renders
  /// workspaces in the same sequence.
  final int position;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last update timestamp.
  final DateTime updatedAt;

  /// Soft-delete timestamp. When non-null, the workspace is considered deleted.
  final DateTime? deletedAt;
  const WorkspacesTableData({
    required this.id,
    required this.name,
    this.logoPath,
    this.ownerUserId,
    required this.secretExcludeGlobs,
    required this.reviewConcurrency,
    required this.autoPublishReview,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || logoPath != null) {
      map['logo_path'] = Variable<String>(logoPath);
    }
    if (!nullToAbsent || ownerUserId != null) {
      map['owner_user_id'] = Variable<String>(ownerUserId);
    }
    map['secret_exclude_globs'] = Variable<String>(secretExcludeGlobs);
    map['review_concurrency'] = Variable<int>(reviewConcurrency);
    map['auto_publish_review'] = Variable<bool>(autoPublishReview);
    map['position'] = Variable<int>(position);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  WorkspacesTableCompanion toCompanion(bool nullToAbsent) {
    return WorkspacesTableCompanion(
      id: Value(id),
      name: Value(name),
      logoPath: logoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(logoPath),
      ownerUserId: ownerUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerUserId),
      secretExcludeGlobs: Value(secretExcludeGlobs),
      reviewConcurrency: Value(reviewConcurrency),
      autoPublishReview: Value(autoPublishReview),
      position: Value(position),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory WorkspacesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkspacesTableData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      logoPath: serializer.fromJson<String?>(json['logoPath']),
      ownerUserId: serializer.fromJson<String?>(json['ownerUserId']),
      secretExcludeGlobs: serializer.fromJson<String>(
        json['secretExcludeGlobs'],
      ),
      reviewConcurrency: serializer.fromJson<int>(json['reviewConcurrency']),
      autoPublishReview: serializer.fromJson<bool>(json['autoPublishReview']),
      position: serializer.fromJson<int>(json['position']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'logoPath': serializer.toJson<String?>(logoPath),
      'ownerUserId': serializer.toJson<String?>(ownerUserId),
      'secretExcludeGlobs': serializer.toJson<String>(secretExcludeGlobs),
      'reviewConcurrency': serializer.toJson<int>(reviewConcurrency),
      'autoPublishReview': serializer.toJson<bool>(autoPublishReview),
      'position': serializer.toJson<int>(position),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  WorkspacesTableData copyWith({
    String? id,
    String? name,
    Value<String?> logoPath = const Value.absent(),
    Value<String?> ownerUserId = const Value.absent(),
    String? secretExcludeGlobs,
    int? reviewConcurrency,
    bool? autoPublishReview,
    int? position,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => WorkspacesTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    logoPath: logoPath.present ? logoPath.value : this.logoPath,
    ownerUserId: ownerUserId.present ? ownerUserId.value : this.ownerUserId,
    secretExcludeGlobs: secretExcludeGlobs ?? this.secretExcludeGlobs,
    reviewConcurrency: reviewConcurrency ?? this.reviewConcurrency,
    autoPublishReview: autoPublishReview ?? this.autoPublishReview,
    position: position ?? this.position,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  WorkspacesTableData copyWithCompanion(WorkspacesTableCompanion data) {
    return WorkspacesTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      logoPath: data.logoPath.present ? data.logoPath.value : this.logoPath,
      ownerUserId: data.ownerUserId.present
          ? data.ownerUserId.value
          : this.ownerUserId,
      secretExcludeGlobs: data.secretExcludeGlobs.present
          ? data.secretExcludeGlobs.value
          : this.secretExcludeGlobs,
      reviewConcurrency: data.reviewConcurrency.present
          ? data.reviewConcurrency.value
          : this.reviewConcurrency,
      autoPublishReview: data.autoPublishReview.present
          ? data.autoPublishReview.value
          : this.autoPublishReview,
      position: data.position.present ? data.position.value : this.position,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkspacesTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('logoPath: $logoPath, ')
          ..write('ownerUserId: $ownerUserId, ')
          ..write('secretExcludeGlobs: $secretExcludeGlobs, ')
          ..write('reviewConcurrency: $reviewConcurrency, ')
          ..write('autoPublishReview: $autoPublishReview, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    logoPath,
    ownerUserId,
    secretExcludeGlobs,
    reviewConcurrency,
    autoPublishReview,
    position,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkspacesTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.logoPath == this.logoPath &&
          other.ownerUserId == this.ownerUserId &&
          other.secretExcludeGlobs == this.secretExcludeGlobs &&
          other.reviewConcurrency == this.reviewConcurrency &&
          other.autoPublishReview == this.autoPublishReview &&
          other.position == this.position &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class WorkspacesTableCompanion extends UpdateCompanion<WorkspacesTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> logoPath;
  final Value<String?> ownerUserId;
  final Value<String> secretExcludeGlobs;
  final Value<int> reviewConcurrency;
  final Value<bool> autoPublishReview;
  final Value<int> position;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const WorkspacesTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.logoPath = const Value.absent(),
    this.ownerUserId = const Value.absent(),
    this.secretExcludeGlobs = const Value.absent(),
    this.reviewConcurrency = const Value.absent(),
    this.autoPublishReview = const Value.absent(),
    this.position = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkspacesTableCompanion.insert({
    required String id,
    required String name,
    this.logoPath = const Value.absent(),
    this.ownerUserId = const Value.absent(),
    this.secretExcludeGlobs = const Value.absent(),
    this.reviewConcurrency = const Value.absent(),
    this.autoPublishReview = const Value.absent(),
    this.position = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<WorkspacesTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? logoPath,
    Expression<String>? ownerUserId,
    Expression<String>? secretExcludeGlobs,
    Expression<int>? reviewConcurrency,
    Expression<bool>? autoPublishReview,
    Expression<int>? position,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (logoPath != null) 'logo_path': logoPath,
      if (ownerUserId != null) 'owner_user_id': ownerUserId,
      if (secretExcludeGlobs != null)
        'secret_exclude_globs': secretExcludeGlobs,
      if (reviewConcurrency != null) 'review_concurrency': reviewConcurrency,
      if (autoPublishReview != null) 'auto_publish_review': autoPublishReview,
      if (position != null) 'position': position,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkspacesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? logoPath,
    Value<String?>? ownerUserId,
    Value<String>? secretExcludeGlobs,
    Value<int>? reviewConcurrency,
    Value<bool>? autoPublishReview,
    Value<int>? position,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return WorkspacesTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      logoPath: logoPath ?? this.logoPath,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      secretExcludeGlobs: secretExcludeGlobs ?? this.secretExcludeGlobs,
      reviewConcurrency: reviewConcurrency ?? this.reviewConcurrency,
      autoPublishReview: autoPublishReview ?? this.autoPublishReview,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
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
    if (logoPath.present) {
      map['logo_path'] = Variable<String>(logoPath.value);
    }
    if (ownerUserId.present) {
      map['owner_user_id'] = Variable<String>(ownerUserId.value);
    }
    if (secretExcludeGlobs.present) {
      map['secret_exclude_globs'] = Variable<String>(secretExcludeGlobs.value);
    }
    if (reviewConcurrency.present) {
      map['review_concurrency'] = Variable<int>(reviewConcurrency.value);
    }
    if (autoPublishReview.present) {
      map['auto_publish_review'] = Variable<bool>(autoPublishReview.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkspacesTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('logoPath: $logoPath, ')
          ..write('ownerUserId: $ownerUserId, ')
          ..write('secretExcludeGlobs: $secretExcludeGlobs, ')
          ..write('reviewConcurrency: $reviewConcurrency, ')
          ..write('autoPublishReview: $autoPublishReview, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UsersTableTable extends UsersTable
    with TableInfo<$UsersTableTable, UsersTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _handleMeta = const VerificationMeta('handle');
  @override
  late final GeneratedColumn<String> handle = GeneratedColumn<String>(
    'handle',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avatarRefMeta = const VerificationMeta(
    'avatarRef',
  );
  @override
  late final GeneratedColumn<String> avatarRef = GeneratedColumn<String>(
    'avatar_ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gitAuthorNameMeta = const VerificationMeta(
    'gitAuthorName',
  );
  @override
  late final GeneratedColumn<String> gitAuthorName = GeneratedColumn<String>(
    'git_author_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gitAuthorEmailMeta = const VerificationMeta(
    'gitAuthorEmail',
  );
  @override
  late final GeneratedColumn<String> gitAuthorEmail = GeneratedColumn<String>(
    'git_author_email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ssoSubjectMeta = const VerificationMeta(
    'ssoSubject',
  );
  @override
  late final GeneratedColumn<String> ssoSubject = GeneratedColumn<String>(
    'sso_subject',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ssoIssuerMeta = const VerificationMeta(
    'ssoIssuer',
  );
  @override
  late final GeneratedColumn<String> ssoIssuer = GeneratedColumn<String>(
    'sso_issuer',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deactivatedAtMeta = const VerificationMeta(
    'deactivatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deactivatedAt =
      GeneratedColumn<DateTime>(
        'deactivated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    handle,
    displayName,
    email,
    avatarRef,
    gitAuthorName,
    gitAuthorEmail,
    ssoSubject,
    ssoIssuer,
    deactivatedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<UsersTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('handle')) {
      context.handle(
        _handleMeta,
        handle.isAcceptableOrUnknown(data['handle']!, _handleMeta),
      );
    } else if (isInserting) {
      context.missing(_handleMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('avatar_ref')) {
      context.handle(
        _avatarRefMeta,
        avatarRef.isAcceptableOrUnknown(data['avatar_ref']!, _avatarRefMeta),
      );
    }
    if (data.containsKey('git_author_name')) {
      context.handle(
        _gitAuthorNameMeta,
        gitAuthorName.isAcceptableOrUnknown(
          data['git_author_name']!,
          _gitAuthorNameMeta,
        ),
      );
    }
    if (data.containsKey('git_author_email')) {
      context.handle(
        _gitAuthorEmailMeta,
        gitAuthorEmail.isAcceptableOrUnknown(
          data['git_author_email']!,
          _gitAuthorEmailMeta,
        ),
      );
    }
    if (data.containsKey('sso_subject')) {
      context.handle(
        _ssoSubjectMeta,
        ssoSubject.isAcceptableOrUnknown(data['sso_subject']!, _ssoSubjectMeta),
      );
    }
    if (data.containsKey('sso_issuer')) {
      context.handle(
        _ssoIssuerMeta,
        ssoIssuer.isAcceptableOrUnknown(data['sso_issuer']!, _ssoIssuerMeta),
      );
    }
    if (data.containsKey('deactivated_at')) {
      context.handle(
        _deactivatedAtMeta,
        deactivatedAt.isAcceptableOrUnknown(
          data['deactivated_at']!,
          _deactivatedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UsersTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UsersTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      handle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}handle'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      avatarRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_ref'],
      ),
      gitAuthorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}git_author_name'],
      ),
      gitAuthorEmail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}git_author_email'],
      ),
      ssoSubject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sso_subject'],
      ),
      ssoIssuer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sso_issuer'],
      ),
      deactivatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deactivated_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $UsersTableTable createAlias(String alias) {
    return $UsersTableTable(attachedDatabase, alias);
  }
}

class UsersTableData extends DataClass implements Insertable<UsersTableData> {
  /// Unique user identifier.
  final String id;

  /// Unique short handle (mention name).
  final String handle;

  /// Display name shown across the UI.
  final String displayName;

  /// Optional email address (invites work without one).
  final String? email;

  /// Optional avatar reference (server media ref or remote URL).
  final String? avatarRef;

  /// Git author name for commits made on this user's behalf.
  final String? gitAuthorName;

  /// Git author email for commits made on this user's behalf.
  final String? gitAuthorEmail;

  /// The SSO provider's immutable subject id (SAML NameID / SCIM externalId)
  /// when the user arrived via SSO/SCIM. Pinned with [ssoIssuer] so a later
  /// email change at the provider cannot silently take over the account.
  final String? ssoSubject;

  /// The issuer whose [ssoSubject] this is (IdP entity id or SCIM
  /// namespace).
  final String? ssoIssuer;

  /// When SCIM deprovisioning disabled the account (null = active). A
  /// deactivated user keeps their row (attribution is permanent) but cannot
  /// log in, holds no devices and belongs to no workspace.
  final DateTime? deactivatedAt;

  /// When the user was provisioned.
  final DateTime createdAt;
  const UsersTableData({
    required this.id,
    required this.handle,
    required this.displayName,
    this.email,
    this.avatarRef,
    this.gitAuthorName,
    this.gitAuthorEmail,
    this.ssoSubject,
    this.ssoIssuer,
    this.deactivatedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['handle'] = Variable<String>(handle);
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || avatarRef != null) {
      map['avatar_ref'] = Variable<String>(avatarRef);
    }
    if (!nullToAbsent || gitAuthorName != null) {
      map['git_author_name'] = Variable<String>(gitAuthorName);
    }
    if (!nullToAbsent || gitAuthorEmail != null) {
      map['git_author_email'] = Variable<String>(gitAuthorEmail);
    }
    if (!nullToAbsent || ssoSubject != null) {
      map['sso_subject'] = Variable<String>(ssoSubject);
    }
    if (!nullToAbsent || ssoIssuer != null) {
      map['sso_issuer'] = Variable<String>(ssoIssuer);
    }
    if (!nullToAbsent || deactivatedAt != null) {
      map['deactivated_at'] = Variable<DateTime>(deactivatedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  UsersTableCompanion toCompanion(bool nullToAbsent) {
    return UsersTableCompanion(
      id: Value(id),
      handle: Value(handle),
      displayName: Value(displayName),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      avatarRef: avatarRef == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarRef),
      gitAuthorName: gitAuthorName == null && nullToAbsent
          ? const Value.absent()
          : Value(gitAuthorName),
      gitAuthorEmail: gitAuthorEmail == null && nullToAbsent
          ? const Value.absent()
          : Value(gitAuthorEmail),
      ssoSubject: ssoSubject == null && nullToAbsent
          ? const Value.absent()
          : Value(ssoSubject),
      ssoIssuer: ssoIssuer == null && nullToAbsent
          ? const Value.absent()
          : Value(ssoIssuer),
      deactivatedAt: deactivatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deactivatedAt),
      createdAt: Value(createdAt),
    );
  }

  factory UsersTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UsersTableData(
      id: serializer.fromJson<String>(json['id']),
      handle: serializer.fromJson<String>(json['handle']),
      displayName: serializer.fromJson<String>(json['displayName']),
      email: serializer.fromJson<String?>(json['email']),
      avatarRef: serializer.fromJson<String?>(json['avatarRef']),
      gitAuthorName: serializer.fromJson<String?>(json['gitAuthorName']),
      gitAuthorEmail: serializer.fromJson<String?>(json['gitAuthorEmail']),
      ssoSubject: serializer.fromJson<String?>(json['ssoSubject']),
      ssoIssuer: serializer.fromJson<String?>(json['ssoIssuer']),
      deactivatedAt: serializer.fromJson<DateTime?>(json['deactivatedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'handle': serializer.toJson<String>(handle),
      'displayName': serializer.toJson<String>(displayName),
      'email': serializer.toJson<String?>(email),
      'avatarRef': serializer.toJson<String?>(avatarRef),
      'gitAuthorName': serializer.toJson<String?>(gitAuthorName),
      'gitAuthorEmail': serializer.toJson<String?>(gitAuthorEmail),
      'ssoSubject': serializer.toJson<String?>(ssoSubject),
      'ssoIssuer': serializer.toJson<String?>(ssoIssuer),
      'deactivatedAt': serializer.toJson<DateTime?>(deactivatedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  UsersTableData copyWith({
    String? id,
    String? handle,
    String? displayName,
    Value<String?> email = const Value.absent(),
    Value<String?> avatarRef = const Value.absent(),
    Value<String?> gitAuthorName = const Value.absent(),
    Value<String?> gitAuthorEmail = const Value.absent(),
    Value<String?> ssoSubject = const Value.absent(),
    Value<String?> ssoIssuer = const Value.absent(),
    Value<DateTime?> deactivatedAt = const Value.absent(),
    DateTime? createdAt,
  }) => UsersTableData(
    id: id ?? this.id,
    handle: handle ?? this.handle,
    displayName: displayName ?? this.displayName,
    email: email.present ? email.value : this.email,
    avatarRef: avatarRef.present ? avatarRef.value : this.avatarRef,
    gitAuthorName: gitAuthorName.present
        ? gitAuthorName.value
        : this.gitAuthorName,
    gitAuthorEmail: gitAuthorEmail.present
        ? gitAuthorEmail.value
        : this.gitAuthorEmail,
    ssoSubject: ssoSubject.present ? ssoSubject.value : this.ssoSubject,
    ssoIssuer: ssoIssuer.present ? ssoIssuer.value : this.ssoIssuer,
    deactivatedAt: deactivatedAt.present
        ? deactivatedAt.value
        : this.deactivatedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  UsersTableData copyWithCompanion(UsersTableCompanion data) {
    return UsersTableData(
      id: data.id.present ? data.id.value : this.id,
      handle: data.handle.present ? data.handle.value : this.handle,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      email: data.email.present ? data.email.value : this.email,
      avatarRef: data.avatarRef.present ? data.avatarRef.value : this.avatarRef,
      gitAuthorName: data.gitAuthorName.present
          ? data.gitAuthorName.value
          : this.gitAuthorName,
      gitAuthorEmail: data.gitAuthorEmail.present
          ? data.gitAuthorEmail.value
          : this.gitAuthorEmail,
      ssoSubject: data.ssoSubject.present
          ? data.ssoSubject.value
          : this.ssoSubject,
      ssoIssuer: data.ssoIssuer.present ? data.ssoIssuer.value : this.ssoIssuer,
      deactivatedAt: data.deactivatedAt.present
          ? data.deactivatedAt.value
          : this.deactivatedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UsersTableData(')
          ..write('id: $id, ')
          ..write('handle: $handle, ')
          ..write('displayName: $displayName, ')
          ..write('email: $email, ')
          ..write('avatarRef: $avatarRef, ')
          ..write('gitAuthorName: $gitAuthorName, ')
          ..write('gitAuthorEmail: $gitAuthorEmail, ')
          ..write('ssoSubject: $ssoSubject, ')
          ..write('ssoIssuer: $ssoIssuer, ')
          ..write('deactivatedAt: $deactivatedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    handle,
    displayName,
    email,
    avatarRef,
    gitAuthorName,
    gitAuthorEmail,
    ssoSubject,
    ssoIssuer,
    deactivatedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UsersTableData &&
          other.id == this.id &&
          other.handle == this.handle &&
          other.displayName == this.displayName &&
          other.email == this.email &&
          other.avatarRef == this.avatarRef &&
          other.gitAuthorName == this.gitAuthorName &&
          other.gitAuthorEmail == this.gitAuthorEmail &&
          other.ssoSubject == this.ssoSubject &&
          other.ssoIssuer == this.ssoIssuer &&
          other.deactivatedAt == this.deactivatedAt &&
          other.createdAt == this.createdAt);
}

class UsersTableCompanion extends UpdateCompanion<UsersTableData> {
  final Value<String> id;
  final Value<String> handle;
  final Value<String> displayName;
  final Value<String?> email;
  final Value<String?> avatarRef;
  final Value<String?> gitAuthorName;
  final Value<String?> gitAuthorEmail;
  final Value<String?> ssoSubject;
  final Value<String?> ssoIssuer;
  final Value<DateTime?> deactivatedAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const UsersTableCompanion({
    this.id = const Value.absent(),
    this.handle = const Value.absent(),
    this.displayName = const Value.absent(),
    this.email = const Value.absent(),
    this.avatarRef = const Value.absent(),
    this.gitAuthorName = const Value.absent(),
    this.gitAuthorEmail = const Value.absent(),
    this.ssoSubject = const Value.absent(),
    this.ssoIssuer = const Value.absent(),
    this.deactivatedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersTableCompanion.insert({
    required String id,
    required String handle,
    required String displayName,
    this.email = const Value.absent(),
    this.avatarRef = const Value.absent(),
    this.gitAuthorName = const Value.absent(),
    this.gitAuthorEmail = const Value.absent(),
    this.ssoSubject = const Value.absent(),
    this.ssoIssuer = const Value.absent(),
    this.deactivatedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       handle = Value(handle),
       displayName = Value(displayName);
  static Insertable<UsersTableData> custom({
    Expression<String>? id,
    Expression<String>? handle,
    Expression<String>? displayName,
    Expression<String>? email,
    Expression<String>? avatarRef,
    Expression<String>? gitAuthorName,
    Expression<String>? gitAuthorEmail,
    Expression<String>? ssoSubject,
    Expression<String>? ssoIssuer,
    Expression<DateTime>? deactivatedAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (handle != null) 'handle': handle,
      if (displayName != null) 'display_name': displayName,
      if (email != null) 'email': email,
      if (avatarRef != null) 'avatar_ref': avatarRef,
      if (gitAuthorName != null) 'git_author_name': gitAuthorName,
      if (gitAuthorEmail != null) 'git_author_email': gitAuthorEmail,
      if (ssoSubject != null) 'sso_subject': ssoSubject,
      if (ssoIssuer != null) 'sso_issuer': ssoIssuer,
      if (deactivatedAt != null) 'deactivated_at': deactivatedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersTableCompanion copyWith({
    Value<String>? id,
    Value<String>? handle,
    Value<String>? displayName,
    Value<String?>? email,
    Value<String?>? avatarRef,
    Value<String?>? gitAuthorName,
    Value<String?>? gitAuthorEmail,
    Value<String?>? ssoSubject,
    Value<String?>? ssoIssuer,
    Value<DateTime?>? deactivatedAt,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return UsersTableCompanion(
      id: id ?? this.id,
      handle: handle ?? this.handle,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarRef: avatarRef ?? this.avatarRef,
      gitAuthorName: gitAuthorName ?? this.gitAuthorName,
      gitAuthorEmail: gitAuthorEmail ?? this.gitAuthorEmail,
      ssoSubject: ssoSubject ?? this.ssoSubject,
      ssoIssuer: ssoIssuer ?? this.ssoIssuer,
      deactivatedAt: deactivatedAt ?? this.deactivatedAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (handle.present) {
      map['handle'] = Variable<String>(handle.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (avatarRef.present) {
      map['avatar_ref'] = Variable<String>(avatarRef.value);
    }
    if (gitAuthorName.present) {
      map['git_author_name'] = Variable<String>(gitAuthorName.value);
    }
    if (gitAuthorEmail.present) {
      map['git_author_email'] = Variable<String>(gitAuthorEmail.value);
    }
    if (ssoSubject.present) {
      map['sso_subject'] = Variable<String>(ssoSubject.value);
    }
    if (ssoIssuer.present) {
      map['sso_issuer'] = Variable<String>(ssoIssuer.value);
    }
    if (deactivatedAt.present) {
      map['deactivated_at'] = Variable<DateTime>(deactivatedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersTableCompanion(')
          ..write('id: $id, ')
          ..write('handle: $handle, ')
          ..write('displayName: $displayName, ')
          ..write('email: $email, ')
          ..write('avatarRef: $avatarRef, ')
          ..write('gitAuthorName: $gitAuthorName, ')
          ..write('gitAuthorEmail: $gitAuthorEmail, ')
          ..write('ssoSubject: $ssoSubject, ')
          ..write('ssoIssuer: $ssoIssuer, ')
          ..write('deactivatedAt: $deactivatedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserPreferencesTableTable extends UserPreferencesTable
    with TableInfo<$UserPreferencesTableTable, UserPreferencesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserPreferencesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE CASCADE',
    ),
  );
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [userId, key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserPreferencesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, key};
  @override
  UserPreferencesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserPreferencesTableData(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $UserPreferencesTableTable createAlias(String alias) {
    return $UserPreferencesTableTable(attachedDatabase, alias);
  }
}

class UserPreferencesTableData extends DataClass
    implements Insertable<UserPreferencesTableData> {
  /// The owning user.
  final String userId;

  /// Preference key (client-defined namespace, e.g. `theme_mode`).
  final String key;

  /// Opaque preference value.
  final String value;

  /// When the value was last written.
  final DateTime updatedAt;
  const UserPreferencesTableData({
    required this.userId,
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UserPreferencesTableCompanion toCompanion(bool nullToAbsent) {
    return UserPreferencesTableCompanion(
      userId: Value(userId),
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserPreferencesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserPreferencesTableData(
      userId: serializer.fromJson<String>(json['userId']),
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  UserPreferencesTableData copyWith({
    String? userId,
    String? key,
    String? value,
    DateTime? updatedAt,
  }) => UserPreferencesTableData(
    userId: userId ?? this.userId,
    key: key ?? this.key,
    value: value ?? this.value,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  UserPreferencesTableData copyWithCompanion(
    UserPreferencesTableCompanion data,
  ) {
    return UserPreferencesTableData(
      userId: data.userId.present ? data.userId.value : this.userId,
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserPreferencesTableData(')
          ..write('userId: $userId, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(userId, key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserPreferencesTableData &&
          other.userId == this.userId &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class UserPreferencesTableCompanion
    extends UpdateCompanion<UserPreferencesTableData> {
  final Value<String> userId;
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UserPreferencesTableCompanion({
    this.userId = const Value.absent(),
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserPreferencesTableCompanion.insert({
    required String userId,
    required String key,
    required String value,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       key = Value(key),
       value = Value(value);
  static Insertable<UserPreferencesTableData> custom({
    Expression<String>? userId,
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserPreferencesTableCompanion copyWith({
    Value<String>? userId,
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return UserPreferencesTableCompanion(
      userId: userId ?? this.userId,
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
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
    return (StringBuffer('UserPreferencesTableCompanion(')
          ..write('userId: $userId, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PairedDevicesTableTable extends PairedDevicesTable
    with TableInfo<$PairedDevicesTableTable, PairedDevicesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PairedDevicesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _platformMeta = const VerificationMeta(
    'platform',
  );
  @override
  late final GeneratedColumn<String> platform = GeneratedColumn<String>(
    'platform',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('web'),
  );
  static const VerificationMeta _pskRefMeta = const VerificationMeta('pskRef');
  @override
  late final GeneratedColumn<String> pskRef = GeneratedColumn<String>(
    'psk_ref',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteFingerprintMeta = const VerificationMeta(
    'remoteFingerprint',
  );
  @override
  late final GeneratedColumn<String> remoteFingerprint =
      GeneratedColumn<String>(
        'remote_fingerprint',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pendingConfirm'),
  );
  static const VerificationMeta _pairedAtMeta = const VerificationMeta(
    'pairedAt',
  );
  @override
  late final GeneratedColumn<DateTime> pairedAt = GeneratedColumn<DateTime>(
    'paired_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _lastSeenAtMeta = const VerificationMeta(
    'lastSeenAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSeenAt = GeneratedColumn<DateTime>(
    'last_seen_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    workspaceId,
    label,
    platform,
    pskRef,
    remoteFingerprint,
    status,
    pairedAt,
    lastSeenAt,
    expiresAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'paired_devices';
  @override
  VerificationContext validateIntegrity(
    Insertable<PairedDevicesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('platform')) {
      context.handle(
        _platformMeta,
        platform.isAcceptableOrUnknown(data['platform']!, _platformMeta),
      );
    }
    if (data.containsKey('psk_ref')) {
      context.handle(
        _pskRefMeta,
        pskRef.isAcceptableOrUnknown(data['psk_ref']!, _pskRefMeta),
      );
    } else if (isInserting) {
      context.missing(_pskRefMeta);
    }
    if (data.containsKey('remote_fingerprint')) {
      context.handle(
        _remoteFingerprintMeta,
        remoteFingerprint.isAcceptableOrUnknown(
          data['remote_fingerprint']!,
          _remoteFingerprintMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('paired_at')) {
      context.handle(
        _pairedAtMeta,
        pairedAt.isAcceptableOrUnknown(data['paired_at']!, _pairedAtMeta),
      );
    }
    if (data.containsKey('last_seen_at')) {
      context.handle(
        _lastSeenAtMeta,
        lastSeenAt.isAcceptableOrUnknown(
          data['last_seen_at']!,
          _lastSeenAtMeta,
        ),
      );
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PairedDevicesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PairedDevicesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      ),
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      platform: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}platform'],
      )!,
      pskRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}psk_ref'],
      )!,
      remoteFingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_fingerprint'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      pairedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}paired_at'],
      )!,
      lastSeenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_seen_at'],
      ),
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      ),
    );
  }

  @override
  $PairedDevicesTableTable createAlias(String alias) {
    return $PairedDevicesTableTable(attachedDatabase, alias);
  }
}

class PairedDevicesTableData extends DataClass
    implements Insertable<PairedDevicesTableData> {
  /// Unique device id (generated at pairing).
  final String id;

  /// The user this device authenticates as. Nullable in SQL only until the
  /// identity bootstrap backfills legacy rows to the owner; required in code.
  final String? userId;

  /// Workspace active at pairing time (seed for the session binding).
  final String? workspaceId;

  /// User-editable label (e.g. "iPhone").
  final String label;

  /// Platform string reported by the phone ("ios", "android", "web").
  final String platform;

  /// Secure-store key referencing this device's PSK
  /// (`paired_device_psk_<id>`).
  final String pskRef;

  /// Pinned remote DTLS fingerprint (TOFU on first connect).
  final String? remoteFingerprint;

  /// Pairing status: `pendingConfirm`, `active`, or `revoked`.
  final String status;

  /// When the device was paired.
  final DateTime pairedAt;

  /// When the device last connected.
  final DateTime? lastSeenAt;

  /// When this credential becomes invalid and the desktop must fail it closed.
  ///
  /// Two-phase: for a `pendingConfirm` device it is the short pairing-offer
  /// window (the QR's ~5 min) — if the user never confirms in time, the offer is
  /// purged. Once confirmed (`active`) it is reset to an absolute credential
  /// lifetime, after which the phone must re-pair. The desktop checks this in
  /// both connect gates so a leaked link is time-boxed rather than a permanent
  /// backdoor. Null means "no expiry" (legacy rows upgraded before this column).
  final DateTime? expiresAt;
  const PairedDevicesTableData({
    required this.id,
    this.userId,
    this.workspaceId,
    required this.label,
    required this.platform,
    required this.pskRef,
    this.remoteFingerprint,
    required this.status,
    required this.pairedAt,
    this.lastSeenAt,
    this.expiresAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || workspaceId != null) {
      map['workspace_id'] = Variable<String>(workspaceId);
    }
    map['label'] = Variable<String>(label);
    map['platform'] = Variable<String>(platform);
    map['psk_ref'] = Variable<String>(pskRef);
    if (!nullToAbsent || remoteFingerprint != null) {
      map['remote_fingerprint'] = Variable<String>(remoteFingerprint);
    }
    map['status'] = Variable<String>(status);
    map['paired_at'] = Variable<DateTime>(pairedAt);
    if (!nullToAbsent || lastSeenAt != null) {
      map['last_seen_at'] = Variable<DateTime>(lastSeenAt);
    }
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<DateTime>(expiresAt);
    }
    return map;
  }

  PairedDevicesTableCompanion toCompanion(bool nullToAbsent) {
    return PairedDevicesTableCompanion(
      id: Value(id),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      workspaceId: workspaceId == null && nullToAbsent
          ? const Value.absent()
          : Value(workspaceId),
      label: Value(label),
      platform: Value(platform),
      pskRef: Value(pskRef),
      remoteFingerprint: remoteFingerprint == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteFingerprint),
      status: Value(status),
      pairedAt: Value(pairedAt),
      lastSeenAt: lastSeenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSeenAt),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
    );
  }

  factory PairedDevicesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PairedDevicesTableData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String?>(json['userId']),
      workspaceId: serializer.fromJson<String?>(json['workspaceId']),
      label: serializer.fromJson<String>(json['label']),
      platform: serializer.fromJson<String>(json['platform']),
      pskRef: serializer.fromJson<String>(json['pskRef']),
      remoteFingerprint: serializer.fromJson<String?>(
        json['remoteFingerprint'],
      ),
      status: serializer.fromJson<String>(json['status']),
      pairedAt: serializer.fromJson<DateTime>(json['pairedAt']),
      lastSeenAt: serializer.fromJson<DateTime?>(json['lastSeenAt']),
      expiresAt: serializer.fromJson<DateTime?>(json['expiresAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String?>(userId),
      'workspaceId': serializer.toJson<String?>(workspaceId),
      'label': serializer.toJson<String>(label),
      'platform': serializer.toJson<String>(platform),
      'pskRef': serializer.toJson<String>(pskRef),
      'remoteFingerprint': serializer.toJson<String?>(remoteFingerprint),
      'status': serializer.toJson<String>(status),
      'pairedAt': serializer.toJson<DateTime>(pairedAt),
      'lastSeenAt': serializer.toJson<DateTime?>(lastSeenAt),
      'expiresAt': serializer.toJson<DateTime?>(expiresAt),
    };
  }

  PairedDevicesTableData copyWith({
    String? id,
    Value<String?> userId = const Value.absent(),
    Value<String?> workspaceId = const Value.absent(),
    String? label,
    String? platform,
    String? pskRef,
    Value<String?> remoteFingerprint = const Value.absent(),
    String? status,
    DateTime? pairedAt,
    Value<DateTime?> lastSeenAt = const Value.absent(),
    Value<DateTime?> expiresAt = const Value.absent(),
  }) => PairedDevicesTableData(
    id: id ?? this.id,
    userId: userId.present ? userId.value : this.userId,
    workspaceId: workspaceId.present ? workspaceId.value : this.workspaceId,
    label: label ?? this.label,
    platform: platform ?? this.platform,
    pskRef: pskRef ?? this.pskRef,
    remoteFingerprint: remoteFingerprint.present
        ? remoteFingerprint.value
        : this.remoteFingerprint,
    status: status ?? this.status,
    pairedAt: pairedAt ?? this.pairedAt,
    lastSeenAt: lastSeenAt.present ? lastSeenAt.value : this.lastSeenAt,
    expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
  );
  PairedDevicesTableData copyWithCompanion(PairedDevicesTableCompanion data) {
    return PairedDevicesTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      label: data.label.present ? data.label.value : this.label,
      platform: data.platform.present ? data.platform.value : this.platform,
      pskRef: data.pskRef.present ? data.pskRef.value : this.pskRef,
      remoteFingerprint: data.remoteFingerprint.present
          ? data.remoteFingerprint.value
          : this.remoteFingerprint,
      status: data.status.present ? data.status.value : this.status,
      pairedAt: data.pairedAt.present ? data.pairedAt.value : this.pairedAt,
      lastSeenAt: data.lastSeenAt.present
          ? data.lastSeenAt.value
          : this.lastSeenAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PairedDevicesTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('label: $label, ')
          ..write('platform: $platform, ')
          ..write('pskRef: $pskRef, ')
          ..write('remoteFingerprint: $remoteFingerprint, ')
          ..write('status: $status, ')
          ..write('pairedAt: $pairedAt, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    workspaceId,
    label,
    platform,
    pskRef,
    remoteFingerprint,
    status,
    pairedAt,
    lastSeenAt,
    expiresAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PairedDevicesTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.workspaceId == this.workspaceId &&
          other.label == this.label &&
          other.platform == this.platform &&
          other.pskRef == this.pskRef &&
          other.remoteFingerprint == this.remoteFingerprint &&
          other.status == this.status &&
          other.pairedAt == this.pairedAt &&
          other.lastSeenAt == this.lastSeenAt &&
          other.expiresAt == this.expiresAt);
}

class PairedDevicesTableCompanion
    extends UpdateCompanion<PairedDevicesTableData> {
  final Value<String> id;
  final Value<String?> userId;
  final Value<String?> workspaceId;
  final Value<String> label;
  final Value<String> platform;
  final Value<String> pskRef;
  final Value<String?> remoteFingerprint;
  final Value<String> status;
  final Value<DateTime> pairedAt;
  final Value<DateTime?> lastSeenAt;
  final Value<DateTime?> expiresAt;
  final Value<int> rowid;
  const PairedDevicesTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.label = const Value.absent(),
    this.platform = const Value.absent(),
    this.pskRef = const Value.absent(),
    this.remoteFingerprint = const Value.absent(),
    this.status = const Value.absent(),
    this.pairedAt = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PairedDevicesTableCompanion.insert({
    required String id,
    this.userId = const Value.absent(),
    this.workspaceId = const Value.absent(),
    required String label,
    this.platform = const Value.absent(),
    required String pskRef,
    this.remoteFingerprint = const Value.absent(),
    this.status = const Value.absent(),
    this.pairedAt = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       label = Value(label),
       pskRef = Value(pskRef);
  static Insertable<PairedDevicesTableData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? workspaceId,
    Expression<String>? label,
    Expression<String>? platform,
    Expression<String>? pskRef,
    Expression<String>? remoteFingerprint,
    Expression<String>? status,
    Expression<DateTime>? pairedAt,
    Expression<DateTime>? lastSeenAt,
    Expression<DateTime>? expiresAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (label != null) 'label': label,
      if (platform != null) 'platform': platform,
      if (pskRef != null) 'psk_ref': pskRef,
      if (remoteFingerprint != null) 'remote_fingerprint': remoteFingerprint,
      if (status != null) 'status': status,
      if (pairedAt != null) 'paired_at': pairedAt,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PairedDevicesTableCompanion copyWith({
    Value<String>? id,
    Value<String?>? userId,
    Value<String?>? workspaceId,
    Value<String>? label,
    Value<String>? platform,
    Value<String>? pskRef,
    Value<String?>? remoteFingerprint,
    Value<String>? status,
    Value<DateTime>? pairedAt,
    Value<DateTime?>? lastSeenAt,
    Value<DateTime?>? expiresAt,
    Value<int>? rowid,
  }) {
    return PairedDevicesTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      workspaceId: workspaceId ?? this.workspaceId,
      label: label ?? this.label,
      platform: platform ?? this.platform,
      pskRef: pskRef ?? this.pskRef,
      remoteFingerprint: remoteFingerprint ?? this.remoteFingerprint,
      status: status ?? this.status,
      pairedAt: pairedAt ?? this.pairedAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      expiresAt: expiresAt ?? this.expiresAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (platform.present) {
      map['platform'] = Variable<String>(platform.value);
    }
    if (pskRef.present) {
      map['psk_ref'] = Variable<String>(pskRef.value);
    }
    if (remoteFingerprint.present) {
      map['remote_fingerprint'] = Variable<String>(remoteFingerprint.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (pairedAt.present) {
      map['paired_at'] = Variable<DateTime>(pairedAt.value);
    }
    if (lastSeenAt.present) {
      map['last_seen_at'] = Variable<DateTime>(lastSeenAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PairedDevicesTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('label: $label, ')
          ..write('platform: $platform, ')
          ..write('pskRef: $pskRef, ')
          ..write('remoteFingerprint: $remoteFingerprint, ')
          ..write('status: $status, ')
          ..write('pairedAt: $pairedAt, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RssFeedsTableTable extends RssFeedsTable
    with TableInfo<$RssFeedsTableTable, RssFeedsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RssFeedsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE CASCADE',
    ),
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
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _iconUrlMeta = const VerificationMeta(
    'iconUrl',
  );
  @override
  late final GeneratedColumn<String> iconUrl = GeneratedColumn<String>(
    'icon_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _userAgentMeta = const VerificationMeta(
    'userAgent',
  );
  @override
  late final GeneratedColumn<String> userAgent = GeneratedColumn<String>(
    'user_agent',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _lastFetchedAtMeta = const VerificationMeta(
    'lastFetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastFetchedAt =
      GeneratedColumn<DateTime>(
        'last_fetched_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    name,
    url,
    description,
    iconUrl,
    userAgent,
    enabled,
    lastFetchedAt,
    lastError,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rss_feeds';
  @override
  VerificationContext validateIntegrity(
    Insertable<RssFeedsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('icon_url')) {
      context.handle(
        _iconUrlMeta,
        iconUrl.isAcceptableOrUnknown(data['icon_url']!, _iconUrlMeta),
      );
    }
    if (data.containsKey('user_agent')) {
      context.handle(
        _userAgentMeta,
        userAgent.isAcceptableOrUnknown(data['user_agent']!, _userAgentMeta),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('last_fetched_at')) {
      context.handle(
        _lastFetchedAtMeta,
        lastFetchedAt.isAcceptableOrUnknown(
          data['last_fetched_at']!,
          _lastFetchedAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RssFeedsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RssFeedsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      iconUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_url'],
      )!,
      userAgent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_agent'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      lastFetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_fetched_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
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
  $RssFeedsTableTable createAlias(String alias) {
    return $RssFeedsTableTable(attachedDatabase, alias);
  }
}

class RssFeedsTableData extends DataClass
    implements Insertable<RssFeedsTableData> {
  /// Unique feed identifier (uuid v4).
  final String id;

  /// Owning user — the feed list is per-user, never shared.
  final String userId;

  /// Display name (e.g. "The Verge").
  final String name;

  /// Feed URL.
  final String url;

  /// Optional description shown in feed-management UI.
  final String description;

  /// Optional icon URL parsed from the feed (or favicon fallback).
  final String iconUrl;

  /// Optional custom User-Agent for this feed (empty = use default).
  final String userAgent;

  /// Whether this feed is active (off = not fetched, not shown).
  final bool enabled;

  /// Last successful fetch timestamp. Null if never fetched.
  final DateTime? lastFetchedAt;

  /// Last error message if the last fetch failed.
  final String? lastError;

  /// Created at.
  final DateTime createdAt;

  /// Updated at.
  final DateTime updatedAt;
  const RssFeedsTableData({
    required this.id,
    required this.userId,
    required this.name,
    required this.url,
    required this.description,
    required this.iconUrl,
    required this.userAgent,
    required this.enabled,
    this.lastFetchedAt,
    this.lastError,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['name'] = Variable<String>(name);
    map['url'] = Variable<String>(url);
    map['description'] = Variable<String>(description);
    map['icon_url'] = Variable<String>(iconUrl);
    map['user_agent'] = Variable<String>(userAgent);
    map['enabled'] = Variable<bool>(enabled);
    if (!nullToAbsent || lastFetchedAt != null) {
      map['last_fetched_at'] = Variable<DateTime>(lastFetchedAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  RssFeedsTableCompanion toCompanion(bool nullToAbsent) {
    return RssFeedsTableCompanion(
      id: Value(id),
      userId: Value(userId),
      name: Value(name),
      url: Value(url),
      description: Value(description),
      iconUrl: Value(iconUrl),
      userAgent: Value(userAgent),
      enabled: Value(enabled),
      lastFetchedAt: lastFetchedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastFetchedAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory RssFeedsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RssFeedsTableData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      url: serializer.fromJson<String>(json['url']),
      description: serializer.fromJson<String>(json['description']),
      iconUrl: serializer.fromJson<String>(json['iconUrl']),
      userAgent: serializer.fromJson<String>(json['userAgent']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      lastFetchedAt: serializer.fromJson<DateTime?>(json['lastFetchedAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String>(name),
      'url': serializer.toJson<String>(url),
      'description': serializer.toJson<String>(description),
      'iconUrl': serializer.toJson<String>(iconUrl),
      'userAgent': serializer.toJson<String>(userAgent),
      'enabled': serializer.toJson<bool>(enabled),
      'lastFetchedAt': serializer.toJson<DateTime?>(lastFetchedAt),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  RssFeedsTableData copyWith({
    String? id,
    String? userId,
    String? name,
    String? url,
    String? description,
    String? iconUrl,
    String? userAgent,
    bool? enabled,
    Value<DateTime?> lastFetchedAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => RssFeedsTableData(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    url: url ?? this.url,
    description: description ?? this.description,
    iconUrl: iconUrl ?? this.iconUrl,
    userAgent: userAgent ?? this.userAgent,
    enabled: enabled ?? this.enabled,
    lastFetchedAt: lastFetchedAt.present
        ? lastFetchedAt.value
        : this.lastFetchedAt,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  RssFeedsTableData copyWithCompanion(RssFeedsTableCompanion data) {
    return RssFeedsTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      url: data.url.present ? data.url.value : this.url,
      description: data.description.present
          ? data.description.value
          : this.description,
      iconUrl: data.iconUrl.present ? data.iconUrl.value : this.iconUrl,
      userAgent: data.userAgent.present ? data.userAgent.value : this.userAgent,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      lastFetchedAt: data.lastFetchedAt.present
          ? data.lastFetchedAt.value
          : this.lastFetchedAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RssFeedsTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('url: $url, ')
          ..write('description: $description, ')
          ..write('iconUrl: $iconUrl, ')
          ..write('userAgent: $userAgent, ')
          ..write('enabled: $enabled, ')
          ..write('lastFetchedAt: $lastFetchedAt, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    name,
    url,
    description,
    iconUrl,
    userAgent,
    enabled,
    lastFetchedAt,
    lastError,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RssFeedsTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.url == this.url &&
          other.description == this.description &&
          other.iconUrl == this.iconUrl &&
          other.userAgent == this.userAgent &&
          other.enabled == this.enabled &&
          other.lastFetchedAt == this.lastFetchedAt &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class RssFeedsTableCompanion extends UpdateCompanion<RssFeedsTableData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> name;
  final Value<String> url;
  final Value<String> description;
  final Value<String> iconUrl;
  final Value<String> userAgent;
  final Value<bool> enabled;
  final Value<DateTime?> lastFetchedAt;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const RssFeedsTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.url = const Value.absent(),
    this.description = const Value.absent(),
    this.iconUrl = const Value.absent(),
    this.userAgent = const Value.absent(),
    this.enabled = const Value.absent(),
    this.lastFetchedAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RssFeedsTableCompanion.insert({
    required String id,
    required String userId,
    required String name,
    required String url,
    this.description = const Value.absent(),
    this.iconUrl = const Value.absent(),
    this.userAgent = const Value.absent(),
    this.enabled = const Value.absent(),
    this.lastFetchedAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       name = Value(name),
       url = Value(url);
  static Insertable<RssFeedsTableData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<String>? url,
    Expression<String>? description,
    Expression<String>? iconUrl,
    Expression<String>? userAgent,
    Expression<bool>? enabled,
    Expression<DateTime>? lastFetchedAt,
    Expression<String>? lastError,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (url != null) 'url': url,
      if (description != null) 'description': description,
      if (iconUrl != null) 'icon_url': iconUrl,
      if (userAgent != null) 'user_agent': userAgent,
      if (enabled != null) 'enabled': enabled,
      if (lastFetchedAt != null) 'last_fetched_at': lastFetchedAt,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RssFeedsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? name,
    Value<String>? url,
    Value<String>? description,
    Value<String>? iconUrl,
    Value<String>? userAgent,
    Value<bool>? enabled,
    Value<DateTime?>? lastFetchedAt,
    Value<String?>? lastError,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return RssFeedsTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      url: url ?? this.url,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      userAgent: userAgent ?? this.userAgent,
      enabled: enabled ?? this.enabled,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
      lastError: lastError ?? this.lastError,
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
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (iconUrl.present) {
      map['icon_url'] = Variable<String>(iconUrl.value);
    }
    if (userAgent.present) {
      map['user_agent'] = Variable<String>(userAgent.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (lastFetchedAt.present) {
      map['last_fetched_at'] = Variable<DateTime>(lastFetchedAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
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
    return (StringBuffer('RssFeedsTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('url: $url, ')
          ..write('description: $description, ')
          ..write('iconUrl: $iconUrl, ')
          ..write('userAgent: $userAgent, ')
          ..write('enabled: $enabled, ')
          ..write('lastFetchedAt: $lastFetchedAt, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RssArticlesTableTable extends RssArticlesTable
    with TableInfo<$RssArticlesTableTable, RssArticlesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RssArticlesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _feedIdMeta = const VerificationMeta('feedId');
  @override
  late final GeneratedColumn<String> feedId = GeneratedColumn<String>(
    'feed_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES rss_feeds (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _guidMeta = const VerificationMeta('guid');
  @override
  late final GeneratedColumn<String> guid = GeneratedColumn<String>(
    'guid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _linkMeta = const VerificationMeta('link');
  @override
  late final GeneratedColumn<String> link = GeneratedColumn<String>(
    'link',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _publishedAtMeta = const VerificationMeta(
    'publishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> publishedAt = GeneratedColumn<DateTime>(
    'published_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _savedMeta = const VerificationMeta('saved');
  @override
  late final GeneratedColumn<bool> saved = GeneratedColumn<bool>(
    'saved',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("saved" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _readMeta = const VerificationMeta('read');
  @override
  late final GeneratedColumn<bool> read = GeneratedColumn<bool>(
    'read',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("read" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    feedId,
    guid,
    title,
    link,
    summary,
    imageUrl,
    author,
    publishedAt,
    saved,
    read,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rss_articles';
  @override
  VerificationContext validateIntegrity(
    Insertable<RssArticlesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('feed_id')) {
      context.handle(
        _feedIdMeta,
        feedId.isAcceptableOrUnknown(data['feed_id']!, _feedIdMeta),
      );
    } else if (isInserting) {
      context.missing(_feedIdMeta);
    }
    if (data.containsKey('guid')) {
      context.handle(
        _guidMeta,
        guid.isAcceptableOrUnknown(data['guid']!, _guidMeta),
      );
    } else if (isInserting) {
      context.missing(_guidMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('link')) {
      context.handle(
        _linkMeta,
        link.isAcceptableOrUnknown(data['link']!, _linkMeta),
      );
    } else if (isInserting) {
      context.missing(_linkMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    }
    if (data.containsKey('published_at')) {
      context.handle(
        _publishedAtMeta,
        publishedAt.isAcceptableOrUnknown(
          data['published_at']!,
          _publishedAtMeta,
        ),
      );
    }
    if (data.containsKey('saved')) {
      context.handle(
        _savedMeta,
        saved.isAcceptableOrUnknown(data['saved']!, _savedMeta),
      );
    }
    if (data.containsKey('read')) {
      context.handle(
        _readMeta,
        read.isAcceptableOrUnknown(data['read']!, _readMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RssArticlesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RssArticlesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      feedId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}feed_id'],
      )!,
      guid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}guid'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      link: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}link'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      )!,
      publishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}published_at'],
      ),
      saved: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}saved'],
      )!,
      read: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}read'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $RssArticlesTableTable createAlias(String alias) {
    return $RssArticlesTableTable(attachedDatabase, alias);
  }
}

class RssArticlesTableData extends DataClass
    implements Insertable<RssArticlesTableData> {
  /// Article id.
  final String id;

  /// Feed id.
  final String feedId;

  /// Feed-provided GUID (or link as fallback).
  final String guid;

  /// Article title.
  final String title;

  /// Link.
  final String link;

  /// Excerpt / description as raw HTML (we strip on render).
  final String summary;

  /// First image URL extracted from media:thumbnail / enclosure / content.
  final String imageUrl;

  /// Article author.
  final String author;

  /// When the article was originally published.
  final DateTime? publishedAt;

  /// Whether the user has bookmarked this article.
  final bool saved;

  /// Whether the user has opened (read) this article.
  final bool read;

  /// When the article was ingested into the local database.
  final DateTime createdAt;
  const RssArticlesTableData({
    required this.id,
    required this.feedId,
    required this.guid,
    required this.title,
    required this.link,
    required this.summary,
    required this.imageUrl,
    required this.author,
    this.publishedAt,
    required this.saved,
    required this.read,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['feed_id'] = Variable<String>(feedId);
    map['guid'] = Variable<String>(guid);
    map['title'] = Variable<String>(title);
    map['link'] = Variable<String>(link);
    map['summary'] = Variable<String>(summary);
    map['image_url'] = Variable<String>(imageUrl);
    map['author'] = Variable<String>(author);
    if (!nullToAbsent || publishedAt != null) {
      map['published_at'] = Variable<DateTime>(publishedAt);
    }
    map['saved'] = Variable<bool>(saved);
    map['read'] = Variable<bool>(read);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  RssArticlesTableCompanion toCompanion(bool nullToAbsent) {
    return RssArticlesTableCompanion(
      id: Value(id),
      feedId: Value(feedId),
      guid: Value(guid),
      title: Value(title),
      link: Value(link),
      summary: Value(summary),
      imageUrl: Value(imageUrl),
      author: Value(author),
      publishedAt: publishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(publishedAt),
      saved: Value(saved),
      read: Value(read),
      createdAt: Value(createdAt),
    );
  }

  factory RssArticlesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RssArticlesTableData(
      id: serializer.fromJson<String>(json['id']),
      feedId: serializer.fromJson<String>(json['feedId']),
      guid: serializer.fromJson<String>(json['guid']),
      title: serializer.fromJson<String>(json['title']),
      link: serializer.fromJson<String>(json['link']),
      summary: serializer.fromJson<String>(json['summary']),
      imageUrl: serializer.fromJson<String>(json['imageUrl']),
      author: serializer.fromJson<String>(json['author']),
      publishedAt: serializer.fromJson<DateTime?>(json['publishedAt']),
      saved: serializer.fromJson<bool>(json['saved']),
      read: serializer.fromJson<bool>(json['read']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'feedId': serializer.toJson<String>(feedId),
      'guid': serializer.toJson<String>(guid),
      'title': serializer.toJson<String>(title),
      'link': serializer.toJson<String>(link),
      'summary': serializer.toJson<String>(summary),
      'imageUrl': serializer.toJson<String>(imageUrl),
      'author': serializer.toJson<String>(author),
      'publishedAt': serializer.toJson<DateTime?>(publishedAt),
      'saved': serializer.toJson<bool>(saved),
      'read': serializer.toJson<bool>(read),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  RssArticlesTableData copyWith({
    String? id,
    String? feedId,
    String? guid,
    String? title,
    String? link,
    String? summary,
    String? imageUrl,
    String? author,
    Value<DateTime?> publishedAt = const Value.absent(),
    bool? saved,
    bool? read,
    DateTime? createdAt,
  }) => RssArticlesTableData(
    id: id ?? this.id,
    feedId: feedId ?? this.feedId,
    guid: guid ?? this.guid,
    title: title ?? this.title,
    link: link ?? this.link,
    summary: summary ?? this.summary,
    imageUrl: imageUrl ?? this.imageUrl,
    author: author ?? this.author,
    publishedAt: publishedAt.present ? publishedAt.value : this.publishedAt,
    saved: saved ?? this.saved,
    read: read ?? this.read,
    createdAt: createdAt ?? this.createdAt,
  );
  RssArticlesTableData copyWithCompanion(RssArticlesTableCompanion data) {
    return RssArticlesTableData(
      id: data.id.present ? data.id.value : this.id,
      feedId: data.feedId.present ? data.feedId.value : this.feedId,
      guid: data.guid.present ? data.guid.value : this.guid,
      title: data.title.present ? data.title.value : this.title,
      link: data.link.present ? data.link.value : this.link,
      summary: data.summary.present ? data.summary.value : this.summary,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      author: data.author.present ? data.author.value : this.author,
      publishedAt: data.publishedAt.present
          ? data.publishedAt.value
          : this.publishedAt,
      saved: data.saved.present ? data.saved.value : this.saved,
      read: data.read.present ? data.read.value : this.read,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RssArticlesTableData(')
          ..write('id: $id, ')
          ..write('feedId: $feedId, ')
          ..write('guid: $guid, ')
          ..write('title: $title, ')
          ..write('link: $link, ')
          ..write('summary: $summary, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('author: $author, ')
          ..write('publishedAt: $publishedAt, ')
          ..write('saved: $saved, ')
          ..write('read: $read, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    feedId,
    guid,
    title,
    link,
    summary,
    imageUrl,
    author,
    publishedAt,
    saved,
    read,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RssArticlesTableData &&
          other.id == this.id &&
          other.feedId == this.feedId &&
          other.guid == this.guid &&
          other.title == this.title &&
          other.link == this.link &&
          other.summary == this.summary &&
          other.imageUrl == this.imageUrl &&
          other.author == this.author &&
          other.publishedAt == this.publishedAt &&
          other.saved == this.saved &&
          other.read == this.read &&
          other.createdAt == this.createdAt);
}

class RssArticlesTableCompanion extends UpdateCompanion<RssArticlesTableData> {
  final Value<String> id;
  final Value<String> feedId;
  final Value<String> guid;
  final Value<String> title;
  final Value<String> link;
  final Value<String> summary;
  final Value<String> imageUrl;
  final Value<String> author;
  final Value<DateTime?> publishedAt;
  final Value<bool> saved;
  final Value<bool> read;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const RssArticlesTableCompanion({
    this.id = const Value.absent(),
    this.feedId = const Value.absent(),
    this.guid = const Value.absent(),
    this.title = const Value.absent(),
    this.link = const Value.absent(),
    this.summary = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.author = const Value.absent(),
    this.publishedAt = const Value.absent(),
    this.saved = const Value.absent(),
    this.read = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RssArticlesTableCompanion.insert({
    required String id,
    required String feedId,
    required String guid,
    required String title,
    required String link,
    this.summary = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.author = const Value.absent(),
    this.publishedAt = const Value.absent(),
    this.saved = const Value.absent(),
    this.read = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       feedId = Value(feedId),
       guid = Value(guid),
       title = Value(title),
       link = Value(link);
  static Insertable<RssArticlesTableData> custom({
    Expression<String>? id,
    Expression<String>? feedId,
    Expression<String>? guid,
    Expression<String>? title,
    Expression<String>? link,
    Expression<String>? summary,
    Expression<String>? imageUrl,
    Expression<String>? author,
    Expression<DateTime>? publishedAt,
    Expression<bool>? saved,
    Expression<bool>? read,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (feedId != null) 'feed_id': feedId,
      if (guid != null) 'guid': guid,
      if (title != null) 'title': title,
      if (link != null) 'link': link,
      if (summary != null) 'summary': summary,
      if (imageUrl != null) 'image_url': imageUrl,
      if (author != null) 'author': author,
      if (publishedAt != null) 'published_at': publishedAt,
      if (saved != null) 'saved': saved,
      if (read != null) 'read': read,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RssArticlesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? feedId,
    Value<String>? guid,
    Value<String>? title,
    Value<String>? link,
    Value<String>? summary,
    Value<String>? imageUrl,
    Value<String>? author,
    Value<DateTime?>? publishedAt,
    Value<bool>? saved,
    Value<bool>? read,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return RssArticlesTableCompanion(
      id: id ?? this.id,
      feedId: feedId ?? this.feedId,
      guid: guid ?? this.guid,
      title: title ?? this.title,
      link: link ?? this.link,
      summary: summary ?? this.summary,
      imageUrl: imageUrl ?? this.imageUrl,
      author: author ?? this.author,
      publishedAt: publishedAt ?? this.publishedAt,
      saved: saved ?? this.saved,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (feedId.present) {
      map['feed_id'] = Variable<String>(feedId.value);
    }
    if (guid.present) {
      map['guid'] = Variable<String>(guid.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (link.present) {
      map['link'] = Variable<String>(link.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (publishedAt.present) {
      map['published_at'] = Variable<DateTime>(publishedAt.value);
    }
    if (saved.present) {
      map['saved'] = Variable<bool>(saved.value);
    }
    if (read.present) {
      map['read'] = Variable<bool>(read.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RssArticlesTableCompanion(')
          ..write('id: $id, ')
          ..write('feedId: $feedId, ')
          ..write('guid: $guid, ')
          ..write('title: $title, ')
          ..write('link: $link, ')
          ..write('summary: $summary, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('author: $author, ')
          ..write('publishedAt: $publishedAt, ')
          ..write('saved: $saved, ')
          ..write('read: $read, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkersTableTable extends WorkersTable
    with TableInfo<$WorkersTableTable, WorkersTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkersTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _capsJsonMeta = const VerificationMeta(
    'capsJson',
  );
  @override
  late final GeneratedColumn<String> capsJson = GeneratedColumn<String>(
    'caps_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _platformMeta = const VerificationMeta(
    'platform',
  );
  @override
  late final GeneratedColumn<String> platform = GeneratedColumn<String>(
    'platform',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('unknown'),
  );
  static const VerificationMeta _credentialRefMeta = const VerificationMeta(
    'credentialRef',
  );
  @override
  late final GeneratedColumn<String> credentialRef = GeneratedColumn<String>(
    'credential_ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pairedDeviceIdMeta = const VerificationMeta(
    'pairedDeviceId',
  );
  @override
  late final GeneratedColumn<String> pairedDeviceId = GeneratedColumn<String>(
    'paired_device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _protocolVersionMeta = const VerificationMeta(
    'protocolVersion',
  );
  @override
  late final GeneratedColumn<int> protocolVersion = GeneratedColumn<int>(
    'protocol_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('offline'),
  );
  static const VerificationMeta _lastHeartbeatAtMeta = const VerificationMeta(
    'lastHeartbeatAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastHeartbeatAt =
      GeneratedColumn<DateTime>(
        'last_heartbeat_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _registeredByMeta = const VerificationMeta(
    'registeredBy',
  );
  @override
  late final GeneratedColumn<String> registeredBy = GeneratedColumn<String>(
    'registered_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _drainedAtMeta = const VerificationMeta(
    'drainedAt',
  );
  @override
  late final GeneratedColumn<DateTime> drainedAt = GeneratedColumn<DateTime>(
    'drained_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _revokedAtMeta = const VerificationMeta(
    'revokedAt',
  );
  @override
  late final GeneratedColumn<DateTime> revokedAt = GeneratedColumn<DateTime>(
    'revoked_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    capsJson,
    platform,
    credentialRef,
    pairedDeviceId,
    protocolVersion,
    status,
    lastHeartbeatAt,
    registeredBy,
    drainedAt,
    revokedAt,
    lastError,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workers';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkersTableData> instance, {
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
    if (data.containsKey('caps_json')) {
      context.handle(
        _capsJsonMeta,
        capsJson.isAcceptableOrUnknown(data['caps_json']!, _capsJsonMeta),
      );
    }
    if (data.containsKey('platform')) {
      context.handle(
        _platformMeta,
        platform.isAcceptableOrUnknown(data['platform']!, _platformMeta),
      );
    }
    if (data.containsKey('credential_ref')) {
      context.handle(
        _credentialRefMeta,
        credentialRef.isAcceptableOrUnknown(
          data['credential_ref']!,
          _credentialRefMeta,
        ),
      );
    }
    if (data.containsKey('paired_device_id')) {
      context.handle(
        _pairedDeviceIdMeta,
        pairedDeviceId.isAcceptableOrUnknown(
          data['paired_device_id']!,
          _pairedDeviceIdMeta,
        ),
      );
    }
    if (data.containsKey('protocol_version')) {
      context.handle(
        _protocolVersionMeta,
        protocolVersion.isAcceptableOrUnknown(
          data['protocol_version']!,
          _protocolVersionMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('last_heartbeat_at')) {
      context.handle(
        _lastHeartbeatAtMeta,
        lastHeartbeatAt.isAcceptableOrUnknown(
          data['last_heartbeat_at']!,
          _lastHeartbeatAtMeta,
        ),
      );
    }
    if (data.containsKey('registered_by')) {
      context.handle(
        _registeredByMeta,
        registeredBy.isAcceptableOrUnknown(
          data['registered_by']!,
          _registeredByMeta,
        ),
      );
    }
    if (data.containsKey('drained_at')) {
      context.handle(
        _drainedAtMeta,
        drainedAt.isAcceptableOrUnknown(data['drained_at']!, _drainedAtMeta),
      );
    }
    if (data.containsKey('revoked_at')) {
      context.handle(
        _revokedAtMeta,
        revokedAt.isAcceptableOrUnknown(data['revoked_at']!, _revokedAtMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkersTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkersTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      capsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caps_json'],
      )!,
      platform: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}platform'],
      )!,
      credentialRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}credential_ref'],
      ),
      pairedDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}paired_device_id'],
      ),
      protocolVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}protocol_version'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      lastHeartbeatAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_heartbeat_at'],
      ),
      registeredBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}registered_by'],
      ),
      drainedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}drained_at'],
      ),
      revokedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}revoked_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $WorkersTableTable createAlias(String alias) {
    return $WorkersTableTable(attachedDatabase, alias);
  }
}

class WorkersTableData extends DataClass
    implements Insertable<WorkersTableData> {
  /// Unique worker id (UUID v4).
  final String id;

  /// Operator-facing worker name (e.g. "mac-studio").
  final String name;

  /// JSON-encoded `WorkerCapabilities` (OS, arch, cores, RAM, flutter SDK,
  /// sandbox backends, ML/GPU, always-on).
  final String capsJson;

  /// Coarse platform string (`macos`/`linux`/`windows`) for quick display.
  final String platform;

  /// Reference to the paired-device credential (never the secret itself).
  final String? credentialRef;

  /// The paired-device row backing this worker (PRD 15), when paired.
  final String? pairedDeviceId;

  /// Wire protocol version the worker handshaked with. A mismatch marks the
  /// worker `incompatible` and withholds leases (spec Clarifications).
  final int protocolVersion;

  /// Lifecycle status: `online`/`draining`/`offline`/`incompatible`/`revoked`.
  final String status;

  /// Last heartbeat time (server clock; workers never set server time).
  final DateTime? lastHeartbeatAt;

  /// Principal (user id) that registered this worker.
  final String? registeredBy;

  /// When the operator put the worker into drain (finish current, take no new).
  final DateTime? drainedAt;

  /// When the worker was revoked (its live session must terminate; no leases).
  final DateTime? revokedAt;

  /// Last error surfaced by/about the worker (for the fleet panel).
  final String? lastError;

  /// Registration time.
  final DateTime createdAt;
  const WorkersTableData({
    required this.id,
    required this.name,
    required this.capsJson,
    required this.platform,
    this.credentialRef,
    this.pairedDeviceId,
    required this.protocolVersion,
    required this.status,
    this.lastHeartbeatAt,
    this.registeredBy,
    this.drainedAt,
    this.revokedAt,
    this.lastError,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['caps_json'] = Variable<String>(capsJson);
    map['platform'] = Variable<String>(platform);
    if (!nullToAbsent || credentialRef != null) {
      map['credential_ref'] = Variable<String>(credentialRef);
    }
    if (!nullToAbsent || pairedDeviceId != null) {
      map['paired_device_id'] = Variable<String>(pairedDeviceId);
    }
    map['protocol_version'] = Variable<int>(protocolVersion);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || lastHeartbeatAt != null) {
      map['last_heartbeat_at'] = Variable<DateTime>(lastHeartbeatAt);
    }
    if (!nullToAbsent || registeredBy != null) {
      map['registered_by'] = Variable<String>(registeredBy);
    }
    if (!nullToAbsent || drainedAt != null) {
      map['drained_at'] = Variable<DateTime>(drainedAt);
    }
    if (!nullToAbsent || revokedAt != null) {
      map['revoked_at'] = Variable<DateTime>(revokedAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  WorkersTableCompanion toCompanion(bool nullToAbsent) {
    return WorkersTableCompanion(
      id: Value(id),
      name: Value(name),
      capsJson: Value(capsJson),
      platform: Value(platform),
      credentialRef: credentialRef == null && nullToAbsent
          ? const Value.absent()
          : Value(credentialRef),
      pairedDeviceId: pairedDeviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(pairedDeviceId),
      protocolVersion: Value(protocolVersion),
      status: Value(status),
      lastHeartbeatAt: lastHeartbeatAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastHeartbeatAt),
      registeredBy: registeredBy == null && nullToAbsent
          ? const Value.absent()
          : Value(registeredBy),
      drainedAt: drainedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(drainedAt),
      revokedAt: revokedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(revokedAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
    );
  }

  factory WorkersTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkersTableData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      capsJson: serializer.fromJson<String>(json['capsJson']),
      platform: serializer.fromJson<String>(json['platform']),
      credentialRef: serializer.fromJson<String?>(json['credentialRef']),
      pairedDeviceId: serializer.fromJson<String?>(json['pairedDeviceId']),
      protocolVersion: serializer.fromJson<int>(json['protocolVersion']),
      status: serializer.fromJson<String>(json['status']),
      lastHeartbeatAt: serializer.fromJson<DateTime?>(json['lastHeartbeatAt']),
      registeredBy: serializer.fromJson<String?>(json['registeredBy']),
      drainedAt: serializer.fromJson<DateTime?>(json['drainedAt']),
      revokedAt: serializer.fromJson<DateTime?>(json['revokedAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'capsJson': serializer.toJson<String>(capsJson),
      'platform': serializer.toJson<String>(platform),
      'credentialRef': serializer.toJson<String?>(credentialRef),
      'pairedDeviceId': serializer.toJson<String?>(pairedDeviceId),
      'protocolVersion': serializer.toJson<int>(protocolVersion),
      'status': serializer.toJson<String>(status),
      'lastHeartbeatAt': serializer.toJson<DateTime?>(lastHeartbeatAt),
      'registeredBy': serializer.toJson<String?>(registeredBy),
      'drainedAt': serializer.toJson<DateTime?>(drainedAt),
      'revokedAt': serializer.toJson<DateTime?>(revokedAt),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  WorkersTableData copyWith({
    String? id,
    String? name,
    String? capsJson,
    String? platform,
    Value<String?> credentialRef = const Value.absent(),
    Value<String?> pairedDeviceId = const Value.absent(),
    int? protocolVersion,
    String? status,
    Value<DateTime?> lastHeartbeatAt = const Value.absent(),
    Value<String?> registeredBy = const Value.absent(),
    Value<DateTime?> drainedAt = const Value.absent(),
    Value<DateTime?> revokedAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    DateTime? createdAt,
  }) => WorkersTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    capsJson: capsJson ?? this.capsJson,
    platform: platform ?? this.platform,
    credentialRef: credentialRef.present
        ? credentialRef.value
        : this.credentialRef,
    pairedDeviceId: pairedDeviceId.present
        ? pairedDeviceId.value
        : this.pairedDeviceId,
    protocolVersion: protocolVersion ?? this.protocolVersion,
    status: status ?? this.status,
    lastHeartbeatAt: lastHeartbeatAt.present
        ? lastHeartbeatAt.value
        : this.lastHeartbeatAt,
    registeredBy: registeredBy.present ? registeredBy.value : this.registeredBy,
    drainedAt: drainedAt.present ? drainedAt.value : this.drainedAt,
    revokedAt: revokedAt.present ? revokedAt.value : this.revokedAt,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
  );
  WorkersTableData copyWithCompanion(WorkersTableCompanion data) {
    return WorkersTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      capsJson: data.capsJson.present ? data.capsJson.value : this.capsJson,
      platform: data.platform.present ? data.platform.value : this.platform,
      credentialRef: data.credentialRef.present
          ? data.credentialRef.value
          : this.credentialRef,
      pairedDeviceId: data.pairedDeviceId.present
          ? data.pairedDeviceId.value
          : this.pairedDeviceId,
      protocolVersion: data.protocolVersion.present
          ? data.protocolVersion.value
          : this.protocolVersion,
      status: data.status.present ? data.status.value : this.status,
      lastHeartbeatAt: data.lastHeartbeatAt.present
          ? data.lastHeartbeatAt.value
          : this.lastHeartbeatAt,
      registeredBy: data.registeredBy.present
          ? data.registeredBy.value
          : this.registeredBy,
      drainedAt: data.drainedAt.present ? data.drainedAt.value : this.drainedAt,
      revokedAt: data.revokedAt.present ? data.revokedAt.value : this.revokedAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkersTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('capsJson: $capsJson, ')
          ..write('platform: $platform, ')
          ..write('credentialRef: $credentialRef, ')
          ..write('pairedDeviceId: $pairedDeviceId, ')
          ..write('protocolVersion: $protocolVersion, ')
          ..write('status: $status, ')
          ..write('lastHeartbeatAt: $lastHeartbeatAt, ')
          ..write('registeredBy: $registeredBy, ')
          ..write('drainedAt: $drainedAt, ')
          ..write('revokedAt: $revokedAt, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    capsJson,
    platform,
    credentialRef,
    pairedDeviceId,
    protocolVersion,
    status,
    lastHeartbeatAt,
    registeredBy,
    drainedAt,
    revokedAt,
    lastError,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkersTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.capsJson == this.capsJson &&
          other.platform == this.platform &&
          other.credentialRef == this.credentialRef &&
          other.pairedDeviceId == this.pairedDeviceId &&
          other.protocolVersion == this.protocolVersion &&
          other.status == this.status &&
          other.lastHeartbeatAt == this.lastHeartbeatAt &&
          other.registeredBy == this.registeredBy &&
          other.drainedAt == this.drainedAt &&
          other.revokedAt == this.revokedAt &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt);
}

class WorkersTableCompanion extends UpdateCompanion<WorkersTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> capsJson;
  final Value<String> platform;
  final Value<String?> credentialRef;
  final Value<String?> pairedDeviceId;
  final Value<int> protocolVersion;
  final Value<String> status;
  final Value<DateTime?> lastHeartbeatAt;
  final Value<String?> registeredBy;
  final Value<DateTime?> drainedAt;
  final Value<DateTime?> revokedAt;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const WorkersTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.capsJson = const Value.absent(),
    this.platform = const Value.absent(),
    this.credentialRef = const Value.absent(),
    this.pairedDeviceId = const Value.absent(),
    this.protocolVersion = const Value.absent(),
    this.status = const Value.absent(),
    this.lastHeartbeatAt = const Value.absent(),
    this.registeredBy = const Value.absent(),
    this.drainedAt = const Value.absent(),
    this.revokedAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkersTableCompanion.insert({
    required String id,
    required String name,
    this.capsJson = const Value.absent(),
    this.platform = const Value.absent(),
    this.credentialRef = const Value.absent(),
    this.pairedDeviceId = const Value.absent(),
    this.protocolVersion = const Value.absent(),
    this.status = const Value.absent(),
    this.lastHeartbeatAt = const Value.absent(),
    this.registeredBy = const Value.absent(),
    this.drainedAt = const Value.absent(),
    this.revokedAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<WorkersTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? capsJson,
    Expression<String>? platform,
    Expression<String>? credentialRef,
    Expression<String>? pairedDeviceId,
    Expression<int>? protocolVersion,
    Expression<String>? status,
    Expression<DateTime>? lastHeartbeatAt,
    Expression<String>? registeredBy,
    Expression<DateTime>? drainedAt,
    Expression<DateTime>? revokedAt,
    Expression<String>? lastError,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (capsJson != null) 'caps_json': capsJson,
      if (platform != null) 'platform': platform,
      if (credentialRef != null) 'credential_ref': credentialRef,
      if (pairedDeviceId != null) 'paired_device_id': pairedDeviceId,
      if (protocolVersion != null) 'protocol_version': protocolVersion,
      if (status != null) 'status': status,
      if (lastHeartbeatAt != null) 'last_heartbeat_at': lastHeartbeatAt,
      if (registeredBy != null) 'registered_by': registeredBy,
      if (drainedAt != null) 'drained_at': drainedAt,
      if (revokedAt != null) 'revoked_at': revokedAt,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkersTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? capsJson,
    Value<String>? platform,
    Value<String?>? credentialRef,
    Value<String?>? pairedDeviceId,
    Value<int>? protocolVersion,
    Value<String>? status,
    Value<DateTime?>? lastHeartbeatAt,
    Value<String?>? registeredBy,
    Value<DateTime?>? drainedAt,
    Value<DateTime?>? revokedAt,
    Value<String?>? lastError,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return WorkersTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      capsJson: capsJson ?? this.capsJson,
      platform: platform ?? this.platform,
      credentialRef: credentialRef ?? this.credentialRef,
      pairedDeviceId: pairedDeviceId ?? this.pairedDeviceId,
      protocolVersion: protocolVersion ?? this.protocolVersion,
      status: status ?? this.status,
      lastHeartbeatAt: lastHeartbeatAt ?? this.lastHeartbeatAt,
      registeredBy: registeredBy ?? this.registeredBy,
      drainedAt: drainedAt ?? this.drainedAt,
      revokedAt: revokedAt ?? this.revokedAt,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
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
    if (capsJson.present) {
      map['caps_json'] = Variable<String>(capsJson.value);
    }
    if (platform.present) {
      map['platform'] = Variable<String>(platform.value);
    }
    if (credentialRef.present) {
      map['credential_ref'] = Variable<String>(credentialRef.value);
    }
    if (pairedDeviceId.present) {
      map['paired_device_id'] = Variable<String>(pairedDeviceId.value);
    }
    if (protocolVersion.present) {
      map['protocol_version'] = Variable<int>(protocolVersion.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (lastHeartbeatAt.present) {
      map['last_heartbeat_at'] = Variable<DateTime>(lastHeartbeatAt.value);
    }
    if (registeredBy.present) {
      map['registered_by'] = Variable<String>(registeredBy.value);
    }
    if (drainedAt.present) {
      map['drained_at'] = Variable<DateTime>(drainedAt.value);
    }
    if (revokedAt.present) {
      map['revoked_at'] = Variable<DateTime>(revokedAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkersTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('capsJson: $capsJson, ')
          ..write('platform: $platform, ')
          ..write('credentialRef: $credentialRef, ')
          ..write('pairedDeviceId: $pairedDeviceId, ')
          ..write('protocolVersion: $protocolVersion, ')
          ..write('status: $status, ')
          ..write('lastHeartbeatAt: $lastHeartbeatAt, ')
          ..write('registeredBy: $registeredBy, ')
          ..write('drainedAt: $drainedAt, ')
          ..write('revokedAt: $revokedAt, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JobsTableTable extends JobsTable
    with TableInfo<$JobsTableTable, JobsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JobsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _specJsonMeta = const VerificationMeta(
    'specJson',
  );
  @override
  late final GeneratedColumn<String> specJson = GeneratedColumn<String>(
    'spec_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _requiredCapsJsonMeta = const VerificationMeta(
    'requiredCapsJson',
  );
  @override
  late final GeneratedColumn<String> requiredCapsJson = GeneratedColumn<String>(
    'required_caps_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _preferredCapsJsonMeta = const VerificationMeta(
    'preferredCapsJson',
  );
  @override
  late final GeneratedColumn<String> preferredCapsJson =
      GeneratedColumn<String>(
        'preferred_caps_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('queued'),
  );
  static const VerificationMeta _workerIdMeta = const VerificationMeta(
    'workerId',
  );
  @override
  late final GeneratedColumn<String> workerId = GeneratedColumn<String>(
    'worker_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pinnedWorkerIdMeta = const VerificationMeta(
    'pinnedWorkerId',
  );
  @override
  late final GeneratedColumn<String> pinnedWorkerId = GeneratedColumn<String>(
    'pinned_worker_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _leaseExpiresAtMeta = const VerificationMeta(
    'leaseExpiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> leaseExpiresAt =
      GeneratedColumn<DateTime>(
        'lease_expires_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _submittedByMeta = const VerificationMeta(
    'submittedBy',
  );
  @override
  late final GeneratedColumn<String> submittedBy = GeneratedColumn<String>(
    'submitted_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _costCentsMeta = const VerificationMeta(
    'costCents',
  );
  @override
  late final GeneratedColumn<int> costCents = GeneratedColumn<int>(
    'cost_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _maxAttemptsMeta = const VerificationMeta(
    'maxAttempts',
  );
  @override
  late final GeneratedColumn<int> maxAttempts = GeneratedColumn<int>(
    'max_attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _lastAckedSeqMeta = const VerificationMeta(
    'lastAckedSeq',
  );
  @override
  late final GeneratedColumn<int> lastAckedSeq = GeneratedColumn<int>(
    'last_acked_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _resultJsonMeta = const VerificationMeta(
    'resultJson',
  );
  @override
  late final GeneratedColumn<String> resultJson = GeneratedColumn<String>(
    'result_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
    'error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _agentIdMeta = const VerificationMeta(
    'agentId',
  );
  @override
  late final GeneratedColumn<String> agentId = GeneratedColumn<String>(
    'agent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
    'conversation_id',
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _leasedAtMeta = const VerificationMeta(
    'leasedAt',
  );
  @override
  late final GeneratedColumn<DateTime> leasedAt = GeneratedColumn<DateTime>(
    'leased_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
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
    workspaceId,
    kind,
    specJson,
    requiredCapsJson,
    preferredCapsJson,
    status,
    workerId,
    pinnedWorkerId,
    leaseExpiresAt,
    priority,
    submittedBy,
    costCents,
    attempts,
    maxAttempts,
    lastAckedSeq,
    resultJson,
    error,
    agentId,
    conversationId,
    createdAt,
    leasedAt,
    startedAt,
    finishedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'jobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<JobsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('spec_json')) {
      context.handle(
        _specJsonMeta,
        specJson.isAcceptableOrUnknown(data['spec_json']!, _specJsonMeta),
      );
    }
    if (data.containsKey('required_caps_json')) {
      context.handle(
        _requiredCapsJsonMeta,
        requiredCapsJson.isAcceptableOrUnknown(
          data['required_caps_json']!,
          _requiredCapsJsonMeta,
        ),
      );
    }
    if (data.containsKey('preferred_caps_json')) {
      context.handle(
        _preferredCapsJsonMeta,
        preferredCapsJson.isAcceptableOrUnknown(
          data['preferred_caps_json']!,
          _preferredCapsJsonMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('worker_id')) {
      context.handle(
        _workerIdMeta,
        workerId.isAcceptableOrUnknown(data['worker_id']!, _workerIdMeta),
      );
    }
    if (data.containsKey('pinned_worker_id')) {
      context.handle(
        _pinnedWorkerIdMeta,
        pinnedWorkerId.isAcceptableOrUnknown(
          data['pinned_worker_id']!,
          _pinnedWorkerIdMeta,
        ),
      );
    }
    if (data.containsKey('lease_expires_at')) {
      context.handle(
        _leaseExpiresAtMeta,
        leaseExpiresAt.isAcceptableOrUnknown(
          data['lease_expires_at']!,
          _leaseExpiresAtMeta,
        ),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('submitted_by')) {
      context.handle(
        _submittedByMeta,
        submittedBy.isAcceptableOrUnknown(
          data['submitted_by']!,
          _submittedByMeta,
        ),
      );
    }
    if (data.containsKey('cost_cents')) {
      context.handle(
        _costCentsMeta,
        costCents.isAcceptableOrUnknown(data['cost_cents']!, _costCentsMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('max_attempts')) {
      context.handle(
        _maxAttemptsMeta,
        maxAttempts.isAcceptableOrUnknown(
          data['max_attempts']!,
          _maxAttemptsMeta,
        ),
      );
    }
    if (data.containsKey('last_acked_seq')) {
      context.handle(
        _lastAckedSeqMeta,
        lastAckedSeq.isAcceptableOrUnknown(
          data['last_acked_seq']!,
          _lastAckedSeqMeta,
        ),
      );
    }
    if (data.containsKey('result_json')) {
      context.handle(
        _resultJsonMeta,
        resultJson.isAcceptableOrUnknown(data['result_json']!, _resultJsonMeta),
      );
    }
    if (data.containsKey('error')) {
      context.handle(
        _errorMeta,
        error.isAcceptableOrUnknown(data['error']!, _errorMeta),
      );
    }
    if (data.containsKey('agent_id')) {
      context.handle(
        _agentIdMeta,
        agentId.isAcceptableOrUnknown(data['agent_id']!, _agentIdMeta),
      );
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('leased_at')) {
      context.handle(
        _leasedAtMeta,
        leasedAt.isAcceptableOrUnknown(data['leased_at']!, _leasedAtMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
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
  JobsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JobsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      specJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}spec_json'],
      )!,
      requiredCapsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}required_caps_json'],
      )!,
      preferredCapsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preferred_caps_json'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      workerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}worker_id'],
      ),
      pinnedWorkerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pinned_worker_id'],
      ),
      leaseExpiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}lease_expires_at'],
      ),
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      submittedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}submitted_by'],
      ),
      costCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cost_cents'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      maxAttempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_attempts'],
      )!,
      lastAckedSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_acked_seq'],
      )!,
      resultJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}result_json'],
      ),
      error: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error'],
      ),
      agentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agent_id'],
      ),
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      leasedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}leased_at'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      ),
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}finished_at'],
      ),
    );
  }

  @override
  $JobsTableTable createAlias(String alias) {
    return $JobsTableTable(attachedDatabase, alias);
  }
}

class JobsTableData extends DataClass implements Insertable<JobsTableData> {
  /// Unique job id (UUID v4).
  final String id;

  /// Workspace scope.
  final String workspaceId;

  /// Job kind wire name (`agentRun`/`pipelineStep`/`codeIndex`/`goldenRender`/
  /// `benchmark`/`evalBatch`).
  final String kind;

  /// JSON-encoded `JobSpec` payload (kind-specific).
  final String specJson;

  /// JSON array of required capability keys (must all be present on a worker).
  final String requiredCapsJson;

  /// JSON array of preferred capability keys (break ties / prefer placement).
  final String preferredCapsJson;

  /// Status: `queued`/`leased`/`running`/`done`/`failed`/`reaped`/`cancelled`.
  final String status;

  /// The worker currently holding the lease (null while queued).
  final String? workerId;

  /// An explicit pin: this job MUST run on this worker id (deterministic).
  final String? pinnedWorkerId;

  /// Lease expiry (server clock). A worker that vanishes has its lease reaped
  /// after this instant.
  final DateTime? leaseExpiresAt;

  /// Scheduling priority (higher runs first within a workspace).
  final int priority;

  /// Principal (user id) that submitted the job.
  final String? submittedBy;

  /// Metered worker cost in cents (token cost stays the billable cost).
  final int costCents;

  /// Attempt count (incremented on each lease → reap/retry cycle).
  final int attempts;

  /// Maximum attempts before the job is surfaced as failed.
  final int maxAttempts;

  /// Last event sequence the server acked from the worker (reconnect replay).
  final int lastAckedSeq;

  /// JSON-encoded result payload (artifact refs, branch, grade) when done.
  final String? resultJson;

  /// Failure reason when `failed`.
  final String? error;

  /// Correlated agent run / conversation this job drives, when applicable.
  final String? agentId;

  /// Correlated conversation (channel) id, when applicable.
  final String? conversationId;

  /// Submission time.
  final DateTime createdAt;

  /// When the job was leased to a worker.
  final DateTime? leasedAt;

  /// When the worker reported it started executing.
  final DateTime? startedAt;

  /// When the job reached a terminal state.
  final DateTime? finishedAt;
  const JobsTableData({
    required this.id,
    required this.workspaceId,
    required this.kind,
    required this.specJson,
    required this.requiredCapsJson,
    required this.preferredCapsJson,
    required this.status,
    this.workerId,
    this.pinnedWorkerId,
    this.leaseExpiresAt,
    required this.priority,
    this.submittedBy,
    required this.costCents,
    required this.attempts,
    required this.maxAttempts,
    required this.lastAckedSeq,
    this.resultJson,
    this.error,
    this.agentId,
    this.conversationId,
    required this.createdAt,
    this.leasedAt,
    this.startedAt,
    this.finishedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['kind'] = Variable<String>(kind);
    map['spec_json'] = Variable<String>(specJson);
    map['required_caps_json'] = Variable<String>(requiredCapsJson);
    map['preferred_caps_json'] = Variable<String>(preferredCapsJson);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || workerId != null) {
      map['worker_id'] = Variable<String>(workerId);
    }
    if (!nullToAbsent || pinnedWorkerId != null) {
      map['pinned_worker_id'] = Variable<String>(pinnedWorkerId);
    }
    if (!nullToAbsent || leaseExpiresAt != null) {
      map['lease_expires_at'] = Variable<DateTime>(leaseExpiresAt);
    }
    map['priority'] = Variable<int>(priority);
    if (!nullToAbsent || submittedBy != null) {
      map['submitted_by'] = Variable<String>(submittedBy);
    }
    map['cost_cents'] = Variable<int>(costCents);
    map['attempts'] = Variable<int>(attempts);
    map['max_attempts'] = Variable<int>(maxAttempts);
    map['last_acked_seq'] = Variable<int>(lastAckedSeq);
    if (!nullToAbsent || resultJson != null) {
      map['result_json'] = Variable<String>(resultJson);
    }
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    if (!nullToAbsent || agentId != null) {
      map['agent_id'] = Variable<String>(agentId);
    }
    if (!nullToAbsent || conversationId != null) {
      map['conversation_id'] = Variable<String>(conversationId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || leasedAt != null) {
      map['leased_at'] = Variable<DateTime>(leasedAt);
    }
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<DateTime>(startedAt);
    }
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<DateTime>(finishedAt);
    }
    return map;
  }

  JobsTableCompanion toCompanion(bool nullToAbsent) {
    return JobsTableCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      kind: Value(kind),
      specJson: Value(specJson),
      requiredCapsJson: Value(requiredCapsJson),
      preferredCapsJson: Value(preferredCapsJson),
      status: Value(status),
      workerId: workerId == null && nullToAbsent
          ? const Value.absent()
          : Value(workerId),
      pinnedWorkerId: pinnedWorkerId == null && nullToAbsent
          ? const Value.absent()
          : Value(pinnedWorkerId),
      leaseExpiresAt: leaseExpiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(leaseExpiresAt),
      priority: Value(priority),
      submittedBy: submittedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(submittedBy),
      costCents: Value(costCents),
      attempts: Value(attempts),
      maxAttempts: Value(maxAttempts),
      lastAckedSeq: Value(lastAckedSeq),
      resultJson: resultJson == null && nullToAbsent
          ? const Value.absent()
          : Value(resultJson),
      error: error == null && nullToAbsent
          ? const Value.absent()
          : Value(error),
      agentId: agentId == null && nullToAbsent
          ? const Value.absent()
          : Value(agentId),
      conversationId: conversationId == null && nullToAbsent
          ? const Value.absent()
          : Value(conversationId),
      createdAt: Value(createdAt),
      leasedAt: leasedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(leasedAt),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
    );
  }

  factory JobsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JobsTableData(
      id: serializer.fromJson<String>(json['id']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      kind: serializer.fromJson<String>(json['kind']),
      specJson: serializer.fromJson<String>(json['specJson']),
      requiredCapsJson: serializer.fromJson<String>(json['requiredCapsJson']),
      preferredCapsJson: serializer.fromJson<String>(json['preferredCapsJson']),
      status: serializer.fromJson<String>(json['status']),
      workerId: serializer.fromJson<String?>(json['workerId']),
      pinnedWorkerId: serializer.fromJson<String?>(json['pinnedWorkerId']),
      leaseExpiresAt: serializer.fromJson<DateTime?>(json['leaseExpiresAt']),
      priority: serializer.fromJson<int>(json['priority']),
      submittedBy: serializer.fromJson<String?>(json['submittedBy']),
      costCents: serializer.fromJson<int>(json['costCents']),
      attempts: serializer.fromJson<int>(json['attempts']),
      maxAttempts: serializer.fromJson<int>(json['maxAttempts']),
      lastAckedSeq: serializer.fromJson<int>(json['lastAckedSeq']),
      resultJson: serializer.fromJson<String?>(json['resultJson']),
      error: serializer.fromJson<String?>(json['error']),
      agentId: serializer.fromJson<String?>(json['agentId']),
      conversationId: serializer.fromJson<String?>(json['conversationId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      leasedAt: serializer.fromJson<DateTime?>(json['leasedAt']),
      startedAt: serializer.fromJson<DateTime?>(json['startedAt']),
      finishedAt: serializer.fromJson<DateTime?>(json['finishedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'kind': serializer.toJson<String>(kind),
      'specJson': serializer.toJson<String>(specJson),
      'requiredCapsJson': serializer.toJson<String>(requiredCapsJson),
      'preferredCapsJson': serializer.toJson<String>(preferredCapsJson),
      'status': serializer.toJson<String>(status),
      'workerId': serializer.toJson<String?>(workerId),
      'pinnedWorkerId': serializer.toJson<String?>(pinnedWorkerId),
      'leaseExpiresAt': serializer.toJson<DateTime?>(leaseExpiresAt),
      'priority': serializer.toJson<int>(priority),
      'submittedBy': serializer.toJson<String?>(submittedBy),
      'costCents': serializer.toJson<int>(costCents),
      'attempts': serializer.toJson<int>(attempts),
      'maxAttempts': serializer.toJson<int>(maxAttempts),
      'lastAckedSeq': serializer.toJson<int>(lastAckedSeq),
      'resultJson': serializer.toJson<String?>(resultJson),
      'error': serializer.toJson<String?>(error),
      'agentId': serializer.toJson<String?>(agentId),
      'conversationId': serializer.toJson<String?>(conversationId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'leasedAt': serializer.toJson<DateTime?>(leasedAt),
      'startedAt': serializer.toJson<DateTime?>(startedAt),
      'finishedAt': serializer.toJson<DateTime?>(finishedAt),
    };
  }

  JobsTableData copyWith({
    String? id,
    String? workspaceId,
    String? kind,
    String? specJson,
    String? requiredCapsJson,
    String? preferredCapsJson,
    String? status,
    Value<String?> workerId = const Value.absent(),
    Value<String?> pinnedWorkerId = const Value.absent(),
    Value<DateTime?> leaseExpiresAt = const Value.absent(),
    int? priority,
    Value<String?> submittedBy = const Value.absent(),
    int? costCents,
    int? attempts,
    int? maxAttempts,
    int? lastAckedSeq,
    Value<String?> resultJson = const Value.absent(),
    Value<String?> error = const Value.absent(),
    Value<String?> agentId = const Value.absent(),
    Value<String?> conversationId = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> leasedAt = const Value.absent(),
    Value<DateTime?> startedAt = const Value.absent(),
    Value<DateTime?> finishedAt = const Value.absent(),
  }) => JobsTableData(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    kind: kind ?? this.kind,
    specJson: specJson ?? this.specJson,
    requiredCapsJson: requiredCapsJson ?? this.requiredCapsJson,
    preferredCapsJson: preferredCapsJson ?? this.preferredCapsJson,
    status: status ?? this.status,
    workerId: workerId.present ? workerId.value : this.workerId,
    pinnedWorkerId: pinnedWorkerId.present
        ? pinnedWorkerId.value
        : this.pinnedWorkerId,
    leaseExpiresAt: leaseExpiresAt.present
        ? leaseExpiresAt.value
        : this.leaseExpiresAt,
    priority: priority ?? this.priority,
    submittedBy: submittedBy.present ? submittedBy.value : this.submittedBy,
    costCents: costCents ?? this.costCents,
    attempts: attempts ?? this.attempts,
    maxAttempts: maxAttempts ?? this.maxAttempts,
    lastAckedSeq: lastAckedSeq ?? this.lastAckedSeq,
    resultJson: resultJson.present ? resultJson.value : this.resultJson,
    error: error.present ? error.value : this.error,
    agentId: agentId.present ? agentId.value : this.agentId,
    conversationId: conversationId.present
        ? conversationId.value
        : this.conversationId,
    createdAt: createdAt ?? this.createdAt,
    leasedAt: leasedAt.present ? leasedAt.value : this.leasedAt,
    startedAt: startedAt.present ? startedAt.value : this.startedAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
  );
  JobsTableData copyWithCompanion(JobsTableCompanion data) {
    return JobsTableData(
      id: data.id.present ? data.id.value : this.id,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      kind: data.kind.present ? data.kind.value : this.kind,
      specJson: data.specJson.present ? data.specJson.value : this.specJson,
      requiredCapsJson: data.requiredCapsJson.present
          ? data.requiredCapsJson.value
          : this.requiredCapsJson,
      preferredCapsJson: data.preferredCapsJson.present
          ? data.preferredCapsJson.value
          : this.preferredCapsJson,
      status: data.status.present ? data.status.value : this.status,
      workerId: data.workerId.present ? data.workerId.value : this.workerId,
      pinnedWorkerId: data.pinnedWorkerId.present
          ? data.pinnedWorkerId.value
          : this.pinnedWorkerId,
      leaseExpiresAt: data.leaseExpiresAt.present
          ? data.leaseExpiresAt.value
          : this.leaseExpiresAt,
      priority: data.priority.present ? data.priority.value : this.priority,
      submittedBy: data.submittedBy.present
          ? data.submittedBy.value
          : this.submittedBy,
      costCents: data.costCents.present ? data.costCents.value : this.costCents,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      maxAttempts: data.maxAttempts.present
          ? data.maxAttempts.value
          : this.maxAttempts,
      lastAckedSeq: data.lastAckedSeq.present
          ? data.lastAckedSeq.value
          : this.lastAckedSeq,
      resultJson: data.resultJson.present
          ? data.resultJson.value
          : this.resultJson,
      error: data.error.present ? data.error.value : this.error,
      agentId: data.agentId.present ? data.agentId.value : this.agentId,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      leasedAt: data.leasedAt.present ? data.leasedAt.value : this.leasedAt,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JobsTableData(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('kind: $kind, ')
          ..write('specJson: $specJson, ')
          ..write('requiredCapsJson: $requiredCapsJson, ')
          ..write('preferredCapsJson: $preferredCapsJson, ')
          ..write('status: $status, ')
          ..write('workerId: $workerId, ')
          ..write('pinnedWorkerId: $pinnedWorkerId, ')
          ..write('leaseExpiresAt: $leaseExpiresAt, ')
          ..write('priority: $priority, ')
          ..write('submittedBy: $submittedBy, ')
          ..write('costCents: $costCents, ')
          ..write('attempts: $attempts, ')
          ..write('maxAttempts: $maxAttempts, ')
          ..write('lastAckedSeq: $lastAckedSeq, ')
          ..write('resultJson: $resultJson, ')
          ..write('error: $error, ')
          ..write('agentId: $agentId, ')
          ..write('conversationId: $conversationId, ')
          ..write('createdAt: $createdAt, ')
          ..write('leasedAt: $leasedAt, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    workspaceId,
    kind,
    specJson,
    requiredCapsJson,
    preferredCapsJson,
    status,
    workerId,
    pinnedWorkerId,
    leaseExpiresAt,
    priority,
    submittedBy,
    costCents,
    attempts,
    maxAttempts,
    lastAckedSeq,
    resultJson,
    error,
    agentId,
    conversationId,
    createdAt,
    leasedAt,
    startedAt,
    finishedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JobsTableData &&
          other.id == this.id &&
          other.workspaceId == this.workspaceId &&
          other.kind == this.kind &&
          other.specJson == this.specJson &&
          other.requiredCapsJson == this.requiredCapsJson &&
          other.preferredCapsJson == this.preferredCapsJson &&
          other.status == this.status &&
          other.workerId == this.workerId &&
          other.pinnedWorkerId == this.pinnedWorkerId &&
          other.leaseExpiresAt == this.leaseExpiresAt &&
          other.priority == this.priority &&
          other.submittedBy == this.submittedBy &&
          other.costCents == this.costCents &&
          other.attempts == this.attempts &&
          other.maxAttempts == this.maxAttempts &&
          other.lastAckedSeq == this.lastAckedSeq &&
          other.resultJson == this.resultJson &&
          other.error == this.error &&
          other.agentId == this.agentId &&
          other.conversationId == this.conversationId &&
          other.createdAt == this.createdAt &&
          other.leasedAt == this.leasedAt &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt);
}

class JobsTableCompanion extends UpdateCompanion<JobsTableData> {
  final Value<String> id;
  final Value<String> workspaceId;
  final Value<String> kind;
  final Value<String> specJson;
  final Value<String> requiredCapsJson;
  final Value<String> preferredCapsJson;
  final Value<String> status;
  final Value<String?> workerId;
  final Value<String?> pinnedWorkerId;
  final Value<DateTime?> leaseExpiresAt;
  final Value<int> priority;
  final Value<String?> submittedBy;
  final Value<int> costCents;
  final Value<int> attempts;
  final Value<int> maxAttempts;
  final Value<int> lastAckedSeq;
  final Value<String?> resultJson;
  final Value<String?> error;
  final Value<String?> agentId;
  final Value<String?> conversationId;
  final Value<DateTime> createdAt;
  final Value<DateTime?> leasedAt;
  final Value<DateTime?> startedAt;
  final Value<DateTime?> finishedAt;
  final Value<int> rowid;
  const JobsTableCompanion({
    this.id = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.kind = const Value.absent(),
    this.specJson = const Value.absent(),
    this.requiredCapsJson = const Value.absent(),
    this.preferredCapsJson = const Value.absent(),
    this.status = const Value.absent(),
    this.workerId = const Value.absent(),
    this.pinnedWorkerId = const Value.absent(),
    this.leaseExpiresAt = const Value.absent(),
    this.priority = const Value.absent(),
    this.submittedBy = const Value.absent(),
    this.costCents = const Value.absent(),
    this.attempts = const Value.absent(),
    this.maxAttempts = const Value.absent(),
    this.lastAckedSeq = const Value.absent(),
    this.resultJson = const Value.absent(),
    this.error = const Value.absent(),
    this.agentId = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.leasedAt = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JobsTableCompanion.insert({
    required String id,
    required String workspaceId,
    required String kind,
    this.specJson = const Value.absent(),
    this.requiredCapsJson = const Value.absent(),
    this.preferredCapsJson = const Value.absent(),
    this.status = const Value.absent(),
    this.workerId = const Value.absent(),
    this.pinnedWorkerId = const Value.absent(),
    this.leaseExpiresAt = const Value.absent(),
    this.priority = const Value.absent(),
    this.submittedBy = const Value.absent(),
    this.costCents = const Value.absent(),
    this.attempts = const Value.absent(),
    this.maxAttempts = const Value.absent(),
    this.lastAckedSeq = const Value.absent(),
    this.resultJson = const Value.absent(),
    this.error = const Value.absent(),
    this.agentId = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.leasedAt = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       kind = Value(kind);
  static Insertable<JobsTableData> custom({
    Expression<String>? id,
    Expression<String>? workspaceId,
    Expression<String>? kind,
    Expression<String>? specJson,
    Expression<String>? requiredCapsJson,
    Expression<String>? preferredCapsJson,
    Expression<String>? status,
    Expression<String>? workerId,
    Expression<String>? pinnedWorkerId,
    Expression<DateTime>? leaseExpiresAt,
    Expression<int>? priority,
    Expression<String>? submittedBy,
    Expression<int>? costCents,
    Expression<int>? attempts,
    Expression<int>? maxAttempts,
    Expression<int>? lastAckedSeq,
    Expression<String>? resultJson,
    Expression<String>? error,
    Expression<String>? agentId,
    Expression<String>? conversationId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? leasedAt,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? finishedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (kind != null) 'kind': kind,
      if (specJson != null) 'spec_json': specJson,
      if (requiredCapsJson != null) 'required_caps_json': requiredCapsJson,
      if (preferredCapsJson != null) 'preferred_caps_json': preferredCapsJson,
      if (status != null) 'status': status,
      if (workerId != null) 'worker_id': workerId,
      if (pinnedWorkerId != null) 'pinned_worker_id': pinnedWorkerId,
      if (leaseExpiresAt != null) 'lease_expires_at': leaseExpiresAt,
      if (priority != null) 'priority': priority,
      if (submittedBy != null) 'submitted_by': submittedBy,
      if (costCents != null) 'cost_cents': costCents,
      if (attempts != null) 'attempts': attempts,
      if (maxAttempts != null) 'max_attempts': maxAttempts,
      if (lastAckedSeq != null) 'last_acked_seq': lastAckedSeq,
      if (resultJson != null) 'result_json': resultJson,
      if (error != null) 'error': error,
      if (agentId != null) 'agent_id': agentId,
      if (conversationId != null) 'conversation_id': conversationId,
      if (createdAt != null) 'created_at': createdAt,
      if (leasedAt != null) 'leased_at': leasedAt,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JobsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? workspaceId,
    Value<String>? kind,
    Value<String>? specJson,
    Value<String>? requiredCapsJson,
    Value<String>? preferredCapsJson,
    Value<String>? status,
    Value<String?>? workerId,
    Value<String?>? pinnedWorkerId,
    Value<DateTime?>? leaseExpiresAt,
    Value<int>? priority,
    Value<String?>? submittedBy,
    Value<int>? costCents,
    Value<int>? attempts,
    Value<int>? maxAttempts,
    Value<int>? lastAckedSeq,
    Value<String?>? resultJson,
    Value<String?>? error,
    Value<String?>? agentId,
    Value<String?>? conversationId,
    Value<DateTime>? createdAt,
    Value<DateTime?>? leasedAt,
    Value<DateTime?>? startedAt,
    Value<DateTime?>? finishedAt,
    Value<int>? rowid,
  }) {
    return JobsTableCompanion(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      kind: kind ?? this.kind,
      specJson: specJson ?? this.specJson,
      requiredCapsJson: requiredCapsJson ?? this.requiredCapsJson,
      preferredCapsJson: preferredCapsJson ?? this.preferredCapsJson,
      status: status ?? this.status,
      workerId: workerId ?? this.workerId,
      pinnedWorkerId: pinnedWorkerId ?? this.pinnedWorkerId,
      leaseExpiresAt: leaseExpiresAt ?? this.leaseExpiresAt,
      priority: priority ?? this.priority,
      submittedBy: submittedBy ?? this.submittedBy,
      costCents: costCents ?? this.costCents,
      attempts: attempts ?? this.attempts,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      lastAckedSeq: lastAckedSeq ?? this.lastAckedSeq,
      resultJson: resultJson ?? this.resultJson,
      error: error ?? this.error,
      agentId: agentId ?? this.agentId,
      conversationId: conversationId ?? this.conversationId,
      createdAt: createdAt ?? this.createdAt,
      leasedAt: leasedAt ?? this.leasedAt,
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
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (specJson.present) {
      map['spec_json'] = Variable<String>(specJson.value);
    }
    if (requiredCapsJson.present) {
      map['required_caps_json'] = Variable<String>(requiredCapsJson.value);
    }
    if (preferredCapsJson.present) {
      map['preferred_caps_json'] = Variable<String>(preferredCapsJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (workerId.present) {
      map['worker_id'] = Variable<String>(workerId.value);
    }
    if (pinnedWorkerId.present) {
      map['pinned_worker_id'] = Variable<String>(pinnedWorkerId.value);
    }
    if (leaseExpiresAt.present) {
      map['lease_expires_at'] = Variable<DateTime>(leaseExpiresAt.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (submittedBy.present) {
      map['submitted_by'] = Variable<String>(submittedBy.value);
    }
    if (costCents.present) {
      map['cost_cents'] = Variable<int>(costCents.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (maxAttempts.present) {
      map['max_attempts'] = Variable<int>(maxAttempts.value);
    }
    if (lastAckedSeq.present) {
      map['last_acked_seq'] = Variable<int>(lastAckedSeq.value);
    }
    if (resultJson.present) {
      map['result_json'] = Variable<String>(resultJson.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    if (agentId.present) {
      map['agent_id'] = Variable<String>(agentId.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (leasedAt.present) {
      map['leased_at'] = Variable<DateTime>(leasedAt.value);
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
    return (StringBuffer('JobsTableCompanion(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('kind: $kind, ')
          ..write('specJson: $specJson, ')
          ..write('requiredCapsJson: $requiredCapsJson, ')
          ..write('preferredCapsJson: $preferredCapsJson, ')
          ..write('status: $status, ')
          ..write('workerId: $workerId, ')
          ..write('pinnedWorkerId: $pinnedWorkerId, ')
          ..write('leaseExpiresAt: $leaseExpiresAt, ')
          ..write('priority: $priority, ')
          ..write('submittedBy: $submittedBy, ')
          ..write('costCents: $costCents, ')
          ..write('attempts: $attempts, ')
          ..write('maxAttempts: $maxAttempts, ')
          ..write('lastAckedSeq: $lastAckedSeq, ')
          ..write('resultJson: $resultJson, ')
          ..write('error: $error, ')
          ..write('agentId: $agentId, ')
          ..write('conversationId: $conversationId, ')
          ..write('createdAt: $createdAt, ')
          ..write('leasedAt: $leasedAt, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlacementLogTableTable extends PlacementLogTable
    with TableInfo<$PlacementLogTableTable, PlacementLogTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlacementLogTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
    'job_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workerIdMeta = const VerificationMeta(
    'workerId',
  );
  @override
  late final GeneratedColumn<String> workerId = GeneratedColumn<String>(
    'worker_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _decisionMeta = const VerificationMeta(
    'decision',
  );
  @override
  late final GeneratedColumn<String> decision = GeneratedColumn<String>(
    'decision',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('queued'),
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workspaceId,
    jobId,
    workerId,
    decision,
    reason,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'placement_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlacementLogTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('job_id')) {
      context.handle(
        _jobIdMeta,
        jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta),
      );
    } else if (isInserting) {
      context.missing(_jobIdMeta);
    }
    if (data.containsKey('worker_id')) {
      context.handle(
        _workerIdMeta,
        workerId.isAcceptableOrUnknown(data['worker_id']!, _workerIdMeta),
      );
    }
    if (data.containsKey('decision')) {
      context.handle(
        _decisionMeta,
        decision.isAcceptableOrUnknown(data['decision']!, _decisionMeta),
      );
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlacementLogTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlacementLogTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      jobId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}job_id'],
      )!,
      workerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}worker_id'],
      ),
      decision: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}decision'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PlacementLogTableTable createAlias(String alias) {
    return $PlacementLogTableTable(attachedDatabase, alias);
  }
}

class PlacementLogTableData extends DataClass
    implements Insertable<PlacementLogTableData> {
  /// Unique row id (UUID v4).
  final String id;

  /// Workspace scope (matches the job).
  final String workspaceId;

  /// The job this decision is about.
  final String jobId;

  /// The chosen worker id, or null when the decision was "stay queued".
  final String? workerId;

  /// Machine-parseable decision code (`pinned`/`preferred`/`spill`/`queued`/
  /// `no_capable_worker`/`cache_warming`/`reaped`/`retried`).
  final String decision;

  /// Human-readable explanation ("ran on mac-studio — required flutter;
  /// vps-1 lacked it").
  final String reason;

  /// Decision time.
  final DateTime createdAt;
  const PlacementLogTableData({
    required this.id,
    required this.workspaceId,
    required this.jobId,
    this.workerId,
    required this.decision,
    required this.reason,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['job_id'] = Variable<String>(jobId);
    if (!nullToAbsent || workerId != null) {
      map['worker_id'] = Variable<String>(workerId);
    }
    map['decision'] = Variable<String>(decision);
    map['reason'] = Variable<String>(reason);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PlacementLogTableCompanion toCompanion(bool nullToAbsent) {
    return PlacementLogTableCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      jobId: Value(jobId),
      workerId: workerId == null && nullToAbsent
          ? const Value.absent()
          : Value(workerId),
      decision: Value(decision),
      reason: Value(reason),
      createdAt: Value(createdAt),
    );
  }

  factory PlacementLogTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlacementLogTableData(
      id: serializer.fromJson<String>(json['id']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      jobId: serializer.fromJson<String>(json['jobId']),
      workerId: serializer.fromJson<String?>(json['workerId']),
      decision: serializer.fromJson<String>(json['decision']),
      reason: serializer.fromJson<String>(json['reason']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'jobId': serializer.toJson<String>(jobId),
      'workerId': serializer.toJson<String?>(workerId),
      'decision': serializer.toJson<String>(decision),
      'reason': serializer.toJson<String>(reason),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PlacementLogTableData copyWith({
    String? id,
    String? workspaceId,
    String? jobId,
    Value<String?> workerId = const Value.absent(),
    String? decision,
    String? reason,
    DateTime? createdAt,
  }) => PlacementLogTableData(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    jobId: jobId ?? this.jobId,
    workerId: workerId.present ? workerId.value : this.workerId,
    decision: decision ?? this.decision,
    reason: reason ?? this.reason,
    createdAt: createdAt ?? this.createdAt,
  );
  PlacementLogTableData copyWithCompanion(PlacementLogTableCompanion data) {
    return PlacementLogTableData(
      id: data.id.present ? data.id.value : this.id,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      workerId: data.workerId.present ? data.workerId.value : this.workerId,
      decision: data.decision.present ? data.decision.value : this.decision,
      reason: data.reason.present ? data.reason.value : this.reason,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlacementLogTableData(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('jobId: $jobId, ')
          ..write('workerId: $workerId, ')
          ..write('decision: $decision, ')
          ..write('reason: $reason, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    jobId,
    workerId,
    decision,
    reason,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlacementLogTableData &&
          other.id == this.id &&
          other.workspaceId == this.workspaceId &&
          other.jobId == this.jobId &&
          other.workerId == this.workerId &&
          other.decision == this.decision &&
          other.reason == this.reason &&
          other.createdAt == this.createdAt);
}

class PlacementLogTableCompanion
    extends UpdateCompanion<PlacementLogTableData> {
  final Value<String> id;
  final Value<String> workspaceId;
  final Value<String> jobId;
  final Value<String?> workerId;
  final Value<String> decision;
  final Value<String> reason;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PlacementLogTableCompanion({
    this.id = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.jobId = const Value.absent(),
    this.workerId = const Value.absent(),
    this.decision = const Value.absent(),
    this.reason = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlacementLogTableCompanion.insert({
    required String id,
    required String workspaceId,
    required String jobId,
    this.workerId = const Value.absent(),
    this.decision = const Value.absent(),
    this.reason = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       jobId = Value(jobId);
  static Insertable<PlacementLogTableData> custom({
    Expression<String>? id,
    Expression<String>? workspaceId,
    Expression<String>? jobId,
    Expression<String>? workerId,
    Expression<String>? decision,
    Expression<String>? reason,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (jobId != null) 'job_id': jobId,
      if (workerId != null) 'worker_id': workerId,
      if (decision != null) 'decision': decision,
      if (reason != null) 'reason': reason,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlacementLogTableCompanion copyWith({
    Value<String>? id,
    Value<String>? workspaceId,
    Value<String>? jobId,
    Value<String?>? workerId,
    Value<String>? decision,
    Value<String>? reason,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return PlacementLogTableCompanion(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      jobId: jobId ?? this.jobId,
      workerId: workerId ?? this.workerId,
      decision: decision ?? this.decision,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (jobId.present) {
      map['job_id'] = Variable<String>(jobId.value);
    }
    if (workerId.present) {
      map['worker_id'] = Variable<String>(workerId.value);
    }
    if (decision.present) {
      map['decision'] = Variable<String>(decision.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlacementLogTableCompanion(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('jobId: $jobId, ')
          ..write('workerId: $workerId, ')
          ..write('decision: $decision, ')
          ..write('reason: $reason, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkspaceRoutesTableTable extends WorkspaceRoutesTable
    with TableInfo<$WorkspaceRoutesTableTable, WorkspaceRoutesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkspaceRoutesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyHashMeta = const VerificationMeta(
    'keyHash',
  );
  @override
  late final GeneratedColumn<String> keyHash = GeneratedColumn<String>(
    'key_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [kind, keyHash, workspaceId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workspace_routes';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkspaceRoutesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('key_hash')) {
      context.handle(
        _keyHashMeta,
        keyHash.isAcceptableOrUnknown(data['key_hash']!, _keyHashMeta),
      );
    } else if (isInserting) {
      context.missing(_keyHashMeta);
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {kind, keyHash};
  @override
  WorkspaceRoutesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkspaceRoutesTableData(
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      keyHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key_hash'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $WorkspaceRoutesTableTable createAlias(String alias) {
    return $WorkspaceRoutesTableTable(attachedDatabase, alias);
  }
}

class WorkspaceRoutesTableData extends DataClass
    implements Insertable<WorkspaceRoutesTableData> {
  /// The kind of key being routed — see [WorkspaceRouteKind].
  final String kind;

  /// The key itself: a hash for secrets, the raw id for opaque ids. Never a
  /// plaintext secret.
  final String keyHash;

  /// The workspace that owns the keyed entity.
  final String workspaceId;

  /// When the route was recorded.
  final DateTime createdAt;
  const WorkspaceRoutesTableData({
    required this.kind,
    required this.keyHash,
    required this.workspaceId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['kind'] = Variable<String>(kind);
    map['key_hash'] = Variable<String>(keyHash);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  WorkspaceRoutesTableCompanion toCompanion(bool nullToAbsent) {
    return WorkspaceRoutesTableCompanion(
      kind: Value(kind),
      keyHash: Value(keyHash),
      workspaceId: Value(workspaceId),
      createdAt: Value(createdAt),
    );
  }

  factory WorkspaceRoutesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkspaceRoutesTableData(
      kind: serializer.fromJson<String>(json['kind']),
      keyHash: serializer.fromJson<String>(json['keyHash']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'kind': serializer.toJson<String>(kind),
      'keyHash': serializer.toJson<String>(keyHash),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  WorkspaceRoutesTableData copyWith({
    String? kind,
    String? keyHash,
    String? workspaceId,
    DateTime? createdAt,
  }) => WorkspaceRoutesTableData(
    kind: kind ?? this.kind,
    keyHash: keyHash ?? this.keyHash,
    workspaceId: workspaceId ?? this.workspaceId,
    createdAt: createdAt ?? this.createdAt,
  );
  WorkspaceRoutesTableData copyWithCompanion(
    WorkspaceRoutesTableCompanion data,
  ) {
    return WorkspaceRoutesTableData(
      kind: data.kind.present ? data.kind.value : this.kind,
      keyHash: data.keyHash.present ? data.keyHash.value : this.keyHash,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkspaceRoutesTableData(')
          ..write('kind: $kind, ')
          ..write('keyHash: $keyHash, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(kind, keyHash, workspaceId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkspaceRoutesTableData &&
          other.kind == this.kind &&
          other.keyHash == this.keyHash &&
          other.workspaceId == this.workspaceId &&
          other.createdAt == this.createdAt);
}

class WorkspaceRoutesTableCompanion
    extends UpdateCompanion<WorkspaceRoutesTableData> {
  final Value<String> kind;
  final Value<String> keyHash;
  final Value<String> workspaceId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const WorkspaceRoutesTableCompanion({
    this.kind = const Value.absent(),
    this.keyHash = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkspaceRoutesTableCompanion.insert({
    required String kind,
    required String keyHash,
    required String workspaceId,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : kind = Value(kind),
       keyHash = Value(keyHash),
       workspaceId = Value(workspaceId);
  static Insertable<WorkspaceRoutesTableData> custom({
    Expression<String>? kind,
    Expression<String>? keyHash,
    Expression<String>? workspaceId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (kind != null) 'kind': kind,
      if (keyHash != null) 'key_hash': keyHash,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkspaceRoutesTableCompanion copyWith({
    Value<String>? kind,
    Value<String>? keyHash,
    Value<String>? workspaceId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return WorkspaceRoutesTableCompanion(
      kind: kind ?? this.kind,
      keyHash: keyHash ?? this.keyHash,
      workspaceId: workspaceId ?? this.workspaceId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (keyHash.present) {
      map['key_hash'] = Variable<String>(keyHash.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkspaceRoutesTableCompanion(')
          ..write('kind: $kind, ')
          ..write('keyHash: $keyHash, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ServerMetaTableTable extends ServerMetaTable
    with TableInfo<$ServerMetaTableTable, ServerMetaTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ServerMetaTableTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'server_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<ServerMetaTableData> instance, {
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
  ServerMetaTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ServerMetaTableData(
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
  $ServerMetaTableTable createAlias(String alias) {
    return $ServerMetaTableTable(attachedDatabase, alias);
  }
}

class ServerMetaTableData extends DataClass
    implements Insertable<ServerMetaTableData> {
  /// Metadata key.
  final String key;

  /// Metadata value.
  final String value;
  const ServerMetaTableData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  ServerMetaTableCompanion toCompanion(bool nullToAbsent) {
    return ServerMetaTableCompanion(key: Value(key), value: Value(value));
  }

  factory ServerMetaTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ServerMetaTableData(
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

  ServerMetaTableData copyWith({String? key, String? value}) =>
      ServerMetaTableData(key: key ?? this.key, value: value ?? this.value);
  ServerMetaTableData copyWithCompanion(ServerMetaTableCompanion data) {
    return ServerMetaTableData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ServerMetaTableData(')
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
      (other is ServerMetaTableData &&
          other.key == this.key &&
          other.value == this.value);
}

class ServerMetaTableCompanion extends UpdateCompanion<ServerMetaTableData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const ServerMetaTableCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ServerMetaTableCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<ServerMetaTableData> custom({
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

  ServerMetaTableCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return ServerMetaTableCompanion(
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
    return (StringBuffer('ServerMetaTableCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ServerSettingsTableTable extends ServerSettingsTable
    with TableInfo<$ServerSettingsTableTable, ServerSettingsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ServerSettingsTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'server_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<ServerSettingsTableData> instance, {
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  ServerSettingsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ServerSettingsTableData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ServerSettingsTableTable createAlias(String alias) {
    return $ServerSettingsTableTable(attachedDatabase, alias);
  }
}

class ServerSettingsTableData extends DataClass
    implements Insertable<ServerSettingsTableData> {
  /// Setting key.
  final String key;

  /// Opaque setting value.
  final String value;

  /// When the value was last written.
  final DateTime updatedAt;
  const ServerSettingsTableData({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ServerSettingsTableCompanion toCompanion(bool nullToAbsent) {
    return ServerSettingsTableCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory ServerSettingsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ServerSettingsTableData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ServerSettingsTableData copyWith({
    String? key,
    String? value,
    DateTime? updatedAt,
  }) => ServerSettingsTableData(
    key: key ?? this.key,
    value: value ?? this.value,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ServerSettingsTableData copyWithCompanion(ServerSettingsTableCompanion data) {
    return ServerSettingsTableData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ServerSettingsTableData(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ServerSettingsTableData &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class ServerSettingsTableCompanion
    extends UpdateCompanion<ServerSettingsTableData> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ServerSettingsTableCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ServerSettingsTableCompanion.insert({
    required String key,
    required String value,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<ServerSettingsTableData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ServerSettingsTableCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ServerSettingsTableCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
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
    return (StringBuffer('ServerSettingsTableCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SsoConnectionsTableTable extends SsoConnectionsTable
    with TableInfo<$SsoConnectionsTableTable, SsoConnectionsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SsoConnectionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _issuerMeta = const VerificationMeta('issuer');
  @override
  late final GeneratedColumn<String> issuer = GeneratedColumn<String>(
    'issuer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _groupsClaimMeta = const VerificationMeta(
    'groupsClaim',
  );
  @override
  late final GeneratedColumn<String> groupsClaim = GeneratedColumn<String>(
    'groups_claim',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('groups'),
  );
  static const VerificationMeta _idpMetadataXmlMeta = const VerificationMeta(
    'idpMetadataXml',
  );
  @override
  late final GeneratedColumn<String> idpMetadataXml = GeneratedColumn<String>(
    'idp_metadata_xml',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _spEntityIdMeta = const VerificationMeta(
    'spEntityId',
  );
  @override
  late final GeneratedColumn<String> spEntityId = GeneratedColumn<String>(
    'sp_entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _emailAttributeMeta = const VerificationMeta(
    'emailAttribute',
  );
  @override
  late final GeneratedColumn<String> emailAttribute = GeneratedColumn<String>(
    'email_attribute',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('email'),
  );
  static const VerificationMeta _displayNameAttributeMeta =
      const VerificationMeta('displayNameAttribute');
  @override
  late final GeneratedColumn<String> displayNameAttribute =
      GeneratedColumn<String>(
        'display_name_attribute',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('displayName'),
      );
  static const VerificationMeta _groupsAttributeMeta = const VerificationMeta(
    'groupsAttribute',
  );
  @override
  late final GeneratedColumn<String> groupsAttribute = GeneratedColumn<String>(
    'groups_attribute',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('groups'),
  );
  static const VerificationMeta _defaultRoleMeta = const VerificationMeta(
    'defaultRole',
  );
  @override
  late final GeneratedColumn<String> defaultRole = GeneratedColumn<String>(
    'default_role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('member'),
  );
  static const VerificationMeta _groupRoleMapMeta = const VerificationMeta(
    'groupRoleMap',
  );
  @override
  late final GeneratedColumn<String> groupRoleMap = GeneratedColumn<String>(
    'group_role_map',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _autoMemberMeta = const VerificationMeta(
    'autoMember',
  );
  @override
  late final GeneratedColumn<bool> autoMember = GeneratedColumn<bool>(
    'auto_member',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_member" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _allowJitMeta = const VerificationMeta(
    'allowJit',
  );
  @override
  late final GeneratedColumn<bool> allowJit = GeneratedColumn<bool>(
    'allow_jit',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("allow_jit" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _allowIdpInitiatedMeta = const VerificationMeta(
    'allowIdpInitiated',
  );
  @override
  late final GeneratedColumn<bool> allowIdpInitiated = GeneratedColumn<bool>(
    'allow_idp_initiated',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("allow_idp_initiated" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _wantResponseSignedMeta =
      const VerificationMeta('wantResponseSigned');
  @override
  late final GeneratedColumn<bool> wantResponseSigned = GeneratedColumn<bool>(
    'want_response_signed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("want_response_signed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _clockSkewSecondsMeta = const VerificationMeta(
    'clockSkewSeconds',
  );
  @override
  late final GeneratedColumn<int> clockSkewSeconds = GeneratedColumn<int>(
    'clock_skew_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(90),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    enabled,
    issuer,
    clientId,
    groupsClaim,
    idpMetadataXml,
    spEntityId,
    emailAttribute,
    displayNameAttribute,
    groupsAttribute,
    defaultRole,
    groupRoleMap,
    autoMember,
    allowJit,
    allowIdpInitiated,
    wantResponseSigned,
    clockSkewSeconds,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sso_connections';
  @override
  VerificationContext validateIntegrity(
    Insertable<SsoConnectionsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('issuer')) {
      context.handle(
        _issuerMeta,
        issuer.isAcceptableOrUnknown(data['issuer']!, _issuerMeta),
      );
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    }
    if (data.containsKey('groups_claim')) {
      context.handle(
        _groupsClaimMeta,
        groupsClaim.isAcceptableOrUnknown(
          data['groups_claim']!,
          _groupsClaimMeta,
        ),
      );
    }
    if (data.containsKey('idp_metadata_xml')) {
      context.handle(
        _idpMetadataXmlMeta,
        idpMetadataXml.isAcceptableOrUnknown(
          data['idp_metadata_xml']!,
          _idpMetadataXmlMeta,
        ),
      );
    }
    if (data.containsKey('sp_entity_id')) {
      context.handle(
        _spEntityIdMeta,
        spEntityId.isAcceptableOrUnknown(
          data['sp_entity_id']!,
          _spEntityIdMeta,
        ),
      );
    }
    if (data.containsKey('email_attribute')) {
      context.handle(
        _emailAttributeMeta,
        emailAttribute.isAcceptableOrUnknown(
          data['email_attribute']!,
          _emailAttributeMeta,
        ),
      );
    }
    if (data.containsKey('display_name_attribute')) {
      context.handle(
        _displayNameAttributeMeta,
        displayNameAttribute.isAcceptableOrUnknown(
          data['display_name_attribute']!,
          _displayNameAttributeMeta,
        ),
      );
    }
    if (data.containsKey('groups_attribute')) {
      context.handle(
        _groupsAttributeMeta,
        groupsAttribute.isAcceptableOrUnknown(
          data['groups_attribute']!,
          _groupsAttributeMeta,
        ),
      );
    }
    if (data.containsKey('default_role')) {
      context.handle(
        _defaultRoleMeta,
        defaultRole.isAcceptableOrUnknown(
          data['default_role']!,
          _defaultRoleMeta,
        ),
      );
    }
    if (data.containsKey('group_role_map')) {
      context.handle(
        _groupRoleMapMeta,
        groupRoleMap.isAcceptableOrUnknown(
          data['group_role_map']!,
          _groupRoleMapMeta,
        ),
      );
    }
    if (data.containsKey('auto_member')) {
      context.handle(
        _autoMemberMeta,
        autoMember.isAcceptableOrUnknown(data['auto_member']!, _autoMemberMeta),
      );
    }
    if (data.containsKey('allow_jit')) {
      context.handle(
        _allowJitMeta,
        allowJit.isAcceptableOrUnknown(data['allow_jit']!, _allowJitMeta),
      );
    }
    if (data.containsKey('allow_idp_initiated')) {
      context.handle(
        _allowIdpInitiatedMeta,
        allowIdpInitiated.isAcceptableOrUnknown(
          data['allow_idp_initiated']!,
          _allowIdpInitiatedMeta,
        ),
      );
    }
    if (data.containsKey('want_response_signed')) {
      context.handle(
        _wantResponseSignedMeta,
        wantResponseSigned.isAcceptableOrUnknown(
          data['want_response_signed']!,
          _wantResponseSignedMeta,
        ),
      );
    }
    if (data.containsKey('clock_skew_seconds')) {
      context.handle(
        _clockSkewSecondsMeta,
        clockSkewSeconds.isAcceptableOrUnknown(
          data['clock_skew_seconds']!,
          _clockSkewSecondsMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SsoConnectionsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SsoConnectionsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      issuer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}issuer'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      )!,
      groupsClaim: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}groups_claim'],
      )!,
      idpMetadataXml: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idp_metadata_xml'],
      )!,
      spEntityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sp_entity_id'],
      )!,
      emailAttribute: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email_attribute'],
      )!,
      displayNameAttribute: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name_attribute'],
      )!,
      groupsAttribute: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}groups_attribute'],
      )!,
      defaultRole: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_role'],
      )!,
      groupRoleMap: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_role_map'],
      )!,
      autoMember: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_member'],
      )!,
      allowJit: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}allow_jit'],
      )!,
      allowIdpInitiated: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}allow_idp_initiated'],
      )!,
      wantResponseSigned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}want_response_signed'],
      )!,
      clockSkewSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}clock_skew_seconds'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SsoConnectionsTableTable createAlias(String alias) {
    return $SsoConnectionsTableTable(attachedDatabase, alias);
  }
}

class SsoConnectionsTableData extends DataClass
    implements Insertable<SsoConnectionsTableData> {
  /// Row id: the kind slug (`saml` / `oidc`).
  final String id;

  /// Protocol kind (`saml` / `oidc`).
  final String kind;

  /// Whether logins may use this connection.
  final bool enabled;

  /// OIDC issuer base URL.
  final String issuer;

  /// OIDC public-client id.
  final String clientId;

  /// OIDC claim carrying group names.
  final String groupsClaim;

  /// SAML IdP EntityDescriptor XML.
  final String idpMetadataXml;

  /// SAML our entityID; empty derives `<origin>/saml`.
  final String spEntityId;

  /// SAML attribute carrying the email.
  final String emailAttribute;

  /// SAML attribute carrying the display name.
  final String displayNameAttribute;

  /// SAML attribute carrying group names.
  final String groupsAttribute;

  /// Role granted when no group maps (WorkspaceRole wire name).
  final String defaultRole;

  /// Group value → role, as a JSON object of wire names.
  final String groupRoleMap;

  /// Whether SSO users are auto-added to workspace memberships (`all`/`none`).
  final bool autoMember;

  /// Whether unknown users may be provisioned at login.
  final bool allowJit;

  /// SAML: accept unsolicited (IdP-initiated) Responses.
  final bool allowIdpInitiated;

  /// SAML: require a Response-root signature too.
  final bool wantResponseSigned;

  /// SAML: validation clock skew, seconds.
  final int clockSkewSeconds;

  /// When this row was last saved.
  final DateTime updatedAt;
  const SsoConnectionsTableData({
    required this.id,
    required this.kind,
    required this.enabled,
    required this.issuer,
    required this.clientId,
    required this.groupsClaim,
    required this.idpMetadataXml,
    required this.spEntityId,
    required this.emailAttribute,
    required this.displayNameAttribute,
    required this.groupsAttribute,
    required this.defaultRole,
    required this.groupRoleMap,
    required this.autoMember,
    required this.allowJit,
    required this.allowIdpInitiated,
    required this.wantResponseSigned,
    required this.clockSkewSeconds,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['enabled'] = Variable<bool>(enabled);
    map['issuer'] = Variable<String>(issuer);
    map['client_id'] = Variable<String>(clientId);
    map['groups_claim'] = Variable<String>(groupsClaim);
    map['idp_metadata_xml'] = Variable<String>(idpMetadataXml);
    map['sp_entity_id'] = Variable<String>(spEntityId);
    map['email_attribute'] = Variable<String>(emailAttribute);
    map['display_name_attribute'] = Variable<String>(displayNameAttribute);
    map['groups_attribute'] = Variable<String>(groupsAttribute);
    map['default_role'] = Variable<String>(defaultRole);
    map['group_role_map'] = Variable<String>(groupRoleMap);
    map['auto_member'] = Variable<bool>(autoMember);
    map['allow_jit'] = Variable<bool>(allowJit);
    map['allow_idp_initiated'] = Variable<bool>(allowIdpInitiated);
    map['want_response_signed'] = Variable<bool>(wantResponseSigned);
    map['clock_skew_seconds'] = Variable<int>(clockSkewSeconds);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SsoConnectionsTableCompanion toCompanion(bool nullToAbsent) {
    return SsoConnectionsTableCompanion(
      id: Value(id),
      kind: Value(kind),
      enabled: Value(enabled),
      issuer: Value(issuer),
      clientId: Value(clientId),
      groupsClaim: Value(groupsClaim),
      idpMetadataXml: Value(idpMetadataXml),
      spEntityId: Value(spEntityId),
      emailAttribute: Value(emailAttribute),
      displayNameAttribute: Value(displayNameAttribute),
      groupsAttribute: Value(groupsAttribute),
      defaultRole: Value(defaultRole),
      groupRoleMap: Value(groupRoleMap),
      autoMember: Value(autoMember),
      allowJit: Value(allowJit),
      allowIdpInitiated: Value(allowIdpInitiated),
      wantResponseSigned: Value(wantResponseSigned),
      clockSkewSeconds: Value(clockSkewSeconds),
      updatedAt: Value(updatedAt),
    );
  }

  factory SsoConnectionsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SsoConnectionsTableData(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      issuer: serializer.fromJson<String>(json['issuer']),
      clientId: serializer.fromJson<String>(json['clientId']),
      groupsClaim: serializer.fromJson<String>(json['groupsClaim']),
      idpMetadataXml: serializer.fromJson<String>(json['idpMetadataXml']),
      spEntityId: serializer.fromJson<String>(json['spEntityId']),
      emailAttribute: serializer.fromJson<String>(json['emailAttribute']),
      displayNameAttribute: serializer.fromJson<String>(
        json['displayNameAttribute'],
      ),
      groupsAttribute: serializer.fromJson<String>(json['groupsAttribute']),
      defaultRole: serializer.fromJson<String>(json['defaultRole']),
      groupRoleMap: serializer.fromJson<String>(json['groupRoleMap']),
      autoMember: serializer.fromJson<bool>(json['autoMember']),
      allowJit: serializer.fromJson<bool>(json['allowJit']),
      allowIdpInitiated: serializer.fromJson<bool>(json['allowIdpInitiated']),
      wantResponseSigned: serializer.fromJson<bool>(json['wantResponseSigned']),
      clockSkewSeconds: serializer.fromJson<int>(json['clockSkewSeconds']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'enabled': serializer.toJson<bool>(enabled),
      'issuer': serializer.toJson<String>(issuer),
      'clientId': serializer.toJson<String>(clientId),
      'groupsClaim': serializer.toJson<String>(groupsClaim),
      'idpMetadataXml': serializer.toJson<String>(idpMetadataXml),
      'spEntityId': serializer.toJson<String>(spEntityId),
      'emailAttribute': serializer.toJson<String>(emailAttribute),
      'displayNameAttribute': serializer.toJson<String>(displayNameAttribute),
      'groupsAttribute': serializer.toJson<String>(groupsAttribute),
      'defaultRole': serializer.toJson<String>(defaultRole),
      'groupRoleMap': serializer.toJson<String>(groupRoleMap),
      'autoMember': serializer.toJson<bool>(autoMember),
      'allowJit': serializer.toJson<bool>(allowJit),
      'allowIdpInitiated': serializer.toJson<bool>(allowIdpInitiated),
      'wantResponseSigned': serializer.toJson<bool>(wantResponseSigned),
      'clockSkewSeconds': serializer.toJson<int>(clockSkewSeconds),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SsoConnectionsTableData copyWith({
    String? id,
    String? kind,
    bool? enabled,
    String? issuer,
    String? clientId,
    String? groupsClaim,
    String? idpMetadataXml,
    String? spEntityId,
    String? emailAttribute,
    String? displayNameAttribute,
    String? groupsAttribute,
    String? defaultRole,
    String? groupRoleMap,
    bool? autoMember,
    bool? allowJit,
    bool? allowIdpInitiated,
    bool? wantResponseSigned,
    int? clockSkewSeconds,
    DateTime? updatedAt,
  }) => SsoConnectionsTableData(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    enabled: enabled ?? this.enabled,
    issuer: issuer ?? this.issuer,
    clientId: clientId ?? this.clientId,
    groupsClaim: groupsClaim ?? this.groupsClaim,
    idpMetadataXml: idpMetadataXml ?? this.idpMetadataXml,
    spEntityId: spEntityId ?? this.spEntityId,
    emailAttribute: emailAttribute ?? this.emailAttribute,
    displayNameAttribute: displayNameAttribute ?? this.displayNameAttribute,
    groupsAttribute: groupsAttribute ?? this.groupsAttribute,
    defaultRole: defaultRole ?? this.defaultRole,
    groupRoleMap: groupRoleMap ?? this.groupRoleMap,
    autoMember: autoMember ?? this.autoMember,
    allowJit: allowJit ?? this.allowJit,
    allowIdpInitiated: allowIdpInitiated ?? this.allowIdpInitiated,
    wantResponseSigned: wantResponseSigned ?? this.wantResponseSigned,
    clockSkewSeconds: clockSkewSeconds ?? this.clockSkewSeconds,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SsoConnectionsTableData copyWithCompanion(SsoConnectionsTableCompanion data) {
    return SsoConnectionsTableData(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      issuer: data.issuer.present ? data.issuer.value : this.issuer,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      groupsClaim: data.groupsClaim.present
          ? data.groupsClaim.value
          : this.groupsClaim,
      idpMetadataXml: data.idpMetadataXml.present
          ? data.idpMetadataXml.value
          : this.idpMetadataXml,
      spEntityId: data.spEntityId.present
          ? data.spEntityId.value
          : this.spEntityId,
      emailAttribute: data.emailAttribute.present
          ? data.emailAttribute.value
          : this.emailAttribute,
      displayNameAttribute: data.displayNameAttribute.present
          ? data.displayNameAttribute.value
          : this.displayNameAttribute,
      groupsAttribute: data.groupsAttribute.present
          ? data.groupsAttribute.value
          : this.groupsAttribute,
      defaultRole: data.defaultRole.present
          ? data.defaultRole.value
          : this.defaultRole,
      groupRoleMap: data.groupRoleMap.present
          ? data.groupRoleMap.value
          : this.groupRoleMap,
      autoMember: data.autoMember.present
          ? data.autoMember.value
          : this.autoMember,
      allowJit: data.allowJit.present ? data.allowJit.value : this.allowJit,
      allowIdpInitiated: data.allowIdpInitiated.present
          ? data.allowIdpInitiated.value
          : this.allowIdpInitiated,
      wantResponseSigned: data.wantResponseSigned.present
          ? data.wantResponseSigned.value
          : this.wantResponseSigned,
      clockSkewSeconds: data.clockSkewSeconds.present
          ? data.clockSkewSeconds.value
          : this.clockSkewSeconds,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SsoConnectionsTableData(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('enabled: $enabled, ')
          ..write('issuer: $issuer, ')
          ..write('clientId: $clientId, ')
          ..write('groupsClaim: $groupsClaim, ')
          ..write('idpMetadataXml: $idpMetadataXml, ')
          ..write('spEntityId: $spEntityId, ')
          ..write('emailAttribute: $emailAttribute, ')
          ..write('displayNameAttribute: $displayNameAttribute, ')
          ..write('groupsAttribute: $groupsAttribute, ')
          ..write('defaultRole: $defaultRole, ')
          ..write('groupRoleMap: $groupRoleMap, ')
          ..write('autoMember: $autoMember, ')
          ..write('allowJit: $allowJit, ')
          ..write('allowIdpInitiated: $allowIdpInitiated, ')
          ..write('wantResponseSigned: $wantResponseSigned, ')
          ..write('clockSkewSeconds: $clockSkewSeconds, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    enabled,
    issuer,
    clientId,
    groupsClaim,
    idpMetadataXml,
    spEntityId,
    emailAttribute,
    displayNameAttribute,
    groupsAttribute,
    defaultRole,
    groupRoleMap,
    autoMember,
    allowJit,
    allowIdpInitiated,
    wantResponseSigned,
    clockSkewSeconds,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SsoConnectionsTableData &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.enabled == this.enabled &&
          other.issuer == this.issuer &&
          other.clientId == this.clientId &&
          other.groupsClaim == this.groupsClaim &&
          other.idpMetadataXml == this.idpMetadataXml &&
          other.spEntityId == this.spEntityId &&
          other.emailAttribute == this.emailAttribute &&
          other.displayNameAttribute == this.displayNameAttribute &&
          other.groupsAttribute == this.groupsAttribute &&
          other.defaultRole == this.defaultRole &&
          other.groupRoleMap == this.groupRoleMap &&
          other.autoMember == this.autoMember &&
          other.allowJit == this.allowJit &&
          other.allowIdpInitiated == this.allowIdpInitiated &&
          other.wantResponseSigned == this.wantResponseSigned &&
          other.clockSkewSeconds == this.clockSkewSeconds &&
          other.updatedAt == this.updatedAt);
}

class SsoConnectionsTableCompanion
    extends UpdateCompanion<SsoConnectionsTableData> {
  final Value<String> id;
  final Value<String> kind;
  final Value<bool> enabled;
  final Value<String> issuer;
  final Value<String> clientId;
  final Value<String> groupsClaim;
  final Value<String> idpMetadataXml;
  final Value<String> spEntityId;
  final Value<String> emailAttribute;
  final Value<String> displayNameAttribute;
  final Value<String> groupsAttribute;
  final Value<String> defaultRole;
  final Value<String> groupRoleMap;
  final Value<bool> autoMember;
  final Value<bool> allowJit;
  final Value<bool> allowIdpInitiated;
  final Value<bool> wantResponseSigned;
  final Value<int> clockSkewSeconds;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SsoConnectionsTableCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.enabled = const Value.absent(),
    this.issuer = const Value.absent(),
    this.clientId = const Value.absent(),
    this.groupsClaim = const Value.absent(),
    this.idpMetadataXml = const Value.absent(),
    this.spEntityId = const Value.absent(),
    this.emailAttribute = const Value.absent(),
    this.displayNameAttribute = const Value.absent(),
    this.groupsAttribute = const Value.absent(),
    this.defaultRole = const Value.absent(),
    this.groupRoleMap = const Value.absent(),
    this.autoMember = const Value.absent(),
    this.allowJit = const Value.absent(),
    this.allowIdpInitiated = const Value.absent(),
    this.wantResponseSigned = const Value.absent(),
    this.clockSkewSeconds = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SsoConnectionsTableCompanion.insert({
    required String id,
    required String kind,
    this.enabled = const Value.absent(),
    this.issuer = const Value.absent(),
    this.clientId = const Value.absent(),
    this.groupsClaim = const Value.absent(),
    this.idpMetadataXml = const Value.absent(),
    this.spEntityId = const Value.absent(),
    this.emailAttribute = const Value.absent(),
    this.displayNameAttribute = const Value.absent(),
    this.groupsAttribute = const Value.absent(),
    this.defaultRole = const Value.absent(),
    this.groupRoleMap = const Value.absent(),
    this.autoMember = const Value.absent(),
    this.allowJit = const Value.absent(),
    this.allowIdpInitiated = const Value.absent(),
    this.wantResponseSigned = const Value.absent(),
    this.clockSkewSeconds = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind);
  static Insertable<SsoConnectionsTableData> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<bool>? enabled,
    Expression<String>? issuer,
    Expression<String>? clientId,
    Expression<String>? groupsClaim,
    Expression<String>? idpMetadataXml,
    Expression<String>? spEntityId,
    Expression<String>? emailAttribute,
    Expression<String>? displayNameAttribute,
    Expression<String>? groupsAttribute,
    Expression<String>? defaultRole,
    Expression<String>? groupRoleMap,
    Expression<bool>? autoMember,
    Expression<bool>? allowJit,
    Expression<bool>? allowIdpInitiated,
    Expression<bool>? wantResponseSigned,
    Expression<int>? clockSkewSeconds,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (enabled != null) 'enabled': enabled,
      if (issuer != null) 'issuer': issuer,
      if (clientId != null) 'client_id': clientId,
      if (groupsClaim != null) 'groups_claim': groupsClaim,
      if (idpMetadataXml != null) 'idp_metadata_xml': idpMetadataXml,
      if (spEntityId != null) 'sp_entity_id': spEntityId,
      if (emailAttribute != null) 'email_attribute': emailAttribute,
      if (displayNameAttribute != null)
        'display_name_attribute': displayNameAttribute,
      if (groupsAttribute != null) 'groups_attribute': groupsAttribute,
      if (defaultRole != null) 'default_role': defaultRole,
      if (groupRoleMap != null) 'group_role_map': groupRoleMap,
      if (autoMember != null) 'auto_member': autoMember,
      if (allowJit != null) 'allow_jit': allowJit,
      if (allowIdpInitiated != null) 'allow_idp_initiated': allowIdpInitiated,
      if (wantResponseSigned != null)
        'want_response_signed': wantResponseSigned,
      if (clockSkewSeconds != null) 'clock_skew_seconds': clockSkewSeconds,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SsoConnectionsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? kind,
    Value<bool>? enabled,
    Value<String>? issuer,
    Value<String>? clientId,
    Value<String>? groupsClaim,
    Value<String>? idpMetadataXml,
    Value<String>? spEntityId,
    Value<String>? emailAttribute,
    Value<String>? displayNameAttribute,
    Value<String>? groupsAttribute,
    Value<String>? defaultRole,
    Value<String>? groupRoleMap,
    Value<bool>? autoMember,
    Value<bool>? allowJit,
    Value<bool>? allowIdpInitiated,
    Value<bool>? wantResponseSigned,
    Value<int>? clockSkewSeconds,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SsoConnectionsTableCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      enabled: enabled ?? this.enabled,
      issuer: issuer ?? this.issuer,
      clientId: clientId ?? this.clientId,
      groupsClaim: groupsClaim ?? this.groupsClaim,
      idpMetadataXml: idpMetadataXml ?? this.idpMetadataXml,
      spEntityId: spEntityId ?? this.spEntityId,
      emailAttribute: emailAttribute ?? this.emailAttribute,
      displayNameAttribute: displayNameAttribute ?? this.displayNameAttribute,
      groupsAttribute: groupsAttribute ?? this.groupsAttribute,
      defaultRole: defaultRole ?? this.defaultRole,
      groupRoleMap: groupRoleMap ?? this.groupRoleMap,
      autoMember: autoMember ?? this.autoMember,
      allowJit: allowJit ?? this.allowJit,
      allowIdpInitiated: allowIdpInitiated ?? this.allowIdpInitiated,
      wantResponseSigned: wantResponseSigned ?? this.wantResponseSigned,
      clockSkewSeconds: clockSkewSeconds ?? this.clockSkewSeconds,
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
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (issuer.present) {
      map['issuer'] = Variable<String>(issuer.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (groupsClaim.present) {
      map['groups_claim'] = Variable<String>(groupsClaim.value);
    }
    if (idpMetadataXml.present) {
      map['idp_metadata_xml'] = Variable<String>(idpMetadataXml.value);
    }
    if (spEntityId.present) {
      map['sp_entity_id'] = Variable<String>(spEntityId.value);
    }
    if (emailAttribute.present) {
      map['email_attribute'] = Variable<String>(emailAttribute.value);
    }
    if (displayNameAttribute.present) {
      map['display_name_attribute'] = Variable<String>(
        displayNameAttribute.value,
      );
    }
    if (groupsAttribute.present) {
      map['groups_attribute'] = Variable<String>(groupsAttribute.value);
    }
    if (defaultRole.present) {
      map['default_role'] = Variable<String>(defaultRole.value);
    }
    if (groupRoleMap.present) {
      map['group_role_map'] = Variable<String>(groupRoleMap.value);
    }
    if (autoMember.present) {
      map['auto_member'] = Variable<bool>(autoMember.value);
    }
    if (allowJit.present) {
      map['allow_jit'] = Variable<bool>(allowJit.value);
    }
    if (allowIdpInitiated.present) {
      map['allow_idp_initiated'] = Variable<bool>(allowIdpInitiated.value);
    }
    if (wantResponseSigned.present) {
      map['want_response_signed'] = Variable<bool>(wantResponseSigned.value);
    }
    if (clockSkewSeconds.present) {
      map['clock_skew_seconds'] = Variable<int>(clockSkewSeconds.value);
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
    return (StringBuffer('SsoConnectionsTableCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('enabled: $enabled, ')
          ..write('issuer: $issuer, ')
          ..write('clientId: $clientId, ')
          ..write('groupsClaim: $groupsClaim, ')
          ..write('idpMetadataXml: $idpMetadataXml, ')
          ..write('spEntityId: $spEntityId, ')
          ..write('emailAttribute: $emailAttribute, ')
          ..write('displayNameAttribute: $displayNameAttribute, ')
          ..write('groupsAttribute: $groupsAttribute, ')
          ..write('defaultRole: $defaultRole, ')
          ..write('groupRoleMap: $groupRoleMap, ')
          ..write('autoMember: $autoMember, ')
          ..write('allowJit: $allowJit, ')
          ..write('allowIdpInitiated: $allowIdpInitiated, ')
          ..write('wantResponseSigned: $wantResponseSigned, ')
          ..write('clockSkewSeconds: $clockSkewSeconds, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$GlobalDatabase extends GeneratedDatabase {
  _$GlobalDatabase(QueryExecutor e) : super(e);
  $GlobalDatabaseManager get managers => $GlobalDatabaseManager(this);
  late final $WorkspacesTableTable workspacesTable = $WorkspacesTableTable(
    this,
  );
  late final $UsersTableTable usersTable = $UsersTableTable(this);
  late final $UserPreferencesTableTable userPreferencesTable =
      $UserPreferencesTableTable(this);
  late final $PairedDevicesTableTable pairedDevicesTable =
      $PairedDevicesTableTable(this);
  late final $RssFeedsTableTable rssFeedsTable = $RssFeedsTableTable(this);
  late final $RssArticlesTableTable rssArticlesTable = $RssArticlesTableTable(
    this,
  );
  late final $WorkersTableTable workersTable = $WorkersTableTable(this);
  late final $JobsTableTable jobsTable = $JobsTableTable(this);
  late final $PlacementLogTableTable placementLogTable =
      $PlacementLogTableTable(this);
  late final $WorkspaceRoutesTableTable workspaceRoutesTable =
      $WorkspaceRoutesTableTable(this);
  late final $ServerMetaTableTable serverMetaTable = $ServerMetaTableTable(
    this,
  );
  late final $ServerSettingsTableTable serverSettingsTable =
      $ServerSettingsTableTable(this);
  late final $SsoConnectionsTableTable ssoConnectionsTable =
      $SsoConnectionsTableTable(this);
  late final Index idxUsersHandle = Index(
    'idx_users_handle',
    'CREATE UNIQUE INDEX idx_users_handle ON users (handle)',
  );
  late final Index idxRssArticlesFeedIdGuid = Index(
    'idx_rss_articles_feedId_guid',
    'CREATE UNIQUE INDEX idx_rss_articles_feedId_guid ON rss_articles (feed_id, guid)',
  );
  late final Index idxWorkersStatus = Index(
    'idx_workers_status',
    'CREATE INDEX idx_workers_status ON workers (status)',
  );
  late final Index idxJobsWorkspaceStatus = Index(
    'idx_jobs_workspace_status',
    'CREATE INDEX idx_jobs_workspace_status ON jobs (workspace_id, status)',
  );
  late final Index idxJobsWorkerStatus = Index(
    'idx_jobs_worker_status',
    'CREATE INDEX idx_jobs_worker_status ON jobs (worker_id, status)',
  );
  late final Index idxJobsLeaseExpiry = Index(
    'idx_jobs_lease_expiry',
    'CREATE INDEX idx_jobs_lease_expiry ON jobs (lease_expires_at)',
  );
  late final Index idxPlacementLogJob = Index(
    'idx_placement_log_job',
    'CREATE INDEX idx_placement_log_job ON placement_log (job_id)',
  );
  late final Index idxPlacementLogWorkspace = Index(
    'idx_placement_log_workspace',
    'CREATE INDEX idx_placement_log_workspace ON placement_log (workspace_id)',
  );
  late final WorkspaceRegistryDao workspaceRegistryDao = WorkspaceRegistryDao(
    this as GlobalDatabase,
  );
  late final UserDao userDao = UserDao(this as GlobalDatabase);
  late final UserPreferenceDao userPreferenceDao = UserPreferenceDao(
    this as GlobalDatabase,
  );
  late final PairedDeviceDao pairedDeviceDao = PairedDeviceDao(
    this as GlobalDatabase,
  );
  late final RssDao rssDao = RssDao(this as GlobalDatabase);
  late final FleetDao fleetDao = FleetDao(this as GlobalDatabase);
  late final WorkspaceRouteDao workspaceRouteDao = WorkspaceRouteDao(
    this as GlobalDatabase,
  );
  late final ServerSettingDao serverSettingDao = ServerSettingDao(
    this as GlobalDatabase,
  );
  late final SsoConnectionDao ssoConnectionDao = SsoConnectionDao(
    this as GlobalDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    workspacesTable,
    usersTable,
    userPreferencesTable,
    pairedDevicesTable,
    rssFeedsTable,
    rssArticlesTable,
    workersTable,
    jobsTable,
    placementLogTable,
    workspaceRoutesTable,
    serverMetaTable,
    serverSettingsTable,
    ssoConnectionsTable,
    idxUsersHandle,
    idxRssArticlesFeedIdGuid,
    idxWorkersStatus,
    idxJobsWorkspaceStatus,
    idxJobsWorkerStatus,
    idxJobsLeaseExpiry,
    idxPlacementLogJob,
    idxPlacementLogWorkspace,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('user_preferences', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('rss_feeds', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'rss_feeds',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('rss_articles', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$WorkspacesTableTableCreateCompanionBuilder =
    WorkspacesTableCompanion Function({
      required String id,
      required String name,
      Value<String?> logoPath,
      Value<String?> ownerUserId,
      Value<String> secretExcludeGlobs,
      Value<int> reviewConcurrency,
      Value<bool> autoPublishReview,
      Value<int> position,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$WorkspacesTableTableUpdateCompanionBuilder =
    WorkspacesTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> logoPath,
      Value<String?> ownerUserId,
      Value<String> secretExcludeGlobs,
      Value<int> reviewConcurrency,
      Value<bool> autoPublishReview,
      Value<int> position,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$WorkspacesTableTableFilterComposer
    extends Composer<_$GlobalDatabase, $WorkspacesTableTable> {
  $$WorkspacesTableTableFilterComposer({
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

  ColumnFilters<String> get logoPath => $composableBuilder(
    column: $table.logoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerUserId => $composableBuilder(
    column: $table.ownerUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get secretExcludeGlobs => $composableBuilder(
    column: $table.secretExcludeGlobs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reviewConcurrency => $composableBuilder(
    column: $table.reviewConcurrency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoPublishReview => $composableBuilder(
    column: $table.autoPublishReview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
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

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorkspacesTableTableOrderingComposer
    extends Composer<_$GlobalDatabase, $WorkspacesTableTable> {
  $$WorkspacesTableTableOrderingComposer({
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

  ColumnOrderings<String> get logoPath => $composableBuilder(
    column: $table.logoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerUserId => $composableBuilder(
    column: $table.ownerUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get secretExcludeGlobs => $composableBuilder(
    column: $table.secretExcludeGlobs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reviewConcurrency => $composableBuilder(
    column: $table.reviewConcurrency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoPublishReview => $composableBuilder(
    column: $table.autoPublishReview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
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

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkspacesTableTableAnnotationComposer
    extends Composer<_$GlobalDatabase, $WorkspacesTableTable> {
  $$WorkspacesTableTableAnnotationComposer({
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

  GeneratedColumn<String> get logoPath =>
      $composableBuilder(column: $table.logoPath, builder: (column) => column);

  GeneratedColumn<String> get ownerUserId => $composableBuilder(
    column: $table.ownerUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get secretExcludeGlobs => $composableBuilder(
    column: $table.secretExcludeGlobs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reviewConcurrency => $composableBuilder(
    column: $table.reviewConcurrency,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get autoPublishReview => $composableBuilder(
    column: $table.autoPublishReview,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$WorkspacesTableTableTableManager
    extends
        RootTableManager<
          _$GlobalDatabase,
          $WorkspacesTableTable,
          WorkspacesTableData,
          $$WorkspacesTableTableFilterComposer,
          $$WorkspacesTableTableOrderingComposer,
          $$WorkspacesTableTableAnnotationComposer,
          $$WorkspacesTableTableCreateCompanionBuilder,
          $$WorkspacesTableTableUpdateCompanionBuilder,
          (
            WorkspacesTableData,
            BaseReferences<
              _$GlobalDatabase,
              $WorkspacesTableTable,
              WorkspacesTableData
            >,
          ),
          WorkspacesTableData,
          PrefetchHooks Function()
        > {
  $$WorkspacesTableTableTableManager(
    _$GlobalDatabase db,
    $WorkspacesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkspacesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkspacesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkspacesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> logoPath = const Value.absent(),
                Value<String?> ownerUserId = const Value.absent(),
                Value<String> secretExcludeGlobs = const Value.absent(),
                Value<int> reviewConcurrency = const Value.absent(),
                Value<bool> autoPublishReview = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkspacesTableCompanion(
                id: id,
                name: name,
                logoPath: logoPath,
                ownerUserId: ownerUserId,
                secretExcludeGlobs: secretExcludeGlobs,
                reviewConcurrency: reviewConcurrency,
                autoPublishReview: autoPublishReview,
                position: position,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> logoPath = const Value.absent(),
                Value<String?> ownerUserId = const Value.absent(),
                Value<String> secretExcludeGlobs = const Value.absent(),
                Value<int> reviewConcurrency = const Value.absent(),
                Value<bool> autoPublishReview = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkspacesTableCompanion.insert(
                id: id,
                name: name,
                logoPath: logoPath,
                ownerUserId: ownerUserId,
                secretExcludeGlobs: secretExcludeGlobs,
                reviewConcurrency: reviewConcurrency,
                autoPublishReview: autoPublishReview,
                position: position,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorkspacesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$GlobalDatabase,
      $WorkspacesTableTable,
      WorkspacesTableData,
      $$WorkspacesTableTableFilterComposer,
      $$WorkspacesTableTableOrderingComposer,
      $$WorkspacesTableTableAnnotationComposer,
      $$WorkspacesTableTableCreateCompanionBuilder,
      $$WorkspacesTableTableUpdateCompanionBuilder,
      (
        WorkspacesTableData,
        BaseReferences<
          _$GlobalDatabase,
          $WorkspacesTableTable,
          WorkspacesTableData
        >,
      ),
      WorkspacesTableData,
      PrefetchHooks Function()
    >;
typedef $$UsersTableTableCreateCompanionBuilder =
    UsersTableCompanion Function({
      required String id,
      required String handle,
      required String displayName,
      Value<String?> email,
      Value<String?> avatarRef,
      Value<String?> gitAuthorName,
      Value<String?> gitAuthorEmail,
      Value<String?> ssoSubject,
      Value<String?> ssoIssuer,
      Value<DateTime?> deactivatedAt,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$UsersTableTableUpdateCompanionBuilder =
    UsersTableCompanion Function({
      Value<String> id,
      Value<String> handle,
      Value<String> displayName,
      Value<String?> email,
      Value<String?> avatarRef,
      Value<String?> gitAuthorName,
      Value<String?> gitAuthorEmail,
      Value<String?> ssoSubject,
      Value<String?> ssoIssuer,
      Value<DateTime?> deactivatedAt,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$UsersTableTableReferences
    extends BaseReferences<_$GlobalDatabase, $UsersTableTable, UsersTableData> {
  $$UsersTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $UserPreferencesTableTable,
    List<UserPreferencesTableData>
  >
  _userPreferencesTableRefsTable(_$GlobalDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.userPreferencesTable,
        aliasName: 'users__id__user_preferences__user_id',
      );

  $$UserPreferencesTableTableProcessedTableManager
  get userPreferencesTableRefs {
    final manager = $$UserPreferencesTableTableTableManager(
      $_db,
      $_db.userPreferencesTable,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _userPreferencesTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RssFeedsTableTable, List<RssFeedsTableData>>
  _rssFeedsTableRefsTable(_$GlobalDatabase db) => MultiTypedResultKey.fromTable(
    db.rssFeedsTable,
    aliasName: 'users__id__rss_feeds__user_id',
  );

  $$RssFeedsTableTableProcessedTableManager get rssFeedsTableRefs {
    final manager = $$RssFeedsTableTableTableManager(
      $_db,
      $_db.rssFeedsTable,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_rssFeedsTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$UsersTableTableFilterComposer
    extends Composer<_$GlobalDatabase, $UsersTableTable> {
  $$UsersTableTableFilterComposer({
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

  ColumnFilters<String> get handle => $composableBuilder(
    column: $table.handle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarRef => $composableBuilder(
    column: $table.avatarRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gitAuthorName => $composableBuilder(
    column: $table.gitAuthorName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gitAuthorEmail => $composableBuilder(
    column: $table.gitAuthorEmail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ssoSubject => $composableBuilder(
    column: $table.ssoSubject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ssoIssuer => $composableBuilder(
    column: $table.ssoIssuer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deactivatedAt => $composableBuilder(
    column: $table.deactivatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> userPreferencesTableRefs(
    Expression<bool> Function($$UserPreferencesTableTableFilterComposer f) f,
  ) {
    final $$UserPreferencesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userPreferencesTable,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserPreferencesTableTableFilterComposer(
            $db: $db,
            $table: $db.userPreferencesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> rssFeedsTableRefs(
    Expression<bool> Function($$RssFeedsTableTableFilterComposer f) f,
  ) {
    final $$RssFeedsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rssFeedsTable,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RssFeedsTableTableFilterComposer(
            $db: $db,
            $table: $db.rssFeedsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UsersTableTableOrderingComposer
    extends Composer<_$GlobalDatabase, $UsersTableTable> {
  $$UsersTableTableOrderingComposer({
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

  ColumnOrderings<String> get handle => $composableBuilder(
    column: $table.handle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarRef => $composableBuilder(
    column: $table.avatarRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gitAuthorName => $composableBuilder(
    column: $table.gitAuthorName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gitAuthorEmail => $composableBuilder(
    column: $table.gitAuthorEmail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ssoSubject => $composableBuilder(
    column: $table.ssoSubject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ssoIssuer => $composableBuilder(
    column: $table.ssoIssuer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deactivatedAt => $composableBuilder(
    column: $table.deactivatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsersTableTableAnnotationComposer
    extends Composer<_$GlobalDatabase, $UsersTableTable> {
  $$UsersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get handle =>
      $composableBuilder(column: $table.handle, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get avatarRef =>
      $composableBuilder(column: $table.avatarRef, builder: (column) => column);

  GeneratedColumn<String> get gitAuthorName => $composableBuilder(
    column: $table.gitAuthorName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get gitAuthorEmail => $composableBuilder(
    column: $table.gitAuthorEmail,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ssoSubject => $composableBuilder(
    column: $table.ssoSubject,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ssoIssuer =>
      $composableBuilder(column: $table.ssoIssuer, builder: (column) => column);

  GeneratedColumn<DateTime> get deactivatedAt => $composableBuilder(
    column: $table.deactivatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> userPreferencesTableRefs<T extends Object>(
    Expression<T> Function($$UserPreferencesTableTableAnnotationComposer a) f,
  ) {
    final $$UserPreferencesTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.userPreferencesTable,
          getReferencedColumn: (t) => t.userId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$UserPreferencesTableTableAnnotationComposer(
                $db: $db,
                $table: $db.userPreferencesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> rssFeedsTableRefs<T extends Object>(
    Expression<T> Function($$RssFeedsTableTableAnnotationComposer a) f,
  ) {
    final $$RssFeedsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rssFeedsTable,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RssFeedsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.rssFeedsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UsersTableTableTableManager
    extends
        RootTableManager<
          _$GlobalDatabase,
          $UsersTableTable,
          UsersTableData,
          $$UsersTableTableFilterComposer,
          $$UsersTableTableOrderingComposer,
          $$UsersTableTableAnnotationComposer,
          $$UsersTableTableCreateCompanionBuilder,
          $$UsersTableTableUpdateCompanionBuilder,
          (UsersTableData, $$UsersTableTableReferences),
          UsersTableData,
          PrefetchHooks Function({
            bool userPreferencesTableRefs,
            bool rssFeedsTableRefs,
          })
        > {
  $$UsersTableTableTableManager(_$GlobalDatabase db, $UsersTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> handle = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> avatarRef = const Value.absent(),
                Value<String?> gitAuthorName = const Value.absent(),
                Value<String?> gitAuthorEmail = const Value.absent(),
                Value<String?> ssoSubject = const Value.absent(),
                Value<String?> ssoIssuer = const Value.absent(),
                Value<DateTime?> deactivatedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersTableCompanion(
                id: id,
                handle: handle,
                displayName: displayName,
                email: email,
                avatarRef: avatarRef,
                gitAuthorName: gitAuthorName,
                gitAuthorEmail: gitAuthorEmail,
                ssoSubject: ssoSubject,
                ssoIssuer: ssoIssuer,
                deactivatedAt: deactivatedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String handle,
                required String displayName,
                Value<String?> email = const Value.absent(),
                Value<String?> avatarRef = const Value.absent(),
                Value<String?> gitAuthorName = const Value.absent(),
                Value<String?> gitAuthorEmail = const Value.absent(),
                Value<String?> ssoSubject = const Value.absent(),
                Value<String?> ssoIssuer = const Value.absent(),
                Value<DateTime?> deactivatedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersTableCompanion.insert(
                id: id,
                handle: handle,
                displayName: displayName,
                email: email,
                avatarRef: avatarRef,
                gitAuthorName: gitAuthorName,
                gitAuthorEmail: gitAuthorEmail,
                ssoSubject: ssoSubject,
                ssoIssuer: ssoIssuer,
                deactivatedAt: deactivatedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$UsersTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({userPreferencesTableRefs = false, rssFeedsTableRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (userPreferencesTableRefs) db.userPreferencesTable,
                    if (rssFeedsTableRefs) db.rssFeedsTable,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (userPreferencesTableRefs)
                        await $_getPrefetchedData<
                          UsersTableData,
                          $UsersTableTable,
                          UserPreferencesTableData
                        >(
                          currentTable: table,
                          referencedTable: $$UsersTableTableReferences
                              ._userPreferencesTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableTableReferences(
                                db,
                                table,
                                p0,
                              ).userPreferencesTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.userId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (rssFeedsTableRefs)
                        await $_getPrefetchedData<
                          UsersTableData,
                          $UsersTableTable,
                          RssFeedsTableData
                        >(
                          currentTable: table,
                          referencedTable: $$UsersTableTableReferences
                              ._rssFeedsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableTableReferences(
                                db,
                                table,
                                p0,
                              ).rssFeedsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.userId == item.id,
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

typedef $$UsersTableTableProcessedTableManager =
    ProcessedTableManager<
      _$GlobalDatabase,
      $UsersTableTable,
      UsersTableData,
      $$UsersTableTableFilterComposer,
      $$UsersTableTableOrderingComposer,
      $$UsersTableTableAnnotationComposer,
      $$UsersTableTableCreateCompanionBuilder,
      $$UsersTableTableUpdateCompanionBuilder,
      (UsersTableData, $$UsersTableTableReferences),
      UsersTableData,
      PrefetchHooks Function({
        bool userPreferencesTableRefs,
        bool rssFeedsTableRefs,
      })
    >;
typedef $$UserPreferencesTableTableCreateCompanionBuilder =
    UserPreferencesTableCompanion Function({
      required String userId,
      required String key,
      required String value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$UserPreferencesTableTableUpdateCompanionBuilder =
    UserPreferencesTableCompanion Function({
      Value<String> userId,
      Value<String> key,
      Value<String> value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$UserPreferencesTableTableReferences
    extends
        BaseReferences<
          _$GlobalDatabase,
          $UserPreferencesTableTable,
          UserPreferencesTableData
        > {
  $$UserPreferencesTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $UsersTableTable _userIdTable(_$GlobalDatabase db) =>
      db.usersTable.createAlias('user_preferences__user_id__users__id');

  $$UsersTableTableProcessedTableManager get userId {
    final $_column = $_itemColumn<String>('user_id')!;

    final manager = $$UsersTableTableTableManager(
      $_db,
      $_db.usersTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$UserPreferencesTableTableFilterComposer
    extends Composer<_$GlobalDatabase, $UserPreferencesTableTable> {
  $$UserPreferencesTableTableFilterComposer({
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

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$UsersTableTableFilterComposer get userId {
    final $$UsersTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.usersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableTableFilterComposer(
            $db: $db,
            $table: $db.usersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserPreferencesTableTableOrderingComposer
    extends Composer<_$GlobalDatabase, $UserPreferencesTableTable> {
  $$UserPreferencesTableTableOrderingComposer({
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

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$UsersTableTableOrderingComposer get userId {
    final $$UsersTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.usersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableTableOrderingComposer(
            $db: $db,
            $table: $db.usersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserPreferencesTableTableAnnotationComposer
    extends Composer<_$GlobalDatabase, $UserPreferencesTableTable> {
  $$UserPreferencesTableTableAnnotationComposer({
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

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$UsersTableTableAnnotationComposer get userId {
    final $$UsersTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.usersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableTableAnnotationComposer(
            $db: $db,
            $table: $db.usersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserPreferencesTableTableTableManager
    extends
        RootTableManager<
          _$GlobalDatabase,
          $UserPreferencesTableTable,
          UserPreferencesTableData,
          $$UserPreferencesTableTableFilterComposer,
          $$UserPreferencesTableTableOrderingComposer,
          $$UserPreferencesTableTableAnnotationComposer,
          $$UserPreferencesTableTableCreateCompanionBuilder,
          $$UserPreferencesTableTableUpdateCompanionBuilder,
          (UserPreferencesTableData, $$UserPreferencesTableTableReferences),
          UserPreferencesTableData,
          PrefetchHooks Function({bool userId})
        > {
  $$UserPreferencesTableTableTableManager(
    _$GlobalDatabase db,
    $UserPreferencesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserPreferencesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserPreferencesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$UserPreferencesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserPreferencesTableCompanion(
                userId: userId,
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                required String key,
                required String value,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserPreferencesTableCompanion.insert(
                userId: userId,
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$UserPreferencesTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({userId = false}) {
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
                    if (userId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.userId,
                                referencedTable:
                                    $$UserPreferencesTableTableReferences
                                        ._userIdTable(db),
                                referencedColumn:
                                    $$UserPreferencesTableTableReferences
                                        ._userIdTable(db)
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

typedef $$UserPreferencesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$GlobalDatabase,
      $UserPreferencesTableTable,
      UserPreferencesTableData,
      $$UserPreferencesTableTableFilterComposer,
      $$UserPreferencesTableTableOrderingComposer,
      $$UserPreferencesTableTableAnnotationComposer,
      $$UserPreferencesTableTableCreateCompanionBuilder,
      $$UserPreferencesTableTableUpdateCompanionBuilder,
      (UserPreferencesTableData, $$UserPreferencesTableTableReferences),
      UserPreferencesTableData,
      PrefetchHooks Function({bool userId})
    >;
typedef $$PairedDevicesTableTableCreateCompanionBuilder =
    PairedDevicesTableCompanion Function({
      required String id,
      Value<String?> userId,
      Value<String?> workspaceId,
      required String label,
      Value<String> platform,
      required String pskRef,
      Value<String?> remoteFingerprint,
      Value<String> status,
      Value<DateTime> pairedAt,
      Value<DateTime?> lastSeenAt,
      Value<DateTime?> expiresAt,
      Value<int> rowid,
    });
typedef $$PairedDevicesTableTableUpdateCompanionBuilder =
    PairedDevicesTableCompanion Function({
      Value<String> id,
      Value<String?> userId,
      Value<String?> workspaceId,
      Value<String> label,
      Value<String> platform,
      Value<String> pskRef,
      Value<String?> remoteFingerprint,
      Value<String> status,
      Value<DateTime> pairedAt,
      Value<DateTime?> lastSeenAt,
      Value<DateTime?> expiresAt,
      Value<int> rowid,
    });

class $$PairedDevicesTableTableFilterComposer
    extends Composer<_$GlobalDatabase, $PairedDevicesTableTable> {
  $$PairedDevicesTableTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pskRef => $composableBuilder(
    column: $table.pskRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteFingerprint => $composableBuilder(
    column: $table.remoteFingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get pairedAt => $composableBuilder(
    column: $table.pairedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PairedDevicesTableTableOrderingComposer
    extends Composer<_$GlobalDatabase, $PairedDevicesTableTable> {
  $$PairedDevicesTableTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pskRef => $composableBuilder(
    column: $table.pskRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteFingerprint => $composableBuilder(
    column: $table.remoteFingerprint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get pairedAt => $composableBuilder(
    column: $table.pairedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PairedDevicesTableTableAnnotationComposer
    extends Composer<_$GlobalDatabase, $PairedDevicesTableTable> {
  $$PairedDevicesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get platform =>
      $composableBuilder(column: $table.platform, builder: (column) => column);

  GeneratedColumn<String> get pskRef =>
      $composableBuilder(column: $table.pskRef, builder: (column) => column);

  GeneratedColumn<String> get remoteFingerprint => $composableBuilder(
    column: $table.remoteFingerprint,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get pairedAt =>
      $composableBuilder(column: $table.pairedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);
}

class $$PairedDevicesTableTableTableManager
    extends
        RootTableManager<
          _$GlobalDatabase,
          $PairedDevicesTableTable,
          PairedDevicesTableData,
          $$PairedDevicesTableTableFilterComposer,
          $$PairedDevicesTableTableOrderingComposer,
          $$PairedDevicesTableTableAnnotationComposer,
          $$PairedDevicesTableTableCreateCompanionBuilder,
          $$PairedDevicesTableTableUpdateCompanionBuilder,
          (
            PairedDevicesTableData,
            BaseReferences<
              _$GlobalDatabase,
              $PairedDevicesTableTable,
              PairedDevicesTableData
            >,
          ),
          PairedDevicesTableData,
          PrefetchHooks Function()
        > {
  $$PairedDevicesTableTableTableManager(
    _$GlobalDatabase db,
    $PairedDevicesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PairedDevicesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PairedDevicesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PairedDevicesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String?> workspaceId = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String> platform = const Value.absent(),
                Value<String> pskRef = const Value.absent(),
                Value<String?> remoteFingerprint = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> pairedAt = const Value.absent(),
                Value<DateTime?> lastSeenAt = const Value.absent(),
                Value<DateTime?> expiresAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PairedDevicesTableCompanion(
                id: id,
                userId: userId,
                workspaceId: workspaceId,
                label: label,
                platform: platform,
                pskRef: pskRef,
                remoteFingerprint: remoteFingerprint,
                status: status,
                pairedAt: pairedAt,
                lastSeenAt: lastSeenAt,
                expiresAt: expiresAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> userId = const Value.absent(),
                Value<String?> workspaceId = const Value.absent(),
                required String label,
                Value<String> platform = const Value.absent(),
                required String pskRef,
                Value<String?> remoteFingerprint = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> pairedAt = const Value.absent(),
                Value<DateTime?> lastSeenAt = const Value.absent(),
                Value<DateTime?> expiresAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PairedDevicesTableCompanion.insert(
                id: id,
                userId: userId,
                workspaceId: workspaceId,
                label: label,
                platform: platform,
                pskRef: pskRef,
                remoteFingerprint: remoteFingerprint,
                status: status,
                pairedAt: pairedAt,
                lastSeenAt: lastSeenAt,
                expiresAt: expiresAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PairedDevicesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$GlobalDatabase,
      $PairedDevicesTableTable,
      PairedDevicesTableData,
      $$PairedDevicesTableTableFilterComposer,
      $$PairedDevicesTableTableOrderingComposer,
      $$PairedDevicesTableTableAnnotationComposer,
      $$PairedDevicesTableTableCreateCompanionBuilder,
      $$PairedDevicesTableTableUpdateCompanionBuilder,
      (
        PairedDevicesTableData,
        BaseReferences<
          _$GlobalDatabase,
          $PairedDevicesTableTable,
          PairedDevicesTableData
        >,
      ),
      PairedDevicesTableData,
      PrefetchHooks Function()
    >;
typedef $$RssFeedsTableTableCreateCompanionBuilder =
    RssFeedsTableCompanion Function({
      required String id,
      required String userId,
      required String name,
      required String url,
      Value<String> description,
      Value<String> iconUrl,
      Value<String> userAgent,
      Value<bool> enabled,
      Value<DateTime?> lastFetchedAt,
      Value<String?> lastError,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$RssFeedsTableTableUpdateCompanionBuilder =
    RssFeedsTableCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> name,
      Value<String> url,
      Value<String> description,
      Value<String> iconUrl,
      Value<String> userAgent,
      Value<bool> enabled,
      Value<DateTime?> lastFetchedAt,
      Value<String?> lastError,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$RssFeedsTableTableReferences
    extends
        BaseReferences<
          _$GlobalDatabase,
          $RssFeedsTableTable,
          RssFeedsTableData
        > {
  $$RssFeedsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $UsersTableTable _userIdTable(_$GlobalDatabase db) =>
      db.usersTable.createAlias('rss_feeds__user_id__users__id');

  $$UsersTableTableProcessedTableManager get userId {
    final $_column = $_itemColumn<String>('user_id')!;

    final manager = $$UsersTableTableTableManager(
      $_db,
      $_db.usersTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$RssArticlesTableTable, List<RssArticlesTableData>>
  _rssArticlesTableRefsTable(_$GlobalDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.rssArticlesTable,
        aliasName: 'rss_feeds__id__rss_articles__feed_id',
      );

  $$RssArticlesTableTableProcessedTableManager get rssArticlesTableRefs {
    final manager = $$RssArticlesTableTableTableManager(
      $_db,
      $_db.rssArticlesTable,
    ).filter((f) => f.feedId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _rssArticlesTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RssFeedsTableTableFilterComposer
    extends Composer<_$GlobalDatabase, $RssFeedsTableTable> {
  $$RssFeedsTableTableFilterComposer({
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

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconUrl => $composableBuilder(
    column: $table.iconUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userAgent => $composableBuilder(
    column: $table.userAgent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastFetchedAt => $composableBuilder(
    column: $table.lastFetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
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

  $$UsersTableTableFilterComposer get userId {
    final $$UsersTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.usersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableTableFilterComposer(
            $db: $db,
            $table: $db.usersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> rssArticlesTableRefs(
    Expression<bool> Function($$RssArticlesTableTableFilterComposer f) f,
  ) {
    final $$RssArticlesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rssArticlesTable,
      getReferencedColumn: (t) => t.feedId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RssArticlesTableTableFilterComposer(
            $db: $db,
            $table: $db.rssArticlesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RssFeedsTableTableOrderingComposer
    extends Composer<_$GlobalDatabase, $RssFeedsTableTable> {
  $$RssFeedsTableTableOrderingComposer({
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

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconUrl => $composableBuilder(
    column: $table.iconUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userAgent => $composableBuilder(
    column: $table.userAgent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastFetchedAt => $composableBuilder(
    column: $table.lastFetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
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

  $$UsersTableTableOrderingComposer get userId {
    final $$UsersTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.usersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableTableOrderingComposer(
            $db: $db,
            $table: $db.usersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RssFeedsTableTableAnnotationComposer
    extends Composer<_$GlobalDatabase, $RssFeedsTableTable> {
  $$RssFeedsTableTableAnnotationComposer({
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

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get iconUrl =>
      $composableBuilder(column: $table.iconUrl, builder: (column) => column);

  GeneratedColumn<String> get userAgent =>
      $composableBuilder(column: $table.userAgent, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<DateTime> get lastFetchedAt => $composableBuilder(
    column: $table.lastFetchedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$UsersTableTableAnnotationComposer get userId {
    final $$UsersTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.usersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableTableAnnotationComposer(
            $db: $db,
            $table: $db.usersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> rssArticlesTableRefs<T extends Object>(
    Expression<T> Function($$RssArticlesTableTableAnnotationComposer a) f,
  ) {
    final $$RssArticlesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rssArticlesTable,
      getReferencedColumn: (t) => t.feedId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RssArticlesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.rssArticlesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RssFeedsTableTableTableManager
    extends
        RootTableManager<
          _$GlobalDatabase,
          $RssFeedsTableTable,
          RssFeedsTableData,
          $$RssFeedsTableTableFilterComposer,
          $$RssFeedsTableTableOrderingComposer,
          $$RssFeedsTableTableAnnotationComposer,
          $$RssFeedsTableTableCreateCompanionBuilder,
          $$RssFeedsTableTableUpdateCompanionBuilder,
          (RssFeedsTableData, $$RssFeedsTableTableReferences),
          RssFeedsTableData,
          PrefetchHooks Function({bool userId, bool rssArticlesTableRefs})
        > {
  $$RssFeedsTableTableTableManager(
    _$GlobalDatabase db,
    $RssFeedsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RssFeedsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RssFeedsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RssFeedsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> iconUrl = const Value.absent(),
                Value<String> userAgent = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<DateTime?> lastFetchedAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RssFeedsTableCompanion(
                id: id,
                userId: userId,
                name: name,
                url: url,
                description: description,
                iconUrl: iconUrl,
                userAgent: userAgent,
                enabled: enabled,
                lastFetchedAt: lastFetchedAt,
                lastError: lastError,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String name,
                required String url,
                Value<String> description = const Value.absent(),
                Value<String> iconUrl = const Value.absent(),
                Value<String> userAgent = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<DateTime?> lastFetchedAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RssFeedsTableCompanion.insert(
                id: id,
                userId: userId,
                name: name,
                url: url,
                description: description,
                iconUrl: iconUrl,
                userAgent: userAgent,
                enabled: enabled,
                lastFetchedAt: lastFetchedAt,
                lastError: lastError,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RssFeedsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({userId = false, rssArticlesTableRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (rssArticlesTableRefs) db.rssArticlesTable,
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
                        if (userId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.userId,
                                    referencedTable:
                                        $$RssFeedsTableTableReferences
                                            ._userIdTable(db),
                                    referencedColumn:
                                        $$RssFeedsTableTableReferences
                                            ._userIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (rssArticlesTableRefs)
                        await $_getPrefetchedData<
                          RssFeedsTableData,
                          $RssFeedsTableTable,
                          RssArticlesTableData
                        >(
                          currentTable: table,
                          referencedTable: $$RssFeedsTableTableReferences
                              ._rssArticlesTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RssFeedsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).rssArticlesTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.feedId == item.id,
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

typedef $$RssFeedsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$GlobalDatabase,
      $RssFeedsTableTable,
      RssFeedsTableData,
      $$RssFeedsTableTableFilterComposer,
      $$RssFeedsTableTableOrderingComposer,
      $$RssFeedsTableTableAnnotationComposer,
      $$RssFeedsTableTableCreateCompanionBuilder,
      $$RssFeedsTableTableUpdateCompanionBuilder,
      (RssFeedsTableData, $$RssFeedsTableTableReferences),
      RssFeedsTableData,
      PrefetchHooks Function({bool userId, bool rssArticlesTableRefs})
    >;
typedef $$RssArticlesTableTableCreateCompanionBuilder =
    RssArticlesTableCompanion Function({
      required String id,
      required String feedId,
      required String guid,
      required String title,
      required String link,
      Value<String> summary,
      Value<String> imageUrl,
      Value<String> author,
      Value<DateTime?> publishedAt,
      Value<bool> saved,
      Value<bool> read,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$RssArticlesTableTableUpdateCompanionBuilder =
    RssArticlesTableCompanion Function({
      Value<String> id,
      Value<String> feedId,
      Value<String> guid,
      Value<String> title,
      Value<String> link,
      Value<String> summary,
      Value<String> imageUrl,
      Value<String> author,
      Value<DateTime?> publishedAt,
      Value<bool> saved,
      Value<bool> read,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$RssArticlesTableTableReferences
    extends
        BaseReferences<
          _$GlobalDatabase,
          $RssArticlesTableTable,
          RssArticlesTableData
        > {
  $$RssArticlesTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $RssFeedsTableTable _feedIdTable(_$GlobalDatabase db) =>
      db.rssFeedsTable.createAlias('rss_articles__feed_id__rss_feeds__id');

  $$RssFeedsTableTableProcessedTableManager get feedId {
    final $_column = $_itemColumn<String>('feed_id')!;

    final manager = $$RssFeedsTableTableTableManager(
      $_db,
      $_db.rssFeedsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_feedIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RssArticlesTableTableFilterComposer
    extends Composer<_$GlobalDatabase, $RssArticlesTableTable> {
  $$RssArticlesTableTableFilterComposer({
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

  ColumnFilters<String> get guid => $composableBuilder(
    column: $table.guid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get link => $composableBuilder(
    column: $table.link,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get saved => $composableBuilder(
    column: $table.saved,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get read => $composableBuilder(
    column: $table.read,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$RssFeedsTableTableFilterComposer get feedId {
    final $$RssFeedsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.feedId,
      referencedTable: $db.rssFeedsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RssFeedsTableTableFilterComposer(
            $db: $db,
            $table: $db.rssFeedsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RssArticlesTableTableOrderingComposer
    extends Composer<_$GlobalDatabase, $RssArticlesTableTable> {
  $$RssArticlesTableTableOrderingComposer({
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

  ColumnOrderings<String> get guid => $composableBuilder(
    column: $table.guid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get link => $composableBuilder(
    column: $table.link,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get saved => $composableBuilder(
    column: $table.saved,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get read => $composableBuilder(
    column: $table.read,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$RssFeedsTableTableOrderingComposer get feedId {
    final $$RssFeedsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.feedId,
      referencedTable: $db.rssFeedsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RssFeedsTableTableOrderingComposer(
            $db: $db,
            $table: $db.rssFeedsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RssArticlesTableTableAnnotationComposer
    extends Composer<_$GlobalDatabase, $RssArticlesTableTable> {
  $$RssArticlesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get guid =>
      $composableBuilder(column: $table.guid, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get link =>
      $composableBuilder(column: $table.link, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get saved =>
      $composableBuilder(column: $table.saved, builder: (column) => column);

  GeneratedColumn<bool> get read =>
      $composableBuilder(column: $table.read, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$RssFeedsTableTableAnnotationComposer get feedId {
    final $$RssFeedsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.feedId,
      referencedTable: $db.rssFeedsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RssFeedsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.rssFeedsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RssArticlesTableTableTableManager
    extends
        RootTableManager<
          _$GlobalDatabase,
          $RssArticlesTableTable,
          RssArticlesTableData,
          $$RssArticlesTableTableFilterComposer,
          $$RssArticlesTableTableOrderingComposer,
          $$RssArticlesTableTableAnnotationComposer,
          $$RssArticlesTableTableCreateCompanionBuilder,
          $$RssArticlesTableTableUpdateCompanionBuilder,
          (RssArticlesTableData, $$RssArticlesTableTableReferences),
          RssArticlesTableData,
          PrefetchHooks Function({bool feedId})
        > {
  $$RssArticlesTableTableTableManager(
    _$GlobalDatabase db,
    $RssArticlesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RssArticlesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RssArticlesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RssArticlesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> feedId = const Value.absent(),
                Value<String> guid = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> link = const Value.absent(),
                Value<String> summary = const Value.absent(),
                Value<String> imageUrl = const Value.absent(),
                Value<String> author = const Value.absent(),
                Value<DateTime?> publishedAt = const Value.absent(),
                Value<bool> saved = const Value.absent(),
                Value<bool> read = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RssArticlesTableCompanion(
                id: id,
                feedId: feedId,
                guid: guid,
                title: title,
                link: link,
                summary: summary,
                imageUrl: imageUrl,
                author: author,
                publishedAt: publishedAt,
                saved: saved,
                read: read,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String feedId,
                required String guid,
                required String title,
                required String link,
                Value<String> summary = const Value.absent(),
                Value<String> imageUrl = const Value.absent(),
                Value<String> author = const Value.absent(),
                Value<DateTime?> publishedAt = const Value.absent(),
                Value<bool> saved = const Value.absent(),
                Value<bool> read = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RssArticlesTableCompanion.insert(
                id: id,
                feedId: feedId,
                guid: guid,
                title: title,
                link: link,
                summary: summary,
                imageUrl: imageUrl,
                author: author,
                publishedAt: publishedAt,
                saved: saved,
                read: read,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RssArticlesTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({feedId = false}) {
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
                    if (feedId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.feedId,
                                referencedTable:
                                    $$RssArticlesTableTableReferences
                                        ._feedIdTable(db),
                                referencedColumn:
                                    $$RssArticlesTableTableReferences
                                        ._feedIdTable(db)
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

typedef $$RssArticlesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$GlobalDatabase,
      $RssArticlesTableTable,
      RssArticlesTableData,
      $$RssArticlesTableTableFilterComposer,
      $$RssArticlesTableTableOrderingComposer,
      $$RssArticlesTableTableAnnotationComposer,
      $$RssArticlesTableTableCreateCompanionBuilder,
      $$RssArticlesTableTableUpdateCompanionBuilder,
      (RssArticlesTableData, $$RssArticlesTableTableReferences),
      RssArticlesTableData,
      PrefetchHooks Function({bool feedId})
    >;
typedef $$WorkersTableTableCreateCompanionBuilder =
    WorkersTableCompanion Function({
      required String id,
      required String name,
      Value<String> capsJson,
      Value<String> platform,
      Value<String?> credentialRef,
      Value<String?> pairedDeviceId,
      Value<int> protocolVersion,
      Value<String> status,
      Value<DateTime?> lastHeartbeatAt,
      Value<String?> registeredBy,
      Value<DateTime?> drainedAt,
      Value<DateTime?> revokedAt,
      Value<String?> lastError,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$WorkersTableTableUpdateCompanionBuilder =
    WorkersTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> capsJson,
      Value<String> platform,
      Value<String?> credentialRef,
      Value<String?> pairedDeviceId,
      Value<int> protocolVersion,
      Value<String> status,
      Value<DateTime?> lastHeartbeatAt,
      Value<String?> registeredBy,
      Value<DateTime?> drainedAt,
      Value<DateTime?> revokedAt,
      Value<String?> lastError,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$WorkersTableTableFilterComposer
    extends Composer<_$GlobalDatabase, $WorkersTableTable> {
  $$WorkersTableTableFilterComposer({
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

  ColumnFilters<String> get capsJson => $composableBuilder(
    column: $table.capsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get credentialRef => $composableBuilder(
    column: $table.credentialRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pairedDeviceId => $composableBuilder(
    column: $table.pairedDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get protocolVersion => $composableBuilder(
    column: $table.protocolVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastHeartbeatAt => $composableBuilder(
    column: $table.lastHeartbeatAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get registeredBy => $composableBuilder(
    column: $table.registeredBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get drainedAt => $composableBuilder(
    column: $table.drainedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get revokedAt => $composableBuilder(
    column: $table.revokedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorkersTableTableOrderingComposer
    extends Composer<_$GlobalDatabase, $WorkersTableTable> {
  $$WorkersTableTableOrderingComposer({
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

  ColumnOrderings<String> get capsJson => $composableBuilder(
    column: $table.capsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get credentialRef => $composableBuilder(
    column: $table.credentialRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pairedDeviceId => $composableBuilder(
    column: $table.pairedDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get protocolVersion => $composableBuilder(
    column: $table.protocolVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastHeartbeatAt => $composableBuilder(
    column: $table.lastHeartbeatAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get registeredBy => $composableBuilder(
    column: $table.registeredBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get drainedAt => $composableBuilder(
    column: $table.drainedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get revokedAt => $composableBuilder(
    column: $table.revokedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkersTableTableAnnotationComposer
    extends Composer<_$GlobalDatabase, $WorkersTableTable> {
  $$WorkersTableTableAnnotationComposer({
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

  GeneratedColumn<String> get capsJson =>
      $composableBuilder(column: $table.capsJson, builder: (column) => column);

  GeneratedColumn<String> get platform =>
      $composableBuilder(column: $table.platform, builder: (column) => column);

  GeneratedColumn<String> get credentialRef => $composableBuilder(
    column: $table.credentialRef,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pairedDeviceId => $composableBuilder(
    column: $table.pairedDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get protocolVersion => $composableBuilder(
    column: $table.protocolVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get lastHeartbeatAt => $composableBuilder(
    column: $table.lastHeartbeatAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get registeredBy => $composableBuilder(
    column: $table.registeredBy,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get drainedAt =>
      $composableBuilder(column: $table.drainedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get revokedAt =>
      $composableBuilder(column: $table.revokedAt, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$WorkersTableTableTableManager
    extends
        RootTableManager<
          _$GlobalDatabase,
          $WorkersTableTable,
          WorkersTableData,
          $$WorkersTableTableFilterComposer,
          $$WorkersTableTableOrderingComposer,
          $$WorkersTableTableAnnotationComposer,
          $$WorkersTableTableCreateCompanionBuilder,
          $$WorkersTableTableUpdateCompanionBuilder,
          (
            WorkersTableData,
            BaseReferences<
              _$GlobalDatabase,
              $WorkersTableTable,
              WorkersTableData
            >,
          ),
          WorkersTableData,
          PrefetchHooks Function()
        > {
  $$WorkersTableTableTableManager(_$GlobalDatabase db, $WorkersTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkersTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkersTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> capsJson = const Value.absent(),
                Value<String> platform = const Value.absent(),
                Value<String?> credentialRef = const Value.absent(),
                Value<String?> pairedDeviceId = const Value.absent(),
                Value<int> protocolVersion = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> lastHeartbeatAt = const Value.absent(),
                Value<String?> registeredBy = const Value.absent(),
                Value<DateTime?> drainedAt = const Value.absent(),
                Value<DateTime?> revokedAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkersTableCompanion(
                id: id,
                name: name,
                capsJson: capsJson,
                platform: platform,
                credentialRef: credentialRef,
                pairedDeviceId: pairedDeviceId,
                protocolVersion: protocolVersion,
                status: status,
                lastHeartbeatAt: lastHeartbeatAt,
                registeredBy: registeredBy,
                drainedAt: drainedAt,
                revokedAt: revokedAt,
                lastError: lastError,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> capsJson = const Value.absent(),
                Value<String> platform = const Value.absent(),
                Value<String?> credentialRef = const Value.absent(),
                Value<String?> pairedDeviceId = const Value.absent(),
                Value<int> protocolVersion = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> lastHeartbeatAt = const Value.absent(),
                Value<String?> registeredBy = const Value.absent(),
                Value<DateTime?> drainedAt = const Value.absent(),
                Value<DateTime?> revokedAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkersTableCompanion.insert(
                id: id,
                name: name,
                capsJson: capsJson,
                platform: platform,
                credentialRef: credentialRef,
                pairedDeviceId: pairedDeviceId,
                protocolVersion: protocolVersion,
                status: status,
                lastHeartbeatAt: lastHeartbeatAt,
                registeredBy: registeredBy,
                drainedAt: drainedAt,
                revokedAt: revokedAt,
                lastError: lastError,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorkersTableTableProcessedTableManager =
    ProcessedTableManager<
      _$GlobalDatabase,
      $WorkersTableTable,
      WorkersTableData,
      $$WorkersTableTableFilterComposer,
      $$WorkersTableTableOrderingComposer,
      $$WorkersTableTableAnnotationComposer,
      $$WorkersTableTableCreateCompanionBuilder,
      $$WorkersTableTableUpdateCompanionBuilder,
      (
        WorkersTableData,
        BaseReferences<_$GlobalDatabase, $WorkersTableTable, WorkersTableData>,
      ),
      WorkersTableData,
      PrefetchHooks Function()
    >;
typedef $$JobsTableTableCreateCompanionBuilder =
    JobsTableCompanion Function({
      required String id,
      required String workspaceId,
      required String kind,
      Value<String> specJson,
      Value<String> requiredCapsJson,
      Value<String> preferredCapsJson,
      Value<String> status,
      Value<String?> workerId,
      Value<String?> pinnedWorkerId,
      Value<DateTime?> leaseExpiresAt,
      Value<int> priority,
      Value<String?> submittedBy,
      Value<int> costCents,
      Value<int> attempts,
      Value<int> maxAttempts,
      Value<int> lastAckedSeq,
      Value<String?> resultJson,
      Value<String?> error,
      Value<String?> agentId,
      Value<String?> conversationId,
      Value<DateTime> createdAt,
      Value<DateTime?> leasedAt,
      Value<DateTime?> startedAt,
      Value<DateTime?> finishedAt,
      Value<int> rowid,
    });
typedef $$JobsTableTableUpdateCompanionBuilder =
    JobsTableCompanion Function({
      Value<String> id,
      Value<String> workspaceId,
      Value<String> kind,
      Value<String> specJson,
      Value<String> requiredCapsJson,
      Value<String> preferredCapsJson,
      Value<String> status,
      Value<String?> workerId,
      Value<String?> pinnedWorkerId,
      Value<DateTime?> leaseExpiresAt,
      Value<int> priority,
      Value<String?> submittedBy,
      Value<int> costCents,
      Value<int> attempts,
      Value<int> maxAttempts,
      Value<int> lastAckedSeq,
      Value<String?> resultJson,
      Value<String?> error,
      Value<String?> agentId,
      Value<String?> conversationId,
      Value<DateTime> createdAt,
      Value<DateTime?> leasedAt,
      Value<DateTime?> startedAt,
      Value<DateTime?> finishedAt,
      Value<int> rowid,
    });

class $$JobsTableTableFilterComposer
    extends Composer<_$GlobalDatabase, $JobsTableTable> {
  $$JobsTableTableFilterComposer({
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

  ColumnFilters<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get specJson => $composableBuilder(
    column: $table.specJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get requiredCapsJson => $composableBuilder(
    column: $table.requiredCapsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preferredCapsJson => $composableBuilder(
    column: $table.preferredCapsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workerId => $composableBuilder(
    column: $table.workerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pinnedWorkerId => $composableBuilder(
    column: $table.pinnedWorkerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get leaseExpiresAt => $composableBuilder(
    column: $table.leaseExpiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get submittedBy => $composableBuilder(
    column: $table.submittedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get costCents => $composableBuilder(
    column: $table.costCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxAttempts => $composableBuilder(
    column: $table.maxAttempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastAckedSeq => $composableBuilder(
    column: $table.lastAckedSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resultJson => $composableBuilder(
    column: $table.resultJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get agentId => $composableBuilder(
    column: $table.agentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get leasedAt => $composableBuilder(
    column: $table.leasedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$JobsTableTableOrderingComposer
    extends Composer<_$GlobalDatabase, $JobsTableTable> {
  $$JobsTableTableOrderingComposer({
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

  ColumnOrderings<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get specJson => $composableBuilder(
    column: $table.specJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get requiredCapsJson => $composableBuilder(
    column: $table.requiredCapsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preferredCapsJson => $composableBuilder(
    column: $table.preferredCapsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workerId => $composableBuilder(
    column: $table.workerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pinnedWorkerId => $composableBuilder(
    column: $table.pinnedWorkerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get leaseExpiresAt => $composableBuilder(
    column: $table.leaseExpiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get submittedBy => $composableBuilder(
    column: $table.submittedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get costCents => $composableBuilder(
    column: $table.costCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxAttempts => $composableBuilder(
    column: $table.maxAttempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastAckedSeq => $composableBuilder(
    column: $table.lastAckedSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resultJson => $composableBuilder(
    column: $table.resultJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get agentId => $composableBuilder(
    column: $table.agentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get leasedAt => $composableBuilder(
    column: $table.leasedAt,
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
}

class $$JobsTableTableAnnotationComposer
    extends Composer<_$GlobalDatabase, $JobsTableTable> {
  $$JobsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get specJson =>
      $composableBuilder(column: $table.specJson, builder: (column) => column);

  GeneratedColumn<String> get requiredCapsJson => $composableBuilder(
    column: $table.requiredCapsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get preferredCapsJson => $composableBuilder(
    column: $table.preferredCapsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get workerId =>
      $composableBuilder(column: $table.workerId, builder: (column) => column);

  GeneratedColumn<String> get pinnedWorkerId => $composableBuilder(
    column: $table.pinnedWorkerId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get leaseExpiresAt => $composableBuilder(
    column: $table.leaseExpiresAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get submittedBy => $composableBuilder(
    column: $table.submittedBy,
    builder: (column) => column,
  );

  GeneratedColumn<int> get costCents =>
      $composableBuilder(column: $table.costCents, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<int> get maxAttempts => $composableBuilder(
    column: $table.maxAttempts,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastAckedSeq => $composableBuilder(
    column: $table.lastAckedSeq,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resultJson => $composableBuilder(
    column: $table.resultJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);

  GeneratedColumn<String> get agentId =>
      $composableBuilder(column: $table.agentId, builder: (column) => column);

  GeneratedColumn<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get leasedAt =>
      $composableBuilder(column: $table.leasedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );
}

class $$JobsTableTableTableManager
    extends
        RootTableManager<
          _$GlobalDatabase,
          $JobsTableTable,
          JobsTableData,
          $$JobsTableTableFilterComposer,
          $$JobsTableTableOrderingComposer,
          $$JobsTableTableAnnotationComposer,
          $$JobsTableTableCreateCompanionBuilder,
          $$JobsTableTableUpdateCompanionBuilder,
          (
            JobsTableData,
            BaseReferences<_$GlobalDatabase, $JobsTableTable, JobsTableData>,
          ),
          JobsTableData,
          PrefetchHooks Function()
        > {
  $$JobsTableTableTableManager(_$GlobalDatabase db, $JobsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JobsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JobsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JobsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> specJson = const Value.absent(),
                Value<String> requiredCapsJson = const Value.absent(),
                Value<String> preferredCapsJson = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> workerId = const Value.absent(),
                Value<String?> pinnedWorkerId = const Value.absent(),
                Value<DateTime?> leaseExpiresAt = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<String?> submittedBy = const Value.absent(),
                Value<int> costCents = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<int> maxAttempts = const Value.absent(),
                Value<int> lastAckedSeq = const Value.absent(),
                Value<String?> resultJson = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<String?> agentId = const Value.absent(),
                Value<String?> conversationId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> leasedAt = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JobsTableCompanion(
                id: id,
                workspaceId: workspaceId,
                kind: kind,
                specJson: specJson,
                requiredCapsJson: requiredCapsJson,
                preferredCapsJson: preferredCapsJson,
                status: status,
                workerId: workerId,
                pinnedWorkerId: pinnedWorkerId,
                leaseExpiresAt: leaseExpiresAt,
                priority: priority,
                submittedBy: submittedBy,
                costCents: costCents,
                attempts: attempts,
                maxAttempts: maxAttempts,
                lastAckedSeq: lastAckedSeq,
                resultJson: resultJson,
                error: error,
                agentId: agentId,
                conversationId: conversationId,
                createdAt: createdAt,
                leasedAt: leasedAt,
                startedAt: startedAt,
                finishedAt: finishedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String workspaceId,
                required String kind,
                Value<String> specJson = const Value.absent(),
                Value<String> requiredCapsJson = const Value.absent(),
                Value<String> preferredCapsJson = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> workerId = const Value.absent(),
                Value<String?> pinnedWorkerId = const Value.absent(),
                Value<DateTime?> leaseExpiresAt = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<String?> submittedBy = const Value.absent(),
                Value<int> costCents = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<int> maxAttempts = const Value.absent(),
                Value<int> lastAckedSeq = const Value.absent(),
                Value<String?> resultJson = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<String?> agentId = const Value.absent(),
                Value<String?> conversationId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> leasedAt = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JobsTableCompanion.insert(
                id: id,
                workspaceId: workspaceId,
                kind: kind,
                specJson: specJson,
                requiredCapsJson: requiredCapsJson,
                preferredCapsJson: preferredCapsJson,
                status: status,
                workerId: workerId,
                pinnedWorkerId: pinnedWorkerId,
                leaseExpiresAt: leaseExpiresAt,
                priority: priority,
                submittedBy: submittedBy,
                costCents: costCents,
                attempts: attempts,
                maxAttempts: maxAttempts,
                lastAckedSeq: lastAckedSeq,
                resultJson: resultJson,
                error: error,
                agentId: agentId,
                conversationId: conversationId,
                createdAt: createdAt,
                leasedAt: leasedAt,
                startedAt: startedAt,
                finishedAt: finishedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$JobsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$GlobalDatabase,
      $JobsTableTable,
      JobsTableData,
      $$JobsTableTableFilterComposer,
      $$JobsTableTableOrderingComposer,
      $$JobsTableTableAnnotationComposer,
      $$JobsTableTableCreateCompanionBuilder,
      $$JobsTableTableUpdateCompanionBuilder,
      (
        JobsTableData,
        BaseReferences<_$GlobalDatabase, $JobsTableTable, JobsTableData>,
      ),
      JobsTableData,
      PrefetchHooks Function()
    >;
typedef $$PlacementLogTableTableCreateCompanionBuilder =
    PlacementLogTableCompanion Function({
      required String id,
      required String workspaceId,
      required String jobId,
      Value<String?> workerId,
      Value<String> decision,
      Value<String> reason,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$PlacementLogTableTableUpdateCompanionBuilder =
    PlacementLogTableCompanion Function({
      Value<String> id,
      Value<String> workspaceId,
      Value<String> jobId,
      Value<String?> workerId,
      Value<String> decision,
      Value<String> reason,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$PlacementLogTableTableFilterComposer
    extends Composer<_$GlobalDatabase, $PlacementLogTableTable> {
  $$PlacementLogTableTableFilterComposer({
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

  ColumnFilters<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jobId => $composableBuilder(
    column: $table.jobId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workerId => $composableBuilder(
    column: $table.workerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get decision => $composableBuilder(
    column: $table.decision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlacementLogTableTableOrderingComposer
    extends Composer<_$GlobalDatabase, $PlacementLogTableTable> {
  $$PlacementLogTableTableOrderingComposer({
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

  ColumnOrderings<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jobId => $composableBuilder(
    column: $table.jobId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workerId => $composableBuilder(
    column: $table.workerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get decision => $composableBuilder(
    column: $table.decision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlacementLogTableTableAnnotationComposer
    extends Composer<_$GlobalDatabase, $PlacementLogTableTable> {
  $$PlacementLogTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get jobId =>
      $composableBuilder(column: $table.jobId, builder: (column) => column);

  GeneratedColumn<String> get workerId =>
      $composableBuilder(column: $table.workerId, builder: (column) => column);

  GeneratedColumn<String> get decision =>
      $composableBuilder(column: $table.decision, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PlacementLogTableTableTableManager
    extends
        RootTableManager<
          _$GlobalDatabase,
          $PlacementLogTableTable,
          PlacementLogTableData,
          $$PlacementLogTableTableFilterComposer,
          $$PlacementLogTableTableOrderingComposer,
          $$PlacementLogTableTableAnnotationComposer,
          $$PlacementLogTableTableCreateCompanionBuilder,
          $$PlacementLogTableTableUpdateCompanionBuilder,
          (
            PlacementLogTableData,
            BaseReferences<
              _$GlobalDatabase,
              $PlacementLogTableTable,
              PlacementLogTableData
            >,
          ),
          PlacementLogTableData,
          PrefetchHooks Function()
        > {
  $$PlacementLogTableTableTableManager(
    _$GlobalDatabase db,
    $PlacementLogTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlacementLogTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlacementLogTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlacementLogTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String> jobId = const Value.absent(),
                Value<String?> workerId = const Value.absent(),
                Value<String> decision = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlacementLogTableCompanion(
                id: id,
                workspaceId: workspaceId,
                jobId: jobId,
                workerId: workerId,
                decision: decision,
                reason: reason,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String workspaceId,
                required String jobId,
                Value<String?> workerId = const Value.absent(),
                Value<String> decision = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlacementLogTableCompanion.insert(
                id: id,
                workspaceId: workspaceId,
                jobId: jobId,
                workerId: workerId,
                decision: decision,
                reason: reason,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlacementLogTableTableProcessedTableManager =
    ProcessedTableManager<
      _$GlobalDatabase,
      $PlacementLogTableTable,
      PlacementLogTableData,
      $$PlacementLogTableTableFilterComposer,
      $$PlacementLogTableTableOrderingComposer,
      $$PlacementLogTableTableAnnotationComposer,
      $$PlacementLogTableTableCreateCompanionBuilder,
      $$PlacementLogTableTableUpdateCompanionBuilder,
      (
        PlacementLogTableData,
        BaseReferences<
          _$GlobalDatabase,
          $PlacementLogTableTable,
          PlacementLogTableData
        >,
      ),
      PlacementLogTableData,
      PrefetchHooks Function()
    >;
typedef $$WorkspaceRoutesTableTableCreateCompanionBuilder =
    WorkspaceRoutesTableCompanion Function({
      required String kind,
      required String keyHash,
      required String workspaceId,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$WorkspaceRoutesTableTableUpdateCompanionBuilder =
    WorkspaceRoutesTableCompanion Function({
      Value<String> kind,
      Value<String> keyHash,
      Value<String> workspaceId,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$WorkspaceRoutesTableTableFilterComposer
    extends Composer<_$GlobalDatabase, $WorkspaceRoutesTableTable> {
  $$WorkspaceRoutesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get keyHash => $composableBuilder(
    column: $table.keyHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorkspaceRoutesTableTableOrderingComposer
    extends Composer<_$GlobalDatabase, $WorkspaceRoutesTableTable> {
  $$WorkspaceRoutesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keyHash => $composableBuilder(
    column: $table.keyHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkspaceRoutesTableTableAnnotationComposer
    extends Composer<_$GlobalDatabase, $WorkspaceRoutesTableTable> {
  $$WorkspaceRoutesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get keyHash =>
      $composableBuilder(column: $table.keyHash, builder: (column) => column);

  GeneratedColumn<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$WorkspaceRoutesTableTableTableManager
    extends
        RootTableManager<
          _$GlobalDatabase,
          $WorkspaceRoutesTableTable,
          WorkspaceRoutesTableData,
          $$WorkspaceRoutesTableTableFilterComposer,
          $$WorkspaceRoutesTableTableOrderingComposer,
          $$WorkspaceRoutesTableTableAnnotationComposer,
          $$WorkspaceRoutesTableTableCreateCompanionBuilder,
          $$WorkspaceRoutesTableTableUpdateCompanionBuilder,
          (
            WorkspaceRoutesTableData,
            BaseReferences<
              _$GlobalDatabase,
              $WorkspaceRoutesTableTable,
              WorkspaceRoutesTableData
            >,
          ),
          WorkspaceRoutesTableData,
          PrefetchHooks Function()
        > {
  $$WorkspaceRoutesTableTableTableManager(
    _$GlobalDatabase db,
    $WorkspaceRoutesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkspaceRoutesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkspaceRoutesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$WorkspaceRoutesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> kind = const Value.absent(),
                Value<String> keyHash = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkspaceRoutesTableCompanion(
                kind: kind,
                keyHash: keyHash,
                workspaceId: workspaceId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String kind,
                required String keyHash,
                required String workspaceId,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkspaceRoutesTableCompanion.insert(
                kind: kind,
                keyHash: keyHash,
                workspaceId: workspaceId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorkspaceRoutesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$GlobalDatabase,
      $WorkspaceRoutesTableTable,
      WorkspaceRoutesTableData,
      $$WorkspaceRoutesTableTableFilterComposer,
      $$WorkspaceRoutesTableTableOrderingComposer,
      $$WorkspaceRoutesTableTableAnnotationComposer,
      $$WorkspaceRoutesTableTableCreateCompanionBuilder,
      $$WorkspaceRoutesTableTableUpdateCompanionBuilder,
      (
        WorkspaceRoutesTableData,
        BaseReferences<
          _$GlobalDatabase,
          $WorkspaceRoutesTableTable,
          WorkspaceRoutesTableData
        >,
      ),
      WorkspaceRoutesTableData,
      PrefetchHooks Function()
    >;
typedef $$ServerMetaTableTableCreateCompanionBuilder =
    ServerMetaTableCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$ServerMetaTableTableUpdateCompanionBuilder =
    ServerMetaTableCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$ServerMetaTableTableFilterComposer
    extends Composer<_$GlobalDatabase, $ServerMetaTableTable> {
  $$ServerMetaTableTableFilterComposer({
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

class $$ServerMetaTableTableOrderingComposer
    extends Composer<_$GlobalDatabase, $ServerMetaTableTable> {
  $$ServerMetaTableTableOrderingComposer({
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

class $$ServerMetaTableTableAnnotationComposer
    extends Composer<_$GlobalDatabase, $ServerMetaTableTable> {
  $$ServerMetaTableTableAnnotationComposer({
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

class $$ServerMetaTableTableTableManager
    extends
        RootTableManager<
          _$GlobalDatabase,
          $ServerMetaTableTable,
          ServerMetaTableData,
          $$ServerMetaTableTableFilterComposer,
          $$ServerMetaTableTableOrderingComposer,
          $$ServerMetaTableTableAnnotationComposer,
          $$ServerMetaTableTableCreateCompanionBuilder,
          $$ServerMetaTableTableUpdateCompanionBuilder,
          (
            ServerMetaTableData,
            BaseReferences<
              _$GlobalDatabase,
              $ServerMetaTableTable,
              ServerMetaTableData
            >,
          ),
          ServerMetaTableData,
          PrefetchHooks Function()
        > {
  $$ServerMetaTableTableTableManager(
    _$GlobalDatabase db,
    $ServerMetaTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ServerMetaTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ServerMetaTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ServerMetaTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ServerMetaTableCompanion(
                key: key,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => ServerMetaTableCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ServerMetaTableTableProcessedTableManager =
    ProcessedTableManager<
      _$GlobalDatabase,
      $ServerMetaTableTable,
      ServerMetaTableData,
      $$ServerMetaTableTableFilterComposer,
      $$ServerMetaTableTableOrderingComposer,
      $$ServerMetaTableTableAnnotationComposer,
      $$ServerMetaTableTableCreateCompanionBuilder,
      $$ServerMetaTableTableUpdateCompanionBuilder,
      (
        ServerMetaTableData,
        BaseReferences<
          _$GlobalDatabase,
          $ServerMetaTableTable,
          ServerMetaTableData
        >,
      ),
      ServerMetaTableData,
      PrefetchHooks Function()
    >;
typedef $$ServerSettingsTableTableCreateCompanionBuilder =
    ServerSettingsTableCompanion Function({
      required String key,
      required String value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$ServerSettingsTableTableUpdateCompanionBuilder =
    ServerSettingsTableCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ServerSettingsTableTableFilterComposer
    extends Composer<_$GlobalDatabase, $ServerSettingsTableTable> {
  $$ServerSettingsTableTableFilterComposer({
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

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ServerSettingsTableTableOrderingComposer
    extends Composer<_$GlobalDatabase, $ServerSettingsTableTable> {
  $$ServerSettingsTableTableOrderingComposer({
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

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ServerSettingsTableTableAnnotationComposer
    extends Composer<_$GlobalDatabase, $ServerSettingsTableTable> {
  $$ServerSettingsTableTableAnnotationComposer({
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

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ServerSettingsTableTableTableManager
    extends
        RootTableManager<
          _$GlobalDatabase,
          $ServerSettingsTableTable,
          ServerSettingsTableData,
          $$ServerSettingsTableTableFilterComposer,
          $$ServerSettingsTableTableOrderingComposer,
          $$ServerSettingsTableTableAnnotationComposer,
          $$ServerSettingsTableTableCreateCompanionBuilder,
          $$ServerSettingsTableTableUpdateCompanionBuilder,
          (
            ServerSettingsTableData,
            BaseReferences<
              _$GlobalDatabase,
              $ServerSettingsTableTable,
              ServerSettingsTableData
            >,
          ),
          ServerSettingsTableData,
          PrefetchHooks Function()
        > {
  $$ServerSettingsTableTableTableManager(
    _$GlobalDatabase db,
    $ServerSettingsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ServerSettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ServerSettingsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ServerSettingsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ServerSettingsTableCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ServerSettingsTableCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ServerSettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$GlobalDatabase,
      $ServerSettingsTableTable,
      ServerSettingsTableData,
      $$ServerSettingsTableTableFilterComposer,
      $$ServerSettingsTableTableOrderingComposer,
      $$ServerSettingsTableTableAnnotationComposer,
      $$ServerSettingsTableTableCreateCompanionBuilder,
      $$ServerSettingsTableTableUpdateCompanionBuilder,
      (
        ServerSettingsTableData,
        BaseReferences<
          _$GlobalDatabase,
          $ServerSettingsTableTable,
          ServerSettingsTableData
        >,
      ),
      ServerSettingsTableData,
      PrefetchHooks Function()
    >;
typedef $$SsoConnectionsTableTableCreateCompanionBuilder =
    SsoConnectionsTableCompanion Function({
      required String id,
      required String kind,
      Value<bool> enabled,
      Value<String> issuer,
      Value<String> clientId,
      Value<String> groupsClaim,
      Value<String> idpMetadataXml,
      Value<String> spEntityId,
      Value<String> emailAttribute,
      Value<String> displayNameAttribute,
      Value<String> groupsAttribute,
      Value<String> defaultRole,
      Value<String> groupRoleMap,
      Value<bool> autoMember,
      Value<bool> allowJit,
      Value<bool> allowIdpInitiated,
      Value<bool> wantResponseSigned,
      Value<int> clockSkewSeconds,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$SsoConnectionsTableTableUpdateCompanionBuilder =
    SsoConnectionsTableCompanion Function({
      Value<String> id,
      Value<String> kind,
      Value<bool> enabled,
      Value<String> issuer,
      Value<String> clientId,
      Value<String> groupsClaim,
      Value<String> idpMetadataXml,
      Value<String> spEntityId,
      Value<String> emailAttribute,
      Value<String> displayNameAttribute,
      Value<String> groupsAttribute,
      Value<String> defaultRole,
      Value<String> groupRoleMap,
      Value<bool> autoMember,
      Value<bool> allowJit,
      Value<bool> allowIdpInitiated,
      Value<bool> wantResponseSigned,
      Value<int> clockSkewSeconds,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$SsoConnectionsTableTableFilterComposer
    extends Composer<_$GlobalDatabase, $SsoConnectionsTableTable> {
  $$SsoConnectionsTableTableFilterComposer({
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

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get issuer => $composableBuilder(
    column: $table.issuer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupsClaim => $composableBuilder(
    column: $table.groupsClaim,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idpMetadataXml => $composableBuilder(
    column: $table.idpMetadataXml,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get spEntityId => $composableBuilder(
    column: $table.spEntityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emailAttribute => $composableBuilder(
    column: $table.emailAttribute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayNameAttribute => $composableBuilder(
    column: $table.displayNameAttribute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupsAttribute => $composableBuilder(
    column: $table.groupsAttribute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultRole => $composableBuilder(
    column: $table.defaultRole,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupRoleMap => $composableBuilder(
    column: $table.groupRoleMap,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoMember => $composableBuilder(
    column: $table.autoMember,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get allowJit => $composableBuilder(
    column: $table.allowJit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get allowIdpInitiated => $composableBuilder(
    column: $table.allowIdpInitiated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get wantResponseSigned => $composableBuilder(
    column: $table.wantResponseSigned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clockSkewSeconds => $composableBuilder(
    column: $table.clockSkewSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SsoConnectionsTableTableOrderingComposer
    extends Composer<_$GlobalDatabase, $SsoConnectionsTableTable> {
  $$SsoConnectionsTableTableOrderingComposer({
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

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get issuer => $composableBuilder(
    column: $table.issuer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupsClaim => $composableBuilder(
    column: $table.groupsClaim,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idpMetadataXml => $composableBuilder(
    column: $table.idpMetadataXml,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get spEntityId => $composableBuilder(
    column: $table.spEntityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emailAttribute => $composableBuilder(
    column: $table.emailAttribute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayNameAttribute => $composableBuilder(
    column: $table.displayNameAttribute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupsAttribute => $composableBuilder(
    column: $table.groupsAttribute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultRole => $composableBuilder(
    column: $table.defaultRole,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupRoleMap => $composableBuilder(
    column: $table.groupRoleMap,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoMember => $composableBuilder(
    column: $table.autoMember,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get allowJit => $composableBuilder(
    column: $table.allowJit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get allowIdpInitiated => $composableBuilder(
    column: $table.allowIdpInitiated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get wantResponseSigned => $composableBuilder(
    column: $table.wantResponseSigned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clockSkewSeconds => $composableBuilder(
    column: $table.clockSkewSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SsoConnectionsTableTableAnnotationComposer
    extends Composer<_$GlobalDatabase, $SsoConnectionsTableTable> {
  $$SsoConnectionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<String> get issuer =>
      $composableBuilder(column: $table.issuer, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get groupsClaim => $composableBuilder(
    column: $table.groupsClaim,
    builder: (column) => column,
  );

  GeneratedColumn<String> get idpMetadataXml => $composableBuilder(
    column: $table.idpMetadataXml,
    builder: (column) => column,
  );

  GeneratedColumn<String> get spEntityId => $composableBuilder(
    column: $table.spEntityId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get emailAttribute => $composableBuilder(
    column: $table.emailAttribute,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayNameAttribute => $composableBuilder(
    column: $table.displayNameAttribute,
    builder: (column) => column,
  );

  GeneratedColumn<String> get groupsAttribute => $composableBuilder(
    column: $table.groupsAttribute,
    builder: (column) => column,
  );

  GeneratedColumn<String> get defaultRole => $composableBuilder(
    column: $table.defaultRole,
    builder: (column) => column,
  );

  GeneratedColumn<String> get groupRoleMap => $composableBuilder(
    column: $table.groupRoleMap,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get autoMember => $composableBuilder(
    column: $table.autoMember,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get allowJit =>
      $composableBuilder(column: $table.allowJit, builder: (column) => column);

  GeneratedColumn<bool> get allowIdpInitiated => $composableBuilder(
    column: $table.allowIdpInitiated,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get wantResponseSigned => $composableBuilder(
    column: $table.wantResponseSigned,
    builder: (column) => column,
  );

  GeneratedColumn<int> get clockSkewSeconds => $composableBuilder(
    column: $table.clockSkewSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SsoConnectionsTableTableTableManager
    extends
        RootTableManager<
          _$GlobalDatabase,
          $SsoConnectionsTableTable,
          SsoConnectionsTableData,
          $$SsoConnectionsTableTableFilterComposer,
          $$SsoConnectionsTableTableOrderingComposer,
          $$SsoConnectionsTableTableAnnotationComposer,
          $$SsoConnectionsTableTableCreateCompanionBuilder,
          $$SsoConnectionsTableTableUpdateCompanionBuilder,
          (
            SsoConnectionsTableData,
            BaseReferences<
              _$GlobalDatabase,
              $SsoConnectionsTableTable,
              SsoConnectionsTableData
            >,
          ),
          SsoConnectionsTableData,
          PrefetchHooks Function()
        > {
  $$SsoConnectionsTableTableTableManager(
    _$GlobalDatabase db,
    $SsoConnectionsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SsoConnectionsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SsoConnectionsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SsoConnectionsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<String> issuer = const Value.absent(),
                Value<String> clientId = const Value.absent(),
                Value<String> groupsClaim = const Value.absent(),
                Value<String> idpMetadataXml = const Value.absent(),
                Value<String> spEntityId = const Value.absent(),
                Value<String> emailAttribute = const Value.absent(),
                Value<String> displayNameAttribute = const Value.absent(),
                Value<String> groupsAttribute = const Value.absent(),
                Value<String> defaultRole = const Value.absent(),
                Value<String> groupRoleMap = const Value.absent(),
                Value<bool> autoMember = const Value.absent(),
                Value<bool> allowJit = const Value.absent(),
                Value<bool> allowIdpInitiated = const Value.absent(),
                Value<bool> wantResponseSigned = const Value.absent(),
                Value<int> clockSkewSeconds = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SsoConnectionsTableCompanion(
                id: id,
                kind: kind,
                enabled: enabled,
                issuer: issuer,
                clientId: clientId,
                groupsClaim: groupsClaim,
                idpMetadataXml: idpMetadataXml,
                spEntityId: spEntityId,
                emailAttribute: emailAttribute,
                displayNameAttribute: displayNameAttribute,
                groupsAttribute: groupsAttribute,
                defaultRole: defaultRole,
                groupRoleMap: groupRoleMap,
                autoMember: autoMember,
                allowJit: allowJit,
                allowIdpInitiated: allowIdpInitiated,
                wantResponseSigned: wantResponseSigned,
                clockSkewSeconds: clockSkewSeconds,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String kind,
                Value<bool> enabled = const Value.absent(),
                Value<String> issuer = const Value.absent(),
                Value<String> clientId = const Value.absent(),
                Value<String> groupsClaim = const Value.absent(),
                Value<String> idpMetadataXml = const Value.absent(),
                Value<String> spEntityId = const Value.absent(),
                Value<String> emailAttribute = const Value.absent(),
                Value<String> displayNameAttribute = const Value.absent(),
                Value<String> groupsAttribute = const Value.absent(),
                Value<String> defaultRole = const Value.absent(),
                Value<String> groupRoleMap = const Value.absent(),
                Value<bool> autoMember = const Value.absent(),
                Value<bool> allowJit = const Value.absent(),
                Value<bool> allowIdpInitiated = const Value.absent(),
                Value<bool> wantResponseSigned = const Value.absent(),
                Value<int> clockSkewSeconds = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SsoConnectionsTableCompanion.insert(
                id: id,
                kind: kind,
                enabled: enabled,
                issuer: issuer,
                clientId: clientId,
                groupsClaim: groupsClaim,
                idpMetadataXml: idpMetadataXml,
                spEntityId: spEntityId,
                emailAttribute: emailAttribute,
                displayNameAttribute: displayNameAttribute,
                groupsAttribute: groupsAttribute,
                defaultRole: defaultRole,
                groupRoleMap: groupRoleMap,
                autoMember: autoMember,
                allowJit: allowJit,
                allowIdpInitiated: allowIdpInitiated,
                wantResponseSigned: wantResponseSigned,
                clockSkewSeconds: clockSkewSeconds,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SsoConnectionsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$GlobalDatabase,
      $SsoConnectionsTableTable,
      SsoConnectionsTableData,
      $$SsoConnectionsTableTableFilterComposer,
      $$SsoConnectionsTableTableOrderingComposer,
      $$SsoConnectionsTableTableAnnotationComposer,
      $$SsoConnectionsTableTableCreateCompanionBuilder,
      $$SsoConnectionsTableTableUpdateCompanionBuilder,
      (
        SsoConnectionsTableData,
        BaseReferences<
          _$GlobalDatabase,
          $SsoConnectionsTableTable,
          SsoConnectionsTableData
        >,
      ),
      SsoConnectionsTableData,
      PrefetchHooks Function()
    >;

class $GlobalDatabaseManager {
  final _$GlobalDatabase _db;
  $GlobalDatabaseManager(this._db);
  $$WorkspacesTableTableTableManager get workspacesTable =>
      $$WorkspacesTableTableTableManager(_db, _db.workspacesTable);
  $$UsersTableTableTableManager get usersTable =>
      $$UsersTableTableTableManager(_db, _db.usersTable);
  $$UserPreferencesTableTableTableManager get userPreferencesTable =>
      $$UserPreferencesTableTableTableManager(_db, _db.userPreferencesTable);
  $$PairedDevicesTableTableTableManager get pairedDevicesTable =>
      $$PairedDevicesTableTableTableManager(_db, _db.pairedDevicesTable);
  $$RssFeedsTableTableTableManager get rssFeedsTable =>
      $$RssFeedsTableTableTableManager(_db, _db.rssFeedsTable);
  $$RssArticlesTableTableTableManager get rssArticlesTable =>
      $$RssArticlesTableTableTableManager(_db, _db.rssArticlesTable);
  $$WorkersTableTableTableManager get workersTable =>
      $$WorkersTableTableTableManager(_db, _db.workersTable);
  $$JobsTableTableTableManager get jobsTable =>
      $$JobsTableTableTableManager(_db, _db.jobsTable);
  $$PlacementLogTableTableTableManager get placementLogTable =>
      $$PlacementLogTableTableTableManager(_db, _db.placementLogTable);
  $$WorkspaceRoutesTableTableTableManager get workspaceRoutesTable =>
      $$WorkspaceRoutesTableTableTableManager(_db, _db.workspaceRoutesTable);
  $$ServerMetaTableTableTableManager get serverMetaTable =>
      $$ServerMetaTableTableTableManager(_db, _db.serverMetaTable);
  $$ServerSettingsTableTableTableManager get serverSettingsTable =>
      $$ServerSettingsTableTableTableManager(_db, _db.serverSettingsTable);
  $$SsoConnectionsTableTableTableManager get ssoConnectionsTable =>
      $$SsoConnectionsTableTableTableManager(_db, _db.ssoConnectionsTable);
}
