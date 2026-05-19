import 'package:cc_domain/features/rigs/domain/value_objects/rig_action.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_clipboard.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_display.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';

/// The modifier names a computer-surface click accepts.
///
/// A CLOSED vocabulary, and the same one the QEMU keymap resolves — every
/// entry here maps to a real modifier qcode. Without the check, any
/// single-character key name (`"b"`) parsed as a modifier and was held down
/// through the click, which is a different chord than the one asked for and
/// reports success either way.
const Set<String> kComputerModifierNames = {
  'ctrl',
  'control',
  'shift',
  'alt',
  'option',
  'super',
  'meta',
  'cmd',
  'command',
};

/// Actions on the desktop (computer-use) surface.
///
/// The wire verbs match Anthropic's computer-use tool so a model's existing
/// familiarity transfers verbatim. Several verbs collapse into one class where
/// they differ only by argument (`left_click`/`right_click`/`double_click` are
/// one [ComputerClick] with a button and a count) — the wire vocabulary stays
/// wide, the code that has to be correct stays narrow.
sealed class ComputerAction extends RigAction {
  /// Const base constructor.
  const ComputerAction();

  @override
  RigSurface get surface => RigSurface.computer;

  /// Parses an untrusted `{action, ...}` payload.
  ///
  /// Total: every failure is a [RigActionInvalid] naming the field, never an
  /// exception. The message is what the model reads next.
  static RigActionParse parse(Map<String, dynamic> args) {
    final verb = rigOptString(args, 'action');
    if (verb == null) {
      return const RigActionInvalid(
        'Missing or invalid argument: action (expected one of '
        'screenshot, cursor_position, mouse_move, left_click, right_click, '
        'middle_click, double_click, triple_click, left_mouse_down, '
        'left_mouse_up, left_click_drag, scroll, key, hold_key, type, wait, '
        'set_display, clipboard_read, clipboard_write)',
      );
    }
    switch (verb) {
      case 'screenshot':
        return const RigActionParsed(ComputerScreenshot());
      case 'cursor_position':
        return const RigActionParsed(ComputerCursorPosition());
      case 'mouse_move':
        final point = rigOptPoint(args, 'coordinate');
        if (point == null) {
          return const RigActionInvalid(
            'Missing or invalid argument: coordinate (expected [x, y] in '
            'guest pixels)',
          );
        }
        return RigActionParsed(ComputerMouseMove(x: point.$1, y: point.$2));
      case 'left_click':
      case 'right_click':
      case 'middle_click':
      case 'double_click':
      case 'triple_click':
        final point = rigOptPoint(args, 'coordinate');
        final modifiers = rigStringList(args, 'text');
        for (final m in modifiers) {
          if (!kComputerModifierNames.contains(m.toLowerCase())) {
            // Validated HERE, like the browser surface does, rather than only
            // at the driver: `text: ["b"]` is a perfectly good single-character
            // key name, so it parsed and was held down through the click.
            return RigActionInvalid(
              'Invalid argument: text — unknown modifier "$m" (expected '
              '${kComputerModifierNames.join(", ")})',
            );
          }
        }
        return RigActionParsed(
          ComputerClick(
            button: switch (verb) {
              'right_click' => RigMouseButton.right,
              'middle_click' => RigMouseButton.middle,
              _ => RigMouseButton.left,
            },
            clicks: switch (verb) {
              'double_click' => 2,
              'triple_click' => 3,
              _ => 1,
            },
            x: point?.$1,
            y: point?.$2,
            modifiers: modifiers,
          ),
        );
      case 'left_mouse_down':
      case 'left_mouse_up':
        return RigActionParsed(
          ComputerButtonHold(
            button: RigMouseButton.left,
            pressed: verb == 'left_mouse_down',
          ),
        );
      case 'left_click_drag':
        final to = rigOptPoint(args, 'coordinate');
        if (to == null) {
          return const RigActionInvalid(
            'Missing or invalid argument: coordinate (expected the drag '
            'DESTINATION as [x, y])',
          );
        }
        final from = rigOptPoint(args, 'start_coordinate');
        return RigActionParsed(
          ComputerDrag(
            fromX: from?.$1,
            fromY: from?.$2,
            toX: to.$1,
            toY: to.$2,
          ),
        );
      case 'scroll':
        final direction = RigScrollDirection.fromWire(
          rigOptString(args, 'scroll_direction'),
        );
        if (direction == null) {
          return const RigActionInvalid(
            'Missing or invalid argument: scroll_direction (expected up, '
            'down, left or right)',
          );
        }
        final point = rigOptPoint(args, 'coordinate');
        return RigActionParsed(
          ComputerScroll(
            direction: direction,
            amount: rigOptInt(args, 'scroll_amount') ?? 3,
            x: point?.$1,
            y: point?.$2,
          ),
        );
      case 'key':
      case 'hold_key':
        final keys = rigOptString(args, 'text');
        if (keys == null) {
          return const RigActionInvalid(
            'Missing or invalid argument: text (expected a key combination '
            r'such as "ctrl+s" or "Return")',
          );
        }
        final holdSeconds = rigOptInt(args, 'duration');
        if (verb == 'hold_key' &&
            holdSeconds != null &&
            (holdSeconds < 0 || holdSeconds > 60)) {
          return const RigActionInvalid(
            'Invalid argument: duration (expected 0-60 seconds to hold the '
            'key)',
          );
        }
        return RigActionParsed(
          ComputerKey(
            combo: keys,
            hold: verb == 'hold_key'
                ? Duration(seconds: holdSeconds ?? 1)
                : null,
          ),
        );
      case 'type':
        final text = rigOptString(args, 'text');
        if (text == null) {
          return const RigActionInvalid(
            'Missing or invalid argument: text (expected the string to type)',
          );
        }
        return RigActionParsed(ComputerType(text));
      case 'wait':
        final seconds = rigOptInt(args, 'duration') ?? 1;
        if (seconds < 0 || seconds > 60) {
          return const RigActionInvalid(
            'Invalid argument: duration (expected 0-60 seconds — a longer '
            'wait means taking a screenshot again later, not blocking a turn)',
          );
        }
        return RigActionParsed(ComputerWait(Duration(seconds: seconds)));
      case 'set_display':
        final width = rigOptInt(args, 'width');
        final height = rigOptInt(args, 'height');
        if (width == null || height == null) {
          return const RigActionInvalid(
            'Missing or invalid arguments: width and height (expected guest '
            'pixels)',
          );
        }
        if (width < 320 || height < 240) {
          return const RigActionInvalid(
            'Invalid display size: minimum is 320x240',
          );
        }
        return RigActionParsed(
          ComputerSetDisplay(
            RigDisplaySize(width, height).clampedForNegotiation(),
          ),
        );
      case 'clipboard_read':
        return RigActionParsed(
          ComputerClipboardRead(
            selection: RigClipboardSelection.fromWire(
              rigOptString(args, 'selection'),
            ),
          ),
        );
      case 'clipboard_write':
        final text = rigOptString(args, 'text');
        if (text == null) {
          return const RigActionInvalid(
            'Missing or invalid argument: text (expected the string to put on '
            'the clipboard). Images and files are not writable through this '
            'verb — they travel on the rig file lane.',
          );
        }
        return RigActionParsed(ComputerClipboardWrite(text));
      default:
        return RigActionInvalid('Unknown computer action: "$verb"');
    }
  }
}

