/// The forge credential layer's audit trail: one JSON line per event through
/// [CcHostLog], so every mint, refusal, revocation and cache drop can be
/// followed in the server log.
///
/// A credential never appears in a line: an event names one only by
/// `hashed_token` (base64 of its SHA-256, exactly as GitHub's organization
/// audit log hashes a token, so a line can be matched there) and
/// `token_kind`, and every string field is scrubbed of anything shaped like
/// a token ([kTokenPatterns]) before it is written.
library;

import 'dart:convert';

import 'package:cc_domain/core/domain/services/redaction/token_patterns.dart'
    show kTokenPatterns, redactTokens;
import 'package:cc_host/cc_host.dart' show CcHostLog;
import 'package:crypto/crypto.dart' show sha256;
import 'package:meta/meta.dart';

/// Every event the forge layer writes.
enum ForgeAuditEvent {
  /// A workspace's GitHub lane or App changed (written on change only).
  githubLaneResolved('github.lane.resolved'),

  /// A one-repository GitHub token was minted.
  githubTokenMinted('github.token.minted'),

  /// A requested GitHub scope was narrowed to what the accountable person
  /// may hold.
  githubTokenClamped('github.token.clamped'),

  /// A one-repository GitHub token was refused.
  githubTokenRefused('github.token.refused'),

  /// A GitHub token was revoked upstream.
  githubTokenRevoked('github.token.revoked'),

  /// Revoking a GitHub token upstream failed.
  githubTokenRevokeFailed('github.token.revoke_failed'),

  /// Cached GitHub grants were dropped.
  githubGrantCacheInvalidated('github.grant.cache_invalidated'),

  /// GitHub could not be asked whether a commit an agent's push stands on is
  /// already published (transport, outage, rate limit); the push is refused.
  githubPushAncestryUnanswered('github.push_ancestry.unanswered'),

  /// An automation request was refused before it was sent.
  forgeRequestRefused('forge.request.refused'),

  /// A GitLab or Bitbucket automation token was saved.
  forgeAutomationTokenSaved('forge.automation_token.saved'),

  /// A GitLab or Bitbucket automation token was removed.
  forgeAutomationTokenCleared('forge.automation_token.cleared'),

  /// A GitLab or Bitbucket automation token was refused (on save, or by the
  /// forge afterwards).
  forgeAutomationTokenRejected('forge.automation_token.rejected'),

  /// A repository link was checked.
  forgeLinkChecked('forge.link.checked'),

  /// A linked repository was pinned to the forge's durable id for it (at
  /// the first authorized read of a row linked before ids were kept).
  forgeRepoPinned('forge.repo.pinned'),

  /// A linked repository was renamed or transferred on the forge (same
  /// id); its stored owner/name followed it.
  forgeRepoMoved('forge.repo.moved'),

  /// A linked repository's path now names a different repository on the
  /// forge; nothing is sent to it until it is relinked.
  forgeRepoReplaced('forge.repo.replaced'),

  /// Renewing a person's forge sign-in failed.
  forgeCredentialRefreshFailed('forge.credential.refresh_failed'),

  /// A renewed sign-in could not be written; it is kept in memory, served,
  /// and written again on the next use.
  grantPersistFailed('grant.persist_failed'),

  /// GitHub refused a GitHub App's JWT.
  githubAppJwtRejected('github.app_jwt.rejected'),

  /// A browser sign-in started.
  signinBegun('signin.begun'),

  /// An own-app callback was refused (unknown or reused state, wrong lane,
  /// expired, or the provider declined).
  signinCallbackRefused('signin.callback_refused'),

  /// A confirmation code was refused.
  signinCodeRejected('signin.code_rejected'),

  /// Connect asked a claim to wait (`rate_limited`); the sign-in stays
  /// pending and the same code may be sent again.
  signinClaimDeferred('signin.claim_deferred'),

  /// A sign-in was stored.
  signinCompleted('signin.completed'),

  /// A sign-in ended without a stored grant.
  signinFailed('signin.failed'),

  /// A pending sign-in was dropped to make room for a newer one.
  signinEvicted('signin.evicted'),

  /// A grant named a different account than the provider confirmed.
  signinIdentityMismatch('signin.identity_mismatch'),

  /// A provider account already acting for another person was refused.
  signinAccountAlreadyBound('signin.account_already_bound'),

  /// A sign-in was renewed.
  grantRefreshed('grant.refreshed'),

  /// The provider or Connect refused to renew a sign-in: it needs a new one.
  grantRefreshRejected('grant.refresh_rejected'),

  /// Renewing a sign-in failed for now; it is retried on the next use.
  grantRefreshUnavailable('grant.refresh_unavailable'),

  /// A stored grant was deleted without a person disconnecting it.
  grantCleared('grant.cleared'),

  /// A person disconnected a grant.
  grantDisconnected('grant.disconnected'),

  /// A grant was not revoked upstream, and why.
  grantRevokeSkipped('grant.revoke_skipped'),

  /// Resetting a slot's grants after a sign-in setting changed failed.
  grantResetFailed('grant.reset_failed'),

  /// A provider app's settings were saved (field names only).
  providerAppSaved('provider_app.saved'),

