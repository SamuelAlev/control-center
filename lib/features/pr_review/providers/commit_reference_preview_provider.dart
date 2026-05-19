import 'dart:async';
import 'dart:convert';

import 'package:control_center/core/database/daos/cache_dao.dart';
import 'package:control_center/core/providers/provider.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Composite key identifying a commit for preview lookup.
class CommitReferenceKey {
  /// Creates a [CommitReferenceKey].
  const CommitReferenceKey({
    required this.owner,
    required this.repo,
    required this.sha,
  });

  /// GitHub repo owner.
  final String owner;

  /// GitHub repo name.
  final String repo;

  /// Commit SHA (lowercased, 7–40 hex chars).
  final String sha;

  /// Stable key used for the CacheDao row.
  String get cacheKey => '$owner/$repo@$sha';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommitReferenceKey &&
          owner == other.owner &&
          repo == other.repo &&
          sha == other.sha;

  @override
  int get hashCode => Object.hash(owner, repo, sha);
}

/// Lightweight preview of a commit — just the fields the chip needs.
class CommitPreview {
  /// Creates a [CommitPreview].
  const CommitPreview({required this.title, required this.shortSha});

  /// Parses a cached JSON payload back into a [CommitPreview].
  factory CommitPreview.fromJson(Map<String, dynamic> json) {
    return CommitPreview(
      title: json['title'] as String? ?? '',
      shortSha: json['short_sha'] as String? ?? '',
    );
  }

  /// First line of the commit message.
  final String title;

  /// Short 7-char SHA for display.
  final String shortSha;

  /// Serializes the preview for cache storage.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'title': title,
    'short_sha': shortSha,
  };
}

const _cacheKind = 'commitPreview';

/// Fetches commit preview metadata (title + short SHA) with stale-while-
/// revalidate caching. Returns `null` when the commit can't be resolved.
final commitReferencePreviewProvider =
    FutureProvider.autoDispose.family<CommitPreview?, CommitReferenceKey>((
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
      unawaited(_refresh(ref, workspaceId, key, cacheDao));
      return preview;
    }
  }

  return _fetch(ref, workspaceId, key, cacheDao);
});

CommitPreview? _decode(String payload) {
  try {
    final decoded = jsonDecode(payload);
    if (decoded is Map<String, dynamic>) {
      return CommitPreview.fromJson(decoded);
    }
  } catch (_) {
    // Bad payload — treat as cache miss.
  }
  return null;
}

Future<CommitPreview?> _fetch(
  Ref ref,
  String workspaceId,
  CommitReferenceKey key,
  CacheDao cacheDao,
) async {
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);

  final client = ref.read(githubApiClientProvider);
  try {
    final commit = await client.pr.getCommit(
      key.owner,
      key.repo,
      key.sha,
      cancelToken: cancelToken,
    );
    if (commit == null) {
      return null;
    }
    final preview = CommitPreview(
      title: commit.title,
      shortSha: commit.shortSha,
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
  CommitReferenceKey key,
  CacheDao cacheDao,
) async {
  await _fetch(ref, workspaceId, key, cacheDao);
}
