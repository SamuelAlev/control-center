import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_domain/features/pr_review/domain/entities/job_run_detail.dart';
import 'package:cc_markdown/cc_markdown.dart' show CcSelectionRegion;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_run_formatting.dart';
import 'package:control_center/features/pr_review/presentation/utils/review_status_palette.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _ansiEscapePattern = RegExp('\x1B\\[[0-9;?]*[A-Za-z]');
final _ghTimestampPrefix = RegExp(
  r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+Z\s*',
  multiLine: true,
);
final _displayAttrPattern = RegExp(r'display=([^;\]]*)');

/// Section title from a `##[start-action display=X;id=Y]` opener: the
/// `display` attribute, else the raw attribute string.
String _actionDisplayName(String line) {
  final inner = line.substring('##[start-action '.length);
  final end = inner.indexOf(']');
  final attrs = end < 0 ? inner : inner.substring(0, end);
  final display = _displayAttrPattern.firstMatch(attrs)?.group(1)?.trim();
  return display == null || display.isEmpty ? attrs.trim() : display;
}

/// Strips ANSI escapes and GitHub's per-line UTC timestamp prefix.
String processJobLogs(String raw) =>
    raw.replaceAll(_ansiEscapePattern, '').replaceAll(_ghTimestampPrefix, '');

/// One `##[group]` section of a job log. [title] is the group header text.
class JobLogSection {
  /// Creates a [JobLogSection].
  const JobLogSection({required this.title, required this.body});

  /// Section title (the `##[group]` header text; `Set up job` for the
  /// preamble, `Complete job` for the tail).
  final String title;

  /// Section body (lines between the header and its `##[endgroup]`).
  final String body;
}

/// Title of the synthetic section holding the post-job cleanup lines (post
/// steps emit no marker of their own on recent runners — their output
/// follows the first `Post job cleanup.` line).
const String kPostJobSectionTitle = 'Post job';

/// Prefix of a top-level STEP section title (`Run pnpm install`,
/// `Run actions/checkout@v4`).
const String _runStepPrefix = 'Run ';

/// Slices a processed job log into ordered sections.
///
/// Modern runner dialect (any top-level `##[group]Run …` marker): a
/// `##[group]Run …` opens a STEP section. The runner titles it by COMMAND,
/// never by the YAML step name, so name matching cannot identify `uses:` or
/// `run:` steps — callers must correlate sections to steps by ORDER (see
/// [mapStepsToSections]). The body keeps the raw `##[group]Run … ##[endgroup]`
/// wrapper plus everything up to the next step — nested info groups
/// (`Getting Git version info`), `##[start-action]` composite children and
/// their own nested `Run …` invocations, bare output lines — so the display
/// layer ([parseLogLines]) renders GitHub's `▼ Run …` fold. A composite
/// step's `Prepare all required actions` block is logged BEFORE its opener
/// but belongs to the step (GitHub shows it as the step's first rows), so it
/// is moved in. The first `Post job cleanup.` line opens a shared
/// [kPostJobSectionTitle] section; the preamble (everything before the first
/// marker, incl. the `GITHUB_TOKEN Permissions` group) is `Set up job`.
/// There is no tail section: trailing lines belong to the last section.
///
/// Legacy dialect (no `##[group]Run …` marker anywhere): every top-level
/// `##[group]X` or `##[start-action display=X;…]` is its own section,
/// matched to steps by name via [sectionForStep]; anything after the last
/// section is the `Complete job` tail.
List<JobLogSection> sliceJobLog(String processed) {
  final hasRunSections = processed
      .split('\n')
      .any((l) => l.startsWith('##[group]$_runStepPrefix'));
  return hasRunSections ? _sliceModern(processed) : _sliceLegacy(processed);
}

/// Leading line of the runner's composite-action preamble
/// (`Prepare all required actions` + `Getting action download info` +
/// `Download action repository …`). Logged before the step's opener but
/// owned by the step it announces.
const String _prepareBlockLeader = 'Prepare all required actions';

List<JobLogSection> _sliceModern(String processed) {
  final sections = <JobLogSection>[];
  final preamble = StringBuffer();
  String? openTitle;
  final openBody = StringBuffer();
  var groupDepth = 0; // nested group depth inside the open section
  var stepGroupOpen = false; // the open section's own Run-group is unclosed
  var openActions = 0; // unclosed `##[start-action]` blocks
  var inPost = false;

  void closeOpen() {
    final title = openTitle;
    if (title != null) {
      final body = openBody.toString();
      if (body.trim().isNotEmpty) {
        sections.add(JobLogSection(title: title, body: body));
      }
      openTitle = null;
      openBody.clear();
    }
  }

  void startSection(String title) {
    closeOpen();
    openTitle = title;
    groupDepth = 0;
  }

  /// Moves a trailing composite-action prepare block (everything from the
  /// last [_prepareBlockLeader] line onward) out of [sink]; returns it.
  String takeTrailingPrepareBlock(StringBuffer sink) {
    final text = sink.toString();
    final idx = text.lastIndexOf(_prepareBlockLeader);
    if (idx < 0 || (idx > 0 && text[idx - 1] != '\n')) {
      return '';
    }
    final block = text.substring(idx);
    // A prepare block is plain lines only. If the tail past the leader holds
    // any `##[` marker, the leader is inside a section body already (e.g. a
    // block moved into a composite step) — not a pending prepare block.
    if (block.contains('##[')) {
      return '';
    }
    sink
      ..clear()
      ..write(text.substring(0, idx));
    return block;
  }

  for (final line in processed.split('\n')) {
    final sink = openTitle == null ? preamble : openBody;
    if (line.startsWith('##[group]$_runStepPrefix') &&
        groupDepth == 0 &&
        !stepGroupOpen &&
        openActions == 0) {
      // A new STEP section. The gates: a `Run …` line inside an unclosed
      // step group, or inside a `##[start-action]` block, is a composite
      // child's own action invocation (`Run pnpm/action-setup@…`), not a
      // step — composite children log AFTER their parent's Run-group closed,
      // so the action block is the reliable nesting signal. Pull a composite
      // step's prepare block out of wherever it landed into this section.
      final prepare = takeTrailingPrepareBlock(sink);
      startSection(line.substring('##[group]'.length).trim());
      stepGroupOpen = true;
      inPost = false;
      openBody
        ..write(prepare)
        ..writeln(line); // raw opener: the display folds it
    } else if (line.startsWith('##[group]')) {
      // Nested group: keep the marker so the display can fold it.
      groupDepth++;
      sink.writeln(line);
    } else if (line.startsWith('##[endgroup]')) {
      if (groupDepth > 0) {
        groupDepth--;
      } else if (stepGroupOpen) {
        stepGroupOpen = false;
      }
      sink.writeln(line); // kept raw: the display folds on it
    } else if (line.startsWith('##[start-action ')) {
      openActions++;
      sink.writeln(line); // kept raw: the display folds it
    } else if (line.startsWith('##[end-action')) {
      if (openActions > 0) {
        openActions--;
      }
      sink.writeln(line);
    } else if (line == 'Post job cleanup.' &&
        groupDepth == 0 &&
        !stepGroupOpen &&
        !inPost) {
      startSection(kPostJobSectionTitle);
      stepGroupOpen = false;
      inPost = true;
      // The marker line itself becomes the title.
    } else {
      sink.writeln(line);
    }
  }
  closeOpen();

  final result = <JobLogSection>[];
  final preambleText = preamble.toString();
  if (preambleText.trim().isNotEmpty) {
    result.add(JobLogSection(title: 'Set up job', body: preambleText));
  }
  result.addAll(sections);
  return result;
}

List<JobLogSection> _sliceLegacy(String processed) {
  final sections = <JobLogSection>[];
  final preamble = StringBuffer();
  final tail = StringBuffer();
  String? openTitle;
  final openBody = StringBuffer();
  var seenGroup = false;

  void closeOpen() {
    final title = openTitle;
    if (title != null) {
      sections.add(JobLogSection(title: title, body: openBody.toString()));
      openTitle = null;
      openBody.clear();
    }
  }

  for (final line in processed.split('\n')) {
    if (line.startsWith('##[group]')) {
      if (openTitle == null) {
        // Groups don't nest in practice — a nested open is treated as body
        // text.
        seenGroup = true;
        openTitle = line.substring('##[group]'.length).trim();
      } else {
        openBody.writeln(line);
      }
    } else if (line.startsWith('##[start-action ')) {
      if (openTitle == null) {
        seenGroup = true;
        openTitle = _actionDisplayName(line);
      } else {
        openBody.writeln(line);
      }
    } else if (line.startsWith('##[endgroup]') ||
        line.startsWith('##[end-action')) {
      if (openTitle != null) {
        closeOpen();
      }
    } else if (openTitle != null) {
      openBody.writeln(line);
    } else if (seenGroup) {
      tail.writeln(line);
    } else {
      preamble.writeln(line);
    }
  }
  closeOpen();

  final result = <JobLogSection>[];
  final preambleText = preamble.toString();
  if (preambleText.trim().isNotEmpty) {
    result.add(JobLogSection(title: 'Set up job', body: preambleText));
  }
  result.addAll(sections);
  final tailText = tail.toString();
  if (tailText.trim().isNotEmpty) {
    result.add(JobLogSection(title: 'Complete job', body: tailText));
  }
  return result;
}

/// Picks the log section for [stepName]: exact title match, then a
/// startsWith/endsWith containment either way. Null when nothing matches.
JobLogSection? sectionForStep(List<JobLogSection> sections, String stepName) {
  for (final s in sections) {
    if (s.title == stepName) {
      return s;
    }
  }
  for (final s in sections) {
    if (s.title.startsWith(stepName) ||
        stepName.startsWith(s.title) ||
        s.title.endsWith(stepName) ||
        stepName.endsWith(s.title)) {
      return s;
    }
  }
  // Post steps emit no step marker of their own on recent runners — their
  // output lives in the shared cleanup section.
  if (stepName.startsWith('Post ')) {
    for (final s in sections) {
      if (s.title == kPostJobSectionTitle) {
        return s;
      }
    }
  }
  return null;
}

/// Maps each API step (by index into [steps]) to its log section.
///
/// The runner titles step sections by COMMAND (`Run pnpm install`,
/// `Run actions/checkout@v4`), never by the YAML step name, so name matching
/// alone cannot identify `uses:`/`run:` steps. Instead, completed
/// non-skipped steps are correlated with `Run …` sections by ORDER — both
/// sequences are chronological. Skipped and unfinished steps have no logs by
/// definition. Anything left over (post steps, the `Set up job`/`Complete
/// job` edges) falls back to [sectionForStep] name matching, without
/// stealing a section already claimed by order correlation (the shared post
/// section excepted).
Map<int, JobLogSection?> mapStepsToSections(
  List<JobRunStep> steps,
  List<JobLogSection> sections,
) {
  final runSections = <JobLogSection>[
    for (final s in sections)
      if (s.title.startsWith(_runStepPrefix)) s,
  ];
  final result = <int, JobLogSection?>{};
  final orderMatched = <JobLogSection>{};
  var runIdx = 0;
  for (var i = 0; i < steps.length; i++) {
    final step = steps[i];
    if (i == 0 ||
        i == steps.length - 1 ||
        !step.isComplete ||
        step.conclusion == CheckRunConclusion.skipped) {
      continue; // edge steps name-match below; skipped/unfinished have none
    }
    if (runIdx < runSections.length) {
      final s = runSections[runIdx++];
      orderMatched.add(s);
      result[i] = s;
    }
  }
  for (var i = 0; i < steps.length; i++) {
    if (result.containsKey(i)) {
      continue;
    }
    final step = steps[i];
    if (!step.isComplete || step.conclusion == CheckRunConclusion.skipped) {
      result[i] = null;
      continue;
    }
    final byName = sectionForStep(sections, step.name);
    result[i] =
        byName != null &&
            (!orderMatched.contains(byName) ||
                byName.title == kPostJobSectionTitle)
        ? byName
        : null;
  }
  return result;
}

/// One visible unit of a parsed log slice: either a text [line] or a
/// collapsible `group` (a nested `##[group]…` info block or a
/// `##[start-action]…` composite child the slicer kept raw). [number] is the
/// 1-based number of the VISIBLE row within the slice: hidden marker lines
/// (`##[endgroup]`, `##[end-action]`) consume no number, so the gutter never
/// shows a gap; collapsing a group hides its numbered children, leaving the
/// jump GitHub's viewer shows.
class LogLineNode {
  /// A plain text line.
  const LogLineNode.line(this.number, this.line)
    : title = null,
      children = const [];

  /// A collapsible group with a header [title] and [children].
  const LogLineNode.group(this.number, this.title, this.children) : line = null;

  /// 1-based line number of this row within the slice.
  final int number;

  /// Line text (plain lines only).
  final String? line;

  /// Group header title (groups only).
  final String? title;

  /// Child nodes (groups only).
  final List<LogLineNode> children;

  /// Whether this node is a collapsible group.
  bool get isGroup => title != null;
}

class _GroupBuilder {
  _GroupBuilder(this.number, this.title);
  final int number;
  final String title;
  final List<LogLineNode> children = [];
}

/// Parses a processed log slice into text lines and nested collapsible
/// groups: `##[group]X` / `##[endgroup]` pairs and
/// `##[start-action display=X;…]` / `##[end-action …]` pairs become [LogLineNode.group]s (the
/// start-action title is its `display` attribute); everything else is a
/// [LogLineNode.line]. Unclosed groups close at the end of the slice; stray
/// closers are dropped.
List<LogLineNode> parseLogLines(String body) {
  final roots = <LogLineNode>[];
  final stack = <_GroupBuilder>[];
  final lines = body.split('\n');
  // `writeln` leaves a trailing empty line — drop it so it doesn't render
  // as a blank numbered row.
  if (lines.isNotEmpty && lines.last.isEmpty) {
    lines.removeLast();
  }
  var number = 0;
  for (final line in lines) {
    if (line.startsWith('##[group]')) {
      stack.add(
        _GroupBuilder(++number, line.substring('##[group]'.length).trim()),
      );
    } else if (line.startsWith('##[start-action ')) {
      stack.add(_GroupBuilder(++number, _actionDisplayName(line)));
    } else if (line.startsWith('##[endgroup]') ||
        line.startsWith('##[end-action')) {
      // Hidden marker: consumes no row number.
      if (stack.isNotEmpty) {
        final g = stack.removeLast();
        final node = LogLineNode.group(g.number, g.title, List.of(g.children));
        (stack.isEmpty ? roots : stack.last.children).add(node);
      }
    } else {
      (stack.isEmpty ? roots : stack.last.children).add(
        LogLineNode.line(++number, line),
      );
    }
  }
  while (stack.isNotEmpty) {
    final g = stack.removeLast();
    final node = LogLineNode.group(g.number, g.title, List.of(g.children));
    (stack.isEmpty ? roots : stack.last.children).add(node);
  }
  return roots;
}

/// Steps accordion for ONE check run: live step progress while the job runs
/// (the jobs API exposes `steps[]` for in-progress jobs), per-step log slices
/// once GitHub publishes the job log, and a trailing full-log item.
class JobStepsAccordion extends ConsumerStatefulWidget {
  /// Creates a [JobStepsAccordion].
  const JobStepsAccordion({super.key, required this.checkRun});

  /// The check run whose Actions job to detail. Must carry a `jobId` — call
  /// sites only render this for Actions-backed checks.
  final CheckRun checkRun;

  @override
  ConsumerState<JobStepsAccordion> createState() => _JobStepsAccordionState();
}

class _JobStepsAccordionState extends ConsumerState<JobStepsAccordion> {
  static const String _fullLogKey = '__full';

  /// Open accordion items, keyed by step name + [_fullLogKey].
  final Set<String> _open = {};

  void _toggle(String key) {
    setState(() {
      if (!_open.add(key)) {
        _open.remove(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final jobId = widget.checkRun.jobId!;
    final detailAsync = ref.watch(prJobRunDetailProvider(jobId));

    return detailAsync.when(
      loading: () =>
          const SizedBox(height: 48, child: Center(child: CcSpinner(size: 16))),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            const Icon(
              AppIcons.alertTriangle,
              size: 14,
              color: ReviewStatusColors.failure,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.jobLogsUnavailable,
                style: CcTypography.caption.copyWith(
                  color: tokens.textTertiary,
                ),
              ),
            ),
            CcButton(
              variant: CcButtonVariant.ghost,
              size: CcButtonSize.sm,
              onPressed: () => ref.invalidate(prJobRunDetailProvider(jobId)),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
      data: (detail) {
        if (detail == null) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Text(
              l10n.jobLogsUnavailable,
              style: CcTypography.caption.copyWith(color: tokens.textTertiary),
            ),
          );
        }
        return _buildDetail(context, detail, tokens, l10n);
      },
    );
  }

  Widget _buildDetail(
    BuildContext context,
    JobRunDetail detail,
    DesignSystemTokens tokens,
    AppLocalizations l10n,
  ) {
    final processed = detail.logs == null ? null : processJobLogs(detail.logs!);
    final sections = processed == null ? null : sliceJobLog(processed);
    final stepSections = sections == null
        ? null
        : mapStepsToSections(detail.steps, sections);
    final items = <Widget>[];

    for (var i = 0; i < detail.steps.length; i++) {
      final step = detail.steps[i];
      // A step can open once logs exist and the step itself completed — its
      // body is its correlated slice, or a "no logs" caption when the step
      // has none (a skipped step, `Complete job`, an unpublished log).
      final section = stepSections?[i];
      final expandable = sections != null && step.isComplete;
      items.add(
        _StepItem(
          step: step,
          expanded: _open.contains(step.name),
          expandable: expandable,
          onToggle: expandable ? () => _toggle(step.name) : null,
          body: !expandable
              ? null
              : section != null
              ? _LogViewer(text: section.body)
              : Padding(
                  padding: const EdgeInsets.fromLTRB(38, 0, 14, 10),
                  child: Text(
                    l10n.noLogsForStep,
                    style: CcTypography.caption.copyWith(
                      color: tokens.textTertiary,
                    ),
                  ),
                ),
          isLast: false,
        ),
      );
    }

    // Status caption under the steps: live jobs can't have logs yet (the API
    // 404s them); a completed job whose logs never published settles on
    // "unavailable" rather than spinning forever.
    if (!detail.isComplete) {
      items.add(_caption(l10n.jobLogsPending, tokens));
    } else if (detail.logs == null) {
      items.add(_caption(l10n.jobLogsUnavailable, tokens));
    } else {
      final processedText = processed!;
      items.add(
        _FullLogItem(
          expanded: _open.contains(_fullLogKey),
          onToggle: () => _toggle(_fullLogKey),
          truncated: detail.logsTruncated,
          onCopy: () {
            Clipboard.setData(ClipboardData(text: processedText));
            CcToastScope.maybeOf(
              context,
            )?.show(l10n.copied, variant: CcToastVariant.success);
          },
          body: _LogViewer(text: processedText),
          isLast: true,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: items,
    );
  }

  Widget _caption(String text, DesignSystemTokens tokens) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(38, 0, 14, 10),
      child: Text(
        text,
        style: CcTypography.caption.copyWith(color: tokens.textTertiary),
      ),
    );
  }
}

/// One step row of the accordion: status glyph + name + duration, with a
/// chevron (and expandable log body) once the step has logs.
class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.step,
    required this.expanded,
    required this.expandable,
    required this.onToggle,
    required this.body,
    required this.isLast,
  });

  final JobRunStep step;
  final bool expanded;
  final bool expandable;
  final VoidCallback? onToggle;
  final Widget? body;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final startedAt = step.startedAt;
    final completedAt = step.completedAt;
    final duration = step.isComplete && startedAt != null && completedAt != null
        ? formatPipelineDuration(completedAt.difference(startedAt))
        : null;

    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: tokens.borderSecondary)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CcTappable(
            onPressed: onToggle,
            builder: (context, states) => Container(
              color: states.contains(WidgetState.hovered)
                  ? tokens.bgSecondary
                  : null,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
                child: Row(
                  children: [
                    _stepGlyph(step),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        step.name,
                        style: CcTypography.caption.copyWith(
                          color: tokens.textPrimary,
                        ),
                      ),
                    ),
                    if (duration != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        duration,
                        style: CcTypography.caption.copyWith(
                          color: tokens.textTertiary,
                        ),
                      ),
                    ],
                    if (expandable) ...[
                      const SizedBox(width: 6),
                      Icon(
                        expanded ? AppIcons.chevronUp : AppIcons.chevronDown,
                        size: 14,
                        color: tokens.textTertiary,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (expanded && body != null) body!,
        ],
      ),
    );
  }

  Widget _stepGlyph(JobRunStep step) {
    if (step.status == CheckRunStatus.inProgress) {
      return const CcSpinner(size: 14, color: ReviewStatusColors.running);
    }
    if (step.isSuccess) {
      return const Icon(
        AppIcons.checkCircle2,
        size: 14,
        color: ReviewStatusColors.success,
      );
    }
    if (step.isFailing) {
      return const Icon(
        AppIcons.xCircle,
        size: 14,
        color: ReviewStatusColors.failure,
      );
    }
    return const Icon(
      AppIcons.minusCircle,
      size: 14,
      color: ReviewStatusColors.neutral,
    );
  }
}

