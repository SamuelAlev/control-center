import 'package:cc_domain/features/pr_review/domain/entities/pr_inline_thread.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/pending_review_comment.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for inline PR review comments grouped by file path.
class PrInlineCommentsState {
  /// Creates a [PrInlineCommentsState] with the given threads and counter.
  PrInlineCommentsState({this.threads = const [], this.idCounter = 0})
    : threadsByPath = _groupByPath(threads);

  PrInlineCommentsState._({
    required this.threads,
    required this.idCounter,
    required this.threadsByPath,
  });

  /// All inline threads, across all files.
  final List<PrInlineThread> threads;

  /// Monotonically increasing counter for generating unique entry/thread IDs.
  final int idCounter;

  /// Threads grouped by file path so per-file consumers can subscribe via
  /// `select((s) => s.threadsByPath[path])` and avoid rebuilding when an
  /// unrelated file's threads change.
  final Map<String, List<PrInlineThread>> threadsByPath;

  /// Returns a copy with the given fields replaced.
  PrInlineCommentsState copyWith({
    List<PrInlineThread>? threads,
    int? idCounter,
  }) => PrInlineCommentsState._(
    threads: threads ?? this.threads,
    idCounter: idCounter ?? this.idCounter,
    threadsByPath: threads != null ? _groupByPath(threads) : threadsByPath,
  );

  static Map<String, List<PrInlineThread>> _groupByPath(
    List<PrInlineThread> threads,
  ) {
    if (threads.isEmpty) {
      return const {};
    }
    final out = <String, List<PrInlineThread>>{};
    for (final t in threads) {
      (out[t.filePath] ??= <PrInlineThread>[]).add(t);
    }
    return out;
  }
}

@immutable
/// Context needed to post inline comments to GitHub.
class PrPostingContext {
  /// Creates a [PrPostingContext] with the required posting parameters.
  const PrPostingContext({
    required this.repository,
    required this.prNumber,
    required this.commitSha,
  });

  /// The PR review repository used to post comments.
  final PrReviewRepository repository;

  /// The pull request number.
  final int prNumber;

  /// The head commit SHA to attach comments to.
  final String commitSha;
}

/// Controller for managing inline review comment threads for a single PR.
class PrInlineCommentsController extends Notifier<PrInlineCommentsState> {
  /// Creates a controller scoped to [pr].
  PrInlineCommentsController(this.pr);

  /// The pull request this controller is scoped to: repo coords + number, so
  /// a comment on PR #N is posted to the repo #N lives in — never to whatever
  /// repo happens to be active.
  final PrRef pr;

  PrPostingContext? _context;

  @override
  /// Builds the initial comment state from the PR's own repo.
  PrInlineCommentsState build() {
    // Both the repo row and the repository come from the controller's own
    // [PrRef], never from the active repo: a comment on PR #N must be posted
    // to the repo #N lives in, even mid-navigation or right after a workspace
    // switch.
    final repo = ref.watch(prRepoRowProvider(pr));
    final repository = ref.watch(prRepositoryProvider(pr));
    final prAsync = ref.watch(prDetailProvider(pr));
    final prEntity = prAsync.value;

    if (repo != null &&
        repository != null &&
        prEntity != null &&
        repo.remoteOwner.isNotEmpty &&
        repo.remoteName.isNotEmpty &&
        prEntity.headSha.isNotEmpty) {
      _context = PrPostingContext(
        repository: repository,
        prNumber: pr.number,
        commitSha: prEntity.headSha,
      );
    } else {
      _context = null;
    }

    return PrInlineCommentsState();
  }

  /// All inline threads in the current state.
  List<PrInlineThread> get threads => state.threads;

  /// Whether a pull request is connected, i.e. whether anything written here
  /// can actually reach the forge. False during load, after a workspace switch
  /// or when the PR carries no head sha — in which case a comment can only be
  /// held locally and offering to "start a review" would be a lie.
  bool get canPost => _context != null;

  /// Threads for a specific file path, or empty if none.
  List<PrInlineThread> forFile(String filePath) =>
      state.threadsByPath[filePath] ?? const <PrInlineThread>[];

  /// The identity stamped on locally-created entries: the signed-in GitHub
  /// viewer, so a just-written comment reads as its real author (login +
  /// avatar) instead of an anonymous "You" while the forge round-trips.
  ///
  /// Read at write time, never watched: a late-resolving identity lookup must
  /// not rebuild this controller (a rebuild returns a fresh state and would
  /// drop the threads it already holds). Falls back to 'You' while the
  /// identity is unresolved, which the server-comment stream corrects once
  /// the comment lands.
  ({String author, String? avatarUrl}) _viewerIdentity() {
    final user = ref.read(githubUserProvider).value;
    final login = user?.login ?? '';
    if (user == null || login.isEmpty) {
      return (author: 'You', avatarUrl: null);
    }
    final avatar = user.avatarUrl;
    return (author: login, avatarUrl: avatar.isEmpty ? null : avatar);
  }

