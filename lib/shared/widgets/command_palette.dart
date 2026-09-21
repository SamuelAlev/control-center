import 'dart:math' as math;

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/github_avatar_url.dart';
import 'package:control_center/shared/widgets/command_fuzzy.dart';
import 'package:control_center/shared/widgets/command_recency_provider.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A source of command palette items contributed by a feature.
///
/// Each source produces items under its [category] header.
/// Items are filtered client-side by the palette's search bar.
abstract class CommandSource {
  /// Unique identifier (for dedup, analytics).
  String get id;

  /// Category header string (e.g. "Pull requests", "Conversations").
  String get category;

  /// Whether items from this source are dynamic (data-dependent, may be empty).
  /// Static sources always contribute items; dynamic ones may vary.
  bool get isDynamic;

  /// Build items this source contributes to the palette.
  /// Called each time the palette opens (not on every keystroke).
  /// Uses [ref] to read Riverpod providers with already-cached data.
  List<CommandItem> buildItems(BuildContext context, WidgetRef ref);
}

/// A command item shown in the command palette.
class CommandItem {
  /// Creates a command palette item.
  const CommandItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.onExecute,
    this.description,
    this.shortcut,
    this.category,
    this.avatarUrl,
  });

  /// Stable identifier (for keys, analytics).
  final String id;

  /// Primary label.
  final String label;

  /// Optional secondary line — entity metadata (repo, status, a person's
  /// name), never a restatement of [label].
  final String? description;

  /// Optional keyboard hint, e.g. `'⌘⇧T'`.
  final String? shortcut;

  /// Leading icon (used as fallback when [avatarUrl] is null or empty).
  final IconData icon;

  /// Optional category — used to group items under a header.
  final String? category;

  /// Optional avatar URL. When set, renders a circular avatar instead of [icon].
  final String? avatarUrl;

  /// Invoked when the item is activated.
  final VoidCallback onExecute;

  /// Whether a second line of metadata should render.
  bool get hasDetail {
    final d = description;
    return d != null && d.trim().isNotEmpty;
  }

  /// Whether a shortcut hint should render.
  bool get hasShortcut {
    final s = shortcut;
    return s != null && s.isNotEmpty;
  }
}

/// Shows the command palette dialog.
///
/// [commandBuilder] is called each time the dialog needs fresh commands
/// (e.g. when data providers emit new values). The dialog rebuilds
/// reactively as dynamic sources like PRs and conversations load.
void showCommandPalette(
  BuildContext context,
  List<CommandItem> Function(BuildContext, WidgetRef) commandBuilder,
) {
  showCcDialog<void>(
    context: context,
    builder: (dialogContext) {
      final ds = dialogContext.designSystem ?? DesignSystemTokens.light();
      final size = MediaQuery.sizeOf(dialogContext);
      final maxWidth = math.min(520.0, size.width - AppSpacing.xl * 2);
      // Spotlight/Raycast sit in the upper third — a dead-center panel reads
      // as a settings dialog. Expanding the route child lets us pin the panel
      // in layout (so hit-testing matches the pixels); Align only hit-tests
      // its child, so taps outside still fall through to the dismiss barrier.
      final topInset = (size.height * 0.12).clamp(72.0, 140.0);
      return SizedBox.expand(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.only(top: topInset),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: maxWidth,
                maxWidth: maxWidth,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: ds.panel,
                  borderRadius: AppRadii.brLg,
                  border: Border.all(color: ds.borderPrimary),
                  boxShadow: CcElevation.floating,
                ),
                child: _CommandPaletteBody(commandBuilder: commandBuilder),
              ),
            ),
          ),
        ),
      );
    },
  );
}


/// Moves the palette selection by [delta] rows (+1 down, -1 up).
class _NavigateIntent extends Intent {
  const _NavigateIntent(this.delta);

  final int delta;
}

class _CommandPaletteBody extends ConsumerStatefulWidget {
  const _CommandPaletteBody({required this.commandBuilder});

