import 'dart:convert';

import 'package:control_center/core/providers/storage_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A worktree file the operator opened in a conversation's editor: the repo it
/// belongs to (empty when the editor reported none) and its repo-relative path.
typedef RecentFile = ({String repoId, String path});

/// Identifies one conversation's recently-opened list. The workspace is part of
/// the key so a list is only ever read back under the workspace it was written
/// in.
typedef RecentFilesArgs = ({String workspaceId, String spaceId});

/// Storage key prefix for the quick-open history; one JSON blob per workspace,
/// mapping space id → its most-recent-first file list.
const String recentFilesKeyPrefix = 'ide_recent_files.';

/// The files a conversation's editor showed most recently, newest first — the
/// quick-open picker's default list (VS Code's "recently opened").
///
/// Per-device UI history, like the sidebar pins: persisted through
/// [AppPreferences] rather than the server. Bounded twice — [maxFiles] per
/// conversation and [maxSpaces] conversations per workspace (least recently
/// touched dropped first) — so the blob cannot grow with every conversation
/// the operator ever opened.
class RecentFilesNotifier extends Notifier<List<RecentFile>> {
  /// Creates the notifier for one conversation.
  RecentFilesNotifier(this.args);

  /// The conversation this list belongs to.
  final RecentFilesArgs args;

  /// How many files one conversation remembers.
  static const int maxFiles = 50;

  /// How many conversations per workspace keep a list.
  static const int maxSpaces = 30;

  late AppPreferences _prefs;

  String get _key => '$recentFilesKeyPrefix${args.workspaceId}';

  @override
  List<RecentFile> build() {
    _prefs = ref.watch(appPreferencesProvider);
    return _readAll()[args.spaceId] ?? const [];
  }

  /// Moves `(repoId, path)` to the front. A no-op when it already leads, so
  /// callers may report every focus change.
  void touch({required String repoId, required String path}) {
    if (path.isEmpty) {
      return;
    }
    final current = state;
    if (current.isNotEmpty && _same(current.first, repoId, path)) {
      return;
    }
    final next = <RecentFile>[
      (repoId: repoId, path: path),
      for (final f in current)
        if (!_sameFile(f, repoId, path)) f,
    ];
    _write(next.length > maxFiles ? next.sublist(0, maxFiles) : next);
  }

  /// Drops `(repoId, path)` from the list (the picker's × button).
  void remove({required String repoId, required String path}) {
    final next = [
      for (final f in state)
        if (!_same(f, repoId, path)) f,
    ];
    if (next.length != state.length) {
      _write(next);
    }
  }

  static bool _same(RecentFile f, String repoId, String path) =>
      f.path == path && f.repoId == repoId;

  /// Whether `f` and `(repoId, path)` name one file. The editor can report a
  /// file without its repo, and that report and a repo-qualified one for the
  /// same path are the same entry.
  static bool _sameFile(RecentFile f, String repoId, String path) =>
      f.path == path &&
      (f.repoId == repoId || f.repoId.isEmpty || repoId.isEmpty);

  void _write(List<RecentFile> files) {
    final all = _readAll()..remove(args.spaceId);
    // Insertion order is recency order: the conversation written last is
    // re-added last, and the oldest ones fall off the front.
    if (files.isNotEmpty) {
      all[args.spaceId] = files;
    }
    while (all.length > maxSpaces) {
      all.remove(all.keys.first);
    }
    _prefs.setString(
      _key,
      jsonEncode({
        for (final e in all.entries)
          e.key: [
            for (final f in e.value) {'r': f.repoId, 'p': f.path},
          ],
      }),
    );
    state = List.unmodifiable(files);
  }

  /// Every conversation's list for the workspace. A malformed blob reads as
  /// empty rather than throwing — this is a convenience, not durable state.
  Map<String, List<RecentFile>> _readAll() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return {};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return {};
      }
      return {
        for (final e in decoded.entries)
          if (e.key is String && e.value is List)
            e.key as String: [
              for (final f in (e.value as List).whereType<Map>())
                if (f['p'] is String && (f['p'] as String).isNotEmpty)
                  (
                    repoId: f['r'] is String ? f['r'] as String : '',
                    path: f['p'] as String,
                  ),
            ],
      };
    } on FormatException {
      return {};
    }
  }
}

/// One conversation's recently-opened files, newest first.
final recentFilesProvider =
    NotifierProvider.family<
      RecentFilesNotifier,
      List<RecentFile>,
      RecentFilesArgs
    >(RecentFilesNotifier.new);
