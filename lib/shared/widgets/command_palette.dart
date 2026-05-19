import 'dart:ui' as ui;

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/github_avatar_url.dart';
import 'package:control_center/shared/widgets/empty_state.dart';
import 'package:control_center/shared/widgets/kbd.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  /// Optional secondary line.
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
      // Earned brand moment: the command palette is the one floating surface
      // that gets a frosted-glass treatment (never the dense work canvas). When
      // the user prefers reduced motion / increased contrast we fall back to a
      // fully-opaque panel — same geometry, no blur, no alpha — so text
      // contrast is identical to the rest of the app (WCAG: rows always sit on
      // solid fills inside the panel either way).
      final reduceTransparency =
          CcMotion.reduced(dialogContext) ||
          (MediaQuery.maybeOf(dialogContext)?.highContrast ?? false);
      final surfaceColor = reduceTransparency
          ? ds.panel
          : ds.panel.withValues(alpha: 0.72);
      return ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 560, maxWidth: 640),
        child: ClipRRect(
          borderRadius: AppRadii.brLg,
          child: _GlassSurface(
            blur: reduceTransparency ? 0 : 18,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: AppRadii.brLg,
                border: Border.all(color: ds.borderPrimary),
                boxShadow: AppShadows.golden,
              ),
              child: _CommandPaletteBody(commandBuilder: commandBuilder),
            ),
          ),
        ),
      );
    },
  );
}

/// Frosted-glass backing for a floating surface. When [blur] is 0 (reduced
/// transparency / increased contrast) it renders [child] directly — no
/// [BackdropFilter], no save-layer — so the opaque-fallback path is a plain
/// solid surface. Purist: uses only `dart:ui` + `package:flutter/widgets.dart`.
class _GlassSurface extends StatelessWidget {
  const _GlassSurface({required this.blur, required this.child});

  final double blur;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (blur <= 0) {
      return child;
    }
    return BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: child,
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

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
  static const double _rowHeight = 64;
  static const double _headerHeight = 36;


  static const double _listVPad = 8;

  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  String _query = '';
  int _selectedIndex = 0;

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
    super.dispose();
  }

  void _onQueryChanged() {
    setState(() {
      _query = _controller.text;
      _selectedIndex = 0;
    });
    _scrollSelectedIntoView();
  }

  void _rebuildEntries(List<CommandItem> commands) {
    final q = _query.trim().toLowerCase();
    _filteredCommands = q.isEmpty
        ? commands
        : commands.where((c) {
            return c.label.toLowerCase().contains(q) ||
                (c.description?.toLowerCase().contains(q) ?? false) ||
                (c.category?.toLowerCase().contains(q) ?? false);
          }).toList();

    final byCategory = <String, List<CommandItem>>{};
    final order = <String>[];
    for (final cmd in _filteredCommands) {
      final l10n = AppLocalizations.of(context);
      final cat = cmd.category ?? l10n.otherLabel;
      if (!byCategory.containsKey(cat)) {
        order.add(cat);
      }
      byCategory.putIfAbsent(cat, () => []).add(cmd);
    }
    final entries = <_PaletteEntry>[];
    var cmdIdx = 0;
    for (final cat in order) {
      entries.add(_PaletteEntry.header(cat));
      for (final cmd in byCategory[cat]!) {
        entries.add(_PaletteEntry.command(cmd, cmdIdx++));
      }
    }
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
    setState(() {
      _selectedIndex = (_selectedIndex + delta) % _filteredCommands.length;
      if (_selectedIndex < 0) {
        _selectedIndex += _filteredCommands.length;
      }
    });
    _scrollSelectedIntoView();
  }

  void _execute(CommandItem cmd) {
    Navigator.of(context).pop();
    cmd.onExecute();
  }

  void _scrollSelectedIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      final offset = _offsetForCmdIndex(_selectedIndex);
      final position = _scrollController.position;
      final viewport = position.viewportDimension;
      final current = position.pixels;
      final itemTop = offset;
      final itemBottom = offset + _rowHeight;
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
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
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
        offset += _rowHeight;
      }
    }
    return offset;
  }

  @override
  Widget build(BuildContext context) {
    // Build fresh commands from all registered sources.
    // ref.watch calls inside the builder trigger rebuilds when
    // data providers (PRs, conversations) emit new values.
    final commands = widget.commandBuilder(context, ref);
    _rebuildEntries(commands);

    // Up/down navigation is handled through the focus tree (Shortcuts/Actions)
    // rather than a global `HardwareKeyboard` handler. The search field owns
    // focus while the palette is open, and these shortcuts sit just above it,
    // so they take precedence over the default text-editing arrow behaviour —
    // the same pattern Flutter's own Autocomplete/SearchAnchor use to drive a
    // list while a field is focused. A global hardware-keyboard handler is
    // unreliable here: focusing a text field can clear it (see
    // KeybindingDispatcher's macOS ghost-input workaround, which calls
    // HardwareKeyboard.clearState() — that wipes every registered handler).
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
        child: SizedBox(
          height: 520,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SearchHeader(
                controller: _controller,
                onSubmit: _executeSelected,
              ),
              const CcDivider(),
              Expanded(
                child: _filteredCommands.isEmpty
                    ? EmptyState(
                        message: 'No commands match',
                        icon: AppIcons.searchX,
                        iconSize: 28,
                        query: _query,
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding:
                            const EdgeInsets.symmetric(vertical: _listVPad),
                        itemCount: _entries.length,
                        itemBuilder: _buildRow,
                      ),
              ),
              const CcDivider(),
              const _FooterHints(),
            ],
          ),
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
          setState(() => _selectedIndex = e.cmdIndex!);
        }
      },
    );
  }
}

