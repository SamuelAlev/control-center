/// Detection of Claude Code's "trust this folder" prompt shown when launching
/// in an untrusted workspace.
///
/// Dart port of the upstream relay's `claude-prompts.ts`. The relay runs Claude in a hidden
/// PTY, so it must auto-confirm this prompt (when running with
/// `--dangerously-skip-permissions`) or fail loudly.
library;

/// Matches ANSI/VT control sequences: an ESC (0x1b) followed by a CSI, OSC,
/// DCS/PM/APC/SOS, or single-char escape. The ESC (0x1b) and BEL (0x07) bytes
/// are built with [String.fromCharCode] so no literal control bytes appear in
/// source. Faithful port of the upstream relay's ANSI_PATTERN.
final RegExp _ansiPattern = _buildAnsiPattern();

RegExp _buildAnsiPattern() {
  final esc = String.fromCharCode(0x1b);
  final bel = String.fromCharCode(0x07);
  final pattern = '$esc(?:'
      r'\[[0-?]*[ -/]*[@-~]' // CSI
      '|'
      '\\][^$bel]*(?:$bel|$esc\\\\)' // OSC, terminated by BEL or ESC backslash
      '|'
      '[PX^_].*?$esc\\\\' // DCS / PM / APC / SOS
      '|'
      '[@-_]' // single-char escape
      ')';
  return RegExp(pattern);
}

/// Strips ANSI/VT control sequences and normalises carriage returns to
/// newlines.
String stripTerminalControls(String text) {
  return text.replaceAll(_ansiPattern, '').replaceAll('\r', '\n');
}

/// Returns whether [text] (raw PTY output) contains Claude's workspace-trust
/// prompt.
bool isWorkspaceTrustPrompt(String text) {
  final compact = stripTerminalControls(text)
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]'), '');
  return compact.contains('quicksafetycheck') &&
      compact.contains('yesitrustthisfolder') &&
      compact.contains('noexit');
}

/// Returns whether the trust prompt should be auto-confirmed, i.e. Claude was
/// launched with `--dangerously-skip-permissions`.
bool shouldAutoConfirmWorkspaceTrust(List<String> claudeArgs) {
  return claudeArgs.contains('--dangerously-skip-permissions');
}

/// A stateful detector that buffers PTY output across chunks and invokes
/// [onDetected] once, the first time the trust prompt is seen.
class WorkspaceTrustPromptDetector {
  /// Creates a [WorkspaceTrustPromptDetector].
  WorkspaceTrustPromptDetector(this.onDetected);

  /// Called once when the trust prompt is first detected.
  final void Function() onDetected;

  String _buffer = '';
  bool _detected = false;

  /// Feeds a chunk of raw PTY output into the detector.
  void add(String data) {
    if (_detected) {
      return;
    }
    _buffer += data;
    if (_buffer.length > 16000) {
      _buffer = _buffer.substring(_buffer.length - 16000);
    }
    if (isWorkspaceTrustPrompt(_buffer)) {
      _detected = true;
      onDetected();
    }
  }
}
