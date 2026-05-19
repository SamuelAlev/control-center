import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/providers/repo_content_search_provider.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_sidebar_filter_controls.dart';
import 'package:control_center/features/pr_review/providers/pr_worktree_search_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The PR diff sidebar's "search in files" mode: a **content** search
/// (`git grep`, tracked + untracked) across the PR's isolated CoW worktree
/// (server-side), grouped per file, with case/regex/whole-word toggles and
/// include/exclude folder filters. Filename filtering lives in the file tree's
/// filter field. Sits behind ⌘F / the tree's search toggle; the trailing
/// "show file list" button (and Esc) return to the tree.
///
/// Results are scoped to the PR-head worktree — the same tree the user edits —
/// so any match jumps to a code-server tab via [onOpenResult], even for files
/// that aren't part of the diff.
class PrWorktreeSearchPanel extends ConsumerStatefulWidget {
  /// Creates a [PrWorktreeSearchPanel].
  const PrWorktreeSearchPanel({
    super.key,
    required this.workspaceId,
    required this.channelId,
    required this.repoId,
    required this.focusToken,
    required this.onShowFileTree,
    required this.onOpenResult,
    this.prTouchedPaths = const {},
  });

  /// Workspace owning the channel/worktree (isolation enforced server-side).
  final String workspaceId;

  /// The PR channel whose worktree is searched.
  final String channelId;

  /// The repo whose worktree is searched.
  final String repoId;

  /// Repo-relative paths the PR touches. Matching files are listed FIRST in the
  /// results (stable partition), so the diff's own files surface ahead of
  /// incidental worktree matches. Empty when unknown (no reordering).
  final Set<String> prTouchedPaths;

  /// Bumped by the host (⌘F, the tree's search button) to (re)focus + select
  /// the query field when the panel is revealed.
  final int focusToken;

  /// Returns to the file-tree mode (the trailing button + Esc).
  final VoidCallback onShowFileTree;

  /// Opens a result in an editable tab — a content match jumps to its 1-based
  /// `line`; a filename hit opens the file at the top (no line).
  final void Function(String path, {int? line}) onOpenResult;

  @override
  ConsumerState<PrWorktreeSearchPanel> createState() =>
      _PrWorktreeSearchPanelState();
}

