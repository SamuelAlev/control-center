// The screen-stream controller is closed by its own `onCancel`, which
// `close_sinks` cannot follow across the closure.
// ignore_for_file: close_sinks

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/rigs/host_ffmpeg.dart';
import 'package:path/path.dart' as p;

/// An ADB invocation failed.
class AdbException implements Exception {
  /// Creates an [AdbException].
  const AdbException(this.message);

  /// What went wrong.
  final String message;

  @override
  String toString() => 'AdbException: $message';
}

/// The device this client is pinned to is gone, or is no longer usable.
///
/// Separated from a plain [AdbException] because it is the one ADB failure
/// with a different fix: no argument change helps, and no retry helps until a
/// device comes back. A raw `error: device 'emulator-5554' not found` reads to
/// a model as a malformed command.
class AdbDeviceGoneException extends AdbException {
  /// Creates an [AdbDeviceGoneException] for [serial].
  const AdbDeviceGoneException(this.serial, String message) : super(message);

  /// The serial this client was pinned to.
  final String serial;

  @override
  String toString() => 'AdbDeviceGoneException($serial): $message';
}

/// One `screenrecord` run: raw H.264 until the device's own time limit.
///
/// A SEGMENT rather than an endless stream, because `screenrecord` caps a
/// recording at 180 seconds and the transcoder above it has to be restarted in
/// step with it — H.264 parameter sets are re-emitted per segment, and feeding
/// two segments into one decoder is how a viewer freezes at the three-minute
/// mark with everything else looking healthy.
class AdbScreenSegment {
  /// Creates an [AdbScreenSegment].
  AdbScreenSegment({required this.bytes, required Future<void> Function() stop})
    : _stop = stop;

  /// The raw H.264 Annex-B bytes, ending when the segment does.
  final Stream<List<int>> bytes;

  final Future<void> Function() _stop;

  /// Ends the segment and reaps the child. Idempotent.
  Future<void> stop() => _stop();
}

/// Drives one Android device over ADB.
///
/// The mobile surface's control channel. Every method shells out to `adb`
/// with an explicit `-s <serial>`: an emulator host commonly has more than one
/// device attached, and an unqualified `adb shell` picks whichever one ADB
/// feels like, which is how you tap the wrong phone. The serial is fixed at
/// construction and [ensureReady] re-checks it before every action, so a
/// device that is swapped or unplugged mid-session is named rather than
/// silently replaced by its neighbour.
///
/// **Egress honesty:** unlike the QEMU surfaces, this one does NOT get a
/// deny-by-default NIC in Tier 1. The Android emulator manages its own
/// networking and `-http-proxy` only covers traffic that honours a proxy, so
/// an app using raw sockets reaches the internet. Real enforcement arrives
/// with the Tier 2 worker (redroid/Cuttlefish behind tap + nftables). The
/// capability layer says so rather than implying parity.
class AdbClient {
  /// Creates an [AdbClient] for [serial] using the `adb` at [adbPath].
  ///
  /// [apkRoots] is the confinement for `install_apk`: an APK is refused unless
  /// its resolved path sits inside one of them. Empty means nothing may be
  /// installed — fail-closed, because "no roots configured" must not read as
  /// "the whole filesystem".
  AdbClient({
    required this.serial,
    required this.adbPath,
    this.apkRoots = const [],
    this.commandTimeout = defaultCommandTimeout,
    this.installTimeout = defaultInstallTimeout,
    this.captureTimeout = defaultCaptureTimeout,
    HostProcessSpawn spawn = spawnHostProcess,
  }) : _spawn = spawn;

  /// The device serial, e.g. `emulator-5554`.
  final String serial;

  /// Absolute path to the `adb` binary.
  final String adbPath;

  /// Host directories an APK may be installed from.
  final List<String> apkRoots;

  final HostProcessSpawn _spawn;

  /// How long an ordinary `adb` command may take before it is killed.
  ///
  /// There was no timeout at all: a wedged `adb shell` (a device that answers
  /// the transport and nothing else — a common emulator state) hung the action
  /// forever, and with it the agent turn that issued it.
  final Duration commandTimeout;

