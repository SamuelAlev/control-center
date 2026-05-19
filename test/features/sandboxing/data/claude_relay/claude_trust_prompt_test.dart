import 'package:cc_infra/src/sandboxing/claude_trust_prompt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('stripTerminalControls', () {
    test('returns plain text unchanged', () {
      const text = 'Hello, world!';
      expect(stripTerminalControls(text), text);
    });

    test('strips ANSI CSI sequences (colors)', () {
      const ansi = '\x1b[31mred text\x1b[0m';
      expect(stripTerminalControls(ansi), 'red text');
    });

    test('strips ANSI OSC sequences (hyperlink)', () {
      // Mock an OSC sequence: ESC ] 8 ; ; http://example.com BEL
      const osc =
          '\x1b]8;;http://example.com\x07click here\x1b]8;;\x07';
      expect(stripTerminalControls(osc), 'click here');
    });

    test('replaces carriage returns with newlines', () {
      expect(stripTerminalControls('line1\rline2\r'), 'line1\nline2\n');
    });

    test('handles empty input', () {
      expect(stripTerminalControls(''), '');
    });

    test('handles only carriage returns', () {
      expect(stripTerminalControls('\r\r\r'), '\n\n\n');
    });

    test('strips single-char escape sequences', () {
      // ESC @ is a single-char escape
      const text = '\x1b@hello';
      expect(stripTerminalControls(text), 'hello');
    });
  });

  group('isWorkspaceTrustPrompt', () {
    test('detects trust prompt text', () {
      const prompt = '''
        QuickSafetyCheck
        Do you trust this folder?
        Options:
        - yesITrustThisFolder
        - noExit
      ''';
      expect(isWorkspaceTrustPrompt(prompt), true);
    });

    test('detects trust prompt with ANSI codes embedded', () {
      const prompt = '\x1b[1mQuickSafetyCheck\x1b[0m\nYesITrustThisFolder\nNoExit';
      expect(isWorkspaceTrustPrompt(prompt), true);
    });

    test('detects trust prompt with mixed case and symbols', () {
      const prompt = 'Quick-Safety-Check!!! yes---itrustthisfolder no/exit';
      expect(isWorkspaceTrustPrompt(prompt), true);
    });

    test('returns false for unrelated text', () {
      expect(isWorkspaceTrustPrompt('Hello, this is a test'), false);
    });

    test('returns false for partial match (only quickSafetyCheck)', () {
      expect(isWorkspaceTrustPrompt('quicksafetycheck and nothing else'), false);
    });

    test('returns false for empty text', () {
      expect(isWorkspaceTrustPrompt(''), false);
    });

    test('detects when keywords are present across whitespace', () {
      const prompt = 'quicksafetycheck   yesitrustthisfolder   noexit';
      expect(isWorkspaceTrustPrompt(prompt), true);
    });
  });

  group('shouldAutoConfirmWorkspaceTrust', () {
    test('returns true when flag is present', () {
      expect(
        shouldAutoConfirmWorkspaceTrust(['--dangerously-skip-permissions']),
        true,
      );
    });

    test('returns true when flag is among other args', () {
      expect(
        shouldAutoConfirmWorkspaceTrust([
          '-p',
          '--dangerously-skip-permissions',
          '--model',
          'sonnet',
        ]),
        true,
      );
    });

    test('returns false when flag is absent', () {
      expect(
        shouldAutoConfirmWorkspaceTrust(['-p', '--model', 'sonnet']),
        false,
      );
    });

    test('returns false for empty args', () {
      expect(shouldAutoConfirmWorkspaceTrust([]), false);
    });

    test('does not match partial flag names', () {
      expect(
        shouldAutoConfirmWorkspaceTrust(['--dangerously-skip']),
        false,
      );
    });
  });

  group('WorkspaceTrustPromptDetector', () {
    test('calls onDetected when trust prompt is seen', () {
      var called = false;
      final detector = WorkspaceTrustPromptDetector(() => called = true);

      detector.add('quicksafetycheck yesitrustthisfolder noexit');
      expect(called, true);
    });

    test('does not call onDetected for unrelated text', () {
      var called = false;
      final detector = WorkspaceTrustPromptDetector(() => called = true);

      detector.add('regular output');
      expect(called, false);
    });

    test('builds buffer across multiple add() calls', () {
      var called = false;
      final detector = WorkspaceTrustPromptDetector(() => called = true);

      detector.add('quick');
      detector.add('safety');
      detector.add('check yesitrustthisfolder noexit');
      expect(called, true);
    });

    test('calls onDetected only once for repeated prompts', () {
      var callCount = 0;
      final detector = WorkspaceTrustPromptDetector(() => callCount++);

      detector.add('quicksafetycheck yesitrustthisfolder noexit');
      detector.add('quicksafetycheck yesitrustthisfolder noexit'); // second
      expect(callCount, 1);
    });

    test('truncates buffer at 16000 characters', () {
      var called = false;
      final detector = WorkspaceTrustPromptDetector(() => called = true);

      // Fill with junk
      detector.add('x' * 16000);
      expect(called, false);

      // Add the trust prompt
      detector.add('quicksafetycheck yesitrustthisfolder noexit');
      expect(called, true);
    });

    test('detects prompt even when buffer wraps', () {
      var called = false;
      final detector = WorkspaceTrustPromptDetector(() => called = true);

      // Overflow the buffer
      detector.add('y' * 15000);
      detector.add('quicksafetycheck yesitrustthisfolder noexit');
      expect(called, true);
    });

    test('onDetected called for partial accumulation then full', () {
      var called = false;
      final detector = WorkspaceTrustPromptDetector(() => called = true);

      detector.add('quick');
      expect(called, false);
      detector.add('safetycheck');
      expect(called, false);
      detector.add(' yesitrustthisfolder noexit');
      expect(called, true);
    });
  });
}
