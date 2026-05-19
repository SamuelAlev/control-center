import 'package:cc_domain/features/model_routing/model_routing.dart';
import 'package:test/test.dart';

void main() {
  group('Wildcard', () {
    test('* matches any run', () {
      expect(Wildcard.match('anthropic', '*'), isTrue);
      expect(Wildcard.match('alibaba-cn', '*-cn'), isTrue);
      expect(Wildcard.match('openai', '*-cn'), isFalse);
      expect(Wildcard.match('provider.use', 'provider.*'), isTrue);
    });

    test('? matches exactly one char', () {
      expect(Wildcard.match('gpt4', 'gpt?'), isTrue);
      expect(Wildcard.match('gpt40', 'gpt?'), isFalse);
    });

    test('escapes regex metacharacters', () {
      expect(Wildcard.match('a.b', 'a.b'), isTrue);
      expect(Wildcard.match('axb', 'a.b'), isFalse); // . is literal
    });

    test('normalizes backslashes to forward slashes', () {
      expect(Wildcard.match(r'a\b\c', 'a/b/c'), isTrue);
      expect(Wildcard.match('a/b/c', r'a\b\c'), isTrue);
    });
  });

  group('ProviderPolicyEngine', () {
    test('default fallback is allow when no statements match', () {
      final engine = ProviderPolicyEngine.fromStatements(const []);
      expect(engine.allowsProvider('anthropic'), isTrue);
    });

    test('last match wins', () {
      final engine = ProviderPolicyEngine.fromStatements(const [
        PolicyStatement.allowProvider('*'),
        PolicyStatement.denyProvider('openai'),
      ]);
      expect(engine.allowsProvider('anthropic'), isTrue);
      expect(engine.allowsProvider('openai'), isFalse);
    });

    test('deny-all then allow-one (last match wins)', () {
      final engine = ProviderPolicyEngine.fromStatements(const [
        PolicyStatement.denyProvider('*'),
        PolicyStatement.allowProvider('anthropic'),
      ]);
      expect(engine.allowsProvider('anthropic'), isTrue);
      expect(engine.allowsProvider('openai'), isFalse);
    });

    test('layered precedence: workspace overrides global', () {
      // Global allows everything; workspace denies data-collecting providers.
      final engine = ProviderPolicyEngine.fromStatements(const [
        PolicyStatement.denyProvider('*', layer: PolicyLayer.workspace),
        PolicyStatement.allowProvider('*', layer: PolicyLayer.global),
        PolicyStatement.allowProvider(
          'on-prem-*',
          layer: PolicyLayer.workspace,
        ),
      ]);
      // Workspace rules (sorted last) win: deny all but on-prem.
      expect(engine.allowsProvider('openai'), isFalse);
      expect(engine.allowsProvider('on-prem-llama'), isTrue);
    });

    test('glob resource matching for a class of providers', () {
      final engine = ProviderPolicyEngine.fromStatements(const [
        PolicyStatement.denyProvider('*-cn'),
      ]);
      expect(engine.allowsProvider('alibaba-cn'), isFalse);
      expect(engine.allowsProvider('anthropic'), isTrue);
    });

    test('round-trips a statement through JSON', () {
      const stmt = PolicyStatement.denyProvider(
        'openai',
        layer: PolicyLayer.workspace,
      );
      final back = PolicyStatement.fromJson(stmt.toJson());
      expect(back, stmt);
    });
  });
}
