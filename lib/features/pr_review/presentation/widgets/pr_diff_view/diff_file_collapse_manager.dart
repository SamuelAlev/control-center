import 'package:flutter/widgets.dart';

/// Manages stable keys and viewed state for individual diff files.
class PrDiffFileCollapseManager {
  /// Creates a collapse manager.
  PrDiffFileCollapseManager({this.onToggleViewed});

  /// Called when a file's viewed state is toggled.
  final void Function({required String path, required bool viewed})?
  onToggleViewed;

  final Map<String, bool> _viewedPaths = {};
  final Map<String, Key> _keys = {};

  /// Returns a stable key for the given file path.
  Key getFileKey(String path) {
    return _keys.putIfAbsent(path, () => ValueKey('file-header-$path'));
  }

  /// Returns whether the given path is marked as viewed.
  bool isViewed(String path) {
    return _viewedPaths[path] ?? false;
  }

  /// Toggles the viewed state for [path] and calls [setState].
  void toggleViewed(String path, VoidCallback setState) {
    final currentlyViewed = _viewedPaths[path] ?? false;
    final next = !currentlyViewed;
    if (next) {
      _viewedPaths[path] = true;
    } else {
      _viewedPaths.remove(path);
    }
    setState();
    onToggleViewed?.call(path: path, viewed: next);
  }

  /// Returns the set of currently viewed paths.
  Set<String> get viewedPaths => {..._viewedPaths.keys};
}
