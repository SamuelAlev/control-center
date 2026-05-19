import 'dart:math';

import 'package:cc_domain/features/model_routing/domain/entities/model_provider.dart';
import 'package:cc_domain/features/model_routing/domain/entities/provider_policy.dart';
import 'package:cc_domain/features/model_routing/domain/entities/rate_limit.dart';
import 'package:cc_domain/features/model_routing/domain/repositories/provider_policy_repository.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';
import 'package:test/test.dart';

/// Covers the small model-routing + harness value types whose `==` / hashCode /
/// factory / convenience methods stayed uncovered: [ReasoningEffort] aliases,
/// [ModelProvider]/[ProviderEnablement] equality, [RateLimitClassification]
/// jitter + equality, [PolicyStatement]/[PolicyDocument] round-trips, and the
/// concrete data classes in the harness ports.
void main() {
  group('ReasoningEffort', () {
    test('fromId accepts canonical + alias spellings', () {
      expect(ReasoningEffort.fromId('minimal'), ReasoningEffort.minimal);
      expect(ReasoningEffort.fromId('none'), ReasoningEffort.minimal);
      expect(ReasoningEffort.fromId('off'), ReasoningEffort.minimal);
      expect(ReasoningEffort.fromId('low'), ReasoningEffort.low);
      expect(ReasoningEffort.fromId('medium'), ReasoningEffort.medium);
      expect(ReasoningEffort.fromId('mid'), ReasoningEffort.medium);
      expect(ReasoningEffort.fromId('high'), ReasoningEffort.high);
      expect(ReasoningEffort.fromId('xhigh'), ReasoningEffort.xhigh);
      expect(ReasoningEffort.fromId('max'), ReasoningEffort.xhigh);
      expect(ReasoningEffort.fromId('extra-high'), ReasoningEffort.xhigh);
    });

    test('fromId is case-insensitive + trims, null/unknown → null', () {
      expect(ReasoningEffort.fromId('  HIGH '), ReasoningEffort.high);
      expect(ReasoningEffort.fromId('XHigh'), ReasoningEffort.xhigh);
      expect(ReasoningEffort.fromId(null), isNull);
      expect(ReasoningEffort.fromId('bogus'), isNull);
    });

    test('id + label for every value', () {
      for (final v in ReasoningEffort.values) {
        expect(v.id, v.name);
      }
      expect(ReasoningEffort.minimal.label, 'Minimal');
      expect(ReasoningEffort.low.label, 'Low');
      expect(ReasoningEffort.medium.label, 'Medium');
      expect(ReasoningEffort.high.label, 'High');
      expect(ReasoningEffort.xhigh.label, 'Extra high');
    });
  });

  group('ProviderEnablement + ModelProvider', () {
    test('isEnabled discriminator', () {
      expect(const ProviderDisabled().isEnabled, isFalse);
      expect(const ProviderEnabledViaEnv('K').isEnabled, isTrue);
      expect(const ProviderEnabledViaAccount('svc').isEnabled, isTrue);
      expect(const ProviderEnabledViaCustom({'k': 'v'}).isEnabled, isTrue);
    });

    test('ProviderDisabled equality + hashCode', () {
      const a = ProviderDisabled(missingEnv: ['A', 'B']);
      const b = ProviderDisabled(missingEnv: ['A', 'B']);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const ProviderDisabled(missingEnv: ['A'])));
    });

    test('ProviderEnabledViaEnv equality + hashCode', () {
      const a = ProviderEnabledViaEnv('K');
      const b = ProviderEnabledViaEnv('K');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const ProviderEnabledViaEnv('OTHER')));
    });

    test('ProviderEnabledViaAccount equality + hashCode', () {
      const a = ProviderEnabledViaAccount('svc');
      const b = ProviderEnabledViaAccount('svc');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const ProviderEnabledViaAccount('other')));
    });

    test('ProviderEnabledViaCustom equality + hashCode', () {
      const a = ProviderEnabledViaCustom({'k': 'v'});
      const b = ProviderEnabledViaCustom({'k': 'v'});
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const ProviderEnabledViaCustom({'k': 'x'})));
    });

    test('ModelProvider isEnabled + withEnablement + toString', () {
      const disabled = ModelProvider(
        id: 'anthropic',
        name: 'Anthropic',
        description: 'desc',
        envKeys: ['ANTHROPIC_API_KEY'],
        docUrl: 'https://x',
        npm: '@anthropic',
      );
      expect(disabled.isEnabled, isFalse);
      expect(disabled.toString(), 'ModelProvider(anthropic, enabled=false)');
      final enabled = disabled.withEnablement(const ProviderEnabledViaEnv('K'));
      expect(enabled.isEnabled, isTrue);
      expect(enabled.toString(), 'ModelProvider(anthropic, enabled=true)');
      // withEnablement preserves other fields.
      expect(enabled.id, 'anthropic');
      expect(enabled.envKeys, ['ANTHROPIC_API_KEY']);
      expect(enabled.npm, '@anthropic');
    });

    test('ModelProvider equality + hashCode by (id, name, enablement)', () {
      const a = ModelProvider(
        id: 'p',
        name: 'P',
        enablement: ProviderEnabledViaEnv('K'),
      );
      const b = ModelProvider(
        id: 'p',
        name: 'P',
        enablement: ProviderEnabledViaEnv('K'),
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      // description difference is irrelevant to equality.
      const c = ModelProvider(
        id: 'p',
        name: 'P',
        description: 'other',
        enablement: ProviderEnabledViaEnv('K'),
      );
      expect(a, c);
      expect(a, isNot(const ModelProvider(id: 'p', name: 'Other')));
      // enablement difference breaks equality.
      expect(
        a,
        isNot(
          const ModelProvider(
            id: 'p',
            name: 'P',
            enablement: ProviderDisabled(),
          ),
        ),
      );
    });

    test('ProviderEntry is constructible', () {
      const entry = ProviderEntry(
        provider: ModelProvider(id: 'p', name: 'P'),
        models: {},
      );
      expect(entry.provider.id, 'p');
      expect(entry.models, isEmpty);
    });
  });

  group('RateLimitClassification', () {
    test('effectiveBackoff returns base when no jitter', () {
      const c = RateLimitClassification(
        reason: RateLimitReason.quotaExhausted,
        baseBackoff: Duration(seconds: 10),
        shouldRotate: true,
      );
      expect(c.effectiveBackoff(), const Duration(seconds: 10));
    });

    test('effectiveBackoff adds seeded jitter', () {
      const c = RateLimitClassification(
        reason: RateLimitReason.modelCapacity,
        baseBackoff: Duration(seconds: 5),
        shouldRotate: false,
        maxJitter: Duration(seconds: 10),
      );
      final r = Random(0);
      final ms = (r.nextDouble() * 10000).round();
      expect(
        c.effectiveBackoff(Random(0)),
        const Duration(seconds: 5) + Duration(milliseconds: ms),
      );
    });

    test('RateLimitReason.id', () {
      for (final v in RateLimitReason.values) {
        expect(v.id, v.name);
      }
    });

    test('equality + hashCode + toString', () {
      const a = RateLimitClassification(
        reason: RateLimitReason.rateLimitExceeded,
        baseBackoff: Duration(seconds: 1),
        shouldRotate: true,
        maxJitter: Duration(seconds: 2),
      );
      const b = RateLimitClassification(
        reason: RateLimitReason.rateLimitExceeded,
        baseBackoff: Duration(seconds: 1),
        shouldRotate: true,
        maxJitter: Duration(seconds: 2),
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(
        a.toString(),
        'RateLimitClassification(RateLimitReason.rateLimitExceeded, backoff=0:00:01.000000, rotate=true)',
      );
      expect(
        a,
        isNot(
          const RateLimitClassification(
            reason: RateLimitReason.unknown,
            baseBackoff: Duration(seconds: 1),
            shouldRotate: true,
          ),
        ),
      );
    });
  });

  group('PolicyStatement + PolicyDocument', () {
    test('PolicyEffect.fromRaw + id', () {
      expect(PolicyEffect.fromRaw('allow'), PolicyEffect.allow);
      expect(PolicyEffect.fromRaw('deny'), PolicyEffect.deny);
      // unknown → deny (fail closed)
      expect(PolicyEffect.fromRaw('bogus'), PolicyEffect.deny);
      expect(PolicyEffect.fromRaw(null), PolicyEffect.deny);
      expect(PolicyEffect.allow.id, 'allow');
      expect(PolicyEffect.deny.id, 'deny');
    });

    test('named constructors', () {
      const allow = PolicyStatement.allowProvider('anthropic');
      expect(allow.action, 'provider.use');
      expect(allow.effect, PolicyEffect.allow);
      expect(allow.resource, 'anthropic');
      const deny = PolicyStatement.denyProvider(
        'openai',
        layer: PolicyLayer.user,
      );
      expect(deny.effect, PolicyEffect.deny);
      expect(deny.layer, PolicyLayer.user);
    });

    test('toJson / fromJson round-trip + layer fallback', () {
      const s = PolicyStatement(
        action: 'provider.*',
        resource: '*-cn',
        effect: PolicyEffect.deny,
        layer: PolicyLayer.global,
      );
      final out = s.toJson();
      expect(out['action'], 'provider.*');
      expect(out['resource'], '*-cn');
      expect(out['effect'], 'deny');
      expect(out['layer'], 'global');
      expect(PolicyStatement.fromJson(out), s);
      // layer fallback → workspace when unknown.
      expect(
        PolicyStatement.fromJson(const {
          'action': 'provider.use',
          'resource': '*',
          'effect': 'allow',
          'layer': 'nope',
        }).layer,
        PolicyLayer.workspace,
      );
    });

    test('equality + hashCode + toString', () {
      const a = PolicyStatement(
        action: 'a',
        resource: 'r',
        effect: PolicyEffect.allow,
        layer: PolicyLayer.workspace,
      );
      const b = PolicyStatement(
        action: 'a',
        resource: 'r',
        effect: PolicyEffect.allow,
        layer: PolicyLayer.workspace,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.toString(), 'allow a r (workspace)');
      expect(
        a,
        isNot(
          const PolicyStatement(
            action: 'a',
            resource: 'r',
            effect: PolicyEffect.deny,
          ),
        ),
      );
    });

    test('PolicyDocument sorts by precedence + equality', () {
      final doc = PolicyDocument(const [
        PolicyStatement(
          action: 'a',
          resource: 'r',
          effect: PolicyEffect.allow,
          layer: PolicyLayer.workspace,
        ),
        PolicyStatement(
          action: 'a',
          resource: 'r',
          effect: PolicyEffect.deny,
          layer: PolicyLayer.global,
        ),
      ]);
      // global sorts before workspace (lowest precedence first).
      expect(doc.statements.first.layer, PolicyLayer.global);
      expect(doc.statements.last.layer, PolicyLayer.workspace);
      expect(doc.isEmpty, isFalse);
      expect(PolicyDocument.empty.isEmpty, isTrue);

      final same = PolicyDocument(const [
        PolicyStatement(
          action: 'a',
          resource: 'r',
          effect: PolicyEffect.deny,
          layer: PolicyLayer.global,
        ),
        PolicyStatement(
          action: 'a',
          resource: 'r',
          effect: PolicyEffect.allow,
          layer: PolicyLayer.workspace,
        ),
      ]);
      expect(doc, same);
      expect(doc.hashCode, same.hashCode);
    });
  });

  group('WorkspaceProviderPolicy', () {
    test('equality + hashCode by (id, statement)', () {
      const s = PolicyStatement.allowProvider('anthropic');
      const a = WorkspaceProviderPolicy(id: 'row1', statement: s);
      const b = WorkspaceProviderPolicy(id: 'row1', statement: s);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const WorkspaceProviderPolicy(id: 'row2', statement: s)));
      expect(
        a,
        isNot(
          const WorkspaceProviderPolicy(
            id: 'row1',
            statement: PolicyStatement.denyProvider('anthropic'),
          ),
        ),
      );
    });
  });

  group('NoopAgentLoopHooks', () {
    test('allows everything and is awaitable', () async {
      const hooks = NoopAgentLoopHooks();
      await hooks.onSessionStart();
      expect(await hooks.preToolUse('bash', {}), isTrue);
      await hooks.postToolUse('bash', 'ok', isError: false);
    });
  });

  group('Subagent data classes', () {
    test('SubagentSpawnRequest preserves fields', () {
      const req = SubagentSpawnRequest(
        description: 'do thing',
        label: 'worker',
        type: SubagentType.general,
        context: HarnessToolContext(
          workspaceId: 'w',
          conversationId: 'c',
          workingDirectory: '/',
          agentId: 'a',
        ),
        modelOverride: 'anthropic/opus',
        effortOverride: 'high',
      );
      expect(req.description, 'do thing');
      expect(req.label, 'worker');
      expect(req.type, SubagentType.general);
      expect(req.modelOverride, 'anthropic/opus');
      expect(req.effortOverride, 'high');
      expect(req.context.workspaceId, 'w');
    });

    test('SubagentResult defaults', () {
      const r = SubagentResult(text: 'done');
      expect(r.text, 'done');
      expect(r.isError, isFalse);
      expect(r.childRunId, isNull);
    });
  });
}
