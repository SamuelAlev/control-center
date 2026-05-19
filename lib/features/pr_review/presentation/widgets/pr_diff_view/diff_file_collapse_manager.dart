import 'package:control_center/features/pr_review/domain/entities/pr_file.dart';
import 'package:flutter/material.dart';

/// Manages the collapsed/expanded and viewed state for individual diff files.
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

  /// Returns whether a file should start collapsed because its patch is large.
  static bool shouldAutoCollapse(PrFile file) {
    return patchLineCount(file.patch) > 500;
  }

  /// Counts the number of newline characters in [patch].
  static int patchLineCount(String patch) {
    if (patch.isEmpty) {
      return 0;
    }
    var count = 0;
    for (var i = 0; i < patch.length; i++) {
      if (patch[i] == '\n') {
        count++;
      }
    }
    return count;
  }
}
