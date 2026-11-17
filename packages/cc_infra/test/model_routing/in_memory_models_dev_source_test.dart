import 'dart:convert';

import 'package:cc_domain/features/model_routing/domain/ports/models_dev_source.dart'
    show ModelsDevSource;
import 'package:cc_infra/src/model_routing/in_memory_models_dev_source.dart';
import 'package:test/test.dart';

Map<String, dynamic> _doc() => {
  'anthropic': {
    'id': 'anthropic',
    'name': 'Anthropic',
    'models': {
      'claude-opus-4-5': {'id': 'claude-opus-4-5', 'name': 'Claude Opus 4.5'},
    },
  },
};

/// `InMemoryModelsDevSource` is a pure in-process [ModelsDevSource] — it serves
/// a caller-supplied fixture for both `load` and `refresh`. These pin its
/// no-IO contract; production reads go through the disk cache, not a bundled
/// snapshot.
void main() {
  group('InMemoryModelsDevSource', () {
    test('load returns the providers of the supplied document', () async {
      final source = InMemoryModelsDevSource(_doc());

      final result = await source.load();

      expect(result?.keys, ['anthropic']);
      expect(result?['anthropic']?.models.keys, ['claude-opus-4-5']);
    });

    test('refresh returns the same providers, forced or not', () async {
      final source = InMemoryModelsDevSource(_doc());

      expect((await source.refresh(force: true))?.keys, ['anthropic']);
      expect((await source.refresh())?.keys, ['anthropic']);
    });

    test('documentText is the supplied document as JSON', () async {
      final source = InMemoryModelsDevSource(_doc());

      expect(jsonDecode((await source.documentText())!), _doc());
    });
  });
}
