// Files dragged in from the operating system, reported by the host.
//
// This is the Dart half of `macos/Runner/FileDropBridge.swift`, and it exists
// for the reason spelled out there: `super_drag_and_drop` cannot work in this
// app. Its native half asks `irondash_engine_context` for a view to register as
// a drag destination, irondash captures that view once from `registrar.view` at
// plugin-registration time, and this app has no view then — the runner is
// headless and every window is created later from Dart. So the value cached is
// nil, forever, and no OS drag has ever reached any `DropRegion` here.
//
// The host registers the destination itself and forwards three things: a drag
// moving over a view, a drag leaving, and a drop with its payload. Hit-testing
// stays in Dart, where the widgets are.
library;

import 'dart:async';

import 'package:control_center/core/utils/app_log.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// A drag currently moving over one of the app's views.
@immutable
class HostDragEvent {
  /// Creates a [HostDragEvent].
  const HostDragEvent({
    required this.viewId,
    required this.position,
    required this.itemCount,
  });

  /// The Flutter view the drag is over, or -1 when the host could not resolve
  /// one. Matched against `View.of(context).viewId` so a drag over a HUD panel
  /// never lights up a target in the main window.
  final int viewId;

  /// Where the pointer is, in that view's logical pixels (top-left origin) —
  /// the same space `RenderBox.globalToLocal` expects.
  final Offset position;

  /// How many items the drag carries, as the host counts them.
  final int itemCount;
}

/// A completed drop.
@immutable
class HostDropEvent {
  /// Creates a [HostDropEvent].
  const HostDropEvent({
    required this.viewId,
    required this.position,
    required this.paths,
    required this.images,
  });

  /// The Flutter view the drop landed in.
  final int viewId;

  /// Where it landed, in that view's logical pixels.
  final Offset position;

  /// Local paths of the dropped files. The common case, and the cheap one: a
  /// path costs nothing to carry, whatever the file weighs.
  final List<String> paths;

  /// Raw picture bytes, for a drag that carried an image and no file behind it
  /// — what a browser or a design tool offers. Empty whenever [paths] is not.
  final List<Uint8List> images;

  /// Whether the drop carried nothing usable.
  bool get isEmpty => paths.isEmpty && images.isEmpty;
}

/// The host's file-drop feed.
///
/// A process-wide singleton because the channel is: the host has one drag at a
/// time and broadcasts it, and every interested widget decides for itself
/// whether the pointer is over it.
class HostFileDrop {
  HostFileDrop._();

  /// The instance.
  static final HostFileDrop instance = HostFileDrop._();

  static const MethodChannel _channel = MethodChannel(
    'com.controlcenter/filedrop',
  );

  /// Whether this platform's host reports drags.
  ///
  /// macOS only, and stated rather than probed: it is the platform whose bridge
  /// exists. Elsewhere the channel is simply never called, and the composer
  /// keeps its `DropRegion` — which on those hosts may well work, since the
  /// view-caching bug is specific to a headless engine.
  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  /// The drag in flight, or null. Never notifies with an equal value.
  final ValueNotifier<HostDragEvent?> dragging = ValueNotifier<HostDragEvent?>(
    null,
  );

  final StreamController<HostDropEvent> _drops =
      StreamController<HostDropEvent>.broadcast();

  /// Completed drops.
  Stream<HostDropEvent> get onDrop => _drops.stream;

  bool _started = false;

  /// Installs the channel handler. Idempotent, and safe to call from a widget's
  /// `initState` — the first caller wins and later ones are free.
  void start() {
    if (_started || !isSupported) {
      return;
    }
    _started = true;
    _channel.setMethodCallHandler(_handle);
  }

  Future<void> _handle(MethodCall call) async {
    final args = call.arguments;
    if (args is! Map) {
      return;
    }
    switch (call.method) {
      case 'over':
        dragging.value = HostDragEvent(
          viewId: _int(args['viewId']),
          position: Offset(_double(args['x']), _double(args['y'])),
          itemCount: _int(args['count']),
        );
      case 'exit':
        dragging.value = null;
      case 'drop':
        // Cleared FIRST: a listener that reacts to the drop by rebuilding
        // should not find a drag still apparently in flight.
        dragging.value = null;
        final event = HostDropEvent(
          viewId: _int(args['viewId']),
          position: Offset(_double(args['x']), _double(args['y'])),
          paths: [
            for (final path in (args['paths'] as List? ?? const []))
              if (path is String && path.isNotEmpty) path,
          ],
          images: [
            for (final image in (args['images'] as List? ?? const []))
              if (image is Uint8List && image.isNotEmpty) image,
          ],
        );
        if (!event.isEmpty) {
          _drops.add(event);
        }
      default:
        AppLog.d('file-drop', 'unknown host method ${call.method}');
    }
  }

  static int _int(Object? value) => value is int ? value : -1;

  static double _double(Object? value) => value is num ? value.toDouble() : 0;
}
