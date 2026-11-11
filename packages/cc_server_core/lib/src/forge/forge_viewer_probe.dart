import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_server_core/src/forge/forge_probe.dart';

/// Who a forge says the bearer of a token is: `login`, the handle PR authors
/// are matched by, and `id`, the account's durable id.
typedef ForgeViewer = ({String login, String id});

/// Asks [forge] who the bearer of [token] is. Null when the token is refused
/// or the forge is unreachable.
///
/// Bitbucket's `/2.0/user` is authenticated the way every Bitbucket call is
/// ([forgeGet]: an `email:token` API token as basic auth, an
/// access token as bearer). An access token has no person behind it and is
/// refused there, so it never reads as anyone's sign-in. The login is the
/// account's `nickname` (falling back to its `account_id`), the same handle
/// Bitbucket PR authors carry; the `account_id` is the durable id.
Future<ForgeViewer?> probeForgeViewer(ForgeHost forge, String token) async {
  if (forge == ForgeHost.local) {
    return null;
  }
  final answer = await forgeGet(forge, token, '/user');
  final json = answer.json;
  return answer.status == 200 && json is Map
      ? forgeViewerFromJson(forge, json)
      : null;
}

/// Reads the viewer out of [forge]'s `/user` answer; null when it names no
/// one.
ForgeViewer? forgeViewerFromJson(ForgeHost forge, Map<dynamic, dynamic> json) {
  String text(Object? value) => switch (value) {
    final String s => s,
    final num n => n.toString(),
    _ => '',
  };
  final ForgeViewer viewer = switch (forge) {
    ForgeHost.github => (login: text(json['login']), id: text(json['id'])),
    ForgeHost.gitlab => (login: text(json['username']), id: text(json['id'])),
    ForgeHost.bitbucket => (
      login: text(json['nickname']).isNotEmpty
          ? text(json['nickname'])
          : text(json['account_id']),
      id: text(json['account_id']),
    ),
    ForgeHost.local => (login: '', id: ''),
  };
  return viewer.login.isEmpty ? null : viewer;
}