// ─── Entries ──────────────────────────────────────────────────────────────────

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

// ─── Search header ────────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Row(
        children: [
          Icon(
            AppIcons.search,
            size: 18,
            color: ds.textTertiary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: CcTextField(
              controller: controller,
              autofocus: true,
              hintText: AppLocalizations.of(context).typeCommandOrSearch,
              onSubmitted: (_) => onSubmit(),
            ),
          ),
          Kbd.symbol(
            label: 'esc',
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

// ─── Category header ──────────────────────────────────────────────────────────

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    return SizedBox(
      height: _CommandPaletteBodyState._headerHeight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label.toUpperCase(),
            style: CcTypography.caption.copyWith(
              color: ds.textTertiary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Command row ──────────────────────────────────────────────────────────────

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
    final bg = selected ? ds.bgSecondary : Colors.transparent;
    final iconBg = selected ? ds.bgPrimary : ds.bgSecondary;
    return SizedBox(
      height: _CommandPaletteBodyState._rowHeight,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => onHover(),
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: Duration.zero,
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: ds.borderSecondary),
                  ),
                  alignment: Alignment.center,
                  child: cmd.avatarUrl != null && cmd.avatarUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            MediaProxyScope.urlOf(
                              context,
                              sizedGitHubAvatarUrl(
                                cmd.avatarUrl!,
                                32,
                                MediaQuery.devicePixelRatioOf(context),
                              ),
                            ),
                            width: 32,
                            height: 32,
                            cacheWidth:
                                (32 * MediaQuery.devicePixelRatioOf(context))
                                    .round(),
                            cacheHeight:
                                (32 * MediaQuery.devicePixelRatioOf(context))
                                    .round(),
                            gaplessPlayback: true,
                            errorBuilder: (_, _, _) => Icon(
                              cmd.icon,
                              size: 16,
                              color: ds.textPrimary,
                            ),
                          ),
                        )
                      : Icon(
                          cmd.icon,
                          size: 16,
                          color: ds.textPrimary,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _HighlightedText(
                        text: cmd.label,
                        query: query,
                        baseStyle: CcTypography.body.copyWith(
                          color: ds.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                      ),
                      if (cmd.description != null) ...[
                        const SizedBox(height: 2),
                        _HighlightedText(
                          text: cmd.description!,
                          query: query,
                          baseStyle: CcTypography.caption.copyWith(
                            color: ds.textTertiary,
                          ),
                          maxLines: 1,
                        ),
                      ],
                    ],
                  ),
                ),
                if (cmd.shortcut != null) ...[
                  const SizedBox(width: 12),
                  Kbd.symbol(label: cmd.shortcut!),
                ],
                const SizedBox(width: 6),
                Icon(
                  AppIcons.cornerDownLeft,
                  size: 14,
                  color: selected
                      ? ds.textPrimary
                      : Colors.transparent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Highlighted query text ───────────────────────────────────────────────────

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
            fontWeight: FontWeight.w700,
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

// ─── Footer hints ─────────────────────────────────────────────────────────────

class _FooterHints extends StatelessWidget {
  const _FooterHints();

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final labelStyle = CcTypography.caption.copyWith(
      color: ds.textTertiary,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Kbd.symbol(label: '↑'),
            const SizedBox(width: 4),
            const Kbd.symbol(label: '↓'),
            const SizedBox(width: 6),
            Text(AppLocalizations.of(context).navigateLabel, style: labelStyle),
            const SizedBox(width: 16),
            const Kbd.symbol(label: '↵'),
            const SizedBox(width: 6),
            Text(AppLocalizations.of(context).selectLabel, style: labelStyle),
            const SizedBox(width: 16),
            const Kbd.symbol(label: 'esc'),
            const SizedBox(width: 6),
            Text(AppLocalizations.of(context).closeKeyboardHint, style: labelStyle),
          ],
        ),
      ),
    );
  }
}
