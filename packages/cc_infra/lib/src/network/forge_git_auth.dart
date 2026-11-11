import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/forge_host.dart';

/// One stored Bitbucket Cloud credential, read the one way every caller
/// (REST, git over HTTPS) must read it.
///
/// Bitbucket has two kinds of token and they authenticate differently:
/// * a person's **API token** is stored as `email:token` and is the password
///   half of basic auth with the Atlassian account's email (REST) or the
///   literal `x-bitbucket-api-token-auth` (git);
/// * a repository, project or workspace **access token** is bare and is a
///   bearer token (REST) or the password for `x-token-auth` (git).
final class BitbucketCredential {
  const BitbucketCredential._(this.token, this.email);

  /// Reads a stored credential. It is an API token only when the text before
  /// the FIRST colon looks like an email (has an `@`); an API token itself
  /// never contains a colon, so anything else is a bare access token.
  factory BitbucketCredential.parse(String stored) {
    final colon = stored.indexOf(':');
    if (colon > 0) {
      final left = stored.substring(0, colon);
      if (left.contains('@')) {
        return BitbucketCredential._(stored.substring(colon + 1), left);
      }
    }
    return BitbucketCredential._(stored, null);
  }

  /// The token itself (without the email).
  final String token;

  /// The Atlassian account's email for an API token; null for an access
  /// token.
  final String? email;

  /// Whether this is a person's API token (`email:token`).
  bool get isApiToken => email != null;

  /// The REST `Authorization` header value.
  String get authorizationHeader => isApiToken
      ? 'Basic ${base64Encode(utf8.encode('$email:$token'))}'
      : 'Bearer $token';

  /// The username and password git sends over HTTPS.
  ({String username, String password}) get gitAuth => isApiToken
      ? (username: 'x-bitbucket-api-token-auth', password: token)
      : (username: 'x-token-auth', password: token);
}

/// The REST `Authorization` header value for [token] on [forge]: `Bearer`
/// everywhere except a Bitbucket API token, which is basic auth (see
/// [BitbucketCredential]).
String forgeAuthorizationHeader(ForgeHost forge, String token) =>
    forge == ForgeHost.bitbucket
    ? BitbucketCredential.parse(token).authorizationHeader
    : 'Bearer $token';

/// The username git sends over HTTPS with a GitHub token.
const String gitHubGitUsername = 'x-access-token';

/// The username and password git sends over HTTPS for [token] on [forge].
///
/// The username is not cosmetic: GitHub wants [gitHubGitUsername], GitLab
/// accepts `oauth2` (any non-empty name works with an access token), and
/// Bitbucket depends on the kind of token ([BitbucketCredential.gitAuth]).
({String username, String password}) forgeGitHttpAuth(
  ForgeHost forge,
  String token,
) => switch (forge) {
  ForgeHost.github => (username: gitHubGitUsername, password: token),
  ForgeHost.gitlab => (username: 'oauth2', password: token),
  ForgeHost.bitbucket => BitbucketCredential.parse(token).gitAuth,
  ForgeHost.local => (username: gitHubGitUsername, password: token),
};

/// The Basic `Authorization` header value git over HTTPS sends for [token]
/// on [forge], from [forgeGitHttpAuth].
String forgeGitBasicAuthorization(ForgeHost forge, String token) {
  final auth = forgeGitHttpAuth(forge, token);
  final pair = utf8.encode('${auth.username}:${auth.password}');
  return 'Basic ${base64Encode(pair)}';
}

/// The `GIT_CONFIG_PARAMETERS` entry that authenticates git over HTTPS to
/// [forge] with [token]: an `http.https://<host>/.extraHeader` Basic
/// Authorization header built from [forgeGitHttpAuth]. Carried in a child's
/// environment (never argv, a URL or `.git/config`), so `ps` and git's own
/// stderr never show it.
String forgeGitAuthConfigParameter(ForgeHost forge, String token) =>
    "'http.https://${forge.gitHost}/.extraHeader="
    "Authorization: ${forgeGitBasicAuthorization(forge, token)}'";
