import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_inline_thread.dart';
import 'package:control_center/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PrInlineCommentsState {
  PrInlineCommentsState({this.threads = const [], this.idCounter = 0})
      : threadsByPath = _groupByPath(threads);

  PrInlineCommentsState._({
    required this.threads,
    required this.idCounter,
    required this.threadsByPath,
  });

  final List<PrInlineThread> threads;
  final int idCounter;

  /// Threads grouped by file path so per-file consumers can subscribe via
  /// `select((s) => s.threadsByPath[path])` and avoid rebuilding when an
  /// unrelated file's threads change.
  final Map<String, List<PrInlineThread>> threadsByPath;

  PrInlineCommentsState copyWith({
    List<PrInlineThread>? threads,
    int? idCounter,
  }) =>
      PrInlineCommentsState._(
        threads: threads ?? this.threads,
        idCounter: idCounter ?? this.idCounter,
        threadsByPath:
            threads != null ? _groupByPath(threads) : threadsByPath,
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
class PrPostingContext {
  const PrPostingContext({
    required this.repository,
    required this.prNumber,
    required this.commitSha,
  });
  final PrReviewRepository repository;
  final int prNumber;
  final String commitSha;
}

class PrInlineCommentsController extends Notifier<PrInlineCommentsState> {
  PrInlineCommentsController(this.prNumber);
  final int prNumber;

  PrPostingContext? _context;

  @override
  PrInlineCommentsState build() {
    final repo = ref.watch(activeRepoProvider);
    final prAsync = ref.watch(prDetailProvider(prNumber));
    final pr = prAsync.value;

    if (repo != null &&
        pr != null &&
        repo.githubOwner.isNotEmpty &&
        repo.githubRepoName.isNotEmpty &&
        pr.headSha.isNotEmpty) {
      _context = PrPostingContext(
        repository: ref.watch(prReviewRepositoryProvider),
        prNumber: prNumber,
        commitSha: pr.headSha,
      );
    } else {
      _context = null;
    }

    return PrInlineCommentsState();
  }

  List<PrInlineThread> get threads => state.threads;

  List<PrInlineThread> forFile(String filePath) =>
      state.threadsByPath[filePath] ?? const <PrInlineThread>[];

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

  PrInlineThread? byId(String id) {
    for (final t in state.threads) {
      if (t.id == id) {
        return t;
      }
    }
    return null;
  }

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
    String author = 'You',
  }) {
    final c1 = state.idCounter + 1;
    final c2 = c1 + 1;
    final ctx = _context;
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
        PrInlineEntry(id: 'entry-$c2', author: author, body: authorBody),
      ],
      syncState: ctx == null
          ? PrInlineSyncState.local
          : PrInlineSyncState.pending,
    );
    state = state.copyWith(
      threads: [...state.threads, thread],
      idCounter: c2,
    );

    if (ctx != null) {
      _postThread(thread, authorBody);
    }
    return thread;
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

  void reply({
    required String threadId,
    required String body,
    String author = 'You',
  }) {
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
    final entry = PrInlineEntry(
      id: 'entry-$counter',
      author: author,
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
      entries: [...t.entries]..[entryIndex] = PrInlineEntry(
          id: old.id,
          author: old.author,
          body: newBody,
          createdAt: old.createdAt,
        ),
    );
    state = state.copyWith(threads: threads);
  }

  void toggleResolved(String threadId) {
    _patchThread(threadId, (t) => t.copyWith(resolved: !t.resolved));
  }

  /// Accepts a suggestion: records an acceptance note and resolves the thread.
  /// The branch is not mutated (GitHub suggestions are comments, not patches);
  /// this is the local "applied & resolved" state.
  void acceptSuggestion(String threadId, {String author = 'You'}) {
    final t = byId(threadId);
    if (t == null) {
      return;
    }
    final counter = state.idCounter + 1;
    final note = PrInlineEntry(
      id: 'entry-$counter',
      author: author,
      body: 'Accepted this suggestion.',
    );
    final threads = [...state.threads];
    final i = threads.indexWhere((x) => x.id == threadId);
    if (i == -1) {
      return;
    }
    threads[i] = t.copyWith(
      entries: [...t.entries, note],
      resolved: true,
    );
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

final prInlineCommentsControllerProvider =
    NotifierProvider.family<PrInlineCommentsController, PrInlineCommentsState, int>(
      PrInlineCommentsController.new,
    );

@immutable
class PrFileThreadsKey {
  const PrFileThreadsKey({required this.prNumber, required this.filePath});
  final int prNumber;
  final String filePath;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrFileThreadsKey &&
          other.prNumber == prNumber &&
          other.filePath == filePath;

  @override
  int get hashCode => Object.hash(prNumber, filePath);
}

/// Per-file slice of [prInlineCommentsControllerProvider]. Cards subscribe to
/// just their file's threads so a draft added on file A doesn't rebuild file B.
final prFileInlineThreadsProvider = Provider.family
    .autoDispose<List<PrInlineThread>, PrFileThreadsKey>((ref, key) {
  return ref.watch(
    prInlineCommentsControllerProvider(key.prNumber)
        .select((s) => s.threadsByPath[key.filePath] ?? const []),
  );
});

