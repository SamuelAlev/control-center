import 'package:cc_domain/features/rigs/domain/value_objects/rig_action.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';

/// Keyboard modifiers accepted by the iOS automation surface.
enum IosKeyModifier {
  /// Command / Meta.
  command,

  /// Control.
  control,

  /// Option / Alt.
  option,

  /// Shift.
  shift;

  /// Stable wire value.
  String get wire => name;

  /// Parses [value], or null when it is not a supported modifier.
  static IosKeyModifier? fromWire(String? value) {
    for (final modifier in values) {
      if (modifier.wire == value) {
        return modifier;
      }
    }
    return null;
  }
}

/// Actions on an ephemeral iOS Simulator, driven through WebDriverAgent.
sealed class IosAction extends RigAction {
  /// Const base constructor.
  const IosAction();

  @override
  RigSurface get surface => RigSurface.ios;

  /// Parses an untrusted `{action, ...}` payload. Total: failures come back as
  /// [RigActionInvalid] naming the malformed field.
  static RigActionParse parse(Map<String, dynamic> args) {
    final verb = rigOptString(args, 'action');
    if (verb == null) {
      return const RigActionInvalid(
        'Missing or invalid argument: action (expected one of tap, swipe, '
        'type, key, home, lock, unlock, rotate, screenshot, ui_dump, '
        'install_app, start_app, stop_app, uninstall_app, open_url, spawn)',
      );
    }
    switch (verb) {
      case 'tap':
        final point = rigOptPoint(args, 'coordinate');
        if (point == null) {
          return const RigActionInvalid(
            'Missing or invalid argument: coordinate (expected [x, y] in '
            'simulator screen points)',
          );
        }
        return RigActionParsed(IosTap(x: point.$1, y: point.$2));
      case 'swipe':
        final from = rigOptPoint(args, 'from');
        final to = rigOptPoint(args, 'to');
        if (from == null || to == null) {
          return const RigActionInvalid(
            'Missing or invalid arguments: from and to (each expected as '
            '[x, y] in simulator screen points)',
          );
        }
        final milliseconds = rigOptInt(args, 'duration_ms') ?? 300;
        return RigActionParsed(
          IosSwipe(
            fromX: from.$1,
            fromY: from.$2,
            toX: to.$1,
            toY: to.$2,
            duration: Duration(milliseconds: milliseconds.clamp(50, 5000)),
          ),
        );
      case 'type':
        final text = rigOptString(args, 'text');
        if (text == null) {
          return const RigActionInvalid('Missing or invalid argument: text');
        }
        return RigActionParsed(IosType(text));
      case 'key':
        final key = rigOptString(args, 'key');
        if (key == null) {
          return const RigActionInvalid(
            'Missing or invalid argument: key (expected enter, backspace, '
            'tab, escape, arrow_up, arrow_down, arrow_left, arrow_right, or '
            'one printable character)',
          );
        }
        if (!IosKey.isSupportedKey(key)) {
          return RigActionInvalid(
            'Invalid argument: unsupported iOS key "$key"',
          );
        }
        final rawModifiers = args['modifiers'];
        if (rawModifiers != null && rawModifiers is! List) {
          return const RigActionInvalid(
            'Missing or invalid argument: modifiers (expected a list of '
            'command, control, option, or shift)',
          );
        }
        final modifiers = <IosKeyModifier>{};
        for (final value in rawModifiers as List? ?? const <Object?>[]) {
          final modifier = value is String
              ? IosKeyModifier.fromWire(value)
              : null;
          if (modifier == null) {
            return RigActionInvalid(
              'Invalid argument: unsupported iOS key modifier "$value" '
              '(expected command, control, option, or shift)',
            );
          }
          modifiers.add(modifier);
        }
        return RigActionParsed(IosKey(key: key, modifiers: modifiers));
      case 'home':
        return const RigActionParsed(IosHome());
      case 'lock':
        return const RigActionParsed(IosLock());
      case 'unlock':
        return const RigActionParsed(IosUnlock());
      case 'rotate':
        final parsed = _parseRotate(args);
        if (parsed == null) {
          return const RigActionInvalid(
            'Missing or invalid argument: direction (expected clockwise or '
            'counterclockwise)',
          );
        }
        return RigActionParsed(IosRotate(parsed));
      case 'screenshot':
        return RigActionParsed(
          IosScreenshot(
            fullResolution: rigOptBool(args, 'full_resolution') ?? false,
          ),
        );
      case 'ui_dump':
        return const RigActionParsed(IosUiDump());
      case 'install_app':
        final path = rigOptString(args, 'path');
        if (path == null) {
          return const RigActionInvalid(
            'Missing or invalid argument: path (a confined host path to the '
            '.app directory)',
          );
        }
        if (!path.toLowerCase().endsWith('.app')) {
          return const RigActionInvalid(
            'Invalid argument: path must name a .app directory',
          );
        }
        return RigActionParsed(IosInstallApp(path));
      case 'start_app':
      case 'stop_app':
      case 'uninstall_app':
        final bundleId = rigOptString(args, 'bundle_id');
        if (bundleId == null || !_bundleIdPattern.hasMatch(bundleId)) {
          return const RigActionInvalid(
            'Missing or invalid argument: bundle_id '
            '(expected a valid reverse-DNS bundle id)',
          );
        }
        if (verb == 'start_app') {
          return RigActionParsed(IosStartApp(bundleId));
        }
        if (verb == 'stop_app') {
          return RigActionParsed(IosStopApp(bundleId));
        }
        return RigActionParsed(IosUninstallApp(bundleId));
      case 'open_url':
        final url = _parseUrl(args);
        if (url == null) {
          return const RigActionInvalid(
            'Missing or invalid argument: url '
            '(expected an absolute URL or app deep link)',
          );
        }
        return RigActionParsed(IosOpenUrl(url));
      case 'spawn':
        final argv = _parseArgv(args);
        if (argv == null) {
          return const RigActionInvalid(
            'Missing or invalid argument: argv (expected 1–64 non-empty '
            'strings without NUL bytes)',
          );
        }
        return RigActionParsed(IosSpawn(argv));
      default:
        return RigActionInvalid('Unknown iOS action: "$verb"');
    }
  }

