import 'dart:math' as math;

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/providers/model_browser_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Opens the model browser for [adapterId] and resolves to the chosen model
/// id — a listed model or a typed custom id — or null when dismissed.
Future<String?> showModelBrowserDialog({
  required BuildContext context,
  required String? adapterId,
  String? selectedModelId,
}) => showCcDialog<String>(
  context: context,
  builder: (_) => ModelBrowserDialog(
    adapterId: adapterId,
    selectedModelId: selectedModelId,
  ),
);

/// A navigable model catalog: a provider rail, a searched list with per-model
/// metadata (context, price, reasoning), and a detail footer for the
/// highlighted row.
///
/// Replaces the flat autocomplete for adapters whose model list runs to the
/// hundreds (the built-in harness with a few providers connected): a single
/// unsectioned overlay makes "what does openai serve?" a scroll hunt, and it
/// had nowhere to show the metadata that actually drives the choice. Free-text
/// ids survive: a query matching nothing offers itself as a custom id, which
/// is how models newer than any catalog are reached.
class ModelBrowserDialog extends ConsumerStatefulWidget {
  /// Creates a [ModelBrowserDialog].
  const ModelBrowserDialog({
    super.key,
    required this.adapterId,
    this.selectedModelId,
  });

  /// The adapter whose models are browsed.
  final String? adapterId;

  /// The currently saved model id, marked in the list and highlighted first.
  final String? selectedModelId;

  @override
  ConsumerState<ModelBrowserDialog> createState() => _ModelBrowserDialogState();
}

/// One renderable line of the list: a provider header, a model, or the
/// "use custom id" action.
sealed class _Item {
  const _Item();
}

class _HeaderItem extends _Item {
  const _HeaderItem(this.name);
  final String name;
}

class _EntryItem extends _Item {
  const _EntryItem(this.entry);
  final ModelBrowserEntry entry;
}

class _CustomItem extends _Item {
  const _CustomItem(this.id);
  final String id;
}

class _ModelBrowserDialogState extends ConsumerState<ModelBrowserDialog> {
  static const double _headerExtent = 30;
  static const double _rowExtent = 46;

  final TextEditingController _searchCtl = TextEditingController();
  final ScrollController _listCtl = ScrollController();

  String? _providerId; // null = all models

  /// Index into the selectable (non-header) items.
  int _highlight = 0;

  /// Whether the initial highlight was aligned to the saved selection.
  bool _seeded = false;

