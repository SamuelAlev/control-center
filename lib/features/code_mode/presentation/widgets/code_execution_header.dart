import 'package:cc_domain/features/code_mode/domain/entities/code_execution.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/code_mode/presentation/code_mode_copy.dart';
import 'package:control_center/features/code_mode/presentation/widgets/code_execution_end_reason.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/human_bytes.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:control_center/shared/widgets/transcript/widgets/script_body.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;

/// The top of an execution record: how it ended and what it was for, then
/// when, how long, who ran it and where, with the ways to the conversation,
/// the run's other scripts and the agent's other scripts.
///
/// A run has no page of its own, so "the run" link is the list scoped to it.
class CodeExecutionHeader extends ConsumerWidget {
  /// Creates the header of [execution].
  const CodeExecutionHeader({
    super.key,
    required this.workspaceId,
    required this.execution,
    required this.settledCalls,
    required this.onBack,
    this.errorName,
  });

  /// The workspace the record belongs to.
  final String workspaceId;

  /// The record.
  final CodeExecution execution;

  /// How many of its calls the record holds. A running script's counts are
  /// set when it ends, so until then the calls settled so far are counted.
  final int settledCalls;

  /// The name of the error the script threw, from its payload.
  final String? errorName;

  /// Steps back to the list.
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final e = execution;
    final state = scriptRunStateOf(e.status);
    final agentName = e.agentId == null
        ? null
        : (ref.watch(workspaceAgentsProvider(workspaceId)).value ?? const [])
              .where((a) => a.id == e.agentId)
              .firstOrNull
              ?.name;
    final title = e.description.trim().isEmpty
        ? l10n.codeExecutionUntitled
        : e.description.trim();
    final spaceId = e.spaceId;
    final conversationId = e.conversationId;
    final errorKind = e.errorKind;
    final running = e.status == CodeExecutionStatus.running;
    final peak = e.peakHeapBytes;
    final cpu = e.cpuMs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CcButton(
                        variant: CcButtonVariant.secondary,
                        size: CcButtonSize.sm,
                        icon: AppIcons.arrowLeft,
                        onPressed: onBack,
                        child: Text(l10n.back),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      CcStatusTag(
                        label: scriptStateLabel(l10n, state),
                        tone: scriptStateTone(state),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    title,
                    style: CcTypography.title.copyWith(color: t.textPrimary),
                  ),
                  if (!running &&
                      e.status.isError &&
                      errorKind != null &&
                      errorKind.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    CodeExecutionEndReason(
                      errorKind: errorKind,
                      errorName: errorName,
                    ),
                  ],
                  if (running) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.codeExecutionRunningNote,
                      style: CcTypography.bodySm.copyWith(
                        color: t.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.xl,
          runSpacing: AppSpacing.md,
          children: [
            _Fact(
              label: l10n.codeExecutionFactStarted,
              child: AppTimestamp(
                dateTime: e.startedAt,
                child: Text(
                  DateFormat.yMMMd(
                    Localizations.localeOf(context).toString(),
                  ).add_Hms().format(e.startedAt.toLocal()),
                ),
              ),
            ),
            // A running script has no duration yet.
            if (!running)
              _Fact(
                label: l10n.codeExecutionFactDuration,
                child: Text(formatScriptDuration(l10n, e.durationMs)),
              ),
            _Fact(
              label: l10n.codeExecutionFactCalls,
              child: Text(
                l10n.scriptCallCount(
                  running ? settledCalls : e.callCounts.total,
                ),
              ),
            ),
            if (agentName != null)
              _Fact(label: l10n.codeExecutionFactAgent, child: Text(agentName)),
            _Fact(
              label: l10n.codeExecutionFactSurface,
              child: Text(switch (e.surface) {
                CodeExecutionSurface.harness =>
                  l10n.codeExecutionSurfaceHarness,
                CodeExecutionSurface.mcp => l10n.codeExecutionSurfaceMcp,
              }),
            ),
            if (cpu != null && !running)
              _Fact(
                label: l10n.codeExecutionFactCpu,
                child: Text(formatScriptDuration(l10n, cpu)),
              ),
            if (peak != null && !running)
              _Fact(
                label: l10n.codeExecutionFactMemory,
                child: Text(humanBytes(peak)),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            if (spaceId != null && conversationId != null)
              _Link(
                icon: AppIcons.messageSquare,
                label: l10n.codeExecutionOpenConversation,
                location: spaceRoute(
                  workspaceId,
                  spaceId,
                  tab: conversationTabKey(conversationId),
                ),
              ),
            _Link(
              icon: AppIcons.activity,
              label: l10n.codeExecutionRunScripts,
              location: codeExecutionsRoute(workspaceId, runId: e.runId),
            ),
            if (e.agentId case final agentId?)
              _Link(
                icon: AppIcons.bot,
                label: l10n.codeExecutionAgentScripts,
                location: codeExecutionsRoute(workspaceId, agentId: agentId),
              ),
          ],
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: CcTypography.caption.copyWith(color: t.textTertiary),
        ),
        const SizedBox(height: AppSpacing.xxs),
        DefaultTextStyle.merge(
          style: CcTypography.bodySm.copyWith(color: t.textPrimary),
          child: child,
        ),
      ],
    );
  }
}

class _Link extends StatelessWidget {
  const _Link({
    required this.icon,
    required this.label,
    required this.location,
  });

  final IconData icon;
  final String label;
  final String location;

  @override
  Widget build(BuildContext context) => CcButton(
    variant: CcButtonVariant.secondary,
    size: CcButtonSize.sm,
    icon: icon,
    onPressed: () => context.go(location),
    child: Text(label),
  );
}
