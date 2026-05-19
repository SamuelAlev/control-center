import 'package:cc_infra/src/messaging/json_content_extractor.dart';
import 'package:test/test.dart';

/// Exercises [JsonContentExtractor] — the recursive best-effort text finder
/// used to surface a human-readable string from arbitrary tool-call metadata.
void main() {
  const extractor = JsonContentExtractor();

  group('extractContent', () {
    test('returns the content string verbatim when non-empty', () {
      expect(
        extractor.extractContent(content: 'hello', metadata: {'text': 'x'}),
        'hello',
      );
    });

    test('returns empty string when content is empty and metadata is null', () {
      expect(extractor.extractContent(content: ''), '');
    });

    test(
      'returns empty string when content is empty and metadata is empty',
      () {
        expect(
          extractor.extractContent(content: '', metadata: <String, dynamic>{}),
          '',
        );
      },
    );

    test('recovers text from a top-level well-known key', () {
      expect(
        extractor.extractContent(
          content: '',
          metadata: {'message': 'hi there'},
        ),
        'hi there',
      );
    });

    test('falls back to metadata["result"] when no nested text is found', () {
      expect(
        extractor.extractContent(
          content: '',
          metadata: {'result': 'computed-result'},
        ),
        'computed-result',
      );
    });

    test('ignores empty result string', () {
      expect(
        extractor.extractContent(content: '', metadata: {'result': ''}),
        '',
      );
    });

    test('ignores non-string result', () {
      expect(
        extractor.extractContent(content: '', metadata: {'result': 42}),
        '',
      );
    });
  });

  group('findTextInMap — recursion', () {
    test('walks into nested maps', () {
      expect(
        extractor.findTextInMap({
          'outer': {'text': 'deep'},
        }),
        'deep',
      );
    });

    test('walks into lists of maps', () {
      expect(
        extractor.findTextInMap({
          'items': [
            {'content': 'list-text'},
          ],
        }),
        'list-text',
      );
    });

    test('returns a non-empty string item from a list', () {
      expect(
        extractor.findTextInMap({
          'items': ['list-string'],
        }),
        'list-string',
      );
    });

    test('returns empty when only empty strings are present', () {
      expect(
        extractor.findTextInMap({
          'text': '',
          'content': '',
          'items': [''],
        }),
        '',
      );
    });

    test('checks well-known keys before traversing values', () {
      // 'text' is a well-known key and should win over a later 'message'
      // that appears deeper in iteration order.
      expect(
        extractor.findTextInMap({
          'text': 'first',
          'nested': {'message': 'second'},
        }),
        'first',
      );
    });

    test('well-known key priority: text > content > message > result', () {
      expect(
        extractor.findTextInMap({
          'result': 'r',
          'message': 'm',
          'content': 'c',
          'text': 't',
        }),
        't',
      );
    });

    test('returns empty for an empty map', () {
      expect(extractor.findTextInMap(<String, dynamic>{}), '');
    });

    test('skips non-string, non-map, non-list values', () {
      expect(extractor.findTextInMap({'a': 1, 'b': true, 'c': 3.14}), '');
    });

    test('skips Map that is not Map<String, dynamic>', () {
      // A plain Map (untyped) is not matched by `is Map<String, dynamic>`.
      expect(
        extractor.findTextInMap({
          'nested': <int, String>{1: 'x'},
        }),
        '',
      );
    });

    test('skips List items that are not String or Map<String, dynamic>', () {
      expect(
        extractor.findTextInMap({
          'items': <dynamic>[1, 2.0, true],
        }),
        '',
      );
    });
  });
}
