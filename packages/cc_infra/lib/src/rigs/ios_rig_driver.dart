import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:cc_domain/features/rigs/domain/value_objects/ios_action.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_action.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_action_result.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_clipboard.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_display.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_file_transfer.dart';
import 'package:cc_infra/src/rigs/host_ffmpeg.dart';
import 'package:cc_infra/src/rigs/ios_simulator_backend.dart';
import 'package:cc_infra/src/rigs/rig_drivers.dart';
import 'package:path/path.dart' as p;

/// Drives one ephemeral iOS Simulator through WebDriverAgent.
class IosRigDriver implements RigDriver {
  /// Creates an iOS driver.
  IosRigDriver({
    required this.session,
    required this.backend,
    required List<String> appRoots,
    required this.onDisplayChanged,
    FfmpegResolver? ffmpeg,
  }) : _appRoots = List.unmodifiable(appRoots),
       _ffmpeg = ffmpeg ?? HostFfmpeg.locate;

  /// Live simulator/WDA session.
  final IosSimulatorSession session;

  /// CoreSimulator operations that do not travel through WDA.
  final IosSimulatorBackend backend;

  final List<String> _appRoots;

  /// Persists a changed logical simulator display.
  final void Function(RigDisplaySize display) onDisplayChanged;
  final FfmpegResolver _ffmpeg;
  Future<void> _commandTail = Future<void>.value();
  bool _disposed = false;

  @override
  RigDisplaySize get display => session.display;

  @override
  RigStreamCodec get watchCodec => RigStreamCodec.mjpeg;

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _commandTail.then((_) {
      if (_disposed) {
        throw StateError('The iOS rig driver is closed.');
      }
      return operation();
    });
    _commandTail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  @override
  Future<RigActionResult> perform(RigAction action) {
    if (action is! IosAction) {
      return Future.value(
        RigActionResult.error(
          'A ${action.surface.wire} action cannot be sent to an iOS rig.',
        ),
      );
    }
    return _serialize(() async {
      try {
        switch (action) {
          case IosTap(:final x, :final y):
            await _refreshScreen();
            _requirePoint(x, y);
            await session.client.tap(x, y);
          case IosSwipe(
            :final fromX,
            :final fromY,
            :final toX,
            :final toY,
            :final duration,
          ):
            await _refreshScreen();
            _requirePoint(fromX, fromY);
            _requirePoint(toX, toY);
            await session.client.swipe(
              fromX: fromX,
              fromY: fromY,
              toX: toX,
              toY: toY,
              duration: duration,
            );
          case IosType(:final text):
            await session.client.typeText(text);
          case IosKey(:final key, :final modifiers):
            await session.client.key([
              for (final modifier in IosKeyModifier.values)
                if (modifiers.contains(modifier)) _modifierValue(modifier),
              _keyValue(key),
            ]);
          case IosHome():
            await session.client.home();
          case IosLock():
            await session.client.lock();
          case IosUnlock():
            await session.client.unlock();
          case IosScreenshot():
            return await _captureForAgentUnlocked();
          case IosUiDump():
            final source = await session.client.source();
            final summary = await Isolate.run(_IosTreeSummary(source).call);
            return RigActionResult.ok(
              wrapUntrustedRigContent(
                summary,
                source: 'ios accessibility tree',
              ),
            );
          case IosInstallApp(:final path):
            final confined = await Isolate.run(
              _IosAppValidation(path, _appRoots).call,
            );
            await backend.installApp(session, confined);
          case IosStartApp(:final bundleId):
            await session.client.launchApp(bundleId);
          case IosStopApp(:final bundleId):
            await backend.stopApp(session, bundleId);
          case IosUninstallApp(:final bundleId):
            await backend.uninstallApp(session, bundleId);
          case IosOpenUrl(:final url):
            await backend.openUrl(session, url);
          case IosSpawn(:final argv):
            final output = await backend.spawn(session, argv);
            return RigActionResult.ok(
              output.isEmpty
                  ? '${action.summary}; the command produced no output.'
                  : wrapUntrustedRigContent(
                      output,
                      source: 'ios simulator process',
                    ),
            );
        }
        return RigActionResult.ok('${action.summary}.');
      } on Object catch (error) {
        return rigDriverFailure(action.verb, error);
      }
    });
  }

  @override
  Future<RigActionResult> captureForAgent() =>
      _serialize(_captureForAgentUnlocked);

