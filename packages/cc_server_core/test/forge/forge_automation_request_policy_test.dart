import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_host/cc_host.dart' show CcHostLog;
import 'package:cc_server_core/src/forge/forge_automation_request_policy.dart';
import 'package:test/test.dart';

/// A GitLab or Bitbucket automation client reaches only its repository and
/// never approves; the refusal is logged as `forge.request.refused`.
void main() {
  late List<String> lines;

  setUp(() {
    lines = [];
    final previous = CcHostLog.sink;
    CcHostLog.sink = (level, message, [error, stackTrace]) =>
        lines.add(message);
    addTearDown(() => CcHostLog.sink = previous);
  });

  group('GitLab', () {
    const base = 'https://gitlab.com/api/v4';
    String? refuse(String method, String path) => refuseForgeAutomationRequest(
      ForgeHost.gitlab,
      'group',
      'api',
      method,
      '$base$path',
      workspaceId: 'ws1',
    );

    test('requests about its own project pass', () {
      for (final (method, path) in [
        ('GET', '/projects/group%2Fapi/merge_requests?state=opened'),
        ('POST', '/projects/group%2Fapi/merge_requests/7/notes'),
        ('PUT', '/projects/group%2Fapi/merge_requests/7'),
        ('GET', '/projects/group%2Fapi/merge_requests/7/approvals'),
        ('GET', '/user'),
        ('GET', '/users?username=ada'),
      ]) {
        expect(refuse(method, path), isNull, reason: '$method $path');
      }
      expect(lines, isEmpty);
    });

    test('another project, or a climb out of this one, is refused', () {
      for (final path in [
        '/projects/group%2Fother/merge_requests',
        '/projects/42/merge_requests',
        '/projects/group%2Fapi/../group%2Fother/issues',
        '/projects/group%2Fapi/%2e%2e/group%2Fother',
        '/groups/group/projects',
        '/projects',
      ]) {
        expect(refuse('GET', path), contains('only reaches'), reason: path);
      }
      expect(refuse('POST', '/user'), isNotNull, reason: 'a read only');
    });

    test('approving, or changing who must approve, is refused', () {
      for (final (method, path) in [
        ('POST', '/projects/group%2Fapi/merge_requests/7/approve'),
        ('POST', '/projects/group%2Fapi/merge_requests/7/approvals'),
        ('PUT', '/projects/group%2Fapi/merge_requests/7/approvals'),
      ]) {
        expect(
          refuse(method, path),
          contains('never approves'),
          reason: '$method $path',
        );
      }
    });

    test('a refusal is logged with the rule and a path template, never the '
        'query', () {
      refuse('POST', '/projects/group%2Fapi/merge_requests/7/approve?x=1');
      expect(lines, hasLength(1));
      expect(lines.single, contains('"event":"forge.request.refused"'));
      expect(lines.single, contains('"rule":"automated_approval"'));
      expect(lines.single, contains('"workspace_id":"ws1"'));
      expect(lines.single, contains('/merge_requests/{n}/approve'));
      expect(lines.single, isNot(contains('x=1')));
    });
  });

  group('Bitbucket', () {
    const base = 'https://api.bitbucket.org/2.0';
    String? refuse(String method, String path) => refuseForgeAutomationRequest(
      ForgeHost.bitbucket,
      'team',
      'svc',
      method,
      '$base$path',
    );

    test('requests about its own repository pass', () {
      for (final (method, path) in [
        ('GET', '/repositories/team/svc/pullrequests'),
        ('POST', '/repositories/team/svc/pullrequests/3/comments'),
        ('DELETE', '/repositories/team/svc/pullrequests/3/approve'),
        ('GET', '/user'),
        ('GET', '/workspaces/team/members'),
      ]) {
        expect(refuse(method, path), isNull, reason: '$method $path');
      }
    });

    test('another repository or workspace is refused', () {
      for (final path in [
        '/repositories/team/other/pullrequests',
        '/repositories/elsewhere/svc',
        '/repositories/team/svc/../other',
        '/workspaces/elsewhere/members',
        '/repositories/team',
      ]) {
        expect(refuse('GET', path), contains('only reaches'), reason: path);
      }
    });

    test('approving is refused', () {
      expect(
        refuse('POST', '/repositories/team/svc/pullrequests/3/approve'),
        contains('never approves'),
      );
    });
  });

  test('GitHub is guarded by its own policy, not this one', () {
    expect(
      refuseForgeAutomationRequest(
        ForgeHost.github,
        'acme',
        'api',
        'POST',
        'https://api.github.com/repos/acme/other/pulls/1/reviews',
      ),
      isNull,
    );
  });
}
