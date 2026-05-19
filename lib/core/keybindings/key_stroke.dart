import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

/// A single key press: a trigger key plus its modifier flags.
///
/// [cmd] is the *primary* command modifier — it resolves to ⌘ (meta) on macOS
/// and Ctrl on Windows/Linux, mirroring VS Code's `Ctrl`/`Cmd` convention. Use
/// [ctrl] only when a binding must literally use the Control key on every
/// platform (rare).
@immutable
class KeyStroke {
  /// Creates a [KeyStroke].
  const KeyStroke(
    this.trigger, {
    this.cmd = false,
    this.ctrl = false,
    this.shift = false,
    this.alt = false,
  });

  /// The non-modifier key that triggers the stroke.
  final LogicalKeyboardKey trigger;

  /// Primary command modifier: ⌘ on macOS, Ctrl elsewhere.
  final bool cmd;

  /// Literal Control modifier (⌃ on macOS). Rarely needed — prefer [cmd].
  final bool ctrl;

  /// Shift modifier.
  final bool shift;

  /// Option / Alt modifier.
  final bool alt;

  /// The `hotkey_manager` modifiers for [platform], resolving [cmd] to meta on
  /// macOS and control elsewhere. Returned as a de-duplicated list.
  List<HotKeyModifier> modifiersFor(TargetPlatform platform) {
    final isMac = platform == TargetPlatform.macOS;
    final mods = <HotKeyModifier>{};
    if (cmd) {
      mods.add(isMac ? HotKeyModifier.meta : HotKeyModifier.control);
    }
    if (ctrl) {
      mods.add(HotKeyModifier.control);
    }
    if (shift) {
      mods.add(HotKeyModifier.shift);
    }
    if (alt) {
      mods.add(HotKeyModifier.alt);
    }
    return mods.toList(growable: false);
  }

  /// Builds the in-app [HotKey] registered with `hotkey_manager`. Its
  /// identifier is the platform-resolved [canonical] string so the same
  /// stroke always produces the same hotkey identity (idempotent register /
  /// unregister, no duplicates in the manager's list).
  HotKey toHotKey(TargetPlatform platform) => HotKey(
        identifier: canonical(platform),
        key: trigger,
        modifiers: modifiersFor(platform),
        scope: HotKeyScope.inapp,
      );

  /// A stable, platform-resolved identity for this stroke. Two strokes that
  /// resolve to the same physical combination on [platform] share a canonical
  /// (e.g. a `cmd` binding and a `ctrl` binding on Windows).
  String canonical(TargetPlatform platform) {
    final names = modifiersFor(platform).map((m) => m.name).toList()..sort();
    return '${names.join('+')}|${trigger.keyId}';
  }

  /// A platform-aware human label, e.g. `⌘⇧T` on macOS or `Ctrl+Shift+T`.
  String displayLabel(TargetPlatform platform) {
    final isMac = platform == TargetPlatform.macOS;
    final parts = <String>[];
    if (cmd) {
      parts.add(isMac ? '⌘' : 'Ctrl');
    }
    if (ctrl && !cmd) {
      parts.add(isMac ? '⌃' : 'Ctrl');
    }
    if (alt) {
      parts.add(isMac ? '⌥' : 'Alt');
    }
    if (shift) {
      parts.add(isMac ? '⇧' : 'Shift');
    }
    parts.add(triggerLabel(trigger));
    return parts.join(isMac ? '' : '+');
  }

  /// A short label for a trigger key (used by both [displayLabel] and the
  /// `Kbd` chip widget).
  static String triggerLabel(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.escape) {
      return 'Esc';
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      // U+23CE (⏎) rather than U+21B5 (↵): the latter is absent from Fira Code
      // and would trigger a Noto fallback in the mono kbd chip.
      return '⏎';
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      return '↑';
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      return '↓';
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      return '←';
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      return '→';
    }
    if (key == LogicalKeyboardKey.backspace) {
      return '⌫';
    }
    if (key == LogicalKeyboardKey.delete) {
      return 'Del';
    }
    if (key == LogicalKeyboardKey.tab) {
      return 'Tab';
    }
    if (key == LogicalKeyboardKey.space) {
      return 'Space';
    }
    return key.keyLabel;
  }

  @override
  bool operator ==(Object other) =>
      other is KeyStroke &&
      other.trigger == trigger &&
      other.cmd == cmd &&
      other.ctrl == ctrl &&
      other.shift == shift &&
      other.alt == alt;

  @override
  int get hashCode => Object.hash(trigger, cmd, ctrl, shift, alt);

  @override
  String toString() => displayLabel(defaultTargetPlatform);
}

/// An ordered sequence of [KeyStroke]s. A single-element chord is an ordinary
/// shortcut; a multi-element chord is a VS Code-style sequence such as
/// `⌘K ⌘C`. The dispatcher resolves chords with a pending-prefix state machine.
@immutable
class KeyChord {
  /// Creates a [KeyChord] from an ordered list of [strokes], which must be
  /// non-empty (a chord needs at least one stroke). Kept assert-free so it can
  /// be used in `const` binding definitions.
  const KeyChord(this.strokes);

  /// The strokes that make up the chord, pressed in order.
  final List<KeyStroke> strokes;

  /// The first stroke — the one registered as a hotkey.
  KeyStroke get first => strokes.first;

  /// Whether this is a multi-stroke chord.
  bool get isChord => strokes.length > 1;

  /// A platform-aware label joining each stroke with a space, e.g. `⌘K ⌘C`.
  String displayLabel(TargetPlatform platform) =>
      strokes.map((s) => s.displayLabel(platform)).join(' ');

  @override
  bool operator ==(Object other) =>
      other is KeyChord && listEquals(other.strokes, strokes);

  @override
  int get hashCode => Object.hashAll(strokes);
}
