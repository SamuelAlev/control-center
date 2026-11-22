import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/wake_context.dart';

/// Every number that bounds a wake rule, in one place (plan section 9,
/// "Limits"). The three counts and the default cost cap are a workspace's to
/// change ([WakeRuleLimits], stored under [wakeRuleLimitsSettingKey]); the
/// rest are fixed.
abstract final class WakeRuleBounds {
  /// An agent's rule ends this long after it is created unless it says
  /// otherwise.
  static const Duration agentDefaultExpiry = Duration(days: 7);

  /// The longest an agent's rule may live (also the farthest a person may
  /// extend one).
  static const Duration agentMaxExpiry = Duration(days: 30);

  /// A person's rule ends this long after it is created unless they say
  /// otherwise.
  static const Duration personDefaultExpiry = Duration(days: 30);

  /// The longest a person's rule may live.
  static const Duration personMaxExpiry = Duration(days: 365);

  /// The run cap of an agent's repeating rule that names none.
  static const int agentDefaultMaxRuns = 50;

  /// The highest run cap any rule may carry.
  static const int maxRunsCeiling = 500;

  /// The run cap of a watch that names none.
  static const int watchDefaultMaxRuns = 10;

  /// How late a one-off may still fire; past it the rule ends `expired`.
  static const Duration oneOffGrace = Duration(hours: 24);

  /// The most a repeating rule's slot may be late and still fire (the grace
  /// is the smaller of this and half the gap to the next slot).
  static const Duration repeatingGraceCeiling = Duration(minutes: 10);

  /// A watch writes its wake this long after the last matching event...
  static const Duration watchQuiet = Duration(seconds: 30);

  /// ...and never later than this after the first.
  static const Duration watchMaxDelay = Duration(minutes: 5);

  /// What one run a rule starts may cost at most, in micro-dollars (5 USD,
  /// a run's default cap), and never more than what the rule has left.
  static const int perRunCostCapMicros = 5000000;

  /// The runs a lineage (rules made by runs other rules' wakes started) may
  /// have in all when its root sets no run cap.
  static const int lineageMaxRuns = 50;
}

/// The workspace setting that holds a workspace's [WakeRuleLimits].
const String wakeRuleLimitsSettingKey = 'wake_rule_limits';

/// A workspace's caps on wake rules: how many active or paused rules an agent
/// may hold in one conversation, in the workspace, and the workspace in all;
/// the cost cap a rule gets when it names none; and the time zone a `cron:`
/// rule is read in when it names none (the workspace's zone; there is no
/// other workspace zone setting). Changed by a workspace
/// admin (`wakeRules.setLimits`); stored as JSON under
/// [wakeRuleLimitsSettingKey]:
///
/// ```json
/// {"per_conversation": 10, "per_agent": 50, "per_workspace": 500,
///  "cost_cap_micros": 50000000, "default_time_zone": "UTC"}
/// ```
class WakeRuleLimits {
  /// Creates limits. Throws [ArgumentError] for a value outside its range.
  WakeRuleLimits({
    this.perConversation = defaultPerConversation,
    this.perAgent = defaultPerAgent,
    this.perWorkspace = defaultPerWorkspace,
    this.costCapMicros = defaultCostCapMicros,
    this.defaultTimeZone = 'UTC',
  }) {
    _check('perConversation', perConversation, 1, maxPerConversation);
    _check('perAgent', perAgent, 1, maxPerAgent);
    _check('perWorkspace', perWorkspace, 1, maxPerWorkspace);
    _check('costCapMicros', costCapMicros, 1, maxCostCapMicros);
    if (defaultTimeZone.trim().isEmpty || defaultTimeZone.length > 64) {
      throw ArgumentError.value(
        defaultTimeZone,
        'defaultTimeZone',
        'must be an IANA zone name',
      );
    }
  }

  /// Reads a stored or sent JSON object: a missing key keeps its default.
  /// Throws [ArgumentError] (or [FormatException]) for a value that is not a
  /// whole number in range.
  factory WakeRuleLimits.fromJson(Map<String, Object?> json) {
    int read(String key, int fallback) => switch (json[key]) {
      null => fallback,
      final int v => v,
      final num v when v == v.roundToDouble() => v.toInt(),
      final other => throw FormatException(
        '$key must be a whole number',
        other,
      ),
    };
    return WakeRuleLimits(
      perConversation: read('per_conversation', defaultPerConversation),
      perAgent: read('per_agent', defaultPerAgent),
      perWorkspace: read('per_workspace', defaultPerWorkspace),
      costCapMicros: read('cost_cap_micros', defaultCostCapMicros),
      defaultTimeZone: switch (json['default_time_zone']) {
        null => 'UTC',
        final String zone => zone.trim(),
        final other => throw FormatException(
          'default_time_zone must be a zone name',
          other,
        ),
      },
    );
  }

  /// Reads the stored setting text; null, empty or unreadable text (a
  /// hand-edited row) is the defaults.
  static WakeRuleLimits fromSetting(String? stored) {
    if (stored == null || stored.trim().isEmpty) {
      return defaults;
    }
    try {
      final decoded = jsonDecode(stored);
      if (decoded is Map<String, Object?>) {
        return WakeRuleLimits.fromJson(decoded);
      }
    } on Object {
      // An unreadable row keeps the defaults rather than lifting the caps.
    }
    return defaults;
  }

