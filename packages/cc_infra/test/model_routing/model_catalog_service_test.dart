import 'dart:convert';

import 'package:cc_domain/features/model_routing/model_routing.dart';
import 'package:cc_infra/src/model_routing/in_memory_models_dev_source.dart';
import 'package:cc_infra/src/model_routing/model_catalog_service.dart';
import 'package:cc_infra/src/model_routing/models_dev_snapshot.dart';
import 'package:test/test.dart';

void main() {
  test('bundled snapshot parses into a non-trivial catalog', () {
    final json =
        jsonDecode(bundledModelsDevSnapshotJson) as Map<String, dynamic>;
    final catalog = ModelCatalog.fromModelsDev(json);
    expect(catalog.providerCount, greaterThanOrEqualTo(8));
    expect(catalog.modelCount, greaterThanOrEqualTo(100));
    // Anthropic + a known model are present with cost + context.
    final opus = catalog.modelGet('anthropic', 'claude-opus-4-5');
    expect(opus, isNotNull);
    expect(opus!.cost!.input, greaterThan(0));
    expect(opus.limits.context, greaterThan(0));
  });

  test('kimi-code/k3 inherits image and video from kimi-for-coding', () {
    final json =
        jsonDecode(bundledModelsDevSnapshotJson) as Map<String, dynamic>;
    final catalog = ModelCatalog.fromModelsDev(json);
    // Harness id is `kimi-code`; models.dev publishes the same plan as
    // `kimi-for-coding`. Without the alias the editor stays text-only.
    expect(catalog.modelGet('kimi-code', 'k3'), isNull);
    final k3 = catalog.resolve('kimi-code/k3');
    expect(k3, isNotNull);
    expect(k3!.id, 'k3');
    expect(k3.inputModalities, [
      ModelModality.text,
      ModelModality.image,
      ModelModality.video,
    ]);
    expect(k3.limits.context, 1048576);
    expect(k3.limits.maxOutput, 131072);
  });


  group('ModelCatalogService', () {
    test('finalizes enablement + policy over the loaded catalog', () async {
      final service = ModelCatalogService(
        source: InMemoryModelsDevSource(),
        presentEnvKeys: () => {'ANTHROPIC_API_KEY'},
      );

      // Anthropic enabled via env; OpenAI disabled (no key).
      final catalog = await service.catalog();
      expect(catalog.providerGet('anthropic')!.isEnabled, isTrue);
      expect(catalog.providerGet('openai')!.isEnabled, isFalse);

      // Policy denies anthropic → removed entirely.
      final denied = await service.catalog(
        policy: ProviderPolicyEngine.fromStatements(const [
          PolicyStatement.denyProvider('anthropic'),
        ]),
      );
      expect(denied.providerGet('anthropic'), isNull);
    });
  });
}