class _PrWorktreeSearchPanelState extends ConsumerState<PrWorktreeSearchPanel> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  /// Debounced query actually sent to the server.
  String _query = '';
  Timer? _debounce;

  /// Content-search options (case/regex/whole-word + include/exclude globs).
  ContentSearchOptions _options = const ContentSearchOptions();

  /// Whether the include/exclude glob row is shown (content mode).
  bool _showFilters = false;

  /// Controllers for the include/exclude glob fields (kept across toggles so a
  /// user's typed globs survive a collapse/expand).
  final _includeController = TextEditingController();
  final _excludeController = TextEditingController();
  Timer? _filtersDebounce;

  /// Content-result paths the user has collapsed (defaults open).
  final _collapsed = <String>{};

  /// Last non-empty result set, kept on screen while the next query loads so
  /// results don't flicker to a spinner on each keystroke.
  List<FileContentMatch> _lastContent = const [];

  /// Retained across the per-keystroke result swap + collapse toggles so the
  /// list keeps a stable offset instead of the implicit controller re-anchoring
  /// (a source of the scroll "jumping"). `primary: false` keeps it off the
  /// ambient PrimaryScrollController.
  final _resultsController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Restore this channel's last query/options: the panel unmounts on every
    // tree↔search toggle, so its ephemeral state lives in a per-channel
    // provider (see [prWorktreeSearchUiStateProvider]) and is written through
    // on every change.
    final saved = ref.read(prWorktreeSearchUiStateProvider(widget.channelId));
    _controller.text = saved.text;
    _query = saved.text.trim();
    _options = saved.options;
    _showFilters = saved.showFilters;
    _includeController.text = saved.options.include;
    _excludeController.text = saved.options.exclude;
    // Autofocus on first reveal.
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusAndSelect());
  }

  /// Write-through of the panel's UI state so it survives the next unmount.
  void _persist() {
    ref.read(prWorktreeSearchUiStateProvider(widget.channelId).notifier).state =
        (text: _controller.text, options: _options, showFilters: _showFilters);
  }

  @override
  void didUpdateWidget(PrWorktreeSearchPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusToken != widget.focusToken) {
      _focusAndSelect();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _filtersDebounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _includeController.dispose();
    _excludeController.dispose();
    _resultsController.dispose();
    super.dispose();
  }

  /// Snaps the results list back to the top — a fresh query returns an entirely
  /// different set, so inheriting the previous offset would land mid-list (and
  /// read as a "jump"). Deferred past the frame that swaps the content.
  void _resetScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_resultsController.hasClients) {
        _resultsController.jumpTo(0);
      }
    });
  }

  void _focusAndSelect() {
    if (!mounted) {
      return;
    }
    _focusNode.requestFocus();
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    // Persist immediately (not after the debounce) so a toggle away within the
    // debounce window still keeps what was typed.
    _persist();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() => _query = '');
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (mounted && trimmed != _query) {
        setState(() => _query = trimmed);
        _resetScroll();
      }
    });
  }

  /// The field's clear (×) button: drops the query immediately and returns
  /// focus to the field so a new search can be typed right away.
  void _clearQuery() {
    _debounce?.cancel();
    setState(() {
      _query = '';
      _lastContent = const [];
    });
    _persist();
    _focusNode.requestFocus();
  }

  /// Applies discrete option toggles (case/regex/word) immediately.
  void _setOptions(ContentSearchOptions options) {
    setState(() => _options = options);
    _persist();
  }

  /// Debounces the include/exclude glob fields into [_options].
  void _syncFilters(String _) {
    _filtersDebounce?.cancel();
    _filtersDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _options = _options.copyWith(
          include: _includeController.text,
          exclude: _excludeController.text,
        );
      });
      _persist();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);

    final (loading, body) = _contentView(l10n, tokens);

    // The disclosure reads "active" while expanded, or when a collapsed glob
    // filter is still applied.
    final filtersActive =
        _showFilters ||
        _options.include.trim().isNotEmpty ||
        _options.exclude.trim().isNotEmpty;

    return ColoredBox(
      color: tokens.bgPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SearchBar(
            controller: _controller,
            focusNode: _focusNode,
            options: _options,
            loading: loading,
            onChanged: _onChanged,
            onClear: _clearQuery,
            onOptionsChanged: _setOptions,
            onClose: widget.onShowFileTree,
          ),
          PrSidebarFilterToggle(
            label: l10n.ideSearchFilters,
            active: filtersActive,
            onToggle: () {
              setState(() => _showFilters = !_showFilters);
              _persist();
            },
          ),
          if (_showFilters)
            _FilterFields(
              includeController: _includeController,
              excludeController: _excludeController,
              onChanged: _syncFilters,
            ),
          Container(height: 1, color: tokens.borderSecondary),
          Expanded(child: body),
        ],
      ),
    );
  }

  /// Content mode: grouped `git grep` matches, with no-flicker retention.
  /// Returns `(loading, body)`.
  (bool, Widget) _contentView(
    AppLocalizations l10n,
    DesignSystemTokens tokens,
  ) {
    final async = _query.isEmpty
        ? const AsyncValue<List<FileContentMatch>>.data([])
        : ref.watch(
            prWorktreeSearchProvider((
              workspaceId: widget.workspaceId,
              channelId: widget.channelId,
              repoId: widget.repoId,
              query: _query,
              options: _options,
            )),
          );
    final raw = async.maybeWhen(
      data: (r) {
        _lastContent = r;
        return r;
      },
      orElse: () => _lastContent,
    );
    final results = _touchedFirst(raw);
    final loading = async.isLoading && _query.isNotEmpty;

    final Widget body;
    if (_query.isEmpty) {
      body = _Hint(message: l10n.searchInFilesHint);
    } else if (results.isEmpty && !loading) {
      body = _Hint(message: l10n.searchNoResults);
    } else {
      // Flatten (file header + its visible match lines) into a single uniform
      // row stream. Nesting each file's matches inside one variable-height list
      // item wrecked ListView's off-screen extent estimate (a 1-match file next
      // to a 50-match file), so scrolling jumped as estimates were corrected.
      // One item per row keeps heights uniform → smooth, stable scrolling.
      final rows = <_SearchRow>[];
      for (final group in results) {
        rows.add(_SearchRow.header(group));
        if (!_collapsed.contains(group.relativePath)) {
          for (final match in group.lines) {
            rows.add(_SearchRow.match(group, match));
          }
        }
      }
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ResultsHeader(
            matchCount: results.fold<int>(0, (s, f) => s + f.lines.length),
            fileCount: results.length,
          ),
          Expanded(
            child: ListView.builder(
              controller: _resultsController,
              primary: false,
              padding: EdgeInsets.zero,
              itemCount: rows.length,
              itemBuilder: (context, i) {
                final row = rows[i];
                final group = row.group;
                final match = row.match;
                if (match == null) {
                  final collapsed = _collapsed.contains(group.relativePath);
                  return _ResultHeader(
                    key: ValueKey('h:${group.relativePath}'),
                    group: group,
                    collapsed: collapsed,
                    onToggle: () => setState(() {
                      if (collapsed) {
                        _collapsed.remove(group.relativePath);
                      } else {
                        _collapsed.add(group.relativePath);
                      }
                    }),
                  );
                }
                return _MatchRow(
                  key: ValueKey('m:${group.relativePath}:${match.line}'),
                  match: match,
                  query: _query,
                  onTap: () =>
                      widget.onOpenResult(group.relativePath, line: match.line),
                );
              },
            ),
          ),
        ],
      );
    }
    return (loading, body);
  }

  /// Stable partition: files the PR touches first (preserving server order
  /// within each partition), then the rest. A no-op when
  /// [PrWorktreeSearchPanel.prTouchedPaths] is empty.
  List<FileContentMatch> _touchedFirst(List<FileContentMatch> results) {
    final touched = widget.prTouchedPaths;
    if (touched.isEmpty || results.isEmpty) {
      return results;
    }
    final inPr = <FileContentMatch>[];
    final rest = <FileContentMatch>[];
    for (final r in results) {
      (touched.contains(r.relativePath) ? inPr : rest).add(r);
    }
    if (inPr.isEmpty) {
      return results;
    }
    return [...inPr, ...rest];
  }
}

