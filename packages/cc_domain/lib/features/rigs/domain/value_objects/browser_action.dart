import 'package:cc_domain/features/rigs/domain/value_objects/rig_action.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_display.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';

/// What a browser extraction returns.
enum BrowserExtractKind {
  /// A pruned DOM: visible text and interactive elements with their selectors.
  /// Not the raw HTML — a real page's HTML is mostly framework noise and
  /// would spend the whole context window on `div`s.
  dom,

  /// The accessibility tree: roles, names and states. Usually the better
  /// choice, because it is what the page MEANS rather than how it is built.
  a11y,

  /// Buffered console messages since the last extraction.
  console;

  /// Stable wire string.
  String get wire => name;

  /// Parses [value], or null when unknown.
  static BrowserExtractKind? fromWire(String? value) {
    for (final k in BrowserExtractKind.values) {
      if (k.wire == value) {
        return k;
      }
    }
    return null;
  }
}

/// The modifier names a `key` action accepts. Wire-stable: they are what the
/// audit log records and what the CDP bitmask is computed from.
const Set<String> kBrowserModifierNames = {'ctrl', 'alt', 'meta', 'shift'};

/// Actions on the browser-use surface, driven over the Chrome DevTools
/// Protocol.
///
/// Selector-first by design: a CSS selector survives a re-render and a
/// scroll, a coordinate does not. Coordinates stay available for the cases
/// where nothing else works (canvas, a custom-drawn control), and the pointer
/// primitives (`mouse_move`, `left_mouse_down`, `left_mouse_up`, `drag`)
/// exist for what even coordinates cannot express in one verb — hover and
/// drag-to-select.
sealed class BrowserAction extends RigAction {
  /// Const base constructor.
  const BrowserAction();

  @override
  RigSurface get surface => RigSurface.browser;

