import 'package:drift/drift.dart';

/// Logical identities over existing blob or workspace-file storage. A content
/// address is deliberately not unique: independent uploads can share bytes.
@TableIndex(name: 'idx_catalog_files_lifecycle', columns: {#state, #createdAt})
@TableIndex(name: 'idx_catalog_files_path', columns: {#path})
class CatalogFilesTable extends Table {
  /// Opaque catalog identity; identical bytes can have distinct rows.
  TextColumn get id => text()();
  @override
  String get tableName => 'catalog_files';

  /// Workspace that owns this logical file.
  TextColumn get workspaceId => text()();

  /// User who uploaded the file, if it came from an upload.
  TextColumn get uploaderUserId => text().nullable()();

  /// Display name supplied for the catalog entry.
  TextColumn get name => text()();

  /// Creator identity attached to the catalog entry, when known.
  TextColumn get creatorId => text().nullable()();

  /// Storage path or blob reference associated with this logical file.
  TextColumn get path => text()();

  /// MIME media type of the stored bytes.
  TextColumn get mediaType => text()();

  /// Size of the file in bytes.
  IntColumn get bytes => integer()();

  /// Origin classification for this catalog entry.
  TextColumn get source => text()();

  /// Whether this catalog entry owns the underlying stored bytes.
  BoolColumn get ownedBytes => boolean().withDefault(const Constant(false))();

  /// Lifecycle state used for catalog cleanup.
  TextColumn get state => text()();

  /// Time this logical file was cataloged.
  DateTimeColumn get createdAt => dateTime()();

  /// Time the catalog metadata last changed.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
