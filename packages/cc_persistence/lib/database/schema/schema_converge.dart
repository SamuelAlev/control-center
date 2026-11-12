import 'package:drift/drift.dart';

/// One row of `sqlite_master`: a table, index, trigger or view and the SQL
/// that created it.
final class SchemaObject {
  /// Creates a schema object.
  SchemaObject({
    required this.type,
    required this.name,
    required this.table,
    required this.sql,
  });

  /// `table`, `index`, `trigger` or `view`.
  final String type;

  /// The object's own name.
  final String name;

  /// The table the object belongs to (its own name for a table).
  final String table;

  /// The stored `CREATE …` text. Null for an index SQLite made on its own
  /// (a primary key or a `UNIQUE` column).
  final String? sql;

  /// [sql] with every run of whitespace collapsed, so two statements that
  /// differ only in layout compare equal.
  ///
  /// Computed once: a schema of several hundred objects is compared object
  /// against object.
  late final String normalizedSql = normalizeSchemaSql(sql);

  /// Whether this is a virtual table (FTS5, for example).
  late final bool isVirtualTable =
      type == 'table' && normalizedSql.startsWith('CREATE VIRTUAL TABLE');

  @override
  String toString() => '$type $name: $normalizedSql';
}

/// Collapses whitespace in a stored `CREATE …` statement.
String normalizeSchemaSql(String? sql) =>
    (sql ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();

/// The schema a database holds, read from `sqlite_master`.
///
/// Built once from a fresh in-memory instance of a database class, it is what
/// "the schema this binary declares" means: an existing file is brought to it
/// by [SchemaConverger], and an imported file is compared against it.
final class SchemaSnapshot {
  /// Wraps [objects] as read from `sqlite_master`.
  SchemaSnapshot(List<SchemaObject> objects)
    : objects = List.unmodifiable(objects),
      _byName = {for (final object in objects) object.name: object};

  /// Every object, in creation order.
  final List<SchemaObject> objects;

  final Map<String, SchemaObject> _byName;

  /// The object called [name], if the schema has one.
  SchemaObject? operator [](String name) => _byName[name];

  /// Ordinary tables (not virtual ones, not their shadow tables).
  Iterable<SchemaObject> get tables => objects.where(
    (o) => o.type == 'table' && !o.isVirtualTable && !isShadowTable(o.name),
  );

  /// Virtual tables.
  late final List<SchemaObject> virtualTables = List.unmodifiable(
    objects.where((o) => o.isVirtualTable),
  );

  late final List<String> _shadowPrefixes = [
    for (final virtual in virtualTables) '${virtual.name}_',
  ];

  /// Indexes created by a statement (not the automatic ones).
  Iterable<SchemaObject> get indexes =>
      objects.where((o) => o.type == 'index' && o.sql != null);

  /// Whether [name] is a shadow table of one of this schema's virtual tables
  /// (`<fts>_data`, `<fts>_idx`, …). SQLite owns those; they are never
  /// created, compared or dropped directly.
  bool isShadowTable(String name) => _shadowPrefixes.any(name.startsWith);

  /// This schema without [tables] and everything that belongs to them
  /// (their indexes and triggers).
  ///
  /// For tables an SQLite extension creates on its own in every connection:
  /// whether one shows up in a freshly built schema depends on whether the
  /// extension happens to be loaded in the process, so it is never part of
  /// what a database declares.
  SchemaSnapshot without(Set<String> tables) => tables.isEmpty
      ? this
      : SchemaSnapshot([
          for (final object in objects)
            if (!tables.contains(object.name) && !tables.contains(object.table))
              object,
        ]);

  /// Reads the schema of [db].
  ///
  /// `sqlite_%` objects (the sequence and statistics tables) are SQLite's own
  /// and are left out.
  static Future<SchemaSnapshot> read(DatabaseConnectionUser db) async {
    final rows = await db
        .customSelect(
          'SELECT type, name, tbl_name, sql FROM sqlite_master '
          "WHERE name NOT LIKE 'sqlite_%' ORDER BY rowid",
        )
        .get();
    return SchemaSnapshot([
      for (final row in rows)
        SchemaObject(
          type: row.read<String>('type'),
          name: row.read<String>('name'),
          table: row.read<String>('tbl_name'),
          sql: row.readNullable<String>('sql'),
        ),
    ]);
  }

  /// The differences between this schema and [declared], as readable lines.
  /// Empty when the two hold the same objects with the same SQL.
  ///
  /// [ignore] names tables an extension owns (and their indexes).
  List<String> differencesFrom(
    SchemaSnapshot declared, {
    Set<String> ignore = const {},
  }) {
    bool skipped(SchemaObject o) =>
        ignore.contains(o.name) ||
        ignore.contains(o.table) ||
        isShadowTable(o.name) ||
        declared.isShadowTable(o.name);
    final differences = <String>[];
    for (final object in objects) {
      if (skipped(object) || (object.type == 'index' && object.sql == null)) {
        continue;
      }
      final wanted = declared[object.name];
      if (wanted == null) {
        differences.add('unexpected ${object.type} ${object.name}');
      } else if (wanted.type != object.type ||
          wanted.normalizedSql != object.normalizedSql) {
        differences.add('${object.type} ${object.name} differs');
      }
    }
    for (final wanted in declared.objects) {
      if (skipped(wanted) || (wanted.type == 'index' && wanted.sql == null)) {
        continue;
      }
      if (this[wanted.name] == null) {
        differences.add('missing ${wanted.type} ${wanted.name}');
      }
    }
    return differences;
  }
}

/// What one [SchemaConverger.converge] run changed.
final class SchemaConvergeReport {
  /// Tables created because the file did not have them.
  final List<String> createdTables = [];

  /// Tables rebuilt because their definition differed.
  final List<String> rebuiltTables = [];

  /// Tables dropped because the schema no longer declares them.
  final List<String> droppedTables = [];

  /// Indexes created or replaced.
  final List<String> createdIndexes = [];

  /// Indexes dropped because the schema no longer declares them.
  final List<String> droppedIndexes = [];

  /// Rows left behind per table: they violated a constraint of the declared
  /// table, duplicated a unique key, or pointed at a parent that is gone.
  final Map<String, int> droppedRows = {};

  /// Orphaned references cleared per `table.column` (the row stays).
  final Map<String, int> clearedReferences = {};

  /// Whether anything in the file changed.
  bool get changedAnything =>
      createdTables.isNotEmpty ||
      rebuiltTables.isNotEmpty ||
      droppedTables.isNotEmpty ||
      createdIndexes.isNotEmpty ||
      droppedIndexes.isNotEmpty ||
      droppedRows.isNotEmpty ||
      clearedReferences.isNotEmpty;

  void _dropRows(String table, int count) {
    if (count > 0) {
      droppedRows[table] = (droppedRows[table] ?? 0) + count;
    }
  }

  /// A one-line summary for the log.
  String describe() {
    String counts(Map<String, int> map) =>
        map.entries.map((e) => '${e.key}=${e.value}').join(', ');
    final rowsLeft = 'rows left behind: ${counts(droppedRows)}';
    final cleared = 'references cleared: ${counts(clearedReferences)}';
    final parts = <String>[
      if (createdTables.isNotEmpty) 'created ${createdTables.join(', ')}',
      if (rebuiltTables.isNotEmpty) 'rebuilt ${rebuiltTables.join(', ')}',
      if (droppedTables.isNotEmpty) 'dropped ${droppedTables.join(', ')}',
      if (createdIndexes.isNotEmpty) '${createdIndexes.length} indexes created',
      if (droppedIndexes.isNotEmpty) '${droppedIndexes.length} indexes dropped',
      if (droppedRows.isNotEmpty) rowsLeft,
      if (clearedReferences.isNotEmpty) cleared,
    ];
    return parts.isEmpty ? 'no change' : parts.join('; ');
  }
}

/// Brings a database file to the schema its class declares, in one
/// transaction.
///
/// There is no ladder of hand-written steps. A file of any earlier version is
/// compared with [declared] object by object:
///
/// * a table the file lacks is created;
/// * a table whose definition differs is rebuilt: the declared table is
///   created, rows are copied column by column (by name), the old table is
///   dropped. A column the file lacks takes its default; a column the schema
///   no longer declares is not copied. Nothing is transformed on the way;
/// * a table, index, trigger or view the schema does not declare is dropped;
/// * indexes are dropped and created to match;
/// * rows that cannot live under the declared constraints are left behind
///   and counted in the report, and references to a missing parent are
///   cleared (`ON DELETE SET NULL`) or their rows removed.
///
/// The version stamp is written inside the same transaction, so a failure
/// leaves the file exactly as it was, at its old version. Because every file
/// ends at the declared schema by construction, a fresh install and an
/// upgraded one cannot drift apart.
final class SchemaConverger {
  /// Creates a converger for one database.
  ///
  /// [fills] supplies a value for a `NOT NULL` column whose old value is
  /// missing or NULL, keyed by column name. It is bound, never interpolated.
  /// [preserve] names tables an SQLite extension owns: never rebuilt, never
  /// dropped. [version] and [applicationId] are stamped at the end.
  SchemaConverger({
    required this._db,
    required this.declared,
    required this.version,
    required this.applicationId,
    this.fills = const {},
    this.preserve = const {},
  });

  final DatabaseConnectionUser _db;

  /// The schema to converge to.
  final SchemaSnapshot declared;

  /// The `user_version` stamped when the run commits.
  final int version;

  /// The `application_id` stamped when the run commits.
  final int applicationId;

  /// Values for `NOT NULL` columns the old rows cannot supply.
  final Map<String, Object> fills;

  /// Extension-owned tables left alone.
  final Set<String> preserve;

  static const _oldPrefix = '__cc_converge_old_';

  /// Runs the convergence. Must not be called inside a transaction:
  /// `PRAGMA foreign_keys` cannot change inside one.
  Future<SchemaConvergeReport> converge() async {
    final report = SchemaConvergeReport();
    // Enforcement is off for the duration: dropping a table would otherwise
    // cascade into its children, and rows are checked as a whole at the end.
    // `legacy_alter_table` keeps `REFERENCES x` in other tables pointing at
    // the name `x` while the old `x` is renamed out of the way.
    await _db.customStatement('PRAGMA foreign_keys = OFF');
    await _db.customStatement('PRAGMA legacy_alter_table = ON');
    try {
      await _db.transaction(() async {
        await _dropLeftoverRebuilds();
        await _dropTriggersAndViews();
        await _dropStaleVirtualTables();
        final current = await SchemaSnapshot.read(_db);
        for (final table in declared.tables) {
          if (preserve.contains(table.name)) {
            continue;
          }
          final existing = current[table.name];
          if (existing == null) {
            await _db.customStatement(table.sql!);
            report.createdTables.add(table.name);
          } else if (existing.type != 'table' ||
              existing.normalizedSql != table.normalizedSql) {
            await _rebuild(table, report);
          }
        }
        await _dropUndeclaredTables(report);
        await _convergeIndexes(report);
        await _repairForeignKeys(report);
        await _db.customStatement('PRAGMA application_id = $applicationId');
        await _db.customStatement('PRAGMA user_version = $version');
      });
    } finally {
      await _db.customStatement('PRAGMA legacy_alter_table = OFF');
      await _db.customStatement('PRAGMA foreign_keys = ON');
    }
    return report;
  }

  /// Removes tables a crashed earlier run could not have left (the run is one
  /// transaction) but a hand-edited file might carry.
  Future<void> _dropLeftoverRebuilds() async {
    final rows = await _db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name LIKE '$_oldPrefix%'",
        )
        .get();
    for (final row in rows) {
      await _db.customStatement(
        'DROP TABLE ${_quote(row.read<String>('name'))}',
      );
    }
  }

  /// Triggers and views are never data. The ones the schema declares are
  /// installed again when the database opens; any other one is somebody
  /// else's code that would run inside this server's statements.
  Future<void> _dropTriggersAndViews() async {
    final rows = await _db
        .customSelect(
          'SELECT type, name FROM sqlite_master '
          "WHERE type IN ('trigger', 'view')",
        )
        .get();
    for (final row in rows) {
      final kind = row.read<String>('type') == 'view' ? 'VIEW' : 'TRIGGER';
      await _db.customStatement(
        'DROP $kind IF EXISTS ${_quote(row.read<String>('name'))}',
      );
    }
  }

  Future<void> _dropStaleVirtualTables() async {
    final current = await SchemaSnapshot.read(_db);
    for (final virtual in current.virtualTables) {
      final wanted = declared[virtual.name];
      if (wanted == null || wanted.normalizedSql != virtual.normalizedSql) {
        await _db.customStatement('DROP TABLE ${_quote(virtual.name)}');
      }
    }
  }

  Future<void> _rebuild(SchemaObject table, SchemaConvergeReport report) async {
    final name = table.name;
    final old = '$_oldPrefix$name';
    await _db.customStatement(
      'ALTER TABLE ${_quote(name)} RENAME TO ${_quote(old)}',
    );
    // The old table keeps its indexes under their names, and index names are
    // global: they must go before the declared ones are created.
    final oldIndexes = await _db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' "
          'AND tbl_name = ? AND sql IS NOT NULL',
          variables: [Variable.withString(old)],
        )
        .get();
    for (final row in oldIndexes) {
      await _db.customStatement(
        'DROP INDEX ${_quote(row.read<String>('name'))}',
      );
    }
    await _db.customStatement(table.sql!);

    final oldColumns = await _columns(old);
    final newColumns = await _columns(name);
    final oldByName = {for (final column in oldColumns) column.name: column};
    final targets = <String>[];
    final sources = <String>[];
    final args = <Object?>[];
    final keepRowid =
        !_isWithoutRowid(table.sql!) &&
        !await _wasWithoutRowid(old) &&
        !newColumns.any((c) => c.isRowidAlias);
    if (keepRowid) {
      // External-content FTS indexes address rows by rowid, so a rebuilt
      // table must keep the ones its rows had.
      targets.add('rowid');
      sources.add('rowid');
    }
    for (final column in newColumns) {
      if (column.isGenerated) {
        continue;
      }
      final source = oldByName[column.name];
      final fill = fills[column.name];
      if (source != null) {
        targets.add(_quote(column.name));
        if (column.notNull && fill != null) {
          sources.add('COALESCE(${_quote(column.name)}, ?)');
          args.add(fill);
        } else {
          sources.add(_quote(column.name));
        }
      } else if (fill != null) {
        targets.add(_quote(column.name));
        sources.add('?');
        args.add(fill);
      } else if (column.notNull && column.defaultValue == null) {
        // No default and nothing to copy: the type's zero value, so the
        // table's other columns are not lost with the row.
        targets.add(_quote(column.name));
        sources.add(column.zeroLiteral);
      }
    }
    final before = await _count(old);
    await _db.customStatement(
      'INSERT OR IGNORE INTO ${_quote(name)} (${targets.join(', ')}) '
      'SELECT ${sources.join(', ')} FROM ${_quote(old)}',
      args,
    );
    final after = await _count(name);
    report._dropRows(name, before - after);
    await _db.customStatement('DROP TABLE ${_quote(old)}');
    report.rebuiltTables.add(name);
  }

  Future<void> _dropUndeclaredTables(SchemaConvergeReport report) async {
    final current = await SchemaSnapshot.read(_db);
    for (final table in current.tables.toList()) {
      if (declared[table.name] != null ||
          preserve.contains(table.name) ||
          declared.isShadowTable(table.name)) {
        continue;
      }
      await _db.customStatement('DROP TABLE ${_quote(table.name)}');
      report.droppedTables.add(table.name);
    }
  }

  Future<void> _convergeIndexes(SchemaConvergeReport report) async {
    final current = await SchemaSnapshot.read(_db);
    for (final index in current.indexes.toList()) {
      if (preserve.contains(index.table)) {
        continue;
      }
      final wanted = declared[index.name];
      if (wanted == null ||
          wanted.type != 'index' ||
          wanted.normalizedSql != index.normalizedSql) {
        await _db.customStatement('DROP INDEX ${_quote(index.name)}');
        if (wanted == null) {
          report.droppedIndexes.add(index.name);
        }
      }
    }
    final remaining = await SchemaSnapshot.read(_db);
    for (final index in declared.indexes) {
      if (preserve.contains(index.table) || remaining[index.name] != null) {
        continue;
      }
      await _createIndex(index, report);
      report.createdIndexes.add(index.name);
    }
  }

  /// Creates [index]; when it is unique and the rows already hold duplicates
  /// of its key, keeps the newest row of each duplicate group first.
  Future<void> _createIndex(
    SchemaObject index,
    SchemaConvergeReport report,
  ) async {
    final key = _UniqueIndexKey.tryParse(index);
    if (key != null && !await _wasWithoutRowid(index.table)) {
      final table = _quote(index.table);
      final notNull = key.expressions
          .map((e) => '($e) IS NOT NULL')
          .join(' AND ');
      final where = key.where == null ? notNull : '(${key.where}) AND $notNull';
      final before = await _count(index.table);
      await _db.customStatement(
        'DELETE FROM $table WHERE rowid IN ('
        'SELECT rowid FROM ('
        'SELECT rowid, ROW_NUMBER() OVER ('
        'PARTITION BY ${key.expressions.join(', ')} ORDER BY rowid DESC'
        ') AS duplicate_rank FROM $table WHERE $where'
        ') WHERE duplicate_rank > 1)',
      );
      report._dropRows(index.table, before - await _count(index.table));
    }
    await _db.customStatement(index.sql!);
  }

  /// Makes every remaining row satisfy its foreign keys.
  ///
  /// A reference declared `ON DELETE SET NULL` is cleared; any other orphan
  /// row is removed. Removing a row can orphan its own children (enforcement
  /// is off, so nothing cascades), hence the loop.
  Future<void> _repairForeignKeys(SchemaConvergeReport report) async {
    for (var pass = 0; pass < 32; pass++) {
      final violations = await _db
          .customSelect('PRAGMA foreign_key_check')
          .get();
      if (violations.isEmpty) {
        return;
      }
      final grouped = <(String, int), List<int>>{};
      final rowidless = <(String, int)>{};
      for (final row in violations) {
        final key = (row.read<String>('table'), row.read<int>('fkid'));
        final rowid = row.readNullable<int>('rowid');
        if (rowid == null) {
          rowidless.add(key);
        } else {
          grouped.putIfAbsent(key, () => []).add(rowid);
        }
      }
      if (rowidless.isNotEmpty) {
        final names = rowidless.map((k) => k.$1).toSet().join(', ');
        throw StateError(
          'orphan rows in a WITHOUT ROWID table cannot be repaired: $names',
        );
      }
      for (final MapEntry(key: (table, fkId), value: rowids)
          in grouped.entries) {
        final keys = await _db
            .customSelect('PRAGMA foreign_key_list(${_quote(table)})')
            .get();
        final columns = [
          for (final row in keys)
            if (row.read<int>('id') == fkId) row,
        ];
        final setNull =
            columns.isNotEmpty &&
            columns.every(
              (c) => c.read<String>('on_delete').toUpperCase() == 'SET NULL',
            );
        for (var start = 0; start < rowids.length; start += 500) {
          final end = start + 500 < rowids.length ? start + 500 : rowids.length;
          final chunk = rowids.sublist(start, end).join(', ');
          if (setNull) {
            final assignments = columns
                .map((c) => '${_quote(c.read<String>('from'))} = NULL')
                .join(', ');
            await _db.customStatement(
              'UPDATE ${_quote(table)} SET $assignments '
              'WHERE rowid IN ($chunk)',
            );
          } else {
            await _db.customStatement(
              'DELETE FROM ${_quote(table)} WHERE rowid IN ($chunk)',
            );
          }
        }
        if (setNull) {
          for (final column in columns) {
            final label = '$table.${column.read<String>('from')}';
            report.clearedReferences[label] =
                (report.clearedReferences[label] ?? 0) + rowids.length;
          }
        } else {
          report._dropRows(table, rowids.length);
        }
      }
    }
    throw StateError('foreign keys still violated after repair');
  }

  Future<List<_Column>> _columns(String table) async {
    final rows = await _db
        .customSelect('PRAGMA table_xinfo(${_quote(table)})')
        .get();
    final primaryKeyColumns = rows.where((r) => r.read<int>('pk') > 0).length;
    return [
      for (final row in rows)
        _Column(
          name: row.read<String>('name'),
          type: row.read<String>('type').toUpperCase(),
          notNull: row.read<int>('notnull') != 0,
          defaultValue: row.readNullable<String>('dflt_value'),
          isGenerated: row.read<int>('hidden') != 0,
          isRowidAlias:
              primaryKeyColumns == 1 &&
              row.read<int>('pk') == 1 &&
              row.read<String>('type').toUpperCase() == 'INTEGER',
        ),
    ];
  }

  Future<int> _count(String table) async {
    final row = await _db
        .customSelect('SELECT COUNT(*) AS c FROM ${_quote(table)}')
        .getSingle();
    return row.read<int>('c');
  }

  Future<bool> _wasWithoutRowid(String table) async {
    final row = await _db
        .customSelect(
          "SELECT sql FROM sqlite_master WHERE type = 'table' AND name = ?",
          variables: [Variable.withString(table)],
        )
        .getSingleOrNull();
    return _isWithoutRowid(row?.readNullable<String>('sql') ?? '');
  }

  static bool _isWithoutRowid(String sql) =>
      RegExp(r'\)\s*WITHOUT\s+ROWID', caseSensitive: false).hasMatch(sql);

  static String _quote(String identifier) =>
      '"${identifier.replaceAll('"', '""')}"';
}

