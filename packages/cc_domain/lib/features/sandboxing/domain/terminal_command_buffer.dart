import 'dart:convert';

/// Reconstructs the command line a PTY write submitted.
///
/// Interactive terminals send one keystroke per `terminal.write`. Typing
/// `ls` then Enter is three writes; only the last one *sends* a command,
/// and that write is usually just `\r`. This buffer follows the same
/// edits across writes (printable input, backspace, Ctrl+U, Ctrl+C) so
/// the audit trail can record the line that was actually submitted
/// rather than the bare carriage return.
class TerminalCommandBuffer {
  final StringBuffer _buf = StringBuffer();
  bool _justSubmitted = false;

  /// Feeds one stdin chunk. Returns the submitted line when this chunk
  /// contains a send (CR/LF), otherwise [TerminalWriteResult.none].
  ///
  /// A chunk that both edits and sends (`ls\r`, a paste) reports the
  /// line as it stood at the send. CRLF is one send, not two.
  TerminalWriteResult feed(List<int> data) {
    if (data.isEmpty) {
      return TerminalWriteResult.none;
    }
    final text = utf8.decode(data, allowMalformed: true);
    String? submitted;
    for (final rune in text.runes) {
      if (rune == 0x0d) {
        submitted = _buf.toString();
        _buf.clear();
        _justSubmitted = true;
        continue;
      }
      if (rune == 0x0a) {
        if (!_justSubmitted) {
          submitted = _buf.toString();
          _buf.clear();
        }
        _justSubmitted = false;
        continue;
      }
      _justSubmitted = false;
      if (rune == 0x08 || rune == 0x7f) {
        final current = _buf.toString();
        if (current.isNotEmpty) {
          _buf
            ..clear()
            ..write(current.substring(0, current.length - 1));
        }
        continue;
      }
      if (rune == 0x15 || rune == 0x03) {
        // Ctrl+U clears the line; Ctrl+C cancels it. Neither is a send.
        _buf.clear();
        continue;
      }
      if (rune == 0x17) {
        _deleteLastWord();
        continue;
      }
      if (rune >= 0x20) {
        _buf.writeCharCode(rune);
      }
    }
    if (submitted == null) {
      return TerminalWriteResult.none;
    }
    return TerminalWriteResult(sent: true, command: submitted);
  }

  void _deleteLastWord() {
    var current = _buf.toString();
    if (current.isEmpty) {
      return;
    }
    current = current.trimRight();
    final breakAt = current.lastIndexOf(RegExp(r'\s'));
    _buf
      ..clear()
      ..write(breakAt < 0 ? '' : current.substring(0, breakAt + 1));
  }
}

/// Outcome of a [TerminalCommandBuffer.feed] / `terminal.write`.
///
/// [sent] is true only when the chunk submitted a line (Enter). [command]
/// is the reconstructed line at that moment (empty when the user sent a
/// bare Enter at an empty prompt).
class TerminalWriteResult {
  /// Creates a [TerminalWriteResult].
  const TerminalWriteResult({this.sent = false, this.command});

  /// No command was submitted by this write.
  static const none = TerminalWriteResult();

  /// Whether this write submitted a command line.
  final bool sent;

  /// The submitted line, when [sent] is true.
  final String? command;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TerminalWriteResult &&
          sent == other.sent &&
          command == other.command;

  @override
  int get hashCode => Object.hash(sent, command);
}
