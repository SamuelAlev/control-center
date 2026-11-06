import 'package:cc_domain/features/rigs/domain/ports/host_window_port.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_action.dart';
import 'package:cc_natives/cc_natives.dart';

/// [HostWindowPort] over the `cc_window` native.
///
/// Resolves the library per call, so a host that exempts it (Windows, until CI
/// builds it) still boots and fails here, at use, with [CcWindowUnavailable].
class NativeHostWindowPort implements HostWindowPort {
  /// Creates a [NativeHostWindowPort].
  const NativeHostWindowPort();

  static CcWindowTarget _target(HostWindowScope scope, [int windowId = 0]) =>
      CcWindowTarget(
        pids: scope.pids.toList(growable: false),
        display: scope.display,
        windowId: windowId,
      );

  static Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on CcWindowFailure catch (e) {
      throw HostWindowException(_failureFor(e.status), e.message);
    }
  }

  static HostWindowFailure _failureFor(CcWindowStatus status) =>
      switch (status) {
        CcWindowStatus.invalid => HostWindowFailure.invalid,
        CcWindowStatus.notOwned => HostWindowFailure.notOwned,
        CcWindowStatus.notFound => HostWindowFailure.notFound,
        CcWindowStatus.permission => HostWindowFailure.permission,
        CcWindowStatus.offDisplay => HostWindowFailure.offDisplay,
        CcWindowStatus.outOfBounds => HostWindowFailure.outOfBounds,
        CcWindowStatus.unsupported => HostWindowFailure.unsupported,
        CcWindowStatus.failed => HostWindowFailure.failed,
        CcWindowStatus.timeout => HostWindowFailure.timeout,
      };

  static int _modifierBits(Set<HostWindowModifier> modifiers) {
    var bits = 0;
    for (final modifier in modifiers) {
      bits |= switch (modifier) {
        HostWindowModifier.shift => 1,
        HostWindowModifier.control => 2,
        HostWindowModifier.alt => 4,
        HostWindowModifier.meta => 8,
      };
    }
    return bits;
  }

  static HostWindowPermission _permission(Object? wire) => switch (wire) {
    'granted' => HostWindowPermission.granted,
    'not_required' => HostWindowPermission.notRequired,
    _ => HostWindowPermission.denied,
  };

  @override
  Future<List<HostWindow>> listWindows(HostWindowScope scope) =>
      _guard(() async {
        final rows = await CcWindow.require.list(_target(scope));
        return [
          for (final row in rows)
            HostWindow(
              id: (row['id'] as num).toInt(),
              pid: (row['pid'] as num).toInt(),
              title: row['title'] as String? ?? '',
              x: (row['x'] as num).round(),
              y: (row['y'] as num).round(),
              width: (row['width'] as num).round(),
              height: (row['height'] as num).round(),
              isOnScreen: row['on_screen'] as bool? ?? false,
            ),
        ];
      });

  @override
  Future<HostWindowFrame> capture(
    HostWindowScope scope,
    int windowId, {
    required int maxWidth,
    required int maxHeight,
  }) => _guard(() async {
    final image = await CcWindow.require.capture(
      _target(scope, windowId),
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
    return HostWindowFrame(
      png: image.png,
      width: image.width,
      height: image.height,
    );
  });

  @override
  Future<void> sendInput(
    HostWindowScope scope,
    int windowId,
    HostWindowInput input, {
    HostWindowInputMode mode = HostWindowInputMode.background,
  }) => _guard(() async {
    final native = CcWindow.require;
    final target = _target(scope, windowId);
    final wireMode = mode == HostWindowInputMode.foreground ? 1 : 0;
    switch (input) {
      case HostWindowPointerInput():
        await native.mouse(
          target,
          mode: wireMode,
          phase: switch (input.phase) {
            HostWindowPointerPhase.move => CcWindowPointerPhase.move,
            HostWindowPointerPhase.down => CcWindowPointerPhase.down,
            HostWindowPointerPhase.up => CcWindowPointerPhase.up,
            HostWindowPointerPhase.drag => CcWindowPointerPhase.drag,
          },
          button: switch (input.button) {
            RigMouseButton.left => 0,
            RigMouseButton.right => 1,
            RigMouseButton.middle => 2,
          },
          x: input.x.toDouble(),
          y: input.y.toDouble(),
          clickCount: input.clickCount,
          modifiers: _modifierBits(input.modifiers),
        );
      case HostWindowScrollInput():
        await native.scroll(
          target,
          mode: wireMode,
          x: input.x.toDouble(),
          y: input.y.toDouble(),
          dx: input.dx,
          dy: input.dy,
          modifiers: _modifierBits(input.modifiers),
        );
      case HostWindowKeyInput():
        await native.key(
          target,
          mode: wireMode,
          key: input.key,
          action: switch (input.phase) {
            HostWindowKeyPhase.tap => 0,
            HostWindowKeyPhase.down => 1,
            HostWindowKeyPhase.up => 2,
          },
          modifiers: _modifierBits(input.modifiers),
        );
      case HostWindowTextInput():
        await native.text(target, mode: wireMode, text: input.text);
    }
  });

  @override
  Future<Map<String, dynamic>> readUi(
    HostWindowScope scope,
    int windowId, {
    int maxNodes = 500,
  }) => _guard(
    () => CcWindow.require.readUi(_target(scope, windowId), maxNodes: maxNodes),
  );

  @override
  Future<HostWindowPermissions> permissions() => _guard(() async {
    final states = await CcWindow.require.permissions();
    return HostWindowPermissions(
      screenCapture: _permission(states['screen_capture']),
      input: _permission(states['input']),
      accessibility: _permission(states['accessibility']),
    );
  });

  @override
  Future<void> openSettings(HostWindowSettingsPane pane) => _guard(
    () => CcWindow.require.openSettings(switch (pane) {
      HostWindowSettingsPane.screenCapture => 0,
      HostWindowSettingsPane.accessibility => 1,
    }),
  );
}
