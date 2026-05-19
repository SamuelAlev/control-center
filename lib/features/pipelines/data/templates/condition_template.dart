import 'dart:io';

import 'package:control_center/core/storage/control_center_paths.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:control_center/features/pipelines/domain/entities/step_result.dart';
import 'package:control_center/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_context.dart';
import 'package:control_center/features/pipelines/domain/services/template_renderer.dart';
import 'package:control_center/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:path/path.dart' as p;

/// Registers the `pipeline.condition` router body.
///
/// Used by `StepKind.router` nodes. It reads its `config.extras`, evaluates a
/// condition, and returns a `StepResult.route(key)` — the engine then fires
/// only the downstream edge whose `routeKey` matches and marks the unselected
/// branches skipped.
///
/// Three authoring shapes are supported (in `config.extras`), in priority
/// order:
///
/// - **predicate** (`extras['predicate']`): a boolean predicate *tree* that
///   routes `"true"` / `"false"`. This is what the "If file exists", "All of
///   (AND)" and "Any of (OR)" palette nodes emit. A predicate node is a map
///   with a `type`:
///   - `{ "type": "fileExists", "paths": ["Cargo.toml", "Cargo.lock"],
///        "baseKey": "repoLocalPath", "negate": false, "recursive": false }`
///     — true when *any* listed path exists on disk (so a multi-path leaf is an
///     OR over files). `negate: true` flips it to "none exist" (file missing).
///     Relative paths resolve against `state[baseKey]` (default `repoLocalPath`,
///     the clone dir) or, when that is empty, the per-run workspace directory.
///     `recursive: true` also searches sub-directories for a matching basename
///     (skipping `.git`, `node_modules`, `build`, `.dart_tool`).
///   - `{ "type": "comparison", "left": "{{score}}", "op": "gt", "right": 80 }`
///     — operators: `equals`, `notEquals`, `contains`, `exists`, `notExists`,
///     `gt`, `lt`. Reads pipeline state, not the filesystem.
///   - `{ "type": "and"|"or", "of": [ <predicate>, ... ] }` — boolean groups.
///   - `{ "type": "not", "of": <predicate> }` — negation.
///
/// - **switch** (`extras['switchKey']`): `{ "switchKey": "prClass",
///   "cases": ["docs","security","standard"], "default": "standard" }` — routes
///   to the first case the value (case-insensitively) contains, else `default`.
///   Tolerant of chatty upstream agent output.
///
/// - **comparison** (legacy top-level `extras['left'/'op'/'right']`): equivalent
///   to a `comparison` predicate, kept for templates authored before the tree.
void registerConditionBody(
  PipelineBodyRegistry registry, {
  required PipelineTemplateRepository templateRepository,
}) {
  const renderer = TemplateRenderer();

  registry.registerBody(BuiltInBodyKeys.condition, (ctx) async {
    final config = await _resolveConfig(templateRepository, ctx);
    if (config == null) {
      return StepResult.failed('condition: step "${ctx.stepId}" missing config');
    }
    final extras = config.extras;

    // ── Predicate-tree mode (file existence, boolean groups, comparison) ──
    final predicate = extras['predicate'];
    if (predicate is Map) {
      final evalCtx = _PredicateContext(
        state: ctx.state,
        trigger: ctx.triggerPayload,
        pipelineRunId: ctx.pipelineRunId,
      );
      final bool matched;
      try {
        matched = await _evaluate(
          predicate.cast<String, dynamic>(),
          evalCtx,
          renderer,
        );
      } on _PredicateError catch (e) {
        return StepResult.failed('condition: ${e.message}');
      }
      final key = matched ? 'true' : 'false';
      return StepResult.route(key, mutatedState: {'${ctx.stepId}_route': key});
    }

    // ── Switch mode ──────────────────────────────────────────────────────
    final switchKey = extras['switchKey'];
    if (switchKey is String && switchKey.isNotEmpty) {
      final raw =
          (ctx.state[switchKey] ?? ctx.triggerPayload?[switchKey])?.toString() ??
              '';
      final value = raw.toLowerCase();
      final cases = (extras['cases'] as List?)?.cast<String>() ?? const [];
      final fallback = extras['default'] as String?;
      final matched = cases.firstWhere(
        (c) => value.contains(c.toLowerCase()),
        orElse: () => fallback ?? (cases.isEmpty ? '' : cases.first),
      );
      if (matched.isEmpty) {
        return StepResult.failed(
          'condition: no matching case for "$raw" on key "$switchKey"',
        );
      }
      return StepResult.route(
        matched,
        mutatedState: {'${ctx.stepId}_route': matched},
      );
    }

    // ── Legacy top-level comparison mode ─────────────────────────────────
    final leftRef = extras['left'] as String? ?? '';
    final left = _resolveLeft(
      leftRef,
      _PredicateContext(
        state: ctx.state,
        trigger: ctx.triggerPayload,
        pipelineRunId: ctx.pipelineRunId,
      ),
      renderer,
    );
    final op = extras['op'] as String? ?? 'exists';
    final right = extras['right'];
    final matched = _compare(left, op, right);
    final key = matched ? 'true' : 'false';
    return StepResult.route(key, mutatedState: {'${ctx.stepId}_route': key});
  });
}

