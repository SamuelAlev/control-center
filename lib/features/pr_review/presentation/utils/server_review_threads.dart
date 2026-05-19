import 'package:cc_domain/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_inline_thread.dart';
import 'package:cc_domain/features/pr_review/domain/services/diff_parser.dart';

/// One forge-side review conversation: a root comment plus its replies, oldest
/// first.
///
/// The forge does not hand conversations over as a unit — it returns a flat
/// comment list where a reply carries `in_reply_to_id` pointing at the ROOT of
/// its thread (not its immediate parent). Reassembling that is the only way to
/// show a discussion as a discussion, and it is needed identically by the diff
/// (where a thread hangs off its anchor line) and by the conversation timeline
/// (where it hangs off the review that started it).
class ServerReviewThread {
  /// Creates a [ServerReviewThread] from [comments], which must be non-empty
  /// and ordered oldest first.
  ServerReviewThread(this.comments) {
    // Thrown rather than asserted: an `assert` is stripped in release, so the
    // check would not run at all in the shipped binary and `root` would throw
    // a bare StateError on an empty list instead.
    if (comments.isEmpty) {
      throw ArgumentError.value(
        comments,
        'comments',
        'a conversation has at least a root',
      );
    }
  }

  /// The conversation's comments, oldest first. The first is the root.
  final List<PrCodeReviewComment> comments;

  /// The root comment — the one that carries the anchor, the range, the
  /// diff hunk and the conversation's resolved state.
  PrCodeReviewComment get root => comments.first;

  /// Stable synthesised id, matching the diff's thread ids so per-thread UI
  /// state (collapsed, focused) is the same object on both surfaces.
  String get id => 'server-${root.id}';

  /// File the conversation is on.
  String get path => root.path;

  /// The forge's thread id, or null when the forge models no resolvable
  /// thread (or the state could not be read).
  String? get threadId => root.threadId;

  /// Whether the conversation is resolved on the forge.
  bool get isResolved => root.isResolved;

  /// Whether the diff line this was left on is gone.
  ///
  /// An outdated conversation cannot be anchored to a row, so the diff can
  /// only show it in a side panel — the timeline is where it can still be read
  /// in full.
  bool get isOutdated => root.anchorLine == null;

  /// Last line of the anchored range (where a forge shows the card), or null
  /// when outdated.
  int? get endLine => root.anchorLine;

  /// First line of the anchored range, or null when outdated.
  int? get startLine => root.anchorStartLine;

  /// Whether the anchor spans more than one line.
  bool get isMultiLine =>
      startLine != null && endLine != null && startLine != endLine;

  /// The id of the review this conversation was STARTED with, or null.
  ///
  /// Read off the root deliberately: replies are submitted with their own
  /// (later) review, so keying a conversation by any other comment would
  /// scatter one discussion across several timeline entries.
  int? get reviewId => root.reviewId;
}

/// Groups a flat forge comment list into conversations, oldest first within
/// each and ordered by their root's creation time.
///
/// A comment whose `in_reply_to_id` names a comment that is not in [comments]
/// (a parent outside the fetched page) is promoted to a root of its own rather
/// than dropped — losing a reply is worse than showing it detached.
List<ServerReviewThread> groupServerReviewThreads(
  Iterable<PrCodeReviewComment> comments,
) {
  final byId = <int, PrCodeReviewComment>{for (final c in comments) c.id: c};
  final roots = <int, List<PrCodeReviewComment>>{};
  final rootOrder = <int>[];

  int rootIdOf(PrCodeReviewComment c) {
    final parent = c.inReplyToId;
    if (parent == null || !byId.containsKey(parent)) {
      return c.id;
    }
    return parent;
  }

  final sorted = [...comments]..sort(_byCreatedThenId);
  for (final c in sorted) {
    final rootId = rootIdOf(c);
    final bucket = roots.putIfAbsent(rootId, () {
      rootOrder.add(rootId);
      return <PrCodeReviewComment>[];
    });
    bucket.add(c);
  }

  final out = <ServerReviewThread>[];
  for (final rootId in rootOrder) {
    final bucket = roots[rootId]!..sort(_byCreatedThenId);
    out.add(ServerReviewThread(bucket));
  }
  return out..sort((a, b) => _byCreatedThenId(a.root, b.root));
}

int _byCreatedThenId(PrCodeReviewComment a, PrCodeReviewComment b) {
  final ad = a.createdAt;
  final bd = b.createdAt;
  if (ad != null && bd != null && ad != bd) {
    return ad.compareTo(bd);
  }
  return a.id.compareTo(b.id);
}

