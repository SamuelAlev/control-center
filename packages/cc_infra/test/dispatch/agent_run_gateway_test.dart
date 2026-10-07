import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/repositories/action_policy_repository.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_constraint.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_harness/tools.dart' show ActionClass;
import 'package:cc_infra/src/dispatch/agent_run_gateway.dart';
import 'package:test/test.dart';

class _Rules implements ActionPolicyRepository {
  final List<ActionPolicyRule> list = [];

  @override
  Future<List<ActionPolicyRule>> rules(String workspaceId) async => list;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Confirm implements ConfirmationPort {
  bool answer = true;
  final List<ConfirmationRequest> asked = [];

  @override
  Future<bool> requestApproval(ConfirmationRequest request) async {
    asked.add(request);
    return answer;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Broker implements CredentialBrokerPort {
  final List<ForgeTokenScope> scopes = [];
  final List<String> revoked = [];
  var _n = 0;

  @override
  Future<ScopedCredentials> mint({
    required String conversationId,
    required ForgeTokenScope scope,
    String? repoOwner,
    String? repoName,
    String? actingUserId,
    String? workspaceId,
  }) async {
    scopes.add(scope);
    _n++;
    return ScopedCredentials(
      handle: 'h$_n',
      environment: {'GH_TOKEN': 'write-tok'},
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
  }

  @override
  Future<void> revoke(String handle) async => revoked.add(handle);
}

/// What the fake GitHub saw.
class _Upstream {
  _Upstream(this.server) {
    server.listen((request) async {
      final body = await request.fold<List<int>>([], (a, b) => a..addAll(b));
      seen.add((
        method: request.method,
        path: request.uri.path,
        query: request.uri.query,
        auth: request.headers.value(HttpHeaders.authorizationHeader),
        body: body,
      ));
      request.response
        ..statusCode = 200
        ..headers.set(
          HttpHeaders.contentTypeHeader,
          'application/x-git-receive-pack-result',
        )
        ..write('upstream-ok');
      await request.response.close();
    });
  }

  final HttpServer server;
  final List<
    ({String method, String path, String query, String? auth, List<int> body})
  >
  seen = [];
}

String _pkt(String line) =>
    '${(line.length + 4).toRadixString(16).padLeft(4, '0')}$line';

final _zero = '0' * 40;
final _one = '1' * 40;

/// A receive-pack request body: ref updates, flush, then pack bytes.
List<int> _push(List<String> refs) => utf8.encode(
  [
    for (var i = 0; i < refs.length; i++)
      _pkt(
        '$_zero $_one ${refs[i]}'
        '${i == 0 ? '\u0000report-status side-band-64k' : ''}\n',
      ),
    '0000',
    'PACK-bytes',
  ].join(),
);

void main() {
  late _Rules rules;
  late _Confirm confirm;
  late _Broker broker;
  late _Upstream upstream;
  late HttpServer host;
  late AgentRunGateway gateway;
  late AgentRunLease lease;
  late HttpClient client;
  var linked = <String>{};

  setUp(() async {
    rules = _Rules();
    confirm = _Confirm();
    broker = _Broker();
    linked = {};
    upstream = _Upstream(
      await HttpServer.bind(InternetAddress.loopbackIPv4, 0),
    );
    host = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    gateway = AgentRunGateway(
      guard: ActionGuardService(repository: rules, confirmationPort: confirm),
      broker: broker,
      loopbackBase: () async => Uri.parse('http://127.0.0.1:${host.port}'),
      repoAllowed: (ws, owner, name) async => linked.contains('$owner/$name'),
      githubBase: Uri.parse('http://127.0.0.1:${upstream.server.port}'),
    );
    host.listen(gateway.handle);
    lease = (await gateway.open(
      const AgentRunGrant(
        workspaceId: 'w1',
        conversationId: 'c1',
        agentId: 'a1',
        spaceId: 's1',
        repoOwner: 'acme',
        repoName: 'widgets',
      ),
    ))!;
    client = HttpClient();
  });

  tearDown(() async {
    client.close(force: true);
    await host.close(force: true);
    await upstream.server.close(force: true);
  });

  void rule(
    ActionClass cls,
    ActionDecision decision, {
    ActionConstraint? constraint,
  }) => rules.list.add(
    ActionPolicyRule(
      id: '${cls.wire}-${decision.wire}-${rules.list.length}',
      workspaceId: 'w1',
      scopeType: ActionScopeType.workspace,
      scopeId: '',
      actionClass: cls,
      decision: decision,
      constraint: constraint,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    ),
  );

  Future<({int status, String body})> send(
    String method,
    String path, {
    List<int>? body,
    String? secret,
  }) async {
    final request = await client.openUrl(
      method,
      Uri.parse('http://127.0.0.1:${host.port}$path'),
    );
    final token = secret ?? lease.secret;
    request.headers.set(AgentRunLease.tokenHeader, token);
    if (body != null) {
      request.add(body);
    }
    final response = await request.close();
    final text = await response.transform(utf8.decoder).join();
    return (status: response.statusCode, body: text);
  }

  const pushPath = '/agent/git/github.com/acme/widgets.git/git-receive-pack';
  const advertPath =
      '/agent/git/github.com/acme/widgets.git/info/refs'
      '?service=git-receive-pack';

  group('lease', () {
    test('routes pushes through the gateway, appended to existing config', () {
      final env = lease.environment(const {'GIT_CONFIG_COUNT': '2'});
      expect(env['GIT_CONFIG_COUNT'], '6');
      expect(env[AgentRunLease.tokenEnvKey], lease.secret);
      final pairs = {
        for (var i = 2; i < 6; i++)
          '${env['GIT_CONFIG_KEY_$i']}=${env['GIT_CONFIG_VALUE_$i']}',
      };
      final base = 'http://127.0.0.1:${host.port}/agent/git/';
      expect(
        pairs,
        containsAll([
          'url.${base}github.com/.pushInsteadOf=https://github.com/',
          'url.${base}github.com/.pushInsteadOf=git@github.com:',
          'http.$base.extraHeader=X-CC-Agent-Run: ${lease.secret}',
        ]),
      );
    });

    test('registers an HTTP PreToolUse hook on Bash', () {
      final settings = jsonDecode(lease.claudeHookSettings()) as Map;
      final entry =
          ((settings['hooks'] as Map)['PreToolUse'] as List).single as Map;
      expect(entry['matcher'], 'Bash');
      final hook = (entry['hooks'] as List).single as Map;
      expect(hook['type'], 'http');
      expect(hook['url'], endsWith('/agent/hooks/pre-tool-use'));
      expect(hook['headers'], {'X-CC-Agent-Run': r'$CC_AGENT_RUN_TOKEN'});
      expect(hook['allowedEnvVars'], ['CC_AGENT_RUN_TOKEN']);
      expect(
        hook['timeout'],
        greaterThan(AgentRunGateway.hookDecisionDeadline.inSeconds),
      );
    });
  });

  group('push proxy', () {
    test('an unknown secret is refused', () async {
      final r = await send(
        'POST',
        pushPath,
        body: _push(['refs/heads/x']),
        secret: 'nope',
      );
      expect(r.status, HttpStatus.unauthorized);
      expect(upstream.seen, isEmpty);
    });

    test(
      'an allowed push is forwarded on the gateway\'s write token',
      () async {
        rule(ActionClass.gitPush, ActionDecision.allow);
        final body = _push(['refs/heads/feature/x']);

        final r = await send('POST', pushPath, body: body);

        expect(r.status, 200);
        expect(r.body, 'upstream-ok');
        final seen = upstream.seen.single;
        expect(seen.path, '/acme/widgets.git/git-receive-pack');
        expect(
          seen.auth,
          'Basic ${base64.encode(utf8.encode('x-access-token:write-tok'))}',
        );
        // The preamble read to decide is replayed byte for byte.
        expect(seen.body, body);
        expect(broker.scopes, [ForgeTokenScope.write]);
        expect(confirm.asked, isEmpty);
      },
    );

    test(
      '"ask first" asks, and a refusal reaches git as rejected refs',
      () async {
        confirm.answer = false; // the built-in default for gitPush is prompt

        final r = await send(
          'POST',
          pushPath,
          body: _push(['refs/heads/main']),
        );

        expect(confirm.asked, hasLength(1));
        expect(confirm.asked.single.spaceId, 's1');
        expect(r.status, 200);
        expect(r.body, contains('ng refs/heads/main'));
        expect(r.body, contains('Control Center policy'));
        expect(upstream.seen, isEmpty);
        expect(broker.scopes, isEmpty, reason: 'no token for a refused push');
      },
    );

    test('a branch rule applies to the refs actually pushed', () async {
      rule(
        ActionClass.gitPush,
        ActionDecision.deny,
        constraint: const ActionConstraint(refs: ['main']),
      );
      rule(ActionClass.gitPush, ActionDecision.allow);

      final toMain = await send(
        'POST',
        pushPath,
        body: _push(['refs/heads/main']),
      );
      expect(toMain.body, contains('ng refs/heads/main'));

      final toFeature = await send(
        'POST',
        pushPath,
        body: _push(['refs/heads/feature/y']),
      );
      expect(toFeature.body, 'upstream-ok');
      expect(upstream.seen, hasLength(1));
    });

    test('a flat deny is refused at discovery, with the reason', () async {
      rule(ActionClass.gitPush, ActionDecision.deny);

      final r = await send('GET', advertPath);

      expect(r.status, HttpStatus.forbidden);
      expect(r.body, contains('Control Center policy'));
      expect(upstream.seen, isEmpty);
      expect(broker.scopes, isEmpty);
    });

    test('discovery is forwarded with the service query', () async {
      final r = await send('GET', advertPath);
      expect(r.status, 200);
      expect(upstream.seen.single.path, '/acme/widgets.git/info/refs');
      expect(upstream.seen.single.query, 'service=git-receive-pack');
    });

    test('a repo the workspace does not link is refused', () async {
      rule(ActionClass.gitPush, ActionDecision.allow);
      final r = await send(
        'POST',
        '/agent/git/github.com/evil/repo.git/git-receive-pack',
        body: _push(['refs/heads/x']),
      );
      expect(r.status, HttpStatus.forbidden);
      expect(upstream.seen, isEmpty);
    });

    test('a linked repo other than the worktree\'s own is allowed', () async {
      rule(ActionClass.gitPush, ActionDecision.allow);
      linked = {'acme/other'};
      final r = await send(
        'POST',
        '/agent/git/github.com/acme/other.git/git-receive-pack',
        body: _push(['refs/heads/x']),
      );
      expect(r.body, 'upstream-ok');
    });

    test('fetches are not proxied', () async {
      final r = await send(
        'GET',
        '/agent/git/github.com/acme/widgets.git/info/refs'
            '?service=git-upload-pack',
      );
      expect(r.status, HttpStatus.forbidden);
    });

    test('closing the lease revokes the write tokens it minted', () async {
      rule(ActionClass.gitPush, ActionDecision.allow);
      await send('POST', pushPath, body: _push(['refs/heads/x']));
      await gateway.close(lease);
      expect(broker.revoked, ['h1']);
      final after = await send('POST', pushPath, body: _push(['refs/heads/x']));
      expect(after.status, HttpStatus.unauthorized);
    });
  });

  group('Claude Code hook', () {
    Future<Map<String, dynamic>?> hook(
      String tool,
      String command, {
      String? description = 'Run the command',
    }) async {
      final r = await send(
        'POST',
        '/agent/hooks/pre-tool-use',
        body: utf8.encode(
          jsonEncode({
            'tool_name': tool,
            'tool_input': {'command': command, 'description': ?description},
          }),
        ),
      );
      expect(r.status, 200);
      if (r.body.isEmpty) {
        return null;
      }
      return (jsonDecode(r.body) as Map<String, dynamic>)['hookSpecificOutput']
          as Map<String, dynamic>;
    }

    test('a denied rule denies the Bash call, with the reason', () async {
      rule(ActionClass.prCreate, ActionDecision.deny);
      final out = await hook('Bash', 'git add -A && gh pr create --fill');
      expect(out!['permissionDecision'], 'deny');
      expect(
        out['permissionDecisionReason'],
        contains('Control Center policy'),
      );
    });

    test('"ask first" asks the operator', () async {
      // prCreate prompts by default.
      final out = await hook('Bash', 'gh pr create');
      expect(confirm.asked, hasLength(1));
      expect(out!['permissionDecision'], 'allow');
    });

    test('an ordinary command is allowed without asking', () async {
      final out = await hook('Bash', 'ls -la');
      expect(out!['permissionDecision'], 'allow');
      expect(confirm.asked, isEmpty);
    });

    test('a Bash call without a description is denied unasked', () async {
      for (final description in [null, '  ']) {
        final out = await hook(
          'Bash',
          'gh pr create',
          description: description,
        );
        expect(out!['permissionDecision'], 'deny');
        expect(out['permissionDecisionReason'], contains('description'));
      }
      expect(confirm.asked, isEmpty);
    });

    test('another tool gets no decision', () async {
      expect(await hook('Read', 'whatever'), isNull);
    });
  });
}