  /// The defaults.
  static final WakeRuleLimits defaults = WakeRuleLimits();

  /// Rules one agent may hold in one conversation, by default.
  static const int defaultPerConversation = 10;

  /// Rules one agent may hold in the workspace, by default.
  static const int defaultPerAgent = 50;

  /// Rules the workspace may hold, by default.
  static const int defaultPerWorkspace = 500;

  /// A rule's cost cap when it names none: 50 USD.
  static const int defaultCostCapMicros = 50000000;

  /// The highest [perConversation] an admin may set.
  static const int maxPerConversation = 100;

  /// The highest [perAgent] an admin may set.
  static const int maxPerAgent = 1000;

  /// The highest [perWorkspace] an admin may set.
  static const int maxPerWorkspace = 10000;

  /// The highest [costCapMicros] an admin may set: 10,000 USD.
  static const int maxCostCapMicros = 10000000000;

  /// Rules one agent may hold in one conversation.
  final int perConversation;

  /// Rules one agent may hold in the workspace.
  final int perAgent;

  /// Rules the workspace may hold.
  final int perWorkspace;

  /// A rule's cost cap when it names none, in micro-dollars.
  final int costCapMicros;

  /// The IANA zone a `cron:` rule is read in when it names none. Whether the
  /// zone exists is checked where it is set (the zone database is the
  /// server's).
  final String defaultTimeZone;

  static void _check(String name, int value, int min, int max) {
    if (value < min || value > max) {
      throw ArgumentError.value(value, name, 'must be $min to $max');
    }
  }

  /// The stored JSON object.
  Map<String, Object> toJson() => {
    'per_conversation': perConversation,
    'per_agent': perAgent,
    'per_workspace': perWorkspace,
    'cost_cap_micros': costCapMicros,
    'default_time_zone': defaultTimeZone,
  };

  @override
  bool operator ==(Object other) =>
      other is WakeRuleLimits &&
      perConversation == other.perConversation &&
      perAgent == other.perAgent &&
      perWorkspace == other.perWorkspace &&
      costCapMicros == other.costCapMicros &&
      defaultTimeZone == other.defaultTimeZone;

  @override
  int get hashCode => Object.hash(
    perConversation,
    perAgent,
    perWorkspace,
    costCapMicros,
    defaultTimeZone,
  );

  @override
  String toString() =>
      'WakeRuleLimits(conversation $perConversation, agent $perAgent, '
      'workspace $perWorkspace, cost $costCapMicros, zone $defaultTimeZone)';
}

/// The `data.kind` of each refusal a wake rule's creation or change can
/// carry: the clients localize by these, and a tool's result carries them in
/// its structured part.
abstract final class WakeRuleRefusals {
  /// An `every:` under 60 seconds.
  static const String intervalTooShort = 'wake_interval_too_short';

  /// An `in:` or `at:` (or a `/schedule` time) under 60 seconds ahead: a
  /// one-off has the floor an `every:` has.
  static const String tooSoon = 'wake_too_soon';

  /// A rule made by a run that a rule's wake started, when the chain it
  /// belongs to has used its runs, its cost or its time: only a person may
  /// start a new chain (or raise the first rule's limits).
  static const String lineageEnded = 'wake_lineage_ended';

  /// A pull request watch whose target no poll reaches (a repository the
  /// space does not expose, one with no forge remote, or one the server
  /// cannot read now): it could never fire.
  static const String watchTargetUnreadable = 'watch_target_unreadable';

  /// An agent's repeating rule with neither `max_runs` nor `expires_in`.
  static const String expiryRequired = 'wake_expiry_required';

  /// A count cap ([WakeRuleLimits]) is reached.
  static const String limitReached = 'wake_limit_reached';

  /// A `when` that does not parse or can never fire.
  static const String invalidWhen = 'wake_invalid_when';

  /// A note over 4,000 characters.
  static const String noteTooLong = 'wake_note_too_long';

  /// An expiry (or a one-off's time) beyond the most the rule's maker may
  /// set.
  static const String expiryTooLong = 'wake_expiry_too_long';

  /// A run cap or a cost cap out of range.
  static const String limitOutOfRange = 'wake_limit_out_of_range';

  /// `next` outside a run a self-paced rule started, or a delay out of range.
  static const String nextOutsideLoop = 'wake_next_outside_loop';

  /// A watch whose target the rule's agent or person may not see.
  static const String watchRefused = 'wake_watch_refused';

  /// A change to a rule that has ended.
  static const String ruleEnded = 'wake_rule_ended';

  /// A change only the rule's own person may make (resume, a note, raised
  /// limits: the rule runs with their sign-in), or one only an admin may
  /// make to a bot's rule. The same kind the wake operations give.
  static const String notYours = 'wake_not_yours';
}

/// Whether a run started only by wakes of [reasons] finishes quietly: a
/// schedule's or a watch's run that ends cleanly notifies no one unless it
/// mentions them. The one place this is decided.
bool wakeRunIsQuiet(Iterable<WakeReason> reasons) =>
    reasons.isNotEmpty &&
    reasons.every((r) => r == WakeReason.schedule || r == WakeReason.watch);