  /// Parses an untrusted `{action, ...}` payload. Total — failures come back
  /// as [RigActionInvalid] naming the field.
  static RigActionParse parse(Map<String, dynamic> args) {
    final verb = rigOptString(args, 'action');
    if (verb == null) {
      return const RigActionInvalid(
        'Missing or invalid argument: action (expected one of navigate, '
        'reload, click, fill, type, key, scroll, mouse_move, drag, '
        'left_mouse_down, left_mouse_up, extract, screenshot, set_viewport, '
        'history, wait_for, clipboard_read, clipboard_write)',
      );
    }
    switch (verb) {
      case 'navigate':
        final url = rigOptString(args, 'url');
        if (url == null) {
          return const RigActionInvalid('Missing or invalid argument: url');
        }
        final parsed = Uri.tryParse(url);
        if (parsed == null || !parsed.hasScheme) {
          return RigActionInvalid(
            'Invalid argument: url must be absolute including the scheme '
            '(got "$url")',
          );
        }
        // A guest that can be told to open file:// or chrome:// can read the
        // guest's own disk and settings pages. Both are inside the enclosure,
        // but neither is what "browse the web" means, and an agent that lands
        // there is confused rather than malicious — refuse clearly.
        if (parsed.scheme != 'http' && parsed.scheme != 'https') {
          return RigActionInvalid(
            'Invalid argument: url scheme "${parsed.scheme}" is not allowed '
            '(only http and https)',
          );
        }
        return RigActionParsed(BrowserNavigate(parsed));
      case 'reload':
        return RigActionParsed(
          BrowserReload(hard: rigOptBool(args, 'hard') ?? false),
        );
      case 'stop_loading':
        return const RigActionParsed(BrowserStopLoading());
      case 'click':
        final selector = rigOptString(args, 'selector');
        final point = rigOptPoint(args, 'coordinate');
        if (selector == null && point == null) {
          return const RigActionInvalid(
            'Missing argument: click needs either selector or coordinate',
          );
        }
        final clicks = rigOptInt(args, 'click_count') ?? 1;
        if (clicks < 1 || clicks > 3) {
          return const RigActionInvalid(
            'Invalid argument: click_count (expected 1, 2 or 3)',
          );
        }
        return RigActionParsed(
          BrowserClick(
            selector: selector,
            x: point?.$1,
            y: point?.$2,
            button: RigMouseButton.fromWire(rigOptString(args, 'button')),
            clicks: clicks,
          ),
        );
      case 'fill':
        final selector = rigOptString(args, 'selector');
        final text = args['text'];
        if (selector == null) {
          return const RigActionInvalid(
            'Missing or invalid argument: selector',
          );
        }
        if (text is! String) {
          return const RigActionInvalid(
            'Missing or invalid argument: text (expected a string; use "" to '
            'clear the field)',
          );
        }
        return RigActionParsed(
          BrowserFill(
            selector: selector,
            text: text,
            submit: rigOptBool(args, 'submit') ?? false,
          ),
        );
      case 'type':
        final text = args['text'];
        if (text is! String) {
          return const RigActionInvalid(
            'Missing or invalid argument: text (expected a string; use fill '
            'with a selector to replace a field\'s value)',
          );
        }
        return RigActionParsed(BrowserType(text));
      case 'key':
        final key = rigOptString(args, 'key');
        if (key == null) {
          return const RigActionInvalid('Missing or invalid argument: key');
        }
        final modifiers = rigStringList(args, 'modifiers');
        for (final m in modifiers) {
          if (!kBrowserModifierNames.contains(m)) {
            return RigActionInvalid(
              'Invalid argument: modifiers — unknown modifier "$m" (expected '
              'ctrl, alt, meta or shift)',
            );
          }
        }
        return RigActionParsed(BrowserKey(key, modifiers: modifiers));
      case 'mouse_move':
        final movePoint = rigOptPoint(args, 'coordinate');
        if (movePoint == null) {
          return const RigActionInvalid(
            'Missing or invalid argument: coordinate (expected [x, y])',
          );
        }
        return RigActionParsed(
          BrowserMouseMove(x: movePoint.$1, y: movePoint.$2),
        );
      case 'drag':
        final to = rigOptPoint(args, 'coordinate');
        if (to == null) {
          return const RigActionInvalid(
            'Missing or invalid argument: coordinate (expected [x, y] — the '
            'drag destination)',
          );
        }
        final from = rigOptPoint(args, 'start_coordinate');
        return RigActionParsed(
          BrowserDrag(fromX: from?.$1, fromY: from?.$2, toX: to.$1, toY: to.$2),
        );
      case 'left_mouse_down':
      case 'left_mouse_up':
        final holdPoint = rigOptPoint(args, 'coordinate');
        return RigActionParsed(
          BrowserMouseButtonHold(
            pressed: verb == 'left_mouse_down',
            x: holdPoint?.$1,
            y: holdPoint?.$2,
          ),
        );
      case 'scroll':
        return RigActionParsed(
          BrowserScroll(
            dx: rigOptInt(args, 'dx') ?? 0,
            dy: rigOptInt(args, 'dy') ?? 400,
            selector: rigOptString(args, 'selector'),
          ),
        );
      case 'extract':
        final kind = BrowserExtractKind.fromWire(
          rigOptString(args, 'kind') ?? 'a11y',
        );
        if (kind == null) {
          return const RigActionInvalid(
            'Invalid argument: kind (expected dom, a11y or console)',
          );
        }
        return RigActionParsed(
          BrowserExtract(kind: kind, selector: rigOptString(args, 'selector')),
        );
      case 'screenshot':
        return RigActionParsed(
          BrowserScreenshot(fullPage: rigOptBool(args, 'full_page') ?? false),
        );
      case 'set_viewport':
        final width = rigOptInt(args, 'width');
        final height = rigOptInt(args, 'height');
        if (width == null || height == null) {
          return const RigActionInvalid(
            'Missing or invalid arguments: width and height',
          );
        }
        if (width < 320 || height < 240) {
          return const RigActionInvalid('Invalid viewport: minimum is 320x240');
        }
        final size = RigDisplaySize(width, height).clampedForNegotiation();
        // Clamped, not rejected: this arrives from a viewer reporting its own
        // display, and a 4x screen is a reason to render sharper, not an
        // error. Above 2 the extra pixels stop being visible, and the guest's
        // raster budget cuts it further — the server re-derives that rather
        // than trusting the client's arithmetic, because exceeding it is what
        // stops a 2-vCPU guest answering at all.
        final scale = size.deviceScaleWithin(
          (rigOptDouble(args, 'device_scale_factor') ?? 1).clamp(1.0, 2.0),
        );
        return RigActionParsed(
          BrowserSetViewport(
            size: size,
            mobile: rigOptBool(args, 'mobile') ?? false,
            deviceScaleFactor: scale,
          ),
        );
      case 'history':
        final delta = rigOptInt(args, 'delta') ?? -1;
        if (delta == 0) {
          return const RigActionInvalid(
            'Invalid argument: delta must be non-zero (negative = back)',
          );
        }
        return RigActionParsed(BrowserHistory(delta));
      case 'wait_for':
        final selector = rigOptString(args, 'selector');
        if (selector == null) {
          return const RigActionInvalid(
            'Missing or invalid argument: selector',
          );
        }
        final timeoutMs = rigOptInt(args, 'timeout_ms') ?? 5000;
        return RigActionParsed(
          BrowserWaitFor(
            selector: selector,
            timeout: Duration(milliseconds: timeoutMs.clamp(100, 30000)),
          ),
        );
      case 'clipboard_read':
        // No `selection` argument, unlike the computer surface: a browser has
        // exactly one clipboard. Accepting the argument and ignoring it would
        // report success for `selection: "primary"` while reading something
        // else.
        return const RigActionParsed(BrowserClipboardRead());
      case 'clipboard_write':
        final text = rigOptString(args, 'text');
        if (text == null) {
          return const RigActionInvalid(
            'Missing or invalid argument: text (expected the string to put on '
            'the clipboard). Images and files are not writable through this '
            'verb — they travel on the rig file lane.',
          );
        }
        return RigActionParsed(BrowserClipboardWrite(text));
      default:
        return RigActionInvalid('Unknown browser action: "$verb"');
    }
  }
}

