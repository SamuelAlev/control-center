import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';

/// Runs several advisors over the same turn and surfaces the most serious note.
///
/// **Why a panel rather than one reviewer with a longer prompt.** The review
/// questions people actually care about are different in KIND — does this
/// couple modules that should not touch, does it leak a credential, does it
/// actually pass its own tests. One advisor asked all three answers about
/// whichever it noticed first, and the other two questions silently go
/// unasked. Separate advisors each have one job, and often want different
/// models: the architecture reviewer is worth a strong model, the "did you run
/// the tests" reviewer is not.
///
/// **Only one note per turn reaches the agent.** A panel that injects three
/// notes per turn does not produce three times the course correction; it
/// produces an agent that stops reading advisories. The most severe note wins,
/// ties break on roster order (so the first-declared advisor is the senior
/// one), and the rest are dropped for this turn — a real concern raised by two
/// reviewers is still one concern.
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
