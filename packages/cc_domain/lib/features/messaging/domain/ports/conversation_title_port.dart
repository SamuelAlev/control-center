/// Proposes a title for a conversation on the workspace's short-task runner,
/// without writing it. The rename dialog's "Generate" button; the human
/// decides whether the suggestion is kept. Also reports which conversations
/// the automatic titling pass is naming right now.
abstract interface class ConversationTitlePort {
  /// Suggests a title for [conversationId] in [workspaceId].
  ///
  /// Throws `NotFoundException` when the conversation is not in the
  /// workspace. Never renames anything.
  Future<ConversationTitleSuggestion> suggestTitle({
    required String workspaceId,
    required String conversationId,
  });

  /// The ids of [spaceId]'s conversations whose automatic title is being
  /// generated right now: the current set on listen, then every change.
  /// In-memory and transient — an empty set after a restart is correct.
  Stream<Set<String>> watchGenerating({
    required String workspaceId,
    required String spaceId,
  });
}

/// The outcome of [ConversationTitlePort.suggestTitle].
final class ConversationTitleSuggestion {
  /// Creates a [ConversationTitleSuggestion].
  const ConversationTitleSuggestion({
    this.title,
    this.unavailable = false,
    this.empty = false,
  });

  /// The proposed title, or null when none could be produced.
  final String? title;

  /// No short-task runner is configured, or it cannot run (adapter missing,
  /// no credential for its provider).
  final bool unavailable;

  /// The conversation has no human message to name it from yet.
  final bool empty;

  @override
  bool operator ==(Object other) =>
      other is ConversationTitleSuggestion &&
      other.title == title &&
      other.unavailable == unavailable &&
      other.empty == empty;

  @override
  int get hashCode => Object.hash(title, unavailable, empty);
}
