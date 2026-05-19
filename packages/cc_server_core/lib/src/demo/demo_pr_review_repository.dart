import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_domain/features/pr_review/domain/entities/commit_status.dart';
import 'package:cc_domain/features/pr_review/domain/entities/issue_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_commit.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_reviewer.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_timeline_event.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/pending_review_comment.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_server_core/src/demo/demo_pr_cache.dart';
import 'package:cc_server_core/src/pr_review/pr_cache_codec.dart';

/// A PR-review repository that is structurally offline.
///
/// It holds no Dio, no forge client and no token: every read is decoded out
/// of the workspace's own `caches` table (seeded by `DemoSeeder`) and every
/// write goes straight back into the same rows. A demo visitor can therefore
/// leave an inline comment, reply in a thread, react and submit a review, and
/// watch their words appear in the thread — with nothing leaving the container.
///
/// Reads ride `CacheDao.watch`, which is a live Drift query, so a write-back
/// updates every open stream without any change-signal plumbing.
///
/// It extends [EmptyPrReviewRepository] so the ~45-member interface stays
/// satisfied as it grows: anything not overridden here degrades to that class's
/// inert default rather than failing to compile. The verbs with no write-back
/// (merge, close, assignees, reviewers, stacks, upload) are deliberately left
/// inert AND are denied at the op layer by `DemoProfile.deniedMutations`, so a
/// visitor never presses a button whose effect does not exist.
class DemoPrReviewRepository extends EmptyPrReviewRepository {
  /// Creates a repository over one workspace database and one `owner/repo`.
  DemoPrReviewRepository({
    required WorkspaceDatabase db,
    required this.owner,
    required this.repo,
    required this.visitor,
  }) : _db = db;

  final WorkspaceDatabase _db;

  /// Repo owner (the fictional org).
  final String owner;

  /// Repo name.
  final String repo;

  /// The visitor, used as the author of anything they write.
  final PrUser visitor;

  /// Serializes the read-modify-write write-backs. Every mutation reads a
  /// JSON list, appends, and re-encodes it across awaits; two interleaved
  /// calls computed the same `_nextId` and the later put silently dropped the
  /// earlier row. One visitor with two tabs is enough to hit that.
  Future<void> _writeLock = Future<void>.value();

  /// Runs [action] holding the write lock, so list edits cannot interleave.
  Future<T> _locked<T>(Future<T> Function() action) {
    final run = _writeLock.then((_) => action());
    // Swallow only for the CHAIN: `action`'s own error must reach its caller,
    // but a failed action must not poison every later write.
    _writeLock = run.then((_) {}, onError: (_) {});
    return run;
  }

  String get _repoFullName => '$owner/$repo';

  String get _workspaceId => _db.workspaceId;

  String _key(int prNumber) => demoPrCacheKey(_repoFullName, prNumber);

  Future<String?> _read(String kind, String key) =>
      _db.cacheDao.read(_workspaceId, kind, key);

  Future<void> _put(String kind, String key, String payload) =>
      _db.cacheDao.put(_workspaceId, kind, key, payload);

  /// Watches a JSON-list cache row, decoding each element with [decode].
  Stream<List<T>> _watchList<T>(
    String kind,
    String key,
    T Function(Map<String, dynamic>) decode,
  ) => _db.cacheDao.watch(_workspaceId, kind, key).map((raw) {
    if (raw == null || raw.isEmpty) {
      return <T>[];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return <T>[];
    }
    return [
      for (final e in decoded)
        if (e is Map) decode(Map<String, dynamic>.from(e)),
    ];
  });