  /// The server's or a workspace's Connect choice changed.
  connectChoiceChanged('connect.choice_changed'),

  /// Changed Connect app identifiers were confirmed.
  connectPinsConfirmed('connect.pins_confirmed'),

  /// This server's Connect install key was rotated.
  connectKeyRotated('connect.key_rotated'),

  /// A call to Connect failed.
  connectCallFailed('connect.call_failed'),

  /// A GitHub App was created from a manifest.
  githubAppManifestCreated('github_app.manifest_created'),

  /// Creating a GitHub App from a manifest was refused.
  githubAppManifestRefused('github_app.manifest_refused');

  const ForgeAuditEvent(this.wire);

  /// The event name as it appears in the log.
  final String wire;

  /// Whether the event reports a problem (logged as a warning).
  bool get isProblem => switch (this) {
    githubTokenRefused ||
    githubTokenRevokeFailed ||
    githubPushAncestryUnanswered ||
    forgeRequestRefused ||
    forgeAutomationTokenRejected ||
    forgeRepoReplaced ||
    forgeCredentialRefreshFailed ||
    grantPersistFailed ||
    githubAppJwtRejected ||
    signinCallbackRefused ||
    signinCodeRejected ||
    signinFailed ||
    signinEvicted ||
    signinIdentityMismatch ||
    signinAccountAlreadyBound ||
    grantRefreshRejected ||
    grantRefreshUnavailable ||
    grantRevokeSkipped ||
    grantResetFailed ||
    connectCallFailed ||
    githubAppManifestRefused => true,
    _ => false,
  };
}

/// Writes [event] with [fields]. [token], when given, is recorded as
/// `hashed_token` and `token_kind` only.
void forgeAudit(
  ForgeAuditEvent event,
  Map<String, Object?> fields, {
  String? token,
}) {
  final line = forgeAuditLine(event, fields, token: token);
  if (event.isProblem) {
    CcHostLog.warning(line);
  } else {
    CcHostLog.info(line);
  }
}

/// The line [forgeAudit] writes: `forge.audit {json}`. Null fields are
/// left out; strings are scrubbed of token-shaped text and [token] itself.
@visibleForTesting
String forgeAuditLine(
  ForgeAuditEvent event,
  Map<String, Object?> fields, {
  String? token,
}) {
  final out = <String, Object?>{'event': event.wire};
  if (token != null && token.isNotEmpty) {
    out['hashed_token'] = forgeHashedToken(token);
    out['token_kind'] = forgeTokenKind(token);
  }
  for (final entry in fields.entries) {
    final value = entry.value;
    if (value == null ||
        out.containsKey(entry.key) ||
        forgeAuditForbiddenFields.contains(entry.key)) {
      continue;
    }
    out[entry.key] = switch (value) {
      final String s => _scrub(s, token),
      final num n => n,
      final bool b => b,
      final DateTime d => d.toUtc().toIso8601String(),
      final Enum e => e.name,
      _ => _scrub('$value', token),
    };
  }
  return 'forge.audit ${jsonEncode(out)}';
}

/// Field names an event never carries, whatever a caller passes: a
/// credential, an OAuth code or `state`, a PKCE verifier, a confirmation code
/// or a seal. A credential is named only by `hashed_token`.
const Set<String> forgeAuditForbiddenFields = {
  'token',
  'access_token',
  'refresh_token',
  'code',
  'confirm_code',
  'verifier',
  'code_verifier',
  'state',
  'seal',
  'secret',
  'client_secret',
  'private_key',
  'password',
  'authorization',
};

/// Base64 of [token]'s SHA-256, the form GitHub's organization audit log
/// records a token in (`hashed_token`): it ties log lines about one
/// credential together, here and on GitHub, and can never be used as one.
String forgeHashedToken(String token) =>
    base64.encode(sha256.convert(utf8.encode(token)).bytes);

/// What kind of credential [token] is, from its published prefix.
String forgeTokenKind(String token) {
  for (final (prefix, kind) in _kinds) {
    if (token.startsWith(prefix)) {
      return kind;
    }
  }
  return 'other';
}

const _kinds = [
  ('ghs_', 'github_installation'),
  ('ghu_', 'github_user'),
  ('ghp_', 'github_pat'),
  ('github_pat_', 'github_pat'),
  ('gho_', 'github_oauth'),
  ('ghr_', 'github_refresh'),
  ('glpat-', 'gitlab_access_token'),
  ('gloas-', 'gitlab_oauth'),
  ('ATCTT', 'bitbucket_access_token'),
  ('ATATT', 'atlassian_api_token'),
];

/// An HTTP Basic credential: the one token-shaped spelling the shared table
/// ([kTokenPatterns]) leaves to the consumer that knows the context, since
/// its value is any base64.
final _basicCredential = RegExp(r'\bBasic\s+[A-Za-z0-9_\-=+/.:]+');

String _scrub(String value, String? token) {
  var out = value;
  if (token != null && token.isNotEmpty) {
    out = out.replaceAll(token, '[token]');
  }
  return redactTokens(
    out,
    replacement: '[token]',
  ).replaceAll(_basicCredential, '[token]');
}
