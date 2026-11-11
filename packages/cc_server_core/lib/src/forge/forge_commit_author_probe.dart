import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart'
    show GitPerson;
import 'package:cc_server_core/src/forge/forge_probe.dart';

/// The name and the forge-verified email GitLab or Bitbucket reports for the
/// bearer of [token]: what an agent commit credits a person as. Null when the
/// forge names no verified email, refuses the token, or cannot be reached.
///
/// GitLab: `/user`'s `commit_email` (the address the person chose for their
/// commits, always one GitLab verified, or their private noreply), else
/// their primary `email`. Bitbucket: the primary confirmed address from
/// `/2.0/user/emails`, named by `/2.0/user`'s `display_name`. A workspace
/// profile's self-set email is never used: anyone can type anyone's address
/// there. GitHub is not probed here; a GitHub co-author is always the
/// person's noreply address from their sign-in.
Future<GitPerson?> probeForgeCommitAuthor(ForgeHost forge, String token) async {
  if (token.isEmpty) {
    return null;
  }
  switch (forge) {
    case ForgeHost.gitlab:
      final user = await _getJson(forge, token, '/user');
      if (user is! Map) {
        return null;
      }
      final email = _text(user['commit_email']).isNotEmpty
          ? _text(user['commit_email'])
          : _text(user['email']);
      final name = _text(user['name']).isNotEmpty
          ? _text(user['name'])
          : _text(user['username']);
      return _person(name, email);
    case ForgeHost.bitbucket:
      final emails = await _getJson(forge, token, '/user/emails');
      final values = emails is Map ? emails['values'] : null;
      if (values is! List) {
        return null;
      }
      final primary = values
          .whereType<Map<dynamic, dynamic>>()
          .where((e) => e['is_primary'] == true && e['is_confirmed'] == true)
          .map((e) => _text(e['email']))
          .where((e) => e.isNotEmpty)
          .firstOrNull;
      if (primary == null) {
        return null;
      }
      final user = await _getJson(forge, token, '/user');
      if (user is! Map) {
        return null;
      }
      final name = _text(user['display_name']).isNotEmpty
          ? _text(user['display_name'])
          : _text(user['nickname']);
      return _person(name, primary);
    case ForgeHost.github || ForgeHost.local:
      return null;
  }
}

/// [name] <[email]> when both make a git identity, else null.
GitPerson? _person(String name, String email) {
  bool clean(String v) =>
      v.trim().isNotEmpty && !v.contains(RegExp('[<>\r\n\x00]'));
  if (!clean(name) || !clean(email) || !email.contains('@')) {
    return null;
  }
  return (name: name.trim(), email: email.trim());
}

String _text(Object? value) => value is String ? value : '';

/// [path]'s JSON on [forge]'s API, or null unless it answered 200.
Future<Object?> _getJson(ForgeHost forge, String token, String path) async {
  final answer = await forgeGet(forge, token, path);
  return answer.status == 200 ? answer.json : null;
}
