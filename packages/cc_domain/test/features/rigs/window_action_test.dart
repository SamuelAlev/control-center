import 'package:cc_domain/features/rigs/domain/ports/host_window_port.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/computer_action.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/enclosure_backend.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_action.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_spec.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/window_action.dart';
import 'package:test/test.dart';

void main() {
  RigAction parsed(Map<String, dynamic> args) =>
      (WindowAction.parse(args) as RigActionParsed).action;

  group('WindowAction.parse', () {
    test('reads the window verbs', () {
      expect(parsed({'action': 'list_windows'}), isA<WindowList>());
      expect(parsed({'action': 'read_ui'}), isA<WindowReadUi>());
      expect(
        parsed({'action': 'select_window', 'window_id': 7}),
        const WindowSelect(7),
      );
    });

    test('select_window needs an id', () {
      final result = WindowAction.parse({'action': 'select_window'});
      expect((result as RigActionInvalid).message, contains('window_id'));
    });

    test('hands every other verb to the computer vocabulary', () {
      expect(parsed({'action': 'screenshot'}), isA<ComputerScreenshot>());
      expect(
        parsed({
          'action': 'left_click',
          'coordinate': [1, 2],
        }),
        isA<ComputerClick>(),
      );
    });

    test('an unknown or missing verb is invalid, never a throw', () {
      expect(
        WindowAction.parse({'action': 'explode'}),
        isA<RigActionInvalid>(),
      );
      expect(WindowAction.parse(const {}), isA<RigActionInvalid>());
    });
  });

  test('looking is allowed under take-over, switching windows is not', () {
    expect(const WindowList().mutatesGuest, isFalse);
    expect(const WindowReadUi().mutatesGuest, isFalse);
    expect(const WindowSelect(1).mutatesGuest, isTrue);
  });

  test('the surface round-trips and has a fixed display', () {
    expect(RigSurface.fromWire('window'), RigSurface.window);
    expect(RigSurface.window.hasResizableDisplay, isFalse);
  });

  test('the backend claims no containment', () {
    expect(
      EnclosureBackend.fromWire('host-window'),
      EnclosureBackend.hostWindow,
    );
    expect(EnclosureBackend.hostWindow.hasEnforcedEgress, isFalse);
    expect(EnclosureBackend.hostWindow.isQemu, isFalse);
  });

  test('a window spec is valid with default resources', () {
    final spec = RigSpec(surface: RigSurface.window, slotId: 'desktop');
    expect(spec.memoryMb, 128);
    expect(spec.cpuCount, 1);
  });

  group('HostWindowScope', () {
    test('refuses a set that cannot own anything safely', () {
      expect(() => HostWindowScope(pids: {}), throwsArgumentError);
      expect(() => HostWindowScope(pids: {1}), throwsArgumentError);
      expect(() => HostWindowScope(pids: {0, 4242}), throwsArgumentError);
    });

    test('is compared by content, whatever the order', () {
      expect(
        HostWindowScope(pids: {10, 20}, display: ':7'),
        HostWindowScope(pids: {20, 10}, display: ':7'),
      );
      expect(
        HostWindowScope(pids: {10}, display: ':7'),
        isNot(HostWindowScope(pids: {10}, display: ':8')),
      );
    });

    test('cannot be widened after it is made', () {
      final scope = HostWindowScope(pids: {10});
      expect(() => scope.pids.add(20), throwsUnsupportedError);
    });
  });

  test('input modes parse from the wire', () {
    expect(
      HostWindowInputMode.fromWire('foreground'),
      HostWindowInputMode.foreground,
    );
    expect(HostWindowInputMode.fromWire('sideways'), isNull);
  });
}
