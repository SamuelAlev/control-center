import 'dart:ui' as ui;

import 'package:cc_data/cc_data.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/skills/skill_evaluation_dialog.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/skill_evaluation/skill_campaign_error.dart';
import 'package:control_center/shared/skill_evaluation/skill_campaign_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

String _evidenceStatus(AppLocalizations l, SkillCampaignView campaign) {
  if (campaign.staleReason != null) {
    return l.skillEvalStale;
  }
  if (campaign.status == SkillCampaignStatus.completed &&
      campaign.report?['coverageComplete'] != true) {
    return l.skillEvalPartial;
  }
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
