import 'dart:async';

import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Pr diff keyboard handler.
class PrDiffKeyboardHandler {
  /// Creates a new [Pr diff keyboard handler].
  PrDiffKeyboardHandler({
    required this.files,
    required this.searchOpenGetter,
    required this.activeScrollPositionGetter,
    required this.revealOffsetGetter,
    required this.fileStateKeys,
    required this.onOpenSearch,
    required this.onCloseSearch,
    required this.onGoToNextMatch,
    required this.onGoToPrevMatch,
    required this.onFullRefresh,
    this.onToggleViewedForPath,
    this.onToggleCollapseForPath,
    this.onCopy,
    this.onClearSelection,
  });

  /// Files being navigated.
  List<PrFile> files;

  /// Whether the find-in-diff search is open.
  final bool Function() searchOpenGetter;

  /// Position.
  final ScrollPosition? Function() activeScrollPositionGetter;

  /// Scroll offset that reveals file i with its header below the pinned tab strip.
  final double Function(int) revealOffsetGetter;

  /// Keys used to scroll individual files into view.
  final Map<String, GlobalKey> fileStateKeys;

  /// Called to open the diff search overlay.
  final VoidCallback onOpenSearch;

  /// Called to close the diff search overlay.
  final VoidCallback onCloseSearch;

  /// Called to jump to the next search match.
  final VoidCallback onGoToNextMatch;

  /// Called to jump to the previous search match.
  final VoidCallback onGoToPrevMatch;

  /// Called to force a full widget rebuild.
  final VoidCallback onFullRefresh;

  /// Called with the focused file's path when the user presses `v` to mark
  /// it as viewed/unviewed.
  final void Function(String path)? onToggleViewedForPath;

  /// Called with the focused file's path when the user presses `c` to
  /// collapse or expand it.
  final void Function(String path)? onToggleCollapseForPath;

  /// Called on Cmd/Ctrl+C (outside a text field) to copy the active diff
  /// selection. Returns true if something was copied.
  final bool Function()? onCopy;

  /// Called on Escape (outside a text field, with no search open) to clear the
  /// active diff text selection. Returns true if a selection was cleared.
  final bool Function()? onClearSelection;

  /// Index of the file currently focused by keyboard nav.
  int focusedFileIndex = 0;

