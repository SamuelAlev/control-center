import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/empty_state.dart';
import 'package:control_center/shared/widgets/kbd.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
  showFDialog<void>(
    context: context,
    builder: (dialogContext, style, animation) {
      return FDialog.raw(
        style: style,
        animation: animation,
        constraints: const BoxConstraints(minWidth: 560, maxWidth: 640),
        builder: (context, _) =>
            _CommandPaletteBody(commandBuilder: commandBuilder),
      );
    },
  );
}

// ─── Body ─────────────────────────────────────────────────────────────────────

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
    HardwareKeyboard.instance.addHandler(_handleKey);
  }



  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
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

  bool _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return false;
    }
    if (!mounted) {
      return false;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      _move(1);
      return true;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _move(-1);
      return true;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (_filteredCommands.isNotEmpty) {
        _execute(_filteredCommands[_selectedIndex]);
      }
      return true;
    }
    return false;
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

    return SizedBox(

      height: 520,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SearchHeader(controller: _controller),
          const FDivider(),
          Expanded(
            child: _filteredCommands.isEmpty
                ? EmptyState(
                    message: 'No commands match',
                    icon: LucideIcons.searchX,
                    iconSize: 28,
                    query: _query,
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: _listVPad),
                    itemCount: _entries.length,
                    itemBuilder: _buildRow,
                  ),
          ),
          const FDivider(),
          const _FooterHints(),
        ],
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
  const _SearchHeader({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Row(
        children: [
          Icon(
            LucideIcons.search,
            size: 18,
            color: theme.colors.mutedForeground,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FTextField(
              control: FTextFieldControl.managed(controller: controller),
              autofocus: true,
              hint: AppLocalizations.of(context).typeCommandOrSearch,
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
    final theme = context.theme;
    return SizedBox(
      height: _CommandPaletteBodyState._headerHeight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label.toUpperCase(),
            style: theme.typography.xs.copyWith(
              color: theme.colors.mutedForeground,
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
    final theme = context.theme;
    final bg = selected ? theme.colors.secondary : Colors.transparent;
    final iconBg = selected ? theme.colors.background : theme.colors.muted;
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
                    border: Border.all(color: theme.colors.border),
                  ),
                  alignment: Alignment.center,
                  child: cmd.avatarUrl != null && cmd.avatarUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            cmd.avatarUrl!,
                            width: 32,
                            height: 32,
                            errorBuilder: (_, _, _) => Icon(
                              cmd.icon,
                              size: 16,
                              color: theme.colors.foreground,
                            ),
                          ),
                        )
                      : Icon(
                          cmd.icon,
                          size: 16,
                          color: theme.colors.foreground,
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
                        baseStyle: theme.typography.sm.copyWith(
                          color: theme.colors.foreground,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                      ),
                      if (cmd.description != null) ...[
                        const SizedBox(height: 2),
                        _HighlightedText(
                          text: cmd.description!,
                          query: query,
                          baseStyle: theme.typography.xs.copyWith(
                            color: theme.colors.mutedForeground,
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
                  LucideIcons.cornerDownLeft,
                  size: 14,
                  color: selected
                      ? theme.colors.foreground
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
            color: context.theme.colors.primary,
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
    final theme = context.theme;
    final labelStyle = theme.typography.xs.copyWith(
      color: theme.colors.mutedForeground,
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
