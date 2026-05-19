import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_domain/features/pr_review/domain/entities/workflow_graph.dart';

/// A GitHub Actions expression — `${{ … }}` — inside a workflow job's `name:`.
final RegExp _expression = RegExp(r'\$\{\{.*?\}\}');

/// The check-run name pattern derived from a templated workflow job `name:`.
///
/// A matrix job's `name:` is a template GitHub expands once per variation, so
/// the literal YAML name never equals any check-run name:
/// `Component Tests (shard ${{ matrix.shard }}/${{ strategy.job-total }})`
/// arrives as `Component Tests (shard 1/4)` … `(shard 4/4)`. This compiles the
/// template into an anchored pattern whose single capture group spans the
/// substituted region, which both identifies a node's children and labels them.
class MatrixNameTemplate {
  MatrixNameTemplate._(this._pattern);

  final RegExp _pattern;

  /// Compiles [jobName] when it carries at least one `${{ … }}` expression.
  /// Returns null for a literal name — those match by equality instead.
  static MatrixNameTemplate? parse(String jobName) {
    final slots = _expression.allMatches(jobName).toList(growable: false);
    if (slots.isEmpty) {
      return null;
    }
    final buffer = StringBuffer('^')
      ..write(RegExp.escape(jobName.substring(0, slots.first.start)))
      ..write('(');
    for (var i = 0; i < slots.length; i++) {
      if (i > 0) {
        buffer.write(
          RegExp.escape(jobName.substring(slots[i - 1].end, slots[i].start)),
        );
      }
      buffer.write('.+?');
    }
    buffer
      ..write(')')
      ..write(RegExp.escape(jobName.substring(slots.last.end)))
      ..write(r'$');
    return MatrixNameTemplate._(RegExp(buffer.toString()));
  }

  /// The substituted region of [checkRunName] — `1/4` for
  /// `Component Tests (shard 1/4)` — or null when that name came from a
  /// different job.
  String? variationOf(String checkRunName) =>
      _pattern.firstMatch(checkRunName)?.group(1);
}

/// Whether [jobName] is a template GitHub substitutes per matrix variation.
bool isMatrixJobName(String jobName) => _expression.hasMatch(jobName);

/// The title a workflow graph node renders.
///
/// GitHub labels an expanded matrix by its YAML job id (`Matrix:
/// component-tests`) rather than by the unresolvable template and so do we;
/// [matrixLabel] supplies the localized form. A literal `name:` renders as
/// authored and a template that produced a single check run renders that
/// run's resolved name — one variation is not a group worth labelling.
String workflowNodeTitle(
  WorkflowJobNode node,
  List<CheckRun> runs, {
  required String Function(String jobId) matrixLabel,
}) {
  if (!isMatrixJobName(node.name)) {
    return node.name;
  }
  if (runs.length == 1) {
    return runs.single.name;
  }
  return matrixLabel(node.id);
}

/// The chip label for one matrix child: the part of [checkRunName] that varies
/// between siblings. That is the substituted region of a templated [jobName]
/// (`1/4`), else the ` (variation)` suffix GitHub appends when the job name is
/// a literal (`a` for `Job (a)`). Falls back to the full name when the check
/// run carries neither form.
String matrixVariationLabel(String jobName, String checkRunName) {
  final substituted = MatrixNameTemplate.parse(
    jobName,
  )?.variationOf(checkRunName);
  if (substituted != null && substituted.isNotEmpty) {
    return substituted;
  }
  if (checkRunName.startsWith('$jobName (') && checkRunName.endsWith(')')) {
    final suffix = checkRunName.substring(
      jobName.length + 2,
      checkRunName.length - 1,
    );
    if (suffix.isNotEmpty) {
      return suffix;
    }
  }
  return checkRunName;
}