/// Open a URL.
class BrowserNavigate extends BrowserAction {
  /// Creates a [BrowserNavigate].
  const BrowserNavigate(this.url);

  /// The absolute http/https URL.
  final Uri url;

  @override
  String get verb => 'navigate';

  @override
  Map<String, dynamic> toJson() => {'action': verb, 'url': url.toString()};

  @override
  String get summary => 'Navigated to ${url.host}${url.path}';
}

/// Click an element or a point.
class BrowserClick extends BrowserAction {
  /// Creates a [BrowserClick].
  const BrowserClick({
    this.selector,
    this.x,
    this.y,
    this.button = RigMouseButton.left,
    this.clicks = 1,
  });

  /// CSS selector, when targeting an element.
  final String? selector;

  /// Viewport x, when targeting a point.
  final int? x;

  /// Viewport y, when targeting a point.
  final int? y;

  /// Which button. Right is how a context menu is opened.
  final RigMouseButton button;

  /// 1 = single, 2 = double (select word), 3 = triple (select paragraph).
  final int clicks;

  @override
  String get verb => 'click';

  @override
  Map<String, dynamic> toJson() => {
    'action': verb,
    if (selector != null) 'selector': selector,
    if (x != null && y != null) 'coordinate': [x, y],
    if (button != RigMouseButton.left) 'button': button.wire,
    if (clicks != 1) 'click_count': clicks,
  };

