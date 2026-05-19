import 'package:cc_domain/features/pr_review/domain/entities/reaction_group.dart';

/// PrInlineSyncState.
enum PrInlineSyncState {
  /// Local.
  local,

  /// Queued for the next review submission — written, deliberately not sent.
  ///
  /// Distinct from [local] (which is "we could not post it") : this one is a
  /// choice. The comment goes out with the verdict so the author reads one
  /// review instead of being notified per comment.
  pendingReview,

  /// Pending.
  pending,

  /// Synced.
  synced,

  /// Error.
  error,
}

/// Pr inline thread kind.
enum PrInlineThreadKind {
  /// Comment.
  comment,

  /// Suggestion.
  suggestion,
}

/// Pr inline entry.
class PrInlineEntry {
  /// Creates an inline comment entry.
  PrInlineEntry({
    required this.id,
    required this.author,
    required this.body,
    this.authorAvatarUrl,
    DateTime? createdAt,
    this.serverCommentId,
    this.reactions = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  /// Identifier.
  final String id;

  /// Author.
  final String author;

  /// Optional avatar URL for [author]. When non-null the GitHub avatar
  /// component renders the real image instead of the login's initial.
  final String? authorAvatarUrl;

  /// Body.
  final String body;

  /// When created.
  final DateTime createdAt;

  /// GitHub review-comment id once this entry is synced (null while local).
  final int? serverCommentId;

  /// Reactions on the synced review comment (empty for local entries).
  final List<ReactionGroup> reactions;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrInlineEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          author == other.author &&
          body == other.body;

  @override
  int get hashCode => Object.hash(id, author, body);

  @override
  String toString() => 'PrInlineEntry($id, $author)';

  /// copyWith.
  PrInlineEntry copyWith({
    String? id,
    String? author,
    String? body,
    String? authorAvatarUrl,
    DateTime? createdAt,
    int? serverCommentId,
    List<ReactionGroup>? reactions,
  }) {
    return PrInlineEntry(
      id: id ?? this.id,
      author: author ?? this.author,
      body: body ?? this.body,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      createdAt: createdAt ?? this.createdAt,
      serverCommentId: serverCommentId ?? this.serverCommentId,
      reactions: reactions ?? this.reactions,
    );
  }
}

/// PrInlineThread.
class PrInlineThread {
  /// Creates an inline comment/suggestion thread.
  PrInlineThread({
    required this.id,
    required this.filePath,
    required this.line,
    required this.side,
    required this.kind,
    required this.originalCode,
    required this.suggestedCode,
    required this.entries,
    int? lineEnd,
    this.startCol,
    this.endCol,
    this.resolved = false,
    this.syncState = PrInlineSyncState.local,
    this.serverId,
    this.threadId,
    this.syncError,
  }) : lineEnd = lineEnd ?? line;

  /// Identifier.
  final String id;

  /// filePath.
  final String filePath;

  /// line.
  final int line;

  /// lineEnd.
  final int lineEnd;

  /// First display column of the anchored range on [line] (tabs expanded), or
  /// null for a whole-line anchor. Local-only — GitHub anchors by line, so this
  /// is used purely to draw a character-precise highlight.
  final int? startCol;

  /// Last display column of the anchored range on [lineEnd] (exclusive), or
  /// null for a whole-line anchor.
  final int? endCol;

  /// side.
  final String side;

  /// kind.
  final PrInlineThreadKind kind;

  /// originalCode.
  final String originalCode;

  /// suggestedCode.
  final String suggestedCode;

  /// entries.
  final List<PrInlineEntry> entries;

  /// Whether resolved.
  final bool resolved;

  /// syncState.
  final PrInlineSyncState syncState;

  /// GitHub review-comment id once the thread is posted (null while local).
  final int? serverId;

  /// The forge's *thread* id (distinct from [serverId], which is a comment id).
  /// Non-null only for a synthesised server thread on a forge that models
  /// resolvable conversations — it is what a resolve writes to.
  final String? threadId;

  /// Last sync error message, when [syncState] is `error`.
  final String? syncError;

  /// isMultiLine.
  bool get isMultiLine => lineEnd > line;

  /// Whether this thread is queued for the next review submission.
  bool get isPendingReview => syncState == PrInlineSyncState.pendingReview;

  /// isSuggestion.
  bool get isSuggestion => kind == PrInlineThreadKind.suggestion;

  /// Whether the anchor covers only part of a single line.
  bool get hasCharRange => startCol != null && endCol != null && !isMultiLine;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrInlineThread &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          filePath == other.filePath &&
          line == other.line &&
          lineEnd == other.lineEnd &&
          startCol == other.startCol &&
          endCol == other.endCol &&
          side == other.side &&
          kind == other.kind &&
          originalCode == other.originalCode &&
          suggestedCode == other.suggestedCode &&
          resolved == other.resolved &&
          syncState == other.syncState &&
          serverId == other.serverId &&
          threadId == other.threadId &&
          syncError == other.syncError;

  @override
  int get hashCode => Object.hash(
    id,
    filePath,
    line,
    lineEnd,
    startCol,
    endCol,
    side,
    kind,
    originalCode,
    suggestedCode,
    resolved,
    syncState,
    serverId,
    threadId,
    syncError,
  );

  /// copyWith.
  PrInlineThread copyWith({
    String? id,
    String? filePath,
    int? line,
    int? lineEnd,
    int? startCol,
    int? endCol,
    String? side,
    PrInlineThreadKind? kind,
    String? originalCode,
    String? suggestedCode,
    List<PrInlineEntry>? entries,
    bool? resolved,
    PrInlineSyncState? syncState,
    int? serverId,
    bool removeServerId = false,
    String? threadId,
    String? syncError,
    bool removeSyncError = false,
  }) {
    return PrInlineThread(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      line: line ?? this.line,
      lineEnd: lineEnd ?? this.lineEnd,
      startCol: startCol ?? this.startCol,
      endCol: endCol ?? this.endCol,
      side: side ?? this.side,
      kind: kind ?? this.kind,
      originalCode: originalCode ?? this.originalCode,
      suggestedCode: suggestedCode ?? this.suggestedCode,
      entries: entries ?? this.entries,
      resolved: resolved ?? this.resolved,
      syncState: syncState ?? this.syncState,
      serverId: removeServerId ? null : (serverId ?? this.serverId),
      threadId: threadId ?? this.threadId,
      syncError: removeSyncError ? null : (syncError ?? this.syncError),
    );
  }

  @override
  String toString() => 'PrInlineThread($filePath:$line, ${kind.name})';
}