  /// How long an install may take. A package manager run over a slow
  /// transport, so it gets its own budget rather than the command one.
  final Duration installTimeout;

  /// How long a screen capture may take — a full-resolution PNG over that
  /// same transport.
  final Duration captureTimeout;

  /// Default for [commandTimeout].
  static const Duration defaultCommandTimeout = Duration(seconds: 15);

  /// Default for [installTimeout].
  static const Duration defaultInstallTimeout = Duration(minutes: 2);

  /// Default for [captureTimeout].
  static const Duration defaultCaptureTimeout = Duration(seconds: 30);

  /// How long one `screenrecord` segment runs before the device ends it.
  ///
  /// `screenrecord` refuses more than 180s; asking for it exactly means the
  /// restart is ours to schedule rather than a surprise.
  static const Duration segmentLength = Duration(seconds: 180);

  /// Locates `adb`, or null when it is not installed.
  ///
  /// Checks PATH first, then the standard SDK layout. An operator who ran
  /// Android Studio's installer very often has a working SDK that is simply
  /// not on the PATH a GUI-launched server inherits, and reporting "adb is not
  /// installed" at that point sends them to install something they already
  /// have.
  static Future<String?> locate() => _locateTool('adb', 'platform-tools');

  /// Locates the `emulator` binary, or null.
  static Future<String?> locateEmulator() =>
      _locateTool('emulator', 'emulator');

  /// The AVDs defined on this host, newest-listed first.
  ///
  /// An emulator with no AVD cannot start anything, and that is a different
  /// problem from "no emulator" with a different fix, so it is reported
  /// separately.
  static Future<List<String>> avds(String emulatorPath) async {
    try {
      final result = await Process.run(emulatorPath, ['-list-avds']);
      if (result.exitCode != 0) {
        return const [];
      }
      return [
        for (final line in '${result.stdout}'.split('\n'))
          if (line.trim().isNotEmpty && !line.contains(' ')) line.trim(),
      ];
    } on Object {
      return const [];
    }
  }

  /// The root of an Android SDK on this host, or null.
  static String? sdkRoot() {
    final env = Platform.environment;
    for (final key in const ['ANDROID_HOME', 'ANDROID_SDK_ROOT']) {
      final value = env[key];
      if (value != null && value.isNotEmpty && Directory(value).existsSync()) {
        return value;
      }
    }
    final home = env['HOME'];
    if (home == null || home.isEmpty) {
      return null;
    }
    for (final candidate in [
      // macOS (Android Studio's default), then Linux.
      '$home/Library/Android/sdk',
      '$home/Android/Sdk',
    ]) {
      if (Directory(candidate).existsSync()) {
        return candidate;
      }
    }
    return null;
  }

  static Future<String?> _locateTool(String binary, String sdkSubdir) async {
    try {
      final result = await Process.run(Platform.isWindows ? 'where' : 'which', [
        binary,
      ]);
      if (result.exitCode == 0) {
        final path = '${result.stdout}'.split('\n').first.trim();
        if (path.isNotEmpty) {
          return path;
        }
      }
    } on Object {
      // Fall through to the SDK layout.
    }
    final sdk = sdkRoot();
    if (sdk == null) {
      return null;
    }
    final candidate = '$sdk/$sdkSubdir/$binary';
    return File(candidate).existsSync() ? candidate : null;
  }

  /// The serials of every attached device that is fully booted.
  static Future<List<String>> devices(String adbPath) async {
    final result = await Process.run(adbPath, ['devices']);
    if (result.exitCode != 0) {
      return const [];
    }
    return [
      for (final line in '${result.stdout}'.split('\n').skip(1))
        if (line.trim().isNotEmpty && line.contains('\tdevice'))
          line.split('\t').first.trim(),
    ];
  }

