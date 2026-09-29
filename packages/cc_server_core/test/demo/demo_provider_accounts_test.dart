import 'dart:convert';

import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_server_core/src/demo/demo_provider.dart';
import 'package:cc_server_core/src/demo/demo_runners.dart';
import 'package:test/test.dart';

void main() {
  const store = DemoCredentialStore();
  const factory = DemoHarnessProviderFactory();

  test('connected providers have multiple fictional accounts', () async {
    for (final id in ['anthropic', 'zai-coding', 'kimi-code']) {
      final accounts = await store.credentialsFor(id);
      expect(accounts.length, greaterThan(1), reason: id);
      expect(accounts.where((a) => a.isActive), hasLength(1), reason: id);
      expect(
        accounts.every((a) => (a.secret ?? '').contains('not-a-real')),
        isTrue,
        reason: id,
      );
      expect(accounts.every((a) => a.secretHint != null), isTrue, reason: id);
    }
  });

  test('an unconnected harness provider has no credential', () async {
    expect(await store.activeCredential('openai'), isNull);
    expect(await store.credentialsFor('openai'), isEmpty);
  });

  test(
    'an unknown provider id still clears the auth gate with no secret',
    () async {
      final credential = await store.activeCredential('demo');
      expect(credential, isNotNull);
      expect(credential!.method, HarnessAuthMethod.none);
      expect(credential.secret, anyOf(isNull, isEmpty));
    },
  );

  test('each connected provider advertises its own models', () async {
    final anthropic = factory.create(providerId: 'anthropic');
    final glm = factory.create(providerId: 'zai-coding');
    final kimi = factory.create(providerId: 'kimi-code');
    final openai = factory.create(providerId: 'openai');

    expect(
      (await anthropic.listModels()).map((m) => m.id),
      contains(kDemoModelId),
    );
    expect(
      (await glm.listModels()).map((m) => m.id),
      containsAll(['glm-5.3', 'glm-5.3-flash']),
    );
    expect(
      (await kimi.listModels()).map((m) => m.id),
      containsAll(['kimi-for-coding', 'k3']),
    );
    expect(await openai.listModels(), isEmpty);
    expect(anthropic.defaultModel, kDemoModelId);
    expect(glm.defaultModel, 'glm-5.3');
  });

  test(
    'detection reports both catalogued runners and never a caller path',
    () async {
      const detection = DemoAdapterRepository();
      final harness = await detection.detectOne(builtInAdapter);
      final claude = await detection.detectOne(
        predefinedAdapters.firstWhere((a) => a.id == 'claude-code'),
      );
      final planted = await detection.detectOne(
        const Adapter(
          id: 'not-a-runner',
          name: 'Planted',
          description: '',
          cliName: '/bin/sh',
        ),
      );

      expect(harness.status, DetectionStatus.found);
      expect(harness.version, 'built-in');
      expect(harness.path, isNull);
      expect(claude.status, DetectionStatus.found);
      expect(claude.path, isNull);
      expect(claude.capabilities?.supportsModelSelection, isTrue);
      expect(planted.status, DetectionStatus.notFound);
    },
  );

  test('Claude Code accounts are logged in and carry no secret', () async {
    final store = DemoClaudeAccountStore();
    final accounts = await store.listWithStatus();
    expect(accounts.map((a) => a.id), ['maya', 'diego', 'priya']);
    expect(accounts.where((a) => a.isDefault), hasLength(1));
    expect(accounts.every((a) => a.loggedIn), isTrue);

    final usage = await demoClaudeAccountUsage(store.configDirFor('diego'));
    expect(usage, isNotNull);
    expect(jsonEncode(usage), isNot(contains('not-a-real')));
    expect(await demoClaudeAccountUsage('demo-claude/nobody'), isNull);
  });
}
