import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Counts the popup routes (dialogs, the ⌘P picker, confirm prompts) open on
/// the navigator it observes.
///
/// A widget that paints into the app's ROOT overlay — the one
/// `control_center_app.dart` wraps around the router — sits above every route
/// that navigator ever pushes, dialogs included. Such a layer reads [open] to
/// stand down while a popup covers the page it belongs to.
class PopupRouteTracker extends NavigatorObserver {
  /// How many popup routes are on the observed navigator right now.
  ValueListenable<int> get open => _open;
  final ValueNotifier<int> _open = ValueNotifier<int>(0);

  void _adjust(Route<dynamic>? route, int delta) {
    if (route is PopupRoute) {
      _open.value = (_open.value + delta).clamp(0, 1 << 20);
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _adjust(route, 1);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _adjust(route, -1);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _adjust(route, -1);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _adjust(oldRoute, -1);
    _adjust(newRoute, 1);
  }

  /// Releases the counter.
  void dispose() => _open.dispose();
}

/// The tracker observing the root navigator — the one `showCcDialog` pushes
/// onto. Wired into the router's `observers`; anywhere without it (a widget
/// test) simply never sees a popup.
final rootPopupRoutesProvider = Provider<PopupRouteTracker>((ref) {
  final tracker = PopupRouteTracker();
  ref.onDispose(tracker.dispose);
  return tracker;
});
