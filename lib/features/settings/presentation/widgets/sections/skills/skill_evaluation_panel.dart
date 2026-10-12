import 'dart:ui' as ui;

import 'package:cc_data/cc_data.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/skill_evaluation/skill_campaign_providers.dart';
import 'package:control_center/shared/skill_evaluation/skill_campaign_error.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/skills/skill_evaluation_dialog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Separate behavioral evidence from the installed skill's security scan.
class SkillEvaluationPanel extends ConsumerStatefulWidget {
  const SkillEvaluationPanel({
    required this.workspaceId,
    required this.slug,
    required this.currentHash,
    required this.availableSkills,
    required this.dirty,
    super.key,
  });
  final String workspaceId, slug, currentHash;
  final List<String> availableSkills;
  final bool dirty;
  @override
  ConsumerState<SkillEvaluationPanel> createState() =>
      _SkillEvaluationPanelState();
}

class _SkillEvaluationPanelState extends ConsumerState<SkillEvaluationPanel> {
  bool _busy = false;
  Object? _error;
  String? _policyCampaignId;
  String get _skillKey => 'workspace:${widget.slug}';
  ({String workspaceId, String? skillKey}) get _scope =>
      (workspaceId: widget.workspaceId, skillKey: _skillKey);

  void _quality(String? id) {
    final route = observabilityRoute(widget.workspaceId);
    context.go(
      '$route?tab=quality${id == null ? '' : '&campaign=${Uri.encodeQueryComponent(id)}'}',
    );
  }

  Future<void> _start(List<SkillCampaignView> history) async {
    final result = await showSkillEvaluationDialog(
      context,
      workspaceId: widget.workspaceId,
      skillSlug: widget.slug,
      currentHash: widget.currentHash,
      availableSkills: widget.availableSkills,
      history: history,
    );
    if (mounted && result != null) _quality(result.id);
  }

