import 'package:control_center/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:control_center/features/pipelines/domain/entities/step_kind.dart';
import 'package:control_center/features/pipelines/domain/services/state_reducer.dart';
import 'package:control_center/features/pipelines/domain/services/template_renderer.dart';

/// Severity of a [PipelineIssue].
enum PipelineIssueSeverity {
  /// Blocks saving / running the pipeline.
  error,

  /// Surfaced to the author but does not block (e.g. a key that might come
  /// from the trigger payload at runtime).
  warning,
}

/// A single problem found by [PipelineValidator].
class PipelineIssue {
  /// Creates a [PipelineIssue].
  const PipelineIssue({
    required this.severity,
    required this.message,
    this.stepId,
  });

  /// How serious the issue is.
  final PipelineIssueSeverity severity;

  /// Human-readable description (raw — the UI re-phrases / localizes).
  final String message;

  /// The step the issue relates to, if any.
  final String? stepId;

  /// Whether this issue blocks save/run.
  bool get isError => severity == PipelineIssueSeverity.error;
}

/// Thrown by the repository when a non-built-in pipeline fails validation.
class PipelineValidationException implements Exception {
  /// Creates a [PipelineValidationException].
  PipelineValidationException(this.issues);

  /// The blocking issues (all [PipelineIssueSeverity.error]).
  final List<PipelineIssue> issues;

  @override
  String toString() =>
      'PipelineValidationException: ${issues.map((i) => i.message).join('; ')}';
}

/// Statically validates a [PipelineDefinition]'s data-flow wiring at author
/// time, so a typo'd `inputKeys`/`{{key}}`, an orphan output, an unreachable
/// terminal, or a dangling router branch surfaces as an error in the editor
/// instead of as a silent empty string at runtime.
class PipelineValidator {
  /// Creates a [PipelineValidator].
  const PipelineValidator({
    this.renderer = const TemplateRenderer(),
    this.reducers = const StateReducer(),
  });

  /// Used to extract `{{key}}` references from prompts/scripts.
  final TemplateRenderer renderer;

  /// Used to validate declared reducer names.
  final StateReducer reducers;

