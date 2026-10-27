import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/repositories/action_policy_repository.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_constraint.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_harness/tools.dart' show ActionClass;
import 'package:cc_infra/src/dispatch/agent_run_gateway.dart';
import 'package:cc_infra/src/dispatch/host_commit_signer.dart';
import 'package:cc_infra/src/sandboxing/macos_sandbox.dart';
import 'package:test/test.dart';

class _Rules implements ActionPolicyRepository {
  final List<ActionPolicyRule> list = [];
  bool fail = false;

  @override
  Future<List<ActionPolicyRule>> rules(String workspaceId) async {
    if (fail) {
      throw StateError('Policy store unavailable');
    }
    return list;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Confirm implements ConfirmationPort {
  bool answer = true;
  final List<ConfirmationRequest> asked = [];
  Completer<bool>? pending;
  Completer<void>? requested;

  @override
  Future<bool> requestApproval(ConfirmationRequest request) async {
    asked.add(request);
    requested?.complete();
    return pending?.future ?? answer;
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

class _Signer implements CommitSigner {
  final List<List<int>> signed = [];
  CommitSigningException? failure;
  Completer<void>? hold;
  int running = 0;
  int maxRunning = 0;

  @override
  Future<String> sign(List<int> payload) async {
    signed.add(payload);
    running++;
    maxRunning = max(maxRunning, running);
    try {
      await hold?.future;
      if (failure case final e?) {
        throw e;
      }
      return '-----BEGIN SSH SIGNATURE-----\nsig\n'
          '-----END SSH SIGNATURE-----\n';
    } finally {
      running--;
    }
  }
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
  late List<GuardAudit> audits;
  late _Signer signer;
  var owner = true;
  var linked = <String>{};
  String? hookReply;
  var hookRequests = 0;

  setUp(() async {
    rules = _Rules();
    confirm = _Confirm();
    broker = _Broker();
    linked = {};
    audits = [];
    signer = _Signer();
    owner = true;
    hookReply = null;
    hookRequests = 0;
    upstream = _Upstream(
      await HttpServer.bind(InternetAddress.loopbackIPv4, 0),
    );
    host = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    gateway = AgentRunGateway(
      guard: ActionGuardService(
        repository: rules,
        confirmationPort: confirm,
        onAudit: audits.add,
      ),
      broker: broker,
      loopbackBase: () async => Uri.parse('http://127.0.0.1:${host.port}'),
      repoAllowed: (ws, owner, name) async => linked.contains('$owner/$name'),
      githubBase: Uri.parse('http://127.0.0.1:${upstream.server.port}'),
      signer: signer,
      mayUseHostSigner: (_) async => owner,
    );
    host.listen((request) async {
      if (request.uri.path == '/agent/hooks/pre-tool-use') {
        hookRequests++;
      }
      if (hookReply case final reply?) {
        await request.drain<void>();
        request.response.write(reply);
        await request.response.close();
        return;
      }
      await gateway.handle(request);
    });
    lease = (await gateway.open(
      const AgentRunGrant(
        workspaceId: 'w1',
        conversationId: 'c1',
        agentId: 'a1',
        spaceId: 's1',
        repoOwner: 'acme',
        repoName: 'widgets',
        committerEmail: 'Ada@Example.com',
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
    String? encoding,
  }) async {
    final request = await client.openUrl(
      method,
      Uri.parse('http://127.0.0.1:${host.port}$path'),
    );
    final token = secret ?? lease.secret;
    request.headers.set(AgentRunLease.tokenHeader, token);
    if (encoding != null) {
      request.headers.set(HttpHeaders.contentEncodingHeader, encoding);
    }
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
        expect(confirm.asked.single.title, contains('push to main'));
        expect(confirm.asked.single.title, isNot(contains('gitPush')));
        expect(confirm.asked.single.detail, isNot(contains('Policy:')));
        expect(confirm.asked.single.command, isNull);
        expect(r.status, 200);
        expect(r.body, contains('ng refs/heads/main'));
        expect(r.body, contains('Control Center policy'));
        expect(upstream.seen, isEmpty);
        expect(broker.scopes, isEmpty, reason: 'no token for a refused push');
      },
    );

    test(
      'compressed updates still require approval before forwarding',
      () async {
        confirm.answer = false;
        final r = await send(
          'POST',
          pushPath,
          body: gzip.encode(_push(['refs/heads/main'])),
          encoding: 'gzip',
        );
        expect(r.body, contains('ng refs/heads/main'));
        expect(confirm.asked.single.spaceId, 's1');
        expect(upstream.seen, isEmpty);
        expect(broker.scopes, isEmpty);
      },
    );

    test('approved compressed updates preserve the inspected bytes', () async {
      final body = _push(['refs/heads/feature']);
      final r = await send(
        'POST',
        pushPath,
        body: gzip.encode(body),
        encoding: 'gzip',
      );
      expect(r.body, 'upstream-ok');
      expect(confirm.asked.single.spaceId, 's1');
      expect(upstream.seen.single.body, body);
    });

    test('uninspectable updates never become unchecked probes', () async {
      for (final body in [
        utf8.encode('invalid'),
        utf8.encode('0001'),
        _push(['refs/heads/main']).sublist(0, 30),
        utf8.encode('0000unexpected-pack'),
      ]) {
        final r = await send('POST', pushPath, body: body);
        expect(r.status, HttpStatus.badRequest);
      }
      expect(upstream.seen, isEmpty);
      expect(broker.scopes, isEmpty);
      expect(confirm.asked, isEmpty);
    });

    test(
      'malformed pushes drain the upload before returning rejection',
      () async {
        final request = await client.postUrl(
          Uri.parse('http://127.0.0.1:${host.port}$pushPath'),
        );
        request.headers.set(AgentRunLease.tokenHeader, lease.secret);
        request.bufferOutput = false;
        request.add(utf8.encode('invalid'));
        await request.flush();
        request.add(List<int>.filled(256 * 1024, 0));
        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();

        expect(response.statusCode, HttpStatus.badRequest);
        expect(body, contains('push blocked'));
        expect(upstream.seen, isEmpty);
        expect(broker.scopes, isEmpty);
        expect(confirm.asked, isEmpty);
      },
    );

    test('a flush-only probe remains effect-free', () async {
      final r = await send('POST', pushPath, body: utf8.encode('0000'));
      expect(r.body, 'upstream-ok');
      expect(upstream.seen.single.body, utf8.encode('0000'));
      expect(confirm.asked, isEmpty);
    });

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
      expect(confirm.asked, isEmpty);
      final audit = audits.single;
      expect(audit.decision, ActionDecision.deny);
      expect(audit.prompted, isFalse);
      expect(audit.workspaceId, 'w1');
      expect(audit.spaceId, 's1');
      expect(audit.agentId, 'a1');
      expect(audit.actionClasses, ['gitPush']);
      expect(audit.actionSummary, 'git push to acme/widgets');
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

  group('commit signing', () {
    final tree = 'a' * 40;
    String commitText({
      String committer = 'ada@example.com',
      String extra = '',
      String message = 'msg\n',
    }) =>
        'tree $tree\nparent ${'c' * 40}\n'
        'author Ada <ada@example.com> 1700000000 +0100\n'
        'committer Ada <$committer> 1700000000 -0130\n'
        '$extra\n$message';
    final commit = utf8.encode(commitText());

    Future<({int status, String body})> sign(Object body) => send(
      'POST',
      AgentRunLease.signPath,
      body: body is String ? utf8.encode(body) : body as List<int>,
    );

    test('the run\'s own commit is signed by the host signer', () async {
      final r = await sign(commit);

      expect(r.status, 200, reason: r.body);
      expect(r.body, startsWith('-----BEGIN SSH SIGNATURE-----'));
      expect(signer.signed.single, commit);
      expect(confirm.asked, isEmpty);
      expect(audits.single.decision, ActionDecision.allow);
      expect(audits.single.actionClasses, ['gitCommit']);
      expect(audits.single.actionSummary, 'sign git commit');
    });

    test('a merge with a mergetag and an encoding is signed', () async {
      final r = await sign(
        commitText(
          extra:
              'encoding ISO-8859-1\nmergetag object ${'d' * 40}\n'
              ' type commit\n tag v1\n',
          // Latin-1 message bytes are the message's business, not the headers'.
        ),
      );
      expect(r.status, 200, reason: r.body);
    });

    test('a non-UTF-8 message under an encoding header is signed', () async {
      final bytes = [
        ...utf8.encode(commitText(extra: 'encoding ISO-8859-1\n', message: '')),
        0xe9, // é in Latin-1
        0x0a,
      ];
      final r = await sign(bytes);
      expect(r.status, 200, reason: r.body);
    });

    test('a tag with a SHA-256 id, tagged as the run, is signed', () async {
      final r = await sign(
        'object ${'b' * 64}\ntype commit\ntag v1\n'
        'tagger Ada <ada@example.com> 1700000000 +0000\n\nrelease\n',
      );
      expect(r.status, 200, reason: r.body);
      expect(audits.single.actionSummary, 'sign git tag');
    });

    test('only well-formed, unsigned commits and tags are signed', () async {
      const ident = 'Ada <ada@example.com> 1 +0000';
      for (final body in [
        '',
        'arbitrary bytes',
        'certificate version 0.1\npusher $ident\n\n',
        // Starts like a commit, then is not one.
        'tree $tree\ngarbage\n\n',
        'tree $tree\nauthor $ident\n\n',
        'tree $tree\ncommitter $ident\nauthor $ident\n\n',
        'tree xyz\nauthor $ident\ncommitter $ident\n\n',
        'tree $tree\nparent nope\nauthor $ident\ncommitter $ident\n\n',
        'tree $tree\nauthor $ident\ncommitter Ada <ada@example.com>\n\n',
        // No blank line: not a complete object.
        'tree $tree\nauthor $ident\ncommitter $ident\n',
        // Already signed, or carrying headers git never signs.
        commitText(extra: 'gpgsig -----BEGIN SSH SIGNATURE-----\n x\n'),
        commitText(extra: 'gpgsig-sha256 x\n'),
        commitText(extra: 'x-extra 1\n'),
        commitText(extra: ' orphan continuation\n'),
        'object $tree\ntype commit\ntag v1\n\n',
        'object $tree\ntype bogus\ntag v1\ntagger $ident\n\n',
        'object $tree\ntype commit\ntag \ntagger $ident\n\n',
      ]) {
        final r = await sign(body);
        expect(r.status, HttpStatus.badRequest, reason: body);
      }
      final nul = await sign([...commit.take(10), 0, ...commit.skip(10)]);
      expect(nul.status, HttpStatus.badRequest);
      expect(signer.signed, isEmpty);
      expect(audits, isEmpty);
    });

    test('a commit made as anyone but the run is refused', () async {
      final r = await sign(commitText(committer: 'mallory@example.com'));
      expect(r.status, HttpStatus.forbidden);
      expect(r.body, contains('mallory@example.com'));
      expect(signer.signed, isEmpty);
    });

    test('a run without an identity signs nothing', () async {
      final anonymous = (await gateway.open(
        const AgentRunGrant(workspaceId: 'w1', conversationId: 'c2'),
      ))!;
      final r = await send(
        'POST',
        AgentRunLease.signPath,
        body: commit,
        secret: anonymous.secret,
      );
      expect(r.status, HttpStatus.forbidden);
      expect(signer.signed, isEmpty);
    });

    test('a run acting for another member never gets the key', () async {
      owner = false;
      final r = await sign(commit);
      expect(r.status, HttpStatus.forbidden);
      expect(r.body, contains("machine's owner"));
      expect(signer.signed, isEmpty);
    });

    test('a gateway with no owner check signs for nobody', () async {
      final closed = AgentRunGateway(
        guard: ActionGuardService(repository: rules, confirmationPort: confirm),
        broker: broker,
        loopbackBase: () async => Uri.parse('http://127.0.0.1:${host.port}'),
        signer: signer,
      );
      final other = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      other.listen(closed.handle);
      final grant = (await closed.open(
        const AgentRunGrant(
          workspaceId: 'w1',
          conversationId: 'c3',
          committerEmail: 'ada@example.com',
        ),
      ))!;
      try {
        final request = await client.postUrl(
          Uri.parse('http://127.0.0.1:${other.port}${AgentRunLease.signPath}'),
        );
        request.headers.set(AgentRunLease.tokenHeader, grant.secret);
        request.add(commit);
        final response = await request.close();
        await response.drain<void>();
        expect(response.statusCode, HttpStatus.forbidden);
        expect(signer.signed, isEmpty);
      } finally {
        await other.close(force: true);
      }
    });

    test('a denied commit rule refuses to sign, with the reason', () async {
      rule(ActionClass.gitCommit, ActionDecision.deny);
      final r = await sign(commit);
      expect(r.status, HttpStatus.forbidden);
      expect(r.body, contains('Control Center policy'));
      expect(signer.signed, isEmpty);
      expect(audits.single.decision, ActionDecision.deny);
    });

    test('an "ask" commit rule does not prompt a second time', () async {
      rule(ActionClass.gitCommit, ActionDecision.prompt);
      final r = await sign(commit);
      expect(r.status, 200, reason: r.body);
      expect(confirm.asked, isEmpty);
    });

    test('signatures run one at a time', () async {
      signer.hold = Completer<void>();
      final first = sign(commit);
      final second = sign(commit);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(signer.signed, hasLength(1));
      signer.hold!.complete();
      expect((await first).status, 200);
      expect((await second).status, 200);
      expect(signer.maxRunning, 1);
    });

    test('a failed signature does not block the next one', () async {
      signer.failure = const CommitSigningException('agent locked');
      final r = await sign(commit);
      expect(r.status, HttpStatus.badGateway);
      expect(r.body.trim(), 'agent locked');
      signer.failure = null;
      expect((await sign(commit)).status, 200);
    });

    test('an unknown run cannot sign', () async {
      final r = await send(
        'POST',
        AgentRunLease.signPath,
        body: commit,
        secret: 'nope',
      );
      expect(r.status, HttpStatus.unauthorized);
      expect(signer.signed, isEmpty);
    });

    test('the lease hands a run the gateway its shim posts to', () {
      final env = lease.environment(const {});
      expect(env[AgentRunLease.gatewayEnvKey], '${lease.base}');
      expect(env[AgentRunLease.tokenEnvKey], lease.secret);
    });

    test('the sandbox shim speaks the gateway\'s contract', () {
      const shim = MacosSandbox.sshSignShim;
      expect(shim, contains('\$${AgentRunLease.gatewayEnvKey}'));
      expect(shim, contains('\$${AgentRunLease.tokenEnvKey}'));
      expect(shim, contains('${AgentRunLease.tokenHeader}: '));
      expect(shim, contains('${AgentRunLease.signPath}"'));
      expect(shim, contains('\${${MacosSandbox.userSshProgramEnvKey}:-'));
      expect(
        shim,
        contains(
          '--max-time ${AgentRunGateway.signTransportDeadline.inSeconds} ',
        ),
      );
      expect(
        AgentRunGateway.signTransportDeadline,
        greaterThan(HostCommitSigner.signTimeout),
      );
    });
  });

  group('Claude Code command hook', () {
    Future<({int exitCode, String out, String err})> hook(
      String tool,
      String command, {
      String? description = 'Run the command',
      String? secret,
      bool available = true,
    }) async {
      final settings =
          jsonDecode(AgentRunLease.claudeHookSettings(available ? lease : null))
              as Map;
      final entry =
          ((settings['hooks'] as Map)['PreToolUse'] as List).single as Map;
      final handler = (entry['hooks'] as List).single as Map;
      final process = await Process.start(
        'sh',
        ['-c', handler['command'] as String],
        environment: {AgentRunLease.tokenEnvKey: secret ?? lease.secret},
      );
      final out = process.stdout.transform(utf8.decoder).join();
      final err = process.stderr.transform(utf8.decoder).join();
      if (available) {
        process.stdin.write(
          jsonEncode({
            'tool_name': tool,
            'tool_input': {'command': command, 'description': ?description},
          }),
        );
      }
      // The missing-lease hook exits without reading stdin. Closing an empty
      // pipe avoids racing that deliberate exit with a write (EPIPE).
      await process.stdin.close();
      return (exitCode: await process.exitCode, out: await out, err: await err);
    }

    test('a denied rule blocks Bash, with the reason', () async {
      rule(ActionClass.prCreate, ActionDecision.deny);
      final result = await hook('Bash', 'git add -A && gh pr create --fill');
      expect(result.exitCode, 2);
      expect(result.err, contains('Control Center policy'));
      expect(confirm.asked, isEmpty);
    });

    test('approval holds the hook until the operator answers', () async {
      confirm.pending = Completer<bool>();
      confirm.requested = Completer<void>();
      var completed = false;
      final pending = hook('Bash', 'gh pr create').then((result) {
        completed = true;
        return result;
      });
      await confirm.requested!.future;
      expect(completed, isFalse);
      expect(confirm.asked.single.spaceId, 's1');
      // The prompt belongs to the run's own conversation, not to every
      // conversation of the space.
      expect(confirm.asked.single.conversationId, 'c1');
      confirm.pending!.complete(true);
      expect((await pending).exitCode, 0);
    });

    test(
      'Bash rationale is attributed without replacing the full command',
      () async {
        const command = 'gh pr create --fill';
        final result = await hook(
          'Bash',
          command,
          description: 'Open a review request for the current changes',
        );
        expect(result.exitCode, 0);
        expect(
          confirm.asked.single.detail,
          contains('Open a review request for the current changes'),
        );
        expect(confirm.asked.single.command, command);
      },
    );

    const compoundPush =
        r'cd repos/web-app && U="https://x-access-token:${GH_TOKEN}@github.com:443/acme/widgets.git"; '
        r'ARGS=(); for b in feature/a feature/b; do ARGS+=("--force-with-lease=refs/heads/$b:$(git rev-parse origin/$b)"); '
        r'done; git push "${ARGS[@]}" "$U" feature/a:refs/heads/feature/a 2>&1 | cat';
    for (final command in [
      compoundPush,
      'GH_TOKEN=token gh pr create --fill',
      'command gh pr review 12 --approve',
      'cd repo; rm obsolete.dart',
    ]) {
      test('declining a classified action blocks $command', () async {
        confirm.answer = false;
        final result = await hook('Bash', command);
        expect(result.exitCode, 2);
        expect(confirm.asked.single.spaceId, 's1');
        expect(confirm.asked.single.command, command);
        expect(confirm.asked.single.title, isNot(contains('bash:')));
        expect(confirm.asked.single.detail, isNot(contains('Policy:')));
        if (command == 'cd repo; rm obsolete.dart') {
          expect(
            confirm.asked.single.title,
            contains('may delete obsolete.dart'),
          );
        }
        expect(audits.single.decision, ActionDecision.deny);
      });
    }

    test(
      'one push is one prompt: the shell approval answers the gateway',
      () async {
        final shell = await hook('Bash', 'git push -u origin feature/x');
        expect(shell.exitCode, 0);
        expect(confirm.asked.single.title, contains('push to feature/x'));

        final push = await send(
          'POST',
          pushPath,
          body: _push(['refs/heads/feature/x']),
        );
        expect(push.body, 'upstream-ok');
        expect(confirm.asked, hasLength(1));
        expect(audits.last.actionSummary, contains('approved at the shell'));

        // The approval named feature/x; another branch is still asked about.
        final other = await send(
          'POST',
          pushPath,
          body: _push(['refs/heads/feature/other']),
        );
        expect(other.body, 'upstream-ok');
        expect(confirm.asked, hasLength(2));
      },
    );

    test('an unnamed push approval covers only the general ask', () async {
      rule(
        ActionClass.gitPush,
        ActionDecision.prompt,
        constraint: const ActionConstraint(refs: ['main']),
      );
      rule(
        ActionClass.gitPush,
        ActionDecision.deny,
        constraint: const ActionConstraint(refs: ['production']),
      );
      expect((await hook('Bash', 'git push')).exitCode, 0);
      expect(
        confirm.asked.single.title,
        contains('destination branch not specified'),
      );

      final feature = await send(
        'POST',
        pushPath,
        body: _push(['refs/heads/feature/x']),
      );
      expect(feature.body, 'upstream-ok');
      expect(confirm.asked, hasLength(1));

      // A branch-specific ask was never shown that branch.
      confirm.answer = false;
      final main = await send(
        'POST',
        pushPath,
        body: _push(['refs/heads/main']),
      );
      expect(main.body, contains('ng refs/heads/main'));
      expect(confirm.asked, hasLength(2));

      // And a deny is never answered by an approval.
      final prod = await send(
        'POST',
        pushPath,
        body: _push(['refs/heads/production']),
      );
      expect(prod.body, contains('ng refs/heads/production'));
      expect(confirm.asked, hasLength(2));
    });

    test('a declined push leaves the gateway asking', () async {
      confirm.answer = false;
      expect((await hook('Bash', 'git push origin feature/x')).exitCode, 2);
      final push = await send(
        'POST',
        pushPath,
        body: _push(['refs/heads/feature/x']),
      );
      expect(push.body, contains('ng refs/heads/feature/x'));
      expect(confirm.asked, hasLength(2));
    });

    test('a named branch is decided by branch rules at the shell', () async {
      rule(
        ActionClass.gitPush,
        ActionDecision.deny,
        constraint: const ActionConstraint(refs: ['main']),
      );
      final result = await hook('Bash', 'git push origin HEAD:main');
      expect(result.exitCode, 2);
      expect(confirm.asked, isEmpty);
    });

    test('remembering a push remembers its branch family only', () async {
      await hook('Bash', 'git push origin abc123:refs/heads/space/f1ea6d92');
      final named = confirm.asked.single;
      expect(named.rememberChoice, isNotNull);
      expect(
        ActionConstraint.decode(named.constraintJson),
        const ActionConstraint(refs: ['space/**']),
      );

      // Nothing narrow to remember about an unknown destination.
      await hook('Bash', 'git push');
      expect(confirm.asked.last.rememberChoice, isNull);
    });

    test('a remembered branch approval silences both checks', () async {
      rules.list.add(
        ActionPolicyRule(
          id: 'remembered',
          workspaceId: 'w1',
          scopeType: ActionScopeType.space,
          scopeId: 's1',
          actionClass: ActionClass.gitPush,
          decision: ActionDecision.allow,
          provenance: 'remembered',
          constraint: const ActionConstraint(refs: ['space/**']),
          expiresAt: DateTime.now().add(const Duration(hours: 8)),
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      );
      final shell = await hook('Bash', 'git push origin space/abc');
      expect(shell.exitCode, 0);
      final push = await send(
        'POST',
        pushPath,
        body: _push(['refs/heads/space/abc']),
      );
      expect(push.body, 'upstream-ok');
      expect(confirm.asked, isEmpty);
    });

    test('an ordinary command passes without asking', () async {
      final result = await hook('Bash', 'ls -la');
      expect(result.exitCode, 0);
      expect(confirm.asked, isEmpty);
    });

    test('a Bash call without a description is denied unasked', () async {
      for (final description in [null, '  ']) {
        final result = await hook(
          'Bash',
          'gh pr create',
          description: description,
        );
        expect(result.exitCode, 2);
        expect(result.err, contains('description'));
      }
      expect(confirm.asked, isEmpty);
    });

    test('invalid hook input never authorizes a command', () async {
      final result = await hook('Read', 'whatever');
      expect(result.exitCode, 2);
      expect(confirm.asked, isEmpty);
    });

    test('an expired run cannot fail open through HTTP 401', () async {
      await gateway.close(lease);
      final result = await hook('Bash', 'gh pr create');
      expect(result.exitCode, 2);
      expect(confirm.asked, isEmpty);
    });

    test(
      'policy lookup failure blocks instead of allowing on HTTP 500',
      () async {
        rules.fail = true;
        final result = await hook('Bash', 'gh pr review --approve');
        expect(result.exitCode, 2);
        expect(confirm.asked, isEmpty);
      },
    );

    for (final reply in ['', '{"unexpected":"response"}']) {
      test(
        '${reply.isEmpty ? 'empty' : 'invalid'} HTTP 200 response still blocks',
        () async {
          hookReply = reply;
          final result = await hook('Bash', 'git push');
          expect(result.exitCode, 2);
          expect(confirm.asked, isEmpty);
        },
      );
    }

    test('a missing lease installs a blocking hook', () async {
      final result = await hook('Bash', 'git push', available: false);
      expect(result.exitCode, 2);
      expect(result.err, contains('permission gateway is unavailable'));
      expect(hookRequests, 0);
      expect(confirm.asked, isEmpty);
    });

    test(
      'an unreachable gateway blocks instead of skipping approval',
      () async {
        await host.close(force: true);
        final result = await hook('Bash', 'git push');
        expect(result.exitCode, 2);
        expect(confirm.asked, isEmpty);
      },
    );
  }, skip: Platform.isWindows ? 'Requires the POSIX hook shell and curl.' : false);
}
