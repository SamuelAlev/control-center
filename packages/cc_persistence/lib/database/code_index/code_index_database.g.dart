// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'code_index_database.dart';

// ignore_for_file: type=lint
class $CodeSymbolsTableTable extends CodeSymbolsTable
    with TableInfo<$CodeSymbolsTableTable, CodeSymbolsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CodeSymbolsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _repoIdMeta = const VerificationMeta('repoId');
  @override
  late final GeneratedColumn<String> repoId = GeneratedColumn<String>(
    'repo_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _checkoutIdMeta = const VerificationMeta(
    'checkoutId',
  );
  @override
  late final GeneratedColumn<String> checkoutId = GeneratedColumn<String>(
    'checkout_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _qualifiedNameMeta = const VerificationMeta(
    'qualifiedName',
  );
  @override
  late final GeneratedColumn<String> qualifiedName = GeneratedColumn<String>(
    'qualified_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startLineMeta = const VerificationMeta(
    'startLine',
  );
  @override
  late final GeneratedColumn<int> startLine = GeneratedColumn<int>(
    'start_line',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endLineMeta = const VerificationMeta(
    'endLine',
  );
  @override
  late final GeneratedColumn<int> endLine = GeneratedColumn<int>(
    'end_line',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _signatureMeta = const VerificationMeta(
    'signature',
  );
  @override
  late final GeneratedColumn<String> signature = GeneratedColumn<String>(
    'signature',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _docstringMeta = const VerificationMeta(
    'docstring',
  );
  @override
  late final GeneratedColumn<String> docstring = GeneratedColumn<String>(
    'docstring',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _parentNameMeta = const VerificationMeta(
    'parentName',
  );
  @override
  late final GeneratedColumn<String> parentName = GeneratedColumn<String>(
    'parent_name',
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
    repoId,
    checkoutId,
    kind,
    name,
    qualifiedName,
    filePath,
    language,
    startLine,
    endLine,
    signature,
    docstring,
    parentName,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'code_symbols';
  @override
  VerificationContext validateIntegrity(
    Insertable<CodeSymbolsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('repo_id')) {
      context.handle(
        _repoIdMeta,
        repoId.isAcceptableOrUnknown(data['repo_id']!, _repoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_repoIdMeta);
    }
    if (data.containsKey('checkout_id')) {
      context.handle(
        _checkoutIdMeta,
        checkoutId.isAcceptableOrUnknown(data['checkout_id']!, _checkoutIdMeta),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('qualified_name')) {
      context.handle(
        _qualifiedNameMeta,
        qualifiedName.isAcceptableOrUnknown(
          data['qualified_name']!,
          _qualifiedNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_qualifiedNameMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    } else if (isInserting) {
      context.missing(_languageMeta);
    }
    if (data.containsKey('start_line')) {
      context.handle(
        _startLineMeta,
        startLine.isAcceptableOrUnknown(data['start_line']!, _startLineMeta),
      );
    } else if (isInserting) {
      context.missing(_startLineMeta);
    }
    if (data.containsKey('end_line')) {
      context.handle(
        _endLineMeta,
        endLine.isAcceptableOrUnknown(data['end_line']!, _endLineMeta),
      );
    } else if (isInserting) {
      context.missing(_endLineMeta);
    }
    if (data.containsKey('signature')) {
      context.handle(
        _signatureMeta,
        signature.isAcceptableOrUnknown(data['signature']!, _signatureMeta),
      );
    }
    if (data.containsKey('docstring')) {
      context.handle(
        _docstringMeta,
        docstring.isAcceptableOrUnknown(data['docstring']!, _docstringMeta),
      );
    }
    if (data.containsKey('parent_name')) {
      context.handle(
        _parentNameMeta,
        parentName.isAcceptableOrUnknown(data['parent_name']!, _parentNameMeta),
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
  CodeSymbolsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CodeSymbolsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      repoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repo_id'],
      )!,
      checkoutId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checkout_id'],
      ),
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      qualifiedName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}qualified_name'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      startLine: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_line'],
      )!,
      endLine: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_line'],
      )!,
      signature: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}signature'],
      )!,
      docstring: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}docstring'],
      ),
      parentName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_name'],
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
  $CodeSymbolsTableTable createAlias(String alias) {
    return $CodeSymbolsTableTable(attachedDatabase, alias);
  }
}

