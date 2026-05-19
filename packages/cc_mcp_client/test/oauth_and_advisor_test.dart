import 'dart:convert';

import 'package:cc_mcp_client/cc_mcp_client.dart';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

void main() {
  group('PKCE', () {
    test('challenge is base64url(sha256(verifier)) with S256', () {
      final pair = PkcePair.generate();
      expect(pair.codeChallengeMethod, 'S256');
      final expected = base64Url
          .encode(sha256.convert(ascii.encode(pair.codeVerifier)).bytes)
          .replaceAll('=', '');
      expect(pair.codeChallenge, expected);
      // Verifier within RFC 7636 length bounds (43..128).
      expect(pair.codeVerifier.length, greaterThanOrEqualTo(43));
      expect(pair.state, isNotEmpty);
    });

    test('each pair is unique', () {
      expect(PkcePair.generate().codeVerifier,
          isNot(PkcePair.generate().codeVerifier));
    });
  });

  group('McpOAuthToken', () {
    test('expiry buffer detection', () {
      final fresh = McpOAuthToken(
        accessToken: 'a',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(fresh.isExpired(), isFalse);
      final stale = McpOAuthToken(
        accessToken: 'a',
        expiresAt: DateTime.now().add(const Duration(minutes: 1)),
      );
      expect(stale.isExpired(), isTrue); // within 5-min buffer
      const noExpiry = McpOAuthToken(accessToken: 'a');
      expect(noExpiry.isExpired(), isFalse);
    });

    test('json round-trip preserves refresh material', () {
      final token = McpOAuthToken(
        accessToken: 'a',
        refreshToken: 'r',
        tokenUrl: 'https://t/token',
        clientId: 'cid',
        expiresAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );
      final back = McpOAuthToken.fromJson(token.toJson());
      expect(back.refreshToken, 'r');
      expect(back.tokenUrl, 'https://t/token');
      expect(back.clientId, 'cid');
    });
  });

  group('SecretObfuscator', () {
    test('redacts registered literals and known patterns', () {
      final obf = SecretObfuscator(literals: {'supersecretvalue'});
      final input = 'token=supersecretvalue and ghp_${'a' * 36} done';
      final out = obf.obfuscate(input);
      expect(out, isNot(contains('supersecretvalue')));
      expect(out, isNot(contains('ghp_')));
      expect(out, contains(SecretObfuscator.placeholder));
    });
  });

  group('AdvisorRuntime', () {
    test('renders only the delta and obfuscates secrets', () {
      final runtime = AdvisorRuntime(
        model: _NullModel(),
        onAdvice: (_, _) {},
        obfuscator: SecretObfuscator(literals: {'topsecret'}),
      );
      final messages = [
        const AdvisorMessage(role: 'user', text: 'do a thing'),
        const AdvisorMessage(role: 'assistant', text: 'using topsecret now'),
      ];
      final delta = runtime.renderDelta(messages);
      expect(delta, contains('do a thing'));
      expect(delta, isNot(contains('topsecret')));
      // Second render with no new messages → empty.
      expect(runtime.renderDelta(messages), isEmpty);
    });

    test('concern/blocker interrupt, nit is an aside, dupes suppressed',
        () async {
      final delivered = <(AdvisorVerdict, AdvisorDelivery)>[];
      final model = _ScriptedModel([
        const AdvisorVerdict(note: 'careful here', severity: AdvisorSeverity.concern),
        const AdvisorVerdict(note: 'careful here', severity: AdvisorSeverity.concern),
        const AdvisorVerdict(note: 'careful here', severity: AdvisorSeverity.blocker),
      ]);
      final runtime = AdvisorRuntime(
        model: model,
        onAdvice: (v, d) => delivered.add((v, d)),
      );

      await runtime.onTurnEnd([const AdvisorMessage(role: 'user', text: 'a')]);
      await runtime.onTurnEnd([
        const AdvisorMessage(role: 'user', text: 'a'),
        const AdvisorMessage(role: 'user', text: 'b'),
      ]);
      await runtime.onTurnEnd([
        const AdvisorMessage(role: 'user', text: 'a'),
        const AdvisorMessage(role: 'user', text: 'b'),
        const AdvisorMessage(role: 'user', text: 'c'),
      ]);

      // First concern delivered (steer); duplicate suppressed; escalation to
      // blocker delivered.
      expect(delivered.length, 2);
      expect(delivered[0].$2, AdvisorDelivery.steer);
      expect(delivered[1].$1.severity, AdvisorSeverity.blocker);
    });
  });

  group('WatchdogDiscovery', () {
    test('orders user-level first, then ancestor→leaf', () async {
      final files = {
        '/home/.claude/WATCHDOG.md': 'global rule',
        '/home/proj/WATCHDOG.md': 'project rule',
      };
      final discovery = WatchdogDiscovery(
        homeDir: '/home',
        cwd: '/home/proj',
        stopDir: '/home',
        readFile: (p) async => files[p],
      );
      final result = await discovery.discover();
      expect(result, isNotNull);
      expect(result!.indexOf('global rule'),
          lessThan(result.indexOf('project rule')));
      expect(result, contains('<attention>'));
    });

    test('returns null when no files exist', () async {
      final discovery = WatchdogDiscovery(
        homeDir: '/home',
        cwd: '/home/proj',
        readFile: (_) async => null,
      );
      expect(await discovery.discover(), isNull);
    });
  });
}

class _NullModel implements AdvisorModel {
  @override
  Future<AdvisorVerdict?> review({
    required String systemPrompt,
    required String transcriptDelta,
  }) async => null;
}

class _ScriptedModel implements AdvisorModel {
  _ScriptedModel(this._verdicts);
  final List<AdvisorVerdict> _verdicts;
  int _i = 0;

  @override
  Future<AdvisorVerdict?> review({
    required String systemPrompt,
    required String transcriptDelta,
  }) async {
    if (_i >= _verdicts.length) {
      return null;
    }
    return _verdicts[_i++];
  }
}
