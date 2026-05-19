import 'package:control_center/features/messaging/providers/repo_content_search_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which axis the Explorer searches: file names/paths, or file contents.
enum ExplorerSearchMode {
  /// Fuzzy-match the query against file names/paths (the default; empty query
  /// shows the lazy per-repo tree).
  filename,

  /// Grep the query across file contents, grouping matching lines per file.
  content,
}

/// The Explorer panel's view state, held OUTSIDE the panel's `State`.
///
/// The IDE sidebar picks its panel with a `switch` on the selected view, so
/// looking at Source Control unmounts the Explorer's element and rebuilds it
/// from scratch on the way back. While this lived in `State`, every re-entry
/// reset the operator to "all repo roots expanded, every folder below them
/// collapsed, no query" and re-listed the tree — the panel could never be
/// cheaper to return to than it was to open the first time.
///
/// Deliberately MUTABLE and deliberately not a `Notifier`: the panel already
/// calls `setState` for its own repaint, and a listenable here would rebuild
/// every reader on each expand/collapse and each debounced keystroke for no
/// one's benefit. Nothing else reads it.
class ExplorerViewState {
  /// Expanded sub-directory keys (`'<repoId>:<relativePath>'`). Membership =
  /// expanded. Empty → all sub-dirs collapsed (VS Code-like).
  final Set<String> expandedDirs = <String>{};

  /// Collapsed repo-root ids. Membership = collapsed. Empty → all repo roots
  /// expanded (which is what arms their first directory listing).
  final Set<String> collapsedRepos = <String>{};

  /// Filename vs content search (the trailing toggle button swaps surfaces).
  ExplorerSearchMode mode = ExplorerSearchMode.filename;

  /// The committed (debounced) query. Also seeds the search field's text on a
  /// remount, so a restored query and the box above it cannot disagree.
  String query = '';

  /// Content-search options (case/regex/whole-word + include/exclude globs).
  ContentSearchOptions options = const ContentSearchOptions();

  /// Whether the include/exclude glob row is shown.
  bool showFilters = false;
}

/// One [ExplorerViewState] per workspace, outliving the panel that reads it.
///
/// Not `autoDispose` — surviving the panel is the entire point. The value is a
/// handful of small sets per workspace the operator has actually opened.
final explorerViewStateProvider = Provider.family<ExplorerViewState, String>(
  (ref, workspaceId) => ExplorerViewState(),
);