  final List<CommandItem> Function(BuildContext, WidgetRef) commandBuilder;

  @override
  ConsumerState<_CommandPaletteBody> createState() =>
      _CommandPaletteBodyState();
}

class _CommandPaletteBodyState extends ConsumerState<_CommandPaletteBody> {
  static const double _rowHeight = 40;
  static const double _rowHeightDetailed = 52;
  static const double _headerHeight = 28;
  static const double _listVPad = AppSpacing.xs;
  static const double _maxListHeight = 360;

  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  /// Query + selection, held in a notifier rather than in `setState` state.
  ///
  /// `build` is what calls `widget.commandBuilder(context, ref)`, which walks
  /// all eight-plus command sources — and its `ref.watch` calls are what
  /// establish this widget's provider dependencies, so it CANNOT be skipped in
  /// a build. Driving the query through a `ValueNotifier` and rebuilding only
  /// the results subtree means a keystroke no longer triggers a build at all:
  /// the command list is built when a data provider changes, and re-ranked
  /// when the query changes. Those are different events and now cost
  /// differently. (The source contract at the top of this file says exactly
  /// this — "not on every keystroke" — and was being violated.)
  final _view = ValueNotifier<_PaletteView>(
    const _PaletteView(query: '', selectedIndex: 0),
  );

  String get _query => _view.value.query;
  int get _selectedIndex => _view.value.selectedIndex;

  /// The commands from the last real build, re-ranked per keystroke.
  List<CommandItem> _commands = const [];

  late List<_PaletteEntry> _entries;
  late List<CommandItem> _filteredCommands;

  @override
  void initState() {
    super.initState();
    _entries = [];
    _filteredCommands = [];
    _controller.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _view.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _view.value = _PaletteView(query: _controller.text, selectedIndex: 0);
    _scrollSelectedIntoView();
  }

  void _rebuildEntries(List<CommandItem> commands, String query) {
    final q = query.trim();
    final recency = ref.read(commandRecencyProvider.notifier);
    // One fuzzy pass ranks everything from the warm in-memory command list
    // (PRD 19 §1) — best-first on a query, recents-first when empty.
    final ranked = rankCommands<CommandItem>(
      q,
      commands,
      textOf: (c) => '${c.label} ${c.description ?? ''} ${c.category ?? ''}',
      recencyOf: (c) => recency.rankOf(c.id),
    );

    final entries = <_PaletteEntry>[];
    final ordered = <CommandItem>[];

    if (q.isNotEmpty) {
      // A search shows a single flat, ranked list — no category headers, so
      // the best matches sit at the very top (Linear-style).
      for (final cmd in ranked) {
        entries.add(_PaletteEntry.command(cmd, ordered.length));
        ordered.add(cmd);
      }
    } else {
      // No query: a "Recent" group floats prior actions to the top, then the
      // remaining commands stay grouped by category for browsing.
      final l10n = AppLocalizations.of(context);
      final recents = [
        for (final c in ranked)
          if (recency.rankOf(c.id).isFinite) c,
      ].take(6).toList();
      final recentIds = {for (final c in recents) c.id};
      if (recents.isNotEmpty) {
        entries.add(_PaletteEntry.header(l10n.recentLabel));
        for (final cmd in recents) {
          entries.add(_PaletteEntry.command(cmd, ordered.length));
          ordered.add(cmd);
        }
      }
      final byCategory = <String, List<CommandItem>>{};
      final order = <String>[];
      for (final cmd in ranked) {
        if (recentIds.contains(cmd.id)) {
          continue;
        }
        final cat = cmd.category ?? l10n.otherLabel;
        if (!byCategory.containsKey(cat)) {
          order.add(cat);
        }
        byCategory.putIfAbsent(cat, () => []).add(cmd);
      }
      for (final cat in order) {
        entries.add(_PaletteEntry.header(cat));
        for (final cmd in byCategory[cat]!) {
          entries.add(_PaletteEntry.command(cmd, ordered.length));
          ordered.add(cmd);
        }
      }
    }
    _filteredCommands = ordered;
    _entries = entries;
  }