/// The trailing "Full log" accordion item, with a copy button and a
/// truncation caption.
class _FullLogItem extends StatelessWidget {
  const _FullLogItem({
    required this.expanded,
    required this.onToggle,
    required this.truncated,
    required this.onCopy,
    required this.body,
    required this.isLast,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final bool truncated;
  final VoidCallback onCopy;
  final Widget body;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: tokens.borderSecondary)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CcTappable(
            onPressed: onToggle,
            builder: (context, states) => Container(
              color: states.contains(WidgetState.hovered)
                  ? tokens.bgSecondary
                  : null,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.fullLog,
                        style: CcTypography.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: tokens.textPrimary,
                        ),
                      ),
                    ),
                    if (truncated)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          l10n.jobLogsTruncated,
                          style: CcTypography.caption.copyWith(
                            color: tokens.textTertiary,
                          ),
                        ),
                      ),
                    CcIconButton(
                      icon: AppIcons.copy,
                      size: CcButtonSize.sm,
                      tooltip: l10n.copyLogs,
                      onPressed: onCopy,
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      expanded ? AppIcons.chevronUp : AppIcons.chevronDown,
                      size: 14,
                      color: tokens.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (expanded) body,
        ],
      ),
    );
  }
}

/// GitHub-style log body: mono text with a line-number gutter and nested
/// collapsible groups (the info blocks and composite actions the slicer kept
/// raw). Collapsing a group hides its children while the gutter numbers keep
/// their original values, leaving the same visible jump GitHub shows.
class JobLogBody extends ConsumerStatefulWidget {
  /// Creates a [JobLogBody].
  const JobLogBody({super.key, required this.text});

