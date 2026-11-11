/// The check a token pasted as a person's own GitLab or Bitbucket credential
/// passes before it is stored: the forge must answer for it, as that person
/// (not a bot), with the scopes the features need, and not expired.
library;

import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_infra/cc_infra.dart' show BitbucketCredential;
import 'package:cc_server_core/src/forge/forge_probe.dart';
import 'package:cc_server_core/src/forge/forge_viewer_probe.dart'
    show ForgeViewer, forgeViewerFromJson;

/// Why a pasted person token was refused. [wire] is the `code` of the
/// `ValidationException` the token dialog shows.
enum PersonTokenRefusal {
  /// The forge could not be asked (unreachable, rate limited, failing).
  unreachable('person_token.unreachable'),

  /// The forge does not accept the token, or it is revoked.
  rejected('person_token.rejected'),

  /// The token is not a person's own (a bot or access token).
  wrongKind('person_token.wrong_kind'),

  /// The token lacks a scope the features need.
  narrowScope('person_token.narrow_scope'),

  /// The token has expired.
  expired('person_token.expired');

  const PersonTokenRefusal(this.wire);

  /// The refusal's code.
  final String wire;
}

/// What a person check concluded about a pasted token.
sealed class PersonTokenVerdict {
  const PersonTokenVerdict();
}

/// The token may be stored: it answers as [viewer], and lapses at
/// [expiresAt] (null when it does not expire or the forge does not say).
final class PersonTokenAccepted extends PersonTokenVerdict {
  /// Creates the verdict.
  const PersonTokenAccepted(this.viewer, {this.expiresAt});

  /// Who the token belongs to.
  final ForgeViewer viewer;

  /// When the token lapses.
  final DateTime? expiresAt;
}

/// The token must not be stored, for [reason]; [message] is what the person
/// is told.
final class PersonTokenRefused extends PersonTokenVerdict {
  /// Creates the verdict.
  const PersonTokenRefused(this.reason, this.message);

  /// Why.
  final PersonTokenRefusal reason;

  /// What the person is told.
  final String message;
}

/// Decides whether a token may be stored as a person's own [forge]
/// credential.
typedef PersonTokenCheck =
    Future<PersonTokenVerdict> Function(ForgeHost forge, String token);

/// What a person is told when they paste a GitLab project or group access
/// token as their own credential.
const String gitLabBotTokenRefusal =
    'This is a GitLab project or group access token, which acts as a bot '
    'rather than as you. Paste your own personal access token instead. '
    "Admins add bot tokens as a repository's automation token.";

/// What a person is told when they paste a Bitbucket access token as their
/// own credential.
const String bitbucketAccessTokenRefusal =
    'This looks like a Bitbucket access token, which belongs to a '
    'repository, project or workspace rather than to you. Paste your '
    'Atlassian API token together with your account email instead. Admins '
    "add access tokens as a repository's automation token.";

/// The GitLab scope a person's token needs: approving, commenting on and
/// reading merge requests all go through the API.
const String gitLabPersonScope = 'api';

/// The Bitbucket scopes, any one of which lets a person's token write to
/// pull requests (an API token's scope, or the OAuth spelling).
const Set<String> bitbucketPullRequestWriteScopes = {
  'write:pullrequest:bitbucket',
  'pullrequest:write',
};

/// The default [PersonTokenCheck]: GitLab is asked `GET /user` and
/// `GET /personal_access_tokens/self`, Bitbucket `GET /user`.
Future<PersonTokenVerdict> checkPersonForgeToken(
  ForgeHost forge,
  String token,
) async {
  switch (forge) {
    case ForgeHost.gitlab:
      final user = await forgeGet(forge, token, '/user');
      final self = user.status == 200
          ? await forgeGet(forge, token, '/personal_access_tokens/self')
          : null;
      return gitLabPersonTokenVerdict(
        userStatus: user.status,
        user: user.json,
        selfStatus: self?.status,
        self: self?.json,
        now: DateTime.now().toUtc(),
      );
    case ForgeHost.bitbucket:
      if (!BitbucketCredential.parse(token).isApiToken) {
        return const PersonTokenRefused(
          PersonTokenRefusal.wrongKind,
          bitbucketAccessTokenRefusal,
        );
      }
      final user = await forgeGet(forge, token, '/user');
      return bitbucketPersonTokenVerdict(
        status: user.status,
        user: user.json,
        scopes: user.header('x-oauth-scopes'),
      );
    case ForgeHost.github || ForgeHost.local:
      return const PersonTokenRefused(
        PersonTokenRefusal.wrongKind,
        'Only GitLab and Bitbucket take a pasted token.',
      );
  }
}

