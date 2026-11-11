import 'package:cc_connect_core/cc_connect_core.dart' show ConnectErrorCode;

/// What the server was doing when Connect refused, for phrasing.
enum ConnectErrorActivity {
  /// Starting or finishing a browser sign-in.
  signIn,

  /// Minting a one-repository GitHub token.
  githubMint,

  /// Installing, listing or authorizing the shared GitHub App.
  githubSetup,
}

/// The context of one Connect refusal: the activity, and the GitHub account
/// it concerned when there was one.
final class ConnectErrorContext {
  const ConnectErrorContext._(this.activity, [this.account = '']);

  /// A token mint for a repository under [owner].
  factory ConnectErrorContext.githubMint(String owner) =>
      ConnectErrorContext._(ConnectErrorActivity.githubMint, owner);

  /// A browser sign-in.
  static const ConnectErrorContext signIn = ConnectErrorContext._(
    ConnectErrorActivity.signIn,
  );

  /// GitHub App setup.
  static const ConnectErrorContext githubSetup = ConnectErrorContext._(
    ConnectErrorActivity.githubSetup,
  );

  /// What the server was doing.
  final ConnectErrorActivity activity;

  /// The GitHub account concerned, or empty.
  final String account;
}

/// Why automation on a Control Center Connect lane does not push, create a
/// branch or open a pull request by itself.
const String kGitHubNeedsRequesterMessage =
    'On Control Center Connect the GitHub App never pushes, creates a branch '
    'or opens a pull request on its own; that needs a person who asked for '
    'it. Run this for someone (it then uses their own GitHub sign-in), or '
    'give the workspace its own GitHub App in Settings.';

/// The one table from a Connect failure to what a person reads. Server-side
/// operator and log copy; clients localize from the stable code instead.
String connectErrorMessage(ConnectErrorCode code, ConnectErrorContext context) {
  final where = context.account.isEmpty ? 'there' : 'on ${context.account}';
  return switch (code) {
    ConnectErrorCode.needsSignIn => switch (context.activity) {
      ConnectErrorActivity.githubMint =>
        'The accountable person needs to sign in to GitHub again.',
      _ => 'Sign in again first.',
    },
    ConnectErrorCode.accessDenied => switch (context.activity) {
      ConnectErrorActivity.githubMint =>
        'The accountable person cannot access this repository.',
      ConnectErrorActivity.githubSetup =>
        'Only an administrator of that GitHub account can do this.',
      ConnectErrorActivity.signIn =>
        'Control Center Connect answered with an unexpected sign-in link, so '
            'it was not opened.',
    },
    ConnectErrorCode.needsRequester => kGitHubNeedsRequesterMessage,
    ConnectErrorCode.codeMismatch =>
      'That code did not match. Check it and retry.',
    ConnectErrorCode.notAdmin =>
      'Only an administrator of that account can do this.',
    ConnectErrorCode.notInstalled =>
      'The Control Center GitHub App is not installed $where.',
    ConnectErrorCode.repoNotSelected =>
      'The Control Center GitHub App is installed $where, but this '
          'repository is not among the ones it may reach. Add it in the '
          "installation's repository settings.",
    ConnectErrorCode.teamBoundElsewhere =>
      'That Slack workspace is connected to another Control Center server.',
    ConnectErrorCode.suspended =>
      'The GitHub App installation $where is suspended.',
    ConnectErrorCode.installBlocked =>
      'Control Center Connect refused this server. Check Settings → Connect.',
    ConnectErrorCode.rateLimited =>
      'Too many requests right now. Try again in a minute.',
    ConnectErrorCode.staleRequest => 'That request expired. Start again.',
    ConnectErrorCode.invalidRequest =>
      'Control Center Connect could not read the request.',
    ConnectErrorCode.providerUnavailable =>
      'Control Center Connect is unreachable right now. Try again shortly.',
  };
}
