import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// One facet in a [SettingsFilterBar].
@immutable
class SettingsFacet<T> {
  /// Creates a [SettingsFacet].
  const SettingsFacet({required this.value, required this.label, this.count});

  /// The value this facet selects.
  final T value;

  /// Localized label. Sentence case.
  final String label;

  /// How many rows the facet would show. Rendered beside the label so the
  /// reader can see there is nothing behind a facet before clicking it.
  final int? count;
}

/// Search plus facets plus a live count, for any settings list long enough that
/// scrolling is the wrong way to find something.
///
/// The rule the kit applies: a list of repeating rows past roughly eight items
/// earns one of these. Under that a filter is chrome; over it, the page has
/// silently become a search problem and pretending otherwise is what produced
/// the eighteen-provider wall.
///
/// The count is not decoration. It is the only thing that tells the reader
/// their query matched nothing versus matched everything, and it is what makes
/// a facet with zero rows honest instead of a dead end.
class SettingsFilterBar<T> extends StatelessWidget {
  /// Creates a [SettingsFilterBar].
  const SettingsFilterBar({
    super.key,
    required this.query,
    required this.onQueryChanged,
    this.searchHint,
    this.facets = const [],
    this.selectedFacet,
    this.onFacetChanged,
    this.resultLabel,
    this.trailing,
  });

  /// The live query text.
  final String query;

  /// Fired on every keystroke.
  final ValueChanged<String> onQueryChanged;

  /// Placeholder for the search field. Name what is searched, not "Search…".
  final String? searchHint;

  /// The facets, in display order. Empty hides the facet row entirely.
  final List<SettingsFacet<T>> facets;

  /// The selected facet value.
  final T? selectedFacet;

  /// Fired with the newly selected facet.
  final ValueChanged<T>? onFacetChanged;

  /// "6 of 18 providers" — already localized and pluralized by the caller.
  final String? resultLabel;

  /// Optional actions at the right (a refresh, an add).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _SearchField(
                query: query,
                onChanged: onQueryChanged,
                hint: searchHint ?? l10n.settingsFilterHint,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.md),
              trailing!,
            ],
          ],
        ),
        if (facets.isNotEmpty || resultLabel != null) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final facet in facets)
                      CcChip(
                        label: facet.count == null
                            ? facet.label
                            : '${facet.label}  ${facet.count}',
                        selected: facet.value == selectedFacet,
                        onPressed: onFacetChanged == null
                            ? null
                            : () => onFacetChanged!(facet.value),
                      ),
                  ],
                ),
              ),
              if (resultLabel != null) ...[
                const SizedBox(width: AppSpacing.md),
                Text(
                  resultLabel!,
                  style: CcTypography.caption.copyWith(
                    color: tokens.textTertiary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

/// Owns its controller so typing survives the parent rebuilding on every
/// keystroke, and re-seeds when the query is cleared from outside.
class _SearchField extends StatefulWidget {
  const _SearchField({
    required this.query,
    required this.onChanged,
    required this.hint,
  });

  final String query;
  final ValueChanged<String> onChanged;
  final String hint;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.query,
  );

  @override
  void didUpdateWidget(covariant _SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != oldWidget.query && widget.query != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.query,
        selection: TextSelection.collapsed(offset: widget.query.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return CcTextField(
      controller: _controller,
      hintText: widget.hint,
      size: CcTextFieldSize.sm,
      onChanged: widget.onChanged,
      prefix: Icon(AppIcons.search, size: 15, color: tokens.fgQuaternary),
      suffix: widget.query.isEmpty
          ? null
          : CcIconButton(
              icon: AppIcons.x,
              size: CcButtonSize.sm,
              variant: CcButtonVariant.ghost,
              tooltip: l10n.clear,
              onPressed: () {
                _controller.clear();
                widget.onChanged('');
              },
            ),
    );
  }
}
