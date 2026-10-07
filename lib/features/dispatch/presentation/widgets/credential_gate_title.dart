import 'package:cc_domain/cc_domain.dart'
    show RunCredentialBlockDto, RunCredentialLane, RunCredentialReason;
import 'package:control_center/l10n/app_localizations.dart';

/// The credential gate's headline: names the SPECIFIC problem, never "a
/// credential problem". Each reason has a different fix, and a title that does
/// not say which one leaves the operator to guess between signing in, waiting,
/// pasting a key and editing the account list.
String credentialGateTitle(
  AppLocalizations l10n,
  RunCredentialBlockDto block,
) => switch (block.reason) {
  RunCredentialReason.planSpent => l10n.credentialGatePlanSpentTitle,
  RunCredentialReason.signedOut => l10n.credentialGateSignedOutTitle,
  RunCredentialReason.credentialExpired => l10n.credentialGateExpiredTitle,
  RunCredentialReason.accountsRemoved =>
    l10n.credentialGateAccountsRemovedTitle,
  RunCredentialReason.noCredential =>
    block.lane == RunCredentialLane.harness
        ? l10n.credentialGateHarnessTitle(
            block.providerId ?? l10n.credentialGateWaitingTitle,
          )
        : l10n.credentialGateSignedOutTitle,
};
