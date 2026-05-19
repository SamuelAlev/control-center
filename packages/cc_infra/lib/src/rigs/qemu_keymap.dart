/// Translation from the X11-style key names models write to QEMU's `qcode`
/// vocabulary.
///
/// Models emit combinations in the xdotool/X11 spelling that Anthropic's
/// computer-use tool documents (`ctrl+s`, `alt+Tab`, `Return`, `super`), which
/// is what the action layer accepts. QEMU's `send-key` takes its own `QKeyCode`
/// names (`ctrl`, `alt`, `ret`, `meta_l`). Nothing translates between them for
/// free, and a silently-dropped modifier turns "save" into typing an "s".
library;

/// The QEMU `qcode` for one X11-style key name, or null when unknown.
///
/// Case-insensitive for named keys (`Return`, `return`, `RETURN`), but
/// case-SENSITIVE for single characters: `A` is `shift`+`a` and losing that
/// distinction types the wrong thing.
List<String>? qemuKeysFor(String name) {
  if (name.isEmpty) {
    return null;
  }
  // A single character is taken literally. Trimming it first turned the SPACE
  // key into an empty name, so `_charCodes[' ']` was unreachable and no string
  // containing a space could be typed into a rig at all.
  final trimmed = name.length == 1 ? name : name.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  // A single printable character.
  if (trimmed.length == 1) {
    final ch = trimmed;
    // Shifted symbols first: '!' is shift+1 on the guest's US layout, and
    // without this row none of them could be typed at all — `_typeText`
    // reported "no keyboard representation" for half of shell syntax.
    final shifted = _shiftedCharCodes[ch];
    if (shifted != null) {
      return ['shift', shifted];
    }
    final lower = ch.toLowerCase();
    final needsShift = ch != lower && ch.toUpperCase() == ch;
    final code = _charCodes[lower];
    if (code == null) {
      return null;
    }
    return needsShift ? ['shift', code] : [code];
  }
  final lowerName = trimmed.toLowerCase();
  // A named key whose glyph is the SHIFTED one on a US layout: the qcode is
  // the unshifted key, so sending it alone types the wrong character. `plus`
  // produced `=`, `colon` produced `;` — quietly, and only visible as the
  // wrong text appearing in the guest.
  final shiftedName = _shiftedNamedCodes[lowerName];
  if (shiftedName != null) {
    return ['shift', shiftedName];
  }
  final code = _namedCodes[lowerName];
  return code == null ? null : [code];
}

/// Named keys whose glyph requires shift on a US layout, mapped to the
/// UNSHIFTED qcode they sit on.
const Map<String, String> _shiftedNamedCodes = {
  'plus': 'equal',
  'colon': 'semicolon',
  'less': 'comma',
  'greater': 'dot',
  'question': 'slash',
  'underscore': 'minus',
  'quotedbl': 'apostrophe',
  'bar': 'backslash',
  'braceleft': 'bracket_left',
  'braceright': 'bracket_right',
  'asciitilde': 'grave_accent',
};

/// Translates a whole combination such as `ctrl+shift+t` into QEMU qcodes.
///
/// Returns null when any component is unknown — a partially-translated
/// combination is worse than a refusal, because it would send a real but
/// different chord to the guest.
List<String>? qemuComboFor(String combo) {
  final parts = combo.split('+').where((p) => p.trim().isNotEmpty).toList();
  if (parts.isEmpty) {
    return null;
  }
  final out = <String>[];
  for (final part in parts) {
    final keys = qemuKeysFor(part);
    if (keys == null) {
      return null;
    }
    for (final k in keys) {
      if (!out.contains(k)) {
        out.add(k);
      }
    }
  }
  return out;
}

/// A whole string translated into one QEMU key chord per character.
///
/// All-or-nothing by construction: when [unsupported] is non-empty, [chords]
/// is empty. Typing the representable prefix and then reporting failure is
/// worse than typing nothing — the model reads the failure, retries, and the
/// characters that DID land are typed twice.
class QemuTypePlan {
  const QemuTypePlan._(this.chords, this.unsupported);

  /// The chords to send, in order. Empty when [unsupported] is not.
  final List<List<String>> chords;

  /// Characters with no keyboard representation on the guest layout, in the
  /// order they first appear and without duplicates.
  final List<String> unsupported;

  /// Whether the whole string can be typed.
  bool get isTypeable => unsupported.isEmpty;
}

