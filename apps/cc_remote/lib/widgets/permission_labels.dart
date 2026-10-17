import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_ui/cc_ui.dart';

String permissionClassLabel(AppLocalizations l, ActionClass action) =>
    switch (action) {
      ActionClass.fileDelete => l.permissionFileDelete,
      ActionClass.fileWriteOutsideWorktree =>
        l.permissionFileWriteOutsideWorktree,
      ActionClass.gitCommit => l.permissionGitCommit,
      ActionClass.gitPush => l.permissionGitPush,
      ActionClass.prCreate => l.permissionPrCreate,
      ActionClass.prPublish => l.permissionPrPublish,
      ActionClass.vendorSyncWrite => l.permissionVendorSyncWrite,
      ActionClass.networkEgress => l.permissionNetworkEgress,
      ActionClass.secretAccess => l.permissionSecretAccess,
      ActionClass.packageInstall => l.permissionPackageInstall,
      ActionClass.processSpawn => l.permissionProcessSpawn,
      ActionClass.workspaceMutation => l.permissionWorkspaceMutation,
      ActionClass.enclosureControl => l.permissionEnclosureControl,
    };

String permissionDecisionLabel(AppLocalizations l, ActionDecision decision) =>
    switch (decision) {
      ActionDecision.allow => l.permissionAllow,
      ActionDecision.prompt => l.permissionAsk,
      ActionDecision.deny => l.permissionDeny,
    };

CcStatusTone permissionDecisionTone(ActionDecision decision) =>
    switch (decision) {
      ActionDecision.allow => CcStatusTone.positive,
      ActionDecision.prompt => CcStatusTone.caution,
      ActionDecision.deny => CcStatusTone.negative,
    };
