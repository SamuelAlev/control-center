import 'dart:convert';

import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_server_core/src/demo/demo_pr_cache.dart';
import 'package:cc_server_core/src/pr_review/open_pr_fetch_port.dart';
import 'package:cc_server_core/src/pr_review/pr_cache_codec.dart';

/// Reads the demo's merged-PR snapshot out of the workspace cache.
///
/// Production `pr.closedByAuthorForWorkspace` searches GitHub. A demo
/// container dials nothing, so the seeder writes the same `caches` row the
/// open-PR poller uses for the live list, and this answers from that row.
class DemoMergedHistory {
  /// Creates a reader over the demo's per-workspace databases.
  const DemoMergedHistory({required WorkspaceDatabaseManager workspaceDbs})
    : _dbs = workspaceDbs;

  final WorkspaceDatabaseManager _dbs;

  /// Maya's recently merged pull requests across [repos].
  ///
  /// [workspaceId] picks the database file. Without it there is nowhere to
  /// look — repo ids are reused across pooled workspaces.
  Future<List<OpenPrGroup>> mergedByViewer(
    List<Repo> repos, {
    String? userId,
    String? workspaceId,
  }) async {
    if (workspaceId == null || workspaceId.isEmpty || repos.isEmpty) {
      return const [];
    }
    final raw = await _dbs
        .of(workspaceId)
        .cacheDao
        .read(
          workspaceId,
          DemoPrCacheKind.closedPrList,
          DemoPrCacheKind.closedPrListKey,
        );
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return const [];
    }
    final repoById = {for (final r in repos) r.id: r};
    final groups = <OpenPrGroup>[];
    for (final row in decoded['repos'] as List? ?? const []) {
      if (row is! Map) {
        continue;
      }
      final id = row['repo_id'] as String?;
      final repo = id == null ? null : repoById[id];
      if (repo == null) {
        continue;
      }
      final prs = <PullRequest>[];
      for (final p in row['prs'] as List? ?? const []) {
        if (p is! Map) {
          continue;
        }
        final pr = PrCacheCodec.pullRequestFromCache(
          Map<String, dynamic>.from(p),
        );
        if (pr != null) {
          prs.add(pr);
        }
      }
      if (prs.isNotEmpty) {
        groups.add((repo: repo, prs: prs, hasMore: false));
      }
    }
    return groups;
  }
}
