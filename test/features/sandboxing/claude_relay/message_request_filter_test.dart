import 'package:control_center/features/sandboxing/data/claude_relay/message_request_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldObserveMessagesRequest', () {
    test('skips Claude session-title generation requests', () {
      final body = <String, Object?>{
        'system': 'Generate a concise, sentence-case title for this session.',
        'response_format': {
          'type': 'json_schema',
          'schema': {
            'type': 'object',
            'properties': {
              'title': {'type': 'string'},
            },
            'required': ['title'],
          },
        },
      };
      expect(shouldObserveMessagesRequest(body), isFalse);
    });

    test('observes a normal agent request', () {
      final body = <String, Object?>{
        'system': 'You are a helpful coding agent.',
        'messages': [
          {'role': 'user', 'content': 'fix the bug'},
        ],
      };
      expect(shouldObserveMessagesRequest(body), isTrue);
    });

    test('observes when the title marker is present but schema is broader', () {
      final body = <String, Object?>{
        'system': 'Generate a concise, sentence-case title',
        'response_format': {
          'type': 'json_schema',
          'schema': {
            'type': 'object',
            'properties': {
              'title': {'type': 'string'},
              'summary': {'type': 'string'},
            },
          },
        },
      };
      expect(shouldObserveMessagesRequest(body), isTrue);
    });

    test('finds the title marker nested in a system block array', () {
      final body = <String, Object?>{
        'system': [
          {'type': 'text', 'text': 'Return JSON with a single "title" field'},
        ],
        'tools': [
          {
            'type': 'json_schema',
            'schema': {
              'properties': {
                'title': {'type': 'string'},
              },
              'required': ['title'],
            },
          },
        ],
      };
      expect(shouldObserveMessagesRequest(body), isFalse);
    });
  });
}
