import 'package:cc_domain/core/domain/value_objects/wake_context.dart';

/// What a goal adds to a run's per-turn prompt: the goal block of a segment,
/// or the reviewer's prompt of a review run, and the wake items it renders
/// itself (a failed verification's notice in place of its wake's generic
/// line). Never part of the cached prefix.
class GoalTurnText {
  /// Creates the text. Throws [ArgumentError] for an empty [section].
  GoalTurnText({
    required this.section,
    Map<String, String> wakeItems = const {},
  }) : wakeItems = Map.unmodifiable(wakeItems) {
    if (section.trim().isEmpty) {
      throw ArgumentError.value(section, 'section', 'must not be empty');
    }
  }

  /// The section's body, rendered with the run's nonce.
  final String section;

  /// Delivered wake id to the item that replaces its generic line in "Why
  /// you were woken".
  final Map<String, String> wakeItems;

  @override
  bool operator ==(Object other) =>
      other is GoalTurnText &&
      section == other.section &&
      wakeItems.length == other.wakeItems.length &&
      wakeItems.entries.every((e) => other.wakeItems[e.key] == e.value);

  @override
  int get hashCode => Object.hash(
    section,
    Object.hashAllUnordered([
      for (final e in wakeItems.entries) Object.hash(e.key, e.value),
    ]),
  );
}

/// Resolves the goal text of a run the wake queue started, from the goal's
/// row: the segment's goal block (with the verification notice when the run
/// delivers a failed verification), or the reviewer's prompt for a
/// `goalReview` run. Null for a run that is neither.
abstract interface class GoalTurnTextPort {
  /// The goal text for the run of [agentId] in [conversationId] that
  /// delivers [wakeContext]'s wakes. [hasRepl]: the run has the `repl` tool,
  /// which picks how the text names the tools it points at.
  Future<GoalTurnText?> forRun({
    required String workspaceId,
    required String agentId,
    required String? conversationId,
    required WakeContext wakeContext,
    required bool hasRepl,
  });
}