  /// Finds a thread that covers the given line and side, or null.
  PrInlineThread? forAnchor({
    required String filePath,
    required int line,
    required String side,
  }) {
    for (final t in state.threads) {
      if (t.filePath == filePath &&
          t.side == side &&
          line >= t.line &&
          line <= t.lineEnd) {
        return t;
      }
    }
    return null;
  }

  /// Finds a thread by its local ID, or null.
  PrInlineThread? byId(String id) {
    for (final t in state.threads) {
      if (t.id == id) {
        return t;
      }
    }
    return null;
  }

  /// Creates a new thread with one entry.
  ///
  /// [batched] queues it for the next review submission instead of posting it
  /// now: the comment stays local, shows a "pending review" badge and goes to
  /// the forge with the verdict in [submitPendingReview]. That is the
  /// difference between leaving five drive-by comments and leaving one review.
  PrInlineThread create({
    required String filePath,
    required int line,
    required String side,
    required PrInlineThreadKind kind,
    required String originalCode,
    required String suggestedCode,
    required String authorBody,
    int? lineEnd,
    int? startCol,
    int? endCol,
    bool batched = false,
    String? author,
  }) {
    final c1 = state.idCounter + 1;
    final c2 = c1 + 1;
    final ctx = _context;
    // Production passes nothing: entries stamp the signed-in GitHub viewer.
    // [author] exists so tests can fixture a thread from someone else.
    final identity = author == null
        ? _viewerIdentity()
        : (author: author, avatarUrl: null);
    final thread = PrInlineThread(
      id: 'thread-$c1',
      filePath: filePath,
      line: line,
      lineEnd: lineEnd,
      startCol: startCol,
      endCol: endCol,
      side: side,
      kind: kind,
      originalCode: originalCode,
      suggestedCode: suggestedCode,
      entries: [
        PrInlineEntry(
          id: 'entry-$c2',
          author: identity.author,
          authorAvatarUrl: identity.avatarUrl,
          body: authorBody,
        ),
      ],
      syncState: ctx == null
          ? PrInlineSyncState.local
          : batched
          ? PrInlineSyncState.pendingReview
          : PrInlineSyncState.pending,
    );
    state = state.copyWith(threads: [...state.threads, thread], idCounter: c2);

    if (ctx != null && !batched) {
      _postThread(thread, authorBody);
    }
    return thread;
  }

  /// Threads queued for the next review submission, in creation order.
  List<PrInlineThread> get pendingReviewThreads => [
    for (final t in state.threads)
      if (t.isPendingReview) t,
  ];

  /// Submits the queued comments together with a verdict as ONE review.
  ///
  /// [event] is `APPROVE` / `REQUEST_CHANGES` / `COMMENT`. On success the
  /// queued threads are dropped locally — the forge now owns them and they come
  /// back through the server-comment stream, so keeping the local copies would
  /// render every comment twice. On failure they are kept and marked `error`,
  /// because silently discarding a reviewer's written work is unforgivable.
  Future<void> submitPendingReview({
    required String event,
    String? body,
  }) async {
    final ctx = _context;
    final queued = pendingReviewThreads;
    if (ctx == null) {
      throw StateError('No pull request is connected to post a review to.');
    }
    try {
      await ctx.repository.submitReview(
        prNumber: ctx.prNumber,
        event: event,
        body: (body == null || body.trim().isEmpty) ? null : body.trim(),
        comments: [
          for (final t in queued)
            PendingReviewComment(
              path: t.filePath,
              line: t.lineEnd,
              side: t.side,
              body: t.entries.isEmpty ? '' : t.entries.first.body,
              startLine: t.isMultiLine ? t.line : null,
              startSide: t.isMultiLine ? t.side : null,
            ),
        ],
      );
    } catch (e) {
      AppLog.e('PrInlineComments', 'Failed to submit review: $e', e);
      final ids = {for (final t in queued) t.id};
      final threads = [
        for (final t in state.threads)
          if (ids.contains(t.id))
            t.copyWith(
              syncState: PrInlineSyncState.error,
              syncError: e.toString(),
            )
          else
            t,
      ];
      state = state.copyWith(threads: threads);
      rethrow;
    }
    final ids = {for (final t in queued) t.id};
    state = state.copyWith(
      threads: [
        for (final t in state.threads)
          if (!ids.contains(t.id)) t,
      ],
    );
  }

