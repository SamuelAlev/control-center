import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/model_routing/model_routing.dart';
import 'package:cc_infra/src/model_routing/file_models_dev_source.dart';
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

  group('FileModelsDevSource (offline)', () {
    late Directory tmp;

    setUp(() => tmp = Directory.systemTemp.createTempSync('modelsdev'));
    tearDown(() => tmp.deleteSync(recursive: true));

    test(
      'falls back to the bundled snapshot with no cache + no network',
      () async {
        final source = FileModelsDevSource(
          cacheFilePath: '${tmp.path}/models.json',
          allowNetwork: false,
        );
        final json = await source.load();
        expect(json, isNotNull);
        expect(json!.keys, contains('anthropic'));
      },
    );

    test('reads a fresh disk cache when present', () async {
      final cacheFile = File('${tmp.path}/models.json');
      cacheFile.writeAsStringSync(
        jsonEncode({
          'acme': {
            'id': 'acme',
            'name': 'Acme',
            'models': {
              'm1': {'id': 'm1', 'name': 'Model One'},
            },
          },
        }),
      );
      final source = FileModelsDevSource(
        cacheFilePath: cacheFile.path,
        allowNetwork: false,
      );
      final json = await source.load();
      expect(json!.keys, ['acme']);
    });
  });

  group('ModelCatalogService', () {
    late Directory tmp;
    setUp(() => tmp = Directory.systemTemp.createTempSync('modelsdev'));
    tearDown(() => tmp.deleteSync(recursive: true));

    test('finalizes enablement + policy over the loaded catalog', () async {
      final service = ModelCatalogService(
        source: FileModelsDevSource(
          cacheFilePath: '${tmp.path}/models.json',
          allowNetwork: false,
        ),
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
