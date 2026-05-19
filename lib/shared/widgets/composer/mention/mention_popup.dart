import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/composer/mention/mention_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A single visual row entry — either a section header or a suggestion.
class _Row {
  const _Row.header(this.header) : suggestion = null, index = null;
  const _Row.item(MentionSuggestion this.suggestion, int this.index)
    : header = null;

  final String? header;
  final MentionSuggestion? suggestion;
  final int? index;

  bool get isHeader => header != null;
}

/// Floating suggestion list pinned to the composer.
///
/// Keyboard handling lives here: we register a global key handler with
/// [HardwareKeyboard] while open, the same pattern used by the command
/// palette in `lib/shared/widgets/command_palette.dart`. This lets the
/// text field keep focus (so typing/cursor keys keep working) while we
/// still intercept arrow up/down, Enter/Tab to pick, and Esc to dismiss.
class MentionPopup extends StatefulWidget {
  /// Creates a new [MentionPopup].
  const MentionPopup({
    super.key,
    required this.query,
    required this.sources,
    required this.onSelect,
    required this.onDismiss,
  });

  /// Current mention query driving the popup contents.
  final MentionQuery query;

  /// Mention sources to query for suggestions.
  final List<MentionSource> sources;

  /// Called when the user selects a suggestion.
  final void Function(MentionSuggestion) onSelect;

  /// Called when the user dismisses the popup without selecting.
  final VoidCallback onDismiss;

  @override
  State<MentionPopup> createState() => _MentionPopupState();
}

class _MentionPopupState extends State<MentionPopup> {
  static const int _perSourceLimit = 6;
  static const double _rowHeight = 44;
  static const double _headerHeight = 24;
  static const double _maxHeight = 280;

  final ScrollController _scroll = ScrollController();
  final Map<String, List<MentionSuggestion>> _bySource = {};
  final List<StreamSubscription<List<MentionSuggestion>>> _subs = [];

