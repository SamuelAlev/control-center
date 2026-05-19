import 'dart:convert';

import 'package:cc_domain/features/guardrails/domain/value_objects/action_request.dart';

/// How a constraint relates to the request being judged.
///
/// Tri-state, not boolean, and that is the whole point. A rule that names a
/// facet the request cannot supply ("deny pushes to main" against a push whose
/// ref nobody extracted) is neither a hit nor a miss — it is UNEVALUABLE, and
/// the only safe answer to an unevaluable safety rule is to ask a human. A
/// boolean here silently picks a side: `false` makes every protected-branch
/// rule inert, `true` denies every push whose ref is not yet extracted.
enum ConstraintMatch {
  /// The request is provably within the constraint.
  hit,

  /// The request carries nothing for a facet the constraint names, so it can
  /// be neither confirmed nor excluded.
  unknown,

  /// The request is provably outside the constraint.
  miss,
}

/// The argument-level condition on a policy rule: which paths, refs and hosts
/// it covers, and what magnitude it tolerates.
///
/// Deliberately a CLOSED, typed, loop-free grammar rather than a general
/// expression language. Three properties fall out of that and all three are
/// the point:
///
///  * every rule can be rendered as a sentence in the UI ("push to anything
///    except `main`"), so an operator can read their own policy back;
///  * a denial can name the constraint that matched, so it is explainable;
///  * the whole policy can be statically enumerated — you can show a customer
///    what an agent may do BEFORE it runs, which is what an unbounded DSL
///    gives up.
///
/// Patterns are glob-ish, matched case-sensitively:
///  * `*` matches within a segment, `**` across segments (paths only);
///  * a leading `!` NEGATES an entry — `refs: ['**', '!main']` reads as "any
///    ref except main". Negations are checked first and win.
///  * a bare `*.example.com` host entry matches subdomains, `example.com`
///    matches exactly.
///
/// A null/absent facet means "this constraint says nothing about that", so it
/// matches. That is what keeps a rule with NO constraint (the pre-constraint
/// shape of every stored row) matching every request exactly as before.
class ActionConstraint {
  /// Creates an [ActionConstraint].
  const ActionConstraint({
    this.paths,
    this.refs,
    this.hosts,
    this.commands,
    this.maxCount,
    this.maxCents,
  });

  /// The always-matching constraint (equivalent to no constraint at all).
  static const ActionConstraint any = ActionConstraint();

  /// Path patterns this rule covers.
  final List<String>? paths;

  /// Git ref patterns this rule covers.
  final List<String>? refs;

  /// Host patterns this rule covers.
  final List<String>? hosts;

  /// Command prefixes this rule covers (`git push`, `rm -rf`).
  final List<String>? commands;

  /// The largest countable magnitude this rule tolerates; a request above it
  /// does not match (so a more restrictive rule decides).
  final int? maxCount;

  /// The largest monetary magnitude in cents this rule tolerates.
  final int? maxCents;

  /// Whether this constraint says nothing at all.
  bool get isUnconstrained =>
      paths == null &&
      refs == null &&
      hosts == null &&
      commands == null &&
      maxCount == null &&
      maxCents == null;

  /// Whether [request] falls within this constraint, for a PERMISSIVE rule.
  ///
  /// Kept boolean because an allow only ever applies when the request is
  /// provably inside it: unknown and outside are both "does not apply".
  bool matches(ActionRequest request) =>
      evaluate(request, restrictive: false) == ConstraintMatch.hit;

