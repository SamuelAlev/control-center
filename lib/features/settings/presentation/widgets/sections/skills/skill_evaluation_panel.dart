import 'package:cc_data/cc_data.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/skills/skill_evaluation_dialog.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/skill_evaluation/skill_campaign_error.dart';
import 'package:control_center/shared/skill_evaluation/skill_campaign_providers.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

part 'skill_evaluation_panel_sections.dart';
part 'skill_evaluation_panel_state.dart';

/// Separate behavioral evidence from the installed skill's security scan.
class SkillEvaluationPanel extends ConsumerStatefulWidget {
  /// Creates evaluation controls for the installed revision of one skill.
  const SkillEvaluationPanel({
    required this.workspaceId,
    required this.slug,
    required this.currentHash,
    required this.availableSkills,
    required this.dirty,
    super.key,
  });

  /// Workspace containing the skill and its evaluation history.
  final String workspaceId;

  /// Workspace skill slug used to scope campaigns and automatic policy.
  final String slug;

  /// Content hash of the installed revision, used to identify stale evidence.
  final String currentHash;

  /// Installed skill slugs offered for composition comparisons.
  final List<String> availableSkills;

  /// Whether the editor has unsaved changes that must not be evaluated.
  final bool dirty;
  @override
  ConsumerState<SkillEvaluationPanel> createState() =>
      _SkillEvaluationPanelState();
}

/// Whether a finished campaign left planned trials unobserved.
bool _isPartial(SkillCampaignView campaign) =>
    campaign.status == SkillCampaignStatus.completed &&
    campaign.report?['coverageComplete'] != true;

String _evidenceStatus(AppLocalizations l, SkillCampaignView campaign) {
  if (campaign.staleReason != null) {
    return l.skillEvalStale;
  }
  return _isPartial(campaign)
      ? l.skillEvalPartial
      : _status(l, campaign.status);
}

CcStatusTone _evidenceTone(SkillCampaignView campaign) {
  if (campaign.staleReason != null) {
    return CcStatusTone.caution;
  }
  return switch (campaign.status) {
    SkillCampaignStatus.completed =>
      _isPartial(campaign) ? CcStatusTone.caution : CcStatusTone.positive,
    SkillCampaignStatus.running => CcStatusTone.positive,
    SkillCampaignStatus.failed => CcStatusTone.negative,
    SkillCampaignStatus.interrupted => CcStatusTone.caution,
    SkillCampaignStatus.queued ||
    SkillCampaignStatus.cancelling ||
    SkillCampaignStatus.cancelled => CcStatusTone.neutral,
  };
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