  @override
  String get summary {
    final where = selector ?? '($x, $y)';
    final what = switch ((button, clicks)) {
      (RigMouseButton.right, _) => 'Right-clicked',
      (RigMouseButton.middle, _) => 'Middle-clicked',
      (_, 3) => 'Triple-clicked',
      (_, 2) => 'Double-clicked',
      _ => 'Clicked',
    };
    return '$what $where';
  }
}

/// Reload the current page.
class BrowserReload extends BrowserAction {
  /// Creates a [BrowserReload]. [hard] bypasses the cache.
  const BrowserReload({this.hard = false});

  /// Whether to ignore the page's cache.
  final bool hard;

  @override
  String get verb => 'reload';

  @override
  Map<String, dynamic> toJson() => {'action': verb, if (hard) 'hard': true};

  @override
  String get summary =>
      hard ? 'Reloaded the page without the cache' : 'Reloaded the page';
}

/// Abort the in-flight page load (the browser's stop button).
class BrowserStopLoading extends BrowserAction {
  /// Creates a [BrowserStopLoading].
  const BrowserStopLoading();

  @override
  String get verb => 'stop_loading';

  @override
  Map<String, dynamic> toJson() => {'action': verb};

  @override
  String get summary => 'Stopped loading the page';
}

/// Type into a field, optionally submitting.
class BrowserFill extends BrowserAction {
  /// Creates a [BrowserFill].
  const BrowserFill({
    required this.selector,
    required this.text,
    this.submit = false,
  });

  /// CSS selector for the input.
  final String selector;

  /// The value to set. Empty clears the field.
  final String text;

  /// Whether to press Enter afterwards.
  final bool submit;

  @override
  String get verb => 'fill';

  @override
  Map<String, dynamic> toJson() => {
    'action': verb,
    'selector': selector,
    'text': text,
    if (submit) 'submit': true,
  };

  @override
  String get summary {
    final preview = text.length > 30 ? '${text.substring(0, 30)}…' : text;
    return 'Filled $selector with "$preview"${submit ? " and submitted" : ""}';
  }
}

/// Type into whatever has focus.
///
/// Distinct from [BrowserFill]: fill addresses a field by selector and
/// REPLACES its value, type sends characters to the focused element — what a
/// person's keyboard does, and the only option when nothing focusable has a
/// stable selector.
class BrowserType extends BrowserAction {
  /// Creates a [BrowserType].
  const BrowserType(this.text);

  /// The characters to insert. Empty is a declared no-op.
  final String text;

  @override
  String get verb => 'type';

  @override
  Map<String, dynamic> toJson() => {'action': verb, 'text': text};

  @override
  String get summary {
    final preview = text.length > 30 ? '${text.substring(0, 30)}…' : text;
    return 'Typed "$preview"';
  }
}

/// Press a key in the page, optionally with modifiers held.
class BrowserKey extends BrowserAction {
  /// Creates a [BrowserKey].
  const BrowserKey(this.key, {this.modifiers = const []});

  /// A DOM key name, e.g. `Enter`, `Escape`, `Tab`.
  final String key;

  /// Held modifiers (`ctrl`, `alt`, `meta`, `shift`) — `shift`+`ArrowLeft`
  /// extends a selection, `ctrl`+`a` selects the field.
  final List<String> modifiers;

  @override
  String get verb => 'key';

  @override
  Map<String, dynamic> toJson() => {
    'action': verb,
    'key': key,
    if (modifiers.isNotEmpty) 'modifiers': modifiers,
  };

  @override
  String get summary =>
      'Pressed ${modifiers.isEmpty ? key : '${modifiers.join("+")}+$key'}';
}

/// Move the pointer without pressing anything — hover.
///
/// Hover is real page state: menus open, links highlight, tooltips arm. It is
/// also what a person watching the live view does constantly, so the audit
/// log samples it like the computer surface's move stream rather than keeping
/// a row per pixel.
class BrowserMouseMove extends BrowserAction {
  /// Creates a [BrowserMouseMove].
  const BrowserMouseMove({required this.x, required this.y});

