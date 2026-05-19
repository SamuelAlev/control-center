import 'package:cc_harness/tools.dart' show ActionClass;

/// What an action is about to DO, in the vocabulary policy can constrain:
/// which paths it touches, which refs it writes, which hosts it reaches, how
/// big it is.
///
/// Verb-level classes alone are a capability gate, not authorization —
/// "this agent may push" is a different claim from "this agent may push
/// `feature/*` to `origin`" (*Capability Gates Are Not Authorization*, arXiv
/// 2606.28679). Every chokepoint already had these arguments in hand and
/// threw them away before consulting policy; this is the type that carries
/// them there.
///
/// A tool that declares no extractor produces an EMPTY request, and a
/// constrained rule simply does not match one — so an undeclared extractor
/// degrades to the unconstrained rule that was already in force, never to a
/// silent allow.
class ActionRequest {
  /// Creates an [ActionRequest].
  const ActionRequest({
    this.classes = const {},
    this.command,
    this.paths = const [],
    this.refs = const [],
    this.hosts = const [],
    this.magnitude,
    this.cents,
  });

  /// An action with no describable arguments (the conservative default).
  static const ActionRequest empty = ActionRequest();

  /// The effect classes this action performs.
  final Set<ActionClass> classes;

  /// The shell command, for `processSpawn` actions.
  final String? command;

  /// Filesystem paths the action reads or writes (absolute, symlink-resolved
  /// by the caller — a constraint that matched an unresolved path would be
  /// bypassable with `..`).
  final List<String> paths;

  /// Git refs the action writes (`refs/heads/main`, `feature/x`).
  final List<String> refs;

  /// Network hosts the action reaches.
  final List<String> hosts;

  /// A countable magnitude (files touched, rows deleted) for ceiling rules.
  final int? magnitude;

  /// A monetary magnitude in cents, for budget ceilings.
  final int? cents;

  /// Whether this request carries anything a constraint could match.
  bool get isEmpty =>
      command == null &&
      paths.isEmpty &&
      refs.isEmpty &&
      hosts.isEmpty &&
      magnitude == null &&
      cents == null;

  /// A copy with [classes] replaced (chokepoints extract arguments once and
  /// re-tag them per gated tool).
  ActionRequest withClasses(Set<ActionClass> classes) => ActionRequest(
    classes: classes,
    command: command,
    paths: paths,
    refs: refs,
    hosts: hosts,
    magnitude: magnitude,
    cents: cents,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionRequest &&
          other.command == command &&
          other.magnitude == magnitude &&
          other.cents == cents &&
          _sameList(other.paths, paths) &&
          _sameList(other.refs, refs) &&
          _sameList(other.hosts, hosts) &&
          other.classes.length == classes.length &&
          other.classes.every(classes.contains);

  static bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    command,
    magnitude,
    cents,
    Object.hashAll(paths),
    Object.hashAll(refs),
    Object.hashAll(hosts),
    Object.hashAllUnordered(classes),
  );

  /// The redacted shape hashed into the audit trail: WHAT was authorized,
  /// without the argument values that may carry secrets. Paths and hosts are
  /// included (they are the authorization-relevant part and are not secret);
  /// the command is included because a policy decision about a command that
  /// does not name the command is unauditable.
  Map<String, Object?> toDigestPayload() => {
    'classes': [for (final c in classes) c.wire]..sort(),
    'command': command,
    'paths': paths,
    'refs': refs,
    'hosts': hosts,
    'magnitude': magnitude,
    'cents': cents,
  };
}
