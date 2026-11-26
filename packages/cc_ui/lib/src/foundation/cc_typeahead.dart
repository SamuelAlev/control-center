import 'dart:async';

import 'package:flutter/services.dart';

/// First-letter jumping for a list that runs on a highlight index (a menu, a
/// dropdown): typing "b" highlights the next row starting with "b", typing
/// "br" quickly highlights the first row starting with "br".
///
/// Only for lists whose keyboard owner is not a text field; in a searchable
/// panel the letters belong to the query.
class CcTypeahead {
  /// Creates a typeahead buffer that clears after [timeout] without a key.
  CcTypeahead({this.timeout = const Duration(milliseconds: 700)});

  /// Pause after which the next letter starts a new search.
  final Duration timeout;

  String _buffer = '';
  Timer? _timer;

  /// Whether letters were typed recently enough that a Space continues the
  /// search instead of activating the highlighted row.
  bool get isTyping => _buffer.isNotEmpty;

  /// The row to highlight for [event], or null when the key is not a
  /// printable character (the caller handles it as usual).
  ///
  /// [labelAt] gives the text a row is matched on, or null for a row the
  /// highlight may not land on (a divider, a heading, a disabled row). When
  /// nothing matches, [current] comes back unchanged.
  int? match(
    KeyEvent event, {
    required int count,
    required int current,
    required String? Function(int index) labelAt,
  }) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return null;
    }
    final character = event.character;
    if (character == null || character.isEmpty) {
      return null;
    }
    final code = character.codeUnitAt(0);
    if (code < 0x20 || code == 0x7f) {
      return null;
    }
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isControlPressed ||
        keyboard.isMetaPressed ||
        keyboard.isAltPressed) {
      return null;
    }
    if (character == ' ' && _buffer.isEmpty) {
      return null;
    }
    _buffer += character.toLowerCase();
    _timer?.cancel();
    _timer = Timer(timeout, () => _buffer = '');

    // A fresh letter moves past the current row so repeated presses cycle;
    // a longer prefix may stay on it.
    final start = _buffer.length == 1 ? current + 1 : current;
    final found = _find(_buffer, start, count, labelAt);
    if (found != null) {
      return found;
    }
    // "bbb" cycles through the rows starting with "b".
    final single = _buffer[0];
    if (_buffer.split('').every((c) => c == single)) {
      return _find(single, current + 1, count, labelAt) ?? current;
    }
    return current;
  }

  int? _find(
    String prefix,
    int start,
    int count,
    String? Function(int index) labelAt,
  ) {
    if (count <= 0) {
      return null;
    }
    for (var step = 0; step < count; step++) {
      final index = ((start < 0 ? 0 : start) + step) % count;
      final label = labelAt(index);
      if (label != null && label.toLowerCase().startsWith(prefix)) {
        return index;
      }
    }
    return null;
  }

  /// Forgets the typed letters (the list closed or was re-filtered).
  void reset() {
    _timer?.cancel();
    _timer = null;
    _buffer = '';
  }

  /// Cancels the reset timer.
  void dispose() => _timer?.cancel();
}
