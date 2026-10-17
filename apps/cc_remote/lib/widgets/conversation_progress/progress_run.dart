import 'dart:convert';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/conversation_progress_providers.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/widgets/conversation_progress/progress_shared.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

class ProgressRun extends StatelessWidget {
  const ProgressRun({
    required this.run,
    required this.depth,
    required this.scope,
    required this.agents,
    super.key,
  });

  final AgentRunLogDto run;
  final int depth;
  final ProgressScope scope;
  final List<AgentDto> agents;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final agent = agents.where((a) => a.id == run.agentId).firstOrNull;
    final status = switch (run.status) {
      'running' => l.progressRunning,
      'pending' => l.progressPending,
      'completed' => l.progressCompleted,
      'error' => l.progressFailed,
      _ => l.progressUnknown,
    };
    final started = DateTime.tryParse(run.startedAt);
    final completed = DateTime.tryParse(run.completedAt ?? '');
    final durationMs = run.status == 'running' && started != null
        ? DateTime.now().difference(started).inMilliseconds
        : run.durationMs ??
              (started == null || completed == null
                  ? null
                  : completed.difference(started).inMilliseconds);
    final duration = durationMs == null || durationMs < 0
        ? l.progressUnknown
        : l.progressDurationSeconds(
            NumberFormat.decimalPatternDigits(
              locale: l.localeName,
              decimalDigits: 1,
            ).format(durationMs / 1000),
          );
    // DTO zero is indistinguishable from an unpriced run. Never call it free.
    final cost = run.costMicros > 0
        ? run.costMicros
        : run.estimatedCostCents > 0
        ? run.estimatedCostCents * 10000
        : null;
    final price = cost == null
        ? l.progressUnknown
        : NumberFormat.currency(
            locale: l.localeName,
            symbol: '\$',
            decimalDigits: 4,
          ).format(cost / 1000000);
    final output = run.outputJson == null
        ? null
        : const JsonEncoder.withIndent('  ').convert(run.outputJson);
    final caption = CcTypography.caption.copyWith(color: t.textSecondary);
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: depth.clamp(0, 3) * 12.0,
        bottom: 8,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.bgPrimary,
          border: Border.all(color: t.borderSoft),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    run.status == 'error'
                        ? AppIcons.triangleAlert
                        : run.status == 'completed'
                        ? AppIcons.circleCheck
                        : AppIcons.loader,
                    size: 18,
                    color: t.textPrimary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      agent?.name ?? run.agentId,
                      style: CcTypography.bodySm.copyWith(
                        fontWeight: FontWeight.w600,
                        color: t.textPrimary,
                      ),
                    ),
                  ),
                  Text(status, style: caption),
                ],
              ),
              if (run.summary?.isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    run.summary!,
                    style: CcTypography.bodySm.copyWith(color: t.textPrimary),
                  ),
                ),
              if (run.errorFamily != null || run.errorCode != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    [?run.errorFamily, ?run.errorCode].join(' · '),
                    style: CcTypography.bodySm.copyWith(
                      color: t.textErrorPrimary,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                l.progressRunDetails(
                  run.modelId ?? l.progressUnknown,
                  duration,
                  price,
                ),
                style: caption,
              ),
              if (cost != null)
                Text(switch (run.costBasis) {
                  'providerReported' ||
                  'provider_reported' => l.progressCostReported,
                  'subscription' => l.progressCostNotional,
                  'mixed' => l.progressCostMixed,
                  _ => l.progressCostEstimated,
                }, style: caption),
              if (started != null)
                Text(
                  l.progressStartedAt(
                    DateFormat.yMMMd(
                      l.localeName,
                    ).add_jm().format(started.toLocal()),
                  ),
                  style: caption,
                ),
              if (run.liveness != null)
                Text(
                  l.progressLiveness(switch (run.liveness) {
                    'alive' || 'productive' => l.progressHealthy,
                    'blocked' => l.progressBlocked,
                    'looping' => l.progressLooping,
                    'stalled' => l.progressStalled,
                    'dead' => l.progressDead,
                    'failed' => l.progressFailed,
                    'completed' => l.progressCompleted,
                    'empty' => l.progressQuiet,
                    _ => l.progressUnknown,
                  }),
                  style: caption,
                ),
              if (run.retryOfRunId != null)
                Text(
                  l.progressRetryOf(run.retryOfRunId!),
                  textDirection: TextDirection.ltr,
                  style: caption,
                ),
              if (run.inputTokens > 0 || run.outputTokens > 0)
                Text(
                  l.progressRunTokens(
                    NumberFormat.decimalPattern(
                      l.localeName,
                    ).format(run.inputTokens),
                    NumberFormat.decimalPattern(
                      l.localeName,
                    ).format(run.outputTokens),
                  ),
                  style: caption,
                ),
              if (output != null) ...[
                const SizedBox(height: 8),
                Text(
                  l.output,
                  style: CcTypography.bodySm.copyWith(color: t.textPrimary),
                ),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: SelectableRegion(
                    selectionControls: emptyTextSelectionControls,
                    child: Text(
                      progressPreview(output),
                      style: CcFonts.code(
                        textStyle: CcTypography.monoNum.copyWith(
                          color: t.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                if (output.length > 6000)
                  Text(l.progressOutputPreviewLimited, style: caption),
              ],
              const SizedBox(height: 8),
              CcButton(
                size: CcButtonSize.lg,
                variant: CcButtonVariant.secondary,
                onPressed: () => context.push(
                  remoteSpaceLocation(
                    workspaceId: scope.workspaceId,
                    spaceId: scope.spaceId,
                    conversationId: scope.conversationId,
                  ),
                ),
                child: Text(l.openConversation),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
