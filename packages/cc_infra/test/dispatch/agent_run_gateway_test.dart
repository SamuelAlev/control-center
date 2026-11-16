import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/dispatch/domain/ports/commit_signing_port.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/repositories/action_policy_repository.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_constraint.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/autonomy_level.dart';
import 'package:cc_domain/features/sandboxing/domain/network_baseline.dart';
import 'package:cc_harness/tools.dart' show ActionClass;
import 'package:cc_infra/src/dispatch/agent_run_gateway.dart';
import 'package:cc_infra/src/dispatch/pushed_commit_inspector.dart';
import 'package:cc_infra/src/git/ssh_commit_signature.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/network/forge_git_auth.dart';
import 'package:cc_infra/src/process/agent_run_client_launcher.dart';
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

/// Signs with the keys it was given, as the server's key store does.
class _Signing implements CommitSigningPort {
  _Signing(this.keys);

  final Map<String, SshSigningKey> keys;
  final List<List<int>> signed = [];

  @override
  Future<String?> publicKeyOf(String userId) async => keys[userId]?.publicKey;

  @override
  Future<String> sign(String userId, String publicKey, List<int> commit) async {
    final key = keys[userId];
    if (key == null || key.publicKey != publicKey) {
      throw const CommitSigningUnavailable('no commit signing key any more.');
    }
    signed.add(commit);
    return key.sign(commit);
  }
}

class _Broker implements CredentialBrokerPort {
  final List<ForgeTokenScope> scopes = [];
  final List<bool> personal = [];
  final List<String> repos = [];
  final List<String?> actors = [];
  final List<String> revoked = [];
  Object? mintError;

  /// When set, the broker refuses: no token, and this note (when it has
  /// words) says why.
  String? refusal;

  /// When set, a mint signals [minting] and waits here before it answers.
  Completer<void>? gate;
  final minting = Completer<void>();
  var _n = 0;

  /// The token minted at [scope] for the repository named [name]. The run's
  /// own `widgets` keeps the short form.
  static String token(ForgeTokenScope scope, [String name = 'widgets']) =>
      name == 'widgets' ? '${scope.name}-tok' : '${scope.name}-tok-$name';

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
    this.personal.add(personal);
    repos.add('$repoOwner/$repoName');
    actors.add(actingUserId);
    if (mintError case final e?) {
      throw e;
    }
    if (gate case final gate?) {
      if (!minting.isCompleted) {
        minting.complete();
      }
      await gate.future;
    }
    // Let a concurrent caller reach the mint before this one returns.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    _n++;
    if (refusal case final note?) {
      return ScopedCredentials(
        handle: 'h$_n',
        environment: const {},
        notes: [if (note.isNotEmpty) note],
      );
    }
    return ScopedCredentials(
      handle: 'h$_n',
      environment: {'GH_TOKEN': token(scope, repoName ?? 'widgets')},
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
  }

  @override
  Future<void> revoke(String handle) async => revoked.add(handle);
}

/// Why a test that runs the run's shell helpers is skipped on Windows.
final Object _needsPosixShell = Platform.isWindows
    ? 'Requires a POSIX shell.'
    : false;

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
    // What GitHub merely stores for others: a fork's tip and a pull
    // request's head. Neither is a branch or tag of this repository.
    _pkt('${'8' * 40} refs/pull/7/head\n'),
    _pkt('${'9' * 40} .have\n'),
    '0000',
  ].join();
}

String _pkt(String line) =>
    '${(line.length + 4).toRadixString(16).padLeft(4, '0')}$line';

/// A fake forge's smart-HTTP fetch side, and what it saw.
class _Forge {
  _Forge(this.server) {
    server.listen((request) async {
      final body = await request.fold<List<int>>([], (a, b) => a..addAll(b));
      seen.add((
        method: request.method,
        path: request.uri.path,
        query: request.uri.query,
        auth: request.headers.value(HttpHeaders.authorizationHeader),
        encoding: request.headers.value(HttpHeaders.contentEncodingHeader),
        gitProtocol: request.headers.value('git-protocol'),
        cookie: request.headers.value(HttpHeaders.cookieHeader),
        body: body,
      ));
      if (answer case final answer?) {
        await answer(request.response);
        await request.response.close();
        return;
      }
      final advertising = request.method == 'GET';
      request.response
        ..statusCode = 200
        ..headers.set(
          HttpHeaders.contentTypeHeader,
          advertising
              ? 'application/x-git-upload-pack-advertisement'
              : 'application/x-git-upload-pack-result',
        )
        ..write(advertising ? advertisement : 'pack-bytes');
      await request.response.close();
    });
  }

  final HttpServer server;

  /// When set, answers in place of the default advertisement or pack.
  Future<void> Function(HttpResponse response)? answer;

  final List<
    ({
      String method,
      String path,
      String query,
      String? auth,
      String? encoding,
      String? gitProtocol,
      String? cookie,
      List<int> body,
    })
  >
  seen = [];

  /// An upload-pack ref advertisement (protocol v0), as smart HTTP serves it.
  static final String advertisement = [
    _pkt('# service=git-upload-pack\n'),
    '0000',
    _pkt('${'2' * 40} HEAD\u0000multi_ack side-band-64k ofs-delta\n'),
    _pkt('${'2' * 40} refs/heads/main\n'),
    '0000',
  ].join();
}

final _zero = '0' * 40;

/// The run's own repository in most tests.
const _widgets = (forge: ForgeHost.github, owner: 'acme', name: 'widgets');
final _one = '1' * 40;

/// Control Center's co-author line on a person's commit.
const _ccTrailer = 'Co-Authored-By: Control Center <hi@usectrl.dev>';