  /// The processed log slice (ANSI/timestamps already stripped).
  final String text;

  @override
  ConsumerState<JobLogBody> createState() => _JobLogBodyState();
}

class _JobLogBodyState extends ConsumerState<JobLogBody> {
  /// Header line numbers of collapsed groups.
  final Set<int> _collapsed = {};
  late List<LogLineNode> _nodes = parseLogLines(widget.text);

  @override
  void didUpdateWidget(JobLogBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _nodes = parseLogLines(widget.text);
      _collapsed.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final codeFont = ref.watch(codeFontFamilyProvider);
    return CcSelectionRegion(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final node in _nodes) ..._nodeRows(node, 0, tokens, codeFont),
        ],
      ),
    );
  }

  Iterable<Widget> _nodeRows(
    LogLineNode node,
    int depth,
    DesignSystemTokens tokens,
    String codeFont,
  ) sync* {
    if (node.isGroup) {
      final collapsed = _collapsed.contains(node.number);
      yield _LogGroupHeader(
        number: node.number,
        title: node.title!,
        depth: depth,
        collapsed: collapsed,
        codeFont: codeFont,
        tokens: tokens,
        onToggle: () => setState(() {
          if (collapsed) {
            _collapsed.remove(node.number);
          } else {
            _collapsed.add(node.number);
          }
        }),
      );
      if (!collapsed) {
        for (final child in node.children) {
          yield* _nodeRows(child, depth + 1, tokens, codeFont);
        }
      }
    } else {
      yield _LogLineRow(
        number: node.number,
        text: node.line!,
        depth: depth,
        codeFont: codeFont,
        tokens: tokens,
      );
    }
  }
}

