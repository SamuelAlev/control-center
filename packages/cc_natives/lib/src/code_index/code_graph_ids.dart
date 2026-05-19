import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Deterministic identifiers for code-graph rows.
///
/// Ids are content-addressed so re-indexing the same symbol/edge/file updates
/// the existing row in place (stable primary key → stable SQLite rowid → the
/// FTS5 and vector indexes stay coherent across re-indexes). Shared by the
/// tree-sitter extractor and the repository so both agree on ids.
///
/// Every id is scoped by [workspaceId] first: workspaces are isolated worktrees
/// that can share the same [repoId] (often on different branches), so the same
/// `repoId|filePath|qualifiedName` in two workspaces MUST yield distinct ids —
/// otherwise their graphs collide and one workspace's symbols leak into the
/// other on upsert.
///
/// [checkoutId] partitions the graph per checkout within a `(workspaceId,
/// repoId)` pair: null (or empty) is the linked checkout, anything else is one
/// conversation/PR worktree (the `isolated_repos` row id). A worktree's tree
/// differs from the linked checkout (a PR head, a feature branch), so its
/// symbols MUST NOT share ids with the linked partition — the same file at two
/// revisions would otherwise overwrite each other on every re-index. The
/// segment is omitted entirely for the linked partition so ids minted before
/// per-checkout graphs stay stable (no id rewrite on migration).
String codeSymbolId(
  String workspaceId,
  String repoId,
  String filePath,
  String qualifiedName, {
  String? checkoutId,
}) => sha1
    .convert(
      utf8.encode(
        '$workspaceId|$repoId|${_checkoutSegment(checkoutId)}'
        '$filePath|$qualifiedName',
      ),
    )
    .toString();

/// Generates a deterministic content-addressed id for a code file.
String codeFileId(
  String workspaceId,
  String repoId,
  String path, {
  String? checkoutId,
}) => sha1
    .convert(
      utf8.encode('$workspaceId|$repoId|${_checkoutSegment(checkoutId)}$path'),
    )
    .toString();

/// Generates a deterministic content-addressed id for a code edge.
String codeEdgeId(
  String workspaceId,
  String repoId,
  String sourceSymbolId,
  String target,
  String kind, {
  String? checkoutId,
}) => sha1
    .convert(
      utf8.encode(
        '$workspaceId|$repoId|${_checkoutSegment(checkoutId)}'
        '$sourceSymbolId|$target|$kind',
      ),
    )
    .toString();

/// Generates a deterministic id for a checkout partition's index checkpoint
/// (one row per `(workspaceId, repoId, checkoutId)`).
String codeIndexCheckpointId(
  String workspaceId,
  String repoId, {
  String? checkoutId,
}) => sha1
    .convert(
      utf8.encode(
        '$workspaceId|$repoId|${_checkoutSegment(checkoutId)}checkpoint',
      ),
    )
    .toString();

/// Pseudo-id used as an edge source for file-level relationships (imports),
/// which have no enclosing symbol.
String codeFileNodeId(
  String workspaceId,
  String repoId,
  String filePath, {
  String? checkoutId,
}) =>
    'file:${codeFileId(workspaceId, repoId, filePath, checkoutId: checkoutId)}';

/// The id segment separating checkout partitions: empty for the linked
/// checkout (keeping pre-partition ids byte-identical), `'<checkoutId>|'`
/// for a worktree partition.
String _checkoutSegment(String? checkoutId) =>
    checkoutId == null || checkoutId.isEmpty ? '' : '$checkoutId|';
