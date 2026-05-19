import 'package:cc_domain/core/domain/services/agent_mention_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgentMentionParser', () {
    const parser = AgentMentionParser();

    group('parseMentions', () {
      test('extracts @names', () {
        expect(parser.parseMentions('hello @alice world'), ['alice']);
      });

      test('returns lowercase', () {
        expect(parser.parseMentions('hello @Alice'), ['alice']);
      });

      test('handles multiple mentions', () {
        expect(
          parser.parseMentions('@alice hey @bob and @charlie'),
          ['alice', 'bob', 'charlie'],
        );
      });

      test('handles no mentions', () {
        expect(parser.parseMentions('hello world'), isEmpty);
      });

      test('handles adjacent mentions', () {
        expect(parser.parseMentions('@alice@bob'), ['alice', 'bob']);
      });
    });

    group('stripMentions', () {
      test('removes @names and trailing whitespace', () {
        expect(parser.stripMentions('hello @alice world'), 'hello world');
      });

      test('handles no mentions', () {
        expect(parser.stripMentions('hello world'), 'hello world');
      });

      test('trims result', () {
        expect(parser.stripMentions('@alice hello @bob '), 'hello');
      });
    });
  });
}
