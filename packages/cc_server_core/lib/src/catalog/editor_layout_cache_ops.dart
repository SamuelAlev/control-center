import 'dart:convert';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/repositories/editor_layout_repository.dart';
import 'package:cc_domain/core/domain/value_objects/editor_layout_cache_kinds.dart';
import 'package:cc_host/cc_host.dart';

/// The `cache.read` / `cache.write` ops clients persist editor layouts through.
///
/// A layout is the caller's own arrangement of a space's or PR's tabs,
/// including the tab each pane last showed, so it roams with the PERSON
/// across devices rather than being shared by the workspace. It is stored in
/// the workspace's `editor_layouts` table under the session's `userId`, never
/// an argument, so no caller can name another person's row. Only the
/// [EditorLayoutCacheKinds] are accepted; the ops reach no other table.
List<RepoOp> buildEditorLayoutCacheOps(EditorLayoutRepository layouts) => [
  RepoOp(
    name: 'cache.read',
    kind: RepoOpKind.read,
    requiredArgs: const ['kind', 'key'],
    handler: (ctx) async {
      final (:surface, :target) = _layoutAddress(ctx);
      return {
        'payload': await layouts.read(
          ctx.workspaceId!,
          userId: ctx.userId,
          surface: surface,
          target: target,
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
      final (:surface, :target) = _layoutAddress(ctx);
      final payload = ctx.args['payload'];
      if (payload is! String || !_isJson(payload)) {
        throw const ValidationException('payload must be a JSON string');
      }
      await layouts.write(
        ctx.workspaceId!,
        userId: ctx.userId,
        surface: surface,
        target: target,
        layout: payload,
      );
      return const {};
    },
  ),
];

/// Validates the client's `kind` and `key`.
({EditorLayoutSurface surface, String target}) _layoutAddress(
  RepoOpContext ctx,
) {
  final kind = ctx.args['kind'];
  final key = ctx.args['key'];
  final surface = kind is String
      ? EditorLayoutSurface.ofClientKind(kind)
      : null;
  if (surface == null) {
    throw const ValidationException('Unknown editor layout cache kind');
  }
  if (key is! String || key.isEmpty) {
    throw const ValidationException('Invalid editor layout cache key');
  }
  return (surface: surface, target: key);
}

bool _isJson(String value) {
  try {
    jsonDecode(value);
    return true;
  } on FormatException {
    return false;
  }
}