/// Plans [text] as one QEMU key chord per character.
///
/// There is no "send this string" primitive at the hypervisor layer — an
/// emulated keyboard only has keys — so typing is inherently a chord per
/// character, and anything without a key (an emoji, a CJK glyph) is reported
/// rather than skipped.
QemuTypePlan planQemuTyping(String text) {
  // CRLF is one newline to a guest; sending both would press Return twice.
  final normalized = text.replaceAll('\r\n', '\n');
  final chords = <List<String>>[];
  final unsupported = <String>[];
  for (final rune in normalized.runes) {
    final ch = String.fromCharCode(rune);
    final keys = switch (ch) {
      '\n' || '\r' => const ['ret'],
      '\t' => const ['tab'],
      _ => qemuKeysFor(ch),
    };
    if (keys == null) {
      if (!unsupported.contains(ch)) {
        unsupported.add(ch);
      }
      continue;
    }
    chords.add(keys);
  }
  return unsupported.isEmpty
      ? QemuTypePlan._(chords, const [])
      : QemuTypePlan._(const [], unsupported);
}

/// The subset of QEMU qcodes reachable from a single character.
const Map<String, String> _charCodes = {
  'a': 'a',
  'b': 'b',
  'c': 'c',
  'd': 'd',
  'e': 'e',
  'f': 'f',
  'g': 'g',
  'h': 'h',
  'i': 'i',
  'j': 'j',
  'k': 'k',
  'l': 'l',
  'm': 'm',
  'n': 'n',
  'o': 'o',
  'p': 'p',
  'q': 'q',
  'r': 'r',
  's': 's',
  't': 't',
  'u': 'u',
  'v': 'v',
  'w': 'w',
  'x': 'x',
  'y': 'y',
  'z': 'z',
  '0': '0',
  '1': '1',
  '2': '2',
  '3': '3',
  '4': '4',
  '5': '5',
  '6': '6',
  '7': '7',
  '8': '8',
  '9': '9',
  ' ': 'spc',
  '-': 'minus',
  '=': 'equal',
  '[': 'bracket_left',
  ']': 'bracket_right',
  '\\': 'backslash',
  ';': 'semicolon',
  "'": 'apostrophe',
  '`': 'grave_accent',
  ',': 'comma',
  '.': 'dot',
  '/': 'slash',
};

/// Shifted symbols on the US layout the guest images boot with.
const Map<String, String> _shiftedCharCodes = {
  '!': '1',
  '@': '2',
  '#': '3',
  r'$': '4',
  '%': '5',
  '^': '6',
  '&': '7',
  '*': '8',
  '(': '9',
  ')': '0',
  '_': 'minus',
  '+': 'equal',
  '{': 'bracket_left',
  '}': 'bracket_right',
  '|': 'backslash',
  ':': 'semicolon',
  '"': 'apostrophe',
  '~': 'grave_accent',
  '<': 'comma',
  '>': 'dot',
  '?': 'slash',
};

/// Named keys and modifiers, in the X11/xdotool spellings models actually
/// produce plus the obvious synonyms.
const Map<String, String> _namedCodes = {
  // Modifiers.
  'ctrl': 'ctrl',
  'control': 'ctrl',
  'ctrl_l': 'ctrl',
  'ctrl_r': 'ctrl_r',
  'shift': 'shift',
  'shift_l': 'shift',
  'shift_r': 'shift_r',
  'alt': 'alt',
  'option': 'alt',
  'alt_l': 'alt',
  'alt_r': 'alt_r',
  'super': 'meta_l',
  'super_l': 'meta_l',
  'super_r': 'meta_r',
  'meta': 'meta_l',
  'cmd': 'meta_l',
  'command': 'meta_l',
  'win': 'meta_l',
  // Editing / navigation.
  'return': 'ret',
  'enter': 'ret',
  'kp_enter': 'kp_enter',
  'tab': 'tab',
  'escape': 'esc',
  'esc': 'esc',
  'space': 'spc',
  'backspace': 'backspace',
  'bksp': 'backspace',
  'delete': 'delete',
  'del': 'delete',
  'insert': 'insert',
  'home': 'home',
  'end': 'end',
  'page_up': 'pgup',
  'pageup': 'pgup',
  'prior': 'pgup',
  'page_down': 'pgdn',
  'pagedown': 'pgdn',
  'next': 'pgdn',
  'up': 'up',
  'down': 'down',
  'left': 'left',
  'right': 'right',
  'menu': 'menu',
  'print': 'print',
  'scroll_lock': 'scroll_lock',
  'pause': 'pause',
  'caps_lock': 'caps_lock',
  'num_lock': 'num_lock',
  // Function keys.
  'f1': 'f1', 'f2': 'f2', 'f3': 'f3', 'f4': 'f4', 'f5': 'f5', 'f6': 'f6',
  'f7': 'f7', 'f8': 'f8', 'f9': 'f9', 'f10': 'f10', 'f11': 'f11',
  'f12': 'f12',
  // Punctuation by name (xdotool spellings).
  'minus': 'minus',
  'equal': 'equal',
  'bracketleft': 'bracket_left',
  'bracketright': 'bracket_right',
  'backslash': 'backslash',
  'semicolon': 'semicolon',
  'apostrophe': 'apostrophe',
  'quoteright': 'apostrophe',
  'grave': 'grave_accent',
  'comma': 'comma',
  'period': 'dot',
  'slash': 'slash',
};