  static final RegExp _bundleIdPattern = RegExp(
    r'^[A-Za-z][A-Za-z0-9_-]*(\.[A-Za-z][A-Za-z0-9_-]*)+$',
  );

  static RigRotateDirection? _parseRotate(Map<String, dynamic> args) {
    final raw = rigOptString(args, 'direction');
    if (raw == null) {
      return RigRotateDirection.clockwise;
    }
    return RigRotateDirection.fromWire(raw);
  }

  static String? _parseUrl(Map<String, dynamic> args) {
    final value = rigOptString(args, 'url');
    if (value == null || value.length > 8192 || value.contains('\u0000')) {
      return null;
    }
    final parsed = Uri.tryParse(value);
    return parsed != null && parsed.scheme.isNotEmpty ? value : null;
  }

  static List<String>? _parseArgv(Map<String, dynamic> args) {
    final raw = args['argv'];
    if (raw is! List || raw.isEmpty || raw.length > 64) {
      return null;
    }
    final argv = <String>[];
    var size = 0;
    for (final value in raw) {
      if (value is! String ||
          value.isEmpty ||
          value.contains('\u0000') ||
          value.length > 4096) {
        return null;
      }
      size += value.length;
      if (size > 32768) {
        return null;
      }
      argv.add(value);
    }
    return argv;
  }
}

/// Tap one simulator screen point.
class IosTap extends IosAction {
  /// Creates an [IosTap].
  const IosTap({required this.x, required this.y});

  /// Logical x coordinate in simulator points.
  final int x;

  /// Logical y coordinate in simulator points.
  final int y;

  @override
  String get verb => 'tap';

  @override
  Map<String, dynamic> toJson() => {
    'action': verb,
    'coordinate': [x, y],
  };

  @override
  String get summary => 'Tapped ($x, $y)';
}

