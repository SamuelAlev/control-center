import 'package:flutter/widgets.dart';

/// How urgently an attention item wants the operator, and thus its sort
/// priority. The strict inclusion rule (PRD 19 §7 adversarial review) means
/// everything here *blocks* something or *explicitly requests* the operator —
/// so [info] is the floor, never a passive notification.
enum InboxAttentionSeverity {
  /// Blocks progress (an agent is stuck, a merge is gated, a sync failed).
  blocking,

  /// Needs attention soon but nothing is halted.
  warning,

  /// A standing request that isn't halting work.
  info,
}

/// One non-PR item awaiting the operator in the inbox's pinned attention
/// strip (a blocked agent, a failed sync), with its single most-likely next
/// action attached (PRD 19 §7).
@immutable
class InboxAttentionItem {
  /// Creates an [InboxAttentionItem].
  const InboxAttentionItem({
    required this.id,
    required this.severity,
    required this.title,
    required this.icon,
    required this.actionLabel,
    required this.onAction,
    this.subtitle,
    this.waitingSince,
  });

  /// Stable identity (source-prefixed, e.g. `agent-approval:<id>`).
  final String id;

  /// How urgently it wants the operator.
  final InboxAttentionSeverity severity;

  /// Primary line ("Agent architect is asking to run a command").
  final String title;

  /// Optional secondary line (detail / context).
  final String? subtitle;

  /// Leading icon.
  final IconData icon;

  /// The single most-likely next action's label ("Review", "Retry", "Open").
  final String actionLabel;

  /// Runs the next action (navigate, open a sheet, retry).
  final VoidCallback onAction;

  /// When the item started waiting — drives the oldest-first tiebreak so the
  /// longest-blocked item floats to the top.
  final DateTime? waitingSince;

  @override
  bool operator ==(Object other) =>
      other is InboxAttentionItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Sort priority for a severity (higher = more urgent).
int _severityRank(InboxAttentionSeverity s) => switch (s) {
  InboxAttentionSeverity.blocking => 2,
  InboxAttentionSeverity.warning => 1,
  InboxAttentionSeverity.info => 0,
};

/// Orders items for the attention strip: most-urgent severity first, then the
/// item that has been waiting longest, then title for a stable order. Pure —
/// the sort is the unit-tested core of the strip.
List<InboxAttentionItem> sortInboxAttentionItems(
  List<InboxAttentionItem> items,
) {
  final sorted = [...items];
  sorted.sort((a, b) {
    final sev = _severityRank(b.severity).compareTo(_severityRank(a.severity));
    if (sev != 0) {
      return sev;
    }
    final aw = a.waitingSince;
    final bw = b.waitingSince;
    if (aw != null && bw != null && aw != bw) {
      return aw.compareTo(bw); // oldest first
    }
    if (aw == null && bw != null) {
      return 1;
    }
    if (aw != null && bw == null) {
      return -1;
    }
    return a.title.compareTo(b.title);
  });
  return sorted;
}
