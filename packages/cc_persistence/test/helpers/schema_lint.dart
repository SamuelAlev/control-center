import 'package:drift/drift.dart';

/// One rule of the declared schema that a table breaks.
final class SchemaViolation {
  /// Creates a violation of [rule] on [table].
  const SchemaViolation(this.rule, this.table, this.detail);

  /// The short name of the rule.
  final String rule;

  /// The table that breaks it.
  final String table;

  /// What exactly is wrong, naming the column or index.
  final String detail;

  @override
  String toString() => '$table: [$rule] $detail';
}

/// One index of a table, as SQLite reports it.
final class _Index {
  _Index({
    required this.name,
    required this.columns,
    required this.unique,
    required this.partial,
    required this.origin,
  });

  final String name;

  /// Key columns in order. An expression column is null.
  final List<String?> columns;
  final bool unique;
  final bool partial;

  /// `c` created by a statement, `u` a UNIQUE constraint, `pk` a primary key.
  final String origin;

  bool get hasExpression => columns.contains(null);
}

/// The structural rules every declared table follows, checked against a live
/// (in-memory) instance of the database rather than against the Dart
/// declarations, so a rule cannot be satisfied on paper only.
///
/// [perWorkspaceFile] turns on the rules that only make sense in a file that
/// holds one workspace (`workspace_id` never selects anything there).
Future<List<SchemaViolation>> lintSchema(
  GeneratedDatabase db, {
  required bool perWorkspaceFile,
  Set<String> jsonColumnNames = const {},
}) async {
  final violations = <SchemaViolation>[];
  final tables = [
    for (final row
        in await db
            .customSelect(
              "SELECT name, sql FROM sqlite_master WHERE type = 'table' "
              "AND name NOT LIKE 'sqlite_%' AND name NOT LIKE '\\_%' ESCAPE '\\' "
              "AND sql NOT LIKE 'CREATE VIRTUAL TABLE%' ORDER BY name",
            )
            .get())
      (row.read<String>('name'), row.read<String>('sql')),
  ];
  final virtual = [
    for (final row
        in await db
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type = 'table' "
              "AND sql LIKE 'CREATE VIRTUAL TABLE%'",
            )
            .get())
      row.read<String>('name'),
  ];

  for (final (table, sql) in tables) {
    if (virtual.any((v) => table.startsWith('${v}_'))) {
      continue;
    }
    void report(String rule, String detail) =>
        violations.add(SchemaViolation(rule, table, detail));

    final columns = await db.customSelect('PRAGMA table_info("$table")').get();
    final notNull = {
      for (final c in columns)
        c.read<String>('name'): c.read<int>('notnull') != 0,
    };
    final primaryKey =
        columns.where((c) => c.read<int>('pk') > 0).toList()
          ..sort((a, b) => a.read<int>('pk').compareTo(b.read<int>('pk')));
    final indexes = <_Index>[
      if (primaryKey.isNotEmpty)
        _Index(
          name: 'PRIMARY KEY',
          columns: [for (final c in primaryKey) c.read<String>('name')],
          unique: true,
          partial: false,
          origin: 'pk',
        ),
    ];
    for (final row
        in await db.customSelect('PRAGMA index_list("$table")').get()) {
      final name = row.read<String>('name');
      if (row.read<String>('origin') == 'pk') {
        continue;
      }
      final info = await db.customSelect('PRAGMA index_xinfo("$name")').get();
      indexes.add(
        _Index(
          name: name,
          columns: [
            for (final c in info)
              if (c.read<int>('key') == 1) c.readNullable<String>('name'),
          ],
          unique: row.read<int>('unique') != 0,
          partial: row.read<int>('partial') != 0,
          origin: row.read<String>('origin'),
        ),
      );
    }

    // workspace_id
    if (notNull.containsKey('workspace_id')) {
      if (!notNull['workspace_id']!) {
        report('workspace-id-not-null', 'workspace_id is nullable');
      }
      if (perWorkspaceFile) {
        for (final index in indexes) {
          // A table with one row per workspace is keyed by the id alone;
          // that key is the row's identity, not a filter.
          final singleton = index.unique && index.columns.length == 1;
          if (index.columns.firstOrNull == 'workspace_id' && !singleton) {
            report(
              'workspace-id-leads-key',
              '${index.name} (${index.columns.join(', ')}) starts with '
                  'workspace_id, which holds one value in this file',
            );
          }
        }
      }
    }

    // An index that is the leading part of another one filters nothing the
    // longer one cannot.
    for (final short in indexes) {
      if (short.origin != 'c' ||
          short.unique ||
          short.partial ||
          short.hasExpression) {
        continue;
      }
      for (final long in indexes) {
        if (identical(short, long) || long.partial || long.hasExpression) {
          continue;
        }
        final isPrefix =
            long.columns.length > short.columns.length &&
            _startsWith(long.columns, short.columns);
        final isDuplicate =
            long.columns.length == short.columns.length &&
            _startsWith(long.columns, short.columns) &&
            (long.unique || long.name.compareTo(short.name) < 0);
        if (isPrefix || isDuplicate) {
          report(
            'redundant-index',
            '${short.name} (${short.columns.join(', ')}) is covered by '
                '${long.name} (${long.columns.join(', ')})',
          );
          break;
        }
      }
    }

    // Foreign keys.
    final keys = await db
        .customSelect('PRAGMA foreign_key_list("$table")')
        .get();
    final byId = <int, List<QueryRow>>{};
    for (final key in keys) {
      byId.putIfAbsent(key.read<int>('id'), () => []).add(key);
    }
    for (final parts in byId.values) {
      parts.sort((a, b) => a.read<int>('seq').compareTo(b.read<int>('seq')));
      final from = [for (final p in parts) p.read<String>('from')];
      final parent = parts.first.read<String>('table');
      final onDelete = parts.first.read<String>('on_delete').toUpperCase();
      if (onDelete == 'SET NULL' && from.any((c) => notNull[c] ?? false)) {
        report(
          'set-null-on-not-null',
          '(${from.join(', ')}) -> $parent is ON DELETE SET NULL but the '
              'column is NOT NULL, so deleting the parent fails',
        );
      }
      if (onDelete == 'NO ACTION' || onDelete == 'RESTRICT') {
        // Deliberate: the parent cannot go while the child exists.
      }
      final covered = indexes.any(
        (index) => !index.partial && _startsWith(index.columns, from),
      );
      if (!covered) {
        report(
          'foreign-key-unindexed',
          '(${from.join(', ')}) -> $parent has no index starting with it, so '
              'every delete of a parent scans this table',
        );
      }
    }

    // JSON columns.
    final normalized = sql.replaceAll(RegExp(r'\s+'), ' ');
    for (final column in columns) {
      final name = column.read<String>('name');
      final type = column.read<String>('type').toUpperCase();
      final looksJson =
          name.endsWith('_json') || jsonColumnNames.contains('$table.$name');
      if (!looksJson || !type.contains('TEXT')) {
        continue;
      }
      if (!normalized.contains('json_valid("$name")')) {
        report('json-unchecked', '$name holds JSON without a json_valid CHECK');
      }
    }
  }
  return violations;
}

bool _startsWith(List<String?> columns, List<String?> prefix) {
  if (columns.length < prefix.length) {
    return false;
  }
  for (var i = 0; i < prefix.length; i++) {
    if (columns[i] == null || columns[i] != prefix[i]) {
      return false;
    }
  }
  return true;
}
