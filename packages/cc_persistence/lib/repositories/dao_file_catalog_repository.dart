import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/catalog_file.dart';
import 'package:cc_domain/core/domain/repositories/file_catalog_repository.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Logical files share content-addressed storage without sharing ownership.
/// Every query is confined to the selected workspace database AND workspace id.
class DaoFileCatalogRepository implements FileCatalogRepository {
  /// Uses per-call workspace resolution, or a transient fan-out database.
  DaoFileCatalogRepository(this._dbs, {WorkspaceDatabase? database})
    : _transientDatabase = database;
  final WorkspaceDatabaseManager _dbs;
  final WorkspaceDatabase? _transientDatabase;
  static const _uuid = Uuid();

  WorkspaceDatabase _db(String workspaceId) {
    final transient = _transientDatabase;
    if (transient != null) {
      if (transient.workspaceId != workspaceId) {
        throw const WorkspaceMismatchException('Catalog workspace mismatch');
      }
      return transient;
    }
    return _dbs.of(workspaceId);
  }

  Future<CatalogFile> _insert({
    required String workspaceId,
    required String name,
    required String path,
    required String mediaType,
    required int bytes,
    required CatalogFileSource source,
    required CatalogFileState state,
    bool ownedBytes = false,
    String? uploaderUserId,
    String? creatorId,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _db(workspaceId).customStatement(
      '''
      INSERT INTO catalog_files (id, workspace_id, uploader_user_id, creator_id, name,
        path, media_type, bytes, source, state, owned_bytes, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
      [
        id,
        workspaceId,
        uploaderUserId,
        creatorId,
        name,
        path,
        mediaType,
        bytes,
        source.name,
        state.name,
        ownedBytes ? 1 : 0,
        now,
        now,
      ],
    );
    return CatalogFile(
      id: id,
      workspaceId: workspaceId,
      name: name,
      path: path,
      mediaType: mediaType,
      bytes: bytes,
      source: source,
      state: state,
      uploaderUserId: uploaderUserId,
      creatorId: creatorId,
      ownedBytes: ownedBytes,
    );
  }

  @override
  Future<CatalogFile> createUpload({
    required String workspaceId,
    required String uploaderUserId,
    required String name,
    required String path,
    required String mediaType,
    required int bytes,
    bool ownedBytes = false,
  }) => _insert(
    workspaceId: workspaceId,
    uploaderUserId: uploaderUserId,
    name: name,
    path: path,
    mediaType: mediaType,
    bytes: bytes,
    ownedBytes: ownedBytes,
    source: CatalogFileSource.upload,
    state: CatalogFileState.draft,
  );

  @override
  Future<CatalogFile> recordArtifact({
    required String workspaceId,
    required String name,
    required String path,
    required String mediaType,
    required int bytes,
    String? creatorId,
  }) async {
    final db = _db(workspaceId);
    return db.transaction(() async {
      final rows = await db
          .customSelect(
            '''
        SELECT id FROM catalog_files WHERE workspace_id = ?
          AND path = ? AND source = 'artifact' LIMIT 1
      ''',
            variables: [Variable<String>(workspaceId), Variable<String>(path)],
          )
          .get();
      if (rows.isNotEmpty) {
        final id = rows.single.read<String>('id');
        await db.customStatement(
          '''
          UPDATE catalog_files SET name = ?, media_type = ?, bytes = ?,
            creator_id = COALESCE(?, creator_id),
            updated_at = ? WHERE workspace_id = ? AND id = ?
        ''',
          [
            name,
            mediaType,
            bytes,
            creatorId,
            DateTime.now().millisecondsSinceEpoch ~/ 1000,
            workspaceId,
            id,
          ],
        );
        return (await byId(workspaceId, id))!;
      }
      return _insert(
        workspaceId: workspaceId,
        name: name,
        path: path,
        mediaType: mediaType,
        bytes: bytes,
        creatorId: creatorId,
        source: CatalogFileSource.artifact,
        state: CatalogFileState.artifact,
      );
    });
  }

  @override
  Future<CatalogFile?> byId(String workspaceId, String fileId) async {
    final rows = await _db(workspaceId)
        .customSelect(
          '''
      SELECT id, workspace_id, uploader_user_id, creator_id, name, path,
        media_type, bytes, source, state, owned_bytes FROM catalog_files
      WHERE workspace_id = ? AND id = ?
    ''',
          variables: [Variable<String>(workspaceId), Variable<String>(fileId)],
        )
        .get();
    if (rows.isEmpty) {
      return null;
    }
    final row = rows.single;
    return CatalogFile(
      id: row.read<String>('id'),
      workspaceId: row.read<String>('workspace_id'),
      uploaderUserId: row.readNullable<String>('uploader_user_id'),
      creatorId: row.readNullable<String>('creator_id'),
      name: row.read<String>('name'),
      path: row.read<String>('path'),
      mediaType: row.read<String>('media_type'),
      bytes: row.read<int>('bytes'),
      source: CatalogFileSource.values.byName(row.read<String>('source')),
      state: CatalogFileState.values.byName(row.read<String>('state')),
      ownedBytes: row.read<int>('owned_bytes') != 0,
    );
  }

  @override
  Future<bool> hasPath(String workspaceId, String path) async =>
      (await _db(workspaceId)
              .customSelect(
                'SELECT 1 FROM catalog_files WHERE workspace_id = ? AND path = ? LIMIT 1',
                variables: [
                  Variable<String>(workspaceId),
                  Variable<String>(path),
                ],
              )
              .get())
          .isNotEmpty;

  @override
  Future<void> claim(
    String workspaceId,
    String userId,
    List<({String fileId, String path})> attachments,
  ) async {
    if (attachments.isEmpty) {
      return;
    }
    final db = _db(workspaceId);
    await db.transaction(() async {
      for (final attachment in attachments) {
        final file = await byId(workspaceId, attachment.fileId);
        if (file == null ||
            file.source != CatalogFileSource.upload ||
            file.path != attachment.path ||
            file.state == CatalogFileState.discarded ||
            (file.state == CatalogFileState.draft &&
                file.uploaderUserId != userId)) {
          throw const ValidationException(
            'Attachment file is not available in this workspace',
          );
        }
      }
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      for (final attachment in attachments) {
        await db.customStatement(
          '''
          UPDATE catalog_files SET state = 'attached', updated_at = ?
          WHERE workspace_id = ? AND id = ? AND state = 'draft'
        ''',
          [now, workspaceId, attachment.fileId],
        );
      }
    });
  }

  @override
  Future<void> discard(String workspaceId, String userId, String fileId) async {
    final file = await byId(workspaceId, fileId);
    if (file == null) {
      throw const ValidationException(
        'Attachment file is not available in this workspace',
      );
    }
    if (file.source != CatalogFileSource.upload ||
        file.uploaderUserId != userId ||
        file.state == CatalogFileState.attached) {
      throw const ValidationException(
        'Only your unclaimed uploads can be discarded',
      );
    }
    // The tombstone retains the id for idempotent retries. Physical cleanup
    // runs separately under the blob hash lock after reference checks.
    await _db(workspaceId).customStatement(
      '''
      UPDATE catalog_files SET state = 'discarded', updated_at = ?
      WHERE workspace_id = ? AND id = ? AND state = 'draft'
    ''',
      [DateTime.now().millisecondsSinceEpoch ~/ 1000, workspaceId, fileId],
    );
  }

  @override
  Future<bool> canReclaim(String workspaceId, String path) async {
    final db = _db(workspaceId);
    final rows = await db
        .customSelect(
          '''
      SELECT
        EXISTS(SELECT 1 FROM catalog_files WHERE workspace_id = ?
          AND path = ? AND source = 'upload' AND owned_bytes = 1) AS owned,
        EXISTS(SELECT 1 FROM catalog_files WHERE workspace_id = ?
          AND path = ? AND state != 'discarded') AS live,
        EXISTS(SELECT 1 FROM conversation_messages
          WHERE metadata LIKE '%' || ? || '%') AS historic
    ''',
          variables: [
            Variable<String>(workspaceId),
            Variable<String>(path),
            Variable<String>(workspaceId),
            Variable<String>(path),
            Variable<String>(path),
          ],
        )
        .getSingle();
    return rows.read<int>('owned') != 0 &&
        rows.read<int>('live') == 0 &&
        rows.read<int>('historic') == 0;
  }
}