class CodeSymbolsTableData extends DataClass
    implements Insertable<CodeSymbolsTableData> {
  /// Deterministic content-addressed id (see `code_graph_ids`); the
  /// worktree partition's ids add a checkoutId segment.
  final String id;

  /// The repository (`repos.id` in `workspace.db`).
  final String repoId;

  /// The checkout partition: NULL = the linked checkout, otherwise an
  /// `isolated_repos` row id of `workspace.db` (one conversation/PR worktree).
  final String? checkoutId;

  /// `CodeSymbolKind.name`.
  final String kind;

  /// Simple (unqualified) symbol name.
  final String name;

  /// Fully-qualified name (e.g. `PipelineEngine.start`).
  final String qualifiedName;

  /// Repo-relative source file path.
  final String filePath;

  /// Source language id (e.g. `dart`).
  final String language;

  /// 1-based start line of the symbol's span.
  final int startLine;

  /// 1-based end line of the symbol's span.
  final int endLine;

  /// Declaration signature, when extractable.
  final String signature;

  /// Leading doc comment, when present.
  final String? docstring;

  /// Qualified name of the lexically enclosing symbol, when any.
  final String? parentName;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last update timestamp.
  final DateTime updatedAt;
  const CodeSymbolsTableData({
    required this.id,
    required this.repoId,
    this.checkoutId,
    required this.kind,
    required this.name,
    required this.qualifiedName,
    required this.filePath,
    required this.language,
    required this.startLine,
    required this.endLine,
    required this.signature,
    this.docstring,
    this.parentName,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['repo_id'] = Variable<String>(repoId);
    if (!nullToAbsent || checkoutId != null) {
      map['checkout_id'] = Variable<String>(checkoutId);
    }
    map['kind'] = Variable<String>(kind);
    map['name'] = Variable<String>(name);
    map['qualified_name'] = Variable<String>(qualifiedName);
    map['file_path'] = Variable<String>(filePath);
    map['language'] = Variable<String>(language);
    map['start_line'] = Variable<int>(startLine);
    map['end_line'] = Variable<int>(endLine);
    map['signature'] = Variable<String>(signature);
    if (!nullToAbsent || docstring != null) {
      map['docstring'] = Variable<String>(docstring);
    }
    if (!nullToAbsent || parentName != null) {
      map['parent_name'] = Variable<String>(parentName);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CodeSymbolsTableCompanion toCompanion(bool nullToAbsent) {
    return CodeSymbolsTableCompanion(
      id: Value(id),
      repoId: Value(repoId),
      checkoutId: checkoutId == null && nullToAbsent
          ? const Value.absent()
          : Value(checkoutId),
      kind: Value(kind),
      name: Value(name),
      qualifiedName: Value(qualifiedName),
      filePath: Value(filePath),
      language: Value(language),
      startLine: Value(startLine),
      endLine: Value(endLine),
      signature: Value(signature),
      docstring: docstring == null && nullToAbsent
          ? const Value.absent()
          : Value(docstring),
      parentName: parentName == null && nullToAbsent
          ? const Value.absent()
          : Value(parentName),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CodeSymbolsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CodeSymbolsTableData(
      id: serializer.fromJson<String>(json['id']),
      repoId: serializer.fromJson<String>(json['repoId']),
      checkoutId: serializer.fromJson<String?>(json['checkoutId']),
      kind: serializer.fromJson<String>(json['kind']),
      name: serializer.fromJson<String>(json['name']),
      qualifiedName: serializer.fromJson<String>(json['qualifiedName']),
      filePath: serializer.fromJson<String>(json['filePath']),
      language: serializer.fromJson<String>(json['language']),
      startLine: serializer.fromJson<int>(json['startLine']),
      endLine: serializer.fromJson<int>(json['endLine']),
      signature: serializer.fromJson<String>(json['signature']),
      docstring: serializer.fromJson<String?>(json['docstring']),
      parentName: serializer.fromJson<String?>(json['parentName']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'repoId': serializer.toJson<String>(repoId),
      'checkoutId': serializer.toJson<String?>(checkoutId),
      'kind': serializer.toJson<String>(kind),
      'name': serializer.toJson<String>(name),
      'qualifiedName': serializer.toJson<String>(qualifiedName),
      'filePath': serializer.toJson<String>(filePath),
      'language': serializer.toJson<String>(language),
      'startLine': serializer.toJson<int>(startLine),
      'endLine': serializer.toJson<int>(endLine),
      'signature': serializer.toJson<String>(signature),
      'docstring': serializer.toJson<String?>(docstring),
      'parentName': serializer.toJson<String?>(parentName),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CodeSymbolsTableData copyWith({
    String? id,
    String? repoId,
    Value<String?> checkoutId = const Value.absent(),
    String? kind,
    String? name,
    String? qualifiedName,
    String? filePath,
    String? language,
    int? startLine,
    int? endLine,
    String? signature,
    Value<String?> docstring = const Value.absent(),
    Value<String?> parentName = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CodeSymbolsTableData(
    id: id ?? this.id,
    repoId: repoId ?? this.repoId,
    checkoutId: checkoutId.present ? checkoutId.value : this.checkoutId,
    kind: kind ?? this.kind,
    name: name ?? this.name,
    qualifiedName: qualifiedName ?? this.qualifiedName,
    filePath: filePath ?? this.filePath,
    language: language ?? this.language,
    startLine: startLine ?? this.startLine,
    endLine: endLine ?? this.endLine,
    signature: signature ?? this.signature,
    docstring: docstring.present ? docstring.value : this.docstring,
    parentName: parentName.present ? parentName.value : this.parentName,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CodeSymbolsTableData copyWithCompanion(CodeSymbolsTableCompanion data) {
    return CodeSymbolsTableData(
      id: data.id.present ? data.id.value : this.id,
      repoId: data.repoId.present ? data.repoId.value : this.repoId,
      checkoutId: data.checkoutId.present
          ? data.checkoutId.value
          : this.checkoutId,
      kind: data.kind.present ? data.kind.value : this.kind,
      name: data.name.present ? data.name.value : this.name,
      qualifiedName: data.qualifiedName.present
          ? data.qualifiedName.value
          : this.qualifiedName,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      language: data.language.present ? data.language.value : this.language,
      startLine: data.startLine.present ? data.startLine.value : this.startLine,
      endLine: data.endLine.present ? data.endLine.value : this.endLine,
      signature: data.signature.present ? data.signature.value : this.signature,
      docstring: data.docstring.present ? data.docstring.value : this.docstring,
      parentName: data.parentName.present
          ? data.parentName.value
          : this.parentName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CodeSymbolsTableData(')
          ..write('id: $id, ')
          ..write('repoId: $repoId, ')
          ..write('checkoutId: $checkoutId, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('qualifiedName: $qualifiedName, ')
          ..write('filePath: $filePath, ')
          ..write('language: $language, ')
          ..write('startLine: $startLine, ')
          ..write('endLine: $endLine, ')
          ..write('signature: $signature, ')
          ..write('docstring: $docstring, ')
          ..write('parentName: $parentName, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    repoId,
    checkoutId,
    kind,
    name,
    qualifiedName,
    filePath,
    language,
    startLine,
    endLine,
    signature,
    docstring,
    parentName,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CodeSymbolsTableData &&
          other.id == this.id &&
          other.repoId == this.repoId &&
          other.checkoutId == this.checkoutId &&
          other.kind == this.kind &&
          other.name == this.name &&
          other.qualifiedName == this.qualifiedName &&
          other.filePath == this.filePath &&
          other.language == this.language &&
          other.startLine == this.startLine &&
          other.endLine == this.endLine &&
          other.signature == this.signature &&
          other.docstring == this.docstring &&
          other.parentName == this.parentName &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CodeSymbolsTableCompanion extends UpdateCompanion<CodeSymbolsTableData> {
  final Value<String> id;
  final Value<String> repoId;
  final Value<String?> checkoutId;
  final Value<String> kind;
  final Value<String> name;
  final Value<String> qualifiedName;
  final Value<String> filePath;
  final Value<String> language;
  final Value<int> startLine;
  final Value<int> endLine;
  final Value<String> signature;
  final Value<String?> docstring;
  final Value<String?> parentName;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CodeSymbolsTableCompanion({
    this.id = const Value.absent(),
    this.repoId = const Value.absent(),
    this.checkoutId = const Value.absent(),
    this.kind = const Value.absent(),
    this.name = const Value.absent(),
    this.qualifiedName = const Value.absent(),
    this.filePath = const Value.absent(),
    this.language = const Value.absent(),
    this.startLine = const Value.absent(),
    this.endLine = const Value.absent(),
    this.signature = const Value.absent(),
    this.docstring = const Value.absent(),
    this.parentName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CodeSymbolsTableCompanion.insert({
    required String id,
    required String repoId,
    this.checkoutId = const Value.absent(),
    required String kind,
    required String name,
    required String qualifiedName,
    required String filePath,
    required String language,
    required int startLine,
    required int endLine,
    this.signature = const Value.absent(),
    this.docstring = const Value.absent(),
    this.parentName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       repoId = Value(repoId),
       kind = Value(kind),
       name = Value(name),
       qualifiedName = Value(qualifiedName),
       filePath = Value(filePath),
       language = Value(language),
       startLine = Value(startLine),
       endLine = Value(endLine);
  static Insertable<CodeSymbolsTableData> custom({
    Expression<String>? id,
    Expression<String>? repoId,
    Expression<String>? checkoutId,
    Expression<String>? kind,
    Expression<String>? name,
    Expression<String>? qualifiedName,
    Expression<String>? filePath,
    Expression<String>? language,
    Expression<int>? startLine,
    Expression<int>? endLine,
    Expression<String>? signature,
    Expression<String>? docstring,
    Expression<String>? parentName,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (repoId != null) 'repo_id': repoId,
      if (checkoutId != null) 'checkout_id': checkoutId,
      if (kind != null) 'kind': kind,
      if (name != null) 'name': name,
      if (qualifiedName != null) 'qualified_name': qualifiedName,
      if (filePath != null) 'file_path': filePath,
      if (language != null) 'language': language,
      if (startLine != null) 'start_line': startLine,
      if (endLine != null) 'end_line': endLine,
      if (signature != null) 'signature': signature,
      if (docstring != null) 'docstring': docstring,
      if (parentName != null) 'parent_name': parentName,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CodeSymbolsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? repoId,
    Value<String?>? checkoutId,
    Value<String>? kind,
    Value<String>? name,
    Value<String>? qualifiedName,
    Value<String>? filePath,
    Value<String>? language,
    Value<int>? startLine,
    Value<int>? endLine,
    Value<String>? signature,
    Value<String?>? docstring,
    Value<String?>? parentName,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CodeSymbolsTableCompanion(
      id: id ?? this.id,
      repoId: repoId ?? this.repoId,
      checkoutId: checkoutId ?? this.checkoutId,
      kind: kind ?? this.kind,
      name: name ?? this.name,
      qualifiedName: qualifiedName ?? this.qualifiedName,
      filePath: filePath ?? this.filePath,
      language: language ?? this.language,
      startLine: startLine ?? this.startLine,
      endLine: endLine ?? this.endLine,
      signature: signature ?? this.signature,
      docstring: docstring ?? this.docstring,
      parentName: parentName ?? this.parentName,
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
    if (repoId.present) {
      map['repo_id'] = Variable<String>(repoId.value);
    }
    if (checkoutId.present) {
      map['checkout_id'] = Variable<String>(checkoutId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (qualifiedName.present) {
      map['qualified_name'] = Variable<String>(qualifiedName.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (startLine.present) {
      map['start_line'] = Variable<int>(startLine.value);
    }
    if (endLine.present) {
      map['end_line'] = Variable<int>(endLine.value);
    }
    if (signature.present) {
      map['signature'] = Variable<String>(signature.value);
    }
    if (docstring.present) {
      map['docstring'] = Variable<String>(docstring.value);
    }
    if (parentName.present) {
      map['parent_name'] = Variable<String>(parentName.value);
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
    return (StringBuffer('CodeSymbolsTableCompanion(')
          ..write('id: $id, ')
          ..write('repoId: $repoId, ')
          ..write('checkoutId: $checkoutId, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('qualifiedName: $qualifiedName, ')
          ..write('filePath: $filePath, ')
          ..write('language: $language, ')
          ..write('startLine: $startLine, ')
          ..write('endLine: $endLine, ')
          ..write('signature: $signature, ')
          ..write('docstring: $docstring, ')
          ..write('parentName: $parentName, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CodeSymbolEmbeddingsTableTable extends CodeSymbolEmbeddingsTable
    with
        TableInfo<
          $CodeSymbolEmbeddingsTableTable,
          CodeSymbolEmbeddingsTableData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CodeSymbolEmbeddingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _symbolIdMeta = const VerificationMeta(
    'symbolId',
  );
  @override
  late final GeneratedColumn<String> symbolId = GeneratedColumn<String>(
    'symbol_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES code_symbols (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _embeddingMeta = const VerificationMeta(
    'embedding',
  );
  @override
  late final GeneratedColumn<Uint8List> embedding = GeneratedColumn<Uint8List>(
    'embedding',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [symbolId, embedding];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'code_symbol_embeddings';
  @override
  VerificationContext validateIntegrity(
    Insertable<CodeSymbolEmbeddingsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('symbol_id')) {
      context.handle(
        _symbolIdMeta,
        symbolId.isAcceptableOrUnknown(data['symbol_id']!, _symbolIdMeta),
      );
    } else if (isInserting) {
      context.missing(_symbolIdMeta);
    }
    if (data.containsKey('embedding')) {
      context.handle(
        _embeddingMeta,
        embedding.isAcceptableOrUnknown(data['embedding']!, _embeddingMeta),
      );
    } else if (isInserting) {
      context.missing(_embeddingMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {symbolId};
  @override
  CodeSymbolEmbeddingsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CodeSymbolEmbeddingsTableData(
      symbolId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}symbol_id'],
      )!,
      embedding: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}embedding'],
      )!,
    );
  }

  @override
  $CodeSymbolEmbeddingsTableTable createAlias(String alias) {
    return $CodeSymbolEmbeddingsTableTable(attachedDatabase, alias);
  }
}

class CodeSymbolEmbeddingsTableData extends DataClass
    implements Insertable<CodeSymbolEmbeddingsTableData> {
  /// The embedded symbol. `ON DELETE CASCADE`: the vector describes the
  /// symbol's text, and every delete of a file, a partition or a repo takes
  /// its vectors with it.
  final String symbolId;

  /// The vector: FLOAT32 bytes of the embedding of the symbol's qualified
  /// name, signature and doc comment.
  final Uint8List embedding;
  const CodeSymbolEmbeddingsTableData({
    required this.symbolId,
    required this.embedding,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['symbol_id'] = Variable<String>(symbolId);
    map['embedding'] = Variable<Uint8List>(embedding);
    return map;
  }

  CodeSymbolEmbeddingsTableCompanion toCompanion(bool nullToAbsent) {
    return CodeSymbolEmbeddingsTableCompanion(
      symbolId: Value(symbolId),
      embedding: Value(embedding),
    );
  }

  factory CodeSymbolEmbeddingsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CodeSymbolEmbeddingsTableData(
      symbolId: serializer.fromJson<String>(json['symbolId']),
      embedding: serializer.fromJson<Uint8List>(json['embedding']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'symbolId': serializer.toJson<String>(symbolId),
      'embedding': serializer.toJson<Uint8List>(embedding),
    };
  }

  CodeSymbolEmbeddingsTableData copyWith({
    String? symbolId,
    Uint8List? embedding,
  }) => CodeSymbolEmbeddingsTableData(
    symbolId: symbolId ?? this.symbolId,
    embedding: embedding ?? this.embedding,
  );
  CodeSymbolEmbeddingsTableData copyWithCompanion(
    CodeSymbolEmbeddingsTableCompanion data,
  ) {
    return CodeSymbolEmbeddingsTableData(
      symbolId: data.symbolId.present ? data.symbolId.value : this.symbolId,
      embedding: data.embedding.present ? data.embedding.value : this.embedding,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CodeSymbolEmbeddingsTableData(')
          ..write('symbolId: $symbolId, ')
          ..write('embedding: $embedding')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(symbolId, $driftBlobEquality.hash(embedding));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CodeSymbolEmbeddingsTableData &&
          other.symbolId == this.symbolId &&
          $driftBlobEquality.equals(other.embedding, this.embedding));
}

class CodeSymbolEmbeddingsTableCompanion
    extends UpdateCompanion<CodeSymbolEmbeddingsTableData> {
  final Value<String> symbolId;
  final Value<Uint8List> embedding;
  final Value<int> rowid;
  const CodeSymbolEmbeddingsTableCompanion({
    this.symbolId = const Value.absent(),
    this.embedding = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CodeSymbolEmbeddingsTableCompanion.insert({
    required String symbolId,
    required Uint8List embedding,
    this.rowid = const Value.absent(),
  }) : symbolId = Value(symbolId),
       embedding = Value(embedding);
  static Insertable<CodeSymbolEmbeddingsTableData> custom({
    Expression<String>? symbolId,
    Expression<Uint8List>? embedding,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (symbolId != null) 'symbol_id': symbolId,
      if (embedding != null) 'embedding': embedding,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CodeSymbolEmbeddingsTableCompanion copyWith({
    Value<String>? symbolId,
    Value<Uint8List>? embedding,
    Value<int>? rowid,
  }) {
    return CodeSymbolEmbeddingsTableCompanion(
      symbolId: symbolId ?? this.symbolId,
      embedding: embedding ?? this.embedding,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (symbolId.present) {
      map['symbol_id'] = Variable<String>(symbolId.value);
    }
    if (embedding.present) {
      map['embedding'] = Variable<Uint8List>(embedding.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CodeSymbolEmbeddingsTableCompanion(')
          ..write('symbolId: $symbolId, ')
          ..write('embedding: $embedding, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CodeEdgesTableTable extends CodeEdgesTable
    with TableInfo<$CodeEdgesTableTable, CodeEdgesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CodeEdgesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _repoIdMeta = const VerificationMeta('repoId');
  @override
  late final GeneratedColumn<String> repoId = GeneratedColumn<String>(
    'repo_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _checkoutIdMeta = const VerificationMeta(
    'checkoutId',
  );
  @override
  late final GeneratedColumn<String> checkoutId = GeneratedColumn<String>(
    'checkout_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceSymbolIdMeta = const VerificationMeta(
    'sourceSymbolId',
  );
  @override
  late final GeneratedColumn<String> sourceSymbolId = GeneratedColumn<String>(
    'source_symbol_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceFilePathMeta = const VerificationMeta(
    'sourceFilePath',
  );
  @override
  late final GeneratedColumn<String> sourceFilePath = GeneratedColumn<String>(
    'source_file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _targetSymbolIdMeta = const VerificationMeta(
    'targetSymbolId',
  );
  @override
  late final GeneratedColumn<String> targetSymbolId = GeneratedColumn<String>(
    'target_symbol_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetNameMeta = const VerificationMeta(
    'targetName',
  );
  @override
  late final GeneratedColumn<String> targetName = GeneratedColumn<String>(
    'target_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _metadataMeta = const VerificationMeta(
    'metadata',
  );
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
    'metadata',
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
    repoId,
    checkoutId,
    sourceSymbolId,
    sourceFilePath,
    targetSymbolId,
    targetName,
    kind,
    metadata,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'code_edges';
  @override
  VerificationContext validateIntegrity(
    Insertable<CodeEdgesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('repo_id')) {
      context.handle(
        _repoIdMeta,
        repoId.isAcceptableOrUnknown(data['repo_id']!, _repoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_repoIdMeta);
    }
    if (data.containsKey('checkout_id')) {
      context.handle(
        _checkoutIdMeta,
        checkoutId.isAcceptableOrUnknown(data['checkout_id']!, _checkoutIdMeta),
      );
    }
    if (data.containsKey('source_symbol_id')) {
      context.handle(
        _sourceSymbolIdMeta,
        sourceSymbolId.isAcceptableOrUnknown(
          data['source_symbol_id']!,
          _sourceSymbolIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceSymbolIdMeta);
    }
    if (data.containsKey('source_file_path')) {
      context.handle(
        _sourceFilePathMeta,
        sourceFilePath.isAcceptableOrUnknown(
          data['source_file_path']!,
          _sourceFilePathMeta,
        ),
      );
    }
    if (data.containsKey('target_symbol_id')) {
      context.handle(
        _targetSymbolIdMeta,
        targetSymbolId.isAcceptableOrUnknown(
          data['target_symbol_id']!,
          _targetSymbolIdMeta,
        ),
      );
    }
    if (data.containsKey('target_name')) {
      context.handle(
        _targetNameMeta,
        targetName.isAcceptableOrUnknown(data['target_name']!, _targetNameMeta),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('metadata')) {
      context.handle(
        _metadataMeta,
        metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta),
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
  CodeEdgesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CodeEdgesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      repoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repo_id'],
      )!,
      checkoutId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checkout_id'],
      ),
      sourceSymbolId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_symbol_id'],
      )!,
      sourceFilePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_file_path'],
      )!,
      targetSymbolId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_symbol_id'],
      ),
      targetName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_name'],
      ),
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      metadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CodeEdgesTableTable createAlias(String alias) {
    return $CodeEdgesTableTable(attachedDatabase, alias);
  }
}

class CodeEdgesTableData extends DataClass
    implements Insertable<CodeEdgesTableData> {
  /// Deterministic content-addressed id (see `code_graph_ids`); the
  /// worktree partition's ids add a checkoutId segment.
  final String id;

  /// The repository (`repos.id` in `workspace.db`).
  final String repoId;

  /// The checkout partition: NULL = the linked checkout, otherwise an
  /// `isolated_repos` row id. Edges never cross partitions (ids embed the
  /// checkout), so a worktree's graph is self-contained.
  final String? checkoutId;

  /// `code_symbols.id` of the edge source (or a `<file>` pseudo-id for imports).
  final String sourceSymbolId;

  /// Repo-relative path of the file the source symbol lives in. Lets the
  /// indexer delete a file's edges in one statement during incremental
  /// re-index (edges otherwise carry no file path).
  final String sourceFilePath;

  /// Resolved `code_symbols.id` of the target, when known.
  final String? targetSymbolId;

  /// Unresolved target name / import URI (set when [targetSymbolId] is NULL).
  final String? targetName;

  /// `CodeEdgeKind.name`.
  final String kind;

  /// Optional JSON metadata (e.g. call-site line).
  final String? metadata;

  /// Creation timestamp.
  final DateTime createdAt;
  const CodeEdgesTableData({
    required this.id,
    required this.repoId,
    this.checkoutId,
    required this.sourceSymbolId,
    required this.sourceFilePath,
    this.targetSymbolId,
    this.targetName,
    required this.kind,
    this.metadata,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['repo_id'] = Variable<String>(repoId);
    if (!nullToAbsent || checkoutId != null) {
      map['checkout_id'] = Variable<String>(checkoutId);
    }
    map['source_symbol_id'] = Variable<String>(sourceSymbolId);
    map['source_file_path'] = Variable<String>(sourceFilePath);
    if (!nullToAbsent || targetSymbolId != null) {
      map['target_symbol_id'] = Variable<String>(targetSymbolId);
    }
    if (!nullToAbsent || targetName != null) {
      map['target_name'] = Variable<String>(targetName);
    }
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CodeEdgesTableCompanion toCompanion(bool nullToAbsent) {
    return CodeEdgesTableCompanion(
      id: Value(id),
      repoId: Value(repoId),
      checkoutId: checkoutId == null && nullToAbsent
          ? const Value.absent()
          : Value(checkoutId),
      sourceSymbolId: Value(sourceSymbolId),
      sourceFilePath: Value(sourceFilePath),
      targetSymbolId: targetSymbolId == null && nullToAbsent
          ? const Value.absent()
          : Value(targetSymbolId),
      targetName: targetName == null && nullToAbsent
          ? const Value.absent()
          : Value(targetName),
      kind: Value(kind),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
      createdAt: Value(createdAt),
    );
  }

  factory CodeEdgesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CodeEdgesTableData(
      id: serializer.fromJson<String>(json['id']),
      repoId: serializer.fromJson<String>(json['repoId']),
      checkoutId: serializer.fromJson<String?>(json['checkoutId']),
      sourceSymbolId: serializer.fromJson<String>(json['sourceSymbolId']),
      sourceFilePath: serializer.fromJson<String>(json['sourceFilePath']),
      targetSymbolId: serializer.fromJson<String?>(json['targetSymbolId']),
      targetName: serializer.fromJson<String?>(json['targetName']),
      kind: serializer.fromJson<String>(json['kind']),
      metadata: serializer.fromJson<String?>(json['metadata']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'repoId': serializer.toJson<String>(repoId),
      'checkoutId': serializer.toJson<String?>(checkoutId),
      'sourceSymbolId': serializer.toJson<String>(sourceSymbolId),
      'sourceFilePath': serializer.toJson<String>(sourceFilePath),
      'targetSymbolId': serializer.toJson<String?>(targetSymbolId),
      'targetName': serializer.toJson<String?>(targetName),
      'kind': serializer.toJson<String>(kind),
      'metadata': serializer.toJson<String?>(metadata),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CodeEdgesTableData copyWith({
    String? id,
    String? repoId,
    Value<String?> checkoutId = const Value.absent(),
    String? sourceSymbolId,
    String? sourceFilePath,
    Value<String?> targetSymbolId = const Value.absent(),
    Value<String?> targetName = const Value.absent(),
    String? kind,
    Value<String?> metadata = const Value.absent(),
    DateTime? createdAt,
  }) => CodeEdgesTableData(
    id: id ?? this.id,
    repoId: repoId ?? this.repoId,
    checkoutId: checkoutId.present ? checkoutId.value : this.checkoutId,
    sourceSymbolId: sourceSymbolId ?? this.sourceSymbolId,
    sourceFilePath: sourceFilePath ?? this.sourceFilePath,
    targetSymbolId: targetSymbolId.present
        ? targetSymbolId.value
        : this.targetSymbolId,
    targetName: targetName.present ? targetName.value : this.targetName,
    kind: kind ?? this.kind,
    metadata: metadata.present ? metadata.value : this.metadata,
    createdAt: createdAt ?? this.createdAt,
  );
  CodeEdgesTableData copyWithCompanion(CodeEdgesTableCompanion data) {
    return CodeEdgesTableData(
      id: data.id.present ? data.id.value : this.id,
      repoId: data.repoId.present ? data.repoId.value : this.repoId,
      checkoutId: data.checkoutId.present
          ? data.checkoutId.value
          : this.checkoutId,
      sourceSymbolId: data.sourceSymbolId.present
          ? data.sourceSymbolId.value
          : this.sourceSymbolId,
      sourceFilePath: data.sourceFilePath.present
          ? data.sourceFilePath.value
          : this.sourceFilePath,
      targetSymbolId: data.targetSymbolId.present
          ? data.targetSymbolId.value
          : this.targetSymbolId,
      targetName: data.targetName.present
          ? data.targetName.value
          : this.targetName,
      kind: data.kind.present ? data.kind.value : this.kind,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CodeEdgesTableData(')
          ..write('id: $id, ')
          ..write('repoId: $repoId, ')
          ..write('checkoutId: $checkoutId, ')
          ..write('sourceSymbolId: $sourceSymbolId, ')
          ..write('sourceFilePath: $sourceFilePath, ')
          ..write('targetSymbolId: $targetSymbolId, ')
          ..write('targetName: $targetName, ')
          ..write('kind: $kind, ')
          ..write('metadata: $metadata, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    repoId,
    checkoutId,
    sourceSymbolId,
    sourceFilePath,
    targetSymbolId,
    targetName,
    kind,
    metadata,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CodeEdgesTableData &&
          other.id == this.id &&
          other.repoId == this.repoId &&
          other.checkoutId == this.checkoutId &&
          other.sourceSymbolId == this.sourceSymbolId &&
          other.sourceFilePath == this.sourceFilePath &&
          other.targetSymbolId == this.targetSymbolId &&
          other.targetName == this.targetName &&
          other.kind == this.kind &&
          other.metadata == this.metadata &&
          other.createdAt == this.createdAt);
}

class CodeEdgesTableCompanion extends UpdateCompanion<CodeEdgesTableData> {
  final Value<String> id;
  final Value<String> repoId;
  final Value<String?> checkoutId;
  final Value<String> sourceSymbolId;
  final Value<String> sourceFilePath;
  final Value<String?> targetSymbolId;
  final Value<String?> targetName;
  final Value<String> kind;
  final Value<String?> metadata;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CodeEdgesTableCompanion({
    this.id = const Value.absent(),
    this.repoId = const Value.absent(),
    this.checkoutId = const Value.absent(),
    this.sourceSymbolId = const Value.absent(),
    this.sourceFilePath = const Value.absent(),
    this.targetSymbolId = const Value.absent(),
    this.targetName = const Value.absent(),
    this.kind = const Value.absent(),
    this.metadata = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CodeEdgesTableCompanion.insert({
    required String id,
    required String repoId,
    this.checkoutId = const Value.absent(),
    required String sourceSymbolId,
    this.sourceFilePath = const Value.absent(),
    this.targetSymbolId = const Value.absent(),
    this.targetName = const Value.absent(),
    required String kind,
    this.metadata = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       repoId = Value(repoId),
       sourceSymbolId = Value(sourceSymbolId),
       kind = Value(kind);
  static Insertable<CodeEdgesTableData> custom({
    Expression<String>? id,
    Expression<String>? repoId,
    Expression<String>? checkoutId,
    Expression<String>? sourceSymbolId,
    Expression<String>? sourceFilePath,
    Expression<String>? targetSymbolId,
    Expression<String>? targetName,
    Expression<String>? kind,
    Expression<String>? metadata,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (repoId != null) 'repo_id': repoId,
      if (checkoutId != null) 'checkout_id': checkoutId,
      if (sourceSymbolId != null) 'source_symbol_id': sourceSymbolId,
      if (sourceFilePath != null) 'source_file_path': sourceFilePath,
      if (targetSymbolId != null) 'target_symbol_id': targetSymbolId,
      if (targetName != null) 'target_name': targetName,
      if (kind != null) 'kind': kind,
      if (metadata != null) 'metadata': metadata,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CodeEdgesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? repoId,
    Value<String?>? checkoutId,
    Value<String>? sourceSymbolId,
    Value<String>? sourceFilePath,
    Value<String?>? targetSymbolId,
    Value<String?>? targetName,
    Value<String>? kind,
    Value<String?>? metadata,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return CodeEdgesTableCompanion(
      id: id ?? this.id,
      repoId: repoId ?? this.repoId,
      checkoutId: checkoutId ?? this.checkoutId,
      sourceSymbolId: sourceSymbolId ?? this.sourceSymbolId,
      sourceFilePath: sourceFilePath ?? this.sourceFilePath,
      targetSymbolId: targetSymbolId ?? this.targetSymbolId,
      targetName: targetName ?? this.targetName,
      kind: kind ?? this.kind,
      metadata: metadata ?? this.metadata,
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
    if (repoId.present) {
      map['repo_id'] = Variable<String>(repoId.value);
    }
    if (checkoutId.present) {
      map['checkout_id'] = Variable<String>(checkoutId.value);
    }
    if (sourceSymbolId.present) {
      map['source_symbol_id'] = Variable<String>(sourceSymbolId.value);
    }
    if (sourceFilePath.present) {
      map['source_file_path'] = Variable<String>(sourceFilePath.value);
    }
    if (targetSymbolId.present) {
      map['target_symbol_id'] = Variable<String>(targetSymbolId.value);
    }
    if (targetName.present) {
      map['target_name'] = Variable<String>(targetName.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
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
    return (StringBuffer('CodeEdgesTableCompanion(')
          ..write('id: $id, ')
          ..write('repoId: $repoId, ')
          ..write('checkoutId: $checkoutId, ')
          ..write('sourceSymbolId: $sourceSymbolId, ')
          ..write('sourceFilePath: $sourceFilePath, ')
          ..write('targetSymbolId: $targetSymbolId, ')
          ..write('targetName: $targetName, ')
          ..write('kind: $kind, ')
          ..write('metadata: $metadata, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CodeFilesTableTable extends CodeFilesTable
    with TableInfo<$CodeFilesTableTable, CodeFilesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CodeFilesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _repoIdMeta = const VerificationMeta('repoId');
  @override
  late final GeneratedColumn<String> repoId = GeneratedColumn<String>(
    'repo_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _checkoutIdMeta = const VerificationMeta(
    'checkoutId',
  );
  @override
  late final GeneratedColumn<String> checkoutId = GeneratedColumn<String>(
    'checkout_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentHashMeta = const VerificationMeta(
    'contentHash',
  );
  @override
  late final GeneratedColumn<String> contentHash = GeneratedColumn<String>(
    'content_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _symbolCountMeta = const VerificationMeta(
    'symbolCount',
  );
  @override
  late final GeneratedColumn<int> symbolCount = GeneratedColumn<int>(
    'symbol_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _indexedAtMeta = const VerificationMeta(
    'indexedAt',
  );
  @override
  late final GeneratedColumn<DateTime> indexedAt = GeneratedColumn<DateTime>(
    'indexed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    repoId,
    checkoutId,
    path,
    contentHash,
    symbolCount,
    language,
    indexedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'code_files';
  @override
  VerificationContext validateIntegrity(
    Insertable<CodeFilesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('repo_id')) {
      context.handle(
        _repoIdMeta,
        repoId.isAcceptableOrUnknown(data['repo_id']!, _repoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_repoIdMeta);
    }
    if (data.containsKey('checkout_id')) {
      context.handle(
        _checkoutIdMeta,
        checkoutId.isAcceptableOrUnknown(data['checkout_id']!, _checkoutIdMeta),
      );
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('content_hash')) {
      context.handle(
        _contentHashMeta,
        contentHash.isAcceptableOrUnknown(
          data['content_hash']!,
          _contentHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentHashMeta);
    }
    if (data.containsKey('symbol_count')) {
      context.handle(
        _symbolCountMeta,
        symbolCount.isAcceptableOrUnknown(
          data['symbol_count']!,
          _symbolCountMeta,
        ),
      );
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    }
    if (data.containsKey('indexed_at')) {
      context.handle(
        _indexedAtMeta,
        indexedAt.isAcceptableOrUnknown(data['indexed_at']!, _indexedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CodeFilesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CodeFilesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      repoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repo_id'],
      )!,
      checkoutId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checkout_id'],
      ),
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      contentHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_hash'],
      )!,
      symbolCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}symbol_count'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      indexedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}indexed_at'],
      )!,
    );
  }

  @override
  $CodeFilesTableTable createAlias(String alias) {
    return $CodeFilesTableTable(attachedDatabase, alias);
  }
}

class CodeFilesTableData extends DataClass
    implements Insertable<CodeFilesTableData> {
  /// Deterministic content-addressed id (see `code_graph_ids`); the
  /// worktree partition's ids add a checkoutId segment.
  final String id;

  /// The repository (`repos.id` in `workspace.db`).
  final String repoId;

  /// The checkout partition: NULL = the linked checkout, otherwise an
  /// `isolated_repos` row id.
  final String? checkoutId;

  /// Repo-relative file path.
  final String path;

  /// SHA-256 of the file content at last index time.
  final String contentHash;

  /// Number of symbols extracted from this file.
  final int symbolCount;

  /// Source language id (e.g. `dart`).
  final String language;

  /// Timestamp of the last successful index of this file.
  final DateTime indexedAt;
  const CodeFilesTableData({
    required this.id,
    required this.repoId,
    this.checkoutId,
    required this.path,
    required this.contentHash,
    required this.symbolCount,
    required this.language,
    required this.indexedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['repo_id'] = Variable<String>(repoId);
    if (!nullToAbsent || checkoutId != null) {
      map['checkout_id'] = Variable<String>(checkoutId);
    }
    map['path'] = Variable<String>(path);
    map['content_hash'] = Variable<String>(contentHash);
    map['symbol_count'] = Variable<int>(symbolCount);
    map['language'] = Variable<String>(language);
    map['indexed_at'] = Variable<DateTime>(indexedAt);
    return map;
  }

  CodeFilesTableCompanion toCompanion(bool nullToAbsent) {
    return CodeFilesTableCompanion(
      id: Value(id),
      repoId: Value(repoId),
      checkoutId: checkoutId == null && nullToAbsent
          ? const Value.absent()
          : Value(checkoutId),
      path: Value(path),
      contentHash: Value(contentHash),
      symbolCount: Value(symbolCount),
      language: Value(language),
      indexedAt: Value(indexedAt),
    );
  }

  factory CodeFilesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CodeFilesTableData(
      id: serializer.fromJson<String>(json['id']),
      repoId: serializer.fromJson<String>(json['repoId']),
      checkoutId: serializer.fromJson<String?>(json['checkoutId']),
      path: serializer.fromJson<String>(json['path']),
      contentHash: serializer.fromJson<String>(json['contentHash']),
      symbolCount: serializer.fromJson<int>(json['symbolCount']),
      language: serializer.fromJson<String>(json['language']),
      indexedAt: serializer.fromJson<DateTime>(json['indexedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'repoId': serializer.toJson<String>(repoId),
      'checkoutId': serializer.toJson<String?>(checkoutId),
      'path': serializer.toJson<String>(path),
      'contentHash': serializer.toJson<String>(contentHash),
      'symbolCount': serializer.toJson<int>(symbolCount),
      'language': serializer.toJson<String>(language),
      'indexedAt': serializer.toJson<DateTime>(indexedAt),
    };
  }

  CodeFilesTableData copyWith({
    String? id,
    String? repoId,
    Value<String?> checkoutId = const Value.absent(),
    String? path,
    String? contentHash,
    int? symbolCount,
    String? language,
    DateTime? indexedAt,
  }) => CodeFilesTableData(
    id: id ?? this.id,
    repoId: repoId ?? this.repoId,
    checkoutId: checkoutId.present ? checkoutId.value : this.checkoutId,
    path: path ?? this.path,
    contentHash: contentHash ?? this.contentHash,
    symbolCount: symbolCount ?? this.symbolCount,
    language: language ?? this.language,
    indexedAt: indexedAt ?? this.indexedAt,
  );
  CodeFilesTableData copyWithCompanion(CodeFilesTableCompanion data) {
    return CodeFilesTableData(
      id: data.id.present ? data.id.value : this.id,
      repoId: data.repoId.present ? data.repoId.value : this.repoId,
      checkoutId: data.checkoutId.present
          ? data.checkoutId.value
          : this.checkoutId,
      path: data.path.present ? data.path.value : this.path,
      contentHash: data.contentHash.present
          ? data.contentHash.value
          : this.contentHash,
      symbolCount: data.symbolCount.present
          ? data.symbolCount.value
          : this.symbolCount,
      language: data.language.present ? data.language.value : this.language,
      indexedAt: data.indexedAt.present ? data.indexedAt.value : this.indexedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CodeFilesTableData(')
          ..write('id: $id, ')
          ..write('repoId: $repoId, ')
          ..write('checkoutId: $checkoutId, ')
          ..write('path: $path, ')
          ..write('contentHash: $contentHash, ')
          ..write('symbolCount: $symbolCount, ')
          ..write('language: $language, ')
          ..write('indexedAt: $indexedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    repoId,
    checkoutId,
    path,
    contentHash,
    symbolCount,
    language,
    indexedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CodeFilesTableData &&
          other.id == this.id &&
          other.repoId == this.repoId &&
          other.checkoutId == this.checkoutId &&
          other.path == this.path &&
          other.contentHash == this.contentHash &&
          other.symbolCount == this.symbolCount &&
          other.language == this.language &&
          other.indexedAt == this.indexedAt);
}

class CodeFilesTableCompanion extends UpdateCompanion<CodeFilesTableData> {
  final Value<String> id;
  final Value<String> repoId;
  final Value<String?> checkoutId;
  final Value<String> path;
  final Value<String> contentHash;
  final Value<int> symbolCount;
  final Value<String> language;
  final Value<DateTime> indexedAt;
  final Value<int> rowid;
  const CodeFilesTableCompanion({
    this.id = const Value.absent(),
    this.repoId = const Value.absent(),
    this.checkoutId = const Value.absent(),
    this.path = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.symbolCount = const Value.absent(),
    this.language = const Value.absent(),
    this.indexedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CodeFilesTableCompanion.insert({
    required String id,
    required String repoId,
    this.checkoutId = const Value.absent(),
    required String path,
    required String contentHash,
    this.symbolCount = const Value.absent(),
    this.language = const Value.absent(),
    this.indexedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       repoId = Value(repoId),
       path = Value(path),
       contentHash = Value(contentHash);
  static Insertable<CodeFilesTableData> custom({
    Expression<String>? id,
    Expression<String>? repoId,
    Expression<String>? checkoutId,
    Expression<String>? path,
    Expression<String>? contentHash,
    Expression<int>? symbolCount,
    Expression<String>? language,
    Expression<DateTime>? indexedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (repoId != null) 'repo_id': repoId,
      if (checkoutId != null) 'checkout_id': checkoutId,
      if (path != null) 'path': path,
      if (contentHash != null) 'content_hash': contentHash,
      if (symbolCount != null) 'symbol_count': symbolCount,
      if (language != null) 'language': language,
      if (indexedAt != null) 'indexed_at': indexedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CodeFilesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? repoId,
    Value<String?>? checkoutId,
    Value<String>? path,
    Value<String>? contentHash,
    Value<int>? symbolCount,
    Value<String>? language,
    Value<DateTime>? indexedAt,
    Value<int>? rowid,
  }) {
    return CodeFilesTableCompanion(
      id: id ?? this.id,
      repoId: repoId ?? this.repoId,
      checkoutId: checkoutId ?? this.checkoutId,
      path: path ?? this.path,
      contentHash: contentHash ?? this.contentHash,
      symbolCount: symbolCount ?? this.symbolCount,
      language: language ?? this.language,
      indexedAt: indexedAt ?? this.indexedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (repoId.present) {
      map['repo_id'] = Variable<String>(repoId.value);
    }
    if (checkoutId.present) {
      map['checkout_id'] = Variable<String>(checkoutId.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (contentHash.present) {
      map['content_hash'] = Variable<String>(contentHash.value);
    }
    if (symbolCount.present) {
      map['symbol_count'] = Variable<int>(symbolCount.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (indexedAt.present) {
      map['indexed_at'] = Variable<DateTime>(indexedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CodeFilesTableCompanion(')
          ..write('id: $id, ')
          ..write('repoId: $repoId, ')
          ..write('checkoutId: $checkoutId, ')
          ..write('path: $path, ')
          ..write('contentHash: $contentHash, ')
          ..write('symbolCount: $symbolCount, ')
          ..write('language: $language, ')
          ..write('indexedAt: $indexedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CodeIndexCheckpointsTableTable extends CodeIndexCheckpointsTable
    with
        TableInfo<
          $CodeIndexCheckpointsTableTable,
          CodeIndexCheckpointsTableData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CodeIndexCheckpointsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _repoIdMeta = const VerificationMeta('repoId');
  @override
  late final GeneratedColumn<String> repoId = GeneratedColumn<String>(
    'repo_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _checkoutIdMeta = const VerificationMeta(
    'checkoutId',
  );
  @override
  late final GeneratedColumn<String> checkoutId = GeneratedColumn<String>(
    'checkout_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _headShaMeta = const VerificationMeta(
    'headSha',
  );
  @override
  late final GeneratedColumn<String> headSha = GeneratedColumn<String>(
    'head_sha',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _worktreeDigestMeta = const VerificationMeta(
    'worktreeDigest',
  );
  @override
  late final GeneratedColumn<String> worktreeDigest = GeneratedColumn<String>(
    'worktree_digest',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _indexerFingerprintMeta =
      const VerificationMeta('indexerFingerprint');
  @override
  late final GeneratedColumn<String> indexerFingerprint =
      GeneratedColumn<String>(
        'indexer_fingerprint',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _generationMeta = const VerificationMeta(
    'generation',
  );
  @override
  late final GeneratedColumn<int> generation = GeneratedColumn<int>(
    'generation',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _baseGenerationMeta = const VerificationMeta(
    'baseGeneration',
  );
  @override
  late final GeneratedColumn<int> baseGeneration = GeneratedColumn<int>(
    'base_generation',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _indexedAtMeta = const VerificationMeta(
    'indexedAt',
  );
  @override
  late final GeneratedColumn<DateTime> indexedAt = GeneratedColumn<DateTime>(
    'indexed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    repoId,
    checkoutId,
    headSha,
    worktreeDigest,
    indexerFingerprint,
    generation,
    baseGeneration,
    indexedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'code_index_checkpoints';
  @override
  VerificationContext validateIntegrity(
    Insertable<CodeIndexCheckpointsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('repo_id')) {
      context.handle(
        _repoIdMeta,
        repoId.isAcceptableOrUnknown(data['repo_id']!, _repoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_repoIdMeta);
    }
    if (data.containsKey('checkout_id')) {
      context.handle(
        _checkoutIdMeta,
        checkoutId.isAcceptableOrUnknown(data['checkout_id']!, _checkoutIdMeta),
      );
    }
    if (data.containsKey('head_sha')) {
      context.handle(
        _headShaMeta,
        headSha.isAcceptableOrUnknown(data['head_sha']!, _headShaMeta),
      );
    } else if (isInserting) {
      context.missing(_headShaMeta);
    }
    if (data.containsKey('worktree_digest')) {
      context.handle(
        _worktreeDigestMeta,
        worktreeDigest.isAcceptableOrUnknown(
          data['worktree_digest']!,
          _worktreeDigestMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_worktreeDigestMeta);
    }
    if (data.containsKey('indexer_fingerprint')) {
      context.handle(
        _indexerFingerprintMeta,
        indexerFingerprint.isAcceptableOrUnknown(
          data['indexer_fingerprint']!,
          _indexerFingerprintMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_indexerFingerprintMeta);
    }
    if (data.containsKey('generation')) {
      context.handle(
        _generationMeta,
        generation.isAcceptableOrUnknown(data['generation']!, _generationMeta),
      );
    }
    if (data.containsKey('base_generation')) {
      context.handle(
        _baseGenerationMeta,
        baseGeneration.isAcceptableOrUnknown(
          data['base_generation']!,
          _baseGenerationMeta,
        ),
      );
    }
    if (data.containsKey('indexed_at')) {
      context.handle(
        _indexedAtMeta,
        indexedAt.isAcceptableOrUnknown(data['indexed_at']!, _indexedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CodeIndexCheckpointsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CodeIndexCheckpointsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      repoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repo_id'],
      )!,
      checkoutId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checkout_id'],
      ),
      headSha: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}head_sha'],
      )!,
      worktreeDigest: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}worktree_digest'],
      )!,
      indexerFingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}indexer_fingerprint'],
      )!,
      generation: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}generation'],
      )!,
      baseGeneration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_generation'],
      )!,
      indexedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}indexed_at'],
      )!,
    );
  }

  @override
  $CodeIndexCheckpointsTableTable createAlias(String alias) {
    return $CodeIndexCheckpointsTableTable(attachedDatabase, alias);
  }
}

class CodeIndexCheckpointsTableData extends DataClass
    implements Insertable<CodeIndexCheckpointsTableData> {
  /// Deterministic id of the partition (see `code_graph_ids`).
  final String id;

  /// The repository (`repos.id` in `workspace.db`).
  final String repoId;

  /// The checkout partition: NULL = the linked checkout, otherwise an
  /// `isolated_repos` row id.
  final String? checkoutId;

  /// `git rev-parse HEAD` at the last successful run ('' = unborn branch).
  final String headSha;

  /// The `RepoStateFingerprint` digest at the last successful run.
  final String worktreeDigest;

  /// Fingerprint of the extractor itself (extractor version + `.scm` queries
  /// + grammar libraries), so editing a query, installing a grammar, or
  /// changing extraction semantics invalidates every checkpoint.
  final String indexerFingerprint;

  /// Bumped every run that actually changed rows (indexed or pruned files).
  /// Worktrees record the base partition's generation they indexed against
  /// ([baseGeneration]); a base re-index therefore invalidates their delta.
  final int generation;

  /// For a worktree row: the base (linked-checkout) partition's [generation]
  /// this delta was measured against. 0 for linked checkouts.
  final int baseGeneration;

  /// When the run that wrote the checkpoint started: what it proves holds as
  /// of then, so anything written while it ran is newer and re-checked.
  final DateTime indexedAt;
  const CodeIndexCheckpointsTableData({
    required this.id,
    required this.repoId,
    this.checkoutId,
    required this.headSha,
    required this.worktreeDigest,
    required this.indexerFingerprint,
    required this.generation,
    required this.baseGeneration,
    required this.indexedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['repo_id'] = Variable<String>(repoId);
    if (!nullToAbsent || checkoutId != null) {
      map['checkout_id'] = Variable<String>(checkoutId);
    }
    map['head_sha'] = Variable<String>(headSha);
    map['worktree_digest'] = Variable<String>(worktreeDigest);
    map['indexer_fingerprint'] = Variable<String>(indexerFingerprint);
    map['generation'] = Variable<int>(generation);
    map['base_generation'] = Variable<int>(baseGeneration);
    map['indexed_at'] = Variable<DateTime>(indexedAt);
    return map;
  }

  CodeIndexCheckpointsTableCompanion toCompanion(bool nullToAbsent) {
    return CodeIndexCheckpointsTableCompanion(
      id: Value(id),
      repoId: Value(repoId),
      checkoutId: checkoutId == null && nullToAbsent
          ? const Value.absent()
          : Value(checkoutId),
      headSha: Value(headSha),
      worktreeDigest: Value(worktreeDigest),
      indexerFingerprint: Value(indexerFingerprint),
      generation: Value(generation),
      baseGeneration: Value(baseGeneration),
      indexedAt: Value(indexedAt),
    );
  }

  factory CodeIndexCheckpointsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CodeIndexCheckpointsTableData(
      id: serializer.fromJson<String>(json['id']),
      repoId: serializer.fromJson<String>(json['repoId']),
      checkoutId: serializer.fromJson<String?>(json['checkoutId']),
      headSha: serializer.fromJson<String>(json['headSha']),
      worktreeDigest: serializer.fromJson<String>(json['worktreeDigest']),
      indexerFingerprint: serializer.fromJson<String>(
        json['indexerFingerprint'],
      ),
      generation: serializer.fromJson<int>(json['generation']),
      baseGeneration: serializer.fromJson<int>(json['baseGeneration']),
      indexedAt: serializer.fromJson<DateTime>(json['indexedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'repoId': serializer.toJson<String>(repoId),
      'checkoutId': serializer.toJson<String?>(checkoutId),
      'headSha': serializer.toJson<String>(headSha),
      'worktreeDigest': serializer.toJson<String>(worktreeDigest),
      'indexerFingerprint': serializer.toJson<String>(indexerFingerprint),
      'generation': serializer.toJson<int>(generation),
      'baseGeneration': serializer.toJson<int>(baseGeneration),
      'indexedAt': serializer.toJson<DateTime>(indexedAt),
    };
  }

  CodeIndexCheckpointsTableData copyWith({
    String? id,
    String? repoId,
    Value<String?> checkoutId = const Value.absent(),
    String? headSha,
    String? worktreeDigest,
    String? indexerFingerprint,
    int? generation,
    int? baseGeneration,
    DateTime? indexedAt,
  }) => CodeIndexCheckpointsTableData(
    id: id ?? this.id,
    repoId: repoId ?? this.repoId,
    checkoutId: checkoutId.present ? checkoutId.value : this.checkoutId,
    headSha: headSha ?? this.headSha,
    worktreeDigest: worktreeDigest ?? this.worktreeDigest,
    indexerFingerprint: indexerFingerprint ?? this.indexerFingerprint,
    generation: generation ?? this.generation,
    baseGeneration: baseGeneration ?? this.baseGeneration,
    indexedAt: indexedAt ?? this.indexedAt,
  );
  CodeIndexCheckpointsTableData copyWithCompanion(
    CodeIndexCheckpointsTableCompanion data,
  ) {
    return CodeIndexCheckpointsTableData(
      id: data.id.present ? data.id.value : this.id,
      repoId: data.repoId.present ? data.repoId.value : this.repoId,
      checkoutId: data.checkoutId.present
          ? data.checkoutId.value
          : this.checkoutId,
      headSha: data.headSha.present ? data.headSha.value : this.headSha,
      worktreeDigest: data.worktreeDigest.present
          ? data.worktreeDigest.value
          : this.worktreeDigest,
      indexerFingerprint: data.indexerFingerprint.present
          ? data.indexerFingerprint.value
          : this.indexerFingerprint,
      generation: data.generation.present
          ? data.generation.value
          : this.generation,
      baseGeneration: data.baseGeneration.present
          ? data.baseGeneration.value
          : this.baseGeneration,
      indexedAt: data.indexedAt.present ? data.indexedAt.value : this.indexedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CodeIndexCheckpointsTableData(')
          ..write('id: $id, ')
          ..write('repoId: $repoId, ')
          ..write('checkoutId: $checkoutId, ')
          ..write('headSha: $headSha, ')
          ..write('worktreeDigest: $worktreeDigest, ')
          ..write('indexerFingerprint: $indexerFingerprint, ')
          ..write('generation: $generation, ')
          ..write('baseGeneration: $baseGeneration, ')
          ..write('indexedAt: $indexedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    repoId,
    checkoutId,
    headSha,
    worktreeDigest,
    indexerFingerprint,
    generation,
    baseGeneration,
    indexedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CodeIndexCheckpointsTableData &&
          other.id == this.id &&
          other.repoId == this.repoId &&
          other.checkoutId == this.checkoutId &&
          other.headSha == this.headSha &&
          other.worktreeDigest == this.worktreeDigest &&
          other.indexerFingerprint == this.indexerFingerprint &&
          other.generation == this.generation &&
          other.baseGeneration == this.baseGeneration &&
          other.indexedAt == this.indexedAt);
}

class CodeIndexCheckpointsTableCompanion
    extends UpdateCompanion<CodeIndexCheckpointsTableData> {
  final Value<String> id;
  final Value<String> repoId;
  final Value<String?> checkoutId;
  final Value<String> headSha;
  final Value<String> worktreeDigest;
  final Value<String> indexerFingerprint;
  final Value<int> generation;
  final Value<int> baseGeneration;
  final Value<DateTime> indexedAt;
  final Value<int> rowid;
  const CodeIndexCheckpointsTableCompanion({
    this.id = const Value.absent(),
    this.repoId = const Value.absent(),
    this.checkoutId = const Value.absent(),
    this.headSha = const Value.absent(),
    this.worktreeDigest = const Value.absent(),
    this.indexerFingerprint = const Value.absent(),
    this.generation = const Value.absent(),
    this.baseGeneration = const Value.absent(),
    this.indexedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CodeIndexCheckpointsTableCompanion.insert({
    required String id,
    required String repoId,
    this.checkoutId = const Value.absent(),
    required String headSha,
    required String worktreeDigest,
    required String indexerFingerprint,
    this.generation = const Value.absent(),
    this.baseGeneration = const Value.absent(),
    this.indexedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       repoId = Value(repoId),
       headSha = Value(headSha),
       worktreeDigest = Value(worktreeDigest),
       indexerFingerprint = Value(indexerFingerprint);
  static Insertable<CodeIndexCheckpointsTableData> custom({
    Expression<String>? id,
    Expression<String>? repoId,
    Expression<String>? checkoutId,
    Expression<String>? headSha,
    Expression<String>? worktreeDigest,
    Expression<String>? indexerFingerprint,
    Expression<int>? generation,
    Expression<int>? baseGeneration,
    Expression<DateTime>? indexedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (repoId != null) 'repo_id': repoId,
      if (checkoutId != null) 'checkout_id': checkoutId,
      if (headSha != null) 'head_sha': headSha,
      if (worktreeDigest != null) 'worktree_digest': worktreeDigest,
      if (indexerFingerprint != null) 'indexer_fingerprint': indexerFingerprint,
      if (generation != null) 'generation': generation,
      if (baseGeneration != null) 'base_generation': baseGeneration,
      if (indexedAt != null) 'indexed_at': indexedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CodeIndexCheckpointsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? repoId,
    Value<String?>? checkoutId,
    Value<String>? headSha,
    Value<String>? worktreeDigest,
    Value<String>? indexerFingerprint,
    Value<int>? generation,
    Value<int>? baseGeneration,
    Value<DateTime>? indexedAt,
    Value<int>? rowid,
  }) {
    return CodeIndexCheckpointsTableCompanion(
      id: id ?? this.id,
      repoId: repoId ?? this.repoId,
      checkoutId: checkoutId ?? this.checkoutId,
      headSha: headSha ?? this.headSha,
      worktreeDigest: worktreeDigest ?? this.worktreeDigest,
      indexerFingerprint: indexerFingerprint ?? this.indexerFingerprint,
      generation: generation ?? this.generation,
      baseGeneration: baseGeneration ?? this.baseGeneration,
      indexedAt: indexedAt ?? this.indexedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (repoId.present) {
      map['repo_id'] = Variable<String>(repoId.value);
    }
    if (checkoutId.present) {
      map['checkout_id'] = Variable<String>(checkoutId.value);
    }
    if (headSha.present) {
      map['head_sha'] = Variable<String>(headSha.value);
    }
    if (worktreeDigest.present) {
      map['worktree_digest'] = Variable<String>(worktreeDigest.value);
    }
    if (indexerFingerprint.present) {
      map['indexer_fingerprint'] = Variable<String>(indexerFingerprint.value);
    }
    if (generation.present) {
      map['generation'] = Variable<int>(generation.value);
    }
    if (baseGeneration.present) {
      map['base_generation'] = Variable<int>(baseGeneration.value);
    }
    if (indexedAt.present) {
      map['indexed_at'] = Variable<DateTime>(indexedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CodeIndexCheckpointsTableCompanion(')
          ..write('id: $id, ')
          ..write('repoId: $repoId, ')
          ..write('checkoutId: $checkoutId, ')
          ..write('headSha: $headSha, ')
          ..write('worktreeDigest: $worktreeDigest, ')
          ..write('indexerFingerprint: $indexerFingerprint, ')
          ..write('generation: $generation, ')
          ..write('baseGeneration: $baseGeneration, ')
          ..write('indexedAt: $indexedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$CodeIndexDatabase extends GeneratedDatabase {
  _$CodeIndexDatabase(QueryExecutor e) : super(e);
  $CodeIndexDatabaseManager get managers => $CodeIndexDatabaseManager(this);
  late final $CodeSymbolsTableTable codeSymbolsTable = $CodeSymbolsTableTable(
    this,
  );
  late final $CodeSymbolEmbeddingsTableTable codeSymbolEmbeddingsTable =
      $CodeSymbolEmbeddingsTableTable(this);
  late final $CodeEdgesTableTable codeEdgesTable = $CodeEdgesTableTable(this);
  late final $CodeFilesTableTable codeFilesTable = $CodeFilesTableTable(this);
  late final $CodeIndexCheckpointsTableTable codeIndexCheckpointsTable =
      $CodeIndexCheckpointsTableTable(this);
  late final Index idxCodeSymbolsPartitionFile = Index(
    'idx_code_symbols_partition_file',
    'CREATE INDEX idx_code_symbols_partition_file ON code_symbols (repo_id, checkout_id, file_path)',
  );
  late final Index idxCodeSymbolsName = Index(
    'idx_code_symbols_name',
    'CREATE INDEX idx_code_symbols_name ON code_symbols (name)',
  );
  late final Index idxCodeSymbolsQualifiedName = Index(
    'idx_code_symbols_qualifiedName',
    'CREATE INDEX idx_code_symbols_qualifiedName ON code_symbols (qualified_name)',
  );
  late final Index idxCodeEdgesPartitionFile = Index(
    'idx_code_edges_partition_file',
    'CREATE INDEX idx_code_edges_partition_file ON code_edges (repo_id, checkout_id, source_file_path)',
  );
  late final Index idxCodeEdgesSource = Index(
    'idx_code_edges_source',
    'CREATE INDEX idx_code_edges_source ON code_edges (source_symbol_id)',
  );
  late final Index idxCodeEdgesTarget = Index(
    'idx_code_edges_target',
    'CREATE INDEX idx_code_edges_target ON code_edges (target_symbol_id)',
  );
  late final Index idxCodeFilesPartitionPath = Index(
    'idx_code_files_partition_path',
    'CREATE INDEX idx_code_files_partition_path ON code_files (repo_id, checkout_id, path)',
  );
  late final Index idxCodeIndexCheckpointsPartition = Index(
    'idx_code_index_checkpoints_partition',
    'CREATE INDEX idx_code_index_checkpoints_partition ON code_index_checkpoints (repo_id, checkout_id)',
  );
  late final CodeGraphDao codeGraphDao = CodeGraphDao(
    this as CodeIndexDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    codeSymbolsTable,
    codeSymbolEmbeddingsTable,
    codeEdgesTable,
    codeFilesTable,
    codeIndexCheckpointsTable,
    idxCodeSymbolsPartitionFile,
    idxCodeSymbolsName,
    idxCodeSymbolsQualifiedName,
    idxCodeEdgesPartitionFile,
    idxCodeEdgesSource,
    idxCodeEdgesTarget,
    idxCodeFilesPartitionPath,
    idxCodeIndexCheckpointsPartition,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'code_symbols',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('code_symbol_embeddings', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$CodeSymbolsTableTableCreateCompanionBuilder =
    CodeSymbolsTableCompanion Function({
      required String id,
      required String repoId,
      Value<String?> checkoutId,
      required String kind,
      required String name,
      required String qualifiedName,
      required String filePath,
      required String language,
      required int startLine,
      required int endLine,
      Value<String> signature,
      Value<String?> docstring,
      Value<String?> parentName,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$CodeSymbolsTableTableUpdateCompanionBuilder =
    CodeSymbolsTableCompanion Function({
      Value<String> id,
      Value<String> repoId,
      Value<String?> checkoutId,
      Value<String> kind,
      Value<String> name,
      Value<String> qualifiedName,
      Value<String> filePath,
      Value<String> language,
      Value<int> startLine,
      Value<int> endLine,
      Value<String> signature,
      Value<String?> docstring,
      Value<String?> parentName,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$CodeSymbolsTableTableReferences
    extends
        BaseReferences<
          _$CodeIndexDatabase,
          $CodeSymbolsTableTable,
          CodeSymbolsTableData
        > {
  $$CodeSymbolsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $CodeSymbolEmbeddingsTableTable,
    List<CodeSymbolEmbeddingsTableData>
  >
  _codeSymbolEmbeddingsTableRefsTable(_$CodeIndexDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.codeSymbolEmbeddingsTable,
        aliasName: 'code_symbols__id__code_symbol_embeddings__symbol_id',
      );

  $$CodeSymbolEmbeddingsTableTableProcessedTableManager
  get codeSymbolEmbeddingsTableRefs {
    final manager = $$CodeSymbolEmbeddingsTableTableTableManager(
      $_db,
      $_db.codeSymbolEmbeddingsTable,
    ).filter((f) => f.symbolId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _codeSymbolEmbeddingsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CodeSymbolsTableTableFilterComposer
    extends Composer<_$CodeIndexDatabase, $CodeSymbolsTableTable> {
  $$CodeSymbolsTableTableFilterComposer({
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

  ColumnFilters<String> get repoId => $composableBuilder(
    column: $table.repoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checkoutId => $composableBuilder(
    column: $table.checkoutId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get qualifiedName => $composableBuilder(
    column: $table.qualifiedName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startLine => $composableBuilder(
    column: $table.startLine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endLine => $composableBuilder(
    column: $table.endLine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get signature => $composableBuilder(
    column: $table.signature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get docstring => $composableBuilder(
    column: $table.docstring,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentName => $composableBuilder(
    column: $table.parentName,
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

  Expression<bool> codeSymbolEmbeddingsTableRefs(
    Expression<bool> Function($$CodeSymbolEmbeddingsTableTableFilterComposer f)
    f,
  ) {
    final $$CodeSymbolEmbeddingsTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.codeSymbolEmbeddingsTable,
          getReferencedColumn: (t) => t.symbolId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CodeSymbolEmbeddingsTableTableFilterComposer(
                $db: $db,
                $table: $db.codeSymbolEmbeddingsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CodeSymbolsTableTableOrderingComposer
    extends Composer<_$CodeIndexDatabase, $CodeSymbolsTableTable> {
  $$CodeSymbolsTableTableOrderingComposer({
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

  ColumnOrderings<String> get repoId => $composableBuilder(
    column: $table.repoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checkoutId => $composableBuilder(
    column: $table.checkoutId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get qualifiedName => $composableBuilder(
    column: $table.qualifiedName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startLine => $composableBuilder(
    column: $table.startLine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endLine => $composableBuilder(
    column: $table.endLine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get signature => $composableBuilder(
    column: $table.signature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get docstring => $composableBuilder(
    column: $table.docstring,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentName => $composableBuilder(
    column: $table.parentName,
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

class $$CodeSymbolsTableTableAnnotationComposer
    extends Composer<_$CodeIndexDatabase, $CodeSymbolsTableTable> {
  $$CodeSymbolsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get repoId =>
      $composableBuilder(column: $table.repoId, builder: (column) => column);

  GeneratedColumn<String> get checkoutId => $composableBuilder(
    column: $table.checkoutId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get qualifiedName => $composableBuilder(
    column: $table.qualifiedName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<int> get startLine =>
      $composableBuilder(column: $table.startLine, builder: (column) => column);

  GeneratedColumn<int> get endLine =>
      $composableBuilder(column: $table.endLine, builder: (column) => column);

  GeneratedColumn<String> get signature =>
      $composableBuilder(column: $table.signature, builder: (column) => column);

  GeneratedColumn<String> get docstring =>
      $composableBuilder(column: $table.docstring, builder: (column) => column);

  GeneratedColumn<String> get parentName => $composableBuilder(
    column: $table.parentName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> codeSymbolEmbeddingsTableRefs<T extends Object>(
    Expression<T> Function($$CodeSymbolEmbeddingsTableTableAnnotationComposer a)
    f,
  ) {
    final $$CodeSymbolEmbeddingsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.codeSymbolEmbeddingsTable,
          getReferencedColumn: (t) => t.symbolId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CodeSymbolEmbeddingsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.codeSymbolEmbeddingsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CodeSymbolsTableTableTableManager
    extends
        RootTableManager<
          _$CodeIndexDatabase,
          $CodeSymbolsTableTable,
          CodeSymbolsTableData,
          $$CodeSymbolsTableTableFilterComposer,
          $$CodeSymbolsTableTableOrderingComposer,
          $$CodeSymbolsTableTableAnnotationComposer,
          $$CodeSymbolsTableTableCreateCompanionBuilder,
          $$CodeSymbolsTableTableUpdateCompanionBuilder,
          (CodeSymbolsTableData, $$CodeSymbolsTableTableReferences),
          CodeSymbolsTableData,
          PrefetchHooks Function({bool codeSymbolEmbeddingsTableRefs})
        > {
  $$CodeSymbolsTableTableTableManager(
    _$CodeIndexDatabase db,
    $CodeSymbolsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CodeSymbolsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CodeSymbolsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CodeSymbolsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> repoId = const Value.absent(),
                Value<String?> checkoutId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> qualifiedName = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<int> startLine = const Value.absent(),
                Value<int> endLine = const Value.absent(),
                Value<String> signature = const Value.absent(),
                Value<String?> docstring = const Value.absent(),
                Value<String?> parentName = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CodeSymbolsTableCompanion(
                id: id,
                repoId: repoId,
                checkoutId: checkoutId,
                kind: kind,
                name: name,
                qualifiedName: qualifiedName,
                filePath: filePath,
                language: language,
                startLine: startLine,
                endLine: endLine,
                signature: signature,
                docstring: docstring,
                parentName: parentName,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String repoId,
                Value<String?> checkoutId = const Value.absent(),
                required String kind,
                required String name,
                required String qualifiedName,
                required String filePath,
                required String language,
                required int startLine,
                required int endLine,
                Value<String> signature = const Value.absent(),
                Value<String?> docstring = const Value.absent(),
                Value<String?> parentName = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CodeSymbolsTableCompanion.insert(
                id: id,
                repoId: repoId,
                checkoutId: checkoutId,
                kind: kind,
                name: name,
                qualifiedName: qualifiedName,
                filePath: filePath,
                language: language,
                startLine: startLine,
                endLine: endLine,
                signature: signature,
                docstring: docstring,
                parentName: parentName,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CodeSymbolsTableTable, CodeSymbolsTableData>(
                    table,
                  ),
                  $$CodeSymbolsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({codeSymbolEmbeddingsTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (codeSymbolEmbeddingsTableRefs) db.codeSymbolEmbeddingsTable,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (codeSymbolEmbeddingsTableRefs)
                    await $_getPrefetchedData<
                      CodeSymbolsTableData,
                      $CodeSymbolsTableTable,
                      CodeSymbolEmbeddingsTableData
                    >(
                      currentTable: table,
                      referencedTable: $$CodeSymbolsTableTableReferences
                          ._codeSymbolEmbeddingsTableRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CodeSymbolsTableTableReferences(
                            db,
                            table,
                            p0,
                          ).codeSymbolEmbeddingsTableRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.symbolId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CodeSymbolsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$CodeIndexDatabase,
      $CodeSymbolsTableTable,
      CodeSymbolsTableData,
      $$CodeSymbolsTableTableFilterComposer,
      $$CodeSymbolsTableTableOrderingComposer,
      $$CodeSymbolsTableTableAnnotationComposer,
      $$CodeSymbolsTableTableCreateCompanionBuilder,
      $$CodeSymbolsTableTableUpdateCompanionBuilder,
      (CodeSymbolsTableData, $$CodeSymbolsTableTableReferences),
      CodeSymbolsTableData,
      PrefetchHooks Function({bool codeSymbolEmbeddingsTableRefs})
    >;
typedef $$CodeSymbolEmbeddingsTableTableCreateCompanionBuilder =
    CodeSymbolEmbeddingsTableCompanion Function({
      required String symbolId,
      required Uint8List embedding,
      Value<int> rowid,
    });
typedef $$CodeSymbolEmbeddingsTableTableUpdateCompanionBuilder =
    CodeSymbolEmbeddingsTableCompanion Function({
      Value<String> symbolId,
      Value<Uint8List> embedding,
      Value<int> rowid,
    });

final class $$CodeSymbolEmbeddingsTableTableReferences
    extends
        BaseReferences<
          _$CodeIndexDatabase,
          $CodeSymbolEmbeddingsTableTable,
          CodeSymbolEmbeddingsTableData
        > {
  $$CodeSymbolEmbeddingsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CodeSymbolsTableTable _symbolIdTable(_$CodeIndexDatabase db) => db
      .codeSymbolsTable
      .createAlias('code_symbol_embeddings__symbol_id__code_symbols__id');

  $$CodeSymbolsTableTableProcessedTableManager get symbolId {
    final $_column = $_itemColumn<String>('symbol_id')!;

    final manager = $$CodeSymbolsTableTableTableManager(
      $_db,
      $_db.codeSymbolsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_symbolIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CodeSymbolEmbeddingsTableTableFilterComposer
    extends Composer<_$CodeIndexDatabase, $CodeSymbolEmbeddingsTableTable> {
  $$CodeSymbolEmbeddingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<Uint8List> get embedding => $composableBuilder(
    column: $table.embedding,
    builder: (column) => ColumnFilters(column),
  );

  $$CodeSymbolsTableTableFilterComposer get symbolId {
    final $$CodeSymbolsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.symbolId,
      referencedTable: $db.codeSymbolsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CodeSymbolsTableTableFilterComposer(
            $db: $db,
            $table: $db.codeSymbolsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CodeSymbolEmbeddingsTableTableOrderingComposer
    extends Composer<_$CodeIndexDatabase, $CodeSymbolEmbeddingsTableTable> {
  $$CodeSymbolEmbeddingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<Uint8List> get embedding => $composableBuilder(
    column: $table.embedding,
    builder: (column) => ColumnOrderings(column),
  );

  $$CodeSymbolsTableTableOrderingComposer get symbolId {
    final $$CodeSymbolsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.symbolId,
      referencedTable: $db.codeSymbolsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CodeSymbolsTableTableOrderingComposer(
            $db: $db,
            $table: $db.codeSymbolsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CodeSymbolEmbeddingsTableTableAnnotationComposer
    extends Composer<_$CodeIndexDatabase, $CodeSymbolEmbeddingsTableTable> {
  $$CodeSymbolEmbeddingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<Uint8List> get embedding =>
      $composableBuilder(column: $table.embedding, builder: (column) => column);

  $$CodeSymbolsTableTableAnnotationComposer get symbolId {
    final $$CodeSymbolsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.symbolId,
      referencedTable: $db.codeSymbolsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CodeSymbolsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.codeSymbolsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CodeSymbolEmbeddingsTableTableTableManager
    extends
        RootTableManager<
          _$CodeIndexDatabase,
          $CodeSymbolEmbeddingsTableTable,
          CodeSymbolEmbeddingsTableData,
          $$CodeSymbolEmbeddingsTableTableFilterComposer,
          $$CodeSymbolEmbeddingsTableTableOrderingComposer,
          $$CodeSymbolEmbeddingsTableTableAnnotationComposer,
          $$CodeSymbolEmbeddingsTableTableCreateCompanionBuilder,
          $$CodeSymbolEmbeddingsTableTableUpdateCompanionBuilder,
          (
            CodeSymbolEmbeddingsTableData,
            $$CodeSymbolEmbeddingsTableTableReferences,
          ),
          CodeSymbolEmbeddingsTableData,
          PrefetchHooks Function({bool symbolId})
        > {
  $$CodeSymbolEmbeddingsTableTableTableManager(
    _$CodeIndexDatabase db,
    $CodeSymbolEmbeddingsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CodeSymbolEmbeddingsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CodeSymbolEmbeddingsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CodeSymbolEmbeddingsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> symbolId = const Value.absent(),
                Value<Uint8List> embedding = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CodeSymbolEmbeddingsTableCompanion(
                symbolId: symbolId,
                embedding: embedding,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String symbolId,
                required Uint8List embedding,
                Value<int> rowid = const Value.absent(),
              }) => CodeSymbolEmbeddingsTableCompanion.insert(
                symbolId: symbolId,
                embedding: embedding,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $CodeSymbolEmbeddingsTableTable,
                    CodeSymbolEmbeddingsTableData
                  >(table),
                  $$CodeSymbolEmbeddingsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({symbolId = false}) {
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
                    if (symbolId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.symbolId,
                                referencedTable:
                                    $$CodeSymbolEmbeddingsTableTableReferences
                                        ._symbolIdTable(db),
                                referencedColumn:
                                    $$CodeSymbolEmbeddingsTableTableReferences
                                        ._symbolIdTable(db)
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

typedef $$CodeSymbolEmbeddingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$CodeIndexDatabase,
      $CodeSymbolEmbeddingsTableTable,
      CodeSymbolEmbeddingsTableData,
      $$CodeSymbolEmbeddingsTableTableFilterComposer,
      $$CodeSymbolEmbeddingsTableTableOrderingComposer,
      $$CodeSymbolEmbeddingsTableTableAnnotationComposer,
      $$CodeSymbolEmbeddingsTableTableCreateCompanionBuilder,
      $$CodeSymbolEmbeddingsTableTableUpdateCompanionBuilder,
      (
        CodeSymbolEmbeddingsTableData,
        $$CodeSymbolEmbeddingsTableTableReferences,
      ),
      CodeSymbolEmbeddingsTableData,
      PrefetchHooks Function({bool symbolId})
    >;
typedef $$CodeEdgesTableTableCreateCompanionBuilder =
    CodeEdgesTableCompanion Function({
      required String id,
      required String repoId,
      Value<String?> checkoutId,
      required String sourceSymbolId,
      Value<String> sourceFilePath,
      Value<String?> targetSymbolId,
      Value<String?> targetName,
      required String kind,
      Value<String?> metadata,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$CodeEdgesTableTableUpdateCompanionBuilder =
    CodeEdgesTableCompanion Function({
      Value<String> id,
      Value<String> repoId,
      Value<String?> checkoutId,
      Value<String> sourceSymbolId,
      Value<String> sourceFilePath,
      Value<String?> targetSymbolId,
      Value<String?> targetName,
      Value<String> kind,
      Value<String?> metadata,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$CodeEdgesTableTableFilterComposer
    extends Composer<_$CodeIndexDatabase, $CodeEdgesTableTable> {
  $$CodeEdgesTableTableFilterComposer({
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

  ColumnFilters<String> get repoId => $composableBuilder(
    column: $table.repoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checkoutId => $composableBuilder(
    column: $table.checkoutId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceSymbolId => $composableBuilder(
    column: $table.sourceSymbolId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceFilePath => $composableBuilder(
    column: $table.sourceFilePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetSymbolId => $composableBuilder(
    column: $table.targetSymbolId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetName => $composableBuilder(
    column: $table.targetName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CodeEdgesTableTableOrderingComposer
    extends Composer<_$CodeIndexDatabase, $CodeEdgesTableTable> {
  $$CodeEdgesTableTableOrderingComposer({
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

  ColumnOrderings<String> get repoId => $composableBuilder(
    column: $table.repoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checkoutId => $composableBuilder(
    column: $table.checkoutId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceSymbolId => $composableBuilder(
    column: $table.sourceSymbolId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceFilePath => $composableBuilder(
    column: $table.sourceFilePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetSymbolId => $composableBuilder(
    column: $table.targetSymbolId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetName => $composableBuilder(
    column: $table.targetName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CodeEdgesTableTableAnnotationComposer
    extends Composer<_$CodeIndexDatabase, $CodeEdgesTableTable> {
  $$CodeEdgesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get repoId =>
      $composableBuilder(column: $table.repoId, builder: (column) => column);

  GeneratedColumn<String> get checkoutId => $composableBuilder(
    column: $table.checkoutId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceSymbolId => $composableBuilder(
    column: $table.sourceSymbolId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceFilePath => $composableBuilder(
    column: $table.sourceFilePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetSymbolId => $composableBuilder(
    column: $table.targetSymbolId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetName => $composableBuilder(
    column: $table.targetName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CodeEdgesTableTableTableManager
    extends
        RootTableManager<
          _$CodeIndexDatabase,
          $CodeEdgesTableTable,
          CodeEdgesTableData,
          $$CodeEdgesTableTableFilterComposer,
          $$CodeEdgesTableTableOrderingComposer,
          $$CodeEdgesTableTableAnnotationComposer,
          $$CodeEdgesTableTableCreateCompanionBuilder,
          $$CodeEdgesTableTableUpdateCompanionBuilder,
          (
            CodeEdgesTableData,
            BaseReferences<
              _$CodeIndexDatabase,
              $CodeEdgesTableTable,
              CodeEdgesTableData
            >,
          ),
          CodeEdgesTableData,
          PrefetchHooks Function()
        > {
  $$CodeEdgesTableTableTableManager(
    _$CodeIndexDatabase db,
    $CodeEdgesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CodeEdgesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CodeEdgesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CodeEdgesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> repoId = const Value.absent(),
                Value<String?> checkoutId = const Value.absent(),
                Value<String> sourceSymbolId = const Value.absent(),
                Value<String> sourceFilePath = const Value.absent(),
                Value<String?> targetSymbolId = const Value.absent(),
                Value<String?> targetName = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CodeEdgesTableCompanion(
                id: id,
                repoId: repoId,
                checkoutId: checkoutId,
                sourceSymbolId: sourceSymbolId,
                sourceFilePath: sourceFilePath,
                targetSymbolId: targetSymbolId,
                targetName: targetName,
                kind: kind,
                metadata: metadata,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String repoId,
                Value<String?> checkoutId = const Value.absent(),
                required String sourceSymbolId,
                Value<String> sourceFilePath = const Value.absent(),
                Value<String?> targetSymbolId = const Value.absent(),
                Value<String?> targetName = const Value.absent(),
                required String kind,
                Value<String?> metadata = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CodeEdgesTableCompanion.insert(
                id: id,
                repoId: repoId,
                checkoutId: checkoutId,
                sourceSymbolId: sourceSymbolId,
                sourceFilePath: sourceFilePath,
                targetSymbolId: targetSymbolId,
                targetName: targetName,
                kind: kind,
                metadata: metadata,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CodeEdgesTableTable, CodeEdgesTableData>(table),
                  BaseReferences<
                    _$CodeIndexDatabase,
                    $CodeEdgesTableTable,
                    CodeEdgesTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CodeEdgesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$CodeIndexDatabase,
      $CodeEdgesTableTable,
      CodeEdgesTableData,
      $$CodeEdgesTableTableFilterComposer,
      $$CodeEdgesTableTableOrderingComposer,
      $$CodeEdgesTableTableAnnotationComposer,
      $$CodeEdgesTableTableCreateCompanionBuilder,
      $$CodeEdgesTableTableUpdateCompanionBuilder,
      (
        CodeEdgesTableData,
        BaseReferences<
          _$CodeIndexDatabase,
          $CodeEdgesTableTable,
          CodeEdgesTableData
        >,
      ),
      CodeEdgesTableData,
      PrefetchHooks Function()
    >;
typedef $$CodeFilesTableTableCreateCompanionBuilder =
    CodeFilesTableCompanion Function({
      required String id,
      required String repoId,
      Value<String?> checkoutId,
      required String path,
      required String contentHash,
      Value<int> symbolCount,
      Value<String> language,
      Value<DateTime> indexedAt,
      Value<int> rowid,
    });
typedef $$CodeFilesTableTableUpdateCompanionBuilder =
    CodeFilesTableCompanion Function({
      Value<String> id,
      Value<String> repoId,
      Value<String?> checkoutId,
      Value<String> path,
      Value<String> contentHash,
      Value<int> symbolCount,
      Value<String> language,
      Value<DateTime> indexedAt,
      Value<int> rowid,
    });

class $$CodeFilesTableTableFilterComposer
    extends Composer<_$CodeIndexDatabase, $CodeFilesTableTable> {
  $$CodeFilesTableTableFilterComposer({
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

  ColumnFilters<String> get repoId => $composableBuilder(
    column: $table.repoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checkoutId => $composableBuilder(
    column: $table.checkoutId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get symbolCount => $composableBuilder(
    column: $table.symbolCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get indexedAt => $composableBuilder(
    column: $table.indexedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CodeFilesTableTableOrderingComposer
    extends Composer<_$CodeIndexDatabase, $CodeFilesTableTable> {
  $$CodeFilesTableTableOrderingComposer({
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

  ColumnOrderings<String> get repoId => $composableBuilder(
    column: $table.repoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checkoutId => $composableBuilder(
    column: $table.checkoutId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get symbolCount => $composableBuilder(
    column: $table.symbolCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get indexedAt => $composableBuilder(
    column: $table.indexedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CodeFilesTableTableAnnotationComposer
    extends Composer<_$CodeIndexDatabase, $CodeFilesTableTable> {
  $$CodeFilesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get repoId =>
      $composableBuilder(column: $table.repoId, builder: (column) => column);

  GeneratedColumn<String> get checkoutId => $composableBuilder(
    column: $table.checkoutId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => column,
  );

  GeneratedColumn<int> get symbolCount => $composableBuilder(
    column: $table.symbolCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<DateTime> get indexedAt =>
      $composableBuilder(column: $table.indexedAt, builder: (column) => column);
}

class $$CodeFilesTableTableTableManager
    extends
        RootTableManager<
          _$CodeIndexDatabase,
          $CodeFilesTableTable,
          CodeFilesTableData,
          $$CodeFilesTableTableFilterComposer,
          $$CodeFilesTableTableOrderingComposer,
          $$CodeFilesTableTableAnnotationComposer,
          $$CodeFilesTableTableCreateCompanionBuilder,
          $$CodeFilesTableTableUpdateCompanionBuilder,
          (
            CodeFilesTableData,
            BaseReferences<
              _$CodeIndexDatabase,
              $CodeFilesTableTable,
              CodeFilesTableData
            >,
          ),
          CodeFilesTableData,
          PrefetchHooks Function()
        > {
  $$CodeFilesTableTableTableManager(
    _$CodeIndexDatabase db,
    $CodeFilesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CodeFilesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CodeFilesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CodeFilesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> repoId = const Value.absent(),
                Value<String?> checkoutId = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<String> contentHash = const Value.absent(),
                Value<int> symbolCount = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<DateTime> indexedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CodeFilesTableCompanion(
                id: id,
                repoId: repoId,
                checkoutId: checkoutId,
                path: path,
                contentHash: contentHash,
                symbolCount: symbolCount,
                language: language,
                indexedAt: indexedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String repoId,
                Value<String?> checkoutId = const Value.absent(),
                required String path,
                required String contentHash,
                Value<int> symbolCount = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<DateTime> indexedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CodeFilesTableCompanion.insert(
                id: id,
                repoId: repoId,
                checkoutId: checkoutId,
                path: path,
                contentHash: contentHash,
                symbolCount: symbolCount,
                language: language,
                indexedAt: indexedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CodeFilesTableTable, CodeFilesTableData>(table),
                  BaseReferences<
                    _$CodeIndexDatabase,
                    $CodeFilesTableTable,
                    CodeFilesTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CodeFilesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$CodeIndexDatabase,
      $CodeFilesTableTable,
      CodeFilesTableData,
      $$CodeFilesTableTableFilterComposer,
      $$CodeFilesTableTableOrderingComposer,
      $$CodeFilesTableTableAnnotationComposer,
      $$CodeFilesTableTableCreateCompanionBuilder,
      $$CodeFilesTableTableUpdateCompanionBuilder,
      (
        CodeFilesTableData,
        BaseReferences<
          _$CodeIndexDatabase,
          $CodeFilesTableTable,
          CodeFilesTableData
        >,
      ),
      CodeFilesTableData,
      PrefetchHooks Function()
    >;
typedef $$CodeIndexCheckpointsTableTableCreateCompanionBuilder =
    CodeIndexCheckpointsTableCompanion Function({
      required String id,
      required String repoId,
      Value<String?> checkoutId,
      required String headSha,
      required String worktreeDigest,
      required String indexerFingerprint,
      Value<int> generation,
      Value<int> baseGeneration,
      Value<DateTime> indexedAt,
      Value<int> rowid,
    });
typedef $$CodeIndexCheckpointsTableTableUpdateCompanionBuilder =
    CodeIndexCheckpointsTableCompanion Function({
      Value<String> id,
      Value<String> repoId,
      Value<String?> checkoutId,
      Value<String> headSha,
      Value<String> worktreeDigest,
      Value<String> indexerFingerprint,
      Value<int> generation,
      Value<int> baseGeneration,
      Value<DateTime> indexedAt,
      Value<int> rowid,
    });

class $$CodeIndexCheckpointsTableTableFilterComposer
    extends Composer<_$CodeIndexDatabase, $CodeIndexCheckpointsTableTable> {
  $$CodeIndexCheckpointsTableTableFilterComposer({
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

  ColumnFilters<String> get repoId => $composableBuilder(
    column: $table.repoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checkoutId => $composableBuilder(
    column: $table.checkoutId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get headSha => $composableBuilder(
    column: $table.headSha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get worktreeDigest => $composableBuilder(
    column: $table.worktreeDigest,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get indexerFingerprint => $composableBuilder(
    column: $table.indexerFingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get generation => $composableBuilder(
    column: $table.generation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseGeneration => $composableBuilder(
    column: $table.baseGeneration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get indexedAt => $composableBuilder(
    column: $table.indexedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CodeIndexCheckpointsTableTableOrderingComposer
    extends Composer<_$CodeIndexDatabase, $CodeIndexCheckpointsTableTable> {
  $$CodeIndexCheckpointsTableTableOrderingComposer({
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

  ColumnOrderings<String> get repoId => $composableBuilder(
    column: $table.repoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checkoutId => $composableBuilder(
    column: $table.checkoutId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get headSha => $composableBuilder(
    column: $table.headSha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get worktreeDigest => $composableBuilder(
    column: $table.worktreeDigest,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get indexerFingerprint => $composableBuilder(
    column: $table.indexerFingerprint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get generation => $composableBuilder(
    column: $table.generation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseGeneration => $composableBuilder(
    column: $table.baseGeneration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get indexedAt => $composableBuilder(
    column: $table.indexedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CodeIndexCheckpointsTableTableAnnotationComposer
    extends Composer<_$CodeIndexDatabase, $CodeIndexCheckpointsTableTable> {
  $$CodeIndexCheckpointsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get repoId =>
      $composableBuilder(column: $table.repoId, builder: (column) => column);

  GeneratedColumn<String> get checkoutId => $composableBuilder(
    column: $table.checkoutId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get headSha =>
      $composableBuilder(column: $table.headSha, builder: (column) => column);

  GeneratedColumn<String> get worktreeDigest => $composableBuilder(
    column: $table.worktreeDigest,
    builder: (column) => column,
  );

  GeneratedColumn<String> get indexerFingerprint => $composableBuilder(
    column: $table.indexerFingerprint,
    builder: (column) => column,
  );

  GeneratedColumn<int> get generation => $composableBuilder(
    column: $table.generation,
    builder: (column) => column,
  );

  GeneratedColumn<int> get baseGeneration => $composableBuilder(
    column: $table.baseGeneration,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get indexedAt =>
      $composableBuilder(column: $table.indexedAt, builder: (column) => column);
}

class $$CodeIndexCheckpointsTableTableTableManager
    extends
        RootTableManager<
          _$CodeIndexDatabase,
          $CodeIndexCheckpointsTableTable,
          CodeIndexCheckpointsTableData,
          $$CodeIndexCheckpointsTableTableFilterComposer,
          $$CodeIndexCheckpointsTableTableOrderingComposer,
          $$CodeIndexCheckpointsTableTableAnnotationComposer,
          $$CodeIndexCheckpointsTableTableCreateCompanionBuilder,
          $$CodeIndexCheckpointsTableTableUpdateCompanionBuilder,
          (
            CodeIndexCheckpointsTableData,
            BaseReferences<
              _$CodeIndexDatabase,
              $CodeIndexCheckpointsTableTable,
              CodeIndexCheckpointsTableData
            >,
          ),
          CodeIndexCheckpointsTableData,
          PrefetchHooks Function()
        > {
  $$CodeIndexCheckpointsTableTableTableManager(
    _$CodeIndexDatabase db,
    $CodeIndexCheckpointsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CodeIndexCheckpointsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CodeIndexCheckpointsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CodeIndexCheckpointsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> repoId = const Value.absent(),
                Value<String?> checkoutId = const Value.absent(),
                Value<String> headSha = const Value.absent(),
                Value<String> worktreeDigest = const Value.absent(),
                Value<String> indexerFingerprint = const Value.absent(),
                Value<int> generation = const Value.absent(),
                Value<int> baseGeneration = const Value.absent(),
                Value<DateTime> indexedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CodeIndexCheckpointsTableCompanion(
                id: id,
                repoId: repoId,
                checkoutId: checkoutId,
                headSha: headSha,
                worktreeDigest: worktreeDigest,
                indexerFingerprint: indexerFingerprint,
                generation: generation,
                baseGeneration: baseGeneration,
                indexedAt: indexedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String repoId,
                Value<String?> checkoutId = const Value.absent(),
                required String headSha,
                required String worktreeDigest,
                required String indexerFingerprint,
                Value<int> generation = const Value.absent(),
                Value<int> baseGeneration = const Value.absent(),
                Value<DateTime> indexedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CodeIndexCheckpointsTableCompanion.insert(
                id: id,
                repoId: repoId,
                checkoutId: checkoutId,
                headSha: headSha,
                worktreeDigest: worktreeDigest,
                indexerFingerprint: indexerFingerprint,
                generation: generation,
                baseGeneration: baseGeneration,
                indexedAt: indexedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $CodeIndexCheckpointsTableTable,
                    CodeIndexCheckpointsTableData
                  >(table),
                  BaseReferences<
                    _$CodeIndexDatabase,
                    $CodeIndexCheckpointsTableTable,
                    CodeIndexCheckpointsTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CodeIndexCheckpointsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$CodeIndexDatabase,
      $CodeIndexCheckpointsTableTable,
      CodeIndexCheckpointsTableData,
      $$CodeIndexCheckpointsTableTableFilterComposer,
      $$CodeIndexCheckpointsTableTableOrderingComposer,
      $$CodeIndexCheckpointsTableTableAnnotationComposer,
      $$CodeIndexCheckpointsTableTableCreateCompanionBuilder,
      $$CodeIndexCheckpointsTableTableUpdateCompanionBuilder,
      (
        CodeIndexCheckpointsTableData,
        BaseReferences<
          _$CodeIndexDatabase,
          $CodeIndexCheckpointsTableTable,
          CodeIndexCheckpointsTableData
        >,
      ),
      CodeIndexCheckpointsTableData,
      PrefetchHooks Function()
    >;

class $CodeIndexDatabaseManager {
  final _$CodeIndexDatabase _db;
  $CodeIndexDatabaseManager(this._db);
  $$CodeSymbolsTableTableTableManager get codeSymbolsTable =>
      $$CodeSymbolsTableTableTableManager(_db, _db.codeSymbolsTable);
  $$CodeSymbolEmbeddingsTableTableTableManager get codeSymbolEmbeddingsTable =>
      $$CodeSymbolEmbeddingsTableTableTableManager(
        _db,
        _db.codeSymbolEmbeddingsTable,
      );
  $$CodeEdgesTableTableTableManager get codeEdgesTable =>
      $$CodeEdgesTableTableTableManager(_db, _db.codeEdgesTable);
  $$CodeFilesTableTableTableManager get codeFilesTable =>
      $$CodeFilesTableTableTableManager(_db, _db.codeFilesTable);
  $$CodeIndexCheckpointsTableTableTableManager get codeIndexCheckpointsTable =>
      $$CodeIndexCheckpointsTableTableTableManager(
        _db,
        _db.codeIndexCheckpointsTable,
      );
}
