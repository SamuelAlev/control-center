import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// Glyph for a trigger [eventType]: start-kind icons, then event-family icons.
IconData iconForTriggerEventType(String eventType) {
  return switch (eventType) {
    PipelineTrigger.manualEventType => AppIcons.play,
    PipelineTrigger.scheduleEventType => AppIcons.clock,
    PipelineTrigger.webhookEventType => AppIcons.plug,
    'PullRequestStatusChanged' => AppIcons.gitPullRequest,
    'PullRequestPublished' => AppIcons.gitPullRequestCreate,
    'PrMerged' => AppIcons.gitMerge,
    'ExternalPrDetected' => AppIcons.gitPullRequestArrow,
    'MessageReceived' => AppIcons.messageSquare,
    'TicketCreated' ||
    'TicketAssigned' ||
    'TicketCompleted' ||
    'TicketFailed' ||
    'TicketCancelled' ||
    'TicketStatusChanged' => AppIcons.ticket,
    'BudgetThresholdCrossed' => AppIcons.dollarSign,
    'RepoAdded' => AppIcons.folderGit2,
    'MeetingRecordingStopped' => AppIcons.mic,
    'SkillUpdated' => AppIcons.sparkles,
    'SpaceDeleted' => AppIcons.trash2,
    'SpaceArchived' => AppIcons.archive,
    'SpaceProvisioningChanged' => AppIcons.loader,
    'PrHeadChanged' => AppIcons.gitCommitHorizontal,
    'EnvironmentStatusChanged' => AppIcons.activity,
    'EnvironmentReady' => AppIcons.circleCheck,
    'EnvironmentDestroyed' => AppIcons.boxes,
    'EnvironmentProcessExited' => AppIcons.terminal,
    _ => AppIcons.zap,
  };
}
