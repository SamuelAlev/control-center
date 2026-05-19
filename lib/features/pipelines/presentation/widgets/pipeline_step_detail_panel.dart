import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_run_formatting.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_status_badge.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:control_center/shared/widgets/artifacts/json_tree_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Side panel describing one selected step's run: status, timing, branch index,
/// a promoted failure / skip reason and the raw input/output payloads behind a
/// disclosure. Shared by the run-detail timeline and the graph canvas so a step
/// always reads the same wherever it is opened.
class PipelineStepDetailPanel extends ConsumerWidget {
  /// Creates a [PipelineStepDetailPanel].
  const PipelineStepDetailPanel({
    super.key,
    required this.step,
    required this.stepRun,
    required this.now,
    this.onClose,
    this.elevated = true,
    this.bordered = true,
  });

  /// The step definition (for its friendly label), if resolvable.
  final PipelineStepDefinition? step;

  /// The latest run of that step, if it executed.
  final PipelineStepRun? stepRun;

  /// Current time for live duration display.
  final DateTime now;

  /// Invoked when the panel's close affordance is used. When null the close
  /// button is hidden — used by the inline timeline split where there is
  /// always a selected step.
  final VoidCallback? onClose;

  /// Whether to render a drop shadow. True for the floating graph overlay;
  /// false for the in-flow timeline split, where a 1px border does the work.
  final bool elevated;

  /// Whether to draw the panel's own border + corner radius. False when the
  /// panel IS the page's right sidebar: the resizable seam is the only edge it
  /// needs and card chrome inside a docked sidebar reads as a floating card
  /// that failed to float.
  final bool bordered;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final s = step;
    final liveStatus = stepRun?.status;
    final isLive =
        liveStatus == PipelineStepStatus.running ||
        liveStatus == PipelineStepStatus.suspended ||
        liveStatus == PipelineStepStatus.pending;