  void _executeSelected() {
    if (_filteredCommands.isEmpty) {
      return;
    }
    _execute(_filteredCommands[_selectedIndex]);
  }

  void _move(int delta) {
    if (_filteredCommands.isEmpty) {
      return;
    }
    var next = (_selectedIndex + delta) % _filteredCommands.length;
    if (next < 0) {
      next += _filteredCommands.length;
    }
    _view.value = _PaletteView(query: _query, selectedIndex: next);
    _scrollSelectedIntoView();
  }

  void _execute(CommandItem cmd) {
    // Remember it so it floats to the top next time (PRD 19 §1 recency).
    ref.read(commandRecencyProvider.notifier).touch(cmd.id);
    Navigator.of(context).pop();
    cmd.onExecute();
  }

  double _rowHeightFor(CommandItem cmd) =>
      cmd.hasDetail ? _rowHeightDetailed : _rowHeight;

  void _scrollSelectedIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients || _filteredCommands.isEmpty) {
        return;
      }
      final offset = _offsetForCmdIndex(_selectedIndex);
      final cmd = _filteredCommands[_selectedIndex];
      final position = _scrollController.position;
      final viewport = position.viewportDimension;
      final current = position.pixels;
      final itemTop = offset;
      final itemBottom = offset + _rowHeightFor(cmd);
      double? target;
      if (itemTop < current + 4) {
        target = (itemTop - _headerHeight).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        );
      } else if (itemBottom > current + viewport - 4) {
        target = (itemBottom - viewport).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        );
      }
      if (target != null && target != current) {
        _scrollController.animateTo(
          target,
          duration: CcMotion.resolve(context, CcMotion.fast),
          curve: CcMotion.standard,
        );
      }
    });
  }

  double _offsetForCmdIndex(int cmdIdx) {
    double offset = _listVPad;
    for (final e in _entries) {
      if (e.isHeader) {
        offset += _headerHeight;
      } else {
        if (e.cmdIndex == cmdIdx) {
          return offset;
        }
        offset += _rowHeightFor(e.command!);
      }
    }
    return offset;
  }

  double _listExtent() {
    var height = _listVPad * 2;
    for (final e in _entries) {
      height += e.isHeader ? _headerHeight : _rowHeightFor(e.command!);
    }
    return height;
  }

  @override
  Widget build(BuildContext context) {
    // Build fresh commands from all registered sources.
    // ref.watch calls inside the builder trigger rebuilds when
    // data providers (PRs, conversations) emit new values.
    //
    // This runs on a real build only — a keystroke updates `_view` instead,
    // and only the results subtree below re-ranks.
    _commands = widget.commandBuilder(context, ref);

    // Up/down navigation is handled through the focus tree (Shortcuts/Actions)
    // rather than a global `HardwareKeyboard` handler. The search field owns
    // focus while the palette is open and these shortcuts sit just above it,
    // so they take precedence over the default text-editing arrow behaviour —
    // the same pattern Flutter's own Autocomplete/SearchAnchor use to drive a
    // list while a field is focused. (The dispatcher's macOS ghost-input
    // workaround used to call HardwareKeyboard.clearState() — which wipes
    // every registered handler; it now synthesises key-ups via
    // releaseStuckKeys instead, but the focus tree remains the right
    // precedence tool for field-local navigation like these arrows.)
    //
    // Enter is intentionally NOT bound here: it flows through the focused
    // search field as `onSubmitted` (see [_executeSelected]).
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.arrowDown): _NavigateIntent(1),
        SingleActivator(LogicalKeyboardKey.arrowUp): _NavigateIntent(-1),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _NavigateIntent: CallbackAction<_NavigateIntent>(
            onInvoke: (intent) {
              _move(intent.delta);
              return null;
            },
          ),
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SearchHeader(
              controller: _controller,
              onSubmit: _executeSelected,
            ),
            const CcDivider(),
            ValueListenableBuilder<_PaletteView>(
              valueListenable: _view,
              builder: (context, view, _) {
                // Ranking happens HERE, against the commands captured by
                // the last real build — so a keystroke re-ranks without
                // rebuilding the eight command sources.
                _rebuildEntries(_commands, view.query);
                if (_filteredCommands.isEmpty) {
                  return const _EmptyResults();
                }
                final extent = _listExtent();
                final fits = extent <= _maxListHeight;
                return SizedBox(
                  height: fits ? extent : _maxListHeight,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: _listVPad),
                    physics: fits ? const NeverScrollableScrollPhysics() : null,
                    itemCount: _entries.length,
                    itemExtentBuilder: (index, _) {
                      final e = _entries[index];
                      if (e.isHeader) {
                        return _headerHeight;
                      }
                      return _rowHeightFor(e.command!);
                    },
                    itemBuilder: _buildRow,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, int i) {
    final e = _entries[i];
    if (e.isHeader) {
      return _CategoryHeader(label: e.header!);
    }
    final cmd = e.command!;
    final selected = e.cmdIndex == _selectedIndex;
    return _CommandRow(
      cmd: cmd,
      selected: selected,
      query: _query,
      onTap: () => _execute(cmd),
      onHover: () {
        if (_selectedIndex != e.cmdIndex) {
          _view.value = _PaletteView(query: _query, selectedIndex: e.cmdIndex!);
        }
      },
    );
  }
}

