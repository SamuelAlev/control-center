import 'package:cc_persistence/database/tables/checks/stored_values_platform.dart';
import 'package:cc_persistence/database/tables/conversation_messages.dart';
import 'package:drift/drift.dart';

/// Logical identities over existing blob or workspace-file storage. A content
/// address is deliberately not unique: independent uploads can share bytes.
@TableIndex(name: 'idx_catalog_files_lifecycle', columns: {#state, #createdAt})
@TableIndex(name: 'idx_catalog_files_path', columns: {#path})
@TableIndex(
  name: 'idx_catalog_files_attached_message',
  columns: {#attachedMessageId},
)
class CatalogFilesTable extends Table {
  /// Opaque catalog identity; identical bytes can have distinct rows.
  TextColumn get id => text()();
  @override
  String get tableName => 'catalog_files';

  /// Workspace that owns this logical file.
  TextColumn get workspaceId => text()();

  /// User who uploaded the file, if it came from an upload. No foreign key:
  /// users live in the global database.
  TextColumn get uploaderUserId => text().nullable()();

  /// Display name supplied for the catalog entry.
  TextColumn get name => text()();

  /// Creator identity attached to the catalog entry, when known. No foreign
  /// key: a principal id, a user's or an agent's.
  TextColumn get creatorId => text().nullable()();

  /// Storage path or blob reference associated with this logical file.
  TextColumn get path => text()();

  /// MIME media type of the stored bytes.
  TextColumn get mediaType => text()();

  /// Size of the file in bytes.
  IntColumn get bytes => integer()();

  /// Origin classification for this catalog entry: a `CatalogFileSource`
  /// name.
  TextColumn get source =>
      // ignore: recursive_getters
      text().check(source.isIn(PlatformStoredValues.catalogFileSource))();

  /// Whether this catalog entry owns the underlying stored bytes.
  BoolColumn get ownedBytes => boolean().withDefault(const Constant(false))();

  /// The message whose metadata carries this upload, written when the draft is
  /// promoted to `attached`. Null for drafts, artifacts, and an upload claimed
  /// before its message existed. Lets byte reclamation answer from the catalog
  /// instead of scanning every message's metadata. Cleared when the message
  /// is deleted: the file then answers to its own lifecycle state.
  TextColumn get attachedMessageId => text().nullable().references(
    ConversationMessagesTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Lifecycle state used for catalog cleanup: a `CatalogFileState` name.
  TextColumn get state =>
      // ignore: recursive_getters
      text().check(state.isIn(PlatformStoredValues.catalogFileState))();

  /// Time this logical file was cataloged.
  DateTimeColumn get createdAt => dateTime()();

  /// Time the catalog metadata last changed.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
