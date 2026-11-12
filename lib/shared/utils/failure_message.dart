import 'package:cc_domain/core/domain/value_objects/workspace_storage_state.dart'
    show workspaceReadOnlyKind;
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:control_center/l10n/app_localizations.dart';

/// The `data.kind` values the server refuses with when storage, a deleted
/// workspace, a request still in flight or a refused restore is the reason.
///
/// Mirrors the server's constants (`rpc_exception_mapper.dart`,
/// `WorkspaceImportRefusal`); the client reads the kind and words it, never
/// the message.
abstract final class StorageRefusalKinds {
  /// The database stayed locked past the timeout; retrying works.
  static const busy = 'storage.busy';

  /// The server's disk is full.
  static const full = 'storage.full';

  /// A read hit damage in the workspace's file.
  static const damaged = 'storage.damaged';

  /// A write to a workspace whose file failed its integrity check.
  static const readOnly = workspaceReadOnlyKind;

  /// The file was written by a newer server version.
  static const newerSchema = 'storage.newer_schema';

  /// The file is not this product's database.
  static const foreignFile = 'storage.foreign_file';

  /// The workspace was deleted.
  static const workspaceDeleted = 'workspace.deleted';

  /// The same request is still being processed.
  static const idempotencyInProgress = 'idempotency.in_progress';

  /// Restore/import: no file at that path.
  static const importMissingSource = 'import.missing_source';

  /// Restore/import: the file fails its integrity check.
  static const importDamaged = 'import.damaged';

  /// Restore/import: the file differs from its snapshot's checksum.
  static const importChecksumMismatch = 'import.checksum_mismatch';

  /// Restore/import: written by a newer server.
  static const importNewerSchema = 'import.newer_schema';

  /// Restore/import: not a workspace database.
  static const importForeignFile = 'import.foreign_file';

  /// Restore/import: could not be brought to this server's schema.
  static const importSchemaMismatch = 'import.schema_mismatch';

  /// Restore/import: would take over links of another workspace.
  static const importRouteConflict = 'import.route_conflict';
}

/// The localized sentence for a storage, deleted-workspace, in-flight or
/// restore refusal named [kind], or null for any other kind.
///
/// For a lane that carries the kind outside a [RemoteRpcException] (the HTTP
/// restore route answers `{error, kind}`). Says what happened and what the
/// person can do; never the database's own words, a path or a version.
String? storageRefusalMessageForKind(
  AppLocalizations l10n,
  String? kind,
) => switch (kind) {
  StorageRefusalKinds.busy => l10n.refusalStorageBusy,
  StorageRefusalKinds.full => l10n.refusalStorageFull,
  StorageRefusalKinds.damaged => l10n.refusalStorageDamaged,
  StorageRefusalKinds.readOnly => l10n.refusalStorageReadOnly,
  StorageRefusalKinds.newerSchema => l10n.refusalStorageNewerSchema,
  StorageRefusalKinds.foreignFile => l10n.refusalStorageForeignFile,
  StorageRefusalKinds.workspaceDeleted => l10n.refusalWorkspaceDeleted,
  StorageRefusalKinds.idempotencyInProgress =>
    l10n.refusalIdempotencyInProgress,
  StorageRefusalKinds.importMissingSource => l10n.refusalImportMissingSource,
  StorageRefusalKinds.importDamaged => l10n.refusalImportDamaged,
  StorageRefusalKinds.importChecksumMismatch =>
    l10n.refusalImportChecksumMismatch,
  StorageRefusalKinds.importNewerSchema => l10n.refusalImportNewerSchema,
  StorageRefusalKinds.importForeignFile => l10n.refusalImportForeignFile,
  StorageRefusalKinds.importSchemaMismatch => l10n.refusalImportSchemaMismatch,
  StorageRefusalKinds.importRouteConflict => l10n.refusalImportRouteConflict,
  _ => null,
};

/// The `data.kind` of [error] when it is a [RemoteRpcException] carrying one.
String? refusalKindOf(Object? error) {
  if (error is! RemoteRpcException) {
    return null;
  }
  final data = error.data;
  final kind = data is Map ? data['kind'] : null;
  return kind is String ? kind : null;
}

/// The localized sentence for [error] when the server refused it for a
/// storage reason, a deleted workspace, a request still in flight or a
/// refused restore (see [StorageRefusalKinds]); null for anything else.
///
/// Read by `data.kind`, never by message text.
String? storageRefusalMessage(AppLocalizations l10n, Object error) =>
    storageRefusalMessageForKind(l10n, refusalKindOf(error));

/// What a failed action says when the caller has no sentence of its own.
///
/// The storage refusal when there is one ([storageRefusalMessage]), else the
/// server's own message for a [RemoteRpcException] (authored client-safe on
/// the server), else [AppLocalizations.failedWithError] around the error.
String failureMessage(AppLocalizations l10n, Object error) {
  final refusal = storageRefusalMessage(l10n, error);
  if (refusal != null) {
    return refusal;
  }
  if (error is RemoteRpcException && error.message.isNotEmpty) {
    return error.message;
  }
  return l10n.failedWithError('$error');
}
