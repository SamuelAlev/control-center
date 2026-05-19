import 'package:cc_domain/features/orchestration/domain/entities/orchestration_proposal.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/playbook.dart';

/// Result of instantiating a playbook.
class PlaybookInstantiation {
  /// Creates a result.
  const PlaybookInstantiation({this.proposal, this.errors = const []});

  /// The substituted proposal (null when [errors] is non-empty).
  final OrchestrationProposal? proposal;

  /// Validation/substitution errors, verbatim for the caller.
  final List<String> errors;

  /// Whether instantiation succeeded.
  bool get isValid => proposal != null && errors.isEmpty;
}

/// Pure `{{param}}` substitution over a playbook's stored proposal
/// (PRD 17 §10, clarifications: "typed and dumb").
///
/// Substitution walks every string value of the proposal JSON — titles,
/// descriptions, prompts, the goal — replacing `{{name}}` placeholders.
/// Required params must be supplied (or carry a default); enum params must
/// match a declared choice; any placeholder left unresolved after
/// substitution is an error, never silently shipped. The caller re-runs
/// `OrchestrationProposalValidator` on the result before anything opens in
/// the Studio.
class PlaybookInstantiator {
  const PlaybookInstantiator._();

  /// Matches `{{name}}` placeholders.
  static final RegExp placeholderPattern = RegExp(r'\{\{([A-Za-z0-9_]+)\}\}');

  /// Instantiates [playbook] with [args].
  static PlaybookInstantiation instantiate(
    Playbook playbook,
    Map<String, String> args,
  ) {
    final errors = <String>[];
    final resolved = <String, String>{};
    for (final param in playbook.params) {
      final supplied = args[param.name];
      final value = supplied ?? param.defaultValue;
      if (value == null || value.isEmpty) {
        if (param.required) {
          errors.add('Missing required parameter: ${param.name}.');
        }
        continue;
      }
      if (param.type == PlaybookParamType.enumeration &&
          param.choices.isNotEmpty &&
          !param.choices.contains(value)) {
        errors.add(
          'Parameter ${param.name} must be one of: '
          '${param.choices.join(', ')} (got "$value").',
        );
        continue;
      }
      resolved[param.name] = value;
    }
    for (final name in args.keys) {
      if (!playbook.params.any((p) => p.name == name)) {
        errors.add('Unknown parameter: $name.');
      }
    }
    if (errors.isNotEmpty) {
      return PlaybookInstantiation(errors: errors);
    }

    final substituted = _substitute(playbook.sourceProposal.toJson(), resolved);

    final unresolved = <String>{};
    _collectUnresolved(substituted, unresolved);
    if (unresolved.isNotEmpty) {
      return PlaybookInstantiation(
        errors: [
          for (final name in unresolved)
            'Unresolved placeholder {{$name}} — declare it as a parameter or remove it from the playbook.',
        ],
      );
    }

    return PlaybookInstantiation(
      proposal: OrchestrationProposal.fromJson(
        substituted as Map<String, dynamic>,
      ),
    );
  }

  /// Deep-walks decoded JSON, substituting placeholders in every string
  /// value. Non-string values (ints, bools) pass through untouched, so
  /// budget numbers cannot be corrupted by substitution.
  static dynamic _substitute(dynamic value, Map<String, String> args) {
    if (value is String) {
      return value.replaceAllMapped(
        placeholderPattern,
        (m) => args[m.group(1)] ?? m.group(0)!,
      );
    }
    if (value is Map) {
      return <String, dynamic>{
        for (final e in value.entries)
          e.key as String: _substitute(e.value, args),
      };
    }
    if (value is List) {
      return [for (final v in value) _substitute(v, args)];
    }
    return value;
  }

  static void _collectUnresolved(dynamic value, Set<String> out) {
    if (value is String) {
      for (final m in placeholderPattern.allMatches(value)) {
        out.add(m.group(1)!);
      }
    } else if (value is Map) {
      for (final v in value.values) {
        _collectUnresolved(v, out);
      }
    } else if (value is List) {
      for (final v in value) {
        _collectUnresolved(v, out);
      }
    }
  }

  /// Every placeholder name referenced anywhere in [proposal] — used by the
  /// save-as-playbook flow to pre-populate the parameter list.
  static Set<String> placeholdersIn(OrchestrationProposal proposal) {
    final out = <String>{};
    _collectUnresolved(proposal.toJson(), out);
    return out;
  }
}
