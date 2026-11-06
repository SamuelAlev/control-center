import 'dart:typed_data';

import 'package:cc_domain/features/rigs/domain/ports/host_window_port.dart';

/// A [HostWindowPort] with the native layer's ownership rule and no OS.
///
/// The rule is reproduced rather than skipped, so a test can prove a refusal
/// reaches the caller and that nothing was sent.
class FakeHostWindowPort implements HostWindowPort {
  /// Creates a fake holding [windows].
  FakeHostWindowPort({List<HostWindow>? windows}) : windows = windows ?? [];

  /// Every window on the fake desktop, including other apps'.
  List<HostWindow> windows;

  /// The permission states [permissions] answers with.
  HostWindowPermissions granted = const HostWindowPermissions(
    screenCapture: HostWindowPermission.granted,
    input: HostWindowPermission.granted,
    accessibility: HostWindowPermission.granted,
  );

  /// Every input that passed the ownership check, in order.
  final List<HostWindowInput> inputs = [];

  /// The mode each of [inputs] arrived with.
  final List<HostWindowInputMode> modes = [];

  /// The `(maxWidth, maxHeight)` of each capture.
  final List<(int, int)> captures = [];

  /// Thrown by the next capture, then cleared when [failOnce].
  HostWindowException? captureFailure;

  /// Whether [captureFailure] clears after one capture.
  bool failOnce = false;

  /// Thrown by [sendInput] once this many inputs have landed.
  int? failInputAfter;

  /// What [readUi] answers.
  Map<String, dynamic> uiTree = const {};

  /// Thrown by [readUi] when set.
  HostWindowException? readUiFailure;

  HostWindow _owned(HostWindowScope scope, int windowId) {
    for (final window in windows) {
      if (window.id != windowId) {
        continue;
      }
      if (!scope.pids.contains(window.pid)) {
        throw HostWindowException(
          HostWindowFailure.notOwned,
          'Window $windowId does not belong to this app\'s processes.',
        );
      }
      return window;
    }
    throw HostWindowException(
      HostWindowFailure.notFound,
      'Window $windowId no longer exists.',
    );
  }

  @override
  Future<List<HostWindow>> listWindows(HostWindowScope scope) async => [
    for (final window in windows)
      if (scope.pids.contains(window.pid)) window,
  ];

  @override
  Future<HostWindowFrame> capture(
    HostWindowScope scope,
    int windowId, {
    required int maxWidth,
    required int maxHeight,
  }) async {
    final window = _owned(scope, windowId);
    captures.add((maxWidth, maxHeight));
    final failure = captureFailure;
    if (failure != null) {
      if (failOnce) {
        captureFailure = null;
      }
      throw failure;
    }
    var width = window.width;
    var height = window.height;
    if (width > maxWidth || height > maxHeight) {
      final fit = maxWidth / width < maxHeight / height
          ? maxWidth / width
          : maxHeight / height;
      width = (width * fit).floor();
      height = (height * fit).floor();
    }
    return HostWindowFrame(
      png: Uint8List.fromList([0x89, 0x50, 0x4e, 0x47]),
      width: width,
      height: height,
    );
  }

  @override
  Future<void> sendInput(
    HostWindowScope scope,
    int windowId,
    HostWindowInput input, {
    HostWindowInputMode mode = HostWindowInputMode.background,
  }) async {
    _owned(scope, windowId);
    final limit = failInputAfter;
    if (limit != null && inputs.length >= limit) {
      failInputAfter = null;
      throw const HostWindowException(
        HostWindowFailure.failed,
        'Input failed.',
      );
    }
    inputs.add(input);
    modes.add(mode);
  }

  @override
  Future<Map<String, dynamic>> readUi(
    HostWindowScope scope,
    int windowId, {
    int maxNodes = 500,
  }) async {
    _owned(scope, windowId);
    final failure = readUiFailure;
    if (failure != null) {
      throw failure;
    }
    return uiTree;
  }

  @override
  Future<HostWindowPermissions> permissions() async => granted;

  @override
  Future<void> openSettings(HostWindowSettingsPane pane) async {}
}

/// A window for tests, on screen unless told otherwise.
HostWindow fakeWindow({
  int id = 100,
  int pid = 4242,
  String title = 'Acme',
  int width = 800,
  int height = 600,
  bool isOnScreen = true,
}) => HostWindow(
  id: id,
  pid: pid,
  title: title,
  x: 40,
  y: 60,
  width: width,
  height: height,
  isOnScreen: isOnScreen,
);
