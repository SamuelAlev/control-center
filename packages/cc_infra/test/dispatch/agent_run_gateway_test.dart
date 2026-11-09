import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/repositories/action_policy_repository.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_constraint.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/autonomy_level.dart';
import 'package:cc_harness/tools.dart' show ActionClass;
import 'package:cc_infra/src/dispatch/agent_run_gateway.dart';
import 'package:cc_infra/src/dispatch/host_commit_signer.dart';
import 'package:cc_infra/src/dispatch/pushed_commit_inspector.dart';
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
  Object? mintError;
  var _n = 0;

  @override
  Future<ScopedCredentials> mint({
    required String conversationId,
    required ForgeTokenScope scope,
    String? repoOwner,
    String? repoName,
    String? actingUserId,
    String? workspaceId,
    bool personal = false,
  }) async {
    scopes.add(scope);
    if (mintError case final e?) {
      throw e;
    }
    // Let a concurrent caller reach the mint before this one returns.
    await Future<void>.delayed(const Duration(milliseconds: 20));
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
      if (request.method == 'GET') {
        request.response
          ..statusCode = 200
          ..headers.set(
            HttpHeaders.contentTypeHeader,
            'application/x-git-receive-pack-advertisement',
          )
          ..write(advertisement);
        await request.response.close();
        return;
      }
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

  /// GitHub's receive-pack ref advertisement, as smart HTTP serves it.
  static final String advertisement = [
    _pkt('# service=git-receive-pack\n'),
    '0000',
    _pkt(
      '${'2' * 40} refs/heads/main\u0000report-status side-band-64k '
      'ofs-delta agent=github/test\n',
    ),
    _pkt('${'3' * 40} refs/heads/dev\n'),
    '0000',
  ].join();
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
  late List<PushedGitObject> inspected;
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
    inspected = [];
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
      inspectPack: (_) async => inspected,
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
      AgentRunGrant(
        workspaceId: 'w1',
        conversationId: 'c1',
        agentId: 'a1',
        spaceId: 's1',
        repoOwner: 'acme',
        repoName: 'widgets',
        identity: AgentCommitIdentity.owner(
          name: 'Ada',
          email: 'Ada@Example.com',
        ),
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

  group('MCP run grant', () {
    test('a live secret proves its own run', () {
      final scope = gateway.mcpScopeFor(lease.secret);

      expect(scope?.attested, isTrue);
      expect(scope?.workspaceId, isNotEmpty);
    });

    test('an unknown secret proves nothing', () {
      expect(gateway.mcpScopeFor('guessed'), isNull);
    });

    test('a closed run proves nothing', () async {
      final closing = (await gateway.open(
        const AgentRunGrant(workspaceId: 'ws', conversationId: 'c'),
      ))!;
      await gateway.close(closing);

      expect(gateway.mcpScopeFor(closing.secret), isNull);
    });

    test('configs that differ only in the run secret compare equal', () {
      String config(String secret) =>
          '{"headers":{"${AgentRunLease.tokenHeader}": "$secret","a":"b"}}';

      expect(
        AgentRunLease.withoutRunSecret(config('one')),
        AgentRunLease.withoutRunSecret(config('two')),
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

    test('discovery asks git for a self-contained (no-thin) pack', () async {
      final r = await send('GET', advertPath);
      expect(r.status, 200);
      expect(
        r.body,
        contains(
          '\u0000report-status side-band-64k ofs-delta agent=github/test '
          'no-thin\n',
        ),
      );
      // Every pkt-line length still matches its payload.
      expect(
        AgentRunGateway.withNoThin(utf8.encode(r.body)),
        utf8.encode(r.body),
      );
      expect(r.body, contains('refs/heads/dev\n'));
    });

    test('an advertisement that is not one is not forwarded', () {
      expect(AgentRunGateway.withNoThin(utf8.encode('upstream-ok')), isNull);
      expect(AgentRunGateway.withNoThin(utf8.encode('0000')), isNull);
    });

    test('pushed commits must carry the run\'s identity', () async {
      rule(ActionClass.gitPush, ActionDecision.allow);
      inspected = [
        const PushedGitObject(
          kind: 'commit',
          oid: 'abcdef0123456789',
          authorEmail: 'mallory@example.com',
          committerEmail: 'ada@example.com',
          signed: false,
          signedOff: false,
        ),
      ];
      final r = await send(
        'POST',
        pushPath,
        body: _push(['refs/heads/feature/x']),
      );
      expect(r.status, 200);
      expect(r.body, contains('ng refs/heads/feature/x'));
      expect(r.body, contains('authored by mallory@example.com'));
      expect(upstream.seen, isEmpty);
    });

    test('a Signed-off-by trailer is refused on any run', () async {
      rule(ActionClass.gitPush, ActionDecision.allow);
      inspected = [
        const PushedGitObject(
          kind: 'commit',
          oid: 'abcdef0123456789',
          authorEmail: 'ada@example.com',
          committerEmail: 'ada@example.com',
          signed: false,
          signedOff: true,
        ),
      ];
      final r = await send(
        'POST',
        pushPath,
        body: _push(['refs/heads/feature/x']),
      );
      expect(r.body, contains('Signed-off-by'));
      expect(upstream.seen, isEmpty);
    });

    test('the owner\'s own matching commits are forwarded', () async {
      rule(ActionClass.gitPush, ActionDecision.allow);
      inspected = [
        const PushedGitObject(
          kind: 'commit',
          oid: 'abcdef0123456789',
          authorEmail: 'Ada@Example.com',
          committerEmail: 'ada@example.com',
          signed: true,
          signedOff: false,
        ),
      ];
      final body = _push(['refs/heads/feature/x']);
      final r = await send('POST', pushPath, body: body);
      expect(r.body, 'upstream-ok');
      expect(upstream.seen.single.body, body);
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

    test('a run whose identity may not use the key is refused', () async {
      final member = (await gateway.open(
        AgentRunGrant(
          workspaceId: 'w1',
          conversationId: 'c4',
          actingUserId: 'u2',
          identity: AgentCommitIdentity.member(
            name: 'Ada',
            email: 'ada@example.com',
          ),
        ),
      ))!;
      final r = await send(
        'POST',
        AgentRunLease.signPath,
        body: commit,
        secret: member.secret,
      );
      expect(r.status, HttpStatus.forbidden);
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
        AgentRunGrant(
          workspaceId: 'w1',
          conversationId: 'c3',
          identity: AgentCommitIdentity.owner(
            name: 'Ada',
            email: 'ada@example.com',
          ),
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

    Map<String, String> configOf(Map<String, String> env) => {
      for (var i = 0; i < int.parse(env['GIT_CONFIG_COUNT']!); i++)
        env['GIT_CONFIG_KEY_$i']!: env['GIT_CONFIG_VALUE_$i']!,
    };

    test('an owner run keeps its signing config', () {
      final config = configOf(lease.environment(const {}));
      expect(config, isNot(contains('commit.gpgsign')));
      expect(config, isNot(contains('gpg.ssh.program')));
    });

    test('a member or unrequested run commits unsigned with every signer '
        'stripped', () async {
      for (final identity in [
        AgentCommitIdentity.member(name: 'Bo', email: 'bo@example.com'),
        AgentCommitIdentity.unrequested(),
        null,
      ]) {
        final run = (await gateway.open(
          AgentRunGrant(
            workspaceId: 'w1',
            conversationId: 'c-${identity.hashCode}',
            identity: identity,
          ),
        ))!;
        final config = configOf(run.environment(const {}));
        expect(config['commit.gpgsign'], 'false', reason: '$identity');
        expect(config['tag.gpgsign'], 'false');
        expect(config['push.gpgsign'], 'false');
        expect(config['gpg.program'], 'false');
        expect(config['gpg.ssh.program'], 'false');
        expect(config['gpg.x509.program'], 'false');
        await gateway.close(run);
      }
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

  group('fetching the run\'s own repo', () {
    const token = 'run-forge-token';
    late Directory home;
    late File helperLog;

    setUp(() {
      home = Directory.systemTemp.createTempSync('cc_lease_fetch');
      helperLog = File('${home.path}/user_helper.log');
      // The shape that broke fetches: every GitHub URL rewritten to SSH, plus
      // user credential helpers that must never see the run's token.
      File('${home.path}/gitconfig').writeAsStringSync('''
[credential]
\thelper = "!f() { cat >> '${helperLog.path}'; echo \\"op=\$1\\" >> '${helperLog.path}'; }; f"
[url "git@github.com:"]
\tinsteadOf = "https://github.com/"
''');
    });

    tearDown(() => home.deleteSync(recursive: true));

    Map<String, String> gitEnv(
      AgentRunLease run, {
      String? forgeToken = token,
    }) {
      final env = <String, String>{
        'GIT_CONFIG_GLOBAL': '${home.path}/gitconfig',
        'GIT_CONFIG_NOSYSTEM': '1',
        'GIT_TERMINAL_PROMPT': '0',
        'GH_TOKEN': ?forgeToken,
      };
      return {...env, ...run.environment(env)};
    }

    Future<ProcessResult> git(
      List<String> args,
      Map<String, String> env, {
      String? input,
    }) async {
      final process = await Process.start(
        'git',
        args,
        workingDirectory: home.path,
        environment: env,
      );
      process.stdin.write(input ?? '');
      await process.stdin.close();
      final out = process.stdout.transform(utf8.decoder).join();
      final err = process.stderr.transform(utf8.decoder).join();
      return ProcessResult(
        process.pid,
        await process.exitCode,
        await out,
        await err,
      );
    }

    /// Fetch and push URLs for a remote at [url], as git resolves them.
    Future<({String fetch, String push})> urls(
      String url,
      Map<String, String> env,
    ) async {
      final repo = Directory('${home.path}/repo');
      if (repo.existsSync()) {
        repo.deleteSync(recursive: true);
      }
      await git(['init', '-q', repo.path], env);
      await git(['-C', repo.path, 'remote', 'add', 'origin', url], env);
      Future<String> get(List<String> extra) async =>
          ((await git([
                    '-C',
                    repo.path,
                    'remote',
                    'get-url',
                    ...extra,
                    'origin',
                  ], env)).stdout
                  as String)
              .trim();
      return (fetch: await get(const []), push: await get(const ['--push']));
    }

    Future<String> fill(String url, Map<String, String> env) async =>
        (await git(['credential', 'fill'], env, input: 'url=$url\n\n')).stdout
            as String;

    test(
      'every origin spelling fetches over HTTPS and pushes to the gateway',
      () async {
        final env = gitEnv(lease);
        final gateway = '${lease.base}/agent/git/github.com/acme/widgets.git';
        for (final origin in const [
          'git@github.com:acme/widgets.git',
          'ssh://git@github.com/acme/widgets.git',
          'https://github.com/acme/widgets.git',
        ]) {
          final resolved = await urls(origin, env);
          expect(resolved.fetch, 'https://github.com/acme/widgets.git');
          expect(resolved.push, gateway);
        }
      },
    );

    test(
      'offers the token for the run\'s repo, with or without .git',
      () async {
        final env = gitEnv(lease);
        for (final url in const [
          'https://github.com/acme/widgets.git',
          'https://github.com/acme/widgets',
        ]) {
          final filled = await fill(url, env);
          expect(filled, contains('username=x-access-token\n'));
          expect(filled, contains('password=$token\n'));
        }
        expect(helperLog.existsSync(), isFalse);
      },
    );

    test('never offers the token for any other repo', () async {
      final env = gitEnv(lease);
      for (final url in const [
        'https://github.com/acme/widgets-extra.git',
        'https://github.com/acme/widgets.gitx',
        'https://github.com/other/widgets.git',
        'https://example.com/acme/widgets.git',
        'https://evil.example/https://github.com/acme/widgets.git',
      ]) {
        expect(await fill(url, env), isNot(contains(token)));
      }
    });

    test('other repos keep the user\'s own routing', () async {
      final resolved = await urls(
        'git@github.com:other/repo.git',
        gitEnv(lease),
      );
      expect(resolved.fetch, 'git@github.com:other/repo.git');
    });

    test('git never hands the token to the user\'s helpers to store', () async {
      final env = gitEnv(lease);
      final approved = await git(
        ['credential', 'approve'],
        env,
        input:
            'protocol=https\nhost=github.com\npath=acme/widgets.git\n'
            'username=x-access-token\npassword=$token\n\n',
      );
      expect(approved.exitCode, 0);
      expect(approved.stderr, isEmpty);
      expect(helperLog.existsSync(), isFalse);
    });

    test('a run without a forge token keeps its origin', () async {
      final resolved = await urls(
        'git@github.com:acme/widgets.git',
        gitEnv(lease, forgeToken: null),
      );
      expect(resolved.fetch, 'git@github.com:acme/widgets.git');
    });

    test('a repo name unfit for a config key adds no fetch routing', () async {
      for (final (owner, name) in const [
        ('acme', '..'),
        ('..', 'widgets'),
        ('acme', 'wid gets'),
        ('acme/x', 'widgets'),
        ('acme', 'widgets\nhelper'),
        ('-acme', 'widgets'),
      ]) {
        final run = (await gateway.open(
          AgentRunGrant(
            workspaceId: 'w1',
            conversationId: 'c1',
            repoOwner: owner,
            repoName: name,
          ),
        ))!;
        expect(run.fetchGitConfig, isEmpty);
        await gateway.close(run);
      }
    });

    test('a run with no repo adds no fetch routing', () async {
      final run = (await gateway.open(
        const AgentRunGrant(workspaceId: 'w1', conversationId: 'c1'),
      ))!;
      expect(run.fetchGitConfig, isEmpty);
      await gateway.close(run);
    });

    test('the environment never carries the token itself', () {
      final added = lease.environment(const {'GH_TOKEN': token});
      expect(added.values.where((value) => value.contains(token)), isEmpty);
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

    /// Runs the real hook for one of Claude Code's own tools, on a run whose
    /// working tree is [worktree].
    Future<({int exitCode, String err})> nativeHook(
      String tool,
      Map<String, Object?> input, {
      required String worktree,
      List<String> stateDirs = const [],
      Mode mode = Mode.chat,
    }) async {
      final run = (await gateway.open(
        AgentRunGrant(
          workspaceId: 'w1',
          conversationId: 'c1',
          agentId: 'a1',
          spaceId: 's1',
          mode: mode,
          worktreeRoot: worktree,
          runnerStateDirs: stateDirs,
        ),
      ))!;
      final settings = jsonDecode(AgentRunLease.claudeHookSettings(run)) as Map;
      final entry =
          ((settings['hooks'] as Map)['PreToolUse'] as List).single as Map;
      final handler = (entry['hooks'] as List).single as Map;
      final process = await Process.start(
        'sh',
        ['-c', handler['command'] as String],
        environment: {AgentRunLease.tokenEnvKey: run.secret},
      );
      final err = process.stderr.transform(utf8.decoder).join();
      unawaited(process.stdout.drain<void>());
      process.stdin.write(jsonEncode({'tool_name': tool, 'tool_input': input}));
      await process.stdin.close();
      return (exitCode: await process.exitCode, err: await err);
    }

    group('native tools', () {
      late Directory tree;

      setUp(() => tree = Directory.systemTemp.createTempSync('cc-hook-tree-'));
      tearDown(() => tree.deleteSync(recursive: true));

      test('the hook matches every tool the policy has a rule for', () {
        final settings =
            jsonDecode(AgentRunLease.claudeHookSettings(lease)) as Map;
        final entry =
            ((settings['hooks'] as Map)['PreToolUse'] as List).single as Map;

        expect((entry['matcher'] as String).split('|'), {
          'Bash',
          'Write',
          'Edit',
          'MultiEdit',
          'NotebookEdit',
          'WebFetch',
          'WebSearch',
        });
      });

      test('without a lease only Bash is blocked', () {
        final settings =
            jsonDecode(AgentRunLease.claudeHookSettings(null)) as Map;
        final entry =
            ((settings['hooks'] as Map)['PreToolUse'] as List).single as Map;

        expect(entry['matcher'], 'Bash');
      });

      test('a write inside the worktree asks nothing', () async {
        rule(ActionClass.fileWriteOutsideWorktree, ActionDecision.deny);

        final result = await nativeHook('Write', {
          'file_path': '${tree.path}/lib/new.dart',
          'content': 'x',
        }, worktree: tree.path);

        expect(result.exitCode, 0);
      });

      test('a write outside the worktree meets the rule', () async {
        rule(ActionClass.fileWriteOutsideWorktree, ActionDecision.deny);

        for (final tool in ['Write', 'Edit', 'MultiEdit']) {
          final result = await nativeHook(tool, {
            'file_path': '/somewhere/else.txt',
          }, worktree: tree.path);

          expect(result.exitCode, 2, reason: tool);
          expect(result.err, contains('Control Center policy'), reason: tool);
        }
      });

      test('a notebook names its path differently', () async {
        rule(ActionClass.fileWriteOutsideWorktree, ActionDecision.deny);

        final result = await nativeHook('NotebookEdit', {
          'notebook_path': '/somewhere/else.ipynb',
        }, worktree: tree.path);

        expect(result.exitCode, 2);
      });

      test('dot-dots cannot walk a write out', () async {
        rule(ActionClass.fileWriteOutsideWorktree, ActionDecision.deny);

        final result = await nativeHook('Write', {
          'file_path': '${tree.path}/a/../../escape.txt',
        }, worktree: tree.path);

        expect(result.exitCode, 2);
      });

      test('a symlink cannot walk a write out', () async {
        rule(ActionClass.fileWriteOutsideWorktree, ActionDecision.deny);
        final outside = Directory.systemTemp.createTempSync('cc-hook-out-');
        addTearDown(() => outside.deleteSync(recursive: true));
        Link('${tree.path}/link').createSync(outside.path);

        final result = await nativeHook('Write', {
          'file_path': '${tree.path}/link/new.txt',
        }, worktree: tree.path);

        expect(result.exitCode, 2);
      });

      test('a read-only mode still writes its own plan file', () async {
        final state = Directory.systemTemp.createTempSync('cc-hook-state-');
        addTearDown(() => state.deleteSync(recursive: true));

        final plan = await nativeHook(
          'Write',
          {'file_path': '${state.path}/plans/plan.md'},
          worktree: tree.path,
          stateDirs: [state.path],
          mode: Mode.plan,
        );
        final elsewhere = await nativeHook(
          'Write',
          {'file_path': '/somewhere/else.txt'},
          worktree: tree.path,
          stateDirs: [state.path],
          mode: Mode.plan,
        );

        expect(plan.exitCode, 0);
        expect(elsewhere.exitCode, 2);
      });

      test('a file larger than a megabyte reaches the policy', () async {
        final result = await nativeHook('Write', {
          'file_path': '${tree.path}/big.txt',
          'content': 'x' * (3 * 1024 * 1024),
        }, worktree: tree.path);

        expect(result.exitCode, 0);
      });

      test('web tools meet the egress rule', () async {
        rule(ActionClass.networkEgress, ActionDecision.deny);

        final fetch = await nativeHook('WebFetch', {
          'url': 'https://example.com/a',
          'prompt': 'read it',
        }, worktree: tree.path);
        final search = await nativeHook('WebSearch', {
          'query': 'dart',
        }, worktree: tree.path);

        expect(fetch.exitCode, 2);
        expect(search.exitCode, 2);
      });

      test('a host rule can tell one fetch from another', () async {
        rule(
          ActionClass.networkEgress,
          ActionDecision.deny,
          constraint: const ActionConstraint(hosts: ['example.com']),
        );

        final blocked = await nativeHook('WebFetch', {
          'url': 'https://example.com/a',
        }, worktree: tree.path);
        final allowed = await nativeHook('WebFetch', {
          'url': 'https://dart.dev/a',
        }, worktree: tree.path);

        expect(blocked.exitCode, 2);
        expect(allowed.exitCode, 0);
      });

      test('a tool that does not say what it touches is refused', () async {
        final result = await nativeHook('Write', {
          'content': 'x',
        }, worktree: tree.path);

        expect(result.exitCode, 2);
        expect(result.err, contains('invalid tool permission request'));
      });
    });

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
        r'cd repos/shop-ui && U="https://x-access-token:${GH_TOKEN}@github.com:443/acme/widgets.git"; '
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

  group(
    'audit fixes',
    () {
      late Directory tree;

      setUp(() => tree = Directory.systemTemp.createTempSync('cc-gw-tree-'));
      tearDown(() => tree.deleteSync(recursive: true));

      Future<AgentRunLease> openRun({
        List<String> shared = const [],
        AutonomyLevel? autonomy,
      }) async => (await gateway.open(
        AgentRunGrant(
          workspaceId: 'w1',
          conversationId: 'c1',
          agentId: 'a1',
          spaceId: 's1',
          worktreeRoot: tree.path,
          sharedWorktreeRoots: shared,
          autonomy: () async => autonomy,
        ),
      ))!;

      Future<({int exitCode, String err})> runHook(
        AgentRunLease run,
        String tool,
        Map<String, Object?> input,
      ) async {
        final settings =
            jsonDecode(AgentRunLease.claudeHookSettings(run)) as Map;
        final entry =
            ((settings['hooks'] as Map)['PreToolUse'] as List).single as Map;
        final handler = (entry['hooks'] as List).single as Map;
        final process = await Process.start(
          'sh',
          ['-c', handler['command'] as String],
          environment: {AgentRunLease.tokenEnvKey: run.secret},
        );
        final err = process.stderr.transform(utf8.decoder).join();
        unawaited(process.stdout.drain<void>());
        process.stdin.write(
          jsonEncode({'tool_name': tool, 'tool_input': input}),
        );
        await process.stdin.close();
        return (exitCode: await process.exitCode, err: await err);
      }

      test(
        'a write through the shared repos link stays inside the run',
        () async {
          rule(ActionClass.fileWriteOutsideWorktree, ActionDecision.deny);
          final shared = Directory.systemTemp.createTempSync('cc-gw-shared-');
          addTearDown(() => shared.deleteSync(recursive: true));
          Link('${tree.path}/repos').createSync(shared.path);
          final run = await openRun(shared: [shared.path]);

          final result = await runHook(run, 'Write', {
            'file_path': '${tree.path}/repos/widgets/lib/a.dart',
            'content': 'x',
          });

          expect(result.exitCode, 0, reason: result.err);
        },
      );

      test('propose-only refuses a write policy allows', () async {
        rule(ActionClass.fileWriteOutsideWorktree, ActionDecision.allow);
        final run = await openRun(autonomy: AutonomyLevel.proposeOnly);

        final result = await runHook(run, 'Write', {
          'file_path': '/somewhere/else.txt',
          'content': 'x',
        });

        expect(result.exitCode, 2);
        expect(result.err, contains('propose-only'));
      });

      test(
        'closing the lease withdraws the approval it was waiting on',
        () async {
          rule(ActionClass.fileWriteOutsideWorktree, ActionDecision.prompt);
          confirm
            ..pending = Completer<bool>()
            ..requested = Completer<void>();
          final run = await openRun();

          final hooked = runHook(run, 'Write', {
            'file_path': '/somewhere/else.txt',
            'content': 'x',
          });
          await confirm.requested!.future;
          final withdrawn = confirm.asked.single.withdrawn;
          expect(withdrawn, isNotNull);

          await gateway.close(run);
          await withdrawn!.timeout(const Duration(seconds: 5));
          confirm.pending!.complete(false);
          expect((await hooked).exitCode, 2);
        },
      );

      test('concurrent pushes share one write-token mint', () async {
        rule(ActionClass.gitPush, ActionDecision.allow);

        final results = await Future.wait([
          send('POST', pushPath, body: _push(['refs/heads/feature/a'])),
          send('POST', pushPath, body: _push(['refs/heads/feature/b'])),
        ]);

        expect(results.map((r) => r.status), everyElement(200));
        expect(broker.scopes, [ForgeTokenScope.write]);
      });

      test('a failure never echoes its detail to the agent', () async {
        rule(ActionClass.gitPush, ActionDecision.allow);
        broker.mintError = StateError('token ghs_leakedsecret rejected');

        final r = await send('POST', pushPath, body: _push(['refs/heads/x']));

        expect(r.body, isNot(contains('ghs_leakedsecret')));
      });
    },
    skip: Platform.isWindows
        ? 'Requires the POSIX hook shell and curl.'
        : false,
  );
}