/// Maps forge comments to the entries the inline-comment widgets render.
///
/// Shared so the diff and the timeline cannot drift into two different
/// renderings of the same conversation.
List<PrInlineEntry> inlineEntriesFromServerComments(
  List<PrCodeReviewComment> comments, {
  required String unknownAuthorLabel,
}) => [
  for (final c in comments)
    PrInlineEntry(
      id: 'server-entry-${c.id}',
      author: c.user?.login ?? unknownAuthorLabel,
      authorAvatarUrl: c.user?.avatarUrl,
      body: c.body,
      createdAt: c.createdAt,
      serverCommentId: c.id,
      reactions: c.reactions,
    ),
];

/// Builds the [PrInlineThread] the comment widgets render for [thread].
///
/// [originalCode] is the source the conversation is about. The diff supplies it
/// off the rendered rows; everywhere else it is derived from the forge's own
/// `diff_hunk`, which is what the comment was written against and the only copy
/// that survives the line being changed. Without it a ```suggestion fence has
/// nothing to diff AGAINST and renders as a header over an empty box — which is
/// exactly what a suggestion looked like outside the diff.
///
/// The kind is always `comment`, even for a suggestion body: the renderer
/// detects the fence and draws the mini-diff either way, while `suggestion`
/// would surface the local accept/dismiss/edit actions, none of which can act
/// on a forge-owned comment.
PrInlineThread inlineThreadFromServerThread(
  ServerReviewThread thread, {
  required String unknownAuthorLabel,
  required bool resolved,
  int? line,
  int? lineEnd,
  String? originalCode,
}) => PrInlineThread(
  id: thread.id,
  filePath: thread.path,
  line: line ?? thread.startLine ?? thread.endLine ?? 0,
  lineEnd: lineEnd ?? thread.endLine ?? line ?? thread.startLine ?? 0,
  side: thread.root.side,
  kind: PrInlineThreadKind.comment,
  originalCode: originalCode ?? originalCodeForServerThread(thread),
  suggestedCode: '',
  serverId: thread.root.id,
  threadId: thread.threadId,
  resolved: resolved,
  syncState: PrInlineSyncState.synced,
  entries: inlineEntriesFromServerComments(
    thread.comments,
    unknownAuthorLabel: unknownAuthorLabel,
  ),
);

/// The source lines [thread] is anchored to, read out of the forge's own
/// `diff_hunk`.
///
/// The hunk is the snapshot the comment was written against, so it still holds
/// the code even when the line has since changed — which is the only reason an
/// outdated conversation's suggestion can be rendered at all. Empty when the
/// conversation has no anchor (nothing to diff against) or no hunk.
String originalCodeForServerThread(ServerReviewThread thread) {
  final end = thread.endLine;
  if (end == null || thread.root.diffHunk.isEmpty) {
    return '';
  }
  return originalCodeFromDiffHunk(
    thread.root.diffHunk,
    thread.root.side,
    thread.startLine ?? end,
    end,
  );
}

/// A reply posted with a LATER review than the conversation it belongs to.
///
/// The timeline entry for that later review would otherwise be empty — the
/// person "reviewed" and said something, but the words live in a conversation
/// anchored under an earlier entry. Surfacing the reply there, with a way back
/// to the discussion, is the difference between a bare "reviewed · 3 hours ago"
/// row and knowing what they said.
class ServerReviewReply {
  /// Creates a [ServerReviewReply].
  const ServerReviewReply({required this.thread, required this.comment});

  /// The conversation the reply belongs to.
  final ServerReviewThread thread;

  /// The reply itself.
  final PrCodeReviewComment comment;
}

/// Replies grouped by the review they were submitted with, skipping each
/// conversation's own root review (whose entry already renders the whole
/// thread) and anything with no review id.
Map<int, List<ServerReviewReply>> serverReviewRepliesByReview(
  List<ServerReviewThread> threads,
) {
  final out = <int, List<ServerReviewReply>>{};
  for (final thread in threads) {
    for (final comment in thread.comments.skip(1)) {
      final reviewId = comment.reviewId;
      if (reviewId == null || reviewId == thread.reviewId) {
        continue;
      }
      out
          .putIfAbsent(reviewId, () => <ServerReviewReply>[])
          .add(ServerReviewReply(thread: thread, comment: comment));
    }
  }
  return out;
}