  Future<RigActionResult> _captureForAgentUnlocked() async {
    try {
      await _refreshScreen();
      final png = await session.client.screenshot();
      final target = display.fitInside(RigDisplaySize.agentCeiling);
      final ffmpeg = await _ffmpeg();
      if (ffmpeg != null) {
        final jpeg = await transcodePngStillToJpeg(
          ffmpeg,
          png,
          target.width,
          target.height,
          logContext: 'rig/ios',
        );
        if (jpeg != null) {
          return RigActionResult(
            text:
                'Screenshot of the $display iOS Simulator, scaled to $target. '
                'Coordinates in actions are in SIMULATOR POINTS ($display), '
                'not screenshot pixels.',
            imageBase64: base64Encode(jpeg),
            imageMediaType: 'image/jpeg',
            displaySize: display.toString(),
          );
        }
      }
      return RigActionResult(
        text:
            'Screenshot of the $display iOS Simulator at full resolution as '
            'PNG: this host has no working ffmpeg, so it could not be '
            'downscaled to $target or encoded as JPEG. Coordinates in actions '
            'are in SIMULATOR POINTS ($display), not screenshot pixels.',
        imageBase64: base64Encode(png),
        imageMediaType: 'image/png',
        displaySize: display.toString(),
      );
    } on Object catch (error) {
      return RigActionResult.error('Screenshot failed: $error');
    }
  }

  @override
  Future<Stream<List<int>>?> openWatchStream(RigWatchRequest request) async {
    await _serialize(() async {
      await _refreshScreen();
      final nativeWidth = display.width * session.scale;
      final nativeHeight = display.height * session.scale;
      final ratio = [
        request.size.width / nativeWidth,
        request.size.height / nativeHeight,
        1.0,
      ].reduce((a, b) => a < b ? a : b);
      await session.client.configureMjpeg(
        fps: request.fps.clamp(1, 15),
        scalingFactor: (ratio * 100).round().clamp(1, 100),
        quality: request.quality,
      );
    });

    final controller = StreamController<List<int>>();
    StreamSubscription<List<int>>? frames;
    Timer? screenPoll;
    var polling = false;
    Future<void> poll() async {
      if (polling || _disposed || controller.isClosed) {
        return;
      }
      polling = true;
      try {
        await _serialize(_refreshScreen);
      } on Object {
        // Frame delivery owns the visible error lane. A transient geometry
        // read must not tear down a healthy MJPEG stream.
      } finally {
        polling = false;
      }
    }

    frames = session.client.openMjpeg().listen(
      controller.add,
      onError: controller.addError,
      onDone: controller.close,
    );
    screenPoll = Timer.periodic(
      const Duration(seconds: 1),
      (_) => unawaited(poll()),
    );
    controller
      ..onPause = frames.pause
      ..onResume = frames.resume
      ..onCancel = () async {
        screenPoll?.cancel();
        await frames?.cancel();
      };
    return controller.stream;
  }

  Future<void> _refreshScreen() async {
    final current = await session.client.screen();
    session.scale = current.scale;
    if (current.size == session.display) {
      return;
    }
    session.display = current.size;
    onDisplayChanged(current.size);
  }

  void _requirePoint(int x, int y) {
    if (x < 0 || y < 0 || x >= display.width || y >= display.height) {
      throw RangeError(
        'Coordinate ($x, $y) is outside the iOS Simulator display $display.',
      );
    }
  }

  @override
  Future<RigClipboardData> readClipboard(
    RigClipboardSelection selection,
  ) => _serialize(() async {
    if (selection != RigClipboardSelection.clipboard) {
      throw const RigSurfaceUnsupported(
        'iOS Simulator has one system pasteboard; PRIMARY and drag selections '
        'do not exist.',
      );
    }
    final textBytes = await session.client.getPasteboard(
      contentType: 'plaintext',
    );
    if (textBytes.isEmpty) {
      return RigClipboardData.empty;
    }
    return RigClipboardData.ofText(
      utf8.decode(textBytes, allowMalformed: true),
    );
  });

  @override
  Future<void> writeClipboard(RigClipboardData data) => _serialize(() async {
    if (data.files.isNotEmpty) {
      throw const RigSurfaceUnsupported(
        'iOS Simulator pasteboard transfer does not support host file drops.',
      );
    }
    if (data.hasImage) {
      await session.client.setPasteboard(
        contentType: 'image',
        bytes: base64Decode(data.imageBase64!),
      );
      return;
    }
    if (data.text != null) {
      await session.client.setPasteboard(
        contentType: 'plaintext',
        bytes: utf8.encode(data.text!),
      );
    }
  });

  @override
  Future<RigDropResult> offerDroppedFiles(
    List<RigGuestFile> landed,
    RigDropRequest request,
  ) async => RigDropResult.error(
    'Dropping files onto iOS Simulator is not supported. Build a simulator '
    '.app in the worktree and use install_app instead.',
  );

  @override
  Future<Stream<List<int>>?> openAudioStream() async => null;

  @override
  Future<bool> sendAudioInput(
    Uint8List bytes, {
    required String sessionId,
    required int sampleRate,
    required int channels,
    bool start = false,
    bool end = false,
  }) async => false;

