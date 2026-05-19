import 'dart:convert';

import 'package:cc_domain/cc_domain.dart' show ValidationException;
import 'package:cc_domain/core/domain/repositories/workspace_settings_repository.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';

/// DAO-backed [WorkspaceSettingsRepository].
///
/// Holds the `WorkspaceDatabaseManager` and resolves the DAO **per call**.
/// Caching `final WorkspaceSettingDao _dao;` in a field would pin whichever
/// workspace happened to resolve first and answer every later caller from that
/// workspace's file — the exact cross-workspace leak the database split makes
/// impossible and the one the isolation ratchet fails on by name.
///
/// Writes are quota-bounded for the same reason the per-user store is: the key
/// space is client-defined, every row is streamed back to every connected
/// member and an unbounded value or key count is a denial of service on the
/// workspace.
class DaoWorkspaceSettingsRepository implements WorkspaceSettingsRepository {
  /// Creates a [DaoWorkspaceSettingsRepository] over the workspace database manager.
  DaoWorkspaceSettingsRepository(this._databases);

  /// Largest accepted value, in UTF-8 bytes.
  static const int maxValueBytes = 256 * 1024;

  /// Largest number of distinct keys one workspace may hold.
  static const int maxKeysPerWorkspace = 256;

  final WorkspaceDatabaseManager _databases;

  @override
  Future<String?> get(String workspaceId, String key) =>
      _databases.of(workspaceId).workspaceSettingDao.getValue(workspaceId, key);

  @override
  Future<Map<String, String>> getAll(String workspaceId) async {
    final rows = await _databases
        .of(workspaceId)
        .workspaceSettingDao
        .getForWorkspace(workspaceId);
    return {for (final row in rows) row.key: row.value};
  }

  @override
  Stream<Map<String, String>> watchAll(String workspaceId) => _databases
      .of(workspaceId)
      .workspaceSettingDao
      .watchForWorkspace(workspaceId)
      .map((rows) => {for (final row in rows) row.key: row.value});

  @override
  Future<void> set(String workspaceId, String key, String? value) async {
    final dao = _databases.of(workspaceId).workspaceSettingDao;
    if (value == null) {
      await dao.deleteValue(workspaceId, key);
      return;
    }
    if (key.isEmpty) {
      throw const ValidationException('Setting key must not be empty.');
    }
    final bytes = utf8.encode(value).length;
    if (bytes > maxValueBytes) {
      throw ValidationException(
        'Setting "$key" is $bytes bytes, over the $maxValueBytes-byte limit.',
      );
    }
    // Only a NEW key can grow the row count, so an over-quota workspace can
    // still edit what it has (and delete its way back under).
    if (await dao.getValue(workspaceId, key) == null) {
      final count = await dao.countForWorkspace(workspaceId);
      if (count >= maxKeysPerWorkspace) {
        throw ValidationException(
          'Workspace setting limit reached ($maxKeysPerWorkspace keys); '
          'cannot add "$key".',
        );
      }
    }
    await dao.setValue(workspaceId, key, value);
  }
}