  /// Target x in viewport pixels.
  final int x;

  /// Target y in viewport pixels.
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

/// Press or release the primary button without completing a click — the two
/// halves of a drag a single click verb cannot express.
class BrowserMouseButtonHold extends BrowserAction {
  /// Creates a [BrowserMouseButtonHold]. The coordinate is optional: null
  /// presses or releases where the pointer already is.
  const BrowserMouseButtonHold({required this.pressed, this.x, this.y});

  /// True to press, false to release.
  final bool pressed;

  /// Optional viewport x to move to first.
  final int? x;

  /// Optional viewport y to move to first.
  final int? y;

  @override
  String get verb => pressed ? 'left_mouse_down' : 'left_mouse_up';

  @override
  Map<String, dynamic> toJson() => {
    'action': verb,
    if (x != null && y != null) 'coordinate': [x, y],
  };

  @override
  String get summary => pressed ? 'Pressed the mouse' : 'Released the mouse';
}

/// Press, move, release — drag to select text or move a slider.
class BrowserDrag extends BrowserAction {
  /// Creates a [BrowserDrag]. A null origin drags from wherever the pointer
  /// already is.
  const BrowserDrag({
    this.fromX,
    this.fromY,
    required this.toX,
    required this.toY,
  });

  /// Optional origin x in viewport pixels.
  final int? fromX;

  /// Optional origin y in viewport pixels.
  final int? fromY;

  /// Destination x in viewport pixels.
  final int toX;

  /// Destination y in viewport pixels.
  final int toY;

  @override
  String get verb => 'drag';

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

/// Scroll the page or an element.
class BrowserScroll extends BrowserAction {
  /// Creates a [BrowserScroll].
  const BrowserScroll({this.dx = 0, this.dy = 400, this.selector});

  /// Horizontal delta in CSS pixels.
  final int dx;

  /// Vertical delta in CSS pixels (positive = down).
  final int dy;

  /// Optional scroll container.
  final String? selector;

  @override
  String get verb => 'scroll';

  @override
  Map<String, dynamic> toJson() => {
    'action': verb,
    'dx': dx,
    'dy': dy,
    if (selector != null) 'selector': selector,
  };

  @override
  String get summary => 'Scrolled ${dy >= 0 ? "down" : "up"} ${dy.abs()}px';
}

/// Read page state as text.
class BrowserExtract extends BrowserAction {
  /// Creates a [BrowserExtract].
  const BrowserExtract({required this.kind, this.selector});

  /// What to extract.
  final BrowserExtractKind kind;

  /// Optional subtree root.
  final String? selector;

  @override
  String get verb => 'extract';

  @override
  bool get mutatesGuest => false;

  @override
  Map<String, dynamic> toJson() => {
    'action': verb,
    'kind': kind.wire,
    if (selector != null) 'selector': selector,
  };

  @override
  String get summary => 'Extracted the ${kind.name} tree';
}

/// Capture the page.
class BrowserScreenshot extends BrowserAction {
  /// Creates a [BrowserScreenshot].
  const BrowserScreenshot({this.fullPage = false});

  /// Whether to capture past the fold.
  final bool fullPage;

  @override
  String get verb => 'screenshot';

  @override
  bool get mutatesGuest => false;

  @override
  Map<String, dynamic> toJson() => {
    'action': verb,
    if (fullPage) 'full_page': true,
  };

  @override
  String get summary =>
      fullPage ? 'Took a full-page screenshot' : 'Took a screenshot';
}

/// Change the emulated viewport.
class BrowserSetViewport extends BrowserAction {
  /// Creates a [BrowserSetViewport].
  const BrowserSetViewport({
    required this.size,
    this.mobile = false,
    this.deviceScaleFactor = 1,
  });

  /// The viewport size in CSS pixels.
  final RigDisplaySize size;