  /// Evaluates this constraint against [request].
  ///
  /// [restrictive] selects the semantics, and the two are genuinely different
  /// questions:
  ///
  /// * A **restrictive** rule (deny / prompt) asks "does this request touch
  ///   anything I forbid?" — so ANY covered value is a hit. Requiring every
  ///   value to match would let an agent launder a forbidden path by batching
  ///   an innocent one alongside it.
  /// * A **permissive** rule (allow) asks "is this request entirely within
  ///   what I permit?" — so EVERY value must be covered, and anything it
  ///   cannot prove is a miss.
  ///
  /// A facet the request says nothing about is unknown for a restrictive
  /// rule (the caller escalates) and a miss for a permissive one (an allow
  /// never applies on faith).
  ConstraintMatch evaluate(
    ActionRequest request, {
    required bool restrictive,
  }) {
    if (isUnconstrained) {
      return ConstraintMatch.hit;
    }
    final facets = <ConstraintMatch>[
      if (paths != null)
        _listFacet(
          request.paths,
          paths!,
          restrictive,
          (v, p) => _matchesOne(v, p, segmented: true),
        ),
      if (refs != null)
        _listFacet(request.refs, refs!, restrictive, _matchesRef),
      if (hosts != null)
        _listFacet(request.hosts, hosts!, restrictive, _matchesHost),
      if (commands != null)
        if (request.command == null || request.command!.isEmpty)
          ConstraintMatch.unknown
        else if (_matchesCommand(request.command!, commands!))
          ConstraintMatch.hit
        else
          ConstraintMatch.miss,
      if (maxCount != null)
        _ceilingFacet(request.magnitude, maxCount!, restrictive),
      if (maxCents != null)
        _ceilingFacet(request.cents, maxCents!, restrictive),
    ];

    if (restrictive) {
      // ANY forbidden thing present is enough to apply the rule; otherwise an
      // unevaluable facet makes the whole rule unevaluable, which the caller
      // escalates rather than guessing.
      if (facets.contains(ConstraintMatch.hit)) {
        return ConstraintMatch.hit;
      }
      return facets.contains(ConstraintMatch.unknown)
          ? ConstraintMatch.unknown
          : ConstraintMatch.miss;
    }
    // A permissive rule applies only when EVERY facet is provably satisfied.
    return facets.every((f) => f == ConstraintMatch.hit)
        ? ConstraintMatch.hit
        : ConstraintMatch.miss;
  }

  /// Ref matching is plain (non-segmented) globbing.
  static bool _matchesRef(String value, List<String> patterns) =>
      _matchesOne(value, patterns);

  /// One list-valued facet. Restrictive rules hit on ANY covered value;
  /// permissive rules need EVERY value covered. No values at all is unknown:
  /// nothing has been proven either way.
  static ConstraintMatch _listFacet(
    List<String> values,
    List<String> patterns,
    bool restrictive,
    bool Function(String value, List<String> patterns) test,
  ) {
    if (values.isEmpty) {
      return ConstraintMatch.unknown;
    }
    final hits = values.where((v) => test(v, patterns)).length;
    if (restrictive) {
      return hits > 0 ? ConstraintMatch.hit : ConstraintMatch.miss;
    }
    return hits == values.length ? ConstraintMatch.hit : ConstraintMatch.miss;
  }

  /// A ceiling reads differently either way round: on an allow it is "up to
  /// this much"; on a deny it is "anything above this much".
  static ConstraintMatch _ceilingFacet(int? value, int ceiling, bool restrictive) {
    if (value == null) {
      return ConstraintMatch.unknown;
    }
    if (restrictive) {
      return value > ceiling ? ConstraintMatch.hit : ConstraintMatch.miss;
    }
    return value <= ceiling ? ConstraintMatch.hit : ConstraintMatch.miss;
  }

  static bool _matchesOne(
    String value,
    List<String> patterns, {
    bool segmented = false,
  }) {
    var allowed = false;
    for (final pattern in patterns) {
      if (pattern.startsWith('!')) {
        // Negations win outright — "everything except main" must not be
        // satisfiable by also listing a pattern that matches main.
        if (_glob(value, pattern.substring(1), segmented: segmented)) {
          return false;
        }
      } else if (_glob(value, pattern, segmented: segmented)) {
        allowed = true;
      }
    }
    // A list of only negations reads as "anything but these".
    final onlyNegations = patterns.every((p) => p.startsWith('!'));
    return allowed || onlyNegations;
  }

  /// Whether one host is covered by [patterns]. `*.example.com` matches the
  /// apex and any subdomain (never `evilexample.com` — the leading dot is
  /// kept in the suffix test); a leading `!` excludes.
  static bool _matchesHost(String host, List<String> patterns) {
    var allowed = false;
    for (final pattern in patterns) {
      final isNegation = pattern.startsWith('!');
      final raw = isNegation ? pattern.substring(1) : pattern;
      final hit = raw.startsWith('*.')
          ? host == raw.substring(2) || host.endsWith(raw.substring(1))
          : host == raw;
      if (hit) {
        if (isNegation) {
          return false;
        }
        allowed = true;
      }
    }
    return allowed || patterns.every((p) => p.startsWith('!'));
  }

