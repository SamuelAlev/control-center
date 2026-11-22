import 'package:cc_domain/features/dispatch/domain/services/wake_admission.dart';

/// The rules of a park at a provider's usage limit (plan section 11): a run
/// that ended because every account it could use is spent waits for the
/// reset the provider reported, as a durable `limitReset` wake, instead of
/// failing.
///
/// Pure values only, shared by every place that parks (a goal segment, a
/// rule's run, a person's run, the credential park before a run starts) and
/// by the wake frame that tells the resumed run why it woke.
// ignore: avoid_classes_with_only_static_members
abstract final class LimitPark {
  /// How long after the reported reset the wake is due: the provider's
  /// clock and ours differ by a little, and a run started on the reset's
  /// second would find the limit still in force.
  static const Duration resetSlack = Duration(seconds: 30);

  /// The latest reset honoured. A reset further away is treated as no
  /// reset: the run fails as it would without one.
  static const Duration maxWait = Duration(days: 7);

  /// How often one goal may park. The park after the last one pauses the
  /// goal for a person's review ([goalHoldDetail]).
  static const int maxGoalParks = 8;

  /// The goal's `holdDetail` when it parked [maxGoalParks] times and hit
  /// the limit again.
  static const String goalHoldDetail = 'limit_parks';

  /// The `stateReason` of the held wake of a person's run: the person
  /// resumes it (`wakes.release`) or drops it (`wakes.cancel`).
  static const String heldReason = WakeStateReasons.limit;

  /// The `kind` of the system row a person's park posts in the
  /// conversation (see [rowKeys]).
  static const String rowKind = 'limit_park';

  /// The metadata keys of the system row a person's park posts, for the
  /// clients that render "Resumes at 14:30" with Resume and Cancel:
  /// `kind` ([rowKind]), `wakeId` (the held wake), `runId` (the run that
  /// hit the limit), `agentId`, `provider` (a display label), `resetsAt`
  /// (the provider's reset, ISO 8601 UTC), `resumesAt` (the wake's
  /// `notBefore`, ISO 8601 UTC) and `requestedByUserId` (the only person
  /// who may Resume; anyone with access to the space may Cancel).
  static const List<String> rowKeys = [
    'kind',
    'wakeId',
    'runId',
    'agentId',
    'provider',
    'resetsAt',
    'resumesAt',
    'requestedByUserId',
  ];

  /// How the park ended, recorded once on the person's row when its wake
  /// settles: [outcomeResumed], [outcomeCancelled], [outcomeExpired] or
  /// [outcomeSkipped].
  static const String rowOutcomeKey = 'outcome';

  /// When the wake settled (ISO 8601 UTC), beside [rowOutcomeKey].
  static const String rowSettledAtKey = 'settledAt';

  /// The skip's kind (the wake's settle reason), with [outcomeSkipped].
  static const String rowSkipKindKey = 'skipKind';

  /// The wake was delivered: the work resumed.
  static const String outcomeResumed = 'resumed';

  /// The wake was cancelled (its person, or a stop).
  static const String outcomeCancelled = 'cancelled';

  /// The wake expired unrun.
  static const String outcomeExpired = 'expired';

  /// The wake was skipped ([rowSkipKindKey] says why).
  static const String outcomeSkipped = 'skipped';

  /// The wake's dedup key for the run [runId]: one park per run, whichever
  /// path writes it first (the run's settlement or the credential park).
  static String dedupKey(String runId) => 'limit:$runId';

  /// The reset to wait for, or null when there is none to honour: absent,
  /// or more than [maxWait] after [now]. A reset already past is honoured
  /// as [now] (the wake is due after [resetSlack]).
  static DateTime? honouredReset(DateTime? resetsAt, DateTime now) {
    if (resetsAt == null) {
      return null;
    }
    final reset = resetsAt.toUtc();
    final at = now.toUtc();
    if (reset.isAfter(at.add(maxWait))) {
      return null;
    }
    return reset.isBefore(at) ? at : reset;
  }

  /// When the wake for [reset] is due.
  static DateTime resumeAt(DateTime reset) => reset.toUtc().add(resetSlack);

  /// How long after its reset a person's pause waits for their Resume
  /// before it expires (its cards then go back to their writers).
  static const Duration personParkLifetime = Duration(days: 7);

  /// When a person's pause for [reset] expires.
  static DateTime personParkExpiresAt(DateTime reset) =>
      reset.toUtc().add(personParkLifetime);

  /// The `detail.fields` every `limitReset` wake carries (the frame's
  /// `[limit-reset]` headline reads them): `provider`, `resetsAt` and
  /// `resumesAt` (ISO 8601 UTC), under the `WakeFields` names.
  static Map<String, Object?> wakeFields({
    required String provider,
    required DateTime reset,
  }) => {
    'provider': provider,
    'resetsAt': reset.toUtc().toIso8601String(),
    'resumesAt': resumeAt(reset).toIso8601String(),
  };

  /// [at] as `YYYY-MM-DD HH:MM UTC`, for the conversation's messages.
  static String stamp(DateTime at) {
    final u = at.toUtc();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${u.year}-${two(u.month)}-${two(u.day)} '
        '${two(u.hour)}:${two(u.minute)} UTC';
  }

  /// A display label for the provider whose limit was reached, from the
  /// run's adapter and model: the model's `provider/` prefix when it has
  /// one, `anthropic` for Claude Code, else the adapter's id. Never empty.
  static String providerLabel({String? adapter, String? modelId}) {
    final model = modelId?.trim() ?? '';
    final slash = model.indexOf('/');
    if (slash > 0) {
      return model.substring(0, slash);
    }
    final id = adapter?.trim() ?? '';
    if (id == 'claude-code' || id == 'claude') {
      return 'anthropic';
    }
    return id.isEmpty ? 'provider' : id;
  }
}