/// The palette's per-keystroke state: what was typed and which row is
/// selected. Both change far more often than the command LIST does, which is
/// why they live in a notifier the results subtree listens to.
class _PaletteView {
  const _PaletteView({required this.query, required this.selectedIndex});

  final String query;
  final int selectedIndex;

  @override
  bool operator ==(Object other) =>
      other is _PaletteView &&
      other.query == query &&
      other.selectedIndex == selectedIndex;

  @override
  int get hashCode => Object.hash(query, selectedIndex);
}


class _PaletteEntry {
  const _PaletteEntry._({this.header, this.command, this.cmdIndex});

  factory _PaletteEntry.header(String label) => _PaletteEntry._(header: label);

  factory _PaletteEntry.command(CommandItem cmd, int index) =>
      _PaletteEntry._(command: cmd, cmdIndex: index);

  final String? header;
  final CommandItem? command;
  final int? cmdIndex;

  bool get isHeader => header != null;
}


class _SearchHeader extends StatelessWidget {
  const _SearchHeader({required this.controller, required this.onSubmit});

  final TextEditingController controller;

  /// Invoked when the user presses Enter in the search field — executes the
  /// currently-selected command.
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + AppSpacing.xxs,
      ),
      child: Row(
        children: [
          Icon(AppIcons.search, size: 16, color: ds.textTertiary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            // Chromeless: a palette's query field carries no box of its own
            // (the Linear/Raycast ⌘K idiom) — the dialog itself is already
            // the focused surface.
            child: CcTextField(
              controller: controller,
              autofocus: true,
              chromeless: true,
              textStyle: CcTypography.body,
              hintText: AppLocalizations.of(context).typeCommandOrSearch,
              onSubmitted: (_) => onSubmit(),
            ),
          ),
        ],
      ),
    );
  }
}


class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    return SizedBox(
      height: _CommandPaletteBodyState._headerHeight,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.xxs,
        ),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CcFonts.code(
              textStyle: CcTypography.label,
              family: context.ccTheme?.monoFontFamily,
            ).copyWith(color: ds.textTertiary),
          ),
        ),
      ),
    );
  }
}


class _CommandRow extends StatelessWidget {
  const _CommandRow({
    required this.cmd,
    required this.selected,
    required this.query,
    required this.onTap,
    required this.onHover,
  });

