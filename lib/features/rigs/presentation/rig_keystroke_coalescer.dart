// Batches printable characters into one `type` action.
library;

import 'dart:async';

/// Buffers consecutive printable characters so a typed word becomes ONE
/// `type` action instead of one action per key.
///
/// Two things made per-character typing wrong rather than merely wasteful.
/// Each character was a JSON-RPC round trip AND a row in `rig_action_log`, so
/// a sentence cost a hundred of each; and the log redacts typed text to
/// `{textLength, textSha256}`, which for a ONE-character string is a hash of
/// a 100-ish-element alphabet — trivially reversed, so the redaction was
/// protecting nothing. Batching fixes both: fewer round trips, and a digest
/// over a whole word is what the redaction assumed it was covering.
///
/// It flushes on the first of: [idle] elapsing with no new character, the
/// buffer reaching [capacity], or an explicit [flush] — which the surface
/// calls before EVERY other action, so a click can never be delivered ahead
/// of the text the user typed before it.
class KeystrokeCoalescer {
  /// Creates a coalescer that hands finished runs of text to [onFlush].
  KeystrokeCoalescer({
    required this.onFlush,
    this.idle = const Duration(milliseconds: 200),
    this.capacity = 64,
  });

  /// Receives each coalesced run, in input order.
  final void Function(String text) onFlush;

  /// How long a run may sit unsent while nothing else is typed. Short enough
  /// that a pause between words still lands promptly; long enough that a
  /// touch-typist's burst becomes one action.
  final Duration idle;

  /// The most characters one action carries. A long paste still arrives, in
  /// bounded pieces, rather than as one unbounded action.
  final int capacity;

  final StringBuffer _pending = StringBuffer();
  Timer? _idleTimer;

  /// Whether anything is waiting to be sent.
  bool get hasPending => _pending.isNotEmpty;

  /// The characters buffered so far (diagnostics and tests).
  String get pending => _pending.toString();

  /// Buffers one printable character.
  void add(String character) {
    if (character.isEmpty) {
      return;
    }
    _pending.write(character);
    if (_pending.length >= capacity) {
      // Flushed on a character boundary — whole characters go in, so a
      // surrogate pair can never be split across two actions.
      flush();
      return;
    }
    _idleTimer?.cancel();
    _idleTimer = Timer(idle, flush);
  }

  /// Sends whatever is buffered, immediately. A no-op when nothing is.
  void flush() {
    _idleTimer?.cancel();
    _idleTimer = null;
    if (_pending.isEmpty) {
      return;
    }
    final text = _pending.toString();
    _pending.clear();
    onFlush(text);
  }

  /// Flushes and stops. Typed characters must not die with the widget: the
  /// user pressed those keys and expects the machine to have them.
  void dispose() {
    flush();
    _idleTimer?.cancel();
    _idleTimer = null;
  }
}