const double _logGutterWidth = 40;
const double _logDepthIndent = 14;

/// The right-aligned line-number cell every log row starts with.
class _LogGutter extends StatelessWidget {
  const _LogGutter({
    required this.number,
    required this.codeFont,
    required this.tokens,
  });

  final int number;
  final String codeFont;
  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    // Excluded from text selection: dragging across log rows must not pull
    // the gutter numbers into the copied text (GitHub behaves the same).
    return SelectionContainer.disabled(
      child: SizedBox(
        width: _logGutterWidth,
        child: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Text(
            '$number',
            textAlign: TextAlign.right,
            style: AppFonts.codeStyleDynamic(
              codeFont,
              fontSize: 11,
              height: 1.5,
            ).copyWith(color: tokens.textQuaternary),
          ),
        ),
      ),
    );
  }
}

/// One plain log line: gutter + mono text, indented by group depth.
class _LogLineRow extends StatelessWidget {
  const _LogLineRow({
    required this.number,
    required this.text,
    required this.depth,
    required this.codeFont,
    required this.tokens,
  });

  final int number;
  final String text;
  final int depth;
  final String codeFont;
  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    final isCommandEcho = text.startsWith('[command]');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LogGutter(number: number, codeFont: codeFont, tokens: tokens),
        SizedBox(width: depth * _logDepthIndent),
        Expanded(
          child: Text(
            // An empty Text lays out zero-height — keep the blank row.
            text.isEmpty ? ' ' : text,
            style:
                AppFonts.codeStyleDynamic(
                  codeFont,
                  fontSize: 12,
                  height: 1.5,
                ).copyWith(
                  color: isCommandEcho
                      ? tokens.textTertiary
                      : tokens.textSecondary,
                ),
          ),
        ),
      ],
    );
  }
}

