import 'package:control_center/shared/widgets/transcript/util/read_output_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseReadOutput', () {
    test('strips arrow line-number prefixes and recovers start line', () {
      const raw = '  12→const x = 1;\n  13→const y = 2;';
      final p = parseReadOutput(raw);
      expect(p.startLine, 12);
      expect(p.content, 'const x = 1;\nconst y = 2;');
    });

    test('strips tab line-number prefixes', () {
      const raw = '1\tfirst\n2\tsecond';
      final p = parseReadOutput(raw);
      expect(p.startLine, 1);
      expect(p.content, 'first\nsecond');
    });

    test('passes through plain output unchanged', () {
      const raw = 'just some text\nwithout numbers';
      final p = parseReadOutput(raw);
      expect(p.startLine, 1);
      expect(p.content, raw);
    });

    test('strips <file> envelope', () {
      const raw = '<file path="a.dart">\n  1→line one\n</file>';
      final p = parseReadOutput(raw);
      expect(p.startLine, 1);
      expect(p.content, 'line one');
    });

    test('empty output', () {
      final p = parseReadOutput('');
      expect(p.content, '');
      expect(p.startLine, 1);
    });
  });
}
