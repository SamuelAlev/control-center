import 'package:cc_connect_core/cc_connect_core.dart'
    show ConnectOAuthLane, SignInFailure;
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart'
    show ForgeConnectionStatus;
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

/// [signInFailureMessage], followed by the server's own explanation when it
/// gave one (an own app's code exchange refused, with the provider's reason).
String signInFailureDetail(
  AppLocalizations l10n,
  SignInFailure? failure,
  ConnectOAuthLane lane, {
  String serverMessage = '',
}) {
  final message = signInFailureMessage(l10n, failure, lane);
  // An account held by another person is said in full by its own sentence.
  final detail = failure == SignInFailure.accountAlreadyBound
      ? ''
      : serverMessage.trim();
  return detail.isEmpty || detail == message ? message : '$message\n$detail';
}

/// How a connection that is not usable reads, by [status]; null for
/// [ForgeConnectionStatus.connected] and [ForgeConnectionStatus.notConnected],
/// which each surface words itself.
///
/// [account] is the last known account, kept so "sign in again" can say as
/// whom. A paused grant is not the person's fault, so it never asks them to
/// sign in again: doing so would replace the parked grant that comes back
/// when the workspace's sign-in service does.
String? unusableConnectionLine(
  AppLocalizations l10n,
  ForgeConnectionStatus status,
  String provider, {
  String account = '',
}) => switch (status) {
  ForgeConnectionStatus.needsSignIn =>
    account.isEmpty
        ? l10n.signInErrorNeedsSignIn(provider)
        : l10n.connectionNeedsSignInAs(provider, account),
  ForgeConnectionStatus.paused => l10n.connectionPaused,
  ForgeConnectionStatus.unreachable => l10n.connectionUnreachable(provider),
  ForgeConnectionStatus.connected || ForgeConnectionStatus.notConnected => null,
};

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
    SignInFailure.accountAlreadyBound => l10n.signInErrorAccountAlreadyBound(
      provider,
    ),
    SignInFailure.scopeMismatch => l10n.signInErrorScopeMismatch(provider),
    SignInFailure.codeMismatch => l10n.signInErrorInvalidCode,
    SignInFailure.invalidCode => l10n.signInErrorTooManyCodes,
    SignInFailure.staleRequest => l10n.signInErrorStaleRequest,
    SignInFailure.attemptUnknown => l10n.signInErrorAttemptUnknown,
    SignInFailure.invalidRequest => l10n.signInErrorInvalidRequest,
    SignInFailure.rateLimited => l10n.signInErrorRateLimited,
    SignInFailure.storeFailed => l10n.signInErrorStoreFailed(provider),
    SignInFailure.providerUnavailable => l10n.signInErrorProviderUnavailable(
      provider,
    ),
    SignInFailure.exchangeFailed => l10n.signInErrorExchangeFailed(provider),
    SignInFailure.misconfigured => l10n.signInErrorMisconfigured(provider),
    SignInFailure.needsSignIn => l10n.signInErrorNeedsSignIn(provider),
    SignInFailure.notInstalled => l10n.signInErrorNotInstalled(provider),
    SignInFailure.teamBoundElsewhere => l10n.signInErrorTeamBoundElsewhere,
    SignInFailure.notAdmin => l10n.signInErrorNotAdmin,
    SignInFailure.suspended => l10n.signInErrorSuspended(provider),
    SignInFailure.installBlocked => l10n.signInErrorInstallBlocked,
    SignInFailure.unknown || null => l10n.signInErrorUnknown,
  };
}