  /// Returns all issues (errors + warnings). Empty means the definition is
  /// structurally sound.
  List<PipelineIssue> validate(PipelineDefinition def) {
    final issues = <PipelineIssue>[];

    // ── Structural: exactly one trigger (the entry node), ≥1 terminal ───
    final triggers =
        def.steps.where((s) => s.kind == StepKind.trigger).toList();
    if (triggers.isEmpty) {
      issues.add(const PipelineIssue(
        severity: PipelineIssueSeverity.error,
        message: 'Pipeline has no trigger step; every pipeline must start with '
            'a trigger.',
      ));
    } else if (triggers.length > 1) {
      issues.add(PipelineIssue(
        severity: PipelineIssueSeverity.error,
        message: 'Pipeline has ${triggers.length} trigger steps; exactly one '
            'is allowed.',
      ));
    } else if (triggers.single.triggers.isNotEmpty) {
      // The trigger is the entry node: nothing may feed into it.
      issues.add(PipelineIssue(
        severity: PipelineIssueSeverity.error,
        stepId: triggers.single.id,
        message: 'Trigger "${triggers.single.id}" is the entry node and cannot '
            'have upstream steps.',
      ));
    }
    final terminals =
        def.steps.where((s) => s.kind == StepKind.terminal).toList();
    if (terminals.isEmpty) {
      issues.add(const PipelineIssue(
        severity: PipelineIssueSeverity.error,
        message: 'Pipeline has no terminal step, so it can never complete.',
      ));
    }

    // ── Duplicate step ids ──────────────────────────────────────────────
    final seen = <String>{};
    for (final s in def.steps) {
      if (!seen.add(s.id)) {
        issues.add(PipelineIssue(
          severity: PipelineIssueSeverity.error,
          stepId: s.id,
          message: 'Duplicate step id "${s.id}".',
        ));
      }
    }

    // ── Edges reference real steps ──────────────────────────────────────
    final ids = def.steps.map((s) => s.id).toSet();
    for (final s in def.steps) {
      for (final t in s.triggers) {
        for (final src in t.sourceStepIds) {
          if (!ids.contains(src)) {
            issues.add(PipelineIssue(
              severity: PipelineIssueSeverity.error,
              stepId: s.id,
              message: 'Step "${s.id}" lists upstream "$src" which does not '
                  'exist.',
            ));
          } else if (t.routeKey != null) {
            final source = def.step(src);
            if (source != null && source.kind != StepKind.router) {
              issues.add(PipelineIssue(
                severity: PipelineIssueSeverity.error,
                stepId: s.id,
                message: 'Step "${s.id}" has a routed edge from "$src", but '
                    '"$src" is not a router.',
              ));
            }
          }
        }
      }
      for (final w in s.waitForStepIds) {
        if (!ids.contains(w)) {
          issues.add(PipelineIssue(
            severity: PipelineIssueSeverity.error,
            stepId: s.id,
            message: 'Join "${s.id}" waits on "$w" which does not exist.',
          ));
        }
      }
    }

    // ── Routers must have at least one routed outgoing edge ─────────────
    for (final r in def.steps.where((s) => s.kind == StepKind.router)) {
      final hasRoutedEdge = def.steps.any((s) =>
          s.triggers.any((t) =>
              t.routeKey != null && t.sourceStepIds.contains(r.id)));
      if (!hasRoutedEdge) {
        issues.add(PipelineIssue(
          severity: PipelineIssueSeverity.error,
          stepId: r.id,
          message: 'Router "${r.id}" has no routed outgoing edges; downstream '
              'steps need a route key.',
        ));
      }
      // Condition predicate sanity (file-existence / boolean-group routers).
      final predicate = r.config.extras['predicate'];
      if (predicate is Map) {
        for (final msg in _predicateIssues(predicate.cast<String, dynamic>())) {
          issues.add(PipelineIssue(
            severity: PipelineIssueSeverity.error,
            stepId: r.id,
            message: 'Router "${r.id}" $msg',
          ));
        }
      } else {
        // Switch-mode sanity: a switch with neither cases nor a default can
        // never select a branch and fails on every run.
        final switchKey = r.config.extras['switchKey'];
        if (switchKey is String && switchKey.isNotEmpty) {
          final cases = (r.config.extras['cases'] as List?)
                  ?.whereType<String>()
                  .where((c) => c.trim().isNotEmpty)
                  .toList() ??
              const [];
          final fallback = r.config.extras['default'] as String?;
          final hasDefault = fallback != null && fallback.trim().isNotEmpty;
          if (cases.isEmpty && !hasDefault) {
            issues.add(PipelineIssue(
              severity: PipelineIssueSeverity.error,
              stepId: r.id,
              message: 'Router "${r.id}" is a switch with no cases and no '
                  'default; it can never select a branch.',
            ));
          }
        }
      }
    }

    // ── Data-flow: every consumed key is produced upstream ──────────────
    // Map of state key -> producing step ids.
    final producedBy = <String, List<String>>{};
    for (final s in def.steps) {
      final key = s.config.outputKey;
      if (key != null && key.isNotEmpty) {
        producedBy.putIfAbsent(key, () => []).add(s.id);
      }
    }

    // Duplicate producers without a reducer lose data on merge.
    for (final entry in producedBy.entries) {
      if (entry.value.length > 1) {
        final anyReducer = def.steps
            .where((s) => entry.value.contains(s.id))
            .any((s) => (s.config.reducer ?? '').isNotEmpty &&
                s.config.reducer != 'override');
        if (!anyReducer) {
          issues.add(PipelineIssue(
            severity: PipelineIssueSeverity.warning,
            message: 'Output key "${entry.key}" is written by '
                '${entry.value.length} steps (${entry.value.join(', ')}) '
                'without a reducer; writes will overwrite each other.',
          ));
        }
      }
    }

    // Reducer names must be known.
    for (final s in def.steps) {
      final r = s.config.reducer;
      if (r != null && r.isNotEmpty && !reducers.isKnown(r)) {
        issues.add(PipelineIssue(
          severity: PipelineIssueSeverity.error,
          stepId: s.id,
          message: 'Step "${s.id}" declares unknown reducer "$r".',
        ));
      }
    }

    // Consumed keys: inputKeys + {{key}} placeholders in prompt/script.
    for (final s in def.steps) {
      final consumed = <String>{...s.config.inputKeys};
      for (final field in [s.config.prompt, s.config.script]) {
        if (field == null) continue;
        for (final ref in renderer.placeholders(field)) {
          if (renderer.isTriggerScoped(ref)) continue;
          final key = renderer.stateKeyOf(ref);
          if (key != null) consumed.add(key);
        }
      }
      for (final key in consumed) {
        if (!producedBy.containsKey(key)) {
          issues.add(PipelineIssue(
            severity: PipelineIssueSeverity.warning,
            stepId: s.id,
            message: 'Step "${s.id}" reads "$key" which no upstream step '
                'produces (it must come from the trigger payload).',
          ));
        }
      }
    }

    // ── forEach must declare an iterable ────────────────────────────────
    for (final s in def.steps.where((s) => s.kind == StepKind.forEach)) {
      final iterableKey = s.config.extras['iterableKey'];
      if (iterableKey is! String || iterableKey.isEmpty) {
        issues.add(PipelineIssue(
          severity: PipelineIssueSeverity.error,
          stepId: s.id,
          message: 'forEach "${s.id}" must declare extras.iterableKey.',
        ));
      }
    }

    return issues;
  }

