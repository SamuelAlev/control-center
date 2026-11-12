import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// A database with no declared tables: a connection to run raw SQL through
/// and to hand to the schema converger.
final class RawDatabase extends GeneratedDatabase {
  /// Opens [executor] at [version] without creating anything.
  RawDatabase(super.executor, {this.version = 1});

  /// An in-memory database.
  RawDatabase.memory() : this(NativeDatabase.memory());

  /// The `user_version` drift stamps on a new file.
  final int version;

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  int get schemaVersion => version;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (_) async {},
    onUpgrade: (_, _, _) async {},
  );
}

/// The schema of a database file as an install really had it: every
/// `sqlite_master` row of a file written by an earlier build, captured from a
/// running install (schema only, no rows).
///
/// A fixture built by taking the current schema apart would follow the code
/// it is meant to check. These do not: they are what the field holds.
final class SchemaFixture {
  SchemaFixture._(this.userVersion, this.statements);

  /// Loads `test/fixtures/schema/<name>.json`.
  ///
  /// A fixture is either a full dump (`objects`) or the dump named by `base`
  /// with the objects in `overrides` replacing the same-named ones: the
  /// files of one install differ in a handful of tables.
  factory SchemaFixture.load(String name) {
    final json = _read(name);
    var objects = _objects(json['objects']);
    final base = json['base'];
    if (base is String) {
      final overrides = {
        for (final object in _objects(json['overrides']))
          object['name']! as String: object,
      };
      objects = [
        for (final object in _objects(_read(base)['objects']))
          overrides[object['name']] ?? object,
      ];
    }
    return SchemaFixture._(json['user_version']! as int, [
      for (final object in objects)
        if (_replayed(object, objects)) object['sql']! as String,
    ]);
  }

  /// The `user_version` the captured file carried.
  final int userVersion;

  /// The `CREATE …` statements, in the order the file created them.
  final List<String> statements;

  static Map<String, Object?> _read(String name) =>
      jsonDecode(File('test/fixtures/schema/$name.json').readAsStringSync())
          as Map<String, Object?>;

  static List<Map<String, Object?>> _objects(Object? value) => [
    for (final object in (value as List<Object?>?) ?? const <Object?>[])
      object! as Map<String, Object?>,
  ];

  /// Automatic indexes have no SQL, a virtual table creates its own shadow
  /// tables, and the vector extension creates its own table.
  static bool _replayed(
    Map<String, Object?> object,
    List<Map<String, Object?>> all,
  ) {
    final sql = object['sql'];
    if (sql is! String) {
      return false;
    }
    final name = object['name']! as String;
    if (name == '_sqliteai_vector') {
      return false;
    }
    final virtual = [
      for (final other in all)
        if ((other['sql'] as String?)?.startsWith('CREATE VIRTUAL TABLE') ??
            false)
          other['name']! as String,
    ];
    return !virtual.any((table) => name.startsWith('${table}_'));
  }

  /// Writes a file with this schema to [path], stamped with [userVersion],
  /// then lets [seed] add rows.
  void writeTo(String path, {void Function(sqlite3.Database db)? seed}) {
    final db = sqlite3.sqlite3.open(path);
    try {
      db.execute('PRAGMA journal_mode = WAL');
      db.execute('BEGIN');
      for (final statement in statements) {
        db.execute(statement);
      }
      db.execute('COMMIT');
      db.execute('PRAGMA user_version = $userVersion');
      seed?.call(db);
    } finally {
      db.close();
    }
  }
}
