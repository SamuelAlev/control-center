/// The localized words of the Goals, Schedules and Improvements pages: the
/// improvement refusal kinds, the labels of an improvement's kind, scope and
/// status, and the one failure path every action on these pages shares.
///
/// A refusal is read by its `data.kind`, never by the server's message text;
/// an unknown kind shows the generic lead-in and the raw kind.
library;

import 'package:cc_domain/features/dispatch/domain/value_objects/improvement_evaluation_summary.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/improvement_values.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_kind_text.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/utils/failure_message.dart';
import 'package:flutter/widgets.dart';

/// An improvement refusal (`data.kind` from `improvements.*`).
String? improvementRefusalSentence(AppLocalizations l10n, String? kind) =>
    switch (kind) {
      'improvement_already_decided' => l10n.improvementRefusalAlreadyDecided,
      'improvement_campaign_required' =>
        l10n.improvementRefusalCampaignRequired,
      'improvement_changed_since' => l10n.improvementRefusalChangedSince,
      'improvement_target_missing' => l10n.improvementRefusalTargetMissing,
      'improvement_campaign_state' => l10n.improvementRefusalCampaignState,
      'improvement_review_cooldown' => l10n.improvementRefusalReviewCooldown,
      'improvement_admin_required' => l10n.improvementRefusalAdminRequired,
      _ => null,
    };

/// The sentence for any refusal these pages may meet: an improvement's, a
/// goal's, a schedule's or a wake's, a storage refusal, else the generic
/// lead-in with the raw kind.
String dispatchRefusalMessage(AppLocalizations l10n, String kind) =>
    improvementRefusalSentence(l10n, kind) ??
    (kind == 'wake_not_yours' ? l10n.wakeRuleRefusalNotYours : null) ??
    storageRefusalMessageForKind(l10n, kind) ??
    workRefusalMessage(l10n, kind);

/// What a failed action or load says: the refusal's sentence by its kind,
/// else the shared failure wording (a demo server's refusal included).
String dispatchFailureMessage(AppLocalizations l10n, Object error) {
  final kind = refusalKindOf(error);
  return kind == null
      ? failureMessage(l10n, error)
      : dispatchRefusalMessage(l10n, kind);
}

/// Shows a failed action as a danger toast.
void showDispatchFailure(BuildContext context, Object error) {
  if (!context.mounted) {
    return;
  }
  CcToastScope.maybeOf(context)?.show(
    dispatchFailureMessage(AppLocalizations.of(context), error),
    variant: CcToastVariant.danger,
  );
}

/// Shows a quiet confirmation.
void showDispatchNotice(BuildContext context, String message) {
  if (context.mounted) {
    CcToastScope.maybeOf(context)?.show(message);
  }
}

/// Runs [call]; a refusal shows its sentence. True when it succeeded.
Future<bool> runDispatchAction(
  BuildContext context,
  Future<Object?> Function() call, {
  String? done,
}) async {
  try {
    await call();
  } on Object catch (e) {
    if (context.mounted) {
      showDispatchFailure(context, e);
    }
    return false;
  }
  if (done != null && context.mounted) {
    showDispatchNotice(context, done);
  }
  return true;
}

/// What an improvement changes, as a label.
String improvementKindLabel(AppLocalizations l10n, ImprovementKind kind) =>
    switch (kind) {
      ImprovementKind.memoryFact => l10n.improvementKindMemoryFact,
      ImprovementKind.policy => l10n.improvementKindPolicy,
      ImprovementKind.agentNote => l10n.improvementKindAgentNote,
      ImprovementKind.skillEdit => l10n.improvementKindSkillEdit,
      ImprovementKind.skillNew => l10n.improvementKindSkillNew,
    };

/// Where an improvement applies, as a label.
String improvementScopeLabel(AppLocalizations l10n, ImprovementScope scope) =>
    switch (scope) {
      ImprovementScope.agent => l10n.improvementScopeAgent,
      ImprovementScope.repository => l10n.improvementScopeRepository,
      ImprovementScope.workspace => l10n.improvementScopeWorkspace,
    };

/// An improvement's status, as a label.
String improvementStatusLabel(
  AppLocalizations l10n,
  ImprovementStatus status,
) => switch (status) {
  ImprovementStatus.proposed => l10n.improvementStatusProposed,
  ImprovementStatus.accepted => l10n.improvementStatusAccepted,
  ImprovementStatus.rejected => l10n.improvementStatusRejected,
  ImprovementStatus.rolledBack => l10n.improvementStatusRolledBack,
  ImprovementStatus.expired => l10n.improvementStatusExpired,
};

/// An improvement's status, as a tag tone.
CcStatusTone improvementStatusTone(ImprovementStatus status) =>
    switch (status) {
      ImprovementStatus.proposed => CcStatusTone.caution,
      ImprovementStatus.accepted => CcStatusTone.positive,
      ImprovementStatus.rejected ||
      ImprovementStatus.rolledBack ||
      ImprovementStatus.expired => CcStatusTone.neutral,
    };

/// What an improvement does to its target, as a label.
String improvementOperationLabel(
  AppLocalizations l10n,
  ImprovementOperation operation,
) => switch (operation) {
  ImprovementOperation.add => l10n.improvementOperationAdd,
  ImprovementOperation.replace => l10n.improvementOperationReplace,
  ImprovementOperation.remove => l10n.improvementOperationRemove,
};

/// A skill change's evaluation numbers in plain sentences: the paired runs
/// and how many the change and the current skill each solved, then only the
/// counts that are not zero (tasks that did worse or cost more with the
/// change, runs that hit a harness error), then whether it ran in full.
/// Whether it passed is the state line's to say, never derived here.
List<String> improvementEvaluationSentences(
  AppLocalizations l10n,
  ImprovementEvaluationSummary e,
) => [
  l10n.improvementEvaluationSolved(
    e.pairedRuns,
    e.candidateSolved,
    e.baselineSolved,
  ),
  if (e.qualityLosses > 0) l10n.improvementEvaluationWorse(e.qualityLosses),
  if (e.costRegressions > 0)
    l10n.improvementEvaluationCostlier(e.costRegressions),
  if (e.harnessErrors > 0)
    l10n.improvementEvaluationHarnessErrors(e.harnessErrors),
  if (!e.coverageComplete || (e.planViolations ?? 0) > 0)
    l10n.improvementEvaluationIncomplete,
];