  /// Drops every queued comment without posting anything.
  void discardPendingReview() {
    final threads = [
      for (final t in state.threads)
        if (!t.isPendingReview) t,
    ];
    if (threads.length != state.threads.length) {
      state = state.copyWith(threads: threads);
    }
  }

  Future<void> _postThread(PrInlineThread thread, String body) async {
    final ctx = _context;
    if (ctx == null) {
      return;
    }
    try {
      final result = await ctx.repository.postReviewComment(
        prNumber: ctx.prNumber,
        commitSha: ctx.commitSha,
        path: thread.filePath,
        line: thread.lineEnd,
        side: thread.side,
        startLine: thread.isMultiLine ? thread.line : null,
        startSide: thread.isMultiLine ? thread.side : null,
        body: body,
      );
      _patchThread(
        thread.id,
        (t) => t.copyWith(
          serverId: result['id'] as int?,
          syncState: PrInlineSyncState.synced,
        ),
      );
    } catch (e) {
      AppLog.e('PrInlineComments', 'Failed to post review comment: $e', e);
      _patchThread(
        thread.id,
        (t) => t.copyWith(
          syncState: PrInlineSyncState.error,
          syncError: e.toString(),
        ),
      );
    }
  }

  /// Retries posting a thread that previously failed.
  ///
  /// Only reaches threads that were posted individually. A queued review
  /// comment that failed as part of a batch is retried by submitting the review
  /// again, not by posting it on its own — that would split the review the
  /// reviewer deliberately bundled.
  Future<void> retryPost(String threadId) async {
    final t = byId(threadId);
    if (t == null || _context == null) {
      return;
    }
    if (t.syncState != PrInlineSyncState.error) {
      return;
    }
    final firstBody = t.entries.isEmpty ? '' : t.entries.first.body;
    if (firstBody.isEmpty) {
      return;
    }
    _patchThread(
      t.id,
      (x) => x.copyWith(syncState: PrInlineSyncState.pending, syncError: null),
    );
    await _postThread(t, firstBody);
  }

  /// Marks a forge-side conversation resolved (or reopens it).
  ///
  /// Lives here rather than in each surface so the diff and the conversation
  /// timeline write through the same path — a resolve that only worked on one
  /// of them would leave two views disagreeing about a settled discussion.
  /// [threadId] is the forge's thread id, not a comment id.
  Future<void> setServerThreadResolved({
    required String threadId,
    required bool resolved,
  }) async {
    final ctx = _context;
    if (ctx == null) {
      throw StateError('No pull request is connected.');
    }
    await ctx.repository.setReviewThreadResolved(
      prNumber: ctx.prNumber,
      threadId: threadId,
      resolved: resolved,
    );
  }

  /// Replies to [thread], whichever kind it is.
  ///
  /// A DRAFT thread lives in this controller, so the reply is appended locally
  /// (and posted if the thread already has a server id). A SYNTHESISED SERVER
  /// thread does not live here at all — [reply] looked it up by id, found
  /// nothing and returned, so replying to any forge-side conversation silently
  /// did nothing. This routes it to the forge by its root comment id instead.
  ///
  /// Throws on a failed post so the caller can say so; the reply lands back
  /// through the comment stream (the repository busts that cache on write).
  Future<void> replyTo(PrInlineThread thread, String body) async {
    final text = body.trim();
    if (text.isEmpty) {
      return;
    }
    if (byId(thread.id) != null) {
      reply(threadId: thread.id, body: text);
      return;
    }
    final ctx = _context;
    final parentId = thread.serverId;
    if (ctx == null || parentId == null) {
      throw StateError('This conversation cannot be replied to yet.');
    }
    await ctx.repository.replyToReviewComment(
      prNumber: ctx.prNumber,
      parentCommentId: parentId,
      body: text,
    );
  }

  /// Adds a reply entry to an existing thread.
  void reply({required String threadId, required String body, String? author}) {
    if (body.trim().isEmpty) {
      return;
    }
    final threads = [...state.threads];
    final i = threads.indexWhere((t) => t.id == threadId);
    if (i == -1) {
      return;
    }
    final t = threads[i];
    final counter = state.idCounter + 1;
    final identity = author == null
        ? _viewerIdentity()
        : (author: author, avatarUrl: null);
    final entry = PrInlineEntry(
      id: 'entry-$counter',
      author: identity.author,
      authorAvatarUrl: identity.avatarUrl,
      body: body.trim(),
    );
    threads[i] = t.copyWith(entries: [...t.entries, entry]);
    state = state.copyWith(threads: threads, idCounter: counter);

    final ctx = _context;
    if (ctx != null && t.serverId != null) {
      _postReply(threads[i], entry, body.trim());
    }
  }

