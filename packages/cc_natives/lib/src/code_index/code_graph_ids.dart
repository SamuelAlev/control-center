import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Content-addressed code-graph ids, scoped by [workspaceId] first (same repo
/// in two workspaces must not collide). [checkoutId] partitions linked vs
/// worktree graphs; omitted for the linked partition so pre-partition ids stay
/// stable.
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
