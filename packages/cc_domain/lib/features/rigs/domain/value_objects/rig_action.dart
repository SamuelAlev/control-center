import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';

/// A mouse button.
enum RigMouseButton {
  /// Primary button.
  left,

  /// Secondary button.
  right,

  /// Wheel button.
  middle;

  /// Stable wire string.
  String get wire => name;

  /// Parses [value], defaulting to [left] — the overwhelmingly common case,
  /// and a wrong-button click is recoverable in a way that a failed action is
  /// not.
  static RigMouseButton fromWire(String? value) {
    for (final b in RigMouseButton.values) {
      if (b.wire == value) {
        return b;
      }
    }
    return RigMouseButton.left;
  }
}

/// A scroll direction.
enum RigScrollDirection {
  /// Scroll up.
  up,

  /// Scroll down.
  down,

  /// Scroll left.
  left,

  /// Scroll right.
  right;

  /// Stable wire string.
  String get wire => name;

  /// Parses [value], or null when unknown.
  static RigScrollDirection? fromWire(String? value) {
    for (final d in RigScrollDirection.values) {
      if (d.wire == value) {
        return d;
      }
    }
    return null;
  }
}

/// One thing an actor (agent or human) does to a rig.
///
/// Abstract here, SEALED per surface (`ComputerAction`, `BrowserAction`,
/// `MobileAction` each seal their own family in their own file). That is where
/// exhaustiveness earns its keep: an adapter switches over one surface's
/// verbs and the compiler catches a missing case. A single sealed root would
/// have to live in one file with every verb of every surface, and a
/// cross-surface switch is not a thing any adapter wants to write.
///
/// A tap is not a click and a CSS selector is not a coordinate, so there is
/// deliberately no "do something" bag with optional fields — that shape pushes
/// validation into every adapter. The verb strings stay wire-compatible with
/// the vocabularies models already know (Anthropic computer use, CDP, ADB) so
/// a model's prior familiarity transfers.
abstract class RigAction {
  /// Const base constructor.
  const RigAction();

  /// The surface this action belongs to. An action never crosses surfaces.
  RigSurface get surface;

  /// The wire verb (what the model wrote, and what the audit log records).
  String get verb;

  /// Whether this action changes the guest.
  ///
  /// Screenshots and extractions do not: they are how an agent looks without
  /// touching. The distinction drives the audit log's noise level and lets a
  /// take-over hold block input without blocking observation — a human who has
  /// taken control still wants the agent's narration to keep working.
  bool get mutatesGuest => true;

  /// JSON form, as recorded in the action log and sent over RPC.
  Map<String, dynamic> toJson();

  /// A one-line human summary for the action feed ("Clicked (412, 180)").
  /// Sentence case, no trailing period.
  String get summary;
}

/// The outcome of parsing an untrusted action payload.
sealed class RigActionParse {
  /// Const base constructor.
  const RigActionParse();
}

/// A well-formed action.
class RigActionParsed extends RigActionParse {
  /// Creates a [RigActionParsed].
  const RigActionParsed(this.action);

  /// The parsed action.
  final RigAction action;
}

/// A malformed action, with the reason stated for the caller.
///
/// The message goes back to the model verbatim through the MCP error path, so
/// it names the offending field and what was expected — "Missing or invalid
/// argument: coordinate (expected [x, y])" teaches the next attempt; "invalid
/// arguments" does not.
class RigActionInvalid extends RigActionParse {
  /// Creates a [RigActionInvalid].
  const RigActionInvalid(this.message);

  /// Operator/model-facing explanation.
  final String message;
}

// ── Argument readers shared by the three surface parsers ──────────────────
//
// Every one is total: they answer "is this the type I need" and never throw,
// because the input is model-authored JSON and a `TypeError` three frames deep
// is a worse error message than a named field. Top-level rather than statics
// on a holder class, matching `domain_matcher.dart`'s `matchesAny`.

/// Reads an int from [args] at [key], or null when missing or not an int.
/// Accepts a double that is exactly integral (models emit `100.0` routinely)
/// and a numeric string.
int? rigOptInt(Map<String, dynamic> args, String key) => _rigAsInt(args[key]);

/// Reads a non-empty string from [args] at [key], or null.
String? rigOptString(Map<String, dynamic> args, String key) {
  final v = args[key];
  if (v is String && v.isNotEmpty) {
    return v;
  }
  return null;
}

/// Reads a bool from [args] at [key], or null. Accepts the strings `"true"`
/// and `"false"`, which models produce when a schema says boolean.
bool? rigOptBool(Map<String, dynamic> args, String key) {
  final v = args[key];
  if (v is bool) {
    return v;
  }
  if (v == 'true') {
    return true;
  }
  if (v == 'false') {
    return false;
  }
  return null;
}

/// Reads a `[x, y]` (or `{x, y}`) coordinate from [args] at [key], or null
/// when absent or malformed.
///
/// Coordinates are guest pixels in the guest's CURRENT display mode. There is
/// deliberately no normalized (0..1) form: the model sees a screenshot whose
/// pixel size it is told, and two coordinate spaces is one more than anyone
/// can keep straight.
(int, int)? rigOptPoint(Map<String, dynamic> args, String key) {
  final v = args[key];
  if (v is List && v.length == 2) {
    final x = _rigAsInt(v[0]);
    final y = _rigAsInt(v[1]);
    if (x != null && y != null) {
      return (x, y);
    }
  }
  if (v is Map) {
    final x = _rigAsInt(v['x']);
    final y = _rigAsInt(v['y']);
    if (x != null && y != null) {
      return (x, y);
    }
  }
  return null;
}

/// Reads a list of non-empty strings from [args] at [key]. A bare string is
/// read as a one-element list; anything else is empty.
List<String> rigStringList(Map<String, dynamic> args, String key) {
  final v = args[key];
  if (v is List) {
    return [
      for (final e in v)
        if (e is String && e.isNotEmpty) e,
    ];
  }
  if (v is String && v.isNotEmpty) {
    return [v];
  }
  return const [];
}

int? _rigAsInt(Object? v) {
  if (v is int) {
    return v;
  }
  if (v is double && v == v.roundToDouble()) {
    return v.round();
  }
  if (v is String) {
    return int.tryParse(v);
  }
  return null;
}