/// Swipe between two simulator screen points.
class IosSwipe extends IosAction {
  /// Creates an [IosSwipe].
  const IosSwipe({
    required this.fromX,
    required this.fromY,
    required this.toX,
    required this.toY,
    required this.duration,
  });

  /// Origin x coordinate in simulator points.
  final int fromX;

  /// Origin y coordinate in simulator points.
  final int fromY;

  /// Destination x coordinate in simulator points.
  final int toX;

  /// Destination y coordinate in simulator points.
  final int toY;

  /// Gesture duration.
  final Duration duration;

  @override
  String get verb => 'swipe';

  @override
  Map<String, dynamic> toJson() => {
    'action': verb,
    'from': [fromX, fromY],
    'to': [toX, toY],
    'duration_ms': duration.inMilliseconds,
  };

  @override
  String get summary => 'Swiped ($fromX, $fromY) to ($toX, $toY)';
}

/// Type literal text into the focused element.
class IosType extends IosAction {
  /// Creates an [IosType].
  const IosType(this.text);

  /// Literal text.
  final String text;

  @override
  String get verb => 'type';

  @override
  Map<String, dynamic> toJson() => {'action': verb, 'text': text};

  @override
  String get summary {
    final preview = text.length > 40 ? '${text.substring(0, 40)}…' : text;
    return 'Typed "$preview"';
  }
}

/// Press a named or printable key, optionally with modifiers.
class IosKey extends IosAction {
  /// Creates an [IosKey]. Callers crossing a trust boundary use [IosAction.parse].
  IosKey({required this.key, Set<IosKeyModifier> modifiers = const {}})
    : modifiers = Set.unmodifiable(modifiers);

  /// Named key or one printable Unicode scalar.
  final String key;

  /// Closed modifier set.
  final Set<IosKeyModifier> modifiers;

  /// Named keys WebDriverAgent handles consistently.
  static const Set<String> namedKeys = {
    'enter',
    'backspace',
    'tab',
    'escape',
    'arrow_up',
    'arrow_down',
    'arrow_left',
    'arrow_right',
  };

  /// Whether [value] is one supported named key or one printable scalar.
  static bool isSupportedKey(String value) {
    if (namedKeys.contains(value)) {
      return true;
    }
    final runes = value.runes.toList(growable: false);
    return runes.length == 1 && runes.single >= 0x20 && runes.single != 0x7f;
  }

  @override
  String get verb => 'key';

  @override
  Map<String, dynamic> toJson() => {
    'action': verb,
    'key': key,
    if (modifiers.isNotEmpty)
      'modifiers': [
        for (final modifier in IosKeyModifier.values)
          if (modifiers.contains(modifier)) modifier.wire,
      ],
  };

  @override
  String get summary {
    final prefix = modifiers.isEmpty
        ? ''
        : '${[for (final modifier in IosKeyModifier.values)
            if (modifiers.contains(modifier)) modifier.wire].join('+')}+';
    return 'Pressed $prefix$key';
  }
}

/// Return to the simulator home screen.
class IosHome extends IosAction {
  /// Creates an [IosHome].
  const IosHome();

  @override
  String get verb => 'home';

  @override
  Map<String, dynamic> toJson() => {'action': verb};

  @override
  String get summary => 'Opened the Home screen';
}

/// Lock the simulator.
class IosLock extends IosAction {
  /// Creates an [IosLock].
  const IosLock();

  @override
  String get verb => 'lock';

  @override
  Map<String, dynamic> toJson() => {'action': verb};

  @override
  String get summary => 'Locked the simulator';
}

/// Unlock the simulator.
class IosUnlock extends IosAction {
  /// Creates an [IosUnlock].
  const IosUnlock();

  @override
  String get verb => 'unlock';

  @override
  Map<String, dynamic> toJson() => {'action': verb};

  @override
  String get summary => 'Unlocked the simulator';
}

/// Rotate the simulator 90 degrees.
class IosRotate extends IosAction {
  /// Creates an [IosRotate].
  const IosRotate([this.direction = RigRotateDirection.clockwise]);

  /// Which way to turn the simulator.
  final RigRotateDirection direction;

