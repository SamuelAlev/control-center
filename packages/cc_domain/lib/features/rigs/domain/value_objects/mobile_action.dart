import 'package:cc_domain/features/rigs/domain/value_objects/rig_action.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';

/// Actions on the mobile-use surface, driven over ADB.
sealed class MobileAction extends RigAction {
  /// Const base constructor.
  const MobileAction();

  @override
  RigSurface get surface => RigSurface.mobile;

  /// Parses an untrusted `{action, ...}` payload. Total — failures come back
  /// as [RigActionInvalid] naming the field.
  static RigActionParse parse(Map<String, dynamic> args) {
    final verb = rigOptString(args, 'action');
    if (verb == null) {
      return const RigActionInvalid(
        'Missing or invalid argument: action (expected one of tap, swipe, '
        'type, key, screenshot, ui_dump, install_apk, start_app)',
      );
    }
    switch (verb) {
      case 'tap':
        final point = rigOptPoint(args, 'coordinate');
        if (point == null) {
          return const RigActionInvalid(
            'Missing or invalid argument: coordinate (expected [x, y] in '
            'device pixels)',
          );
        }
        return RigActionParsed(MobileTap(x: point.$1, y: point.$2));
      case 'swipe':
        final from = rigOptPoint(args, 'from');
        final to = rigOptPoint(args, 'to');
        if (from == null || to == null) {
          return const RigActionInvalid(
            'Missing or invalid arguments: from and to (each expected as '
            '[x, y] in device pixels)',
          );
        }
        final ms = rigOptInt(args, 'duration_ms') ?? 300;
        return RigActionParsed(
          MobileSwipe(
            fromX: from.$1,
            fromY: from.$2,
            toX: to.$1,
            toY: to.$2,
            duration: Duration(milliseconds: ms.clamp(50, 5000)),
          ),
        );
      case 'type':
        final text = rigOptString(args, 'text');
        if (text == null) {
          return const RigActionInvalid('Missing or invalid argument: text');
        }
        return RigActionParsed(MobileType(text));
      case 'key':
        final key = rigOptString(args, 'key');
        if (key == null) {
          return const RigActionInvalid(
            'Missing or invalid argument: key (expected a name such as back, '
            'home, enter, or an Android keycode like KEYCODE_TAB)',
          );
        }
        final resolved = MobileKey.resolveKeycode(key);
        if (resolved == null) {
          return RigActionInvalid(
            'Unknown key: "$key" (expected back, home, recents, enter, '
            'delete, tab, escape, volume_up, volume_down, power, or an '
            'explicit KEYCODE_* name)',
          );
        }
        return RigActionParsed(MobileKey(resolved));
      case 'screenshot':
        return const RigActionParsed(MobileScreenshot());
      case 'ui_dump':
        return const RigActionParsed(MobileUiDump());
      case 'install_apk':
        final path = rigOptString(args, 'path');
        if (path == null) {
          return const RigActionInvalid(
            'Missing or invalid argument: path (a host path to the .apk)',
          );
        }
        if (!path.toLowerCase().endsWith('.apk')) {
          return const RigActionInvalid(
            'Invalid argument: path must name a .apk file',
          );
        }
        return RigActionParsed(MobileInstallApk(path));
      case 'start_app':
        final package = rigOptString(args, 'package');
        if (package == null) {
          return const RigActionInvalid(
            'Missing or invalid argument: package (e.g. com.example.app)',
          );
        }
        // The package name is interpolated into an `am start` argument, so it
        // is validated as a package name rather than trusted. Nothing here
        // reaches a shell through a string, but a value that cannot be a
        // package is a mistake worth naming at the boundary.
        if (!RegExp(
          r'^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$',
        ).hasMatch(package)) {
          return RigActionInvalid(
            'Invalid argument: "$package" is not a valid Android package name',
          );
        }
        return RigActionParsed(
          MobileStartApp(
            package: package,
            activity: rigOptString(args, 'activity'),
          ),
        );
      default:
        return RigActionInvalid('Unknown mobile action: "$verb"');
    }
  }
}

/// Tap the screen.
class MobileTap extends MobileAction {
  /// Creates a [MobileTap].
  const MobileTap({required this.x, required this.y});

  /// Device-pixel x.
  final int x;

  /// Device-pixel y.
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

/// Swipe between two points.
class MobileSwipe extends MobileAction {
  /// Creates a [MobileSwipe].
  const MobileSwipe({
    required this.fromX,
    required this.fromY,
    required this.toX,
    required this.toY,
    required this.duration,
  });