  @override
  Future<void> dispose() async {
    _disposed = true;
    try {
      await _commandTail;
    } on Object {
      // The operation already returned its own failure result.
    }
  }
}

String _modifierValue(IosKeyModifier modifier) => switch (modifier) {
  IosKeyModifier.shift => '\uE008',
  IosKeyModifier.control => '\uE009',
  IosKeyModifier.option => '\uE00A',
  IosKeyModifier.command => '\uE03D',
};

String _keyValue(String key) => switch (key) {
  'backspace' => '\uE003',
  'tab' => '\uE004',
  'enter' => '\uE007',
  'escape' => '\uE00C',
  'arrow_up' => '\uE013',
  'arrow_down' => '\uE015',
  'arrow_left' => '\uE012',
  'arrow_right' => '\uE014',
  _ => key,
};

class _IosAppValidation {
  const _IosAppValidation(this.path, this.permittedRoots);

  final String path;
  final List<String> permittedRoots;

  String call() => _validateIosAppBundle(path, permittedRoots);
}

class _IosTreeSummary {
  const _IosTreeSummary(this.source);

  final Object? source;

  String call() => _summarizeIosTree(source);
}

String _validateIosAppBundle(String path, List<String> permittedRoots) {
  final directory = Directory(path);
  if (!directory.existsSync() || !path.toLowerCase().endsWith('.app')) {
    throw ArgumentError.value(
      path,
      'path',
      'Expected an existing .app directory',
    );
  }
  final canonicalBundle = directory.resolveSymbolicLinksSync();
  final roots = <String>[];
  for (final root in permittedRoots) {
    final entity = Directory(root);
    if (entity.existsSync()) {
      roots.add(entity.resolveSymbolicLinksSync());
    }
  }
  if (!roots.any((root) => _inside(root, canonicalBundle))) {
    throw ArgumentError.value(
      path,
      'path',
      'The .app must be inside the rig worktree or server data directory',
    );
  }
  for (final entity in Directory(
    canonicalBundle,
  ).listSync(recursive: true, followLinks: false)) {
    if (entity is! Link) {
      continue;
    }
    final target = entity.resolveSymbolicLinksSync();
    if (!_inside(canonicalBundle, target)) {
      throw ArgumentError(
        'The .app contains a symlink outside its bundle: ${entity.path}',
      );
    }
  }
  return canonicalBundle;
}

bool _inside(String root, String candidate) {
  final relative = p.relative(candidate, from: root);
  return relative == '.' ||
      (relative != '..' && !relative.startsWith('..${p.separator}'));
}

String _summarizeIosTree(Object? source) {
  const maxNodes = 500;
  const maxChars = 24000;
  final lines = <String>[];
  var visited = 0;
  var omitted = 0;
  var chars = 0;

  void visit(Object? node, int depth) {
    if (node is List) {
      for (final child in node) {
        visit(child, depth);
      }
      return;
    }
    if (node is! Map) {
      return;
    }
    final map = Map<String, dynamic>.from(node);
    final children = map['children'];
    final type = map['type']?.toString();
    final name = map['name']?.toString();
    final label = map['label']?.toString();
    final value = map['value']?.toString();
    final rect = map['rect'];
    final meaningful = [
      type,
      name,
      label,
      value,
    ].any((part) => part != null && part.isNotEmpty);
    if (meaningful) {
      visited++;
      final center = _rectCenter(rect);
      final parts = <String>[
        '${'  ' * depth}${type ?? 'element'}',
        if (name != null && name.isNotEmpty) 'name=${jsonEncode(name)}',
        if (label != null && label.isNotEmpty && label != name)
          'label=${jsonEncode(label)}',
        if (value != null && value.isNotEmpty) 'value=${jsonEncode(value)}',
        if (map['enabled'] != null) 'enabled=${map['enabled']}',
        if (map['visible'] != null) 'visible=${map['visible']}',
        if (center != null) 'center=[${center.$1}, ${center.$2}]',
      ];
      final line = parts.join(' ');
      if (visited <= maxNodes && chars + line.length + 1 <= maxChars) {
        lines.add(line);
        chars += line.length + 1;
      } else {
        omitted++;
      }
    }
    if (children is List) {
      for (final child in children) {
        visit(child, depth + 1);
      }
    }
  }

  visit(source, 0);
  if (lines.isEmpty) {
    lines.add('The accessibility hierarchy is empty.');
  }
  if (omitted > 0) {
    lines.add('… $omitted additional nodes omitted.');
  }
  return lines.join('\n');
}

(int, int)? _rectCenter(Object? raw) {
  if (raw is! Map) {
    return null;
  }
  final x = raw['x'];
  final y = raw['y'];
  final width = raw['width'];
  final height = raw['height'];
  if (x is! num || y is! num || width is! num || height is! num) {
    return null;
  }
  return ((x + width / 2).round(), (y + height / 2).round());
}