/// One flattened search-results row: a file header (`match == null`) or a single
/// content match line under it. Flattening keeps list-item heights uniform so
/// scrolling doesn't jump (see `_contentView`).
class _SearchRow {
  const _SearchRow.header(this.group) : match = null;
  const _SearchRow.match(this.group, this.match);

  final FileContentMatch group;
  final ContentMatchLine? match;
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.options,
    required this.loading,
    required this.onChanged,
    required this.onClear,
    required this.onOptionsChanged,
    required this.onClose,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ContentSearchOptions options;
  final bool loading;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final ValueChanged<ContentSearchOptions> onOptionsChanged;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 5),
      child: Row(
        children: [
          Expanded(
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.escape): onClose,
              },
              child: CcTextField(
                controller: controller,
                focusNode: focusNode,
                size: CcTextFieldSize.sm,
                hintText: l10n.searchInFilesHintField,
                onChanged: onChanged,
                prefix: Icon(
                  AppIcons.search,
                  size: 13,
                  color: tokens.textTertiary,
                ),
                // Clear (×) + the regex/word/case toggles; loading lives in
                // the field so results don't flicker away.
                suffix: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PrFieldClearButton(
                      controller: controller,
                      onCleared: onClear,
                    ),
                    _OptionToggle(
                      icon: AppIcons.caseSensitive,
                      tooltip: l10n.ideSearchMatchCase,
                      active: options.caseSensitive,
                      onChanged: (v) =>
                          onOptionsChanged(options.copyWith(caseSensitive: v)),
                    ),
                    _OptionToggle(
                      icon: AppIcons.regex,
                      tooltip: l10n.ideSearchRegex,
                      active: options.regex,
                      onChanged: (v) =>
                          onOptionsChanged(options.copyWith(regex: v)),
                    ),
                    _OptionToggle(
                      icon: AppIcons.quote,
                      tooltip: l10n.ideSearchWholeWord,
                      active: options.wholeWord,
                      onChanged: (v) =>
                          onOptionsChanged(options.copyWith(wholeWord: v)),
                    ),
                    if (loading)
                      const Padding(
                        padding: EdgeInsets.all(5),
                        child: CcSpinner(size: 13, strokeWidth: 2),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          CcIconButton(
            size: CcButtonSize.sm,
            icon: AppIcons.list,
            tooltip: l10n.showFileList,
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

/// The include/exclude glob fields (content mode), shown when the filters
/// disclosure is expanded.
class _FilterFields extends StatelessWidget {
  const _FilterFields({
    required this.includeController,
    required this.excludeController,
    required this.onChanged,
  });

  final TextEditingController includeController;
  final TextEditingController excludeController;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
      child: Column(
        children: [
          CcTextField(
            controller: includeController,
            hintText: l10n.ideSearchFilesToInclude,
            size: CcTextFieldSize.sm,
            prefix: Icon(
              AppIcons.listFilter,
              size: 13,
              color: tokens.textTertiary,
            ),
            onChanged: onChanged,
          ),
          const SizedBox(height: 5),
          CcTextField(
            controller: excludeController,
            hintText: l10n.ideSearchFilesToExclude,
            size: CcTextFieldSize.sm,
            prefix: Icon(
              AppIcons.filterX,
              size: 13,
              color: tokens.textTertiary,
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// A centered, muted empty/hint message filling the results area.
class _Hint extends StatelessWidget {
  const _Hint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: tokens.textTertiary),
        ),
      ),
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({required this.matchCount, required this.fileCount});

  final int matchCount;
  final int fileCount;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      child: Text(
        l10n.searchResultsCount(matchCount, fileCount),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: tokens.textSecondary,
        ),
      ),
    );
  }
}

/// A single collapsible file-header row in the flattened results list. Its match
/// lines are separate list items (see the flatten in `_contentView`), so this
/// renders only the header (chevron, file name, dir, match count).
class _ResultHeader extends StatelessWidget {
  const _ResultHeader({
    super.key,
    required this.group,
    required this.collapsed,
    required this.onToggle,
  });

  final FileContentMatch group;
  final bool collapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final slash = group.relativePath.lastIndexOf('/');
    final name = slash >= 0
        ? group.relativePath.substring(slash + 1)
        : group.relativePath;
    final dir = slash >= 0 ? group.relativePath.substring(0, slash) : '';
    return CcTappable(
      onPressed: onToggle,
      borderRadius: BorderRadius.zero,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: hovered ? tokens.hover : const Color(0x00000000),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 8, 4),
            child: Row(
              children: [
                Icon(
                  collapsed ? AppIcons.chevronRight : AppIcons.chevronDown,
                  size: 12,
                  color: tokens.textTertiary,
                ),
                const SizedBox(width: 4),
                Icon(AppIcons.fileCode, size: 13, color: tokens.textTertiary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: tokens.textPrimary,
                    ),
                  ),
                ),
                if (dir.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      dir,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 11,
                        color: tokens.textTertiary,
                      ),
                    ),
                  ),
                ] else
                  const Spacer(),
                const SizedBox(width: 6),
                _CountBadge(count: group.lines.length),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MatchRow extends StatelessWidget {
  const _MatchRow({
    super.key,
    required this.match,
    required this.query,
    required this.onTap,
  });

  final ContentMatchLine match;
  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final display = match.text.trimLeft();
    final base = CcFonts.code(
      textStyle: TextStyle(fontSize: 12, color: tokens.textSecondary),
    );
    return CcTappable(
      onPressed: onTap,
      borderRadius: BorderRadius.zero,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: hovered ? tokens.hover : const Color(0x00000000),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(30, 2, 8, 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 34,
                  child: Text(
                    '${match.line}',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 11, color: tokens.textTertiary),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: base,
                      children: _highlightSpans(
                        display,
                        query,
                        highlight: TextStyle(
                          backgroundColor: tokens.bgWarningSecondary,
                          color: tokens.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: tokens.bgSecondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: tokens.textSecondary,
        ),
      ),
    );
  }
}

/// A small toggle icon-button for a content-search option (case/regex/word).
/// Shows a pressed/selected visual when [active].
class _OptionToggle extends StatelessWidget {
  const _OptionToggle({
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.onChanged,
  });

  final IconData icon;
  final String tooltip;
  final bool active;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return CcTooltip(
      message: tooltip,
      showDelay: const Duration(milliseconds: 400),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => onChanged(!active),
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: active ? tokens.hover : const Color(0x00000000),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Icon(
              icon,
              size: 13,
              color: active ? tokens.fg : tokens.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Splits [text] into spans, wrapping each case-insensitive occurrence of
/// [query] in [highlight]. Non-matching runs inherit the ambient style.
List<InlineSpan> _highlightSpans(
  String text,
  String query, {
  required TextStyle highlight,
}) {
  if (query.isEmpty) {
    return [TextSpan(text: text)];
  }
  final lower = text.toLowerCase();
  final q = query.toLowerCase();
  final spans = <InlineSpan>[];
  var i = 0;
  while (i < text.length) {
    final idx = lower.indexOf(q, i);
    if (idx < 0) {
      spans.add(TextSpan(text: text.substring(i)));
      break;
    }
    if (idx > i) {
      spans.add(TextSpan(text: text.substring(i, idx)));
    }
    spans.add(
      TextSpan(text: text.substring(idx, idx + q.length), style: highlight),
    );
    i = idx + q.length;
  }
  return spans;
}