  /// Handles Cmd+F, Esc, Enter, J/K keys.
  bool handleGlobalKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return false;
    }

    final isMeta = HardwareKeyboard.instance.isMetaPressed;
    final isCtrl = HardwareKeyboard.instance.isControlPressed;
    final isShift = HardwareKeyboard.instance.isShiftPressed;
    final searchOpen = searchOpenGetter();

    if (event.logicalKey == LogicalKeyboardKey.keyF && (isMeta || isCtrl)) {
      onOpenSearch();
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyC &&
        (isMeta || isCtrl) &&
        event is KeyDownEvent &&
        onCopy != null &&
        !_focusInEditable()) {
      // Copy the diff selection; if there's nothing selected, let the event
      // fall through (return false) so other handlers can act on it.
      if (onCopy!()) {
        return true;
      }
    }
    if (event.logicalKey == LogicalKeyboardKey.escape && searchOpen) {
      onCloseSearch();
      return true;
    }
    // Escape with no search open clears any active text selection. Falls
    // through (returns false) when there's nothing selected, so other Escape
    // handlers (e.g. closing an inline composer) still get the event.
    if (event.logicalKey == LogicalKeyboardKey.escape &&
        event is KeyDownEvent &&
        !searchOpen &&
        onClearSelection != null &&
        !_focusInEditable()) {
      if (onClearSelection!()) {
        return true;
      }
    }
    if (searchOpen && event.logicalKey == LogicalKeyboardKey.enter) {
      if (isShift) {
        onGoToPrevMatch();
      } else {
        onGoToNextMatch();
      }
      return true;
    }
    final isPlainKey = !isMeta && !isCtrl && !isShift;
    if (isPlainKey && !searchOpen && !_focusInEditable()) {
      if (event.logicalKey == LogicalKeyboardKey.keyJ) {
        unawaited(stepToFile(1));
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyK) {
        unawaited(stepToFile(-1));
        return true;
      }
      // Toggle actions ignore key-repeat: holding the key would otherwise
      // flip the state on every repeat tick, producing a visible flash and
      // racing the network mutation against itself.
      final isInitialPress = event is KeyDownEvent;
      if (event.logicalKey == LogicalKeyboardKey.keyV && isInitialPress) {
        final path = _focusedPath();
        if (path != null && onToggleViewedForPath != null) {
          onToggleViewedForPath!(path);
          // Advance to the next file (if any) after the toggle's collapse
          // has been laid out, so [_resolvedFileTop] reads the new layout
          // and doesn't over-scroll past the next file.
          if (focusedFileIndex + 1 < files.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              unawaited(stepToFile(1));
            });
          }
          return true;
        }
      }
      if (event.logicalKey == LogicalKeyboardKey.keyC && isInitialPress) {
        final path = _focusedPath();
        if (path != null && onToggleCollapseForPath != null) {
          onToggleCollapseForPath!(path);
          return true;
        }
      }
    }
    return false;
  }

  /// Path of the file currently under the keyboard cursor, re-synced to the
  /// scroll position so `v`/`c` always act on whatever the user is viewing.
  String? _focusedPath() {
    if (files.isEmpty) {
      return null;
    }
    final position = activeScrollPositionGetter();
    if (position != null) {
      focusedFileIndex = _findFileAtOffset(position.pixels);
    } else {
      focusedFileIndex = focusedFileIndex.clamp(0, files.length - 1);
    }
    return files[focusedFileIndex].filename;
  }

  bool _focusInEditable() {
    final focused = FocusManager.instance.primaryFocus?.context;
    if (focused == null) {
      return false;
    }

    return focused.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  /// Moves keyboard focus by [delta] files and scrolls to it.
  Future<void> stepToFile(int delta) async {
    if (files.isEmpty) {
      return;
    }

    final position = activeScrollPositionGetter();
    if (position == null) {
      return;
    }

    // Always re-anchor the cursor to whatever file the scroll position is
    // currently inside. Without this, manual scrolling (or the small drift
    // between estimated and actually-rendered file tops after ensureVisible)
    // leaves [focusedFileIndex] pointing at a file the user is no longer
    // viewing, and `focusedFileIndex + delta` jumps relative to the wrong
    // anchor — so J can scroll back to the same file.
    focusedFileIndex = _findFileAtOffset(position.pixels);

    final next = (focusedFileIndex + delta).clamp(0, files.length - 1);
    if (next == focusedFileIndex && delta != 0) {
      return;
    }

    focusedFileIndex = next;

    final targetPath = files[focusedFileIndex].filename;
    final targetKey = fileStateKeys[targetPath];
    final target = revealOffsetGetter(focusedFileIndex);
    await position.animateTo(
      target.clamp(position.minScrollExtent, position.maxScrollExtent),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = targetKey?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.0,
          duration: const Duration(milliseconds: 150),
        );
      }
    });
  }

  int _findFileAtOffset(double offset) {
    // Walk backwards: the focused file is the last one whose reveal offset is at
    // or above the current scroll offset. Uses the same reveal metric as the
    // scroll target (header docked below the pinned tab strip) so the anchor and
    // the target are exact inverses — otherwise the re-anchor lands a file early
    // and j/k re-scrolls to the file already shown.
    const tolerance = 4.0;
    for (var i = files.length - 1; i >= 0; i--) {
      if (revealOffsetGetter(i) <= offset + tolerance) {
        return i;
      }
    }
    return 0;
  }

  /// Immediately scrolls to the file at [index].
  Future<void> jumpToFile(int index) async {
    final position = activeScrollPositionGetter();
    if (position == null) {
      return;
    }

    focusedFileIndex = index.clamp(0, files.length - 1);
    final target = revealOffsetGetter(
      focusedFileIndex,
    ).clamp(position.minScrollExtent, position.maxScrollExtent);
    onFullRefresh();
    final targetPath = files[focusedFileIndex].filename;
    final targetKey = fileStateKeys[targetPath];
    await position.animateTo(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = targetKey?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.0,
          duration: const Duration(milliseconds: 150),
        );
      }
    });
  }
}
