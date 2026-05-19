import 'package:cc_infra/cc_infra.dart';
import 'package:test/test.dart';

/// The channel name a bridged conversation gets is the operator's only handle on
/// it in the sidebar, so it has to read like a request rather than a truncated
/// blob — hence a word-boundary cut and a fallback that is never empty.
void main() {
  group('titleFrom', () {
    test('names a channel after the request', () {
      expect(
        ChatText.titleFrom('Fix the flaky login test', fallback: 'Slack'),
        'Fix the flaky login test',
      );
    });

    test('uses the first non-empty line', () {
      expect(
        ChatText.titleFrom(
          '\n\n  Second line has it  \nthird',
          fallback: 'Slack',
        ),
        'Second line has it',
      );
    });

    test('truncates on a word boundary', () {
      final title = ChatText.titleFrom(
        'The authentication middleware rejects a refreshed token for one '
        'request after rotation',
        fallback: 'Slack',
        maxLength: 40,
      );
      expect(title.length, lessThanOrEqualTo(41));
      expect(title, endsWith('…'));
      expect(title, isNot(contains('  ')));
      // Cut between words, not mid-word.
      expect(title.substring(0, title.length - 1), isNot(endsWith(' ')));
    });

    test('falls back when there is nothing to name it after', () {
      expect(
        ChatText.titleFrom('   \n\n ', fallback: 'Slack conversation'),
        'Slack conversation',
      );
    });
  });
}
