import 'package:drift/drift.dart';

/// Logical identities over existing blob or workspace-file storage. A content
/// address is deliberately not unique: independent uploads can share bytes.
@TableIndex(name: 'idx_catalog_files_lifecycle', columns: {#state, #createdAt})
@TableIndex(name: 'idx_catalog_files_path', columns: {#path})
class CatalogFilesTable extends Table {
  TextColumn get id => text()();
  @override
  String get tableName => 'catalog_files';

  TextColumn get workspaceId => text()();
  TextColumn get uploaderUserId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get creatorId => text().nullable()();
  TextColumn get path => text()();
  TextColumn get mediaType => text()();
  IntColumn get bytes => integer()();
  TextColumn get source => text()();
  BoolColumn get ownedBytes => boolean().withDefault(const Constant(false))();
  TextColumn get state => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
