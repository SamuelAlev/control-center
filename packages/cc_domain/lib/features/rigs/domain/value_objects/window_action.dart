import 'package:cc_domain/features/rigs/domain/value_objects/computer_action.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_action.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';

/// The verbs only the window surface has.
///
/// Everything else a window rig does is a [ComputerAction]: the point of
/// sharing that vocabulary is that a model already knows it, so [parse] hands
/// any other verb to [ComputerAction.parse].
sealed class WindowAction extends RigAction {
  /// Const base constructor.
  const WindowAction();

  @override
  RigSurface get surface => RigSurface.window;

  /// Parses an untrusted `{action, ...}` payload. Total, like
  /// [ComputerAction.parse].
  static RigActionParse parse(Map<String, dynamic> args) {
    switch (rigOptString(args, 'action')) {
      case 'list_windows':
        return const RigActionParsed(WindowList());
      case 'read_ui':
        return const RigActionParsed(WindowReadUi());
      case 'select_window':
        final id = rigOptInt(args, 'window_id');
        if (id == null) {
          return const RigActionInvalid(
            'Missing or invalid argument: window_id (expected an id from '
            'list_windows)',
          );
        }
        return RigActionParsed(WindowSelect(id));
      default:
        return ComputerAction.parse(args);
    }
  }
}

/// List the app's windows.
class WindowList extends WindowAction {
  /// Creates a [WindowList].
  const WindowList();

  @override
  String get verb => 'list_windows';

  @override
  bool get mutatesGuest => false;

  @override
  Map<String, dynamic> toJson() => {'action': verb};

  @override
  String get summary => 'Listed the windows';
}

/// Choose which window later actions and the viewer use.
///
/// Counts as a mutation although the app never hears of it: the viewer follows
/// the selection, so an agent must not switch the window under a person who
/// has taken control.
class WindowSelect extends WindowAction {
  /// Creates a [WindowSelect].
  const WindowSelect(this.windowId);

  /// The chosen window.
  final int windowId;

  @override
  String get verb => 'select_window';

  @override
  Map<String, dynamic> toJson() => {'action': verb, 'window_id': windowId};

  @override
  String get summary => 'Selected window $windowId';
}

/// Read the window's accessibility tree.
class WindowReadUi extends WindowAction {
  /// Creates a [WindowReadUi].
  const WindowReadUi();

  @override
  String get verb => 'read_ui';

  @override
  bool get mutatesGuest => false;

  @override
  Map<String, dynamic> toJson() => {'action': verb};

  @override
  String get summary => 'Read the UI tree';
}
