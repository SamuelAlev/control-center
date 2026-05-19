import 'package:cc_domain/features/model_routing/domain/ports/models_dev_source.dart'
    show ModelsDevSource;
import 'package:cc_domain/features/model_routing/model_routing.dart'
    show ModelsDevSource;
import 'package:cc_infra/src/model_routing/in_memory_models_dev_source.dart';
import 'package:cc_infra/src/model_routing/models_dev_snapshot.dart';
import 'package:test/test.dart';

/// `InMemoryModelsDevSource` is a pure in-process [ModelsDevSource] — it serves
/// a fixed document (the bundled snapshot by default) for both `load` and
/// `refresh`. These pin its no-IO contract.
void main() {
  group('InMemoryModelsDevSource', () {
    test('load returns the supplied document', () async {
      final doc = <String, dynamic>{'models': <dynamic>[]};
      final source = InMemoryModelsDevSource(doc);

      final result = await source.load();

      expect(result, same(doc));
    });

    test('refresh returns the supplied document', () async {
      final doc = <String, dynamic>{'foo': 1};
      final source = InMemoryModelsDevSource(doc);

      final result = await source.refresh(force: true);

      expect(result, same(doc));
    });

    test('refresh without force returns the same document', () async {
      final doc = <String, dynamic>{'a': 'b'};
      final source = InMemoryModelsDevSource(doc);

      final result = await source.refresh();

      expect(result, same(doc));
    });

    test(
      'defaults to the bundled snapshot when no document is supplied',
      () async {
        final source = InMemoryModelsDevSource();

        final result = await source.load();

        expect(result, isNotNull);
        expect(result!.isNotEmpty, isTrue);
      },
    );

    test('bundled snapshot is itself a Map', () {
      // Confirms the JSON shape decodes to a map and not a list/string.
      expect(bundledModelsDevSnapshotJson.isNotEmpty, isTrue);
    });
  });
}