  /// Returns only the blocking issues.
  List<PipelineIssue> errors(PipelineDefinition def) =>
      validate(def).where((i) => i.isError).toList();
}

/// Walks a condition predicate tree and returns human-readable problems (empty
/// when sound). Mirrors the shapes the `pipeline.condition` body understands.
List<String> _predicateIssues(Map<String, dynamic> node) {
  final type = node['type'];
  switch (type) {
    case 'fileExists':
      final paths = node['paths'];
      final hasPath = (paths is List && paths.any((p) => p is String && p.trim().isNotEmpty)) ||
          (paths is String && paths.trim().isNotEmpty) ||
          (node['path'] is String && (node['path'] as String).trim().isNotEmpty);
      return hasPath ? const [] : const ['has a file-exists check with no paths.'];
    case 'comparison':
      final problems = <String>[];
      final left = node['left'];
      if (left is! String || left.trim().isEmpty) {
        problems.add('has a comparison with no "left" operand.');
      }
      const validOps = {
        'equals', 'notEquals', 'contains', 'exists', 'notExists', 'gt', 'lt',
      };
      final op = node['op'];
      if (op == null) {
        problems.add('has a comparison with no operator.');
      } else if (op is! String || !validOps.contains(op)) {
        problems.add('has a comparison with an unknown operator "$op".');
      }
      // Every operator except the unary exists/notExists needs a right operand.
      if (op is String &&
          op != 'exists' &&
          op != 'notExists' &&
          node['right'] == null) {
        problems.add('has a comparison "$op" with no "right" operand.');
      }
      return problems;
    case 'and':
    case 'or':
      // Mirror the runtime's `_children` normalization: `of` may be a list or a
      // single map (a one-element group).
      final of = node['of'];
      final children = of is Map
          ? [of]
          : (of is List ? of.whereType<Map>().toList() : const <Map>[]);
      if (children.isEmpty) {
        return ['has an empty "$type" condition group.'];
      }
      return [
        for (final child in children)
          ..._predicateIssues(child.cast<String, dynamic>()),
      ];
    case 'not':
      final of = node['of'];
      final child = of is Map ? of : (of is List && of.isNotEmpty ? of.first : null);
      if (child is! Map) return const ['has a "not" condition with no child.'];
      return _predicateIssues(child.cast<String, dynamic>());
    default:
      return ['has an unknown condition type "$type".'];
  }
}
