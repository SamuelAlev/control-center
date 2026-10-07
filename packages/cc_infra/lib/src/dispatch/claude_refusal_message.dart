import 'package:cc_domain/core/domain/ports/run_credential_gate_port.dart';

/// The one sentence a run refused for want of a Claude Code account gets.
///
/// ONE function with two callers on purpose. It is both what the credential
/// gate shows the operator while the run is parked and what the dispatch
/// session writes into the transcript if the wait times out — and those two must
/// be the same sentence, or the dialog explains one problem and the failed turn
/// blames another.
///
/// Not localized, for the reason the account roster is not: the values in it
/// (an account count, a reset instant the plan reported) are the server's own,
/// and the string lands in a run transcript beside the CLI's own output rather
/// than in a widget.
String claudeRefusalDetail(AccountPoolRefusal refusal) {
  final n = refusal.accountIds.length;
  switch (refusal.reason) {
    case RunCredentialReason.planSpent:
      final reset = refusal.earliestReset;
      // The count only earns its place when there is a choice to describe;
      // "all 1 attached accounts" is how a single-account install reads its own
      // status as a configuration it does not have.
      final subject = n > 1
          ? 'all $n attached Claude Code accounts are'
          : 'this Claude Code account is';
      final when = reset == null
          ? '.'
          : ' — ${n > 1 ? 'the earliest resets' : 'it resets'} at '
                '${reset.toLocal()}.';
      return '[claude] $subject out of plan headroom$when';
    case RunCredentialReason.credentialExpired:
      // Deliberately not "signed out". The two look identical to a run and
      // could not be less alike to the operator: one account was never logged
      // into, the other worked this morning and needs the same login again.
      return '[claude] ${n > 1 ? 'every attached Claude Code account has a '
                    'sign-in that has' : "this Claude Code account's sign-in has"} '
          'expired and cannot renew itself. Sign in again from '
          'Settings → Adapters → Claude Code.';
    case RunCredentialReason.accountsRemoved:
      return accountPoolRemovedDetail(
        tag: 'claude',
        noun: 'Claude Code account',
        count: n,
      );
    case RunCredentialReason.signedOut:
    case RunCredentialReason.noCredential:
      return '[claude] ${n > 1 ? 'no attached Claude Code account is signed '
                    'in' : 'this Claude Code account is signed out'}. Sign in '
          'from Settings → Adapters → Claude Code, or run '
          '`claude auth login` against its config directory.';
  }
}

/// The sentence for a harness run whose pool for [providerId] refused it.
///
/// Only [RunCredentialReason.accountsRemoved] reaches here today — an
/// all-spent harness pool is handed to the fallback chain rather than refused
/// — but every reason gets a sentence so a new refusal cannot land blank.
String harnessPoolRefusalDetail(
  String providerId,
  AccountPoolRefusal refusal,
) => switch (refusal.reason) {
  RunCredentialReason.accountsRemoved => accountPoolRemovedDetail(
    tag: 'harness',
    noun: '"$providerId" key',
    count: refusal.accountIds.length,
  ),
  _ =>
    '[harness] no "$providerId" key attached to this agent or workspace '
        'can serve this run.',
};

/// The one wording for a pool that names only removed credentials, whatever
/// the lane — so the dialog reads the same whichever runner was held.
///
/// Never falls back to a default credential: the pool was configured to keep
/// the run off whatever is not on it.
String accountPoolRemovedDetail({
  required String tag,
  required String noun,
  required int count,
}) =>
    '[$tag] ${count > 1 ? 'every $noun attached to this agent or workspace '
              'has' : 'the $noun attached to this agent or workspace has'} '
    'been removed from the server. Attach another one in the account rotation '
    'settings, or clear the list to use the default.';
