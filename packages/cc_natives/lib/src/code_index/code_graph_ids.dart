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
String codeSymbolId(
  String workspaceId,
  String repoId,
  String filePath,
  String qualifiedName,
) => sha1
    .convert(utf8.encode('$workspaceId|$repoId|$filePath|$qualifiedName'))
    .toString();

/// Generates a deterministic content-addressed id for a code file.
String codeFileId(String workspaceId, String repoId, String path) =>
    sha1.convert(utf8.encode('$workspaceId|$repoId|$path')).toString();

/// Generates a deterministic content-addressed id for a code edge.
String codeEdgeId(
  String workspaceId,
  String repoId,
  String sourceSymbolId,
  String target,
  String kind,
) => sha1
    .convert(
      utf8.encode('$workspaceId|$repoId|$sourceSymbolId|$target|$kind'),
    )
    .toString();

/// Pseudo-id used as an edge source for file-level relationships (imports),
/// which have no enclosing symbol.
String codeFileNodeId(String workspaceId, String repoId, String filePath) =>
    'file:${codeFileId(workspaceId, repoId, filePath)}';
