import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/repositories/file_catalog_repository.dart';
import 'package:cc_host/cc_host.dart' show RepoOp;
import 'package:cc_infra/cc_infra.dart' show BlobStore, blobHashOf;

/// `files.discard`: drops an uploaded attachment the composer no longer sends,
/// reclaiming its blob once no catalog row references it.
///
/// A pack the catalog spreads, so `remote_rpc_catalog.dart` does not grow.
/// Absent (empty) when the host wires no blob store or file catalog, like the
/// `blob.put` upload it undoes.
List<RepoOp> buildFileDiscardOps({
  required FileCatalogRepository? fileCatalog,
  required BlobStore? blobStore,
}) {
  if (fileCatalog == null || blobStore == null) {
    return const [];
  }
  return [
    RepoOp(
      name: 'files.discard',
      kind: RepoOpKind.mutate,
      undoClass: UndoClass.irreversible,
      requiredArgs: ['file_id'],
      handler: (ctx) async {
        final fileId = ctx.args['file_id'];
        if (fileId is! String || fileId.isEmpty) {
          throw const ValidationException('file_id must be a nonempty string');
        }
        final workspaceId = ctx.workspaceId!;
        final file = await fileCatalog.byId(workspaceId, fileId);
        final hash = blobHashOf(file?.path);
        if (hash == null) {
          await fileCatalog.discard(workspaceId, ctx.userId, fileId);
        } else {
          await blobStore.withHashLock(workspaceId, hash, () async {
            await fileCatalog.discard(workspaceId, ctx.userId, fileId);
            if (await fileCatalog.canReclaim(workspaceId, file!.path)) {
              await blobStore.deleteHash(workspaceId, hash);
            }
          });
        }
        return {'ok': true};
      },
    ),
  ];
}
