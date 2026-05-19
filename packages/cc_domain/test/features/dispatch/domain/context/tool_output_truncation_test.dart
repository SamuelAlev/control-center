import 'package:cc_domain/features/dispatch/domain/context/tool_output_truncation.dart';
import 'package:test/test.dart';

void main() {
  group('truncateToolOutput — characters', () {
    test('passes through when under the character limit', () {
      const limits = ToolOutputLimits(characterLimit: 100, lineLimit: 0);
      final out = truncateToolOutput('a' * 50, limits);
      expect(out.truncated, isFalse);
      expect(out.content, 'a' * 50);
    });

    test('head+tail split keeps 20% head and 80% tail with a marker', () {
      const limits = ToolOutputLimits(characterLimit: 100, lineLimit: 0);
      final input = '${'H' * 500}${'T' * 500}';
      final out = truncateToolOutput(input, limits);
      expect(out.truncated, isTrue);
      expect(out.omittedChars, input.length - 100);
      expect(out.content, contains('characters omitted'));
      // 20 head chars then marker then 80 tail chars.
      expect(out.content.startsWith('H' * 20), isTrue);
      expect(out.content.endsWith('T' * 80), isTrue);
    });

    test('head direction keeps only the head', () {
      const limits = ToolOutputLimits(
        characterLimit: 10,
        lineLimit: 0,
        direction: TruncateDirection.head,
      );
      final out = truncateToolOutput('0123456789ABCDEF', limits);
      expect(out.truncated, isTrue);
      expect(out.content.startsWith('0123456789'), isTrue);
      expect(out.content, contains('characters omitted'));
    });

    test('tail direction keeps only the tail', () {
      const limits = ToolOutputLimits(
        characterLimit: 10,
        lineLimit: 0,
        direction: TruncateDirection.tail,
      );
      final out = truncateToolOutput('0123456789ABCDEF', limits);
      expect(out.truncated, isTrue);
      expect(out.content.endsWith('6789ABCDEF'), isTrue);
    });
  });

  group('truncateToolOutput — lines', () {
    test('passes through when under the line limit', () {
      const limits = ToolOutputLimits(characterLimit: 0, lineLimit: 10);
      final out = truncateToolOutput(
        List.generate(5, (i) => 'line $i').join('\n'),
        limits,
      );
      expect(out.truncated, isFalse);
    });

    test('drops the middle lines and reports the omitted count', () {
      const limits = ToolOutputLimits(characterLimit: 0, lineLimit: 10);
      final input = List.generate(100, (i) => 'line $i').join('\n');
      final out = truncateToolOutput(input, limits);
      expect(out.truncated, isTrue);
      expect(out.omittedLines, 90);
      expect(out.content, contains('lines omitted'));
      expect(out.content, contains('line 0'));
      expect(out.content, contains('line 99'));
      expect(out.content, isNot(contains('line 50')));
    });
  });

  group('ToolOutputLimitTable', () {
    test('resolves built-in per-tool limits and strips mcp prefix', () {
      const table = ToolOutputLimitTable.defaults;
      expect(table.forTool('grep').direction, TruncateDirection.head);
      expect(table.forTool('mcp__cc__grep').direction, TruncateDirection.head);
      expect(table.forTool('Read').direction, TruncateDirection.head);
    });

    test('falls back to the standard limits for unknown tools', () {
      const table = ToolOutputLimitTable.defaults;
      expect(table.forTool('something_else').characterLimit,
          ToolOutputLimits.standard.characterLimit);
    });
  });
}
