import 'package:control_center/features/sandboxing/data/claude_relay/claude_trust_prompt.dart';
import 'package:flutter_test/flutter_test.dart';

/// ESC (0x1b) built at runtime so source stays pure ASCII.
final String _esc = String.fromCharCode(0x1b);

void main() {
  group('stripTerminalControls', () {
    test('removes CSI colour/style sequences', () {
      final input = '$_esc[1;32mgreen$_esc[0m text';
      expect(stripTerminalControls(input), 'green text');
    });

    test('normalises carriage returns to newlines', () {
      expect(stripTerminalControls('a\rb'), 'a\nb');
    });
  });

  group('isWorkspaceTrustPrompt', () {
    test('detects the trust prompt even with ANSI codes interleaved', () {
      final prompt = '$_esc[2J$_esc[1m Quick safety check $_esc[0m\r\n'
          '$_esc[32m> 1. Yes, I trust this folder$_esc[0m\r\n'
          '  2. No, exit\r\n';
      expect(isWorkspaceTrustPrompt(prompt), isTrue);
    });

    test('returns false for ordinary output', () {
      expect(isWorkspaceTrustPrompt('Working on your request...'), isFalse);
    });
  });

  group('shouldAutoConfirmWorkspaceTrust', () {
    test('true when --dangerously-skip-permissions is present', () {
      expect(
        shouldAutoConfirmWorkspaceTrust(
          ['--model', 'sonnet', '--dangerously-skip-permissions'],
        ),
        isTrue,
      );
    });

    test('false otherwise', () {
      expect(shouldAutoConfirmWorkspaceTrust(['--model', 'sonnet']), isFalse);
    });
  });

  group('WorkspaceTrustPromptDetector', () {
    test('fires exactly once across chunked output', () {
      var count = 0;
      WorkspaceTrustPromptDetector(() => count++)
        ..add('$_esc[1m Quick safety check $_esc[0m\r\n')
        ..add('1. Yes, I trust this folder\r\n')
        ..add('2. No, exit\r\n')
        ..add('2. No, exit again\r\n');
      expect(count, 1);
    });

    test('does not fire for unrelated output', () {
      var count = 0;
      WorkspaceTrustPromptDetector(() => count++)
          .add('just some normal terminal output\r\n');
      expect(count, 0);
    });
  });
}
