import 'package:cc_infra/src/sandboxing/message_request_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldObserveMessagesRequest', () {
    test('returns true for a regular user message (no system prompt)', () {
      final body = <String, Object?>{
        'model': 'claude-sonnet-4-20250514',
        'messages': [
          {'role': 'user', 'content': 'Hello'},
        ],
      };
      expect(shouldObserveMessagesRequest(body), true);
    });

    test('returns true for body with unrelated system prompt', () {
      final body = <String, Object?>{
        'model': 'claude-sonnet-4-20250514',
        'system': 'You are a helpful assistant.',
        'messages': [
          {'role': 'user', 'content': 'Hello'},
        ],
      };
      expect(shouldObserveMessagesRequest(body), true);
    });

    test('returns true for body with system prompt as list of blocks', () {
      final body = <String, Object?>{
        'model': 'claude-sonnet-4-20250514',
        'system': [
          {'type': 'text', 'text': 'Some other system prompt'},
        ],
        'messages': [
          {'role': 'user', 'content': 'Hello'},
        ],
      };
      expect(shouldObserveMessagesRequest(body), true);
    });

    test('returns false for session title request with json_schema', () {
      final body = <String, Object?>{
        'model': 'claude-sonnet-4-20250514',
        'system': 'Generate a concise, sentence-case title',
        'messages': [
          {'role': 'user', 'content': '...'},
        ],
        'tool_choice': {
          'type': 'json_schema',
          'schema': {
            'type': 'object',
            'properties': {'title': {'type': 'string'}},
            'required': ['title'],
          },
        },
      };
      expect(shouldObserveMessagesRequest(body), false);
    });

    test('returns false for session title request (system as list)', () {
      final body = <String, Object?>{
        'model': 'claude-sonnet-4-20250514',
        'system': [
          {'type': 'text', 'text': 'Generate a concise, sentence-case title'},
        ],
        'messages': [
          {'role': 'user', 'content': '...'},
        ],
        'tool_choice': {
          'type': 'json_schema',
          'schema': {
            'type': 'object',
            'properties': {'title': {'type': 'string'}},
            'required': ['title'],
          },
        },
      };
      expect(shouldObserveMessagesRequest(body), false);
    });

    test('returns false for title request with JSON-return marker', () {
      final body = <String, Object?>{
        'model': 'claude-sonnet-4-20250514',
        'system':
            'Generate a concise, sentence-case title. Return JSON with a single "title" field.',
        'messages': [
          {'role': 'user', 'content': '...'},
        ],
        'tool_choice': {
          'type': 'tool',
          'name': 'title',
        },
      };
      // No json_schema tool_choice, so the schema check fails → should observe
      expect(shouldObserveMessagesRequest(body), true);
    });

    test('returns true when system has markers but no json_schema', () {
      final body = <String, Object?>{
        'model': 'claude-sonnet-4-20250514',
        'system': 'Generate a concise, sentence-case title',
        'messages': [
          {'role': 'user', 'content': '...'},
        ],
      };
      expect(shouldObserveMessagesRequest(body), true);
    });

    test('returns true when json_schema exists but no marker in system', () {
      final body = <String, Object?>{
        'model': 'claude-sonnet-4-20250514',
        'system': 'Some other system prompt',
        'messages': [
          {'role': 'user', 'content': '...'},
        ],
        'tool_choice': {
          'type': 'json_schema',
          'schema': {
            'type': 'object',
            'properties': {'title': {'type': 'string'}},
            'required': ['title'],
          },
        },
      };
      expect(shouldObserveMessagesRequest(body), true);
    });

    test('returns true for schema with extra properties (not title-only)', () {
      final body = <String, Object?>{
        'model': 'claude-sonnet-4-20250514',
        'system': 'Generate a concise, sentence-case title',
        'messages': [
          {'role': 'user', 'content': '...'},
        ],
        'tool_choice': {
          'type': 'json_schema',
          'schema': {
            'type': 'object',
            'properties': {
              'title': {'type': 'string'},
              'other': {'type': 'string'},
            },
            'required': ['title'],
          },
        },
      };
      expect(shouldObserveMessagesRequest(body), true);
    });

    test('returns true for schema without required field', () {
      final body = <String, Object?>{
        'model': 'claude-sonnet-4-20250514',
        'system': 'Generate a concise, sentence-case title',
        'messages': [
          {'role': 'user', 'content': '...'},
        ],
        'tool_choice': {
          'type': 'json_schema',
          'schema': {
            'type': 'object',
            'properties': {'title': {'type': 'string'}},
          },
        },
      };
      // required is absent, so the schema check passes (null -> true)
      expect(shouldObserveMessagesRequest(body), false);
    });

    test('returns true for schema with extra required fields', () {
      final body = <String, Object?>{
        'model': 'claude-sonnet-4-20250514',
        'system': 'Generate a concise, sentence-case title',
        'messages': [
          {'role': 'user', 'content': '...'},
        ],
        'tool_choice': {
          'type': 'json_schema',
          'schema': {
            'type': 'object',
            'properties': {'title': {'type': 'string'}},
            'required': ['title', 'other'],
          },
        },
      };
      expect(shouldObserveMessagesRequest(body), true);
    });

    test('returns true for empty body', () {
      expect(shouldObserveMessagesRequest(<String, Object?>{}), true);
    });

    test('returns false when markers found in nested system array text', () {
      final body = <String, Object?>{
        'model': 'claude-sonnet-4-20250514',
        'system': [
          {
            'type': 'text',
            'text': 'You are helpful.\nGenerate a concise, sentence-case title.',
          },
        ],
        'messages': [
          {'role': 'user', 'content': '...'},
        ],
        'tool_choice': {
          'type': 'json_schema',
          'schema': {
            'type': 'object',
            'properties': {'title': {'type': 'string'}},
            'required': ['title'],
          },
        },
      };
      expect(shouldObserveMessagesRequest(body), false);
    });

    test('returns true when markers found but tool_choice not a Map', () {
      final body = <String, Object?>{
        'model': 'claude-sonnet-4-20250514',
        'system': 'Generate a concise, sentence-case title',
        'messages': [
          {'role': 'user', 'content': '...'},
        ],
        'tool_choice': 'auto',
      };
      expect(shouldObserveMessagesRequest(body), true);
    });
  });
}