  List<_Row> _rows = const [];
  List<MentionSuggestion> _flat = const [];
  int _selected = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKey);
    _runSources();
  }

  @override
  void didUpdateWidget(covariant MentionPopup old) {
    super.didUpdateWidget(old);
    final triggerChanged = old.query.trigger != widget.query.trigger;
    final partialChanged = old.query.partial != widget.query.partial;
    final sourcesChanged = !identical(old.sources, widget.sources);
    if (triggerChanged || partialChanged || sourcesChanged) {
      _runSources();
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _scroll.dispose();
    super.dispose();
  }

  void _runSources() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _bySource.clear();
    setState(() {
      _loading = true;
      _flat = const [];
      _rows = const [];
      _selected = 0;
    });

    final relevant = widget.sources
        .where((s) => s.triggers.contains(widget.query.trigger))
        .toList();
    if (relevant.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    for (final source in relevant) {
      final sub = source
          .suggest(widget.query)
          .listen(
            (items) {
              if (!mounted) {
                return;
              }
              _bySource[source.kind] = items.take(_perSourceLimit).toList();
              _rebuild();
            },
            onError: (_) {
              if (!mounted) {
                return;
              }
              _bySource[source.kind] = const [];
              _rebuild();
            },
          );
      _subs.add(sub);
    }
    // If every source completed synchronously the rebuild already happened;
    // flip loading off after a microtask either way.
    scheduleMicrotask(() {
      if (mounted) {
        setState(() => _loading = false);
      }
    });
  }

  void _rebuild() {
    final rows = <_Row>[];
    final flat = <MentionSuggestion>[];
    var idx = 0;
    for (final source in widget.sources) {
      if (!source.triggers.contains(widget.query.trigger)) {
        continue;
      }
      final items = _bySource[source.kind];
      if (items == null || items.isEmpty) {
        continue;
      }
      final header = source.sectionLabel(context);
      if (header != null) {
        rows.add(_Row.header(header));
      }
      for (final s in items) {
        rows.add(_Row.item(s, idx));
        flat.add(s);
        idx++;
      }
    }
    setState(() {
      _rows = rows;
      _flat = flat;
      if (_selected >= _flat.length) {
        _selected = _flat.isEmpty ? 0 : _flat.length - 1;
      }
    });
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
    if (key == LogicalKeyboardKey.escape) {
      widget.onDismiss();
      return true;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.tab) {
      if (_flat.isNotEmpty) {
        widget.onSelect(_flat[_selected]);
        return true;
      }
      // No suggestions: let Enter fall through to submit the message.
      return false;
    }
    return false;
  }

  void _move(int delta) {
    if (_flat.isEmpty) {
      return;
    }
    setState(() {
      _selected = (_selected + delta) % _flat.length;
      if (_selected < 0) {
        _selected += _flat.length;
      }
    });
    _scrollSelectedIntoView();
  }

  void _scrollSelectedIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) {
        return;
      }
      final offset = _offsetForFlatIndex(_selected);
      final pos = _scroll.position;
      final view = pos.viewportDimension;
      final cur = pos.pixels;
      final top = offset;
      final bottom = offset + _rowHeight;
      double? target;
      if (top < cur + 4) {
        target = (top - _headerHeight).clamp(
          pos.minScrollExtent,
          pos.maxScrollExtent,
        );
      } else if (bottom > cur + view - 4) {
        target = (bottom - view).clamp(
          pos.minScrollExtent,
          pos.maxScrollExtent,
        );
      }
      if (target != null && target != cur) {
        _scroll.animateTo(
          target,
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut,
        );
      }
    });
  }

  double _offsetForFlatIndex(int flatIdx) {
    double offset = 6;
    for (final row in _rows) {
      if (row.isHeader) {
        offset += _headerHeight;
      } else {
        if (row.index == flatIdx) {
          return offset;
        }
        offset += _rowHeight;
      }
    }
    return offset;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.designSystem ?? DesignSystemTokens.light();
    if (_flat.isEmpty && !_loading) {
      return const SizedBox.shrink();
    }
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxHeight: _maxHeight),
        decoration: BoxDecoration(
          color: ds.bgPrimary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ds.borderSecondary),
          boxShadow: AppShadows.golden,
        ),
        child: _flat.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  l10n.searching,
                  style: CcTypography.body.copyWith(
                    color: ds.textTertiary,
                  ),
                ),
              )
            : ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(vertical: 6),
                shrinkWrap: true,
                itemCount: _rows.length,
                itemBuilder: _buildRow,
              ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, int i) {
    final row = _rows[i];
    final ds = context.designSystem ?? DesignSystemTokens.light();
    if (row.isHeader) {
      return SizedBox(
        height: _headerHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 2),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              row.header!.toUpperCase(),
              style: CcTypography.caption.copyWith(
                color: ds.textTertiary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
      );
    }
    final s = row.suggestion!;
    final selected = row.index == _selected;
    return _SuggestionRow(
      suggestion: s,
      selected: selected,
      onTap: () => widget.onSelect(s),
      onHover: () {
        if (_selected != row.index) {
          setState(() => _selected = row.index!);
        }
      },
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({
    required this.suggestion,
    required this.selected,
    required this.onTap,
    required this.onHover,
  });

  final MentionSuggestion suggestion;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onHover;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final bg = selected ? ds.bgSecondary : Colors.transparent;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _MentionPopupState._rowHeight),
      child: CcTappable(
        onPressed: onTap,
        mouseCursor: SystemMouseCursors.click,
        builder: (context, states) => MouseRegion(
          onEnter: (_) => onHover(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 60),
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                if (suggestion.icon != null)
                  Icon(
                    suggestion.icon,
                    size: 16,
                    color: ds.textTertiary,
                  ),
                if (suggestion.icon != null) const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        suggestion.label,
                        style: CcTypography.body.copyWith(
                          color: ds.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (suggestion.description != null &&
                          suggestion.description!.isNotEmpty)
                        Text(
                          suggestion.description!,
                          style: CcTypography.caption.copyWith(
                            color: ds.textTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
