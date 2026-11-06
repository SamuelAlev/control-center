import 'package:control_center/features/sandboxing/presentation/terminal_session_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a single line is typed as is, without its trailing newline', () {
    expect(terminalPrefillText('tool setup\n'), 'tool setup');
  });

  test('backslash continuations join with a space', () {
    expect(
      terminalPrefillText('tool setup \\\n  --all \\\r\n  --yes'),
      'tool setup  --all  --yes',
    );
  });

  test('any other multi-line text is not typed at all', () {
    expect(terminalPrefillText('a\nb'), isNull);
    expect(terminalPrefillText('a\rb'), isNull);
    expect(terminalPrefillText('if x; then\n  y\nfi'), isNull);
  });

  test('escape sequences are dropped', () {
    expect(terminalPrefillText('a\x1b[2Jb\x07'), 'a[2Jb');
  });
}
