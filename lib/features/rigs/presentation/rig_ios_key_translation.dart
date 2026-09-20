import 'package:flutter/services.dart';

/// iOS key name for a Flutter logical key, or null when WebDriverAgent has no
/// stable representation for it.
String? rigIosKeyNameFor(LogicalKeyboardKey key) => _iosKeyNames[key];

final Map<LogicalKeyboardKey, String> _iosKeyNames = {
  LogicalKeyboardKey.enter: 'enter',
  LogicalKeyboardKey.numpadEnter: 'enter',
  LogicalKeyboardKey.backspace: 'backspace',
  LogicalKeyboardKey.tab: 'tab',
  LogicalKeyboardKey.escape: 'escape',
  LogicalKeyboardKey.arrowUp: 'arrow_up',
  LogicalKeyboardKey.arrowDown: 'arrow_down',
  LogicalKeyboardKey.arrowLeft: 'arrow_left',
  LogicalKeyboardKey.arrowRight: 'arrow_right',
};

/// Maps a local point through a centered `BoxFit.contain` frame.
///
/// Returns null for letterbox bars or unknown/empty geometry. iOS uses screen
/// points, so the result is intentionally not multiplied by device pixel ratio.
(int, int)? rigContainedGuestPoint({
  required Offset local,
  required Size canvas,
  required int guestWidth,
  required int guestHeight,
}) {
  if (guestWidth <= 0 || guestHeight <= 0) {
    return null;
  }
  final widthScale = canvas.width / guestWidth;
  final heightScale = canvas.height / guestHeight;
  final scale = widthScale < heightScale ? widthScale : heightScale;
  if (scale <= 0 || !scale.isFinite) {
    return null;
  }
  final originX = (canvas.width - guestWidth * scale) / 2;
  final originY = (canvas.height - guestHeight * scale) / 2;
  final x = (local.dx - originX) / scale;
  final y = (local.dy - originY) / scale;
  if (x < 0 || y < 0 || x >= guestWidth || y >= guestHeight) {
    return null;
  }
  return (
    x.round().clamp(0, guestWidth - 1),
    y.round().clamp(0, guestHeight - 1),
  );
}

/// Translates one completed primary-pointer gesture into an iOS tap or swipe.
Map<String, dynamic> rigIosGestureAction({
  required (int, int) from,
  required (int, int) to,
  required Duration elapsed,
}) {
  final dx = to.$1 - from.$1;
  final dy = to.$2 - from.$2;
  if (dx * dx + dy * dy <= 64) {
    return {
      'action': 'tap',
      'coordinate': [to.$1, to.$2],
    };
  }
  return {
    'action': 'swipe',
    'from': [from.$1, from.$2],
    'to': [to.$1, to.$2],
    'duration_ms': elapsed.inMilliseconds.clamp(50, 5000),
  };
}

/// iOS guest-side clipboard chord after the boundary policy admits transfer.
Map<String, dynamic> rigIosClipboardKeyAction(String letter) => {
  'action': 'key',
  'key': letter,
  'modifiers': ['command'],
};

/// Builds the iOS `key` wire action for one non-text key press.
///
/// Unmodified printable text is intentionally excluded: callers coalesce it
/// into `type` actions so normal typing does not become one RPC per character.
Map<String, dynamic>? rigIosKeyAction({
  required LogicalKeyboardKey key,
  required String? character,
  required bool control,
  required bool alt,
  required bool meta,
  required bool shift,
}) {
  final named = rigIosKeyNameFor(key);
  final hasCommandModifier = control || alt || meta;
  if (named == null && !hasCommandModifier) {
    return null;
  }

  final candidate = named ?? character ?? key.keyLabel;
  if (candidate.runes.length != 1 && named == null) {
    return null;
  }

  final modifiers = <String>[
    if (meta) 'command',
    if (control) 'control',
    if (alt) 'option',
    if (shift) 'shift',
  ];
  return <String, dynamic>{
    'action': 'key',
    'key': candidate,
    if (modifiers.isNotEmpty) 'modifiers': modifiers,
  };
}
