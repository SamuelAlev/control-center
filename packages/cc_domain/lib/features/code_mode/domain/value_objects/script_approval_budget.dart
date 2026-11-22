import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';

/// What one script may still ask of a person for approval.
///
/// A script can make hundreds of calls in one `repl` call and catch every
/// refusal, so without a bound one script could put card after card in front
/// of a person, and a declined card would not slow it down. Two rules hold
/// for every call of one script that would need a person, on every surface
/// that runs scripts:
///
/// - at most [CodeModeLimits.maxApprovalAsks] of its calls reach a person;
/// - once a person declined one of its calls, its later calls that would
///   need a person are refused without asking.
///
/// Only a person's answer is a decision. A card nobody answered (its
/// deadline passed, it was withdrawn or expired, the host shut down) refuses
/// its own call and nothing else: it still counts as one of the script's
/// asks, and the script's next call that needs a person asks again.
///
/// A refusal is a denial the script can read ([refusal]), audited as a
/// denial nobody was asked about. Calls policy allows or denies on its own
/// never touch the budget. One instance per execution (a `repl` call). A
/// direct call has none.
final class ScriptApprovalBudget {
  /// Creates the budget of one execution, with nothing asked yet.
  ScriptApprovalBudget();

  int _asked = 0;
  bool _declined = false;

  /// The reason when a person declined one of the script's calls.
  static const String declinedReason =
      'A person already declined a call from this script; calls that need '
      'approval are refused for the rest of it.';

  /// The reason when the script used up its asks.
  static const String exhaustedReason =
      'This script has asked for approval ${CodeModeLimits.maxApprovalAsks} '
      'times (CodeModeLimits.maxApprovalAsks), its limit; calls that need '
      'approval are refused for the rest of it. Return what you have and let '
      'the model ask directly.';

  /// How many of the script's calls reached a person so far.
  int get asked => _asked;

  /// Whether a person declined one of the script's calls.
  bool get declined => _declined;

  /// Null while the script may still ask a person; otherwise why a call that
  /// would need a person is refused without asking.
  String? get refusal {
    if (_declined) {
      return declinedReason;
    }
    if (_asked >= CodeModeLimits.maxApprovalAsks) {
      return exhaustedReason;
    }
    return null;
  }

  /// Records that a person is being asked about one of the script's calls.
  /// A gate calls it once per card, in the same synchronous step as its
  /// check of [refusal] and before it awaits anything: calls that arrive
  /// together then cannot all pass a check none of them has counted against
  /// yet.
  void asking() => _asked++;

  /// Gives back an ask counted by [asking] for a card that never went up:
  /// the policy answered on its own, a standing approval covered the call,
  /// or the space's autonomy dial refused it first.
  void release() {
    if (_asked > 0) {
      _asked--;
    }
  }

  /// Records how a card about one of the script's calls came down: a
  /// person's answer ([approved]), or, when [unanswered], no answer at all
  /// (`ConfirmationRequest.onUnanswered` fired: a deadline, a withdrawal,
  /// an expiry, a shutdown). Only a person's decline refuses the script's
  /// later calls; an unanswered card leaves the budget as it was (its ask
  /// stays counted). An unanswered card never approves anything: the gate
  /// refuses its call either way.
  void answered({required bool approved, required bool unanswered}) {
    if (!approved && !unanswered) {
      _declined = true;
    }
  }
}