final class _Column {
  const _Column({
    required this.name,
    required this.type,
    required this.notNull,
    required this.defaultValue,
    required this.isGenerated,
    required this.isRowidAlias,
  });

  final String name;
  final String type;
  final bool notNull;
  final String? defaultValue;
  final bool isGenerated;
  final bool isRowidAlias;

  /// The zero value of this column's storage class.
  String get zeroLiteral {
    if (type.contains('INT') ||
        type.contains('REAL') ||
        type.contains('FLOA') ||
        type.contains('DOUB') ||
        type.contains('NUM') ||
        type.contains('BOOL')) {
      return '0';
    }
    if (type.contains('BLOB')) {
      return "x''";
    }
    return "''";
  }
}

/// The key expressions and predicate of a `CREATE UNIQUE INDEX` statement.
final class _UniqueIndexKey {
  const _UniqueIndexKey(this.expressions, this.where);

  final List<String> expressions;
  final String? where;

  static _UniqueIndexKey? tryParse(SchemaObject index) {
    final sql = index.normalizedSql;
    if (!sql.toUpperCase().startsWith('CREATE UNIQUE INDEX')) {
      return null;
    }
    final on = RegExp(r'\sON\s', caseSensitive: false).firstMatch(sql);
    if (on == null) {
      return null;
    }
    final open = sql.indexOf('(', on.end);
    if (open < 0) {
      return null;
    }
    var depth = 0;
    var close = -1;
    var inString = false;
    final parts = <String>[];
    var partStart = open + 1;
    for (var i = open; i < sql.length; i++) {
      final char = sql[i];
      if (char == "'") {
        inString = !inString;
      }
      if (inString) {
        continue;
      }
      if (char == '(') {
        depth++;
      } else if (char == ')') {
        depth--;
        if (depth == 0) {
          parts.add(sql.substring(partStart, i));
          close = i;
          break;
        }
      } else if (char == ',' && depth == 1) {
        parts.add(sql.substring(partStart, i));
        partStart = i + 1;
      }
    }
    if (close < 0) {
      return null;
    }
    final direction = RegExp(r'\s+(ASC|DESC)$', caseSensitive: false);
    final expressions = [
      for (final part in parts) part.trim().replaceAll(direction, ''),
    ];
    final rest = sql.substring(close + 1).trim();
    final where = rest.toUpperCase().startsWith('WHERE ')
        ? rest.substring(6).trim()
        : null;
    return _UniqueIndexKey(expressions, where);
  }
}