  static bool _matchesCommand(String command, List<String> prefixes) {
    var allowed = false;
    for (final prefix in prefixes) {
      final isNegation = prefix.startsWith('!');
      final raw = isNegation ? prefix.substring(1) : prefix;
      // Prefix match on a WORD boundary: `git pushx` must not match a rule
      // about `git push` (the same rule the command-policy net uses).
      final hit = command == raw || command.startsWith('$raw ');
      if (hit) {
        if (isNegation) {
          return false;
        }
        allowed = true;
      }
    }
    return allowed || prefixes.every((p) => p.startsWith('!'));
  }

  /// Glob matcher. `*` stops at `/` when [segmented]; `**` always crosses.
  static bool _glob(String value, String pattern, {bool segmented = false}) {
    final buffer = StringBuffer('^');
    var i = 0;
    while (i < pattern.length) {
      final c = pattern[i];
      if (c == '*') {
        final isDouble = i + 1 < pattern.length && pattern[i + 1] == '*';
        if (isDouble) {
          buffer.write('.*');
          i += 2;
          // `**/` should also match zero directories.
          if (i < pattern.length && pattern[i] == '/') {
            i++;
            buffer.write('(?:/)?');
          }
          continue;
        }
        buffer.write(segmented ? '[^/]*' : '.*');
        i++;
        continue;
      }
      if (c == '?') {
        buffer.write(segmented ? '[^/]' : '.');
        i++;
        continue;
      }
      buffer.write(RegExp.escape(c));
      i++;
    }
    buffer.write(r'$');
    return RegExp(buffer.toString()).hasMatch(value);
  }

  /// A human-readable one-liner for the UI and the audit row.
  String describe() {
    if (isUnconstrained) {
      return 'any';
    }
    final parts = <String>[
      if (paths != null) 'paths=${paths!.join(",")}',
      if (refs != null) 'refs=${refs!.join(",")}',
      if (hosts != null) 'hosts=${hosts!.join(",")}',
      if (commands != null) 'commands=${commands!.join(",")}',
      if (maxCount != null) 'maxCount=$maxCount',
      if (maxCents != null) 'maxCents=$maxCents',
    ];
    return parts.join(' ');
  }

  /// The stored JSON shape.
  Map<String, Object?> toJson() => {
    if (paths != null) 'paths': paths,
    if (refs != null) 'refs': refs,
    if (hosts != null) 'hosts': hosts,
    if (commands != null) 'commands': commands,
    if (maxCount != null) 'maxCount': maxCount,
    if (maxCents != null) 'maxCents': maxCents,
  };

  /// Parses the stored JSON shape; null for a malformed or absent value —
  /// which reads as "no constraint", i.e. the rule matches everything, which
  /// is the pre-constraint meaning of every existing row.
  static ActionConstraint? fromJson(Map<String, dynamic> json) {
    List<String>? strings(Object? raw) => raw is List
        ? [for (final e in raw) e.toString()]
        : null;
    int? number(Object? raw) => raw is int
        ? raw
        : raw is num
        ? raw.toInt()
        : null;
    final c = ActionConstraint(
      paths: strings(json['paths']),
      refs: strings(json['refs']),
      hosts: strings(json['hosts']),
      commands: strings(json['commands']),
      maxCount: number(json['maxCount']),
      maxCents: number(json['maxCents']),
    );
    return c.isUnconstrained ? null : c;
  }

  /// Parses the stored column value.
  static ActionConstraint? decode(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? fromJson(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  /// Encodes for storage.
  String encode() => jsonEncode(toJson());

  // Value equality over the canonical encoding: the facets are lists whose
  // ORDER is meaningful to nobody but whose contents decide the rule, and
  // comparing the encoded form gets both right without a bespoke list walk.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionConstraint && other.encode() == encode();

  @override
  int get hashCode => encode().hashCode;
}