  @override
  void dispose() {
    _searchCtl.dispose();
    _listCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final groupsAsync = ref.watch(modelBrowserGroupsProvider(widget.adapterId));
    final maxHeight = math.min(520.0, MediaQuery.sizeOf(context).height - 160);

    return CcDialog(
      title: l10n.selectModel,
      maxWidth: 760,
      onClose: () => Navigator.of(context).pop(),
      content: SizedBox(
        height: maxHeight,
        child: groupsAsync.when(
          loading: () =>
              Center(child: CcSpinner(semanticLabel: l10n.loadingModels)),
          error: (e, _) => Center(
            child: Text(
              l10n.failedWithError('$e'),
              style: CcTypography.bodySm.copyWith(color: context.ds.danger),
            ),
          ),
          data: (groups) => _body(context, l10n, groups),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l10n,
    List<ModelBrowserGroup> groups,
  ) {
    final t = context.ds;
    final query = _searchCtl.text.trim();

    // Rail filter first, then search — the rail scopes what search runs over.
    final visibleGroups = [
      for (final g in groups)
        if (_providerId == null || g.id == _providerId)
          if (g.models.where((m) => m.matches(query)).toList()
              case final matched when matched.isNotEmpty)
            ModelBrowserGroup(id: g.id, name: g.name, models: matched),
    ];

    // Flatten to renderable lines; headers only when more than one group is
    // visible (a lone header repeats the rail selection it sits under).
    final items = <_Item>[];
    final showHeaders = visibleGroups.length > 1;
    for (final g in visibleGroups) {
      if (showHeaders) {
        items.add(_HeaderItem(g.name));
      }
      items.addAll([for (final m in g.models) _EntryItem(m)]);
    }
    // A query no listed model matches is offered back as a custom id — the
    // free-text lane the autocomplete used to provide.
    final noMatches = items.isEmpty;
    if (noMatches && query.isNotEmpty) {
      items.add(_CustomItem(query));
    }
    final selectable = <int>[
      for (var i = 0; i < items.length; i++)
        if (items[i] is! _HeaderItem) i,
    ];

    if (!_seeded) {
      _seeded = true;
      final saved = selectable.indexWhere(
        (i) =>
            items[i] is _EntryItem &&
            (items[i] as _EntryItem).entry.id == widget.selectedModelId,
      );
      if (saved > 0) {
        _highlight = saved;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _ensureVisible(items, selectable),
        );
      }
    }
    if (_highlight >= selectable.length) {
      _highlight = selectable.isEmpty ? 0 : selectable.length - 1;
    }
    final focused = selectable.isEmpty ? null : items[selectable[_highlight]];

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
            _move(1, items, selectable),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
            _move(-1, items, selectable),
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CcTextField(
            controller: _searchCtl,
            hintText: l10n.searchOrTypeModel,
            prefix: Icon(CcIcons.search, size: 16, color: t.fgTertiary),
            autofocus: true,
            onChanged: (_) => setState(() => _highlight = 0),
            onSubmitted: (_) => _commit(focused),
          ),
          AppSpacing.vGapMd,
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (groups.length > 1) ...[
                  SizedBox(width: 190, child: _rail(l10n, groups)),
                  AppSpacing.hGapMd,
                  Container(width: 1, color: t.borderPrimary),
                  AppSpacing.hGapMd,
                ],
                Expanded(
                  child: noMatches && query.isEmpty
                      ? Center(
                          child: Text(
                            widget.adapterId == 'cc-harness'
                                ? l10n.harnessConnectProviderForModels
                                : l10n.noModelsAdvertised,
                            style: CcTypography.bodySm.copyWith(
                              color: t.textTertiary,
                            ),
                          ),
                        )
                      : _list(l10n, items, selectable),
                ),
              ],
            ),
          ),
          AppSpacing.vGapSm,
          Container(height: 1, color: t.borderPrimary),
          AppSpacing.vGapSm,
          _footer(l10n, focused),
        ],
      ),
    );
  }

  // ─── Rail ─────────────────────────────────────────────────────────────────

  Widget _rail(AppLocalizations l10n, List<ModelBrowserGroup> groups) {
    final q = _searchCtl.text;
    final total = groups.fold<int>(0, (n, g) => n + g.matchCount(q));
    return CcScrollArea(
      child: ListView(
        children: [
          _railItem(label: l10n.allModels, count: total, id: null),
          for (final g in groups)
            _railItem(label: g.name, count: g.matchCount(q), id: g.id),
        ],
      ),
    );
  }

  Widget _railItem({
    required String label,
    required int count,
    required String? id,
  }) {
    final t = context.ds;
    final selected = _providerId == id;
    return CcTappable(
      onPressed: () => setState(() {
        _providerId = id;
        _highlight = 0;
        if (_listCtl.hasClients) {
          _listCtl.jumpTo(0);
        }
      }),
      borderRadius: AppRadii.brSm,
      semanticLabel: label,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return Container(
          padding: const EdgeInsetsDirectional.fromSTEB(10, 7, 10, 7),
          decoration: BoxDecoration(
            color: selected
                ? t.accentSoft
                : hovered
                ? t.bgSecondaryHover
                : null,
            borderRadius: AppRadii.brSm,
          ),
          child: Row(
            children: [
              Expanded(
                child: CcTruncatedText(
                  label,
                  style: CcTypography.bodySm.copyWith(
                    color: selected ? t.textPrimary : t.textSecondary,
                  ),
                ),
              ),
              AppSpacing.hGapSm,
              Text(
                '$count',
                style: CcTypography.caption.copyWith(color: t.textTertiary),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── List ─────────────────────────────────────────────────────────────────

  Widget _list(AppLocalizations l10n, List<_Item> items, List<int> selectable) {
    return CcScrollArea(
      child: ListView.builder(
        controller: _listCtl,
        itemCount: items.length,
        itemBuilder: (context, i) => switch (items[i]) {
          final _HeaderItem h => _header(h),
          final _EntryItem e => _entryRow(l10n, e, selectable.indexOf(i)),
          final _CustomItem c => _customRow(l10n, c, selectable.indexOf(i)),
        },
      ),
    );
  }

  Widget _header(_HeaderItem h) {
    final t = context.ds;
    return SizedBox(
      height: _headerExtent,
      child: Align(
        alignment: AlignmentDirectional.bottomStart,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(10, 0, 10, 6),
          child: Text(
            h.name,
            style: CcTypography.caption.copyWith(color: t.textTertiary),
          ),
        ),
      ),
    );
  }

  Widget _entryRow(
    AppLocalizations l10n,
    _EntryItem item,
    int selectableIndex,
  ) {
    final t = context.ds;
    final e = item.entry;
    final highlighted = selectableIndex == _highlight;
    final selected = e.id == widget.selectedModelId;
    return _selectableRow(
      selectableIndex: selectableIndex,
      highlighted: highlighted,
      semanticLabel: e.name,
      onPressed: () => Navigator.of(context).pop(e.id),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CcTruncatedText(
                  e.name,
                  style: CcTypography.bodySm.copyWith(color: t.textPrimary),
                ),
                if (e.id != e.name)
                  CcTruncatedText(
                    e.id,
                    style: CcTypography.caption.copyWith(color: t.textTertiary),
                  ),
              ],
            ),
          ),
          AppSpacing.hGapSm,
          if (e.reasoning)
            CcTooltip(
              message: l10n.modelSupportsReasoning,
              child: Icon(CcIcons.sparkles, size: 13, color: t.fgTertiary),
            ),
          if (e.contextWindow case final ctx?) ...[
            AppSpacing.hGapSm,
            SizedBox(
              width: 44,
              child: Text(
                compactTokenCount(ctx),
                textAlign: TextAlign.end,
                style: CcTypography.caption.copyWith(color: t.textTertiary),
              ),
            ),
          ],
          AppSpacing.hGapSm,
          SizedBox(
            width: 76,
            child: Text(
              _rowPrice(l10n, e),
              textAlign: TextAlign.end,
              style: CcTypography.caption.copyWith(color: t.textTertiary),
            ),
          ),
          if (selected) ...[
            AppSpacing.hGapSm,
            Icon(CcIcons.check, size: 14, color: t.accent),
          ],
        ],
      ),
    );
  }

  Widget _customRow(
    AppLocalizations l10n,
    _CustomItem item,
    int selectableIndex,
  ) {
    final t = context.ds;
    return _selectableRow(
      selectableIndex: selectableIndex,
      highlighted: selectableIndex == _highlight,
      semanticLabel: l10n.useCustomModelId(item.id),
      onPressed: () => Navigator.of(context).pop(item.id),
      child: Row(
        children: [
          Icon(CcIcons.search, size: 14, color: t.fgTertiary),
          AppSpacing.hGapSm,
          Expanded(
            child: CcTruncatedText(
              l10n.useCustomModelId(item.id),
              style: CcTypography.bodySm.copyWith(color: t.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectableRow({
    required int selectableIndex,
    required bool highlighted,
    required String semanticLabel,
    required VoidCallback onPressed,
    required Widget child,
  }) {
    final t = context.ds;
    return MouseRegion(
      onEnter: (_) => setState(() => _highlight = selectableIndex),
      child: CcTappable(
        onPressed: onPressed,
        borderRadius: AppRadii.brSm,
        semanticLabel: semanticLabel,
        builder: (context, states) => Container(
          height: _rowExtent,
          padding: const EdgeInsetsDirectional.fromSTEB(10, 0, 10, 0),
          decoration: BoxDecoration(
            color: highlighted ? t.bgSecondaryHover : null,
            borderRadius: AppRadii.brSm,
          ),
          child: child,
        ),
      ),
    );
  }

  // ─── Footer ───────────────────────────────────────────────────────────────

  /// The highlighted row's full metadata — the detail that does not fit in a
  /// list line (exact prices, output ceiling, the effort vocabulary).
  Widget _footer(AppLocalizations l10n, _Item? focused) {
    final t = context.ds;
    final caption = CcTypography.caption.copyWith(color: t.textTertiary);
    if (focused is! _EntryItem) {
      final text = focused is _CustomItem
          ? focused.id
          : l10n.noModelsMatchSearch;
      return Text(text, style: caption);
    }
    final e = focused.entry;
    final fmt = NumberFormat(
      '0.##',
      Localizations.localeOf(context).toString(),
    );
    final parts = <String>[
      if (e.contextWindow case final ctx?)
        l10n.contextTokens(compactTokenCount(ctx)),
      if (e.maxOutput case final out?)
        l10n.modelOutputTokens(compactTokenCount(out)),
      if (e.isFree)
        l10n.modelFree
      else if (e.hasKnownCost)
        l10n.modelPricePerMTokens(
          '\$${fmt.format(e.inputCost ?? 0)}',
          '\$${fmt.format(e.outputCost ?? 0)}',
        ),
      if (e.thinkingLevels case final levels?)
        if (levels.isNotEmpty)
          l10n.modelEffortLevels(levels.map((l) => l.label).join(' · ')),
    ];
    return Row(
      children: [
        Flexible(
          child: CcTruncatedText(
            e.name,
            style: CcTypography.bodySm.copyWith(color: t.textPrimary),
          ),
        ),
        if (parts.isNotEmpty) ...[
          AppSpacing.hGapSm,
          Expanded(
            flex: 3,
            child: CcTruncatedText(parts.join('  ·  '), style: caption),
          ),
        ],
      ],
    );
  }

  // ─── Behavior ─────────────────────────────────────────────────────────────

  void _move(int delta, List<_Item> items, List<int> selectable) {
    if (selectable.isEmpty) {
      return;
    }
    setState(() {
      _highlight = (_highlight + delta).clamp(0, selectable.length - 1);
    });
    _ensureVisible(items, selectable);
  }

  void _commit(_Item? focused) {
    switch (focused) {
      case _EntryItem(:final entry):
        Navigator.of(context).pop(entry.id);
      case _CustomItem(:final id):
        Navigator.of(context).pop(id);
      case _HeaderItem() || null:
        break;
    }
  }

  /// Scrolls the list so the highlighted row is inside the viewport. Offsets
  /// are computed from the fixed item extents — rows are built lazily, so
  /// there is no render object to `ensureVisible` against.
  void _ensureVisible(List<_Item> items, List<int> selectable) {
    if (!_listCtl.hasClients || selectable.isEmpty) {
      return;
    }
    final layoutIndex = selectable[_highlight];
    var top = 0.0;
    for (var i = 0; i < layoutIndex; i++) {
      top += items[i] is _HeaderItem ? _headerExtent : _rowExtent;
    }
    final bottom = top + _rowExtent;
    final position = _listCtl.position;
    if (top < position.pixels) {
      _listCtl.jumpTo(top);
    } else if (bottom > position.pixels + position.viewportDimension) {
      _listCtl.jumpTo(bottom - position.viewportDimension);
    }
  }

  String _rowPrice(AppLocalizations l10n, ModelBrowserEntry e) {
    if (!e.hasKnownCost) {
      return '—';
    }
    if (e.isFree) {
      return l10n.modelFree;
    }
    final fmt = NumberFormat(
      '0.##',
      Localizations.localeOf(context).toString(),
    );
    return '\$${fmt.format(e.inputCost ?? 0)}/${fmt.format(e.outputCost ?? 0)}';
  }
}

/// Formats a token count compactly (200000 → "200k", 1048576 → "1M").
String compactTokenCount(int tokens) {
  if (tokens >= 1000000) {
    final m = tokens / 1000000;
    return '${m == m.roundToDouble() ? m.toInt() : m.toStringAsFixed(1)}M';
  }
  if (tokens >= 1000) {
    return '${(tokens / 1000).round()}k';
  }
  return '$tokens';
}
