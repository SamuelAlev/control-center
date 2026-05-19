import 'dart:async';

import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/services/diff_parser.dart';
import 'package:flutter/material.dart';

/// Pr diff search controller.
class PrDiffSearchController {
  /// Creates a new [Pr diff search controller].
  PrDiffSearchController({
    required this.files,
    required this.onChanged,
    required this.fileStateKeys,
    required this.activeScrollPositionGetter,
    required this.estimatedFileTopGetter,
    required this.onInsertOverlay,
    required this.onRemoveOverlay,
  });

  /// Files being searched.
  List<PrFile> files;

  /// Called when match data changes.
  final VoidCallback onChanged;

  /// Parsed-diff cache keyed by filename. Populated lazily on the first
  /// search that targets a given file — keeps re-typing in the search box
  /// from re-parsing every patch on every keystroke. Stale entries for
  /// files no longer in [files] are harmless (just unread).
  final Map<String, List<DiffLine>> _parsedByFilename = {};

  /// Map<String,.
  final Map<String, GlobalKey> fileStateKeys;

  /// Position.
  final ScrollPosition? Function() activeScrollPositionGetter;

  /// Estimated Y offset of a file in the scroll view.
  final double Function(int) estimatedFileTopGetter;

  /// Called to insert the search overlay entry.
  final void Function(OverlayEntry) onInsertOverlay;

  /// Called to remove the search overlay entry.
  final void Function(OverlayEntry) onRemoveOverlay;

  /// Whether the search UI is visible.
  bool searchOpen = false;

  /// Current query string.
  String searchQuery = '';

  /// Debounce timer for search input.
  Timer? searchDebounce;

  /// Active search overlay entry.
  OverlayEntry? searchOverlay;

  /// Focus node.
  final FocusNode searchFocus = FocusNode();

  /// Text controller.
  final TextEditingController searchCtrl = TextEditingController();

  /// Total number of matches across all files.
  int totalMatches = 0;

  /// 1-based index of the currently focused match.
  int currentMatchIdx = 0;

  /// List of all match file/line coordinates.
  final List<SearchMatch> matchLocations = [];

  /// Key for the current match widget for ensureVisible.
  GlobalKey? currentMatchKey;

  /// Estimated height of a collapsed file header.
  static const double collapsedFileHeightEstimate = 52;

  /// Vertical padding between files.
  static const double filePaddingBetween = 16;

  /// Height of the diff toolbar.
  static const double toolbarHeight = 48;

  /// Rebuilds match list from [searchQuery].
  void updateMatchData() {
    matchLocations.clear();
    currentMatchKey = null;
    totalMatches = 0;
    currentMatchIdx = 0;
    if (searchQuery.isEmpty) {
      return;
    }

    final lowerQuery = searchQuery.toLowerCase();
    for (var fi = 0; fi < files.length; fi++) {
      final file = files[fi];
      if (file.patch.isEmpty) {
        continue;
      }
      // Cheap pre-filter: a substring not present in the raw patch can't
      // be present in any parsed line. Skips parseUnifiedDiff entirely for
      // the vast majority of files on a typical query.
      if (!file.patch.toLowerCase().contains(lowerQuery)) {
        continue;
      }

      final lines = _parsedByFilename.putIfAbsent(
        file.filename,
        () => parseUnifiedDiff(file.patch),
      );
      for (var li = 0; li < lines.length; li++) {
        if (lines[li].content.toLowerCase().contains(lowerQuery)) {
          matchLocations.add(SearchMatch(fileIndex: fi, lineIndex: li));
          totalMatches++;
        }
      }
    }
    if (totalMatches > 0) {
      currentMatchIdx = 1;
      currentMatchKey = GlobalKey();
    }
  }

  /// Jumps to the match offset by [delta].
  void goToMatch(int delta) {
    if (totalMatches == 0) {
      return;
    }

    var next = currentMatchIdx + delta;
    if (next < 1) {
      next = totalMatches;
    }

    if (next > totalMatches) {
      next = 1;
    }

    currentMatchIdx = next;
    currentMatchKey = GlobalKey();

    final match = matchLocations[currentMatchIdx - 1];
    // The canvas viewer (`FastDiffView`) always paints every line in its
    // file, so no `ensureLineRendered` plumbing is needed any more.
    onChanged();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToCurrentMatch(match);
    });
  }

  /// Jumps to the next match.
  void goToNextMatch() => goToMatch(1);

  /// Jumps to the previous match.
  void goToPrevMatch() => goToMatch(-1);

  /// Scrolls the viewport to the current match.
  void scrollToCurrentMatch(SearchMatch match) {
    final ctx = currentMatchKey?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.25,
        duration: const Duration(milliseconds: 200),
      );
      return;
    }
    final position = activeScrollPositionGetter();
    if (position == null) {
      return;
    }

    final estimatedTop = estimatedFileTopGetter(match.fileIndex);
    final target = estimatedTop.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    position.jumpTo(target);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx2 = currentMatchKey?.currentContext;
      if (ctx2 != null) {
        Scrollable.ensureVisible(
          ctx2,
          alignment: 0.25,
          duration: const Duration(milliseconds: 200),
        );
      }
    });
  }

  /// Opens the search overlay and requests focus.
  void openSearch() {
    if (searchOpen) {
      searchFocus.requestFocus();
      searchCtrl.selection = TextSelection(
        baseOffset: 0,
        extentOffset: searchCtrl.text.length,
      );
      return;
    }
    searchOpen = true;
    onChanged();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      searchFocus.requestFocus();
    });
  }

  /// Closes the search overlay and clears state.
  void closeSearch() {
    if (!searchOpen) {
      return;
    }

    searchDebounce?.cancel();
    onRemoveOverlay(searchOverlay!);
    matchLocations.clear();
    currentMatchKey = null;
    searchOpen = false;
    searchQuery = '';
    totalMatches = 0;
    currentMatchIdx = 0;
    onChanged();
    searchCtrl.clear();
  }

  /// Debounced handler for query text changes.
  void onSearchChanged(String value) {
    searchDebounce?.cancel();
    if (value.isEmpty) {
      searchQuery = '';
      updateMatchData();
      onChanged();
      return;
    }
    searchDebounce = Timer(const Duration(milliseconds: 50), () {
      searchQuery = value;
      updateMatchData();
      onChanged();
    });
  }

  /// Cleans up timers, overlays, and controllers.
  void dispose() {
    searchDebounce?.cancel();
    searchOverlay?.remove();
    searchOverlay = null;
    searchFocus.dispose();
    searchCtrl.dispose();
  }
}

/// Search match.
class SearchMatch {
  /// SearchMatch({required.
  const SearchMatch({required this.fileIndex, required this.lineIndex});

  /// Index of the file containing the match.
  final int fileIndex;

  /// Index of the line within the file.
  final int lineIndex;
}
