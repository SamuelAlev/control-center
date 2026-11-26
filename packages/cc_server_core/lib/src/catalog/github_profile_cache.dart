import 'dart:async';

import 'package:cc_domain/core/domain/entities/github_team_profile.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/pr_review/domain/entities/github_profile_activity.dart';

/// Server-side in-memory TTL + in-flight coalescing cache for GitHub profile
/// reads (`github.userProfile`, `github.teamProfile`, `github.profileActivity`).
///
/// Cache keys include the acting user (`actingUserId`) and, for workspace-scoped
/// activity, `workspaceId` and the sorted visible GitHub repo coordinates so
/// authorization and workspace boundaries are never crossed.
class GitHubProfileCache {
  /// Creates a profile cache with configurable TTLs and capacity.
  GitHubProfileCache({
    this.userProfileTtl = const Duration(minutes: 5),
    this.teamProfileTtl = const Duration(minutes: 5),
    this.activityTtl = const Duration(minutes: 3),
    this.maxEntries = 128,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    _userProfiles = _CoalescingTtlCache<Map<String, dynamic>?>(
      ttl: userProfileTtl,
      maxEntries: maxEntries,
      now: _now,
    );
    _teamProfiles = _CoalescingTtlCache<GitHubTeamProfile?>(
      ttl: teamProfileTtl,
      maxEntries: maxEntries,
      now: _now,
    );
    _activities = _CoalescingTtlCache<GitHubProfileActivity>(
      ttl: activityTtl,
      maxEntries: maxEntries,
      now: _now,
    );
  }

  /// TTL for `github.userProfile` entries.
  final Duration userProfileTtl;

  /// TTL for `github.teamProfile` entries.
  final Duration teamProfileTtl;

  /// TTL for `github.profileActivity` entries.
  final Duration activityTtl;

  /// Maximum entries retained per cache lane (LRU eviction).
  final int maxEntries;

  final DateTime Function() _now;
  late final _CoalescingTtlCache<Map<String, dynamic>?> _userProfiles;
  late final _CoalescingTtlCache<GitHubTeamProfile?> _teamProfiles;
  late final _CoalescingTtlCache<GitHubProfileActivity> _activities;

  final Map<String, int> _userGenerations = {};
  final Map<String, int> _workspaceUserGenerations = {};

  int _userGeneration(String userId) => _userGenerations[userId] ?? 0;

  int _workspaceUserGeneration(String workspaceId, String userId) =>
      _workspaceUserGenerations['$workspaceId\u0000$userId'] ?? 0;

  /// Returns a cached/coalesced GitHub user profile or loads it via [load].
  Future<Map<String, dynamic>?> getUserProfile({
    required String actingUserId,
    required String login,
    bool force = false,
    required Future<Map<String, dynamic>?> Function() load,
  }) {
    final key = '$actingUserId\u0000${login.trim().toLowerCase()}';
    final gen = _userGeneration(actingUserId);
    return _userProfiles.get(
      key,
      force: force,
      shouldCache: (value) => value != null,
      isStillValid: () => _userGeneration(actingUserId) == gen,
      load: load,
    );
  }

  /// Returns a cached/coalesced GitHub team profile or loads it via [load].
  Future<GitHubTeamProfile?> getTeamProfile({
    required String actingUserId,
    required String organization,
    required String slug,
    bool force = false,
    required Future<GitHubTeamProfile?> Function() load,
  }) {
    final key =
        '$actingUserId\u0000${organization.trim().toLowerCase()}\u0000'
        '${slug.trim().toLowerCase()}';
    final gen = _userGeneration(actingUserId);
    return _teamProfiles.get(
      key,
      force: force,
      shouldCache: (value) => value != null,
      isStillValid: () => _userGeneration(actingUserId) == gen,
      load: load,
    );
  }

  /// Returns cached/coalesced workspace-scoped PR activity or loads via [load].
  Future<GitHubProfileActivity> getProfileActivity({
    required String workspaceId,
    required String actingUserId,
    required String targetKey,
    required List<Repo> visibleRepos,
    bool force = false,
    required Future<GitHubProfileActivity> Function() load,
  }) {
    final repoParts = <String>[];
    for (final repo in visibleRepos) {
      if (repo.forge == ForgeHost.github &&
          repo.remoteOwner.isNotEmpty &&
          repo.remoteName.isNotEmpty) {
        final owner = repo.remoteOwner.toLowerCase();
        final name = repo.remoteName.toLowerCase();
        repoParts.add('${repo.id}:$owner/$name');
      }
    }
    repoParts.sort();
    final key =
        '$workspaceId\u0000$actingUserId\u0000$targetKey\u0000'
        '${repoParts.join(',')}';
    final userGen = _userGeneration(actingUserId);
    final wsUserGen = _workspaceUserGeneration(workspaceId, actingUserId);
    return _activities.get(
      key,
      force: force,
      shouldCache: (_) => true,
      isStillValid: () =>
          _userGeneration(actingUserId) == userGen &&
          _workspaceUserGeneration(workspaceId, actingUserId) == wsUserGen,
      load: load,
    );
  }

  /// Drops cached entries for [userId] (scoped to [workspaceId] when given)
  /// and prevents in-flight loads from repopulating stale values.
  void invalidateUser(String userId, {String? workspaceId}) {
    if (workspaceId == null) {
      _userGenerations[userId] = _userGeneration(userId) + 1;
      final prefix = '$userId\u0000';
      _userProfiles.invalidateWhere((key) => key.startsWith(prefix));
      _teamProfiles.invalidateWhere((key) => key.startsWith(prefix));
      _activities.invalidateWhere((key) {
        final parts = key.split('\u0000');
        return parts.length >= 2 && parts[1] == userId;
      });
      return;
    }
    final wsUserKey = '$workspaceId\u0000$userId';
    _workspaceUserGenerations[wsUserKey] =
        (_workspaceUserGenerations[wsUserKey] ?? 0) + 1;
    final prefix = '$workspaceId\u0000$userId\u0000';
    _activities.invalidateWhere((key) => key.startsWith(prefix));
  }
}

class _CacheEntry<T> {
  const _CacheEntry(this.value, this.at);