/// Capture the screen.
class ComputerScreenshot extends ComputerAction {
  /// Creates a [ComputerScreenshot].
  const ComputerScreenshot();

  @override
  String get verb => 'screenshot';

  @override
  bool get mutatesGuest => false;

  @override
  Map<String, dynamic> toJson() => {'action': verb};

  @override
  String get summary => 'Took a screenshot';
}

/// Report where the cursor is.
class ComputerCursorPosition extends ComputerAction {
  /// Creates a [ComputerCursorPosition].
  const ComputerCursorPosition();

  @override
  String get verb => 'cursor_position';

  @override
  bool get mutatesGuest => false;

  @override
  Map<String, dynamic> toJson() => {'action': verb};

  @override
  String get summary => 'Read the cursor position';
}

/// Move the pointer without clicking.
class ComputerMouseMove extends ComputerAction {
  /// Creates a [ComputerMouseMove].
  const ComputerMouseMove({required this.x, required this.y});

  /// Target x in guest pixels.
  final int x;

  /// Target y in guest pixels.
  final int y;

  @override
  String get verb => 'mouse_move';

  @override
  Map<String, dynamic> toJson() => {
    'action': verb,
    'coordinate': [x, y],
  };

  @override
  String get summary => 'Moved to ($x, $y)';
}

