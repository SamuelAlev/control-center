import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/composer/mention/mention_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A single visual row entry — either a section header or a suggestion.
class _Row {
  const _Row.header(this.header)
    : suggestion = null,
      index = null,
      sourceKind = null;
  const _Row.item(
    MentionSuggestion this.suggestion,
    int this.index,
    String this.sourceKind,
  ) : header = null;

  final String? header;
  final MentionSuggestion? suggestion;
  final int? index;

  /// Kind of the source that produced this row's suggestion — commits are
  /// gated per source so a slow async source never blocks fast (synchronous)
  /// ones.
  final String? sourceKind;

  bool get isHeader => header != null;
}

/// Floating suggestion list pinned to the composer.
///
/// Keyboard handling lives here: we register a global key handler with
/// [HardwareKeyboard] while open, the same pattern used by the command
/// palette in `lib/shared/widgets/command_palette.dart`. This lets the
/// text field keep focus (so typing/cursor keys keep working) while we
/// still intercept arrow up/down, Enter/Tab to pick and Esc to dismiss.
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

  /// Bumped on every re-query; a source's entry is current only when its
  /// delivery generation matches. Rows from an older generation stay VISIBLE
  /// while the new query is in flight (no blank flash) but must never be
  /// committed — they answer a different partial.
  int _generation = 0;
  final Map<String, int> _sourceGen = {};

  /// Source kinds aligned with [_flat] — lets Enter/Tab commit only a row
  /// whose own source has answered the current query.
  List<String> _flatKinds = const [];

  /// Shows the "Searching…" placeholder only once a query has genuinely taken
  /// [_searchingDelay] with nothing to show — fast (synchronous) sources never
  /// flash it.
  static const Duration _searchingDelay = Duration(milliseconds: 300);
  Timer? _searchingTimer;
  bool _showSearching = false;

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
      // The parent rebuilds the source list on every build (fresh literal),
      // so identity says nothing about a semantic change. Keep the rows
      // unless the trigger itself changed: a refined partial or spurious
      // source-identity churn swaps them atomically on re-delivery instead of
      // blanking the popup for a frame.
      _runSources(keepStale: !triggerChanged);
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    _searchingTimer?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _scroll.dispose();
    super.dispose();
  }

  void _runSources({bool keepStale = false}) {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _searchingTimer?.cancel();
    _generation++;
    final generation = _generation;
    setState(() {
      _loading = true;
      _showSearching = false;
      if (!(keepStale && _flat.isNotEmpty)) {
        _bySource.clear();
        _flat = const [];
        _flatKinds = const [];
        _rows = const [];
      }
      _selected = 0;
    });

    final relevant = widget.sources
        .where((s) => s.triggers.contains(widget.query.trigger))
        .toList();
    if (relevant.isEmpty) {
      setState(() {
        _loading = false;
        _bySource.clear();
        _flat = const [];
        _flatKinds = const [];
        _rows = const [];
      });
      return;
    }

    // Surface "Searching…" only if nothing has been delivered after the
    // delay — and there is genuinely nothing on screen yet.
    _searchingTimer = Timer(_searchingDelay, () {
      if (mounted && _loading && _flat.isEmpty && !_showSearching) {
        setState(() => _showSearching = true);
      }
    });

    for (final source in relevant) {
      final sub = source
          .suggest(widget.query)
          .listen(
            (items) {
              if (!mounted) {
                return;
              }
              _bySource[source.kind] = items.take(_perSourceLimit).toList();
              _sourceGen[source.kind] = generation;
              _rebuild();
            },
            onError: (_) {
              if (!mounted) {
                return;
              }
              _bySource[source.kind] = const [];
              _sourceGen[source.kind] = generation;
              _rebuild();
            },
          );
      _subs.add(sub);
    }
  }

  void _rebuild() {
    final relevant = <MentionSource>[
      for (final source in widget.sources)
        if (source.triggers.contains(widget.query.trigger)) source,
    ];
    var allCurrent = relevant.isNotEmpty;
    for (final source in relevant) {
      if (_sourceGen[source.kind] != _generation) {
        allCurrent = false;
        break;
      }
    }
    final rows = <_Row>[];
    final flat = <MentionSuggestion>[];
    final flatKinds = <String>[];
    var idx = 0;
    for (final source in relevant) {
      final items = _bySource[source.kind];
      if (items == null || items.isEmpty) {
        continue;
      }
      final header = source.sectionLabel(context);
      if (header != null) {
        rows.add(_Row.header(header));
      }
      for (final s in items) {
        rows.add(_Row.item(s, idx, source.kind));
        flat.add(s);
        flatKinds.add(source.kind);
        idx++;
      }
    }
    setState(() {
      _rows = rows;
      _flat = flat;
      _flatKinds = flatKinds;
      _loading = !allCurrent;
      if (allCurrent) {
        _searchingTimer?.cancel();
        _showSearching = false;
      }
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
        // Commit only a row whose own source answered the current query — a
        // row from a still-lagging source answers the previous keystroke.
        // Synchronous sources (slash commands) re-deliver within a microtask,
        // so their rows are never held back.
        if (_sourceGen[_flatKinds[_selected]] == _generation) {
          widget.onSelect(_flat[_selected]);
        }
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
    if (_flat.isEmpty && !_showSearching) {
      return const SizedBox.shrink();
    }
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxHeight: _maxHeight),
        decoration: BoxDecoration(
          color: ds.bgPrimary,
          borderRadius: AppRadii.brMd,
          border: Border.all(color: ds.borderSecondary),
          boxShadow: AppShadows.golden,
        ),
        child: _flat.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  l10n.searching,
                  style: CcTypography.body.copyWith(color: ds.textTertiary),
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
      onTap: () {
        // Same per-source guard as Enter/Tab: a not-yet-refreshed row answers
        // an older keystroke.
        if (_sourceGen[row.sourceKind] == _generation) {
          widget.onSelect(s);
        }
      },
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
      constraints: const BoxConstraints(
        minHeight: _MentionPopupState._rowHeight,
      ),
      child: CcTappable(
        onPressed: onTap,
        mouseCursor: SystemMouseCursors.click,
        builder: (context, states) => MouseRegion(
          onEnter: (_) => onHover(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 60),
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: bg, borderRadius: AppRadii.brMd),
            child: Row(
              children: [
                if (suggestion.icon != null)
                  Icon(suggestion.icon, size: 16, color: ds.textTertiary),
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
                // Provenance, trailing: which repo a skill came from. It rides
                // beside the name rather than in the description because the
                // description is the skill's own words and would push it out.
                if (suggestion.badge != null && suggestion.badge!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: ds.bgTertiary,
                          borderRadius: AppRadii.brSm,
                          border: Border.all(color: ds.borderSecondary),
                        ),
                        child: Text(
                          suggestion.badge!,
                          style: CcTypography.caption.copyWith(
                            color: ds.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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