  @override
  String get verb => 'rotate';

  @override
  Map<String, dynamic> toJson() => {
    'action': verb,
    'direction': direction.wire,
  };

  @override
  String get summary => direction == RigRotateDirection.clockwise
      ? 'Rotated clockwise'
      : 'Rotated counterclockwise';
}

/// Capture the simulator screen.
class IosScreenshot extends IosAction {
  /// Creates an [IosScreenshot].
  const IosScreenshot({this.fullResolution = false});

  /// When true, return the native PNG instead of the downscaled agent JPEG.
  final bool fullResolution;

  @override
  String get verb => 'screenshot';

  @override
  bool get mutatesGuest => false;

  @override
  Map<String, dynamic> toJson() => {
    'action': verb,
    if (fullResolution) 'full_resolution': true,
  };

  @override
  String get summary => 'Took a screenshot';
}

/// Dump the iOS accessibility hierarchy.
class IosUiDump extends IosAction {
  /// Creates an [IosUiDump].
  const IosUiDump();

  @override
  String get verb => 'ui_dump';

  @override
  bool get mutatesGuest => false;

  @override
  Map<String, dynamic> toJson() => {'action': verb};

  @override
  String get summary => 'Dumped the accessibility hierarchy';
}

/// Install a simulator `.app` bundle from a confined host path.
class IosInstallApp extends IosAction {
  /// Creates an [IosInstallApp].
  const IosInstallApp(this.path);

  /// Host path to the `.app` directory.
  final String path;

  @override
  String get verb => 'install_app';

  @override
  Map<String, dynamic> toJson() => {'action': verb, 'path': path};

  @override
  String get summary => 'Installed ${path.split('/').last}';
}

/// Launch an installed simulator app.
class IosStartApp extends IosAction {
  /// Creates an [IosStartApp].
  const IosStartApp(this.bundleId);

  /// Reverse-DNS bundle identifier.
  final String bundleId;

  @override
  String get verb => 'start_app';

  @override
  Map<String, dynamic> toJson() => {'action': verb, 'bundle_id': bundleId};

  @override
  String get summary => 'Started $bundleId';
}

/// Terminates one running simulator application.
class IosStopApp extends IosAction {
  /// Creates a terminate action.
  const IosStopApp(this.bundleId);

  /// Application bundle identifier.
  final String bundleId;

  @override
  String get verb => 'stop_app';

  @override
  Map<String, dynamic> toJson() => {'action': verb, 'bundle_id': bundleId};

  @override
  String get summary => 'Stopped $bundleId';
}

/// Removes one application from the simulator.
class IosUninstallApp extends IosAction {
  /// Creates an uninstall action.
  const IosUninstallApp(this.bundleId);

  /// Application bundle identifier.
  final String bundleId;

  @override
  String get verb => 'uninstall_app';

  @override
  Map<String, dynamic> toJson() => {'action': verb, 'bundle_id': bundleId};

  @override
  String get summary => 'Uninstalled $bundleId';
}

/// Opens an absolute web URL or application deep link.
class IosOpenUrl extends IosAction {
  /// Creates a URL action.
  const IosOpenUrl(this.url);

  /// Absolute URL or custom-scheme deep link.
  final String url;

  @override
  String get verb => 'open_url';

  @override
  Map<String, dynamic> toJson() => {'action': verb, 'url': url};

  @override
  String get summary => 'Opened $url';
}

/// Runs one argv-shaped process inside the simulator.
///
/// This is the escape hatch for developer operations not represented by a
/// stable typed verb, such as `log`, `defaults`, or targeted diagnostics.
/// CoreSimulator receives argv directly; no host shell is invoked.
class IosSpawn extends IosAction {
  /// Creates a simulator process action.
  IosSpawn(List<String> argv) : argv = List.unmodifiable(argv);

  /// Simulator command and arguments.
  final List<String> argv;

  @override
  String get verb => 'spawn';

  @override
  Map<String, dynamic> toJson() => {'action': verb, 'argv': argv};

  @override
  String get summary => 'Ran ${argv.first} in the iOS Simulator';
}
