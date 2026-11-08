import 'package:flutter/widgets.dart';

/// What the tray panel asks of the app. The presenter implements it: it owns
/// the main window, the router and the panel's own lifetime.
abstract interface class TrayPanelActions {
  /// Shows the main window as it was.
  void openApp();

  /// Shows the main window on [route].
  void openRoute(String route);

  /// Shows the main window on the Desktop app settings.
  void openSettings();

  /// Makes [workspaceId] the active workspace, as the title-bar chip does,
  /// without showing the main window: the panel follows it.
  void switchWorkspace(String workspaceId);

  /// Quits the app.
  void quit();

  /// Closes the panel. [returnFocus] hands the keyboard back to the app that
  /// had it before the panel opened (an Escape, not a click elsewhere, which
  /// already moved it).
  void dismiss({bool returnFocus = false});
}

/// Hands [actions] to the panel's widgets.
class TrayPanelScope extends InheritedWidget {
  /// Creates a [TrayPanelScope].
  const TrayPanelScope({
    required this.actions,
    required super.child,
    super.key,
  });

  /// The presenter's actions.
  final TrayPanelActions actions;

  /// The nearest scope's actions.
  static TrayPanelActions of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<TrayPanelScope>();
    assert(scope != null, 'No TrayPanelScope above this widget');
    return scope!.actions;
  }

  @override
  bool updateShouldNotify(TrayPanelScope oldWidget) =>
      !identical(actions, oldWidget.actions);
}