  Future<void> _postReply(
    PrInlineThread thread,
    PrInlineEntry entry,
    String body,
  ) async {
    final ctx = _context;
    if (ctx == null) {
      return;
    }
    final parentId = thread.serverId;
    if (parentId == null) {
      return;
    }
    try {
      await ctx.repository.replyToReviewComment(
        prNumber: ctx.prNumber,
        parentCommentId: parentId,
        body: body,
      );
    } catch (e) {
      AppLog.e('PrInlineComments', 'Failed to post reply: $e', e);
    }
  }

  /// Updates the body of a specific entry within a thread.
  void updateEntry({
    required String threadId,
    required String entryId,
    required String newBody,
  }) {
    final threads = [...state.threads];
    final i = threads.indexWhere((t) => t.id == threadId);
    if (i == -1) {
      return;
    }
    final t = threads[i];
    final entryIndex = t.entries.indexWhere((e) => e.id == entryId);
    if (entryIndex == -1) {
      return;
    }
    final old = t.entries[entryIndex];
    threads[i] = t.copyWith(
      entries: [...t.entries]
        ..[entryIndex] = PrInlineEntry(
          id: old.id,
          author: old.author,
          body: newBody,
          createdAt: old.createdAt,
        ),
    );
    state = state.copyWith(threads: threads);
  }

  /// Toggles the resolved state of a thread.
  void toggleResolved(String threadId) {
    _patchThread(threadId, (t) => t.copyWith(resolved: !t.resolved));
  }

  /// Accepts a suggestion: records an acceptance note and resolves the thread.
  /// The branch is not mutated (GitHub suggestions are comments, not patches);
  /// this is the local "applied & resolved" state.
  void acceptSuggestion(String threadId, {String? author}) {
    final t = byId(threadId);
    if (t == null) {
      return;
    }
    final counter = state.idCounter + 1;
    final identity = author == null
        ? _viewerIdentity()
        : (author: author, avatarUrl: null);
    final note = PrInlineEntry(
      id: 'entry-$counter',
      author: identity.author,
      authorAvatarUrl: identity.avatarUrl,
      body: 'Accepted this suggestion.',
    );
    final threads = [...state.threads];
    final i = threads.indexWhere((x) => x.id == threadId);
    if (i == -1) {
      return;
    }
    threads[i] = t.copyWith(entries: [...t.entries, note], resolved: true);
    state = state.copyWith(threads: threads, idCounter: counter);
  }

  /// Dismisses a thread, removing it from the local set. (Server-side comments
  /// are re-synthesised from the fetched list, so this hides drafts; dismissing
  /// a posted comment server-side is a separate, not-yet-wired operation.)
  void dismissThread(String threadId) {
    final threads = [...state.threads]..removeWhere((t) => t.id == threadId);
    if (threads.length != state.threads.length) {
      state = state.copyWith(threads: threads);
    }
  }

  void _patchThread(
    String id,
    PrInlineThread Function(PrInlineThread) mutator,
  ) {
    final threads = [...state.threads];
    final i = threads.indexWhere((t) => t.id == id);
    if (i == -1) {
      return;
    }
    threads[i] = mutator(threads[i]);
    state = state.copyWith(threads: threads);
  }
}

/// Provider for the inline comments controller, scoped by PR identity.
final prInlineCommentsControllerProvider =
    NotifierProvider.family<
      PrInlineCommentsController,
      PrInlineCommentsState,
      PrRef
    >(PrInlineCommentsController.new);

@immutable
/// Key used to subscribe to inline threads for a specific file within a PR.
/// Carries the full [PrRef] — the number alone is ambiguous across repos.
class PrFileThreadsKey {
  /// Creates a key for the given PR and file path.
  const PrFileThreadsKey({required this.pr, required this.filePath});

  /// The pull request the file belongs to.
  final PrRef pr;

  /// The file path within the PR.
  final String filePath;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrFileThreadsKey && other.pr == pr && other.filePath == filePath;

  @override
  int get hashCode => Object.hash(pr, filePath);
}

/// Per-file slice of [prInlineCommentsControllerProvider]. Cards subscribe to
/// just their file's threads so a draft added on file A doesn't rebuild file B.
final prFileInlineThreadsProvider = Provider.family
    .autoDispose<List<PrInlineThread>, PrFileThreadsKey>((ref, key) {
      return ref.watch(
        prInlineCommentsControllerProvider(
          key.pr,
        ).select((s) => s.threadsByPath[key.filePath] ?? const []),
      );
    });
