// Flutter key events → the names the rig action layer speaks.
//
// Two vocabularies, because the two drivable surfaces speak different ones:
// the desktop takes X11-style names through QMP's keymap, the browser takes
// CDP key names. Split out of the input surface so the tables are readable as
// tables rather than as a tail on a 700-line widget.
library;

import 'package:flutter/services.dart';

/// Keys that are only ever chord components, never a chord of their own.
final Set<LogicalKeyboardKey> kRigBareModifiers = {
  LogicalKeyboardKey.control,
  LogicalKeyboardKey.controlLeft,
  LogicalKeyboardKey.controlRight,
  LogicalKeyboardKey.shift,
  LogicalKeyboardKey.shiftLeft,
  LogicalKeyboardKey.shiftRight,
  LogicalKeyboardKey.alt,
  LogicalKeyboardKey.altLeft,
  LogicalKeyboardKey.altRight,
  LogicalKeyboardKey.meta,
  LogicalKeyboardKey.metaLeft,
  LogicalKeyboardKey.metaRight,
  LogicalKeyboardKey.capsLock,
  LogicalKeyboardKey.fn,
};

/// Characters some platforms attach to non-printing keys (Enter arrives as
/// `\r`, Backspace as `\b` on some engines) — these must resolve through the
/// named-key path, not be "typed".
const Set<String> kRigControlCharacters = {
  '\n',
  '\r',
  '\t',
  '\b',
  '\x7f',
  '\x1b',
};

/// The X11-style name the rig action layer accepts for [key], or null when
/// the key has no keyboard representation in the guest.
String? rigX11NameFor(LogicalKeyboardKey key) {
  final named = _x11Named[key];
  if (named != null) {
    return named;
  }
  // Letters/digits under a modifier: the logical key's label is the plain
  // character ('S' for the s key), which the combo layer lowercases into the
  // right qcode.
  final label = key.keyLabel;
  if (label.length == 1) {
    return label.toLowerCase();
  }
  return null;
}

final Map<LogicalKeyboardKey, String> _x11Named = {
  LogicalKeyboardKey.enter: 'Return',
  LogicalKeyboardKey.numpadEnter: 'KP_Enter',
  LogicalKeyboardKey.tab: 'Tab',
  LogicalKeyboardKey.escape: 'Escape',
  LogicalKeyboardKey.backspace: 'BackSpace',
  LogicalKeyboardKey.delete: 'Delete',
  LogicalKeyboardKey.insert: 'Insert',
  LogicalKeyboardKey.home: 'Home',
  LogicalKeyboardKey.end: 'End',
  LogicalKeyboardKey.pageUp: 'Page_Up',
  LogicalKeyboardKey.pageDown: 'Page_Down',
  LogicalKeyboardKey.arrowUp: 'Up',
  LogicalKeyboardKey.arrowDown: 'Down',
  LogicalKeyboardKey.arrowLeft: 'Left',
  LogicalKeyboardKey.arrowRight: 'Right',
  LogicalKeyboardKey.space: 'space',
  LogicalKeyboardKey.f1: 'F1',
  LogicalKeyboardKey.f2: 'F2',
  LogicalKeyboardKey.f3: 'F3',
  LogicalKeyboardKey.f4: 'F4',
  LogicalKeyboardKey.f5: 'F5',
  LogicalKeyboardKey.f6: 'F6',
  LogicalKeyboardKey.f7: 'F7',
  LogicalKeyboardKey.f8: 'F8',
  LogicalKeyboardKey.f9: 'F9',
  LogicalKeyboardKey.f10: 'F10',
  LogicalKeyboardKey.f11: 'F11',
  LogicalKeyboardKey.f12: 'F12',
};

/// The CDP key name for [key], or null when the browser surface has no
/// mapping for it.
String? rigCdpNameFor(LogicalKeyboardKey key) => _cdpNamed[key];

final Map<LogicalKeyboardKey, String> _cdpNamed = {
  LogicalKeyboardKey.enter: 'Enter',
  LogicalKeyboardKey.tab: 'Tab',
  LogicalKeyboardKey.escape: 'Escape',
  LogicalKeyboardKey.backspace: 'Backspace',
  LogicalKeyboardKey.delete: 'Delete',
  LogicalKeyboardKey.home: 'Home',
  LogicalKeyboardKey.end: 'End',
  LogicalKeyboardKey.pageUp: 'PageUp',
  LogicalKeyboardKey.pageDown: 'PageDown',
  // Chord-only (ctrl+space): a bare space arrives as a character and is
  // typed through the coalescer before this table is consulted.
  LogicalKeyboardKey.space: 'Space',
  LogicalKeyboardKey.arrowUp: 'ArrowUp',
  LogicalKeyboardKey.arrowDown: 'ArrowDown',
  LogicalKeyboardKey.arrowLeft: 'ArrowLeft',
  LogicalKeyboardKey.arrowRight: 'ArrowRight',
};