  final CommandItem cmd;
  final bool selected;
  final String query;
  final VoidCallback onTap;
  final VoidCallback onHover;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final iconColor = selected ? ds.textPrimary : ds.textTertiary;
    final wash = selected ? ds.hoverStrong : const Color(0x00000000);
    return SizedBox(
      height: cmd.hasDetail
          ? _CommandPaletteBodyState._rowHeightDetailed
          : _CommandPaletteBodyState._rowHeight,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => onHover(),
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: CcMotion.resolveFade(context, CcMotion.fast),
            curve: CcMotion.standard,
            // Inset square wash — the Linear highlight, squared to the system
            // identity. A full-bleed bar on a 64px row was the gray slab.
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              color: wash,
              borderRadius: AppRadii.brSm,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Center(child: _Leading(cmd: cmd, color: iconColor)),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: cmd.hasDetail
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _HighlightedText(
                              text: cmd.label,
                              query: query,
                              baseStyle: CcTypography.bodySm.copyWith(
                                color: ds.textPrimary,
                              ),
                              maxLines: 1,
                            ),
                            _HighlightedText(
                              text: cmd.description!.trim(),
                              query: query,
                              baseStyle: CcTypography.caption.copyWith(
                                color: ds.textTertiary,
                              ),
                              maxLines: 1,
                            ),
                          ],
                        )
                      : _HighlightedText(
                          text: cmd.label,
                          query: query,
                          baseStyle: CcTypography.bodySm.copyWith(
                            color: ds.textPrimary,
                          ),
                          maxLines: 1,
                        ),
                ),
                if (cmd.hasShortcut) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    cmd.shortcut!,
                    style: CcFonts.code(
                      textStyle: CcTypography.caption,
                      family: context.ccTheme?.monoFontFamily,
                    ).copyWith(color: ds.textTertiary),
                  ),
                ],
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  AppIcons.cornerDownLeft,
                  size: 14,
                  color: selected ? ds.textTertiary : const Color(0x00000000),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Leading extends StatelessWidget {
  const _Leading({required this.cmd, required this.color});

  final CommandItem cmd;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final url = cmd.avatarUrl;
    if (url == null || url.isEmpty) {
      return Icon(cmd.icon, size: 16, color: color);
    }
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return ClipOval(
      child: Image.network(
        MediaProxyScope.urlOf(
          context,
          sizedGitHubAvatarUrl(url, 20, dpr),
        ),
        width: 20,
        height: 20,
        cacheWidth: (20 * dpr).round(),
        cacheHeight: (20 * dpr).round(),
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => Icon(cmd.icon, size: 16, color: color),
      ),
    );
  }
}


class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: Center(
        child: Text(
          'No commands match',
          style: CcTypography.bodySm.copyWith(color: ds.textTertiary),
        ),
      ),
    );
  }
}


class _HighlightedText extends StatelessWidget {
  const _HighlightedText({
    required this.text,
    required this.query,
    required this.baseStyle,
    this.maxLines,
  });

  final String text;
  final String query;
  final TextStyle baseStyle;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final q = query.trim();
    if (q.isEmpty) {
      return Text(
        text,
        style: baseStyle,
        maxLines: maxLines,
        overflow: maxLines == null ? null : TextOverflow.ellipsis,
      );
    }
    final lowerText = text.toLowerCase();
    final lowerQuery = q.toLowerCase();
    final spans = <InlineSpan>[];
    var cursor = 0;
    while (true) {
      final idx = lowerText.indexOf(lowerQuery, cursor);
      if (idx == -1) {
        break;
      }
      if (idx > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, idx)));
      }
      spans.add(
        TextSpan(
          text: text.substring(idx, idx + q.length),
          style: baseStyle.copyWith(
            color: (context.designSystem ?? DesignSystemTokens.light())
                .textPrimary,
            fontWeight: CcTypography.semiboldWeight,
          ),
        ),
      );
      cursor = idx + q.length;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }
    return Text.rich(
      TextSpan(style: baseStyle, children: spans),
      maxLines: maxLines,
      overflow: maxLines == null ? TextOverflow.clip : TextOverflow.ellipsis,
    );
  }
}
