import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/dispatch/domain/context/context_inspection.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/conversation_token_totals.dart';
import 'package:cc_remote/conversation_progress_model.dart';
import 'package:cc_remote/conversation_progress_providers.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/conversation_progress/progress_context_segment.dart';
import 'package:cc_remote/widgets/conversation_progress/progress_shared.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ProgressContext extends ConsumerStatefulWidget {
  const ProgressContext({
    required this.scope,
    required this.runs,
    required this.agents,
    required this.tokens,
    super.key,
  });

  final ProgressScope scope;
  final List<AgentRunLogDto> runs;
  final AsyncValue<List<AgentDto>> agents;
  final AsyncValue<ConversationTokenTotals> tokens;

  @override
  ConsumerState<ProgressContext> createState() => _ProgressContextState();
}

class _ProgressContextState extends ConsumerState<ProgressContext> {
  String? _selectedAgentId;

  @override
  Widget build(BuildContext context) {
    final scope = widget.scope;
    final l = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final agentList = (widget.agents.value ?? const <AgentDto>[])
        .where((a) => a.workspaceId == scope.workspaceId)
        .toList();
    final agentIds = {for (final run in widget.runs) run.agentId};
    final relevant = agentIds.isEmpty
        ? agentList
        : agentList.where((agent) => agentIds.contains(agent.id)).toList();
    final selected =
        relevant.where((a) => a.id == _selectedAgentId).firstOrNull ??
        relevant.firstOrNull;
    if (widget.agents.hasError) {
      return progressError(
        l,
        widget.agents.error!,
        () => ref.invalidate(agentsProvider),
      );
    }
    if (widget.agents.isLoading) return const CcSpinner(size: 18);
    if (selected == null) {
      return Text(
        l.progressNoAgent,
        style: CcTypography.bodySm.copyWith(color: t.textSecondary),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (relevant.length > 1) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final agent in relevant)
                CcButton(
                  size: CcButtonSize.lg,
                  variant: selected.id == agent.id
                      ? CcButtonVariant.line
                      : CcButtonVariant.secondary,
                  onPressed: () => setState(() => _selectedAgentId = agent.id),
                  child: Text(agent.name),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        _ContextReading(
          key: ValueKey(selected.id),
          scope: scope,
          agent: selected,
          tokens: widget.tokens,
        ),
      ],
    );
  }
}

class _ContextReading extends ConsumerStatefulWidget {
  const _ContextReading({
    required this.scope,
    required this.agent,
    required this.tokens,
    super.key,
  });

  final ProgressScope scope;
  final AgentDto agent;
  final AsyncValue<ConversationTokenTotals> tokens;

  @override
  ConsumerState<_ContextReading> createState() => _ContextReadingState();
}

class _ContextReadingState extends ConsumerState<_ContextReading> {
  ContextSegmentKind? _openedSegment;
  @override
  Widget build(BuildContext context) {
    final scope = widget.scope;
    final agent = widget.agent;
    final tokens = widget.tokens;
    final l = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final args = (scope: scope, agentId: agent.id, includeContent: false);
    final inspection = ref.watch(progressInspectionProvider(args));
    final persistent = inspection.value;
    final reading = progressContextReading(
      tokens.value,
      persistent,
      agent.contextSize,
    );
    final window = reading.windowTokens;
    final used = reading.usedTokens;
    final nf = NumberFormat.decimalPattern(l.localeName);
    String format(int? count) =>
        count == null ? l.progressUnknown : nf.format(count);
    final usedLabel = format(used);
    final windowLabel = window == null || window <= 0
        ? l.progressUnknown
        : nf.format(window);
    final percent = used == null || window == null || window <= 0
        ? null
        : (used / window * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.progressContextReading(usedLabel, windowLabel),
          style: CcTypography.body.copyWith(color: t.textPrimary),
        ),
        Text(
          reading.measured
              ? l.progressMeasured
              : used != null
              ? l.progressEstimated
              : l.progressContextUnknown,
          style: CcTypography.caption.copyWith(color: t.textSecondary),
        ),
        if (percent != null)
          Text(
            l.progressContextPercent(nf.format(percent)),
            style: CcTypography.bodySm.copyWith(color: t.textPrimary),
          ),
        if (agent.monthlyBudgetCents > 0)
          Text(
            l.progressMonthlyBudget(
              NumberFormat.currency(
                locale: l.localeName,
                symbol: '\$',
                decimalDigits: 2,
              ).format(agent.monthlyBudgetCents / 100),
            ),
            style: CcTypography.caption.copyWith(color: t.textSecondary),
          ),
        if (tokens.hasError)
          progressError(
            l,
            tokens.error!,
            () => ref.invalidate(progressTokensProvider(scope)),
          )
        else if (tokens.isLoading)
          const CcSpinner(size: 18)
        else
          Text(
            l.progressConversationTokens(format(tokens.value!.tokens)),
            style: CcTypography.bodySm.copyWith(color: t.textSecondary),
          ),
        if (inspection.hasError)
          progressError(
            l,
            inspection.error!,
            () => ref.invalidate(progressInspectionProvider(args)),
          )
        else if (inspection.isLoading)
          const CcSpinner(size: 18)
        else if (persistent != null) ...[
          Text(
            l.progressInspectionFor(
              persistent.agentName,
              persistent.modelId ?? l.progressUnknown,
            ),
            style: CcTypography.caption.copyWith(color: t.textSecondary),
          ),
          for (final segment in persistent.segments)
            ProgressContextSegment(
              scope: scope,
              agentId: agent.id,
              segment: segment,
              formatter: nf,
              open: _openedSegment == segment.kind,
              onToggle: () => setState(
                () => _openedSegment = _openedSegment == segment.kind
                    ? null
                    : segment.kind,
              ),
            ),
        ],
      ],
    );
  }
}