  /// Waits until the device reports `sys.boot_completed`.
  ///
  /// An emulator answers ADB long before Android is usable; acting on it in
  /// between gets taps swallowed by a boot animation and reads as "the app is
  /// broken".
  Future<bool> awaitBoot({
    Duration timeout = const Duration(minutes: 3),
    void Function(String step)? onProgress,
  }) async {
    final deadline = DateTime.now().add(timeout);
    onProgress?.call('Waiting for Android to finish booting');
    while (DateTime.now().isBefore(deadline)) {
      try {
        final result = await _run(['shell', 'getprop', 'sys.boot_completed']);
        if (result.stdout.trim() == '1') {
          return true;
        }
      } on TimeoutException {
        // A device mid-boot routinely stops answering for a few seconds; that
        // is what this loop is for, so a slow probe is not a failed boot.
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    return false;
  }

  /// Confirms the pinned device is still attached AND booted.
  ///
  /// Called before every action. `_bootMobile` picks a serial once, and
  /// nothing re-checked it afterwards: unplug that device (or let an emulator
  /// die) and every later tap failed with a raw transport error, or — worse,
  /// had the rig not been pinned — landed on whichever device ADB picked
  /// next. One `getprop` answers both halves, because a command against a
  /// missing serial fails at the transport.
  Future<void> ensureReady() async {
    final ({int exitCode, String stdout, String stderr}) result;
    try {
      result = await _run(['shell', 'getprop', 'sys.boot_completed']);
    } on TimeoutException {
      throw AdbDeviceGoneException(
        serial,
        'Device $serial stopped answering ADB. It may be shutting down or '
        'wedged; check the emulator and open the rig again.',
      );
    }
    if (result.exitCode != 0) {
      throw AdbDeviceGoneException(
        serial,
        'Device $serial is no longer attached '
        '(${_firstLine(result.stderr.isEmpty ? result.stdout : result.stderr)}). '
        'This rig is pinned to that serial and will not silently move to '
        'another device — start it again, or open a new rig.',
      );
    }
    if (result.stdout.trim() != '1') {
      throw AdbDeviceGoneException(
        serial,
        'Device $serial is attached but has not finished booting, so input '
        'would be swallowed by the boot animation. Wait and retry.',
      );
    }
  }

  /// The device's screen size in pixels.
  Future<(int, int)?> screenSize() async {
    final result = await _run(['shell', 'wm', 'size']);
    // "Physical size: 1080x1920", possibly followed by an override line.
    final match = RegExp(
      r'(?:Override|Physical) size:\s*(\d+)x(\d+)',
    ).allMatches(result.stdout).lastOrNull;
    if (match == null) {
      return null;
    }
    return (int.parse(match.group(1)!), int.parse(match.group(2)!));
  }

  /// Captures the screen as PNG bytes.
  ///
  /// `exec-out` rather than `shell`: the latter mangles binary output by
  /// translating line endings, which corrupts every PNG that happens to
  /// contain a 0x0d byte.
  Future<Uint8List> screencap() async {
    final process = await _spawn(adbPath, [
      '-s',
      serial,
      'exec-out',
      'screencap',
      '-p',
    ]);
    final builder = BytesBuilder(copy: false);
    final stderrFuture = process.stderr.transform(utf8.decoder).join();
    unawaited(process.stdin.close().catchError((Object _) {}));
    try {
      await process.stdout.forEach(builder.add).timeout(captureTimeout);
    } on TimeoutException {
      process.kill();
      throw AdbException(
        'screencap did not finish within ${captureTimeout.inSeconds}s on '
        '$serial.',
      );
    }
    final code = await process.exitCode;
    if (code != 0) {
      throw AdbException('screencap failed: ${(await stderrFuture).trim()}');
    }
    final bytes = builder.takeBytes();
    if (bytes.isEmpty) {
      throw const AdbException('screencap returned no bytes');
    }
    return bytes;
  }

  /// Taps at device coordinates.
  Future<void> tap(int x, int y) async {
    await _expectOk(['shell', 'input', 'tap', '$x', '$y']);
  }

  /// Swipes between two points over [duration].
  Future<void> swipe(int x1, int y1, int x2, int y2, Duration duration) async {
    await _expectOk([
      'shell',
      'input',
      'swipe',
      '$x1',
      '$y1',
      '$x2',
      '$y2',
      '${duration.inMilliseconds}',
    ]);
  }

  /// Types [text] into the focused field.
  ///
  /// `input text` treats a space as an argument separator and interprets a
  /// handful of characters, so the text is escaped rather than passed raw —
  /// otherwise typing "hello world" silently types "hello".
  Future<void> typeText(String text) async {
    if (text.isEmpty) {
      return;
    }
    // Newlines are sent as a KEY, not as text. `adb shell` hands its argument
    // to the device's own shell, where a raw `\n` is a COMMAND SEPARATOR:
    // everything after it in a multi-line paste was executed as a shell
    // command in the guest instead of typed into the focused field.
    final lines = text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n');
    for (var i = 0; i < lines.length; i++) {
      if (i > 0) {
        await keyEvent('KEYCODE_ENTER');
      }
      if (lines[i].isNotEmpty) {
        await _expectOk(['shell', 'input', 'text', _escapeForInput(lines[i])]);
      }
    }
  }

  /// Android keycodes this client will send.
  ///
  /// A CLOSED shape, not a closed list: the vocabulary is large and grows with
  /// each Android release, so the check is on the FORM — `KEYCODE_…` in
  /// upper snake case, or a bare number. That is enough to make the value
  /// unable to be anything but an argument, which is the property that
  /// matters when it is interpolated into a device-side shell command.
  static final RegExp _keycodePattern = RegExp(
    r'^(KEYCODE_[A-Z0-9_]+|[0-9]{1,4})$',
  );

  /// Presses an Android keycode.
  Future<void> keyEvent(String keycode) async {
    if (!_keycodePattern.hasMatch(keycode)) {
      throw AdbException(
        'Refusing keycode "$keycode": expected a KEYCODE_* name or a numeric '
        'code. The value reaches the device\'s own shell, so it is validated '
        'rather than trusted to have come from the parser.',
      );
    }
    await _expectOk(['shell', 'input', 'keyevent', keycode]);
  }

  /// Dumps the view hierarchy as text.
  Future<String> uiDump() async {
    // `--compressed` drops the layout-only nodes that make a raw dump
    // unreadable and enormous; `/dev/tty` streams it instead of writing a file
    // into the device we would then have to pull and delete.
    final result = await _run([
      'exec-out',
      'uiautomator',
      'dump',
      '--compressed',
      '/dev/tty',
    ]);
    final xml = result.stdout;
    if (result.exitCode != 0) {
      throw AdbException(
        'uiautomator failed (exit ${result.exitCode}): '
        '${_firstLine(result.stderr.isEmpty ? xml : result.stderr)}',
      );
    }
    if (!xml.contains('<hierarchy')) {
      // uiautomator exits 0 while printing "ERROR: could not get idle state"
      // when the screen never settles, so the exit code alone is not enough.
      throw AdbException(
        'uiautomator produced no hierarchy: '
        '${_firstLine(result.stderr.trim().isEmpty ? xml : result.stderr)}',
      );
    }
    return summarizeHierarchy(xml);
  }

  /// Installs an APK from the host.
  ///
  /// Confined to [apkRoots]: the path is resolved through its symlinks first,
  /// so neither `../` nor a link planted inside an allowed root can point out
  /// of it.
  Future<void> installApk(String hostPath) async {
    final resolved = _resolveConfinedApk(hostPath);
    final result = await _run([
      'install',
      '-r',
      resolved,
    ], timeout: installTimeout);
    final output = '${result.stdout}\n${result.stderr}';
    // Both halves are needed. Modern platform-tools exit non-zero on a failed
    // install; older ones exit 0 and print `Failure [INSTALL_FAILED_…]`, which
    // is why the old `stdout.contains('Success')` test existed — but that test
    // also called a killed adb, a permission error and an empty output a
    // failure with no reason, and called any output containing the word
    // "Success" anywhere a win.
    final failure = RegExp(r'Failure \[([^\]]*)\]').firstMatch(output);
    if (result.exitCode != 0 || failure != null) {
      throw AdbException(
        'Installing ${p.basename(resolved)} on $serial failed'
        '${failure != null ? ' (${failure.group(1)})' : ''}: '
        '${_firstLine(output)}',
      );
    }
  }

  /// Launches an app.
  Future<void> startApp(String package, {String? activity}) async {
    final args = activity != null
        ? ['shell', 'am', 'start', '-n', '$package/$activity']
        : [
            'shell',
            'monkey',
            '-p',
            package,
            '-c',
            'android.intent.category.LAUNCHER',
            '1',
          ];
    final result = await _run(args);
    final output = '${result.stdout}\n${result.stderr}';
    // `am` and `monkey` both exit 0 while reporting a failure in their output,
    // so the exit code is necessary and not sufficient. The old test —
    // `stdout.contains('Error')` — matched any app or activity name containing
    // that word and missed monkey's own wording entirely.
    final amError = RegExp(
      r'^\s*Error(?: type \d+)?:\s*(.*)$',
      multiLine: true,
    ).firstMatch(output);
    final monkeyError = RegExp(
      r'^\s*\*\* (No activities found.*|Error:.*)$',
      multiLine: true,
    ).firstMatch(output);
    if (result.exitCode != 0 || amError != null || monkeyError != null) {
      final detail =
          amError?.group(1) ?? monkeyError?.group(1) ?? _firstLine(output);
      throw AdbException(
        'Could not start $package'
        '${activity != null ? '/$activity' : ''} on $serial: '
        '${detail.trim().isEmpty ? 'adb exited ${result.exitCode}' : detail}',
      );
    }
  }

  /// Starts ONE `screenrecord` segment of raw H.264.
  ///
  /// Deliberately not an endless stream: the device ends a recording at
  /// [segmentLength] whatever anyone wants, and the transcoder above has to be
  /// cycled with it. Handing the caller a segment makes that boundary visible
  /// instead of hiding it inside a stream that quietly changes parameter sets
  /// mid-flight.
  Future<AdbScreenSegment> startScreenSegment({
    required int bitRate,
    int? width,
    int? height,
  }) async {
    final process = await _spawn(adbPath, [
      '-s',
      serial,
      'exec-out',
      'screenrecord',
      '--output-format=h264',
      '--bit-rate=$bitRate',
      if (width != null && height != null) '--size=${width}x$height',
      '--time-limit=${segmentLength.inSeconds}',
      '-',
    ]);
    unawaited(process.stdin.close().catchError((Object _) {}));
    unawaited(
      process.stderr
          .transform(utf8.decoder)
          .forEach((e) => CcInfraLog.debug('rig/adb screenrecord: $e'))
          .catchError((Object _) {}),
    );
    var stopped = false;
    return AdbScreenSegment(
      bytes: process.stdout,
      stop: () async {
        if (stopped) {
          return;
        }
        stopped = true;
        process.kill();
        await process.exitCode;
      },
    );
  }

  /// Runs one `adb` command against the pinned serial, bounded by [timeout].
  ///
  /// Implemented over the spawn seam rather than `Process.run` because a
  /// `Future.timeout` around `Process.run` abandons the child instead of
  /// killing it — the caller is freed and the wedged `adb` stays, holding the
  /// device's transport for everybody else.
  Future<({int exitCode, String stdout, String stderr})> _run(
    List<String> args, {
    Duration? timeout,
  }) async {
    final process = await _spawn(adbPath, ['-s', serial, ...args]);
    final out = process.stdout.transform(utf8.decoder).join();
    final err = process.stderr.transform(utf8.decoder).join();
    unawaited(process.stdin.close().catchError((Object _) {}));
    final int code;
    try {
      code = await process.exitCode.timeout(timeout ?? commandTimeout);
    } on TimeoutException {
      process.kill();
      throw TimeoutException(
        'adb ${args.join(' ')} on $serial did not finish in time',
        timeout ?? commandTimeout,
      );
    }
    return (exitCode: code, stdout: await out, stderr: await err);
  }

  Future<void> _expectOk(List<String> args) async {
    final result = await _run(args);
    if (result.exitCode != 0) {
      throw AdbException(
        'adb ${args.join(' ')} failed: '
        '${_firstLine(result.stderr.isEmpty ? result.stdout : result.stderr)}',
      );
    }
  }

  /// Resolves [hostPath] and refuses it unless it sits inside [apkRoots].
  String _resolveConfinedApk(String hostPath) {
    final file = File(hostPath);
    if (!file.existsSync()) {
      throw AdbException('No APK at $hostPath');
    }
    // Symlinks first: `<worktree>/link.apk -> /etc/shadow` is inside an
    // allowed root by string and outside it by content, and it is the content
    // that lands on the device.
    final String resolved;
    try {
      resolved = file.resolveSymbolicLinksSync();
    } on FileSystemException catch (e) {
      throw AdbException('Could not resolve $hostPath: ${e.message}');
    }
    final roots = <String>[];
    for (final root in apkRoots) {
      if (root.isEmpty) {
        continue;
      }
      try {
        roots.add(Directory(root).resolveSymbolicLinksSync());
      } on FileSystemException {
        // A root that does not exist on this host confines nothing; skip it
        // rather than letting it widen or narrow the check by accident.
        continue;
      }
    }
    for (final root in roots) {
      if (p.isWithin(root, resolved)) {
        return resolved;
      }
    }
    throw AdbException(
      roots.isEmpty
          ? 'install_apk is refused: this host has no directory an APK may be '
                'installed from, so nothing can be pushed into the device. '
                'Build the APK inside the rig\'s worktree.'
          : 'install_apk is confined to ${roots.join(', ')}. '
                '$hostPath resolves to $resolved, which is outside — a rig is '
                'not a way to push arbitrary host files into a guest.',
    );
  }

  /// Escapes [text] for `adb shell input text`.
  static String _escapeForInput(String text) {
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      final ch = String.fromCharCode(rune);
      if (ch == ' ') {
        buffer.write('%s');
      } else if (const [
        '\\',
        '"',
        "'",
        '(',
        ')',
        '&',
        '<',
        '>',
        ';',
        '|',
        '*',
        '~',
        '`',
        r'$',
      ].contains(ch)) {
        buffer.write('\\$ch');
      } else {
        buffer.write(ch);
      }
    }
    return buffer.toString();
  }

  static String _firstLine(String text) {
    for (final line in text.split('\n')) {
      if (line.trim().isNotEmpty) {
        return line.trim();
      }
    }
    return '';
  }

  /// Reduces a uiautomator dump to the nodes an agent can act on.
  ///
  /// The raw XML is largely layout containers; a real screen is tens of
  /// kilobytes of it. This keeps what has a label, a resource id or is
  /// clickable, with its centre point, which is what a tap needs.
  static String summarizeHierarchy(String xml) {
    final lines = <String>[];
    for (final node in parseNodeAttributes(xml)) {
      String attr(String name) => node[name] ?? '';

      final text = attr('text');
      final desc = attr('content-desc');
      final resource = attr('resource-id');
      final clickable = attr('clickable') == 'true';
      final className = attr('class').split('.').last;
      if (text.isEmpty && desc.isEmpty && resource.isEmpty && !clickable) {
        continue;
      }
      final bounds = RegExp(
        r'\[(-?\d+),(-?\d+)\]\[(-?\d+),(-?\d+)\]',
      ).firstMatch(attr('bounds'));
      final center = bounds == null
          ? ''
          : ' @(${(int.parse(bounds.group(1)!) + int.parse(bounds.group(3)!)) ~/ 2},'
                '${(int.parse(bounds.group(2)!) + int.parse(bounds.group(4)!)) ~/ 2})';
      lines.add(
        '$className'
        '${clickable ? ' [tappable]' : ''}'
        '${text.isEmpty ? '' : ' "$text"'}'
        '${desc.isEmpty ? '' : ' desc="$desc"'}'
        '${resource.isEmpty ? '' : ' id=$resource'}'
        '$center',
      );
    }
    return lines.join('\n');
  }

  /// The attributes of every `<node …>` in a uiautomator dump, in order.
  ///
  /// A real parser and not `<node\b[^>]*>`, because a `>` is perfectly legal
  /// inside an XML attribute value — an app whose button reads "Next >" ended
  /// that regex early, and every node after it in the dump was mis-split or
  /// lost. Quotes are tracked so a value's delimiter is the only thing that
  /// can close it, and entities are decoded, because `text="Say &quot;hi&quot;"`
  /// is what a screen with a quote in it actually serialises to.
  ///
  /// It is deliberately a tokenizer and not a full XML parse: the input is one
  /// known shape from one known producer, the dump is tens of kilobytes on
  /// every screenshot, and nothing here needs a tree.
  static List<Map<String, String>> parseNodeAttributes(String xml) {
    const tagOpen = '<node';
    final nodes = <Map<String, String>>[];
    var i = 0;
    while (true) {
      final start = xml.indexOf(tagOpen, i);
      if (start < 0) {
        break;
      }
      // `<nodeish` is a different element; only a delimiter may follow.
      final after = start + tagOpen.length;
      if (after < xml.length && !_isTagBreak(xml.codeUnitAt(after))) {
        i = after;
        continue;
      }
      final attrs = <String, String>{};
      var j = after;
      while (j < xml.length) {
        // Skip whitespace between attributes.
        while (j < xml.length && _isSpace(xml.codeUnitAt(j))) {
          j++;
        }
        if (j >= xml.length) {
          break;
        }
        final c = xml[j];
        if (c == '>' || (c == '/' && j + 1 < xml.length && xml[j + 1] == '>')) {
          j += c == '>' ? 1 : 2;
          break;
        }
        final nameStart = j;
        while (j < xml.length &&
            !_isSpace(xml.codeUnitAt(j)) &&
            xml[j] != '=' &&
            xml[j] != '>' &&
            xml[j] != '/') {
          j++;
        }
        final name = xml.substring(nameStart, j);
        while (j < xml.length && _isSpace(xml.codeUnitAt(j))) {
          j++;
        }
        if (j >= xml.length || xml[j] != '=') {
          // A valueless attribute: not legal XML, but a truncated dump can
          // produce one and dropping the rest of the tag is worse than
          // recording nothing for it.
          if (name.isNotEmpty) {
            attrs[name] = '';
          }
          continue;
        }
        j++; // '='
        while (j < xml.length && _isSpace(xml.codeUnitAt(j))) {
          j++;
        }
        if (j >= xml.length) {
          break;
        }
        final quote = xml[j];
        if (quote != '"' && quote != "'") {
          // Unquoted value: read to the next delimiter. Also not legal XML,
          // and also survivable.
          final valueStart = j;
          while (j < xml.length &&
              !_isSpace(xml.codeUnitAt(j)) &&
              xml[j] != '>') {
            j++;
          }
          attrs[name] = _decodeEntities(xml.substring(valueStart, j));
          continue;
        }
        j++; // opening quote
        final valueStart = j;
        final close = xml.indexOf(quote, j);
        if (close < 0) {
          // Unterminated: everything after it is unparseable, so stop rather
          // than resynchronising onto a fragment.
          j = xml.length;
          attrs[name] = _decodeEntities(xml.substring(valueStart));
          break;
        }
        attrs[name] = _decodeEntities(xml.substring(valueStart, close));
        j = close + 1;
      }
      if (attrs.isNotEmpty) {
        nodes.add(attrs);
      }
      i = j > start ? j : start + tagOpen.length;
    }
    return nodes;
  }

  static bool _isSpace(int unit) =>
      unit == 0x20 || unit == 0x09 || unit == 0x0a || unit == 0x0d;

  static bool _isTagBreak(int unit) =>
      _isSpace(unit) || unit == 0x3e /* > */ || unit == 0x2f /* / */;

  /// Decodes the five predefined XML entities plus numeric character
  /// references. uiautomator escapes every one of them, and a label rendered
  /// as `Save &amp; exit` is a label an agent will not find by name.
  static String _decodeEntities(String value) {
    if (!value.contains('&')) {
      return value;
    }
    return value.replaceAllMapped(
      RegExp(r'&(#x[0-9a-fA-F]+|#\d+|[a-zA-Z]+);'),
      (m) {
        final body = m.group(1)!;
        if (body.startsWith('#x') || body.startsWith('#X')) {
          final code = int.tryParse(body.substring(2), radix: 16);
          return code == null ? m.group(0)! : String.fromCharCode(code);
        }
        if (body.startsWith('#')) {
          final code = int.tryParse(body.substring(1));
          return code == null ? m.group(0)! : String.fromCharCode(code);
        }
        return switch (body) {
          'amp' => '&',
          'lt' => '<',
          'gt' => '>',
          'quot' => '"',
          'apos' => "'",
          // An entity we do not know is left verbatim: inventing a character
          // for it would silently change the label an agent matches on.
          _ => m.group(0)!,
        };
      },
    );
  }
}
