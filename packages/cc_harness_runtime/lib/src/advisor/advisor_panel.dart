import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';

/// Runs several advisors on one turn; only the most severe note reaches the
/// agent (ties: roster order). Separate advisors keep distinct jobs/models.
class AdvisorPanel implements Advisor {
  /// Creates an [AdvisorPanel] over [members], in precedence order.
  AdvisorPanel(this.members);

  /// The advisors, in the order they were declared.
  final List<Advisor> members;

  @override
  Future<AdvisorNote?> review(List<HarnessMessage> history) async {
    if (members.isEmpty) {
      return null;
    }
    // Reviewed concurrently: they are independent, and running them in
    // sequence would put N model round-trips on the turn boundary the primary
    // agent is waiting at.
    final notes = await Future.wait(
      members.map((m) async {
        try {
          return await m.review(history);
        } on Object {
          // A failing advisor costs its own note, never the run.
          return null;
        }
      }),
    );

    AdvisorNote? best;
    for (final note in notes) {
      if (note == null) {
        continue;
      }
      // Strictly greater, so an equal severity leaves the earlier (more
      // senior) advisor's note in place.
      if (best == null || note.severity.rank > best.severity.rank) {
        best = note;
      }
    }
    return best;
  }

  @override
  void reset() {
    for (final member in members) {
      try {
        member.reset();
      } on Object {
        // Reset is best-effort; a member that cannot re-prime just repeats
        // itself once.
      }
    }
  }
}
