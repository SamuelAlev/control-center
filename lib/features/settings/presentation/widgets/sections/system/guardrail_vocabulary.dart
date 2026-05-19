import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';

/// Localized display label for an [ActionClass] (sentence case). The
/// [ActionClass.wire] value is a stable identifier; this maps it to prose.
String guardrailClassLabel(AppLocalizations l10n, ActionClass cls) =>
    switch (cls) {
      ActionClass.fileDelete => l10n.guardrailClassFileDelete,
      ActionClass.fileWriteOutsideWorktree =>
        l10n.guardrailClassFileWriteOutsideWorktree,
      ActionClass.gitCommit => l10n.guardrailClassGitCommit,
      ActionClass.gitPush => l10n.guardrailClassGitPush,
      ActionClass.prCreate => l10n.guardrailClassPrCreate,
      ActionClass.prPublish => l10n.guardrailClassPrPublish,
      ActionClass.vendorSyncWrite => l10n.guardrailClassVendorSyncWrite,
      ActionClass.networkEgress => l10n.guardrailClassNetworkEgress,
      ActionClass.secretAccess => l10n.guardrailClassSecretAccess,
      ActionClass.packageInstall => l10n.guardrailClassPackageInstall,
      ActionClass.processSpawn => l10n.guardrailClassProcessSpawn,
      ActionClass.workspaceMutation => l10n.guardrailClassWorkspaceMutation,
      ActionClass.enclosureControl => l10n.guardrailClassEnclosureControl,
    };

/// Localized decision label (allow / ask first / deny).
String guardrailDecisionLabel(AppLocalizations l10n, ActionDecision decision) =>
    switch (decision) {
      ActionDecision.allow => l10n.guardrailDecisionAllow,
      ActionDecision.prompt => l10n.guardrailDecisionPrompt,
      ActionDecision.deny => l10n.guardrailDecisionDeny,
    };

/// The status tone for a decision (never color-alone — always paired with the
/// localized label).
CcStatusTone guardrailDecisionTone(ActionDecision decision) =>
    switch (decision) {
      ActionDecision.allow => CcStatusTone.positive,
      ActionDecision.prompt => CcStatusTone.caution,
      ActionDecision.deny => CcStatusTone.negative,
    };

/// The allow / ask-first / deny options for a [CcSelect].
List<CcSelectOption<ActionDecision>> guardrailDecisionOptions(
  AppLocalizations l10n,
) => [
  for (final d in ActionDecision.values)
    CcSelectOption(value: d, label: guardrailDecisionLabel(l10n, d)),
];

/// The thirteen action classes, grouped by the kind of damage they do.
///
/// A flat list of thirteen is a list you read; four families of two to five are
/// something you scan. The families also carry the real distinction: "can it
/// touch my files" and "can it reach the network" are different questions an
/// operator answers with different appetites, and interleaving them in wire
/// order asked for both at once.
const List<
  ({String Function(AppLocalizations) label, List<ActionClass> classes})
>
kGuardrailFamilies = [
  (
    label: _familyFiles,
    classes: [ActionClass.fileDelete, ActionClass.fileWriteOutsideWorktree],
  ),
  (
    label: _familyGit,
    classes: [
      ActionClass.gitCommit,
      ActionClass.gitPush,
      ActionClass.prCreate,
      ActionClass.prPublish,
      ActionClass.vendorSyncWrite,
    ],
  ),
  (
    label: _familyMachine,
    classes: [
      ActionClass.processSpawn,
      ActionClass.packageInstall,
      ActionClass.networkEgress,
      ActionClass.enclosureControl,
    ],
  ),
  (
    label: _familyControl,
    classes: [ActionClass.secretAccess, ActionClass.workspaceMutation],
  ),
];

String _familyFiles(AppLocalizations l) => l.guardrailFamilyFiles;
String _familyGit(AppLocalizations l) => l.guardrailFamilyGit;
String _familyMachine(AppLocalizations l) => l.guardrailFamilyMachine;
String _familyControl(AppLocalizations l) => l.guardrailFamilyControl;