    return Container(
      decoration: BoxDecoration(
        color: tokens.bgPrimary,
        border: bordered ? Border.all(color: tokens.borderSecondary) : null,
        borderRadius: bordered ? AppRadii.brLg : null,
        boxShadow: elevated ? AppShadows.golden : null,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    s?.config.label ?? s?.id ?? '—',
                    style: TextStyle(
                      color: tokens.textPrimary,
                      fontSize: 15,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                AppSpacing.hGapSm,
                if (isLive && stepRun != null)
                  CcIconButton(
                    icon: AppIcons.square,
                    tooltip: l10n.killRunning,
                    onPressed: () => ref
                        .read(pipelineEngineProvider)
                        .killStep(context.currentWorkspaceId!, stepRun!.id),
                  ),
                if (onClose != null)
                  CcIconButton(
                    icon: AppIcons.x,
                    tooltip: l10n.close,
                    onPressed: onClose,
                  ),
              ],
            ),
            if (stepRun != null) ...[
              const SizedBox(height: AppSpacing.xs),
              PipelineStatusBadge.forStep(stepStatus: stepRun!.status),
            ],
            const SizedBox(height: AppSpacing.md),
            CcDivider(color: tokens.borderSecondary),
            const SizedBox(height: AppSpacing.md),
            // Long input/output JSON blocks blow past the panel's bounded
            // height — wrap the detail block in a scrollable region so the
            // panel never overflows its viewport.
            Expanded(
              child: stepRun == null
                  ? Text(
                      l10n.pipelineStepNotExecuted,
                      style: TextStyle(color: tokens.textTertiary),
                    )
                  : SingleChildScrollView(
                      child: _StepRunBody(
                        stepRun: stepRun!,
                        now: now,
                        tokens: tokens,
                        l10n: l10n,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepRunBody extends ConsumerWidget {
  const _StepRunBody({
    required this.stepRun,
    required this.now,
    required this.tokens,
    required this.l10n,
  });

  final PipelineStepRun stepRun;
  final DateTime now;
  final DesignSystemTokens tokens;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only a non-terminal step keeps ticking; a terminal one with no recorded
    // finish (e.g. a skipped branch) is frozen at zero rather than counting up.
    final duration = stepRun.finishedAt != null
        ? stepRun.finishedAt!.difference(stepRun.startedAt)
        : (stepRun.isTerminal
              ? Duration.zero
              : now.difference(stepRun.startedAt));

    // Surface the most important fact first: why this step failed or what it
    // skipped, lifted out of the raw payload so the operator never has to read
    // JSON to learn the outcome.
    final failureReason = _failureReason(stepRun);
    final skipReason = _skipReason(stepRun);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (failureReason != null) ...[
          _ReasonCallout(
            label: l10n.pipelineStepError,
            text: failureReason,
            fg: tokens.textErrorPrimary,
            bg: tokens.bgErrorPrimary,
            border: tokens.borderErrorSubtle,
            icon: AppIcons.circleAlert,
          ),
          const SizedBox(height: AppSpacing.md),
        ] else if (skipReason != null) ...[
          _ReasonCallout(
            label: l10n.pipelineStepSkippedReason,
            text: skipReason,
            fg: tokens.textWarningPrimary,
            bg: tokens.bgWarningPrimary,
            border: tokens.fgWarningSecondary,
            icon: AppIcons.triangleAlert,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        _MetaRow(
          label: l10n.pipelineStepStarted,
          value: formatPipelineDateTime(stepRun.startedAt),
          dateTime: stepRun.startedAt,
          tokens: tokens,
        ),
        if (stepRun.finishedAt != null)
          _MetaRow(
            label: l10n.pipelineStepFinished,
            value: formatPipelineDateTime(stepRun.finishedAt!),
            dateTime: stepRun.finishedAt,
            tokens: tokens,
          ),
        _MetaRow(
          label: l10n.pipelineStepDurationLabel,
          value: formatPipelineDuration(duration),
          tokens: tokens,
        ),
        if (stepRun.branchIndex != null)
          _MetaRow(
            label: l10n.pipelineStepBranch,
            value: '${stepRun.branchIndex}',
            tokens: tokens,
          ),
        if (stepRun.channelId != null) ...[
          const SizedBox(height: AppSpacing.md),
          CcButton(
            icon: AppIcons.messagesSquare,
            variant: CcButtonVariant.secondary,
            size: CcButtonSize.sm,
            onPressed: () {
              // Open the hidden pipeline-spawned conversation — the only entry
              // point, since these channels are filtered out of the sidebar.
              // The URL is the source of truth; MessagingScreen mirrors it into
              // the selection provider.
              GoRouter.of(context).go(
                channelRoute(context.currentWorkspaceId!, stepRun.channelId!),
              );
            },
            child: Text(l10n.pipelineStepViewConversation),
          ),
        ],
        if (stepRun.inputJson != null) ...[
          const SizedBox(height: AppSpacing.md),
          _CollapsibleJson(
            label: l10n.pipelineStepInput,
            raw: stepRun.inputJson!,
            tokens: tokens,
          ),
        ],
        if (stepRun.outputJson != null) ...[
          const SizedBox(height: AppSpacing.md),
          _CollapsibleJson(
            label: l10n.pipelineStepOutput,
            raw: stepRun.outputJson!,
            tokens: tokens,
          ),
        ],
        // What the step's agent(s) actually did — status, summary, duration,
        // and cost — so observability reaches past the step's terminal status.
        _AgentActivitySection(stepRun: stepRun, tokens: tokens, l10n: l10n),
      ],
    );
  }
}

/// Lists the agent run logs a step dispatched (empty for deterministic steps),
/// filtered from the run's logs by `pipelineStepRunId`. Surfaces each run's
/// status, summary, duration and cost — the "per-step live logs" observability
/// gap (§199): the step-runs stream already updates status/output live and
/// this adds the agent execution behind it.
class _AgentActivitySection extends ConsumerWidget {
  const _AgentActivitySection({
    required this.stepRun,
    required this.tokens,
    required this.l10n,
  });

  final PipelineStepRun stepRun;
  final DesignSystemTokens tokens;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read the route-driven active workspace via its provider (not
    // GoRouterState) so the panel renders even without a router above it
    // (widget tests, embedded previews).
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return const SizedBox.shrink();
    }
    final logsAsync = ref.watch(
      pipelineRunAgentLogsProvider((
        workspaceId: workspaceId,
        runId: stepRun.pipelineRunId,
      )),
    );
    final logs = (logsAsync.asData?.value ?? const <AgentRunLog>[])
        .where((l) => l.pipelineStepRunId == stepRun.id)
        .toList();
    if (logs.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.pipelineStepAgentActivity,
          style: TextStyle(
            color: tokens.textSecondary,
            fontSize: 12,
            height: 1.3,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final log in logs) ...[
          _AgentRunTile(log: log, tokens: tokens, l10n: l10n),
          const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }
}

/// One agent run within a step: a status icon, a localized status label, an
/// optional one-line summary and a duration + cost trailer.
class _AgentRunTile extends StatelessWidget {
  const _AgentRunTile({
    required this.log,
    required this.tokens,
    required this.l10n,
  });

  final AgentRunLog log;
  final DesignSystemTokens tokens;
  final AppLocalizations l10n;

  (IconData, Color, String) _status() => switch (log.status) {
    RunStatus.completed => (
      AppIcons.checkCircle,
      tokens.fgSuccessSecondary,
      l10n.runStatusCompleted,
    ),
    RunStatus.error => (
      AppIcons.circleAlert,
      tokens.textErrorPrimary,
      l10n.failed,
    ),
    RunStatus.running => (AppIcons.loader, tokens.textTertiary, l10n.running),
    RunStatus.pending => (
      AppIcons.clock,
      tokens.textTertiary,
      l10n.runStatusQueued,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = _status();
    final cents = log.totalCostCentsWithChildren;
    final trailer = <String>[
      if (log.completedAt != null)
        formatPipelineDuration(log.completedAt!.difference(log.startedAt)),
      if (cents > 0) '\$${(cents / 100).toStringAsFixed(2)}',
    ].join(' · ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: tokens.bgSecondary,
        border: Border.all(color: tokens.borderSecondary),
        borderRadius: AppRadii.brSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (trailer.isNotEmpty)
                Text(
                  trailer,
                  style: TextStyle(
                    color: tokens.textTertiary,
                    fontSize: 11,
                    height: 1.3,
                    fontFamily: CcFonts.codeFamily,
                  ),
                ),
            ],
          ),
          if (log.summary != null && log.summary!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              log.summary!.trim(),
              style: TextStyle(
                color: tokens.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The fatal reason a step failed, if any: an explicit error message, else a
/// recognizable error field mined from the output payload of a failed step.
String? _failureReason(PipelineStepRun sr) {
  final msg = sr.errorMessage?.trim();
  if (msg != null && msg.isNotEmpty) {
    return msg;
  }
  if (sr.status != PipelineStepStatus.failed) {
    return null;
  }
  return _stringField(sr.outputJson, const [
    'failureReason',
    'error',
    'reason',
    'message',
  ]);
}

/// A non-fatal skip note mined from the output payload (e.g. a step that
/// completed but skipped part of its work). Shown even on completed steps.
String? _skipReason(PipelineStepRun sr) {
  return _stringField(sr.outputJson, const ['skippedReason', 'skipReason']);
}

/// Returns the first non-empty string value among [keys] in a JSON object
/// payload, or null when [raw] is absent, not an object, or has no match.
String? _stringField(String? raw, List<String> keys) {
  if (raw == null) {
    return null;
  }
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      for (final key in keys) {
        final v = decoded[key];
        if (v is String && v.trim().isNotEmpty) {
          return v.trim();
        }
      }
    }
  } on Object {
    // Not JSON; nothing to promote.
  }
  return null;
}

/// A prominent, readable callout for a failure or skip reason, drawn above the
/// raw payloads so the outcome is legible without parsing JSON.
class _ReasonCallout extends StatelessWidget {
  const _ReasonCallout({
    required this.label,
    required this.text,
    required this.fg,
    required this.bg,
    required this.border,
    required this.icon,
  });

  final String label;
  final String text;
  final Color fg;
  final Color bg;
  final Color border;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: AppRadii.brSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          SelectableText(
            text,
            style: TextStyle(color: fg, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}

/// A label/value row in the step detail overview.
class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
    required this.tokens,
    this.dateTime,
  });

  final String label;
  final String value;
  final DesignSystemTokens tokens;

  /// The instant [value] renders, when it is a concrete timestamp (started /
  /// finished). Non-null rows attach the shared accessibility hover card;
  /// duration / branch rows leave it null.
  final DateTime? dateTime;

  @override
  Widget build(BuildContext context) {
    final Widget valueDisplay = Text(
      value,
      style: TextStyle(color: tokens.textPrimary, fontSize: 12, height: 1.4),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: TextStyle(
                color: tokens.textTertiary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
          Expanded(
            child: dateTime != null
                ? AppTimestamp(dateTime: dateTime!, child: valueDisplay)
                : valueDisplay,
          ),
        ],
      ),
    );
  }
}

/// A payload section that keeps the raw JSON behind a disclosure: the header
/// (a sentence-case label, a chevron and a copy button) is always visible, but
/// the pretty-printed blob is collapsed by default so the promoted reason and
/// the step's metadata lead. The operator expands it only when they want the
/// raw payload, so a large output never buries the rest of the panel.
class _CollapsibleJson extends StatefulWidget {
  const _CollapsibleJson({
    required this.label,
    required this.raw,
    required this.tokens,
  });

  final String label;
  final String raw;
  final DesignSystemTokens tokens;

  @override
  State<_CollapsibleJson> createState() => _CollapsibleJsonState();
}

class _CollapsibleJsonState extends State<_CollapsibleJson> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          expanded: _expanded,
          child: CcTappable(
            onPressed: () => setState(() => _expanded = !_expanded),
            builder: (context, states) => Row(
              children: [
                AnimatedRotation(
                  turns: _expanded ? 0 : -0.25,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    AppIcons.chevronDown,
                    size: 14,
                    color: tokens.fgQuaternary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: tokens.textSecondary,
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                _CopyButton(value: widget.raw, tokens: tokens),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: AppSpacing.xs),
          _JsonBlock(raw: widget.raw, tokens: tokens),
        ],
      ],
    );
  }
}

/// A step's JSON payload, rendered as a navigable tree.
///
/// Delegates to the shared [JsonTreeView] rather than pretty-printing into a
/// `SelectableText`: this panel used to be the only place in the app that showed
/// a structured agent output and it showed it as one flat blob. The artifact
/// system needed the same rendering, so the tree moved to `lib/shared/` and this
/// call site follows it.
class _JsonBlock extends StatelessWidget {
  const _JsonBlock({required this.raw, required this.tokens});

  final String raw;
  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: tokens.bgSecondary,
        border: Border.all(color: tokens.borderSecondary),
        borderRadius: AppRadii.brSm,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: JsonTreeView.fromRaw(raw),
      ),
    );
  }
}

/// Small copy-to-clipboard button that flips to a check mark briefly.
class _CopyButton extends StatefulWidget {
  const _CopyButton({required this.value, required this.tokens});

  final String value;
  final DesignSystemTokens tokens;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.value));
    if (!mounted) {
      return;
    }
    setState(() => _copied = true);
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CcIconButton(
      onPressed: _copy,
      size: CcButtonSize.sm,
      tooltip: _copied ? l10n.copied : l10n.copy,
      icon: _copied ? AppIcons.check : AppIcons.copy,
      color: _copied
          ? widget.tokens.fgSuccessSecondary
          : widget.tokens.fgQuaternary,
    );
  }
}