  Future<void> _policy(
    SkillCampaignPolicyView? policy,
    SkillCampaignView? template,
  ) async {
    if (_busy) return;
    final enabled = policy?.enabled != true;
    if (enabled && template == null) return;
    final config = enabled
        ? <String, dynamic>{
            'skillSlug': widget.slug,
            'corpusId': template!.corpusId,
            'adapter': template.adapter,
            'providerId': template.providerId,
            'modelId': template.modelId,
            'comparison': template.comparison.name,
            'repetitions': template.repetitions,
            'budgetMicros': template.budgetMicros,
            if (template.baselineHash != null)
              'baselineHash': template.baselineHash,
            if (template.configuration['ambientSkillSlugs'] is List)
              'ambientSkillSlugs': template.configuration['ambientSkillSlugs'],
          }
        : policy!.configuration;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(skillCampaignClientProvider)
          .setSkillPolicy(
            workspaceId: widget.workspaceId,
            skillKey: _skillKey,
            enabled: enabled,
            configuration: config,
          );
      ref.invalidate(
        skillCampaignPolicyProvider((
          workspaceId: widget.workspaceId,
          skillKey: _skillKey,
        )),
      );
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final readOnly = ref.watch(isDemoServerProvider);
    final history = ref.watch(skillCampaignsProvider(_scope));
    final policy = ref.watch(
      skillCampaignPolicyProvider((
        workspaceId: widget.workspaceId,
        skillKey: _skillKey,
      )),
    );
    final campaigns = [...?history.asData?.value]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final current = campaigns
        .where(
          (c) =>
              c.skillHash == widget.currentHash &&
              widget.currentHash.isNotEmpty,
        )
        .toList();
    final latest = current.firstOrNull;
    final reason = widget.dirty
        ? l.skillEvalUnsaved
        : widget.currentHash.isEmpty
        ? null
        : current.isEmpty
        ? l.skillEvalNotEvaluated
        : latest!.staleReason;
    final template =
        current.where((c) => c.id == _policyCampaignId).firstOrNull ??
        current.firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Text(
          l.skillEvalTitle,
          style: CcTypography.label.copyWith(color: t.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (widget.currentHash.isEmpty)
          Text(
            l.skillEvalHashUnavailable,
            style: CcTypography.caption.copyWith(color: t.textSecondary),
          )
        else
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
                  widget.currentHash,
                  textDirection: ui.TextDirection.ltr,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: CcTypography.caption.copyWith(color: t.textSecondary),
                ),
              ),
            ],
          ),
        const SizedBox(height: AppSpacing.sm),
        if (history.isLoading && history.asData == null) const CcSpinner(),
        if (history.hasError) Text(skillCampaignError(l, history.error!)),
        if (current.isEmpty &&
            campaigns.isNotEmpty &&
            widget.currentHash.isNotEmpty)
          Text(
            l.skillEvalStale,
            style: CcTypography.caption.copyWith(color: t.textSecondary),
          ),
        if (reason != null)
          Text(
            reason,
            style: CcTypography.bodySm.copyWith(color: t.textSecondary),
          ),
        if (latest != null) ...[
          Text(
            '${_evidenceStatus(l, latest)} · '
            '${l.skillEvalProgress(latest.completedAttempts, latest.plannedAttempts)} · ${latest.modelId}',
            style: CcTypography.bodySm.copyWith(color: t.textPrimary),
          ),
          Text(
            l.skillEvalCoverage(latest.corpusId, latest.repetitions),
            style: CcTypography.caption.copyWith(color: t.textSecondary),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            CcButton(
              size: CcButtonSize.sm,
              onPressed:
                  readOnly ||
                      widget.dirty ||
                      widget.currentHash.isEmpty ||
                      history.hasError
                  ? null
                  : () => _start(campaigns),
              child: Text(l.skillEvalStart),
            ),
            CcButton(
              size: CcButtonSize.sm,
              variant: CcButtonVariant.secondary,
              onPressed: () => _quality(latest?.id),
              child: Text(l.skillEvalOpenQuality),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l.skillEvalPolicyNote,
          style: CcTypography.caption.copyWith(color: t.textSecondary),
        ),
        if (current.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          CcSelect<String>(
            label: l.skillEvalPolicyTemplate,
            value: template?.id,
            options: [
              for (final c in current)
                CcSelectOption(
                  value: c.id,
                  label:
                      '${c.corpusId} · ${c.modelId} · ${_evidenceStatus(l, c)}',
                ),
            ],
            onChanged: (id) => setState(() => _policyCampaignId = id),
          ),
        ],
        if (policy.hasError) Text(skillCampaignError(l, policy.error!)),
        CcButton(
          size: CcButtonSize.sm,
          variant: CcButtonVariant.secondary,
          onPressed:
              readOnly ||
                  widget.dirty ||
                  policy.isLoading ||
                  policy.hasError ||
                  _busy ||
                  (policy.asData?.value?.enabled != true && template == null)
              ? null
              : () => _policy(policy.asData?.value, template),
          child: Text(
            policy.asData?.value?.enabled == true
                ? l.skillEvalDisableUpdates
                : l.skillEvalEnableUpdates,
          ),
        ),
        if (template == null && policy.asData?.value?.enabled != true)
          Text(
            l.skillEvalPolicyNeedsCampaign,
            style: CcTypography.caption.copyWith(color: t.textSecondary),
          ),
        if (_error != null) Text(skillCampaignError(l, _error!)),
        if (campaigns.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            l.skillEvalHistory,
            style: CcTypography.label.copyWith(color: t.textPrimary),
          ),
          for (final c in campaigns.take(8))
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: CcButton(
                size: CcButtonSize.sm,
                variant: CcButtonVariant.ghost,
                onPressed: () => _quality(c.id),
                child: Text(
                  '${c.skillHash.length > 12 ? c.skillHash.substring(0, 12) : c.skillHash} · ${_evidenceStatus(l, c)} · ${c.modelId}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

String _evidenceStatus(AppLocalizations l, SkillCampaignView campaign) {
  if (campaign.staleReason != null) return l.skillEvalStale;
  if (campaign.status == SkillCampaignStatus.completed &&
      campaign.report?['coverageComplete'] != true)
    return l.skillEvalPartial;
  return _status(l, campaign.status);
}

String _status(AppLocalizations l, SkillCampaignStatus status) =>
    switch (status) {
      SkillCampaignStatus.queued => l.skillEvalQueued,
      SkillCampaignStatus.running => l.skillEvalRunning,
      SkillCampaignStatus.cancelling => l.skillEvalCancelling,
      SkillCampaignStatus.cancelled => l.skillEvalCancelled,
      SkillCampaignStatus.completed => l.skillEvalCompleted,
      SkillCampaignStatus.failed => l.skillEvalFailed,
      SkillCampaignStatus.interrupted => l.skillEvalInterrupted,
    };
