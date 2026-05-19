import 'dart:async';
import 'dart:convert';

import 'package:control_center/core/database/daos/cache_dao.dart';
import 'package:control_center/core/providers/provider.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Composite key identifying a PR for preview lookup.
class PrReferenceKey {
  /// Creates a [PrReferenceKey].
  const PrReferenceKey({
    required this.owner,
    required this.repo,
    required this.number,
  });

  /// GitHub repo owner / org.
  final String owner;

  /// GitHub repo name.
  final String repo;

  /// PR number.
  final int number;

  /// Stable string used as the CacheDao key.
  String get cacheKey => '$owner/$repo#$number';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrReferenceKey &&
          owner == other.owner &&
          repo == other.repo &&
          number == other.number;

  @override
  int get hashCode => Object.hash(owner, repo, number);
}

/// Lightweight preview of a PR — just the fields the chip needs.
class PrPreview {
  /// Creates a [PrPreview].
  const PrPreview({
    required this.title,
    required this.state,
    required this.isDraft,
    required this.isMerged,
    required this.htmlUrl,
  });

  /// Parses a cached JSON payload back into a [PrPreview].
  factory PrPreview.fromJson(Map<String, dynamic> json) {
    return PrPreview(
      title: json['title'] as String? ?? '',
      state: json['state'] as String? ?? 'open',
      isDraft: json['draft'] as bool? ?? false,
      isMerged: json['merged'] as bool? ?? false,
      htmlUrl: json['html_url'] as String? ?? '',
    );
  }

  /// PR title.
  final String title;

  /// Raw GitHub PR state (`open` or `closed`).
  final String state;

  /// Whether the PR is in draft mode.
  final bool isDraft;

  /// Whether the PR has been merged.
  final bool isMerged;

  /// Canonical GitHub web URL for the PR.
  final String htmlUrl;

  /// Serializes the preview for cache storage.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'title': title,
    'state': state,
    'draft': isDraft,
    'merged': isMerged,
    'html_url': htmlUrl,
  };
}

const _cacheKind = 'prPreview';

/// Fetches PR preview metadata (title + state) with stale-while-revalidate
/// caching. Returns `null` when the PR can't be resolved (404, missing
/// workspace context, network failure) so callers can fall back to a plain
/// link.
final prReferencePreviewProvider =
    FutureProvider.autoDispose.family<PrPreview?, PrReferenceKey>((
  ref,
  key,
) async {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return null;
  }

  final cacheDao = ref.watch(cacheDaoProvider);
  final cached = await cacheDao.read(workspaceId, _cacheKind, key.cacheKey);
  if (cached != null) {
    final preview = _decode(cached);
    if (preview != null) {
      // Stale-while-revalidate: kick off a background refresh, return cached.
      unawaited(_refresh(ref, workspaceId, key, cacheDao));
      return preview;
    }
  }

  return _fetch(ref, workspaceId, key, cacheDao);
});

PrPreview? _decode(String payload) {
  try {
    final decoded = jsonDecode(payload);
    if (decoded is Map<String, dynamic>) {
      return PrPreview.fromJson(decoded);
    }
  } catch (_) {
    // Bad payload — treat as cache miss.
  }
  return null;
}

Future<PrPreview?> _fetch(
  Ref ref,
  String workspaceId,
  PrReferenceKey key,
  CacheDao cacheDao,
) async {
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);

  final client = ref.read(githubApiClientProvider);
  try {
    final pr = await client.pr.getPullRequest(
      key.owner,
      key.repo,
      key.number,
      cancelToken: cancelToken,
    );
    if (pr == null) {
      return null;
    }
    final preview = PrPreview(
      title: pr.title,
      state: pr.state,
      isDraft: pr.isDraft,
      isMerged: pr.mergedAt != null,
      htmlUrl: pr.htmlUrl,
    );
    await cacheDao.put(
      workspaceId,
      _cacheKind,
      key.cacheKey,
      jsonEncode(preview.toJson()),
    );
    return preview;
  } on DioException {
    return null;
  } catch (_) {
    return null;
  }
}

Future<void> _refresh(
  Ref ref,
  String workspaceId,
  PrReferenceKey key,
  CacheDao cacheDao,
) async {
  await _fetch(ref, workspaceId, key, cacheDao);
}

/// Synchronous check: is `(owner, repo)` registered as a repo in the
/// currently active workspace? Used by the markdown builder to decide chip
/// vs. plain link without an async hop.
final repoInActiveWorkspaceProvider =
    Provider.autoDispose.family<bool, ({String owner, String repo})>((
  ref,
  args,
) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return false;
  }
  final repos = ref.watch(reposForWorkspaceProvider(workspaceId)).value ??
      const [];
  return repos.any(
    (r) =>
        r.githubOwner.toLowerCase() == args.owner.toLowerCase() &&
        r.githubRepoName.toLowerCase() == args.repo.toLowerCase(),
  );
});