/// A collapsible group header: gutter + chevron + mono title.
class _LogGroupHeader extends StatelessWidget {
  const _LogGroupHeader({
    required this.number,
    required this.title,
    required this.depth,
    required this.collapsed,
    required this.codeFont,
    required this.tokens,
    required this.onToggle,
  });

  final int number;
  final String title;
  final int depth;
  final bool collapsed;
  final String codeFont;
  final DesignSystemTokens tokens;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return CcTappable(
      onPressed: onToggle,
      borderRadius: BorderRadius.circular(4),
      builder: (context, states) => Container(
        color: states.contains(WidgetState.hovered) ? tokens.bgSecondary : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LogGutter(number: number, codeFont: codeFont, tokens: tokens),
            SizedBox(width: depth * _logDepthIndent),
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Icon(
                collapsed ? AppIcons.chevronRight : AppIcons.chevronDown,
                size: 12,
                color: tokens.textTertiary,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                title,
                style:
                    AppFonts.codeStyleDynamic(
                      codeFont,
                      fontSize: 12,
                      height: 1.5,
                    ).copyWith(
                      fontWeight: FontWeight.w600,
                      color: tokens.textPrimary,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mono log viewer shared by step bodies and the full log: a bordered
/// surface with selectable text. The content renders at its natural height
/// so the checks tab keeps a single scrollbar — no viewport nested inside
/// the accordion.
class _LogViewer extends ConsumerWidget {
  const _LogViewer({required this.text});

  final String text;

  /// Past this many lines (only reachable via the full log) the viewer falls
  /// back to one plain selectable text — folding every line into gutter +
  /// content rows costs ~3 widgets per line.
  static const int _maxFoldingLines = 2000;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final folds = '\n'.allMatches(text).length <= _maxFoldingLines;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 12, 10),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: tokens.bgPrimary,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: tokens.borderSecondary),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: folds
              ? JobLogBody(text: text)
              : CcSelectionRegion(
                  child: Text(
                    text,
                    style: AppFonts.codeStyleDynamic(
                      ref.watch(codeFontFamilyProvider),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