  final T value;
  final DateTime at;
}

class _CoalescingTtlCache<T> {
  _CoalescingTtlCache({
    required this.ttl,
    required this.maxEntries,
    required this._now,
  });

  final Duration ttl;
  final int maxEntries;
  final DateTime Function() _now;

  final Map<String, _CacheEntry<T>> _entries = {};
  final Map<String, Future<T>> _inflight = {};

  Future<T> get(
    String key, {
    required bool force,
    required bool Function(T value) shouldCache,
    required bool Function() isStillValid,
    required Future<T> Function() load,
  }) {
    if (!force) {
      final cached = _entries[key];
      if (cached != null) {
        if (_now().difference(cached.at) < ttl) {
          _entries
            ..remove(key)
            ..[key] = cached;
          return Future<T>.value(cached.value);
        }
        _entries.remove(key);
      }
      final existing = _inflight[key];
      if (existing != null) {
        return existing;
      }
    }

    late final Future<T> future;
    future = load().then((value) {
      if (shouldCache(value) && isStillValid()) {
        _store(key, value);
      }
      return value;
    }).whenComplete(() {
      if (identical(_inflight[key], future)) {
        _inflight.remove(key);
      }
    });
    _inflight[key] = future;
    return future;
  }

  void invalidateWhere(bool Function(String key) test) {
    _entries.removeWhere((key, _) => test(key));
    _inflight.removeWhere((key, _) => test(key));
  }

  void _store(String key, T value) {
    _entries
      ..remove(key)
      ..[key] = _CacheEntry(value, _now());
    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }
  }
}
