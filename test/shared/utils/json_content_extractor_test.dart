import 'package:control_center/shared/utils/json_content_extractor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JsonContentExtractor', () {
    late JsonContentExtractor extractor;

    setUp(() {
      extractor = const JsonContentExtractor();
    });

    group('extractContent', () {
      test('returns content when flat content is present', () {
        expect(
          extractor.extractContent(content: 'Here is the response'),
          'Here is the response',
        );
      });

      test('returns empty when flat content is empty and no metadata', () {
        expect(extractor.extractContent(content: ''), '');
      });

      test('extracts from metadata text field', () {
        expect(
          extractor.extractContent(
            content: '',
            metadata: {'text': 'Text from metadata'},
          ),
          'Text from metadata',
        );
      });

      test('extracts from metadata content field', () {
        expect(
          extractor.extractContent(
            content: '',
            metadata: {'content': 'Content from metadata'},
          ),
          'Content from metadata',
        );
      });

      test('extracts from metadata message field', () {
        expect(
          extractor.extractContent(
            content: '',
            metadata: {'message': 'Message from metadata'},
          ),
          'Message from metadata',
        );
      });

      test('extracts from metadata result field', () {
        expect(
          extractor.extractContent(
            content: '',
            metadata: {'result': 'Result from metadata'},
          ),
          'Result from metadata',
        );
      });

      test('falls back to top-level result key in metadata', () {
        expect(
          extractor.extractContent(
            content: '',
            metadata: {'result': 'Top-level result'},
          ),
          'Top-level result',
        );
      });

      test('returns empty for metadata with no known keys', () {
        expect(
          extractor.extractContent(
            content: '',
            metadata: {'unknown': 'no match'},
          ),
          '',
        );
      });

      test('prefers content over metadata', () {
        expect(
          extractor.extractContent(
            content: 'Direct content',
            metadata: {'text': 'Metadata text'},
          ),
          'Direct content',
        );
      });

      test('returns empty for empty content and empty metadata', () {
        expect(extractor.extractContent(content: '', metadata: {}), '');
      });

      test('extracts from nested metadata', () {
        expect(
          extractor.extractContent(
            content: '',
            metadata: {
              'data': {'text': 'Nested text'},
            },
          ),
          'Nested text',
        );
      });

      test('extracts from list inside metadata', () {
        expect(
          extractor.extractContent(
            content: '',
            metadata: {
              'items': [
                {'text': 'List text'},
              ],
            },
          ),
          'List text',
        );
      });

      test('extracts string directly from list', () {
        expect(
          extractor.extractContent(
            content: '',
            metadata: {
              'items': ['Direct string'],
            },
          ),
          'Direct string',
        );
      });
    });

    group('findTextInMap', () {
      test('returns first matching key in priority order', () {
        final map = {
          'message': 'Message',
          'text': 'Text',
          'content': 'Content',
        };
        expect(extractor.findTextInMap(map), 'Text');
      });

      test('returns empty for empty map', () {
        expect(extractor.findTextInMap({}), '');
      });

      test('returns empty for map with no matching keys', () {
        expect(extractor.findTextInMap({'foo': 'bar'}), '');
      });

      test('skips empty string values', () {
        final map = {'text': '', 'content': '', 'message': 'actual'};
        expect(extractor.findTextInMap(map), 'actual');
      });

      test('searches deeply nested maps', () {
        final map = {
          'outer': {
            'inner': {
              'deep': {'text': 'Deep value'},
            },
          },
        };
        expect(extractor.findTextInMap(map), 'Deep value');
      });

      test('returns empty for null values in map', () {
        final map = <String, dynamic>{'text': null, 'content': null};
        expect(extractor.findTextInMap(map), '');
      });
    });
  });
}
