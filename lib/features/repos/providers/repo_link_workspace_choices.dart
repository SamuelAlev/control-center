import 'dart:convert';

import 'package:control_center/core/providers/storage_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Persisted preference key for the workspace a repository's external links
/// open in when the repository is linked in more than one workspace.
///
/// A JSON object of `owner/name` → workspace id. It follows the user across
/// devices (see `di/synced_preferences.dart`): which workspace someone reviews
/// a repository from is their habit, not the machine's.
const String repoLinkWorkspaceChoicesKey = 'repo_link_workspace_choices';

/// The remembered answers to "which workspace should this repository's links
/// open in?".
@immutable
class RepoLinkWorkspaceChoices {
  /// Creates a snapshot over [byRepo].
  const RepoLinkWorkspaceChoices([this.byRepo = const {}]);

  /// Decodes the stored JSON, treating anything malformed as no choices: a
  /// preference written by a newer client must not break link handling.
  factory RepoLinkWorkspaceChoices.decode(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const RepoLinkWorkspaceChoices();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return const RepoLinkWorkspaceChoices();
      }
      return RepoLinkWorkspaceChoices(
        Map.unmodifiable({
          for (final entry in decoded.entries)
            if (entry.key is String && entry.value is String)
              entry.key as String: entry.value as String,
        }),
      );
    } on FormatException {
      return const RepoLinkWorkspaceChoices();
    }
  }

  /// `owner/name` (spelled as when it was remembered) → workspace id.
  final Map<String, String> byRepo;

  /// The remembered workspace for [repoFullName], matched case-insensitively
  /// the way GitHub matches owner and repository names.
  String? workspaceFor(String repoFullName) {
    final key = _keyFor(repoFullName);
    return key == null ? null : byRepo[key];
  }

  /// Returns a snapshot that opens [repoFullName] in [workspaceId].
  RepoLinkWorkspaceChoices remember(String repoFullName, String workspaceId) {
    final next = Map.of(byRepo)..remove(_keyFor(repoFullName));
    next[repoFullName] = workspaceId;
    return RepoLinkWorkspaceChoices(Map.unmodifiable(next));
  }

  /// Returns a snapshot without a choice for [repoFullName].
  RepoLinkWorkspaceChoices forget(String repoFullName) =>
      RepoLinkWorkspaceChoices(
        Map.unmodifiable(Map.of(byRepo)..remove(_keyFor(repoFullName))),
      );

  /// The stored JSON form.
  String encode() => jsonEncode(byRepo);

  String? _keyFor(String repoFullName) {
    final wanted = repoFullName.toLowerCase();
    for (final key in byRepo.keys) {
      if (key.toLowerCase() == wanted) {
        return key;
      }
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is RepoLinkWorkspaceChoices && mapEquals(other.byRepo, byRepo);

  @override
  int get hashCode => Object.hashAllUnordered(
    byRepo.entries.map((e) => Object.hash(e.key, e.value)),
  );
}

/// Which of [candidates] a repository link opens in without asking, or null
/// when the user has to choose.
///
/// [candidates] are the ids of every workspace linking the repository, in the
/// operator's workspace order; it is never empty (an unlinked repository is
/// the caller's fallback, not a choice). [remembered] only counts while it is
/// still a candidate: a choice for a workspace that has since dropped the
/// repository, or was deleted, asks again rather than opening the wrong one.
String? repoLinkWorkspaceWithoutAsking({
  required List<String> candidates,
  required String? remembered,
}) {
  assert(candidates.isNotEmpty, 'An unlinked repository has no candidates.');
  if (candidates.length == 1) {
    return candidates.single;
  }
  return candidates.contains(remembered) ? remembered : null;
}

/// The signed-in user's remembered repository → workspace choices.
final repoLinkWorkspaceChoicesProvider =
    NotifierProvider<
      RepoLinkWorkspaceChoicesNotifier,
      RepoLinkWorkspaceChoices
    >(RepoLinkWorkspaceChoicesNotifier.new);

/// Loads and persists the user's remembered repository → workspace choices.
class RepoLinkWorkspaceChoicesNotifier
    extends Notifier<RepoLinkWorkspaceChoices> {
  late AppPreferences _preferences;

  @override
  RepoLinkWorkspaceChoices build() {
    _preferences = ref.watch(appPreferencesProvider);
    return RepoLinkWorkspaceChoices.decode(
      _preferences.getString(repoLinkWorkspaceChoicesKey),
    );
  }

  /// Opens [repoFullName]'s links in [workspaceId] from now on.
  Future<void> remember(String repoFullName, String workspaceId) =>
      _save(state.remember(repoFullName, workspaceId));

  /// Asks again the next time a link to [repoFullName] arrives.
  Future<void> forget(String repoFullName) => _save(state.forget(repoFullName));

  Future<void> _save(RepoLinkWorkspaceChoices next) async {
    // An empty map removes the key rather than storing `{}`, so the synced
    // copy is deleted too instead of lingering as an empty value.
    if (next.byRepo.isEmpty) {
      await _preferences.remove(repoLinkWorkspaceChoicesKey);
    } else {
      await _preferences.setString(repoLinkWorkspaceChoicesKey, next.encode());
    }
    state = next;
  }
}