/// Resolves a comparison's left operand. A `{{…}}` template is rendered (so
/// `{{score}}` yields the value); a bare key / `$state.`-style ref is looked up
/// directly, preserving its runtime type for numeric comparisons.
Object? _resolveLeft(
  String ref,
  _PredicateContext ctx,
  TemplateRenderer renderer,
) {
  if (ref.contains('{{')) {
    return renderer.render(ref, state: ctx.state, trigger: ctx.trigger).text;
  }
  return renderer.resolve(ref, state: ctx.state, trigger: ctx.trigger);
}

Future<PipelineNodeConfig?> _resolveConfig(
  PipelineTemplateRepository repo,
  PipelineContext ctx,
) async {
  final workspaceId = ctx.workspaceId;
  final def = await repo.getById(workspaceId, ctx.templateId);
  return def?.step(ctx.stepId)?.config;
}

/// Recursively evaluates a predicate node to a boolean.
Future<bool> _evaluate(
  Map<String, dynamic> node,
  _PredicateContext ctx,
  TemplateRenderer renderer,
) async {
  final type = node['type'] as String?;
  switch (type) {
    case 'and':
      final of = _children(node);
      for (final child in of) {
        if (!await _evaluate(child, ctx, renderer)) {
          return false;
        }
      }
      return true;
    case 'or':
      final of = _children(node);
      for (final child in of) {
        if (await _evaluate(child, ctx, renderer)) {
          return true;
        }
      }
      return false;
    case 'not':
      final of = _children(node);
      if (of.isEmpty) {
        throw const _PredicateError('"not" predicate has no child');
      }
      return !await _evaluate(of.first, ctx, renderer);
    case 'comparison':
      final left = _resolveLeft(node['left'] as String? ?? '', ctx, renderer);
      return _compare(left, node['op'] as String? ?? 'exists', node['right']);
    case 'fileExists':
      return await _fileExists(node, ctx, renderer);
    default:
      throw _PredicateError('unknown predicate type "$type"');
  }
}

/// Normalizes a predicate's children. `and`/`or` use a `of` list; `not` accepts
/// either a single map or a one-element list.
List<Map<String, dynamic>> _children(Map<String, dynamic> node) {
  final of = node['of'];
  if (of is Map) {
    return [of.cast<String, dynamic>()];
  }
  if (of is List) {
    return of
        .whereType<Map>()
        .map((m) => m.cast<String, dynamic>())
        .toList(growable: false);
  }
  return const [];
}