PersonTokenRefused _unreachable(ForgeHost forge) => PersonTokenRefused(
  PersonTokenRefusal.unreachable,
  '${forge.displayName} could not be reached to check the token. Try again.',
);

bool _unanswered(int? status) =>
    status == null || status == 429 || status >= 500;

/// The verdict on a GitLab token whose `GET /user` answered [userStatus]
/// with [user], and `GET /personal_access_tokens/self` [selfStatus] with
/// [self] (statuses null when GitLab was not reached).
///
/// GitLab marks the users behind project and group access tokens `bot:
/// true`; such a token in a person's slot would credit their work to a bot
/// and their approvals to nobody.
PersonTokenVerdict gitLabPersonTokenVerdict({
  required int? userStatus,
  required Object? user,
  required int? selfStatus,
  required Object? self,
  required DateTime now,
}) {
  if (_unanswered(userStatus)) {
    return _unreachable(ForgeHost.gitlab);
  }
  final viewer = userStatus == 200 && user is Map
      ? forgeViewerFromJson(ForgeHost.gitlab, user)
      : null;
  if (viewer == null) {
    return const PersonTokenRefused(
      PersonTokenRefusal.rejected,
      'GitLab does not accept this token.',
    );
  }
  if ((user as Map)['bot'] == true) {
    return const PersonTokenRefused(
      PersonTokenRefusal.wrongKind,
      gitLabBotTokenRefusal,
    );
  }
  if (_unanswered(selfStatus)) {
    return _unreachable(ForgeHost.gitlab);
  }
  if (selfStatus != 200 || self is! Map) {
    return const PersonTokenRefused(
      PersonTokenRefusal.wrongKind,
      'GitLab does not show this token as a personal access token. Paste a '
      'personal access token instead.',
    );
  }
  if (self['active'] == false || self['revoked'] == true) {
    return const PersonTokenRefused(
      PersonTokenRefusal.rejected,
      'GitLab reports this token as revoked or inactive.',
    );
  }
  final scopes = self['scopes'];
  if (scopes is! List || !scopes.contains(gitLabPersonScope)) {
    return const PersonTokenRefused(
      PersonTokenRefusal.narrowScope,
      'This GitLab token lacks the "$gitLabPersonScope" scope, which '
      'reviewing and commenting on merge requests need.',
    );
  }
  // `expires_at` is a date; GitLab expires the token at midnight UTC on it.
  final expiry = self['expires_at'];
  final date =
      expiry is String && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(expiry)
      ? DateTime.tryParse(expiry)
      : null;
  final expiresAt = date == null
      ? null
      : DateTime.utc(date.year, date.month, date.day);
  if (expiry != null && expiresAt == null) {
    return const PersonTokenRefused(
      PersonTokenRefusal.rejected,
      'GitLab answered an unreadable expiry for this token.',
    );
  }
  if (expiresAt != null && !expiresAt.isAfter(now)) {
    return const PersonTokenRefused(
      PersonTokenRefusal.expired,
      'This GitLab token has expired. Create a new one.',
    );
  }
  return PersonTokenAccepted(viewer, expiresAt: expiresAt);
}

/// The verdict on a Bitbucket API token whose `GET /user` answered
/// [status] with [user]; [scopes] is the answer's `x-oauth-scopes` header
/// (null when Bitbucket does not report the token's scopes, which are then
/// not checked). Bitbucket does not report an API token's expiry.
PersonTokenVerdict bitbucketPersonTokenVerdict({
  required int? status,
  required Object? user,
  required String? scopes,
}) {
  if (_unanswered(status)) {
    return _unreachable(ForgeHost.bitbucket);
  }
  final viewer = status == 200 && user is Map
      ? forgeViewerFromJson(ForgeHost.bitbucket, user)
      : null;
  if (viewer == null || viewer.id.isEmpty) {
    return const PersonTokenRefused(
      PersonTokenRefusal.rejected,
      'Bitbucket does not accept this token with this email. A token that '
      'has expired is refused too.',
    );
  }
  if (scopes != null) {
    final granted = {
      for (final s in scopes.split(RegExp(r'[,\s]+')))
        if (s.isNotEmpty) s,
    };
    if (granted.intersection(bitbucketPullRequestWriteScopes).isEmpty) {
      return const PersonTokenRefused(
        PersonTokenRefusal.narrowScope,
        'This Bitbucket token cannot write to pull requests, which reviewing '
        'and commenting need. Add the "write:pullrequest:bitbucket" scope.',
      );
    }
  }
  return PersonTokenAccepted(viewer);
}
