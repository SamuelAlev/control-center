import 'dart:ui' as ui;

import 'package:cc_data/cc_data.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/observability/presentation/widgets/sections/skill_attempt_timeline.dart';
import 'package:control_center/features/observability/presentation/widgets/sections/skill_behavior_summary.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/skill_evaluation/skill_campaign_error.dart';
import 'package:control_center/shared/skill_evaluation/skill_campaign_providers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

part 'skill_campaign_detail_attempts.dart';
part 'skill_campaign_detail_report.dart';

/// Live campaign evidence; partial and stale runs are never presented as verdicts.
class SkillCampaignDetail extends ConsumerStatefulWidget {
  /// Creates a live detail view seeded with the selected campaign snapshot.
  const SkillCampaignDetail({
    required this.workspaceId,
    required this.campaignId,
    required this.initial,
    super.key,
  });

  /// Workspace whose membership authorizes campaign reads and actions.
  final String workspaceId;

  /// Campaign whose progress and attempt evidence are displayed.
  final String campaignId;

  /// Snapshot shown until the live subscription supplies the campaign.
  final SkillCampaignView initial;
  @override
  ConsumerState<SkillCampaignDetail> createState() =>
      _SkillCampaignDetailState();
}

class _SkillCampaignDetailState extends ConsumerState<SkillCampaignDetail> {
  bool _busy = false;
  Object? _error;
  String? _attemptId;
  int _refreshEpoch = 0;

  Future<void> _cancel() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(skillCampaignClientProvider)
          .cancelCampaign(widget.workspaceId, widget.campaignId);
    } catch (error) {
      if (mounted) {
        setState(() => _error = error);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _export() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final bundle = await ref
          .read(skillCampaignClientProvider)
          .exportCampaign(widget.workspaceId, widget.campaignId);
      await Clipboard.setData(ClipboardData(text: bundle.content));
      if (mounted) {
        CcToastScope.maybeOf(context)?.show(
          AppLocalizations.of(context).skillEvalExportCopied(bundle.filename),
          variant: CcToastVariant.success,
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final snapshotScope = (
      workspaceId: widget.workspaceId,
      campaignId: widget.campaignId,
    );
    final snapshot = ref.watch(skillCampaignProvider(snapshotScope));
    if (isSkillCampaignDenied(snapshot.error)) {
      return Text(skillCampaignError(l, snapshot.error!));
    }
    if (snapshot.asData != null && snapshot.asData!.value == null) {
      return Text(l.skillEvalUnavailable(l.skillEvalUnknown));
    }
    final c = snapshot.asData?.value ?? widget.initial;
    final report = c.report;
    final settledEvidence =
        c.status == SkillCampaignStatus.completed &&
        c.staleReason == null &&
        report?['coverageComplete'] == true;
    final percent = NumberFormat.percentPattern(
      Localizations.localeOf(context).toString(),
    );
    final number = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );
    final money = NumberFormat.currency(
      locale: Localizations.localeOf(context).toString(),
      symbol: r'$',
      decimalDigits: 4,
    );
    final attempts = ref.watch(skillAttemptsProvider(snapshotScope));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${c.skillSlug} · ${_comparison(l, c.comparison)} · '
          '${c.adapter == 'claude-cli' ? l.guardrailAdapterClaudeCli : l.guardrailAdapterHarness} · ${c.modelId}',
          style: CcTypography.bodySm.copyWith(color: t.textPrimary),
        ),
        Text(
          c.staleReason != null
              ? l.skillEvalStale
              : c.status == SkillCampaignStatus.completed && !settledEvidence
              ? l.skillEvalPartial
              : _campaignStatus(l, c.status),
          style: CcTypography.caption.copyWith(color: t.textSecondary),
        ),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            Text(
              l.skillEvalCurrentHash(''),
              style: CcTypography.caption.copyWith(color: t.textSecondary),
            ),
            // RTL carve-out: package hashes are code-like identifiers.
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                c.skillHash,
                textDirection: ui.TextDirection.ltr,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: CcTypography.caption.copyWith(color: t.textSecondary),
              ),
            ),
          ],
        ),
        Text(
          l.skillEvalProgress(c.completedAttempts, c.plannedAttempts),
          style: CcTypography.caption.copyWith(color: t.textSecondary),
        ),
        Text(
          l.skillEvalSpend(
            c.spentMicros == null
                ? l.skillEvalUnknown
                : money.format(c.spentMicros! / 1000000),
            money.format(c.budgetMicros / 1000000),
          ),
          style: CcTypography.caption.copyWith(color: t.textSecondary),
        ),
        if (c.adapter == 'claude-cli' ||
            (c.configuration['modelPin'] as Map?)?['budgetEnforcement'] ==
                'stop_after_call')
          Text(
            l.skillEvalUsageBudgetNote,
            style: CcTypography.caption.copyWith(color: t.textSecondary),
          ),
        if (c.staleReason != null) Text(l.skillEvalStaleReason(c.staleReason!)),
        if (c.error != null) Text(l.skillEvalUnavailable(c.error!)),
        if (snapshot.hasError) Text(skillCampaignError(l, snapshot.error!)),
        if (snapshot.asData?.value == null && snapshot.isLoading)
          Text(l.skillEvalReconnecting),
        if (_error != null) Text(skillCampaignError(l, _error!)),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            if (!c.isTerminal)
              CcButton(
                size: CcButtonSize.sm,
                variant: CcButtonVariant.destructive,
                onPressed: _busy ? null : _cancel,
                child: Text(l.skillEvalCancel),
              ),
            CcButton(
              size: CcButtonSize.sm,
              variant: CcButtonVariant.secondary,
              onPressed: _busy ? null : _export,
              child: Text(l.skillEvalExport),
            ),
            CcButton(
              size: CcButtonSize.sm,
              variant: CcButtonVariant.ghost,
              onPressed: () {
                ref.invalidate(skillCampaignProvider(snapshotScope));
                ref.invalidate(skillAttemptsProvider(snapshotScope));
                setState(() => _refreshEpoch++);
              },
              child: Text(l.skillEvalRefresh),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _CampaignReport(
          report: report,
          settledEvidence: settledEvidence,
          percent: percent,
          number: number,
          money: money,
        ),
        const SizedBox(height: AppSpacing.md),
        _CampaignAttempts(
          attempts: attempts,
          workspaceId: widget.workspaceId,
          campaignId: widget.campaignId,
          attemptId: _attemptId,
          refreshEpoch: _refreshEpoch,
          onSelectAttempt: (id) => setState(() => _attemptId = id),
        ),
      ],
    );
  }
}
