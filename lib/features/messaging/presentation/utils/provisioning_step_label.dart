import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_step.dart';
import 'package:control_center/l10n/app_localizations.dart';

/// The localized label for the moment space provisioning is currently in:
/// the granular [step] when the server reports one ("Cloning repo…",
/// "Setting up agent…"), else the generic "Preparing workspace…". Shared by
/// the messaging composer banner and the PR workbench tabs so every
/// provisioning surface narrates the same way.
String provisioningStepLabel(
  AppLocalizations l10n,
  SpaceProvisioningStep? step,
) {
  if (step == null || step.subject.isEmpty) {
    return l10n.preparingWorkspace;
  }
  return switch (step.kind) {
    SpaceProvisioningStepKind.repo => l10n.provisioningCloningRepo(
      step.subject,
    ),
    SpaceProvisioningStepKind.prCheckout => l10n.provisioningCheckingOutPr(
      step.subject,
    ),
    SpaceProvisioningStepKind.script => l10n.provisioningRunningSetupScript(
      step.subject,
    ),
    SpaceProvisioningStepKind.agent => l10n.provisioningSettingUpAgent(
      step.subject,
    ),
  };
}