/// Click, optionally after moving, optionally with modifiers held.
class ComputerClick extends ComputerAction {
  /// Creates a [ComputerClick].
  const ComputerClick({
    required this.button,
    this.clicks = 1,
    this.x,
    this.y,
    this.modifiers = const [],
  });

  /// Which button.
  final RigMouseButton button;

  /// 1 = single, 2 = double, 3 = triple.
  final int clicks;

  /// Optional x to move to first (null = click where the pointer is).
  final int? x;

  /// Optional y to move to first.
  final int? y;

  /// Modifier keys held for the click (`ctrl`, `shift`, `alt`, `super`).
  final List<String> modifiers;

  @override
  String get verb => switch ((button, clicks)) {
    (RigMouseButton.right, _) => 'right_click',
    (RigMouseButton.middle, _) => 'middle_click',
    (_, 3) => 'triple_click',
    (_, 2) => 'double_click',
    _ => 'left_click',
  };

  @override
  Map<String, dynamic> toJson() => {
    'action': verb,
    if (x != null && y != null) 'coordinate': [x, y],
    if (modifiers.isNotEmpty) 'text': modifiers,
  };

  @override
  String get summary {
    final where = x != null && y != null ? ' ($x, $y)' : '';
    final mods = modifiers.isEmpty ? '' : ' with ${modifiers.join("+")}';
    return switch (clicks) {
      3 => 'Triple-clicked$where$mods',
      2 => 'Double-clicked$where$mods',
      _ =>
        '${button == RigMouseButton.left ? "Clicked" : "${button.name[0].toUpperCase()}${button.name.substring(1)}-clicked"}$where$mods',
    };
  }
}

/// Press or release a button without completing a click — the half of a
/// manual drag a single click verb cannot express.
class ComputerButtonHold extends ComputerAction {
  /// Creates a [ComputerButtonHold].
  const ComputerButtonHold({required this.button, required this.pressed});

  /// Which button.
  final RigMouseButton button;

  /// True to press, false to release.
  final bool pressed;

  @override
  String get verb => pressed ? 'left_mouse_down' : 'left_mouse_up';

  @override
  Map<String, dynamic> toJson() => {'action': verb};

  @override
  String get summary => pressed ? 'Pressed the mouse' : 'Released the mouse';
}

/// Press, move, release.
class ComputerDrag extends ComputerAction {
  /// Creates a [ComputerDrag]. A null origin drags from wherever the pointer
  /// already is.
  const ComputerDrag({
    this.fromX,
    this.fromY,
    required this.toX,
    required this.toY,
  });

  /// Optional origin x.
  final int? fromX;

  /// Optional origin y.
  final int? fromY;

  /// Destination x.
  final int toX;

  /// Destination y.
  final int toY;

  @override
  String get verb => 'left_click_drag';

  @override
  Map<String, dynamic> toJson() => {
    'action': verb,
    if (fromX != null && fromY != null) 'start_coordinate': [fromX, fromY],
    'coordinate': [toX, toY],
  };

  @override
  String get summary => fromX != null && fromY != null
      ? 'Dragged ($fromX, $fromY) to ($toX, $toY)'
      : 'Dragged to ($toX, $toY)';
}

/// Scroll a number of wheel clicks.
class ComputerScroll extends ComputerAction {
  /// Creates a [ComputerScroll].
  const ComputerScroll({
    required this.direction,
    this.amount = 3,
    this.x,
    this.y,
  });

  /// Which way.
  final RigScrollDirection direction;

  /// Wheel clicks.
  final int amount;

  /// Optional x to move to first.
  final int? x;

  /// Optional y to move to first.
  final int? y;

  @override
  String get verb => 'scroll';

  @override
  Map<String, dynamic> toJson() => {
    'action': verb,
    'scroll_direction': direction.wire,
    'scroll_amount': amount,
    if (x != null && y != null) 'coordinate': [x, y],
  };

  @override
  String get summary => 'Scrolled ${direction.name} $amount';
}

/// Press a key combination, optionally holding it.
class ComputerKey extends ComputerAction {
  /// Creates a [ComputerKey].
  const ComputerKey({required this.combo, this.hold});