/// The default run: Ada asked for it, attribution on, no signing key.
final _adaIdentity = AgentCommitIdentity.person((
  name: 'Ada',
  email: 'Ada@Example.com',
), creditAgent: true);

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
  late List<PushedGitObject> inspected;
  var linked = <String>{};
  var refusedActors = <String>{};
  final checkedActors = <String?>[];
  String? hookReply;
  var hookRequests = 0;

  /// What the fake GitHub answers when asked whether a commit is reachable
  /// from a base, and what it was asked.
  bool? Function(String base, String oid) publishedOn = (_, _) => false;
  final ancestryAsked =
      <({String repo, String base, String oid, String token})>[];

  setUp(() async {
    rules = _Rules();
    confirm = _Confirm();
    broker = _Broker();
    // The run's own repo is linked; the check applies to it too.
    linked = {'acme/widgets'};
    refusedActors = {};
    checkedActors.clear();
    audits = [];
    // By default the pack carries the pushed tip: a well-formed commit of
    // the person who asked for the run.
    inspected = [
      PushedGitObject(
        kind: 'commit',
        oid: _one,
        authorName: 'Ada',
        authorEmail: 'Ada@Example.com',
        committerName: 'Ada',
        committerEmail: 'Ada@Example.com',
        signed: false,
        signedOff: false,
        coAuthors: const [_ccTrailer],
        creditedCoAuthors: const [_ccTrailer],
      ),
    ];
    hookReply = null;
    hookRequests = 0;
    publishedOn = (_, _) => false;
    ancestryAsked.clear();
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
      repoAllowed: (ws, owner, name, actor) async {
        checkedActors.add(actor);
        return linked.contains('$owner/$name') &&
            !refusedActors.contains(actor);
      },
      forgeBases: {
        ForgeHost.github: Uri.parse('http://127.0.0.1:${upstream.server.port}'),
      },
      inspectPack: (_) async => inspected,
      ancestry:
          ({
            required owner,
            required name,
            required base,
            required oid,
            required token,
          }) async {
            ancestryAsked.add((
              repo: '$owner/$name',
              base: base,
              oid: oid,
              token: token,
            ));
            return publishedOn(base, oid);
          },
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
        repos: const [_widgets],
        identity: _adaIdentity,
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

    test('the owner\'s personal MCP servers come only from the grant',
        () async {
      expect(gateway.mcpScopeFor(lease.secret)?.personalMcp, isFalse);
      final accountable = (await gateway.open(
        const AgentRunGrant(
          workspaceId: 'ws',
          conversationId: 'c',
          personalMcp: true,
        ),
      ))!;
      addTearDown(() => gateway.close(accountable));
      final scope = gateway.mcpScopeFor(accountable.secret)!;
      expect(scope.personalMcp, isTrue);
      expect(scope.toolView.includePersonal, isTrue);
      expect(scope.toolView.workspaceId, 'ws');
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

    test('GitHub\'s compressed answer comes back plain, and says so', () async {
      rule(ActionClass.gitPush, ActionDecision.allow);
      // The gateway's client asks for gzip and decodes it on the way.
      upstream.server.autoCompress = true;
      client.autoUncompress = false;
      final request = await client.openUrl(
        'POST',
        Uri.parse('http://127.0.0.1:${host.port}$pushPath'),
      );
      request.headers.set(AgentRunLease.tokenHeader, lease.secret);
      request.add(_push(['refs/heads/feature/x']));

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      expect(response.statusCode, 200);
      expect(response.headers.value(HttpHeaders.contentEncodingHeader), isNull);
      expect(body, 'upstream-ok');
      expect(upstream.seen, hasLength(1));
    });

    test(
      'a forwarded push records its branches for the run, a refused one not',
      () async {
        rule(
          ActionClass.gitPush,
          ActionDecision.deny,
          constraint: const ActionConstraint(refs: ['main']),
        );
        rule(ActionClass.gitPush, ActionDecision.allow);
        await send('POST', pushPath, body: _push(['refs/heads/feature/x']));
        await send('POST', pushPath, body: _push(['refs/heads/main']));

        final runs = gateway.openRuns(workspaceId: 'w1', conversationId: 'c1');
        expect(runs, hasLength(1));
        expect(runs.single.pushed('ACME', 'widgets', 'feature/x'), isTrue);
        expect(runs.single.pushed('acme', 'widgets', 'main'), isFalse);
        expect(runs.single.pushed('acme', 'other', 'feature/x'), isFalse);
        expect(
          runs.single.pushedAt('acme', 'widgets', 'feature/x', _one),
          isTrue,
          reason: 'the run pushed exactly this commit',
        );
        expect(
          runs.single.pushedAt(
            'acme',
            'widgets',
            'feature/x',
            _one.substring(0, 12).toUpperCase(),
          ),
          isTrue,
        );
        expect(
          runs.single.pushedAt('acme', 'widgets', 'feature/x', '2' * 40),
          isFalse,
          reason: 'a commit the run never pushed',
        );
        expect(
          runs.single.pushedAt('acme', 'widgets', 'feature/x', '111111'),
          isFalse,
          reason: 'too short a prefix to name one commit',
        );
        expect(
          gateway.openRuns(workspaceId: 'w2', conversationId: 'c1'),
          isEmpty,
          reason: 'another workspace never sees this run',
        );

        await gateway.close(lease);
        expect(
          gateway.openRuns(workspaceId: 'w1', conversationId: 'c1'),
          isEmpty,
        );
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

    test('a refused write mint tells git why: a Connect bot push needs a '
        'requester', () async {
      broker.refusal =
          'No GitHub token for acme/widgets: pushing needs a person who '
          'asked for it.';

      final r = await send('GET', advertPath);

      expect(r.status, HttpStatus.serviceUnavailable);
      expect(
        r.body.trim(),
        'Control Center: No GitHub token for acme/widgets: pushing needs a '
        'person who asked for it.',
      );
      expect(upstream.seen, isEmpty);
      expect(broker.revoked, ['h1']);
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
          oid: '1111111111111111111111111111111111111111',
          authorName: 'Ada',
          committerName: 'Ada',
          authorEmail: 'mallory@example.com',
          committerEmail: 'Ada@Example.com',
          signed: false,
          signedOff: false,
          coAuthors: [_ccTrailer],
          creditedCoAuthors: [_ccTrailer],
        ),
      ];
      final r = await send(
        'POST',
        pushPath,
        body: _push(['refs/heads/feature/x']),
      );
      expect(r.status, 200);
      expect(r.body, contains('ng refs/heads/feature/x'));
      expect(r.body, contains('<mallory@example.com>; this run authors as'));
      expect(upstream.seen, isEmpty);
    });

    test('a Signed-off-by trailer is refused on any run', () async {
      rule(ActionClass.gitPush, ActionDecision.allow);
      inspected = [
        const PushedGitObject(
          kind: 'commit',
          oid: '1111111111111111111111111111111111111111',
          authorName: 'Ada',
          committerName: 'Ada',
          authorEmail: 'ada@example.com',
          committerEmail: 'ada@example.com',
          signed: false,
          signedOff: true,
          coAuthors: [_ccTrailer],
          creditedCoAuthors: [_ccTrailer],
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

    test('the requester\'s own commits crediting Control Center are '
        'forwarded', () async {
      rule(ActionClass.gitPush, ActionDecision.allow);
      inspected = [
        const PushedGitObject(
          kind: 'commit',
          oid: '1111111111111111111111111111111111111111',
          authorName: 'Ada',
          committerName: 'Ada',
          authorEmail: 'ada@example.com',
          committerEmail: 'ada@example.com',
          signed: false,
          signedOff: false,
          coAuthors: ['co-authored-by: Control Center <HI@usectrl.dev>'],
          creditedCoAuthors: [
            'co-authored-by: Control Center <HI@usectrl.dev>',
          ],
        ),
      ];
      final body = _push(['refs/heads/feature/x']);
      final r = await send('POST', pushPath, body: body);
      expect(r.body, 'upstream-ok');
      expect(upstream.seen.single.body, body);
    });

    test('a signed commit or a borrowed co-author is refused', () async {
      rule(ActionClass.gitPush, ActionDecision.allow);
      for (final (object, reason) in const [
        (
          PushedGitObject(
            kind: 'commit',
            oid: '1111111111111111111111111111111111111111',
            authorName: 'Ada',
            committerName: 'Ada',
            authorEmail: 'Ada@Example.com',
            committerEmail: 'Ada@Example.com',
            signed: true,
            signedOff: false,
            coAuthors: [_ccTrailer],
            creditedCoAuthors: [_ccTrailer],
          ),
          'are not signed',
        ),
        (
          PushedGitObject(
            kind: 'commit',
            oid: '1111111111111111111111111111111111111111',
            authorName: 'Ada',
            committerName: 'Ada',
            authorEmail: 'Ada@Example.com',
            committerEmail: 'Ada@Example.com',
            signed: false,
            signedOff: false,
            coAuthors: [_ccTrailer, 'Co-authored-by: Eve <eve@example.com>'],
            creditedCoAuthors: [
              _ccTrailer,
              'Co-authored-by: Eve <eve@example.com>',
            ],
          ),
          'credits "Co-authored-by: Eve',
        ),
      ]) {
        inspected = [object];
        final r = await send(
          'POST',
          pushPath,
          body: _push(['refs/heads/feature/x']),
        );
        expect(r.body, contains('ng refs/heads/feature/x'));
        expect(r.body, contains(reason));
      }
      expect(upstream.seen, isEmpty);
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

    test('the repo check sees who asked for the run, on its own repo '
        'too', () async {
      rule(ActionClass.gitPush, ActionDecision.allow);
      refusedActors = {'bo'};
      final bos = (await gateway.open(
        AgentRunGrant(
          workspaceId: 'w1',
          conversationId: 'c2',
          agentId: 'a1',
          spaceId: 's1',
          actingUserId: 'bo',
          repos: const [_widgets],
          identity: _adaIdentity,
        ),
      ))!;
      final r = await send(
        'POST',
        pushPath,
        body: _push(['refs/heads/x']),
        secret: bos.secret,
      );
      expect(r.status, HttpStatus.forbidden);
      expect(checkedActors, ['bo']);
      expect(upstream.seen, isEmpty);
    });

    test(
      'a tip the pack does not carry must already be a tip on GitHub',
      () async {
        rule(ActionClass.gitPush, ActionDecision.allow);
        inspected = [];
        List<int> pointAt(String oid, String ref) => utf8.encode(
          [
            _pkt('$_zero $oid $ref\u0000report-status side-band-64k\n'),
            '0000',
          ].join(),
        );
        // Another fork's (or an unreferenced) commit: never inspected.
        final hidden = await send(
          'POST',
          pushPath,
          body: pointAt('4' * 40, 'refs/heads/sneak'),
        );
        expect(hidden.body, contains('ng refs/heads/sneak'));
        expect(hidden.body, contains('does not carry'));
        expect(upstream.seen.map((s) => s.method), ['GET']);
        expect(upstream.seen.single.query, 'service=git-receive-pack');

        // An existing branch's tip under a new name is already on GitHub.
        upstream.seen.clear();
        final copied = await send(
          'POST',
          pushPath,
          body: pointAt('2' * 40, 'refs/heads/copy'),
        );
        expect(copied.body, 'upstream-ok');
        expect(upstream.seen.map((s) => s.method), ['GET', 'POST']);

        // A deletion carries nothing and is not checked.
        upstream.seen.clear();
        final deleted = await send(
          'POST',
          pushPath,
          body: utf8.encode(
            [
              _pkt('${'2' * 40} $_zero refs/heads/old\u0000report-status\n'),
              '0000',
            ].join(),
          ),
        );
        expect(deleted.body, 'upstream-ok');
        expect(upstream.seen.map((s) => s.method), ['POST']);
      },
    );

    test('what GitHub only stores for others is not a tip of this '
        'repository', () async {
      rule(ActionClass.gitPush, ActionDecision.allow);
      for (final oid in ['8' * 40, '9' * 40]) {
        final r = await send(
          'POST',
          pushPath,
          body: utf8.encode(
            [
              _pkt(
                '$_zero $oid refs/heads/sneak\u0000report-status '
                'side-band-64k\n',
              ),
              '0000',
            ].join(),
          ),
        );
        expect(r.body, contains('ng refs/heads/sneak'), reason: oid);
        expect(r.body, contains('does not carry'), reason: oid);
      }
      expect(upstream.seen.map((s) => s.method), ['GET', 'GET']);
    });

    group('what a pushed commit stands on', () {
      /// The run's own commit, standing on [below].
      PushedGitObject standingOn(
        List<String> below, {
        String kind = 'commit',
      }) => PushedGitObject(
        kind: kind,
        oid: _one,
        authorName: kind == 'commit' ? 'Ada' : null,
        authorEmail: kind == 'commit' ? 'Ada@Example.com' : null,
        committerName: 'Ada',
        committerEmail: 'Ada@Example.com',
        signed: false,
        signedOff: false,
        coAuthors: kind == 'commit' ? const [_ccTrailer] : const [],
        creditedCoAuthors: kind == 'commit' ? const [_ccTrailer] : const [],
        buildsOn: below,
      );
      final unknown = '5' * 40;

      setUp(() => rule(ActionClass.gitPush, ActionDecision.allow));

      test('a branch or tag tip of the repository needs no lookup', () async {
        inspected = [
          standingOn(['2' * 40, '3' * 40]),
        ];
        final r = await send('POST', pushPath, body: _push(['refs/heads/x']));
        expect(r.body, 'upstream-ok');
        expect(ancestryAsked, isEmpty);
      });

      test('a commit on the default branch is published', () async {
        publishedOn = (base, oid) => base == 'HEAD' && oid == unknown;
        inspected = [
          standingOn([unknown]),
        ];
        final r = await send('POST', pushPath, body: _push(['refs/heads/x']));
        expect(r.body, 'upstream-ok');
        expect(ancestryAsked, [
          (
            repo: 'acme/widgets',
            base: 'HEAD',
            oid: unknown,
            token: 'write-tok',
          ),
        ]);
      });

      test('an amended branch stands on its own published history', () async {
        // Not on the default branch, but below what refs/heads/dev points
        // at on GitHub today.
        publishedOn = (base, oid) => base == '3' * 40;
        inspected = [
          standingOn([unknown]),
        ];
        final r = await send('POST', pushPath, body: _push(['refs/heads/dev']));
        expect(r.body, 'upstream-ok');
        expect(ancestryAsked.map((a) => a.base), ['HEAD', '3' * 40]);
      });

      test('a commit the repository has not published is refused, as a '
          'parent or as a tag\'s target', () async {
        for (final kind in ['commit', 'tag']) {
          upstream.seen.clear();
          inspected = [
            standingOn([unknown], kind: kind),
          ];
          final r = await send('POST', pushPath, body: _push(['refs/heads/x']));
          expect(r.body, contains('ng refs/heads/x'), reason: kind);
          expect(
            r.body,
            allOf(
              contains('$kind 111111111111 stands on 555555555555'),
              contains('cannot be inspected'),
            ),
            reason: kind,
          );
          // Only the ref advertisement was read; nothing was forwarded.
          expect(upstream.seen.map((s) => s.method), ['GET'], reason: kind);
        }
      });

      test('a carried parent is inspected, not looked up', () async {
        inspected = [
          standingOn([unknown]),
          PushedGitObject(
            kind: 'commit',
            oid: unknown,
            authorName: 'Ada',
            authorEmail: 'Ada@Example.com',
            committerName: 'Ada',
            committerEmail: 'Ada@Example.com',
            signed: false,
            signedOff: false,
            coAuthors: const [_ccTrailer],
            creditedCoAuthors: const [_ccTrailer],
            buildsOn: ['2' * 40],
          ),
        ];
        final r = await send('POST', pushPath, body: _push(['refs/heads/x']));
        expect(r.body, 'upstream-ok');
        expect(ancestryAsked, isEmpty);
      });

      test('a lookup GitHub did not answer refuses the push', () async {
        publishedOn = (_, _) => null;
        inspected = [
          standingOn([unknown]),
        ];
        final r = await send('POST', pushPath, body: _push(['refs/heads/x']));
        expect(r.body, contains('ng refs/heads/x'));
        expect(r.body, contains('could not ask GitHub'));
        expect(upstream.seen.map((s) => s.method), ['GET']);
      });

      test('a push standing on more commits than can be checked is '
          'refused', () async {
        publishedOn = (_, _) => true;
        inspected = [
          standingOn([
            for (var i = 0; i < 17; i++)
              i.toRadixString(16).padLeft(2, 'a') * 20,
          ]),
        ];
        final r = await send('POST', pushPath, body: _push(['refs/heads/x']));
        expect(r.body, contains('too many commits'));
        expect(ancestryAsked, isEmpty);
      });

      test('a gateway with no way to ask publishes nothing it did not '
          'see', () async {
        gateway = AgentRunGateway(
          guard: ActionGuardService(
            repository: rules,
            confirmationPort: confirm,
            onAudit: audits.add,
          ),
          broker: broker,
          loopbackBase: () async => Uri.parse('http://127.0.0.1:${host.port}'),
          repoAllowed: (_, _, _, _) async => true,
          forgeBases: {
            ForgeHost.github: Uri.parse(
              'http://127.0.0.1:${upstream.server.port}',
            ),
          },
          inspectPack: (_) async => inspected,
        );
        final run = (await gateway.open(
          AgentRunGrant(
            workspaceId: 'w1',
            conversationId: 'c1',
            repos: const [_widgets],
            identity: _adaIdentity,
          ),
        ))!;
        inspected = [
          standingOn([unknown]),
        ];
        final refused = await send(
          'POST',
          pushPath,
          body: _push(['refs/heads/x']),
          secret: run.secret,
        );
        expect(refused.body, contains('stands on 555555555555'));
        // A tip is still a tip.
        inspected = [
          standingOn(['2' * 40]),
        ];
        final ok = await send(
          'POST',
          pushPath,
          body: _push(['refs/heads/x']),
          secret: run.secret,
        );
        expect(ok.body, 'upstream-ok');
      });
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

  group('no signing', () {
    test('the lease hands a run the gateway its shims post to', () {
      final env = lease.environment(const {});
      expect(env[AgentRunLease.gatewayEnvKey], '${lease.base}');
      expect(env[AgentRunLease.tokenEnvKey], lease.secret);
    });

    Map<String, String> configOf(Map<String, String> env) => {
      for (var i = 0; i < int.parse(env['GIT_CONFIG_COUNT']!); i++)
        env['GIT_CONFIG_KEY_$i']!: env['GIT_CONFIG_VALUE_$i']!,
    };

    test('a run without a signing key commits unsigned with every signer '
        'stripped, whoever asked for it', () async {
      final runs = [
        lease,
        for (final identity in [
          AgentCommitIdentity.person((name: 'Bo', email: 'bo@example.com')),
          AgentCommitIdentity.automation(),
          null,
        ])
          (await gateway.open(
            AgentRunGrant(
              workspaceId: 'w1',
              conversationId: 'c-${identity.hashCode}',
              identity: identity,
            ),
          ))!,
      ];
      for (final run in runs) {
        final config = configOf(run.environment(const {}));
        expect(config['commit.gpgsign'], 'false');
        expect(config['tag.gpgsign'], 'false');
        expect(config['push.gpgsign'], 'false');
        expect(config['gpg.program'], 'false');
        expect(config['gpg.ssh.program'], 'false');
        expect(config['gpg.x509.program'], 'false');
      }
    });

    test('a run without a signing key gets nothing signed', () async {
      final r = await send(
        'POST',
        AgentRunSigning.path,
        body: utf8.encode('tree ${'a' * 40}\n'),
      );
      expect(r.status, HttpStatus.forbidden);
      expect(r.body, contains('does not sign its commits'));
      expect(audits, isEmpty);
    });
  });

  group('commit signing', () {
    late SshSigningKey key;
    late _Signing signing;
    late AgentRunLease signer;
    late AgentCommitIdentity identity;

    /// The moment the hand-built commits below are made at.
    const madeAt = 1700000000;

    /// The gateway's clock: [madeAt] unless a test moves it.
    late DateTime Function() clock;

    /// A commit object as git hands it to its signer.
    List<int> commitObject({
      String author = 'Ada <Ada@Example.com>',
      String committer = 'Ada <Ada@Example.com>',
      String message = 'change\n\n$_ccTrailer\n',
      String extraHeaders = '',
      int authorAt = madeAt,
      int committerAt = madeAt,
    }) => utf8.encode(
      'tree ${'a' * 40}\n'
      'author $author $authorAt +0000\n'
      'committer $committer $committerAt +0000\n'
      '$extraHeaders'
      '\n$message',
    );

    Future<({int status, String body})> sign(List<int> commit) =>
        send('POST', AgentRunSigning.path, body: commit, secret: signer.secret);

    setUp(() async {
      key = await SshSigningKey.generate();
      signing = _Signing({'ada': key});
      clock = () => DateTime.fromMillisecondsSinceEpoch(madeAt * 1000);
      identity = AgentCommitIdentity.person(
        (name: 'Ada', email: 'Ada@Example.com'),
        creditAgent: true,
        signingKey: key.publicKey,
      );
      gateway = AgentRunGateway(
        guard: ActionGuardService(
          repository: rules,
          confirmationPort: confirm,
          onAudit: audits.add,
        ),
        broker: broker,
        loopbackBase: () async => Uri.parse('http://127.0.0.1:${host.port}'),
        signing: signing,
        now: () => clock(),
      );
      signer = (await gateway.open(
        AgentRunGrant(
          workspaceId: 'w1',
          conversationId: 'c-sign',
          agentId: 'a1',
          spaceId: 's1',
          actingUserId: 'ada',
          runId: 'run-1',
          identity: identity,
          signProgram: '/runs/run-1/bin/cc-git-sign',
        ),
      ))!;
    });

    Map<String, String> configOf(AgentRunLease lease) {
      final env = lease.environment(const {});
      return {
        for (var i = 0; i < int.parse(env['GIT_CONFIG_COUNT']!); i++)
          env['GIT_CONFIG_KEY_$i']!: env['GIT_CONFIG_VALUE_$i']!,
      };
    }

    test('the run\'s git signs every commit with the requester\'s key '
        'through the shim, and nothing else', () {
      final config = configOf(signer);
      expect(config['gpg.format'], 'ssh');
      expect(config['gpg.ssh.program'], '/runs/run-1/bin/cc-git-sign');
      expect(config['user.signingkey'], 'key::${key.publicKey}');
      expect(config['commit.gpgsign'], 'true');
      expect(config['tag.gpgsign'], 'false');
      expect(config['push.gpgsign'], 'false');
      expect(config['gpg.program'], 'false');
      expect(config['gpg.x509.program'], 'false');
      expect(gateway.signs, isTrue);
    });

    test('a run opens only when its identity and its git agree on '
        'signing', () async {
      Future<AgentRunLease?> open(
        AgentRunGateway on,
        AgentCommitIdentity who, {
        String? signProgram,
      }) => on.open(
        AgentRunGrant(
          workspaceId: 'w1',
          conversationId: 'c-mismatch',
          actingUserId: 'ada',
          identity: who,
          signProgram: signProgram,
        ),
      );
      // A key the run's git has no signer for: its pushes would be held to
      // signatures it cannot make.
      await expectLater(open(gateway, identity), throwsStateError);
      // A signer for a run whose commits are checked as unsigned.
      await expectLater(
        open(gateway, identity.unsigned, signProgram: '/bin/cc-git-sign'),
        throwsStateError,
      );
      // A gateway that signs nothing.
      final unsigning = AgentRunGateway(
        guard: ActionGuardService(
          repository: rules,
          confirmationPort: confirm,
          onAudit: audits.add,
        ),
        broker: broker,
        loopbackBase: () async => Uri.parse('http://127.0.0.1:${host.port}'),
      );
      await expectLater(
        open(unsigning, identity, signProgram: '/bin/cc-git-sign'),
        throwsStateError,
      );
      for (final on in [gateway, unsigning]) {
        expect(
          on.openRuns(workspaceId: 'w1', conversationId: 'c-mismatch'),
          isEmpty,
        );
      }
    });

    test('the run\'s own commit is signed with the requester\'s key and '
        'the signature is recorded', () async {
      final payload = commitObject();
      final r = await send(
        'POST',
        AgentRunSigning.path,
        body: payload,
        secret: signer.secret,
      );
      expect(r.status, HttpStatus.ok, reason: r.body);
      expect(await SshSignature.signerOf(r.body, payload), key.publicKey);
      expect(signing.signed, hasLength(1));
      final audit = audits.single;
      expect(audit.actionSummary, 'sign git commit');
      expect(audit.decision, ActionDecision.allow);
      expect(audit.onBehalfOfUserId, 'ada');
      expect(audit.runId, 'run-1');
    });

    test('a commit that is not the run\'s own is not signed', () async {
      for (final (name, payload, reason) in [
        (
          'another author',
          commitObject(author: 'Mallory <mallory@example.com>'),
          'this run authors as Ada',
        ),
        (
          'another committer',
          commitObject(committer: 'Control Center <hi@usectrl.dev>'),
          'this run commits as Ada',
        ),
        (
          'no co-author line',
          commitObject(message: 'change\n'),
          'does not carry',
        ),
        (
          'a borrowed co-author',
          commitObject(
            message:
                'change\n\n$_ccTrailer\n'
                'Co-authored-by: Eve <eve@example.com>\n',
          ),
          'credits "Co-authored-by: Eve',
        ),
        (
          'signed off',
          commitObject(
            message: 'change\n\n$_ccTrailer\nSigned-off-by: Ada <a@x>\n',
          ),
          'Signed-off-by',
        ),
        (
          'another encoding',
          commitObject(extraHeaders: 'encoding ISO-8859-1\n'),
          'declares the encoding',
        ),
      ]) {
        final r = await send(
          'POST',
          AgentRunSigning.path,
          body: payload,
          secret: signer.secret,
        );
        expect(r.status, HttpStatus.forbidden, reason: name);
        expect(r.body, contains(reason), reason: name);
      }
      expect(signing.signed, isEmpty);
      expect(audits, isEmpty);
    });

    test('only a well-formed, unsigned commit is signed', () async {
      for (final (name, payload, status) in [
        (
          'a tag',
          utf8.encode(
            'object ${'a' * 40}\ntype commit\ntag v1\n'
            'tagger Ada <Ada@Example.com> 1700000000 +0000\n\nrelease\n',
          ),
          HttpStatus.badRequest,
        ),
        ('not an object', utf8.encode('hello'), HttpStatus.badRequest),
        (
          'no committer',
          utf8.encode(
            'tree ${'a' * 40}\nauthor Ada <Ada@Example.com> 1 +0000\n\nm\n',
          ),
          HttpStatus.badRequest,
        ),
        (
          'already signed',
          commitObject(
            extraHeaders:
                'gpgsig -----BEGIN SSH SIGNATURE-----\n AAAA\n'
                ' -----END SSH SIGNATURE-----\n',
          ),
          HttpStatus.badRequest,
        ),
        (
          'too large',
          List<int>.filled(1024 * 1024 + 1, 0x61),
          HttpStatus.requestEntityTooLarge,
        ),
      ]) {
        final r = await send(
          'POST',
          AgentRunSigning.path,
          body: payload,
          secret: signer.secret,
        );
        expect(r.status, status, reason: name);
      }
      expect(signing.signed, isEmpty);
    });

    test(
      'a read-only mode signs nothing, and the refusal is recorded',
      () async {
        final readOnly = (await gateway.open(
          AgentRunGrant(
            workspaceId: 'w1',
            conversationId: 'c-plan',
            actingUserId: 'ada',
            mode: Mode.plan,
            identity: identity,
            signProgram: '/runs/run-2/bin/cc-git-sign',
          ),
        ))!;
        final r = await send(
          'POST',
          AgentRunSigning.path,
          body: commitObject(),
          secret: readOnly.secret,
        );
        expect(r.status, HttpStatus.forbidden);
        expect(r.body, contains('Control Center policy'));
        expect(signing.signed, isEmpty);
        expect(audits.single.decision, ActionDecision.deny);
      },
    );

    test('a key that changed or went away since the run started signs '
        'nothing', () async {
      signing.keys['ada'] = await SshSigningKey.generate();
      var r = await send(
        'POST',
        AgentRunSigning.path,
        body: commitObject(),
        secret: signer.secret,
      );
      expect(r.status, HttpStatus.conflict);
      expect(r.body, contains('changed since it started'));

      signing.keys.remove('ada');
      r = await send(
        'POST',
        AgentRunSigning.path,
        body: commitObject(),
        secret: signer.secret,
      );
      expect(r.status, HttpStatus.conflict);
      expect(signing.signed, isEmpty);
    });

    test('one run cannot have another run\'s person sign', () async {
      // Bo's run, no key of his own: Ada's key is not his to use.
      final bos = (await gateway.open(
        AgentRunGrant(
          workspaceId: 'w1',
          conversationId: 'c-bo',
          actingUserId: 'bo',
          identity: AgentCommitIdentity.person((
            name: 'Bo',
            email: 'bo@example.com',
          )),
        ),
      ))!;
      final r = await send(
        'POST',
        AgentRunSigning.path,
        body: commitObject(),
        secret: bos.secret,
      );
      expect(r.status, HttpStatus.forbidden);
      expect(signing.signed, isEmpty);
    });

    test('a commit is signed only as it is made', () async {
      final skew = AgentRunSigning.clockSkew.inSeconds;
      for (final (name, payload) in [
        ('an old committer date', commitObject(committerAt: madeAt - skew - 1)),
        (
          'a committer date ahead',
          commitObject(committerAt: madeAt + skew + 1),
        ),
        ('an author date ahead', commitObject(authorAt: madeAt + skew + 1)),
      ]) {
        final r = await sign(payload);
        expect(r.status, HttpStatus.forbidden, reason: name);
        expect(r.body, contains('signed only as it is made'), reason: name);
      }
      expect(signing.signed, isEmpty);
      expect(audits, isEmpty);

      // An amended or rebased commit keeps its older author date, and a
      // clock a little off is still now.
      final r = await sign(
        commitObject(authorAt: madeAt - 30 * 86400, committerAt: madeAt + skew),
      );
      expect(r.status, HttpStatus.ok, reason: r.body);
    });

    test('a run is signed for a bounded number of commits', () async {
      // Counted before the key is read: no signature is needed to get there.
      signing.keys.remove('ada');
      for (var i = 0; i < AgentRunSigning.maxSignaturesPerRun; i++) {
        expect((await sign(commitObject())).status, HttpStatus.conflict);
      }
      signing.keys['ada'] = key;
      final r = await sign(commitObject());
      expect(r.status, HttpStatus.tooManyRequests);
      expect(r.body, contains('Start a new run'));
      expect(signing.signed, isEmpty);

      // The count is the run's own: another run of the same person signs.
      final next = (await gateway.open(
        AgentRunGrant(
          workspaceId: 'w1',
          conversationId: 'c-next',
          actingUserId: 'ada',
          identity: identity,
          signProgram: '/runs/run-3/bin/cc-git-sign',
        ),
      ))!;
      final other = await send(
        'POST',
        AgentRunSigning.path,
        body: commitObject(),
        secret: next.secret,
      );
      expect(other.status, HttpStatus.ok, reason: other.body);
    });

    test('an ask rule asks before a commit is signed, and a no signs '
        'nothing', () async {
      rule(ActionClass.gitCommit, ActionDecision.prompt);
      var r = await sign(commitObject());
      expect(r.status, HttpStatus.ok, reason: r.body);
      expect(confirm.asked.single.conversationId, 'c-sign');

      confirm.answer = false;
      r = await sign(commitObject());
      expect(r.status, HttpStatus.forbidden);
      expect(r.body, contains('Control Center policy'));
      expect(confirm.asked, hasLength(2));
      expect(signing.signed, hasLength(1));
    });

    test('the yes to a committing shell command answers the ask for its '
        'commits, for a while', () async {
      rule(ActionClass.gitCommit, ActionDecision.prompt);
      final shell = await send(
        'POST',
        '/agent/hooks/pre-tool-use',
        body: utf8.encode(
          jsonEncode({
            'tool_name': 'Bash',
            'tool_input': {
              'command': 'git commit -m change',
              'description': 'Commit the change',
            },
          }),
        ),
        secret: signer.secret,
      );
      expect(shell.body.trim(), 'allow');
      expect(confirm.asked, hasLength(1));

      var r = await sign(commitObject());
      expect(r.status, HttpStatus.ok, reason: r.body);
      expect(confirm.asked, hasLength(1));
      expect(
        audits.last.actionSummary,
        'sign git commit (approved at the shell prompt)',
      );
      expect(audits.last.decision, ActionDecision.allow);
      expect(audits.last.onBehalfOfUserId, 'ada');

      // Past the window the commit is asked about again.
      final later =
          madeAt + AgentRunGateway.shellPushApprovalWindow.inSeconds + 1;
      clock = () => DateTime.fromMillisecondsSinceEpoch(later * 1000);
      r = await sign(commitObject(authorAt: later, committerAt: later));
      expect(r.status, HttpStatus.ok, reason: r.body);
      expect(confirm.asked, hasLength(2));
    });

    test('a shell approval never answers a deny', () async {
      rule(ActionClass.gitCommit, ActionDecision.prompt);
      final shell = await send(
        'POST',
        '/agent/hooks/pre-tool-use',
        body: utf8.encode(
          jsonEncode({
            'tool_name': 'Bash',
            'tool_input': {
              'command': 'git commit -m change',
              'description': 'Commit the change',
            },
          }),
        ),
        secret: signer.secret,
      );
      expect(shell.body.trim(), 'allow');
      rules.list
        ..clear()
        ..add(
          ActionPolicyRule(
            id: 'commit-deny',
            workspaceId: 'w1',
            scopeType: ActionScopeType.workspace,
            scopeId: '',
            actionClass: ActionClass.gitCommit,
            decision: ActionDecision.deny,
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
        );
      final r = await sign(commitObject());
      expect(r.status, HttpStatus.forbidden);
      expect(confirm.asked, hasLength(1));
      expect(signing.signed, isEmpty);
    });

    test('git commits through the shim and the commit verifies under the '
        'requester\'s key', () async {
      // Git stamps the commit itself.
      clock = DateTime.now;
      final scratch = await Directory.systemTemp.createTemp('cc-sign-e2e-');
      addTearDown(() => scratch.delete(recursive: true));
      final shim = File('${scratch.path}/bin/${AgentRunSigning.shimName}')
        ..createSync(recursive: true)
        ..writeAsStringSync(AgentRunSigning.shim(gateway.client));
      expect(Process.runSync('/bin/chmod', ['755', shim.path]).exitCode, 0);
      final run = (await gateway.open(
        AgentRunGrant(
          workspaceId: 'w1',
          conversationId: 'c-e2e',
          actingUserId: 'ada',
          identity: identity,
          signProgram: shim.path,
        ),
      ))!;
      final repo = Directory('${scratch.path}/repo')..createSync();
      final env = {
        'PATH': Platform.environment['PATH'] ?? '/usr/bin:/bin',
        'HOME': scratch.path,
        'GIT_CONFIG_GLOBAL': (File(
          '${scratch.path}/gitconfig',
        )..writeAsStringSync('')).path,
        'GIT_CONFIG_NOSYSTEM': '1',
        ...identity.environment,
        ...run.environment(const {}),
      };
      Future<ProcessResult> git(List<String> args, {Encoding? out = utf8}) =>
          Process.run(
            'git',
            args,
            workingDirectory: repo.path,
            environment: env,
            includeParentEnvironment: false,
            stdoutEncoding: out,
          );
      expect((await git(['init', '--quiet', '-b', 'main'])).exitCode, 0);
      File('${repo.path}/a.txt').writeAsStringSync('a');
      expect((await git(['add', 'a.txt'])).exitCode, 0);

      // Not the run's own commit: git reports the gateway's reason.
      final refused = await git(['commit', '--quiet', '-m', 'no credit']);
      expect(refused.exitCode, isNot(0));
      expect('${refused.stderr}', contains('does not carry'));

      final commit = await git([
        'commit',
        '--quiet',
        '-m',
        'change',
        '-m',
        _ccTrailer,
      ]);
      expect(commit.exitCode, 0, reason: '${commit.stderr}');
      final raw =
          (await git(['cat-file', 'commit', 'HEAD'], out: null)).stdout
              as List<int>;
      final object = await PushedCommitInspector.read('commit', 'head', raw);
      expect(object.signedBy, key.publicKey);
      expect(PushedCommitInspector.violation([object], identity), isNull);
    }, skip: Platform.isWindows ? 'the signing shim is a shell script' : false);
  });

  group('fetch proxy', () {
    const gitlabApi = (
      forge: ForgeHost.gitlab,
      owner: 'acme/platform',
      name: 'api-server',
    );
    const bitbucketUi = (
      forge: ForgeHost.bitbucket,
      owner: 'acme',
      name: 'shop-ui',
    );
    const gitlabToken = 'gitlab-test-token';
    const bitbucketToken = 'ada@example.com:bitbucket-test-token';
    final reviewToken = _Broker.token(ForgeTokenScope.review);
    late Map<ForgeHost, _Forge> forges;
    final looked = <({String ws, String repo, String? actor})>[];
    var fetchTokens = <ForgeHost, String?>{};
    String? fetchRefusal;
    final logged = <String>[];
    CcInfraLogSink? previousSink;

    AgentRunGateway fetchGateway({bool withLookup = true}) => AgentRunGateway(
      guard: ActionGuardService(
        repository: rules,
        confirmationPort: confirm,
        onAudit: audits.add,
      ),
      broker: broker,
      loopbackBase: () async => Uri.parse('http://127.0.0.1:${host.port}'),
      forgeBases: {
        for (final MapEntry(:key, :value) in forges.entries)
          key: Uri.parse('http://127.0.0.1:${value.server.port}'),
      },
      fetchCredential: withLookup
          ? (ws, repo, actor) async {
              looked.add((
                ws: ws,
                repo: '${repo.forge.gitHost}/${repo.owner}/${repo.name}',
                actor: actor,
              ));
              return (token: fetchTokens[repo.forge], refusal: fetchRefusal);
            }
          : null,
    );

    Future<AgentRunLease> openRun() async => (await gateway.open(
      const AgentRunGrant(
        workspaceId: 'w1',
        conversationId: 'c-fetch',
        agentId: 'a1',
        spaceId: 's1',
        actingUserId: 'u-ada',
        repos: [_widgets, gitlabApi, bitbucketUi],
      ),
    ))!;

    setUp(() async {
      forges = {
        for (final forge in ForgeHost.supported)
          forge: _Forge(await HttpServer.bind(InternetAddress.loopbackIPv4, 0)),
      };
      looked.clear();
      fetchTokens = {
        ForgeHost.gitlab: gitlabToken,
        ForgeHost.bitbucket: bitbucketToken,
      };
      fetchRefusal = null;
      logged.clear();
      previousSink = CcInfraLog.sink;
      CcInfraLog.sink = (level, message, [error, stackTrace]) =>
          logged.add('$message ${error ?? ''}');
      // The `host` server dispatches to whatever `gateway` is now.
      gateway = fetchGateway();
      lease = await openRun();
    });

    tearDown(() async {
      CcInfraLog.sink = previousSink;
      for (final forge in forges.values) {
        await forge.server.close(force: true);
      }
    });

    Future<({int status, HttpHeaders headers, List<int> body})> fetch(
      String method,
      String path, {
      List<int>? body,
      Map<String, String> headers = const {},
    }) async {
      final request = await client.openUrl(
        method,
        Uri.parse('http://127.0.0.1:${host.port}$path'),
      );
      request.headers.set(AgentRunLease.tokenHeader, lease.secret);
      headers.forEach(request.headers.set);
      if (body != null) {
        request.add(body);
      }
      final response = await request.close();
      final bytes = await response.fold<List<int>>([], (a, b) => a..addAll(b));
      return (
        status: response.statusCode,
        headers: response.headers,
        body: bytes,
      );
    }

    String advert(String repo) =>
        '/agent/git/$repo/info/refs?service=git-upload-pack';
    String uploadPack(String repo) => '/agent/git/$repo/git-upload-pack';
    bool nothingUpstream() => forges.values.every((f) => f.seen.isEmpty);

    test('each forge fetches the run\'s repository on the run\'s credential, '
        'always at its .git path', () async {
      final cases = [
        (
          forge: ForgeHost.github,
          asked: 'github.com/acme/widgets.git',
          path: '/acme/widgets.git',
          auth: forgeGitBasicAuthorization(ForgeHost.github, reviewToken),
        ),
        (
          forge: ForgeHost.gitlab,
          asked: 'gitlab.com/acme/platform/api-server.git',
          path: '/acme/platform/api-server.git',
          auth: forgeGitBasicAuthorization(ForgeHost.gitlab, gitlabToken),
        ),
        (
          // git may ask without `.git`; upstream always gets it.
          forge: ForgeHost.bitbucket,
          asked: 'bitbucket.org/acme/shop-ui',
          path: '/acme/shop-ui.git',
          auth: forgeGitBasicAuthorization(ForgeHost.bitbucket, bitbucketToken),
        ),
      ];
      for (final c in cases) {
        final listed = await fetch('GET', advert(c.asked));
        expect(listed.status, 200, reason: c.asked);
        expect(utf8.decode(listed.body), _Forge.advertisement);
        expect(
          listed.headers.contentType?.mimeType,
          'application/x-git-upload-pack-advertisement',
        );

        final request = utf8.encode('0032want ${'2' * 40}\n00000009done\n');
        final packed = await fetch(
          'POST',
          uploadPack(c.asked),
          body: request,
          headers: const {
            'Content-Type': 'application/x-git-upload-pack-request',
            'Git-Protocol': 'version=2',
            // Anything git did not need stays here.
            'Cookie': 'session=abc',
          },
        );
        expect(packed.status, 200, reason: c.asked);
        expect(utf8.decode(packed.body), 'pack-bytes');

        final seen = forges[c.forge]!.seen;
        expect(seen, hasLength(2), reason: c.asked);
        expect(seen[0].method, 'GET');
        expect(seen[0].path, '${c.path}/info/refs');
        expect(seen[0].query, 'service=git-upload-pack');
        expect(seen[0].auth, c.auth);
        expect(seen[1].method, 'POST');
        expect(seen[1].path, '${c.path}/git-upload-pack');
        expect(seen[1].query, isEmpty);
        expect(seen[1].auth, c.auth);
        expect(seen[1].body, request);
        expect(seen[1].gitProtocol, 'version=2');
        expect(seen[1].cookie, isNull);
      }
      expect(broker.scopes, [
        ForgeTokenScope.review,
      ], reason: 'minted once, then the lease\'s own');
      expect(broker.repos, ['acme/widgets']);
      expect(looked, hasLength(4));
      expect(looked.map((l) => l.repo).toSet(), {
        'gitlab.com/acme/platform/api-server',
        'bitbucket.org/acme/shop-ui',
      });
      expect(looked.every((l) => l.ws == 'w1' && l.actor == 'u-ada'), isTrue);
      expect(confirm.asked, isEmpty, reason: 'a fetch asks no one');
    });

    test('a real git lists a nested GitLab repository through the gateway, '
        'in every URL spelling', () async {
      final home = Directory.systemTemp.createTempSync('cc_fetch_git');
      addTearDown(() => home.deleteSync(recursive: true));
      File('${home.path}/gitconfig').writeAsStringSync('');
      final base = <String, String>{
        'GIT_CONFIG_GLOBAL': '${home.path}/gitconfig',
        'GIT_CONFIG_NOSYSTEM': '1',
        'GIT_TERMINAL_PROMPT': '0',
      };
      final env = {...base, ...lease.environment(base)};
      for (final url in const [
        'https://gitlab.com/acme/platform/api-server.git',
        'git@gitlab.com:acme/platform/api-server.git',
        'ssh://git@gitlab.com/acme/platform/api-server',
      ]) {
        final listed = await Process.run(
          'git',
          ['ls-remote', url],
          workingDirectory: home.path,
          environment: env,
        );
        expect(listed.exitCode, 0, reason: '$url: ${listed.stderr}');
        expect(listed.stdout, contains('${'2' * 40}\trefs/heads/main'));
      }
      final seen = forges[ForgeHost.gitlab]!.seen;
      expect(seen, hasLength(3));
      for (final s in seen) {
        expect(s.path, '/acme/platform/api-server.git/info/refs');
        expect(
          s.auth,
          forgeGitBasicAuthorization(ForgeHost.gitlab, gitlabToken),
        );
      }
    });

    test('a repository that is not the run\'s is forwarded with no '
        'credential', () async {
      for (final (forge, asked, path) in const [
        (
          ForgeHost.github,
          'github.com/acme/widgets-extra.git',
          '/acme/widgets-extra.git',
        ),
        (
          ForgeHost.gitlab,
          'gitlab.com/acme/platform/api-server-fork.git',
          '/acme/platform/api-server-fork.git',
        ),
      ]) {
        expect((await fetch('GET', advert(asked))).status, 200);
        expect(
          (await fetch('POST', uploadPack(asked), body: [0x30])).status,
          200,
        );
        final seen = forges[forge]!.seen;
        expect(seen.map((s) => s.path), [
          '$path/info/refs',
          '$path/git-upload-pack',
        ]);
        expect(seen.map((s) => s.auth), [null, null]);
      }
      expect(broker.scopes, isEmpty, reason: 'no token is minted for it');
      expect(looked, isEmpty, reason: 'no token is looked up for it');
    });

    test('on a host a sandbox cannot reach by itself, only the run\'s own '
        'repositories are proxied', () async {
      // bitbucket.org is not in the sandbox's network baseline: forwarding
      // another repository there would open a destination to the run.
      expect(kBaselineAllowedDomains, isNot(contains('bitbucket.org')));
      expect(
        kBaselineAllowedDomains,
        containsAll(['github.com', 'gitlab.com']),
      );
      for (final asked in const [
        'bitbucket.org/other/shop-ui',
        'bitbucket.org/acme/shop-ui-extra.git',
      ]) {
        final listed = await fetch('GET', advert(asked));
        final packed = await fetch('POST', uploadPack(asked), body: [0x30]);
        for (final r in [listed, packed]) {
          expect(r.status, HttpStatus.forbidden);
          expect(
            utf8.decode(r.body),
            contains('only this run\'s own repositories on Bitbucket'),
          );
        }
      }
      expect(nothingUpstream(), isTrue);
      expect(looked, isEmpty);
    });

    test('a network egress deny refuses the fetch, and asks no one', () async {
      rule(ActionClass.networkEgress, ActionDecision.deny);

      final listed = await fetch('GET', advert('github.com/acme/widgets.git'));
      final packed = await fetch(
        'POST',
        uploadPack('gitlab.com/acme/platform/api-server.git'),
        body: utf8.encode('0000'),
      );

      for (final r in [listed, packed]) {
        expect(r.status, HttpStatus.forbidden);
        expect(utf8.decode(r.body), startsWith('Control Center policy: '));
      }
      expect(nothingUpstream(), isTrue);
      expect(broker.scopes, isEmpty);
      expect(looked, isEmpty);
      expect(confirm.asked, isEmpty);
      expect(
        audits.where((a) => a.decision == ActionDecision.deny),
        isNotEmpty,
      );
    });

    test('a deny for one forge\'s host leaves the others', () async {
      rule(
        ActionClass.networkEgress,
        ActionDecision.deny,
        constraint: const ActionConstraint(hosts: ['gitlab.com']),
      );

      final gitlab = await fetch(
        'GET',
        advert('gitlab.com/acme/platform/api-server.git'),
      );
      final github = await fetch('GET', advert('github.com/acme/widgets.git'));

      expect(gitlab.status, HttpStatus.forbidden);
      expect(github.status, 200);
      expect(forges[ForgeHost.gitlab]!.seen, isEmpty);
      expect(forges[ForgeHost.github]!.seen, hasLength(1));
    });

    test('"ask first" on network egress never holds a fetch', () async {
      rule(ActionClass.networkEgress, ActionDecision.prompt);

      final r = await fetch('GET', advert('bitbucket.org/acme/shop-ui.git'));

      expect(r.status, 200);
      expect(confirm.asked, isEmpty);
    });

    test(
      'a push to GitLab or Bitbucket is refused toward stack_publish',
      () async {
        for (final (repo, name) in const [
          ('gitlab.com/acme/platform/api-server.git', 'GitLab'),
          ('bitbucket.org/acme/shop-ui.git', 'Bitbucket'),
        ]) {
          for (final r in [
            await fetch(
              'GET',
              '/agent/git/$repo/info/refs?service=git-receive-pack',
            ),
            await fetch(
              'POST',
              '/agent/git/$repo/git-receive-pack',
              body: _push(['refs/heads/main']),
            ),
          ]) {
            expect(r.status, HttpStatus.forbidden);
            expect(
              utf8.decode(r.body),
              'Control Center does not proxy pushes to $name: agents publish '
              'there with the stack_publish tool.\n',
            );
          }
        }
        expect(nothingUpstream(), isTrue);
        expect(looked, isEmpty);
      },
    );

    test('Git LFS is refused in one line', () async {
      final r = await fetch(
        'POST',
        '/agent/git/github.com/acme/widgets.git/info/lfs/objects/batch',
        body: utf8.encode('{}'),
      );
      expect(r.status, HttpStatus.forbidden);
      expect(utf8.decode(r.body), 'Control Center does not proxy Git LFS.\n');
      expect(nothingUpstream(), isTrue);
    });

    test(
      'a crafted path is refused before anything is minted or sent',
      () async {
        for (final (method, path) in const [
          (
            'GET',
            '/agent/git/github.com/acme/..%2Fwidgets.git/info/refs'
                '?service=git-upload-pack',
          ),
          (
            'GET',
            '/agent/git/github.com/acme/sub/widgets.git/info/refs'
                '?service=git-upload-pack',
          ),
          (
            'GET',
            '/agent/git/bitbucket.org/acme/sub/shop-ui.git/info/refs'
                '?service=git-upload-pack',
          ),
          (
            'GET',
            '/agent/git/evil.example/acme/widgets.git/info/refs'
                '?service=git-upload-pack',
          ),
          (
            'GET',
            '/agent/git/github.com/acme/wid%20gets.git/info/refs'
                '?service=git-upload-pack',
          ),
          (
            'GET',
            '/agent/git/github.com/-acme/widgets.git/info/refs'
                '?service=git-upload-pack',
          ),
          ('GET', '/agent/git/github.com/acme/.git/info/refs?service=x'),
          (
            'GET',
            '/agent/git/github.com/acme/.git/info/refs?service=git-upload-pack',
          ),
          (
            'GET',
            '/agent/git/github.com/widgets.git/info/refs'
                '?service=git-upload-pack',
          ),
          ('GET', '/agent/git/github.com/acme/widgets.git/info/refs'),
          ('GET', '/agent/git/github.com/acme/widgets.git/objects/info/packs'),
          (
            'POST',
            '/agent/git/github.com/acme/widgets.git/info/refs'
                '?service=git-upload-pack',
          ),
          ('GET', '/agent/git/github.com/acme/widgets.git/git-upload-pack'),
        ]) {
          final r = await fetch(method, path);
          expect(r.status, HttpStatus.forbidden, reason: path);
          expect(utf8.decode(r.body), startsWith('Control Center '));
        }
        expect(nothingUpstream(), isTrue);
        expect(broker.scopes, isEmpty);
        expect(looked, isEmpty);
      },
    );

    test('compressed bodies reach each side as they can read them', () async {
      client.autoUncompress = false;
      final negotiation = gzip.encode(utf8.encode('0009done\n'));
      forges[ForgeHost.gitlab]!.answer = (response) async {
        response.headers
          ..set(
            HttpHeaders.contentTypeHeader,
            'application/x-git-upload-pack-result',
          )
          ..set(HttpHeaders.contentEncodingHeader, 'gzip');
        response.add(gzip.encode(utf8.encode('pack-bytes')));
      };

      final r = await fetch(
        'POST',
        uploadPack('gitlab.com/acme/platform/api-server.git'),
        body: negotiation,
        headers: const {'Content-Encoding': 'gzip'},
      );

      // git's gzip request goes upstream untouched, header and all.
      final seen = forges[ForgeHost.gitlab]!.seen.single;
      expect(seen.encoding, 'gzip');
      expect(seen.body, negotiation);
      // The forge's gzip answer was decoded on the way, so it comes back
      // plain and says so.
      expect(r.status, 200);
      expect(r.headers.value(HttpHeaders.contentEncodingHeader), isNull);
      expect(utf8.decode(r.body), 'pack-bytes');
    });

    test('a redirect is neither followed nor relayed', () async {
      forges[ForgeHost.gitlab]!.answer = (response) async {
        response
          ..statusCode = HttpStatus.found
          ..headers.set(
            HttpHeaders.locationHeader,
            'http://127.0.0.1:${forges[ForgeHost.github]!.server.port}/x.git',
          );
      };

      final r = await fetch(
        'GET',
        advert('gitlab.com/acme/platform/api-server.git'),
      );

      expect(r.status, HttpStatus.badGateway);
      expect(r.headers.value(HttpHeaders.locationHeader), isNull);
      expect(
        utf8.decode(r.body),
        startsWith(
          'Control Center: GitLab answered with a redirect (HTTP 302)',
        ),
      );
      expect(forges[ForgeHost.gitlab]!.seen, hasLength(1));
      expect(forges[ForgeHost.github]!.seen, isEmpty);
    });

    test('a forge\'s 401 never makes git ask for a password', () async {
      forges[ForgeHost.bitbucket]!.answer = (response) async {
        response
          ..statusCode = HttpStatus.unauthorized
          ..headers.set(
            HttpHeaders.wwwAuthenticateHeader,
            'Basic realm="Bitbucket"',
          );
      };

      final r = await fetch('GET', advert('bitbucket.org/acme/shop-ui.git'));

      expect(r.status, HttpStatus.forbidden);
      expect(r.headers.value(HttpHeaders.wwwAuthenticateHeader), isNull);
      expect(
        utf8.decode(r.body),
        'Control Center: Bitbucket refused this request (HTTP 401).\n',
      );
    });

    test(
      'a missing credential is a refusal, never an anonymous fetch',
      () async {
        fetchTokens = {};
        fetchRefusal = 'Sign in to GitLab in Control Center first.';
        broker.refusal = 'The GitHub App is not installed on acme/widgets.';

        final gitlab = await fetch(
          'GET',
          advert('gitlab.com/acme/platform/api-server.git'),
        );
        fetchRefusal = null;
        final bitbucket = await fetch(
          'POST',
          uploadPack('bitbucket.org/acme/shop-ui.git'),
          body: utf8.encode('0000'),
        );
        final github = await fetch(
          'GET',
          advert('github.com/acme/widgets.git'),
        );

        expect(gitlab.status, HttpStatus.serviceUnavailable);
        expect(
          utf8.decode(gitlab.body),
          'Control Center: Sign in to GitLab in Control Center first.\n',
        );
        expect(bitbucket.status, HttpStatus.serviceUnavailable);
        expect(
          utf8.decode(bitbucket.body),
          'Control Center has no Bitbucket credential that can read '
          'acme/shop-ui.\n',
        );
        expect(github.status, HttpStatus.serviceUnavailable);
        expect(
          utf8.decode(github.body),
          contains('The GitHub App is not installed on acme/widgets.'),
        );
        expect(nothingUpstream(), isTrue);
      },
    );

    test(
      'without a credential lookup GitLab and Bitbucket are refused',
      () async {
        gateway = fetchGateway(withLookup: false);
        lease = await openRun();

        final r = await fetch(
          'GET',
          advert('gitlab.com/acme/platform/api-server.git'),
        );

        expect(r.status, HttpStatus.serviceUnavailable);
        expect(
          utf8.decode(r.body),
          'Control Center has no GitLab credential that can read '
          'acme/platform/api-server.\n',
        );
        expect(nothingUpstream(), isTrue);
      },
    );

    test('no credential appears in any answer or log line', () async {
      forges[ForgeHost.bitbucket]!.answer = (response) async {
        response.statusCode = HttpStatus.unauthorized;
      };
      final answers = [
        for (final repo in const [
          'github.com/acme/widgets.git',
          'gitlab.com/acme/platform/api-server.git',
          'bitbucket.org/acme/shop-ui.git',
        ]) ...[
          await fetch('GET', advert(repo)),
          await fetch('POST', uploadPack(repo), body: utf8.encode('0000')),
        ],
      ];
      expect(forges.values.every((f) => f.seen.isNotEmpty), isTrue);

      final secrets = [
        reviewToken,
        gitlabToken,
        'bitbucket-test-token',
        for (final (forge, token) in [
          (ForgeHost.github, reviewToken),
          (ForgeHost.gitlab, gitlabToken),
          (ForgeHost.bitbucket, bitbucketToken),
        ])
          forgeGitBasicAuthorization(forge, token).substring('Basic '.length),
      ];
      final said = [
        for (final a in answers) ...[
          utf8.decode(a.body, allowMalformed: true),
          a.headers.toString(),
        ],
        ...logged,
      ].join('\n');
      for (final secret in secrets) {
        expect(said, isNot(contains(secret)));
      }
    });
  });

  group('fetch routing', () {
    late Directory home;

    setUp(() {
      home = Directory.systemTemp.createTempSync('cc_lease_fetch');
      // A user who rewrites every GitHub and GitLab URL to SSH: the run's
      // repositories must still reach the gateway.
      File('${home.path}/gitconfig').writeAsStringSync('''
[url "git@github.com:"]
\tinsteadOf = "https://github.com/"
[url "git@gitlab.com:"]
\tinsteadOf = "https://gitlab.com/"
''');
    });

    tearDown(() => home.deleteSync(recursive: true));

    Map<String, String> gitEnv(AgentRunLease run) {
      final env = <String, String>{
        'GIT_CONFIG_GLOBAL': '${home.path}/gitconfig',
        'GIT_CONFIG_NOSYSTEM': '1',
        'GIT_TERMINAL_PROMPT': '0',
      };
      return {...env, ...run.environment(env)};
    }

    Future<ProcessResult> git(List<String> args, Map<String, String> env) =>
        Process.run('git', args, workingDirectory: home.path, environment: env);

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

    Future<AgentRunLease> everyForge() async => (await gateway.open(
      const AgentRunGrant(
        workspaceId: 'w1',
        conversationId: 'c-forges',
        repos: [
          _widgets,
          (forge: ForgeHost.gitlab, owner: 'acme/platform', name: 'api-server'),
          (forge: ForgeHost.bitbucket, owner: 'acme', name: 'shop-ui'),
        ],
      ),
    ))!;

    test('every spelling of each of the run\'s repositories fetches through '
        'the gateway', () async {
      final run = await everyForge();
      final env = gitEnv(run);
      final gw = '${run.base}/agent/git';
      for (final (origins, expected) in [
        (
          const [
            'git@github.com:acme/widgets.git',
            'ssh://git@github.com/acme/widgets.git',
            'https://github.com/acme/widgets.git',
          ],
          '$gw/github.com/acme/widgets.git',
        ),
        (
          const [
            'git@gitlab.com:acme/platform/api-server.git',
            'ssh://git@gitlab.com/acme/platform/api-server.git',
            'https://gitlab.com/acme/platform/api-server.git',
          ],
          '$gw/gitlab.com/acme/platform/api-server.git',
        ),
        (
          const [
            'git@bitbucket.org:acme/shop-ui.git',
            'ssh://git@bitbucket.org/acme/shop-ui.git',
            'https://bitbucket.org/acme/shop-ui.git',
          ],
          '$gw/bitbucket.org/acme/shop-ui.git',
        ),
      ]) {
        for (final origin in origins) {
          final resolved = await urls(origin, env);
          expect(resolved.fetch, expected, reason: origin);
          // GitHub pushes go by pushInsteadOf; elsewhere the gateway refuses
          // the push and says to use stack_publish.
          expect(resolved.push, expected, reason: origin);
        }
      }
      await gateway.close(run);
    });

    test('other repos keep the user\'s own routing', () async {
      final run = await everyForge();
      final resolved = await urls(
        'https://gitlab.com/other/repo.git',
        gitEnv(run),
      );
      expect(resolved.fetch, 'git@gitlab.com:other/repo.git');
      await gateway.close(run);
    });

    test(
      'the run\'s git config names no credential and no forge token',
      () async {
        final asked = await send('GET', AgentRunForgeTokens.path);
        expect(asked.body, _Broker.token(ForgeTokenScope.review));

        final run = await everyForge();
        expect(run.fetchGitConfig, hasLength(9));
        for (final (key, _) in run.fetchGitConfig) {
          expect(key, endsWith('.insteadOf'));
        }
        final added = lease.environment(const {});
        expect(added.keys, isNot(contains('GH_TOKEN')));
        expect(
          added.values.where((v) => v.toLowerCase().contains('credential')),
          isEmpty,
        );
        expect(
          added.values.where(
            (v) => v.contains(_Broker.token(ForgeTokenScope.review)),
          ),
          isEmpty,
        );
        final config = await git(['config', '--list'], gitEnv(run));
        expect(config.stdout, isNot(contains('credential.')));
        await gateway.close(run);
      },
    );

    test('a run on no repository keeps its origin', () async {
      final run = (await gateway.open(
        const AgentRunGrant(workspaceId: 'w1', conversationId: 'c1'),
      ))!;
      final resolved = await urls(
        'git@github.com:acme/widgets.git',
        gitEnv(run),
      );
      expect(resolved.fetch, 'git@github.com:acme/widgets.git');
      expect(run.fetchGitConfig, isEmpty);
      await gateway.close(run);
    });

    test('a repo name unfit for a config key adds no fetch routing', () async {
      for (final (forge, owner, name) in const [
        (ForgeHost.github, 'acme', '..'),
        (ForgeHost.github, '..', 'widgets'),
        (ForgeHost.github, 'acme', 'wid gets'),
        (ForgeHost.github, 'acme/x', 'widgets'),
        (ForgeHost.bitbucket, 'acme/x', 'shop-ui'),
        (ForgeHost.gitlab, 'acme//x', 'api-server'),
        (ForgeHost.gitlab, 'acme/../x', 'api-server'),
        (ForgeHost.github, 'acme', 'widgets\nhelper'),
        (ForgeHost.github, '-acme', 'widgets'),
        (ForgeHost.github, 'acme', r'widgets$(id)'),
        (ForgeHost.github, 'acme', 'widgets"; id; "'),
        (ForgeHost.local, 'acme', 'widgets'),
      ]) {
        final run = (await gateway.open(
          AgentRunGrant(
            workspaceId: 'w1',
            conversationId: 'c1',
            repos: [(forge: forge, owner: owner, name: name)],
          ),
        ))!;
        expect(run.fetchGitConfig, isEmpty, reason: '$owner/$name');
        await gateway.close(run);
      }
    });
  });

  group('the run\'s read token', () {
    const path = AgentRunForgeTokens.path;
    final token = _Broker.token(ForgeTokenScope.review);

    String named(String repo) => '$path?repo=${Uri.encodeQueryComponent(repo)}';

    test('is the review token of the run\'s repository, bounded by the '
        'person it acts for and never their own sign-in', () async {
      final requested = (await gateway.open(
        AgentRunGrant(
          workspaceId: 'w1',
          conversationId: 'c-person',
          actingUserId: 'bo',
          repos: const [_widgets],
          identity: _adaIdentity,
        ),
      ))!;

      final r = await send('GET', path, secret: requested.secret);

      expect(r.status, HttpStatus.ok);
      expect(r.body, token);
      expect(broker.scopes, [ForgeTokenScope.review]);
      expect(broker.personal, [false]);
      expect(broker.actors, ['bo']);
      expect(broker.repos, ['acme/widgets']);
      await gateway.close(requested);
    });

    test('every spelling of the repository names it, on one mint', () async {
      for (final repo in const [
        'acme/widgets',
        'ACME/Widgets',
        'acme/widgets.git',
        'github.com/acme/widgets',
        'https://github.com/acme/widgets',
        'https://github.com/acme/widgets.git',
        'git@github.com:acme/widgets.git',
        'ssh://git@github.com/acme/widgets.git',
      ]) {
        final r = await send('GET', named(repo));
        expect(r.status, HttpStatus.ok, reason: repo);
        expect(r.body, token, reason: repo);
      }
      expect(broker.scopes, hasLength(1));
      expect(broker.repos, [
        'acme/widgets',
      ], reason: 'minted under the name the server recorded');
    });

    test('a repository the run does not work on is refused, linked to the '
        'workspace or not, and nothing is minted', () async {
      linked.add('acme/secrets');
      for (final repo in const [
        'acme/secrets',
        'other/widgets',
        'acme/widgets-extra',
        'acme/widgets/extra',
        'https://gitlab.com/acme/widgets',
        'https://bitbucket.org/acme/widgets',
        'not a repo',
        '../widgets',
      ]) {
        final r = await send('GET', named(repo));
        expect(r.status, HttpStatus.forbidden, reason: repo);
        expect(r.body, startsWith('Control Center: this run has no GitHub '));
        expect(r.body, contains('acme/widgets'), reason: repo);
      }
      expect(broker.scopes, isEmpty);
    });

    test('a run on several repositories names the one it means', () async {
      final run = (await gateway.open(
        const AgentRunGrant(
          workspaceId: 'w1',
          conversationId: 'c-space',
          repos: [
            (forge: ForgeHost.github, owner: 'acme', name: 'shop-ui'),
            (forge: ForgeHost.github, owner: 'acme', name: 'api-server'),
          ],
        ),
      ))!;

      final unnamed = await send('GET', path, secret: run.secret);
      expect(unnamed.status, HttpStatus.badRequest);
      expect(unnamed.body, contains('acme/shop-ui, acme/api-server'));
      expect(unnamed.body, contains('--repo owner/name'));
      expect(broker.scopes, isEmpty);

      for (final name in const ['shop-ui', 'api-server']) {
        final r = await send('GET', named('acme/$name'), secret: run.secret);
        expect(r.body, _Broker.token(ForgeTokenScope.review, name));
      }
      // The first repository's token is never the second one's.
      final again = await send(
        'GET',
        named('acme/shop-ui'),
        secret: run.secret,
      );
      expect(again.body, _Broker.token(ForgeTokenScope.review, 'shop-ui'));
      expect(broker.repos, ['acme/shop-ui', 'acme/api-server']);
      await gateway.close(run);
    });

    test('a run on no repository has none', () async {
      final run = (await gateway.open(
        const AgentRunGrant(workspaceId: 'w1', conversationId: 'c-none'),
      ))!;

      final unnamed = await send('GET', path, secret: run.secret);
      final asked = await send(
        'GET',
        named('acme/widgets'),
        secret: run.secret,
      );

      expect(unnamed.status, HttpStatus.badRequest);
      expect(asked.status, HttpStatus.forbidden);
      for (final r in [unnamed, asked]) {
        expect(r.body, contains('works on no GitHub repository'));
      }
      expect(broker.scopes, isEmpty);
      await gateway.close(run);
    });

    test('one run never reads with another\'s lease', () async {
      final other = (await gateway.open(
        const AgentRunGrant(
          workspaceId: 'w2',
          conversationId: 'c-other',
          repos: [(forge: ForgeHost.github, owner: 'other', name: 'repo')],
        ),
      ))!;

      final r = await send('GET', named('acme/widgets'), secret: other.secret);

      expect(r.status, HttpStatus.forbidden);
      expect(broker.scopes, isEmpty);
      await gateway.close(other);
    });

    test('a refusal says why, and leaves no credential live', () async {
      broker.refusal = 'Bo has no access to acme/widgets on GitHub.';

      final r = await send('GET', path);

      expect(r.status, HttpStatus.serviceUnavailable);
      expect(
        r.body,
        'Control Center: Bo has no access to acme/widgets on GitHub.\n',
      );
      expect(broker.revoked, ['h1']);
    });

    test('a refusal without a reason says what to do', () async {
      broker.refusal = '';

      final r = await send('GET', path);

      expect(r.status, HttpStatus.serviceUnavailable);
      expect(r.body, contains('Install the GitHub App on it'));
    });

    test('a refusal is asked again, not remembered', () async {
      broker.refusal = 'Not yet.';
      await send('GET', path);
      broker.refusal = null;

      final r = await send('GET', path);

      expect(r.status, HttpStatus.ok);
      expect(r.body, token);
    });

    test('concurrent requests share one mint', () async {
      final results = await Future.wait([
        for (var i = 0; i < 4; i++) send('GET', path),
      ]);

      expect(results.map((r) => r.body), everyElement(token));
      expect(broker.scopes, [ForgeTokenScope.review]);
    });

    test('is not the token a push is forwarded on', () async {
      rule(ActionClass.gitPush, ActionDecision.allow);
      await send('POST', pushPath, body: _push(['refs/heads/feature/a']));

      final r = await send('GET', path);

      expect(r.body, token);
      expect(r.body, isNot(_Broker.token(ForgeTokenScope.write)));
      expect(broker.scopes, [ForgeTokenScope.write, ForgeTokenScope.review]);
    });

    test('closing the lease revokes it, and the lease reads no more', () async {
      await send('GET', path);
      await send('GET', path);

      await gateway.close(lease);

      expect(broker.scopes, hasLength(1));
      expect(broker.revoked, ['h1']);
      final after = await send('GET', path);
      expect(after.status, HttpStatus.unauthorized);
      expect(broker.scopes, hasLength(1));
    });

    test('a lease that closes while its token is minted leaves none '
        'live', () async {
      broker.gate = Completer<void>();
      final pending = send('GET', path);
      await broker.minting.future;

      await gateway.close(lease);
      broker.gate!.complete();
      final r = await pending;

      expect(r.status, HttpStatus.serviceUnavailable);
      expect(r.body, isNot(contains(token)));
      expect(broker.revoked, ['h1']);
    });

    test('needs the run\'s secret', () async {
      final r = await send('GET', path, secret: 'not-a-run');

      expect(r.status, HttpStatus.unauthorized);
      expect(broker.scopes, isEmpty);
    });

    test('is read, never posted', () async {
      final r = await send('POST', path);

      expect(r.status, HttpStatus.notFound);
      expect(broker.scopes, isEmpty);
    });

    test('is marked uncacheable', () async {
      final request = await client.getUrl(
        Uri.parse('http://127.0.0.1:${host.port}$path'),
      );
      request.headers.set(AgentRunLease.tokenHeader, lease.secret);
      final response = await request.close();
      await response.drain<void>();

      expect(
        response.headers.value(HttpHeaders.cacheControlHeader),
        'no-store',
      );
    });

    test('a mint failure never echoes its detail to the agent', () async {
      broker.mintError = StateError('token ghs_leakedsecret rejected');

      final r = await send('GET', path);

      expect(r.status, HttpStatus.internalServerError);
      expect(r.body, isNot(contains('ghs_leakedsecret')));
    });
  });

  group('naming a repository', () {
    test('owner/name, a host path or any remote URL on GitHub', () {
      for (final value in const [
        'acme/widgets',
        'acme/widgets.git',
        'github.com/acme/widgets',
        'https://github.com/acme/widgets',
        'https://github.com/acme/widgets.git',
        'https://github.com/acme/widgets/',
        'https://x-access-token:secret@github.com/acme/widgets.git',
        'git@github.com:acme/widgets.git',
        'ssh://git@github.com/acme/widgets.git',
      ]) {
        expect(AgentRunForgeTokens.repoOf(value), _widgets, reason: value);
      }
    });

    test('nothing else', () {
      for (final value in const [
        '',
        'widgets',
        'acme/',
        '/widgets',
        'acme/widgets/extra',
        'acme widgets',
        '-acme/widgets',
        'https://gitlab.com/acme/widgets',
        'https://bitbucket.org/acme/widgets.git',
        'https://github.com/acme/widgets/tree/main',
        'https://example.com/acme/widgets',
      ]) {
        expect(AgentRunForgeTokens.repoOf(value), isNull, reason: value);
      }
    });

    test('a grant answers for its repositories in any letter case, on '
        'their own forge', () {
      const one = AgentRunGrant(
        workspaceId: 'w1',
        conversationId: 'c1',
        repos: [(forge: ForgeHost.github, owner: 'Acme', name: 'Widgets')],
      );
      const several = AgentRunGrant(
        workspaceId: 'w1',
        conversationId: 'c1',
        repos: [
          (forge: ForgeHost.github, owner: 'acme', name: 'shop-ui'),
          (forge: ForgeHost.github, owner: 'acme', name: 'api-server'),
        ],
      );
      const mixed = AgentRunGrant(
        workspaceId: 'w1',
        conversationId: 'c1',
        repos: [
          (forge: ForgeHost.gitlab, owner: 'acme/platform', name: 'api-server'),
          (forge: ForgeHost.github, owner: 'acme', name: 'widgets'),
        ],
      );
      const none = AgentRunGrant(workspaceId: 'w1', conversationId: 'c1');

      expect(one.repoOn(ForgeHost.github, 'acme', 'widgets'), (
        forge: ForgeHost.github,
        owner: 'Acme',
        name: 'Widgets',
      ));
      expect(one.repoOn(ForgeHost.github, 'acme', 'widgets-extra'), isNull);
      expect(one.repoOn(ForgeHost.gitlab, 'acme', 'widgets'), isNull);
      expect(one.soleGitHubRepo, one.repos.single);
      expect(several.soleGitHubRepo, isNull);
      expect(several.repoOn(ForgeHost.github, 'ACME', 'API-Server'), isNotNull);
      expect(
        mixed.repoOn(ForgeHost.gitlab, 'Acme/Platform', 'api-server'),
        isNotNull,
      );
      expect(mixed.gitHubRepos, [_widgets]);
      expect(mixed.soleGitHubRepo, _widgets);
      expect(none.soleGitHubRepo, isNull);
      expect(none.repoOn(ForgeHost.github, 'acme', 'widgets'), isNull);
    });
  });

  group('gh for a run', () {
    final token = _Broker.token(ForgeTokenScope.review);
    late Directory dir;
    late String shim;

    setUp(() async {
      dir = Directory.systemTemp.createTempSync('cc_run_gh_');
      // The run's shim directory, and the directory of the real gh: here
      // one that reports the token and arguments it was run with.
      shim = '${dir.path}/shims/${AgentRunForgeTokens.ghShimName}';
      final real = '${dir.path}/real/gh';
      for (final (path, script) in [
        (shim, AgentRunForgeTokens.ghShim(gateway.client)),
        (
          real,
          '#!/bin/sh\n'
              r'printf "token=%s\n" "${GH_TOKEN:-}"'
              '\n'
              r'for a; do printf "arg=%s\n" "$a"; done'
              '\n',
        ),
      ]) {
        File(path)
          ..createSync(recursive: true)
          ..writeAsStringSync(script);
        await Process.run('/bin/chmod', ['755', path]);
      }
    });

    tearDown(() => dir.deleteSync(recursive: true));

    Future<ProcessResult> gh(
      List<String> args, {
      AgentRunLease? run,
      Map<String, String> env = const {},
      String? cwd,
      bool realGh = true,
    }) => Process.run(
      shim,
      args,
      workingDirectory: cwd ?? dir.path,
      environment: {
        'GIT_CONFIG_NOSYSTEM': '1',
        'GIT_CONFIG_GLOBAL': '${dir.path}/no-gitconfig',
        // What a run's environment never carries, whatever this test's
        // own shell does.
        'GH_TOKEN': '',
        'GH_REPO': '',
        ...(run ?? lease).environment(const {}),
        'PATH': [
          '${dir.path}/shims',
          if (realGh) '${dir.path}/real',
          if (realGh) Platform.environment['PATH'] ?? '/usr/bin:/bin',
        ].join(':'),
        ...env,
      },
    );

    test('reads what the lease sets, and asks the agent run client', () {
      final script = AgentRunForgeTokens.ghShim(gateway.client);
      expect(script, contains('"\$${AgentRunLease.gatewayEnvKey}"'));
      expect(script, contains('"\$${AgentRunLease.tokenEnvKey}"'));
      expect(
        script,
        contains('${gateway.client.shellCommand} forge-token "\$repo"'),
      );
      expect(script, isNot(contains('curl')));
    });

    test('runs the real gh, arguments untouched, on the token of the '
        'repository the command names', () async {
      for (final args in const [
        ['pr', 'view', '12', '--repo', 'acme/widgets'],
        ['pr', 'view', '12', '--repo=acme/widgets'],
        ['-R', 'acme/widgets', 'issue', 'list', '--search', 'a b  c'],
        ['run', 'list', '-Racme/widgets'],
        ['pr', 'list', '--repo', 'https://github.com/acme/widgets'],
        ['pr', 'list', '--repo', 'github.com/acme/widgets'],
      ]) {
        final result = await gh(args);
        expect(result.exitCode, 0, reason: '$args ${result.stderr}');
        expect(
          result.stdout,
          'token=$token\n${[for (final a in args) 'arg=$a\n'].join()}',
        );
        expect(result.stderr, isEmpty);
      }
      expect(broker.scopes, [ForgeTokenScope.review]);
    });

    test('reads GH_REPO', () async {
      final result = await gh(
        const ['pr', 'list'],
        env: const {'GH_REPO': 'acme/widgets'},
      );

      expect(result.stdout, startsWith('token=$token\n'));
    });

    test('otherwise asks for the checkout it runs in', () async {
      final run = (await gateway.open(
        const AgentRunGrant(
          workspaceId: 'w1',
          conversationId: 'c-space',
          repos: [
            (forge: ForgeHost.github, owner: 'acme', name: 'shop-ui'),
            (forge: ForgeHost.github, owner: 'acme', name: 'api-server'),
          ],
        ),
      ))!;
      final checkout = Directory('${dir.path}/api-server')..createSync();
      for (final args in [
        ['init', '-q'],
        ['remote', 'add', 'origin', 'git@github.com:acme/api-server.git'],
      ]) {
        await Process.run('git', args, workingDirectory: checkout.path);
      }

      final inside = await gh(
        const ['pr', 'status'],
        run: run,
        cwd: checkout.path,
      );
      final outside = await gh(const ['pr', 'status'], run: run);

      expect(
        inside.stdout,
        startsWith(
          'token=${_Broker.token(ForgeTokenScope.review, 'api-server')}\n',
        ),
      );
      // Outside a checkout, with several to choose from, it runs signed
      // out and says how to choose.
      expect(outside.stdout, 'token=\narg=pr\narg=status\n');
      expect(outside.stderr, contains('--repo owner/name'));
      await gateway.close(run);
    });

    test('a run on one repository reads it from anywhere', () async {
      final result = await gh(const ['api', 'rate_limit']);

      expect(result.stdout, 'token=$token\narg=api\narg=rate_limit\n');
    });

    test('a repository that is not the run\'s runs signed out, and says '
        'so', () async {
      final result = await gh(const ['pr', 'list', '--repo', 'other/repo']);

      expect(result.exitCode, 0);
      expect(
        result.stdout,
        'token=\narg=pr\narg=list\narg=--repo\narg=other/repo\n',
      );
      expect(
        result.stderr,
        contains('this run has no GitHub token for other/repo'),
      );
      expect(broker.scopes, isEmpty);
    });

    test('a refusal reaches the agent in words', () async {
      broker.refusal = 'Bo has no access to acme/widgets on GitHub.';

      final result = await gh(const ['pr', 'list']);

      expect(result.stdout, startsWith('token=\n'));
      expect(
        result.stderr,
        'Control Center: Bo has no access to acme/widgets on GitHub.\n',
      );
    });

    test('a gateway that does not answer leaves gh signed out, and says '
        'so', () async {
      final result = await gh(
        const ['pr', 'list'],
        // Nothing listens on the discard port.
        env: {AgentRunLease.gatewayEnvKey: 'http://127.0.0.1:9'},
      );

      expect(result.exitCode, 0);
      expect(result.stdout, 'token=\narg=pr\narg=list\n');
      expect(
        result.stderr,
        'Control Center: the agent run gateway did not answer.\n',
      );
    });

    test('without a gateway it is plain gh', () async {
      final result = await gh(
        const ['--version'],
        env: {AgentRunLease.gatewayEnvKey: ''},
      );

      expect(result.stdout, 'token=\narg=--version\n');
      expect(broker.scopes, isEmpty);
    });

    test('where gh is not installed, it is not found', () async {
      final result = await gh(const ['pr', 'list'], realGh: false);

      expect(result.exitCode, 127);
      expect(result.stderr, contains('gh: command not found'));
      expect(broker.scopes, isEmpty);
    });

    test(
      'never finds itself under another spelling of its directory',
      () async {
        final alias = Link('${dir.path}/alias')
          ..createSync('${dir.path}/shims');

        final result = await gh(
          const ['pr', 'list'],
          env: {'PATH': '${alias.path}:${dir.path}/shims/.:${dir.path}/shims'},
        );

        expect(result.exitCode, 127);
      },
    );
  }, skip: _needsPosixShell);

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
      rule(ActionClass.fileDelete, ActionDecision.deny);
      final result = await hook('Bash', 'git add -A && rm stale.txt');
      expect(result.exitCode, 2);
      expect(result.err, contains('Control Center policy'));
      expect(confirm.asked, isEmpty);
    });

    for (final command in [
      'git add -A && gh pr create --fill',
      'gh api repos/acme/widgets/pulls -f title=x -f head=a -f base=main',
    ]) {
      test(
        'opening a pull request from the shell is refused: $command',
        () async {
          // Even an allow rule cannot let it through: the run's token cannot
          // open one, and the server opens it as the requester instead.
          rule(ActionClass.prCreate, ActionDecision.allow);
          final result = await hook('Bash', command);
          expect(result.exitCode, 2);
          expect(result.err, contains('open_pull_request'));
          expect(confirm.asked, isEmpty);
        },
      );
    }

    for (final command in [
      'gh pr comment 12 --body done',
      'gh pr edit 12 --body x',
      'GH_TOKEN=token gh pr merge 12 --squash',
      'command gh pr review 12 --approve',
      'gh issue comment 3 --body hi',
      'gh api repos/acme/widgets/issues/12/comments -f body=hi',
    ]) {
      test('a GitHub write from the shell is refused: $command', () async {
        // Even an allow rule cannot let it through: the run's token only
        // reads, and the agent comments through the server instead.
        rule(ActionClass.prPublish, ActionDecision.allow);
        rule(ActionClass.vendorSyncWrite, ActionDecision.allow);
        final result = await hook('Bash', command);
        expect(result.exitCode, 2);
        expect(result.err, contains('comment_on_pull_request'));
        expect(result.err, contains('update_pull_request'));
        expect(confirm.asked, isEmpty);
      });
    }

    for (final command in [
      'gh pr view 12 --repo acme/widgets',
      'gh pr checks 12',
      'gh run list --limit 5',
      'gh api repos/acme/widgets/pulls/12',
      'git fetch origin main',
    ]) {
      test('reading GitHub from the shell asks nothing: $command', () async {
        final result = await hook('Bash', command);
        expect(result.exitCode, 0, reason: result.err);
        expect(confirm.asked, isEmpty);
      });
    }

    test('approval holds the hook until the operator answers', () async {
      confirm.pending = Completer<bool>();
      confirm.requested = Completer<void>();
      var completed = false;
      final pending = hook('Bash', 'rm stale.txt').then((result) {
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
        const command = 'rm stale.txt';
        final result = await hook(
          'Bash',
          command,
          description: 'Remove the stale fixture file now',
        );
        expect(result.exitCode, 0);
        expect(
          confirm.asked.single.detail,
          contains('Remove the stale fixture file now'),
        );
        expect(confirm.asked.single.command, command);
      },
    );

    const compoundPush =
        r'cd repos/shop-ui && U="https://x-access-token:${GH_TOKEN}@github.com:443/acme/widgets.git"; '
        r'ARGS=(); for b in feature/a feature/b; do ARGS+=("--force-with-lease=refs/heads/$b:$(git rev-parse origin/$b)"); '
        r'done; git push "${ARGS[@]}" "$U" feature/a:refs/heads/feature/a 2>&1 | cat';
    for (final command in [compoundPush, 'cd repo; rm obsolete.dart']) {
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

      // An unknown destination is remembered by its exact command only; the
      // push gateway still asks about the real branch.
      await hook('Bash', 'git push');
      expect(
        ActionConstraint.decode(confirm.asked.last.constraintJson),
        const ActionConstraint(commands: ['git push']),
      );
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

    test('a client that is missing or fails still blocks', () async {
      for (final command in [
        ['/nonexistent/cc_server', 'agent-run'],
        // Exits 1, which Claude Code would not treat as a block.
        ['/usr/bin/false'],
      ]) {
        final run = (await AgentRunGateway(
          guard: ActionGuardService(
            repository: rules,
            confirmationPort: confirm,
          ),
          broker: broker,
          loopbackBase: () async => Uri.parse('http://127.0.0.1:${host.port}'),
          client: AgentRunClientLauncher(command: command, files: command),
        ).open(const AgentRunGrant(workspaceId: 'w1', conversationId: 'c1')))!;
        final settings =
            jsonDecode(AgentRunLease.claudeHookSettings(run)) as Map;
        final entry =
            ((settings['hooks'] as Map)['PreToolUse'] as List).single as Map;
        final handler = (entry['hooks'] as List).single as Map;

        final result = await Process.run(
          'sh',
          ['-c', handler['command'] as String],
          environment: {AgentRunLease.tokenEnvKey: run.secret},
        );

        expect(result.exitCode, 2, reason: '$command');
        expect(
          result.stderr,
          endsWith(
            'Control Center permission check failed; command '
            'blocked.\n',
          ),
        );
      }
      expect(hookRequests, 0);
    });
  }, skip: Platform.isWindows ? 'Requires the POSIX hook shell.' : false);

  group('audit fixes', () {
    late Directory tree;

    setUp(() => tree = Directory.systemTemp.createTempSync('cc-gw-tree-'));
    tearDown(() => tree.deleteSync(recursive: true));

    Future<AgentRunLease> openRun({
      List<String> shared = const [],
      List<String> readOnly = const [],
      AutonomyLevel? autonomy,
    }) async => (await gateway.open(
      AgentRunGrant(
        workspaceId: 'w1',
        conversationId: 'c1',
        agentId: 'a1',
        spaceId: 's1',
        worktreeRoot: tree.path,
        sharedWorktreeRoots: shared,
        readOnlyWorktrees: readOnly,
        autonomy: () async => autonomy,
      ),
    ))!;

    Future<({int exitCode, String err})> runHook(
      AgentRunLease run,
      String tool,
      Map<String, Object?> input,
    ) async {
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

    test('a Claude write into a worktree the person may not change is '
        'refused before the policy is asked', () async {
      rule(ActionClass.fileWriteOutsideWorktree, ActionDecision.allow);
      final shared = Directory.systemTemp.createTempSync('cc-gw-shared-');
      addTearDown(() => shared.deleteSync(recursive: true));
      final locked = Directory('${shared.path}/locked')..createSync();
      Directory('${shared.path}/open').createSync();
      Link('${tree.path}/repos').createSync(shared.path);
      final run = await openRun(shared: [shared.path], readOnly: [locked.path]);

      for (final (tool, key) in [
        ('Write', 'file_path'),
        ('Edit', 'file_path'),
        ('MultiEdit', 'file_path'),
        ('NotebookEdit', 'notebook_path'),
      ]) {
        final result = await runHook(run, tool, {
          key: '${tree.path}/repos/locked/lib/a.dart',
          'content': 'x',
        });
        expect(result.exitCode, 2, reason: tool);
        expect(result.err, contains('locked is read-only for this run'));
        expect(result.err, contains('repo_grant_required, level write'));
      }
      final open = await runHook(run, 'Write', {
        'file_path': '${tree.path}/repos/open/lib/a.dart',
        'content': 'x',
      });
      expect(open.exitCode, 0, reason: open.err);
      expect(confirm.asked, isEmpty);
    });

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
      // Nobody asked for this run: it pushes as the App.
      expect(broker.personal, [false]);
    });

    test(
      'a push for a requester rides their own one-repository token',
      () async {
        rule(ActionClass.gitPush, ActionDecision.allow);
        final requested = (await gateway.open(
          AgentRunGrant(
            workspaceId: 'w1',
            conversationId: 'c-person',
            actingUserId: 'u1',
            repos: const [_widgets],
            identity: _adaIdentity,
          ),
        ))!;

        final r = await send(
          'POST',
          pushPath,
          body: _push(['refs/heads/feature/a']),
          secret: requested.secret,
        );

        expect(r.status, 200);
        expect(broker.personal, [true]);
        await gateway.close(requested);
      },
    );

    test('a failure never echoes its detail to the agent', () async {
      rule(ActionClass.gitPush, ActionDecision.allow);
      broker.mintError = StateError('token ghs_leakedsecret rejected');

      final r = await send('POST', pushPath, body: _push(['refs/heads/x']));

      expect(r.body, isNot(contains('ghs_leakedsecret')));
    });
  }, skip: Platform.isWindows ? 'Requires the POSIX hook shell.' : false);
}
