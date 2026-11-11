import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_server_core/src/forge/forge_viewer_probe.dart';
import 'package:test/test.dart';

/// Every forge's `/user` answer names the viewer: Bitbucket included, by the
/// same handle its PR authors carry, with `account_id` as the durable id.
void main() {
  test('Bitbucket names the nickname and keeps the account id', () {
    expect(
      forgeViewerFromJson(ForgeHost.bitbucket, {
        'nickname': 'jdoe',
        'display_name': 'Jane Doe',
        'account_id': '557057:9d0a',
      }),
      (login: 'jdoe', id: '557057:9d0a'),
    );
  });

  test('a Bitbucket account without a nickname is its account id', () {
    expect(
      forgeViewerFromJson(ForgeHost.bitbucket, {'account_id': '557057:9d0a'}),
      (login: '557057:9d0a', id: '557057:9d0a'),
    );
  });

  test('GitHub and GitLab keep their logins and numeric ids', () {
    expect(
      forgeViewerFromJson(ForgeHost.github, {'login': 'octocat', 'id': 1}),
      (login: 'octocat', id: '1'),
    );
    expect(
      forgeViewerFromJson(ForgeHost.gitlab, {'username': 'jdoe', 'id': 42}),
      (login: 'jdoe', id: '42'),
    );
  });

  test('an answer that names nobody is no viewer', () {
    expect(forgeViewerFromJson(ForgeHost.bitbucket, const {}), isNull);
    expect(forgeViewerFromJson(ForgeHost.local, {'login': 'x'}), isNull);
  });

  test('no request goes out for an empty token or the local forge', () async {
    expect(await probeForgeViewer(ForgeHost.local, 'x'), isNull);
    expect(await probeForgeViewer(ForgeHost.bitbucket, ''), isNull);
  });
}
