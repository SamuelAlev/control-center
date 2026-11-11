import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/repositories/cache_repository.dart';
import 'package:cc_domain/core/domain/value_objects/editor_layout_cache_kinds.dart';
import 'package:cc_host/cc_host.dart';

/// The `cache.read` / `cache.write` ops clients persist editor layouts through.
///
/// A layout is the caller's own arrangement of a space's or PR's tabs,
/// including the tab each pane last showed, so it roams with the PERSON
/// across devices rather than being shared by the workspace. The stored key is
/// derived from the session's `userId`, never from an argument, so no caller
/// can name another person's row. Only [EditorLayoutCacheKinds.all] are
/// reachable: the same `caches` table holds server-owned rows (PR payloads,
/// collaboration and escalation state) that clients must not read or forge.
List<RepoOp> buildEditorLayoutCacheOps(CacheRepository cache) => [
  RepoOp(
    name: 'cache.read',
    kind: RepoOpKind.read,
    requiredArgs: const ['kind', 'key'],
    handler: (ctx) async {
      final (:kind, :key) = _layoutAddress(ctx);
      return {
        'payload': await cache.read(
          ctx.workspaceId!,
          kind,
          editorLayoutOwnerKey(ctx.userId, key),
        ),
      };
    },
  ),
  RepoOp(
    name: 'cache.write',
    kind: RepoOpKind.mutate,
    // Personal UI state: auditing every tab press is noise, not accountability.
    audited: false,
    requiredArgs: const ['kind', 'key'],
    handler: (ctx) async {
      final (:kind, :key) = _layoutAddress(ctx);
      final payload = ctx.args['payload'];
      if (payload is! String) {
        throw const ValidationException('payload must be a string');
      }
      await cache.put(
        ctx.workspaceId!,
        kind,
        editorLayoutOwnerKey(ctx.userId, key),
        payload,
      );
      return const {};
    },
  ),
];

/// The stored cache key of [userId]'s layout under the client's [key].
String editorLayoutOwnerKey(String userId, String key) =>
    '$_ownerPrefix$userId:$key';

const String _ownerPrefix = 'user:';

/// Validates the client's `kind` and `key`.
///
/// A key carrying the owner prefix is refused so a stored key always names
/// exactly one owner.
({String kind, String key}) _layoutAddress(RepoOpContext ctx) {
  final kind = ctx.args['kind'];
  final key = ctx.args['key'];
  if (kind is! String || !EditorLayoutCacheKinds.all.contains(kind)) {
    throw const ValidationException('Unknown editor layout cache kind');
  }
  if (key is! String || key.isEmpty || key.startsWith(_ownerPrefix)) {
    throw const ValidationException('Invalid editor layout cache key');
  }
  return (kind: kind, key: key);
}
