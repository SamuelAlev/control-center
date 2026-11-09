import 'package:cc_connect_core/cc_connect_core.dart' show ConnectOAuthLane;
import 'package:cc_data/cc_data.dart' show SignInFailure;
import 'package:control_center/l10n/app_localizations.dart';

/// The provider a lane signs in to, as a brand name (never translated).
String signInProviderName(ConnectOAuthLane lane) => switch (lane) {
  ConnectOAuthLane.github => 'GitHub',
  ConnectOAuthLane.google => 'Google Calendar',
  ConnectOAuthLane.linear || ConnectOAuthLane.linearApp => 'Linear',
  ConnectOAuthLane.slack => 'Slack',
};

/// The button that starts [lane]'s sign-in, and the sign-in dialog's title.
String signInActionLabel(AppLocalizations l10n, ConnectOAuthLane lane) =>
    switch (lane) {
      ConnectOAuthLane.github || ConnectOAuthLane.linear =>
        l10n.signInToProvider(signInProviderName(lane)),
      // Slack's lane installs the shared app into a workspace; nobody signs
      // in to anything.
      ConnectOAuthLane.slack => l10n.signInAddControlCenter(
        signInProviderName(lane),
      ),
      ConnectOAuthLane.linearApp => l10n.linearConnectAutomation,
      ConnectOAuthLane.google => l10n.calendarConnectGoogle,
    };

/// The toast after [lane]'s sign-in succeeded as [account] (empty when the
/// provider named nobody).
String signInSuccessMessage(
  AppLocalizations l10n,
  ConnectOAuthLane lane,
  String account,
) {
  final provider = signInProviderName(lane);
  if (lane == ConnectOAuthLane.slack) {
    // The account is the Slack workspace the shared app was installed in.
    return l10n.signInAddedControlCenter(account.isEmpty ? provider : account);
  }
  return account.isEmpty
      ? l10n.signInSucceededNoAccount(provider)
      : l10n.signInSucceeded(provider, account);
}

/// What went wrong, in words a person can act on. Never the raw code.
String signInFailureMessage(
  AppLocalizations l10n,
  SignInFailure? failure,
  ConnectOAuthLane lane,
) {
  final provider = signInProviderName(lane);
  return switch (failure) {
    SignInFailure.expired => l10n.signInErrorExpired,
    SignInFailure.accessDenied => l10n.signInErrorAccessDenied(provider),
    SignInFailure.scopeMismatch => l10n.signInErrorScopeMismatch(provider),
    SignInFailure.invalidCode => l10n.signInErrorInvalidCode,
    SignInFailure.providerUnavailable => l10n.signInErrorProviderUnavailable(
      provider,
    ),
    SignInFailure.exchangeFailed => l10n.signInErrorExchangeFailed(provider),
    SignInFailure.misconfigured => l10n.signInErrorMisconfigured(provider),
    SignInFailure.needsSignIn => l10n.signInErrorNeedsSignIn(provider),
    SignInFailure.notInstalled => l10n.signInErrorNotInstalled(provider),
    SignInFailure.installationBoundElsewhere =>
      l10n.signInErrorInstallationBoundElsewhere,
    SignInFailure.teamBoundElsewhere => l10n.signInErrorTeamBoundElsewhere,
    SignInFailure.notAdmin => l10n.signInErrorNotAdmin,
    SignInFailure.suspended => l10n.signInErrorSuspended(provider),
    SignInFailure.installBlocked => l10n.signInErrorInstallBlocked,
    SignInFailure.unknown || null => l10n.signInErrorUnknown,
  };
}
