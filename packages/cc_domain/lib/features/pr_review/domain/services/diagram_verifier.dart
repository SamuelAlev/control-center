// Pure diagram verification (PRD 18 §3). A generated diagram is a VIEW OF
// VERIFIED EDGES, not prose with arrows: every sequence message / state
// transition is cross-checked against the real code-graph edge set. An edge
// the graph doesn't know is FLAGGED (rendered dashed + "unverified") or, in
// strict mode, DROPPED. ER diagrams describe schema, so they pass through.
//
// The server builds [corroboratedEdgeKeys] from actual code edges using the
// SAME [edgeKey] canonicalization, so this stays a pure, testable function.

import 'package:cc_domain/features/pr_review/domain/value_objects/review_diagram.dart';

/// Verifies diagram edges against the code graph.
class DiagramVerifier {
  /// Creates a [DiagramVerifier].
  const DiagramVerifier();

  /// Canonical edge key used on both sides of the check (case/space
  /// insensitive `from→to`).
  static String edgeKey(String from, String to) =>
      '${from.trim().toLowerCase()}→${to.trim().toLowerCase()}';

  /// Returns a copy of [diagram] with each edge's `corroborated` flag set from
  /// [corroboratedEdgeKeys]. When [dropUncorroborated] is true, uncorroborated
  /// edges are removed entirely instead of flagged.
  ReviewDiagram verify(
    ReviewDiagram diagram,
    Set<String> corroboratedEdgeKeys, {
    bool dropUncorroborated = false,
  }) {
    switch (diagram) {
      case SequenceDiagram():
        final messages = <SequenceMessage>[];
        for (final m in diagram.messages) {
          final ok = corroboratedEdgeKeys.contains(edgeKey(m.from, m.to));
          if (!ok && dropUncorroborated) {
            continue;
          }
          messages.add(m.withCorroboration(value: ok));
        }
        return SequenceDiagram(
          title: diagram.title,
          participants: diagram.participants,
          messages: messages,
        );
      case StateMachineDiagram():
        final transitions = <StateTransition>[];
        for (final t in diagram.transitions) {
          final ok = corroboratedEdgeKeys.contains(edgeKey(t.from, t.to));
          if (!ok && dropUncorroborated) {
            continue;
          }
          transitions.add(t.withCorroboration(value: ok));
        }
        return StateMachineDiagram(
          title: diagram.title,
          states: diagram.states,
          transitions: transitions,
          initialState: diagram.initialState,
        );
      case EntityRelationDiagram():
        // Schema diagrams are not call edges; nothing to corroborate.
        return diagram;
    }
  }
}