  /// An X11-style combination, e.g. `ctrl+s`, `alt+Tab`, `Return`.
  final String combo;

  /// How long to hold it, or null for a tap.
  final Duration? hold;

  @override
  String get verb => hold == null ? 'key' : 'hold_key';

  @override
  Map<String, dynamic> toJson() => {
    'action': verb,
    'text': combo,
    if (hold != null) 'duration': hold!.inSeconds,
  };

  @override
  String get summary =>
      hold == null ? 'Pressed $combo' : 'Held $combo for ${hold!.inSeconds}s';
}

/// Type literal text.
class ComputerType extends ComputerAction {
  /// Creates a [ComputerType].
  const ComputerType(this.text);

  /// The literal text to type.
  final String text;

  @override
  String get verb => 'type';

  @override
  Map<String, dynamic> toJson() => {'action': verb, 'text': text};

  @override
  String get summary {
    final preview = text.length > 40 ? '${text.substring(0, 40)}…' : text;
    return 'Typed "${preview.replaceAll("\n", " ")}"';
  }
}

/// Wait for the guest to settle.
class ComputerWait extends ComputerAction {
  /// Creates a [ComputerWait].
  const ComputerWait(this.duration);

  /// How long to wait.
  final Duration duration;

  @override
  String get verb => 'wait';

  @override
  bool get mutatesGuest => false;

  @override
  Map<String, dynamic> toJson() => {
    'action': verb,
    'duration': duration.inSeconds,
  };

  @override
  String get summary => 'Waited ${duration.inSeconds}s';
}

/// Re-negotiate the guest's display mode.
///
/// Not an Anthropic verb — display size is tool configuration there. It exists
/// because a rig's display follows the VIEWER's panel, so the size is a
/// runtime property rather than a fixed one, and an agent that just resized a
/// window needs the guest to actually change modes.
class ComputerSetDisplay extends ComputerAction {
  /// Creates a [ComputerSetDisplay].
  const ComputerSetDisplay(this.size);

  /// The requested mode.
  final RigDisplaySize size;

  @override
  String get verb => 'set_display';

  @override
  Map<String, dynamic> toJson() => {
    'action': verb,
    'width': size.width,
    'height': size.height,
  };

  @override
  String get summary => 'Set the display to $size';
}

/// Read what is on one of the guest's X selections.
///
/// Observation, not mutation: reading a clipboard changes nothing, and an
/// agent that has been taken over still needs to be able to see what the
/// person just copied in order to narrate it.
///
/// Not an Anthropic computer-use verb. The alternative — `key ctrl+c` then
/// guess — reads whatever the focused application decided to copy, which is
/// not the same question and gives no way to tell "nothing was copied" from
/// "the app ignored the chord".
class ComputerClipboardRead extends ComputerAction {
  /// Creates a [ComputerClipboardRead].
  const ComputerClipboardRead({
    this.selection = RigClipboardSelection.clipboard,
  });

  /// Which selection to read. See [RigClipboardSelection] — `primary` is
  /// select-to-copy and `xdnd` is a drag in flight, neither of which is what
  /// `clipboard` holds.
  final RigClipboardSelection selection;

  @override
  String get verb => 'clipboard_read';

  @override
  bool get mutatesGuest => false;

  @override
  Map<String, dynamic> toJson() => {
    'action': verb,
    'selection': selection.wire,
  };

  @override
  String get summary => switch (selection) {
    RigClipboardSelection.clipboard => 'Read the clipboard',
    RigClipboardSelection.primary => 'Read the primary selection',
    RigClipboardSelection.xdnd => 'Read the drag payload',
  };
}

/// Put text on the guest's clipboard.
///
/// Text only, deliberately. Images and files are orders of magnitude larger
/// than anything else an action carries, and an action's arguments are
/// recorded in `rig_action_log` — so the byte-carrying flavours travel on the
/// rig file lane instead, where they are never written to the audit table.
class ComputerClipboardWrite extends ComputerAction {
  /// Creates a [ComputerClipboardWrite].
  const ComputerClipboardWrite(this.text);

  /// The text to place on the `CLIPBOARD` selection.
  final String text;

  @override
  String get verb => 'clipboard_write';

  @override
  Map<String, dynamic> toJson() => {'action': verb, 'text': text};

  @override
  String get summary => 'Put ${text.length} characters on the clipboard';
}