  /// Whether to emulate a touch/mobile device.
  final bool mobile;

  /// How many DEVICE pixels the guest renders per CSS pixel.
  ///
  /// [size] stays in CSS pixels on purpose. A Retina tab asked to lay out in
  /// guest-native pixels renders half-size text nobody can read, so the
  /// viewport keeps mapping 1:1 onto layout points and this raises the
  /// RESOLUTION underneath it — the same split a real Retina display makes.
  /// Without it the guest painted 1 device pixel per CSS pixel, the panel
  /// drew that across 2 physical pixels on any display above 1x, and every
  /// glyph on the watch lane was a 2x upscale of a 1x render.
  ///
  /// It is not a coordinate space: CDP and BiDi both take pointer coordinates
  /// in CSS pixels, so nothing downstream of a click has to know about this.
  final double deviceScaleFactor;

  @override
  String get verb => 'set_viewport';

  @override
  Map<String, dynamic> toJson() => {
    'action': verb,
    'width': size.width,
    'height': size.height,
    if (mobile) 'mobile': true,
    if (deviceScaleFactor != 1) 'device_scale_factor': deviceScaleFactor,
  };

  @override
  String get summary =>
      'Set the viewport to $size${mobile ? " (mobile)" : ""}'
      '${deviceScaleFactor == 1 ? "" : " at ${deviceScaleFactor}x"}';
}

/// Go back or forward.
class BrowserHistory extends BrowserAction {
  /// Creates a [BrowserHistory]. Negative goes back.
  const BrowserHistory(this.delta);

  /// Entries to move; negative is back.
  final int delta;

  @override
  String get verb => 'history';

  @override
  Map<String, dynamic> toJson() => {'action': verb, 'delta': delta};

  @override
  String get summary =>
      delta < 0 ? 'Went back ${delta.abs()}' : 'Went forward $delta';
}

/// Wait for an element to appear.
class BrowserWaitFor extends BrowserAction {
  /// Creates a [BrowserWaitFor].
  const BrowserWaitFor({required this.selector, required this.timeout});

  /// CSS selector to wait for.
  final String selector;

  /// How long to wait before giving up.
  final Duration timeout;

  @override
  String get verb => 'wait_for';

  @override
  bool get mutatesGuest => false;

  @override
  Map<String, dynamic> toJson() => {
    'action': verb,
    'selector': selector,
    'timeout_ms': timeout.inMilliseconds,
  };

  @override
  String get summary => 'Waited for $selector';
}

/// Read the browser's clipboard.
///
/// The browser surface is headless: there is no X server behind it and no
/// system clipboard to reach for. What this reads is Chromium's OWN
/// clipboard, which is what a page's `document.execCommand('copy')` and a
/// Ctrl+C keystroke write into and what a Ctrl+V pastes from — so it is
/// exactly the clipboard the page can observe, and nothing wider.
class BrowserClipboardRead extends BrowserAction {
  /// Creates a [BrowserClipboardRead].
  const BrowserClipboardRead();

  @override
  String get verb => 'clipboard_read';

  @override
  bool get mutatesGuest => false;

  @override
  Map<String, dynamic> toJson() => {'action': verb};

  @override
  String get summary => 'Read the clipboard';
}

/// Put text on the browser's clipboard, so a paste into the page finds it.
///
/// Text only, for the same reason the computer surface's write is: an
/// action's arguments land in `rig_action_log`, and image bytes do not belong
/// in an audit table.
class BrowserClipboardWrite extends BrowserAction {
  /// Creates a [BrowserClipboardWrite].
  const BrowserClipboardWrite(this.text);

  /// The text to place on the clipboard.
  final String text;

  @override
  String get verb => 'clipboard_write';

  @override
  Map<String, dynamic> toJson() => {'action': verb, 'text': text};

  @override
  String get summary => 'Put ${text.length} characters on the clipboard';
}
