import 'package:cc_domain/features/pr_review/domain/entities/pr_label.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/notifiers/pr_edit_notifier.dart';
import 'package:control_center/features/pr_review/presentation/widgets/picker_flyout.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

String _key(String name) => name.toLowerCase();

bool _has(Iterable<String> names, String name) =>
    names.any((candidate) => _key(candidate) == _key(name));

/// The compact `+` on the Labels rail. Opens a flyout of the repository's
/// labels, already-applied ones first; closing it saves the diff.
class LabelPickerHeader extends ConsumerStatefulWidget {
  /// Creates a [LabelPickerHeader].
  const LabelPickerHeader({
    super.key,
    required this.prRef,
    required this.current,
    required this.enabled,
    this.compact = false,
  });

  /// The pull request these labels belong to.
  final PrRef prRef;

  /// Labels currently on the pull request.
  final List<PrLabel> current;

  /// Whether editing is allowed. When false and [compact], renders nothing.
  final bool enabled;

  /// When true, renders only the `+` affordance for a section header.
  final bool compact;

  @override
  ConsumerState<LabelPickerHeader> createState() => _LabelPickerHeaderState();
}

class _LabelPickerHeaderState extends ConsumerState<LabelPickerHeader> {
  final LayerLink _link = LayerLink();
  final OverlayPortalController _overlay = OverlayPortalController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  Set<String> _selected = {};
  String _query = '';
  List<PrLabel> _catalog = const [];
  bool _loading = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _open() {
    _selected = {for (final label in widget.current) label.name};
    _query = '';
    _searchController.clear();
    _overlay.show();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocus.requestFocus();
      }
    });
    setState(() {});
  }

  void _toggleOpen() {
    if (_overlay.isShowing) {
      _close();
    } else {
      _open();
    }
  }

  Future<void> _close() async {
    if (!_overlay.isShowing) {
      return;
    }
    _overlay.hide();
    await _apply();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _apply() async {
    final current = [for (final label in widget.current) label.name];
    final add = _selected.where((name) => !_has(current, name)).toList();
    final remove = current.where((name) => !_has(_selected, name)).toList();
    if (add.isEmpty && remove.isEmpty) {
      return;
    }
    final toaster = CcToastScope.of(context);
    final l10n = AppLocalizations.of(context);
    final error = await ref
        .read(prEditProvider(widget.prRef).notifier)
        .applyLabelChanges(add: add, remove: remove);
    if (error != null && mounted) {
      toaster.show(
        l10n.failedToUpdateLabels(error),
        variant: CcToastVariant.danger,
      );
    }
  }

  void _toggle(PrLabel label) {
    setState(() {
      if (_has(_selected, label.name)) {
        _selected.removeWhere((name) => _key(name) == _key(label.name));
      } else {
        _selected.add(label.name);
      }
    });
  }

  /// Catalog rows plus any label already on the PR that the catalog omitted,
  /// so it can still be unchecked. Catalog color wins when both exist.
  List<PrLabel> _merged() {
    final byKey = <String, PrLabel>{
      for (final label in widget.current) _key(label.name): label,
    };
    for (final label in _catalog) {
      byKey[_key(label.name)] = label;
    }
    return byKey.values.toList();
  }

  List<PrLabel> _matching(List<PrLabel> labels) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return labels;
    }
    return [
      for (final label in labels)
        if (label.name.toLowerCase().contains(query) ||
            label.description.toLowerCase().contains(query))
          label,
    ];
  }

  List<PrLabel> _selectedLabels(List<PrLabel> merged) {
    final byKey = {for (final label in merged) _key(label.name): label};
    final seen = <String>{};
    final out = <PrLabel>[];
    for (final label in widget.current) {
      final key = _key(label.name);
      if (_has(_selected, label.name) && seen.add(key)) {
        out.add(byKey[key] ?? label);
      }
    }
    for (final label in merged) {
      final key = _key(label.name);
      if (_has(_selected, label.name) && seen.add(key)) {
        out.add(label);
      }
    }
    return out;
  }

  List<PrLabel> _rest(List<PrLabel> merged) {
    final rest = merged.where((label) => !_has(_selected, label.name)).toList();
    rest.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return rest;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_overlay.isShowing) {
      final async = ref.watch(repoLabelsProvider(widget.prRef));
      _catalog = async.value ?? const [];
      _loading = async.isLoading && _catalog.isEmpty && widget.current.isEmpty;
    }
    if (widget.compact && !widget.enabled) {
      return const SizedBox.shrink();
    }
    final child = widget.compact
        ? CompactPickerAddButton(
            semanticLabel: l10n.addLabels,
            onPressed: _toggleOpen,
          )
        : CcTappable(
            onPressed: widget.enabled ? _toggleOpen : null,
            builder: (context, states) => Text(l10n.labels),
          );
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _overlay,
        overlayChildBuilder: _buildFlyout,
        child: child,
      ),
    );
  }

  Widget _buildFlyout(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final searching = _query.trim().isNotEmpty;
    final Widget list;
    if (_loading) {
      list = const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(child: CcSpinner()),
      );
    } else {
      final merged = _matching(_merged());
      final rows = searching
          ? [for (final label in merged) _row(label)]
          : _groupedRows(tokens, merged);
      if (rows.isEmpty) {
        list = Padding(
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Center(
            child: Text(
              l10n.noMatchingLabels,
              style: TextStyle(fontSize: 13, color: tokens.textQuaternary),
            ),
          ),
        );
      } else {
        list = ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
          children: rows,
        );
      }
    }
    return PickerFlyoutPanel(
      link: _link,
      title: l10n.addLabels,
      searchController: _searchController,
      searchFocus: _searchFocus,
      hintText: l10n.searchLabels,
      onQueryChanged: (value) => setState(() => _query = value),
      onClose: _close,
      list: list,
    );
  }

  List<Widget> _groupedRows(DesignSystemTokens tokens, List<PrLabel> merged) {
    final rows = <Widget>[
      for (final label in _selectedLabels(merged)) _row(label),
    ];
    final rest = _rest(merged);
    if (rest.isNotEmpty) {
      if (rows.isNotEmpty) {
        rows.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Container(height: 1, color: tokens.borderSecondary),
          ),
        );
      }
      for (final label in rest) {
        rows.add(_row(label));
      }
    }
    return rows;
  }

  Widget _row(PrLabel label) => _LabelFlyoutRow(
    label: label,
    selected: _has(_selected, label.name),
    onTap: () => _toggle(label),
  );
}

class _LabelFlyoutRow extends StatelessWidget {
  const _LabelFlyoutRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final PrLabel label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final swatch = CcColorTag.parseHex(label.color) ?? tokens.fgQuaternary;
    final name = Text(
      label.name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: tokens.textPrimary,
      ),
    );
    return CcTappable(
      onPressed: onTap,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return Container(
          color: hovered ? tokens.bgPrimaryHover : const Color(0x00000000),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            children: [
              PickerCheckBox(selected: selected, hovered: hovered),
              const SizedBox(width: 10),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: swatch,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: label.description.isEmpty
                    ? name
                    : CcTooltip(message: label.description, child: name),
              ),
            ],
          ),
        );
      },
    );
  }
}