  /// Origin x.
  final int fromX;

  /// Origin y.
  final int fromY;

  /// Destination x.
  final int toX;

  /// Destination y.
  final int toY;

  /// Gesture duration — the difference between a fling and a drag.
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

/// Type text into the focused field.
class MobileType extends MobileAction {
  /// Creates a [MobileType].
  const MobileType(this.text);

  /// The literal text.
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

/// Press a hardware/soft key.
class MobileKey extends MobileAction {
  /// Creates a [MobileKey] from a resolved `KEYCODE_*` name.
  const MobileKey(this.keycode);

  /// The Android keycode name, e.g. `KEYCODE_BACK`.
  final String keycode;

  /// Friendly names accepted alongside raw `KEYCODE_*` values, so a model can
  /// write "back" without knowing Android's constant table.
  static const Map<String, String> _aliases = {
    'back': 'KEYCODE_BACK',
    'home': 'KEYCODE_HOME',
    'recents': 'KEYCODE_APP_SWITCH',
    'enter': 'KEYCODE_ENTER',
    'delete': 'KEYCODE_DEL',
    'backspace': 'KEYCODE_DEL',
    'tab': 'KEYCODE_TAB',
    'escape': 'KEYCODE_ESCAPE',
    'search': 'KEYCODE_SEARCH',
    'menu': 'KEYCODE_MENU',
    'volume_up': 'KEYCODE_VOLUME_UP',
    'volume_down': 'KEYCODE_VOLUME_DOWN',
    'power': 'KEYCODE_POWER',
  };

  /// Resolves [name] to a `KEYCODE_*` constant, or null when it is neither a
  /// known alias nor a well-formed keycode.
  static String? resolveKeycode(String name) {
    final alias = _aliases[name.toLowerCase()];
    if (alias != null) {
      return alias;
    }
    if (RegExp(r'^KEYCODE_[A-Z0-9_]+$').hasMatch(name)) {
      return name;
    }
    return null;
  }

  @override
  String get verb => 'key';

  @override
  Map<String, dynamic> toJson() => {'action': verb, 'key': keycode};

  @override
  String get summary => 'Pressed $keycode';
}

/// Capture the screen.
class MobileScreenshot extends MobileAction {
  /// Creates a [MobileScreenshot].
  const MobileScreenshot();

  @override
  String get verb => 'screenshot';

  @override
  bool get mutatesGuest => false;

  @override
  Map<String, dynamic> toJson() => {'action': verb};

  @override
  String get summary => 'Took a screenshot';
}

/// Dump the view hierarchy as text.
class MobileUiDump extends MobileAction {
  /// Creates a [MobileUiDump].
  const MobileUiDump();

  @override
  String get verb => 'ui_dump';

  @override
  bool get mutatesGuest => false;

  @override
  Map<String, dynamic> toJson() => {'action': verb};

  @override
  String get summary => 'Dumped the view hierarchy';
}

/// Install an APK from the host.
class MobileInstallApk extends MobileAction {
  /// Creates a [MobileInstallApk].
  const MobileInstallApk(this.path);

  /// Host path to the `.apk`.
  ///
  /// The adapter (`AdbClient.installApk`) resolves this path's symlinks and
  /// refuses it unless the result is inside one of the roots the rig was
  /// constructed with — its worktree and the server's data directory. A rig
  /// must not be a way to push arbitrary host files into a guest, and a host
  /// with no roots configured installs NOTHING rather than everything.
  ///
  /// The parse above additionally requires a `.apk` suffix; that is a typo
  /// guard, not the confinement — the suffix says nothing about where the file
  /// lives.
  final String path;

  @override
  String get verb => 'install_apk';

  @override
  Map<String, dynamic> toJson() => {'action': verb, 'path': path};

  @override
  String get summary => 'Installed ${path.split("/").last}';
}

/// Launch an app.
class MobileStartApp extends MobileAction {
  /// Creates a [MobileStartApp].
  const MobileStartApp({required this.package, this.activity});

  /// The Android package name.
  final String package;

  /// An optional explicit activity; null launches the default.
  final String? activity;

  @override
  String get verb => 'start_app';

  @override
  Map<String, dynamic> toJson() => {
    'action': verb,
    'package': package,
    if (activity != null) 'activity': activity,
  };

  @override
  String get summary => 'Started $package';
}
