import 'package:control_center/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:sqlite_vector/sqlite_vector.dart';

AppDatabase createTestDatabase() {
  sqlite3.sqlite3.tempDirectory = '/tmp';
  sqlite3.sqlite3.loadSqliteVectorExtension();
  return AppDatabase.forTesting(NativeDatabase.memory());
}
