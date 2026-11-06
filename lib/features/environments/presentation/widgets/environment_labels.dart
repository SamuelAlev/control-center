import 'package:cc_domain/features/environments/domain/entities/environment_run.dart';
import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_component.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// Whether an environment has anything to exec into or restart.
///
/// Failed counts: restarting the one part that broke is the reason to be here,
/// and the rest of the stack is usually still up.
bool environmentHasLiveParts(EnvironmentStatus status) =>
    status.isRunning || status == EnvironmentStatus.failed;

/// What a status capsule shows for [environment]: a start that stopped for a
/// person to do something on the host isn't broken, so it doesn't read as such.
(String, CcStatusTone) environmentDisplay(
  AppLocalizations l10n,
  SpaceEnvironment environment,
) =>
    environment.status == EnvironmentStatus.failed &&
        (environment.lastError?.needsHostSetup ?? false)
    ? (l10n.environmentNeedsSetup, CcStatusTone.caution)
    : environmentStatusDisplay(l10n, environment.status);

/// What a status capsule shows for an environment.
(String, CcStatusTone) environmentStatusDisplay(
  AppLocalizations l10n,
  EnvironmentStatus status,
) => switch (status) {
  EnvironmentStatus.creating ||
  EnvironmentStatus.starting => (l10n.rigPhaseStarting, CcStatusTone.caution),
  EnvironmentStatus.ready => (l10n.rigPhaseReady, CcStatusTone.positive),
  EnvironmentStatus.degraded => (
    l10n.environmentStatusDegraded,
    CcStatusTone.caution,
  ),
  EnvironmentStatus.failed => (l10n.failed, CcStatusTone.negative),
  EnvironmentStatus.stopped => (l10n.stopped, CcStatusTone.neutral),
  EnvironmentStatus.stopping => (
    l10n.environmentStatusStopping,
    CcStatusTone.caution,
  ),
  EnvironmentStatus.destroying => (
    l10n.environmentStatusDestroying,
    CcStatusTone.caution,
  ),
  EnvironmentStatus.gone => (l10n.environmentStatusGone, CcStatusTone.neutral),
};

/// What a status capsule shows for a component state.
(String, CcStatusTone) environmentComponentStateDisplay(
  AppLocalizations l10n,
  String state,
) => switch (state) {
  'pending' => (l10n.pipelineStatusPending, CcStatusTone.neutral),
  'starting' => (l10n.rigPhaseStarting, CcStatusTone.caution),
  'ready' => (l10n.rigPhaseReady, CcStatusTone.positive),
  'running' => (l10n.running, CcStatusTone.positive),
  'completed' => (l10n.pipelineStatusCompleted, CcStatusTone.positive),
  'stopped' => (l10n.stopped, CcStatusTone.neutral),
  'closed' => (l10n.closed, CcStatusTone.neutral),
  'crashed' => (l10n.environmentStateCrashed, CcStatusTone.negative),
  'failed' => (l10n.failed, CcStatusTone.negative),
  _ => (state, CcStatusTone.neutral),
};

/// What a run's status reads as.
(String, CcStatusTone) environmentRunStatusDisplay(
  AppLocalizations l10n,
  EnvironmentRunStatus status,
) => switch (status) {
  EnvironmentRunStatus.running => (l10n.running, CcStatusTone.caution),
  EnvironmentRunStatus.succeeded => (l10n.passed, CcStatusTone.positive),
  EnvironmentRunStatus.failed => (l10n.failed, CcStatusTone.negative),
  EnvironmentRunStatus.timedOut => (
    l10n.agentQuestionTimedOutLabel,
    CcStatusTone.negative,
  ),
};

/// A component kind's name.
String environmentKindLabel(AppLocalizations l10n, String kind) =>
    switch (kind) {
      'compose' => l10n.environmentKindCompose,
      'cli' => l10n.environmentKindCli,
      'process' => l10n.environmentKindProcess,
      'task' => l10n.environmentKindTask,
      'app' => l10n.environmentKindApp,
      _ => kind,
    };

/// When a task runs, in words.
String environmentTriggerLabel(
  AppLocalizations l10n,
  EnvironmentTaskTrigger trigger,
) => switch (trigger) {
  EnvironmentTaskTrigger.provision => l10n.environmentsTriggerProvision,
  EnvironmentTaskTrigger.create => l10n.environmentsTriggerCreate,
  EnvironmentTaskTrigger.start => l10n.environmentsTriggerStart,
  EnvironmentTaskTrigger.change => l10n.environmentsTriggerChange,
  EnvironmentTaskTrigger.manual => l10n.environmentsTriggerManual,
  EnvironmentTaskTrigger.archive => l10n.environmentsTriggerArchive,
};

/// What a component is, at a glance.
IconData environmentKindIcon(String kind) => switch (kind) {
  'compose' => AppIcons.layers,
  'process' => AppIcons.activity,
  'task' => AppIcons.scrollText,
  'cli' => AppIcons.terminal,
  'app' => AppIcons.appWindow,
  _ => AppIcons.boxes,
};