  /// Reads a JSON-list cache row once.
  Future<List<Map<String, dynamic>>> _readList(String kind, String key) async {
    final raw = await _read(kind, key);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return [];
    }
    return [
      for (final e in decoded)
        if (e is Map) Map<String, dynamic>.from(e),
    ];
  }

  // ── Reads ────────────────────────────────────────────────────────────────

  @override
  Stream<PullRequest?> watchPullRequest(int prNumber) => _db.cacheDao
      .watch(_workspaceId, DemoPrCacheKind.detail, _key(prNumber))
      .map((raw) {
        if (raw == null || raw.isEmpty) {
          return null;
        }
        final decoded = jsonDecode(raw);
        return decoded is Map
            ? PrCacheCodec.pullRequestFromCache(
                Map<String, dynamic>.from(decoded),
              )
            : null;
      });

  /// The diff is stored as RAW text, not JSON — matching how the production
  /// cache stores it (`decode: (raw) => raw`).
  @override
  Stream<String> watchDiff(int prNumber) => _db.cacheDao
      .watch(_workspaceId, DemoPrCacheKind.diff, _key(prNumber))
      .map((raw) => raw ?? '');

  @override
  Stream<List<PrFile>> watchFiles(int prNumber) => _watchList(
    DemoPrCacheKind.files,
    _key(prNumber),
    PrCacheCodec.fileFromCache,
  );

  @override
  Stream<String> watchFileContent(String path, String ref) => _db.cacheDao
      .watch(
        _workspaceId,
        DemoPrCacheKind.fileContent,
        demoFileContentCacheKey(_repoFullName, ref, path),
      )
      .map((raw) => raw ?? '');

  @override
  Stream<List<PrCommit>> watchCommits(int prNumber) => _watchList(
    DemoPrCacheKind.commits,
    _key(prNumber),
    PrCacheCodec.commitFromCache,
  );

  @override
  Stream<List<PrFile>> watchCommitFiles(String sha) => _watchList(
    DemoPrCacheKind.commitFiles,
    demoShaCacheKey(_repoFullName, sha),
    PrCacheCodec.fileFromCache,
  );

  @override
  Stream<List<PrReviewSubmission>> watchReviews(int prNumber) => _watchList(
    DemoPrCacheKind.reviews,
    _key(prNumber),
    PrCacheCodec.reviewFromCache,
  );

  @override
  Stream<List<PrCodeReviewComment>> watchReviewComments(int prNumber) =>
      _watchList(
        DemoPrCacheKind.reviewComments,
        _key(prNumber),
        PrCacheCodec.reviewCommentFromCache,
      );

  @override
  Stream<List<IssueComment>> watchIssueComments(int prNumber) => _watchList(
    DemoPrCacheKind.issueComments,
    _key(prNumber),
    PrCacheCodec.issueCommentFromCache,
  );

  @override
  Stream<List<PrTimelineEvent>> watchTimelineEvents(int prNumber) => _watchList(
    DemoPrCacheKind.timelineEvents,
    _key(prNumber),
    PrCacheCodec.timelineEventFromCache,
  );

  @override
  Stream<List<CheckRun>> watchCheckRuns(int prNumber) => _watchList(
    DemoPrCacheKind.checkRuns,
    _key(prNumber),
    PrCacheCodec.checkRunFromCache,
  );

  @override
  Stream<List<CommitStatus>> watchCommitStatuses(int prNumber) => _watchList(
    DemoPrCacheKind.commitStatuses,
    _key(prNumber),
    PrCacheCodec.commitStatusFromCache,
  );

  @override
  Stream<List<PrReviewer>> watchReviewers(int prNumber) => _watchList(
    DemoPrCacheKind.reviewerState,
    _key(prNumber),
    PrCacheCodec.reviewerFromCache,
  );

  @override
  Future<List<PrUser>> listAssignableUsers() async {
    final rows = await _readList(
      DemoPrCacheKind.assignableUsers,
      _repoFullName,
    );
    return [for (final m in rows) ?PrCacheCodec.userFromCache(m)];
  }

  // ── Drafts ───────────────────────────────────────────────────────────────
  // Real rows in `review_drafts`, the same table the production repository
  // uses — a draft is a visitor's own unsent text and belongs in the workspace
  // file that gets deleted with them.

  @override
  Future<void> upsertDraft(int prNumber, String text) =>
      _db.reviewDao.upsertDraft(owner, repo, prNumber, text);

  @override
  Future<String?> getDraft(int prNumber) =>
      _db.reviewDao.getDraft(owner, repo, prNumber);

  @override
  Future<void> clearDraft(int prNumber) =>
      _db.reviewDao.clearDraft(owner, repo, prNumber);

  // ── Writes, all of them into the cache the reads watch ───────────────────

  @override
  Future<Map<String, dynamic>> postReviewComment({
    required int prNumber,
    required String commitSha,
    required String path,
    required int line,
    required String side,
    required String body,
    int? startLine,
    String? startSide,
  }) => _locked(() async {
    final key = _key(prNumber);
    final rows = await _readList(DemoPrCacheKind.reviewComments, key);
    final id = _nextId(rows);
    rows.add({
      'id': id,
      'body': body,
      'user': PrCacheCodec.userToCache(visitor),
      'path': path,
      'position': line,
      'created_at': DateTime.now().toIso8601String(),
      'side': side,
      'start_line': ?startLine,
      'diff_hunk': '',
      'line': line,
      'thread_id': 'demo-thread-$id',
      'reactions': <Map<String, dynamic>>[],
    });
    await _put(DemoPrCacheKind.reviewComments, key, jsonEncode(rows));
    return {'id': id};
  });

  @override
  Future<void> replyToReviewComment({
    required int prNumber,
    required int parentCommentId,
    required String body,
  }) => _locked(() async {
    final key = _key(prNumber);
    final rows = await _readList(DemoPrCacheKind.reviewComments, key);
    final parent = rows.firstWhere(
      (r) => r['id'] == parentCommentId,
      orElse: () => <String, dynamic>{},
    );
    final id = _nextId(rows);
    rows.add({
      'id': id,
      'body': body,
      'user': PrCacheCodec.userToCache(visitor),
      'path': parent['path'] ?? '',
      'position': parent['position'],
      'created_at': DateTime.now().toIso8601String(),
      'side': parent['side'] ?? 'RIGHT',
      'in_reply_to_id': parentCommentId,
      'diff_hunk': '',
      'line': parent['line'],
      // Replies join the parent's thread, which is what makes them render
      // nested rather than as a new top-level comment.
      if (parent['thread_id'] != null) 'thread_id': parent['thread_id'],
      'reactions': <Map<String, dynamic>>[],
    });
    await _put(DemoPrCacheKind.reviewComments, key, jsonEncode(rows));
  });

  @override
  Future<void> submitReview({
    required int prNumber,
    required String event,
    String? body,
    List<PendingReviewComment> comments = const [],
  }) => _locked(() async {
    final key = _key(prNumber);
    // Pending inline comments materialize as real thread comments, so
    // submitting a review the visitor composed across several files lands all
    // of it at once — the way it does against a real forge.
    if (comments.isNotEmpty) {
      final inline = await _readList(DemoPrCacheKind.reviewComments, key);
      for (final pending in comments) {
        final id = _nextId(inline);
        inline.add({
          'id': id,
          'body': pending.body,
          'user': PrCacheCodec.userToCache(visitor),
          'path': pending.path,
          'position': pending.line,
          'created_at': DateTime.now().toIso8601String(),
          'side': pending.side,
          if (pending.startLine != null) 'start_line': pending.startLine,
          'diff_hunk': '',
          'line': pending.line,
          'thread_id': 'demo-thread-$id',
          'reactions': <Map<String, dynamic>>[],
        });
      }
      await _put(DemoPrCacheKind.reviewComments, key, jsonEncode(inline));
    }
    final rows = await _readList(DemoPrCacheKind.reviews, key);
    rows.add({
      'id': _nextId(rows),
      'state': switch (event.toUpperCase()) {
        'APPROVE' => PrReviewSubmissionState.approved.name,
        'REQUEST_CHANGES' => PrReviewSubmissionState.changesRequested.name,
        _ => PrReviewSubmissionState.commented.name,
      },
      'author': PrCacheCodec.userToCache(visitor),
      'body': body ?? '',
      'submitted_at': DateTime.now().toIso8601String(),
      'reactions': <Map<String, dynamic>>[],
    });
    await _put(DemoPrCacheKind.reviews, key, jsonEncode(rows));
  });

  @override
  Future<void> setReviewThreadResolved({
    required int prNumber,
    required String threadId,
    required bool resolved,
  }) => _locked(() async {
    final key = _key(prNumber);
    final rows = await _readList(DemoPrCacheKind.reviewComments, key);
    for (final row in rows) {
      if (row['thread_id'] == threadId) {
        row['is_resolved'] = resolved;
      }
    }
    await _put(DemoPrCacheKind.reviewComments, key, jsonEncode(rows));
  });

  @override
  Future<void> markFileAsViewed({
    required int prNumber,
    required String externalId,
    required String path,
    required bool viewed,
  }) => _locked(() async {
    final key = _key(prNumber);
    final rows = await _readList(DemoPrCacheKind.files, key);
    // The key the codec reads is `viewed_state` (the PrFileViewedState enum
    // name) — the production repository writes exactly this. Writing a bare
    // `viewed` bool here was invisible: the watch stream re-decodes through
    // `PrCacheCodec.fileFromCache`, which ignores unknown keys.
    final wire = viewed
        ? PrFileViewedState.viewed.name
        : PrFileViewedState.unviewed.name;
    for (final row in rows) {
      if (row['filename'] == path || row['path'] == path) {
        row['viewed_state'] = wire;
      }
    }
    await _put(DemoPrCacheKind.files, key, jsonEncode(rows));
  });

  @override
  Future<void> toggleReviewCommentReaction({
    required int commentId,
    required int prNumber,
    required String content,
    required bool add,
    String? currentUserLogin,
  }) => _toggleReaction(
    kind: DemoPrCacheKind.reviewComments,
    prNumber: prNumber,
    id: commentId,
    content: content,
    add: add,
  );

  @override
  Future<void> toggleIssueCommentReaction({
    required int commentId,
    required int prNumber,
    required String content,
    required bool add,
    String? currentUserLogin,
  }) => _toggleReaction(
    kind: DemoPrCacheKind.issueComments,
    prNumber: prNumber,
    id: commentId,
    content: content,
    add: add,
  );

  @override
  Future<void> toggleReviewReaction({
    required int reviewId,
    required int prNumber,
    required String content,
    required bool add,
    String? currentUserLogin,
  }) => _toggleReaction(
    kind: DemoPrCacheKind.reviews,
    prNumber: prNumber,
    id: reviewId,
    content: content,
    add: add,
  );

  @override
  Future<void> togglePullRequestReaction({
    required int prNumber,
    required String content,
    required bool add,
    String? currentUserLogin,
  }) async {
    final key = _key(prNumber);
    final raw = await _read(DemoPrCacheKind.detail, key);
    if (raw == null || raw.isEmpty) {
      return;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return;
    }
    final row = Map<String, dynamic>.from(decoded);
    row['reactions'] = _applyReaction(row['reactions'], content, add: add);
    await _put(DemoPrCacheKind.detail, key, jsonEncode(row));
  }

  /// Invalidation is a no-op with a purpose: there is no upstream to re-fetch
  /// from, and dropping the row would empty the page permanently.
  @override
  Future<void> invalidatePullRequest(int prNumber) async {}

  @override
  Future<void> invalidateDiff(int prNumber) async {}

  Future<void> _toggleReaction({
    required String kind,
    required int prNumber,
    required int id,
    required String content,
    required bool add,
  }) => _locked(() async {
    final key = _key(prNumber);
    final rows = await _readList(kind, key);
    for (final row in rows) {
      if (row['id'] == id) {
        row['reactions'] = _applyReaction(row['reactions'], content, add: add);
      }
    }
    await _put(kind, key, jsonEncode(rows));
  });

  /// Adds or removes the visitor from the [content] reaction group.
  List<Map<String, dynamic>> _applyReaction(
    dynamic existing,
    String content, {
    required bool add,
  }) {
    final groups = <Map<String, dynamic>>[
      for (final g in (existing is List ? existing : const []))
        if (g is Map) Map<String, dynamic>.from(g),
    ];
    final index = groups.indexWhere((g) => g['content'] == content);
    if (index == -1) {
      if (!add) {
        return groups;
      }
      groups.add({
        'content': content,
        'emoji': _emojiFor(content),
        'count': 1,
        'user_reacted': true,
        'usernames': [visitor.login],
      });
      return groups;
    }
    final group = groups[index];
    final names = <String>[
      for (final n in (group['usernames'] is List
          ? group['usernames'] as List
          : const []))
        n.toString(),
    ]..removeWhere((n) => n == visitor.login);
    if (add) {
      names.add(visitor.login);
    }
    if (names.isEmpty) {
      groups.removeAt(index);
      return groups;
    }
    group
      ..['usernames'] = names
      ..['count'] = names.length
      ..['user_reacted'] = add;
    return groups;
  }

  static String _emojiFor(String content) => switch (content) {
    'THUMBS_UP' || '+1' => '👍',
    'THUMBS_DOWN' || '-1' => '👎',
    'LAUGH' => '😄',
    'HOORAY' => '🎉',
    'CONFUSED' => '😕',
    'HEART' => '❤️',
    'ROCKET' => '🚀',
    'EYES' => '👀',
    _ => '👍',
  };

  /// One past the highest existing id, so a new row never collides with a
  /// seeded one.
  static int _nextId(List<Map<String, dynamic>> rows) {
    var max = 0;
    for (final row in rows) {
      final id = row['id'];
      if (id is int && id > max) {
        max = id;
      }
    }
    return max + 1;
  }
}