/// Evaluates a `fileExists` leaf: true when any of `paths` exists under the
/// resolved base directory. `negate` flips it; `recursive` also scans
/// sub-directories for a matching basename.
Future<bool> _fileExists(
  Map<String, dynamic> node,
  _PredicateContext ctx,
  TemplateRenderer renderer,
) async {
  final rawPaths = node['paths'];
  final paths = <String>[
    if (rawPaths is String && rawPaths.isNotEmpty) rawPaths,
    if (rawPaths is List)
      for (final v in rawPaths)
        if (v is String && v.trim().isNotEmpty) v.trim(),
    // Single-path convenience key.
    if (node['path'] is String && (node['path'] as String).isNotEmpty)
      node['path'] as String,
  ];
  if (paths.isEmpty) {
    throw const _PredicateError('"fileExists" predicate lists no paths');
  }

  final baseKey = node['baseKey'] as String? ?? 'repoLocalPath';
  final baseFromState = ctx.state[baseKey];
  // Only fall back to the per-run workspace dir (which needs app storage to be
  // initialized) when no usable base key is in state — so the common case of a
  // resolved `repoLocalPath` does no app-bootstrap work.
  final baseDir = (baseFromState is String && baseFromState.isNotEmpty)
      ? baseFromState
      : await ctx.runDir();
  final recursive = node['recursive'] == true;

  var anyExists = false;
  for (final path in paths) {
    final rendered = renderer
        .render(path, state: ctx.state, trigger: ctx.trigger)
        .text
        .trim();
    if (rendered.isEmpty) {
      continue;
    }
    final full = p.isAbsolute(rendered) ? rendered : p.join(baseDir, rendered);
    if (FileSystemEntity.typeSync(full) != FileSystemEntityType.notFound) {
      anyExists = true;
      break;
    }
    if (recursive && _existsRecursive(baseDir, p.basename(rendered))) {
      anyExists = true;
      break;
    }
  }

  final negate = node['negate'] == true;
  return negate ? !anyExists : anyExists;
}

/// Bounded recursive search for an entity named [basename] anywhere under
/// [rootPath]. Skips heavy/irrelevant directories and caps the number of
/// entries scanned so a huge tree can't stall the run.
bool _existsRecursive(String rootPath, String basename) {
  const skipDirs = {'.git', 'node_modules', 'build', '.dart_tool', '.idea'};
  const maxEntries = 50000;
  final root = Directory(rootPath);
  if (!root.existsSync()) {
    return false;
  }
  final queue = <Directory>[root];
  var scanned = 0;
  while (queue.isNotEmpty) {
    final dir = queue.removeLast();
    final List<FileSystemEntity> entries;
    try {
      entries = dir.listSync(followLinks: false);
    } on FileSystemException {
      continue; // unreadable dir — skip
    }
    for (final entry in entries) {
      if (++scanned > maxEntries) {
        return false;
      }
      final name = p.basename(entry.path);
      if (name == basename) {
        return true;
      }
      if (entry is Directory && !skipDirs.contains(name)) {
        queue.add(entry);
      }
    }
  }
  return false;
}

bool _compare(Object? left, String op, Object? right) {
  switch (op) {
    case 'exists':
      return left != null && '$left'.isNotEmpty;
    case 'notExists':
      return left == null || '$left'.isEmpty;
    case 'equals':
      return '$left' == '$right';
    case 'notEquals':
      return '$left' != '$right';
    case 'contains':
      return left != null && '$left'.contains('$right');
    case 'gt':
      return _asNum(left) != null &&
          _asNum(right) != null &&
          _asNum(left)! > _asNum(right)!;
    case 'lt':
      return _asNum(left) != null &&
          _asNum(right) != null &&
          _asNum(left)! < _asNum(right)!;
    default:
      return false;
  }
}

num? _asNum(Object? v) {
  if (v is num) {
    return v;
  }
  if (v is String) {
    return num.tryParse(v);
  }
  return null;
}

/// Filesystem + state context for a condition evaluation.
class _PredicateContext {
  _PredicateContext({
    required this.state,
    required this.trigger,
    required this.pipelineRunId,
  });

  final Map<String, dynamic> state;
  final Map<String, dynamic>? trigger;
  final String pipelineRunId;

  String? _runDirPath;

  /// Per-run workspace dir, the base for relative paths when no `baseKey` state
  /// value (e.g. `repoLocalPath`) is set. Resolved (and cached) lazily so a
  /// purely state-based check never touches app storage.
  Future<String> runDir() async {
    return _runDirPath ??= (await pipelineRunDir(pipelineRunId)).path;
  }
}

/// Thrown for malformed predicates so the body can fail the step with a clear
/// message instead of throwing an opaque type error.
class _PredicateError implements Exception {
  const _PredicateError(this.message);
  final String message;
}
