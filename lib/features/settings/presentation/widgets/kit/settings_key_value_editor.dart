import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_key_value_pair.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// A real editor for a map, in place of a text field holding JSON.
///
/// The SSO group-to-role mapping was a single-line box you typed
/// `{"platform-leads": "admin"}` into, parsed by a regex with a fallback parser
/// behind it, where a missing quote silently saved "no mapping at all". A map
/// is a list of pairs, so this renders a list of pairs: a key field, an arrow,
/// a value (free text, or a select when the values are a closed set), and a
/// remove button. Nothing to escape, nothing to get subtly wrong, and an
/// invalid role is now unpickable rather than accepted and dropped.
///
/// Empty keys are skipped on emit, so a half-typed row costs nothing.
class SettingsKeyValueEditor extends StatefulWidget {
  /// Creates a [SettingsKeyValueEditor].
  const SettingsKeyValueEditor({
    super.key,
    required this.entries,
    required this.onChanged,
    this.keyHint,
    this.valueHint,
    this.valueOptions,
    this.addLabel,
    this.emptyLabel,
    this.obscureValues = false,
    this.enabled = true,
  });

  /// The current pairs. Order is preserved as given.
  final List<SettingsKeyValuePair> entries;

  /// Fired with the full pair list after every edit.
  final ValueChanged<List<SettingsKeyValuePair>> onChanged;

  /// Placeholder for the key field.
  final String? keyHint;

  /// Placeholder for the value field. Ignored when [valueOptions] is set.
  final String? valueHint;

  /// When set, the value is a select over this closed list instead of free
  /// text.
  final List<CcSelectOption<String>>? valueOptions;

  /// Label for the add button.
  final String? addLabel;

  /// What to say when there are no pairs, and what adding one would do.
  final String? emptyLabel;

  /// Masks the value field (env vars can hold secrets).
  final bool obscureValues;

  /// Disables every control.
  final bool enabled;

  @override
  State<SettingsKeyValueEditor> createState() => _SettingsKeyValueEditorState();
}

class _SettingsKeyValueEditorState extends State<SettingsKeyValueEditor> {
  final _rows = <_Row>[];
  late List<SettingsKeyValuePair> _emitted;

  @override
  void initState() {
    super.initState();
    _seed(widget.entries);
    _emitted = List.of(widget.entries);
  }

  @override
  void didUpdateWidget(covariant SettingsKeyValueEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-seed only when the parent supplies something we did not just emit —
    // otherwise every keystroke would rebuild the controllers under the cursor
    // and typing would drop characters.
    if (!_listEquals(widget.entries, _emitted)) {
      setState(() {
        _seed(widget.entries);
        _emitted = List.of(widget.entries);
      });
    }
  }

  static bool _listEquals(
    List<SettingsKeyValuePair> a,
    List<SettingsKeyValuePair> b,
  ) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  void _seed(List<SettingsKeyValuePair> entries) {
    if (_rows.isNotEmpty) {
      final stale = List.of(_rows);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final row in stale) {
          row.dispose();
        }
      });
    }
    _rows
      ..clear()
      ..addAll(
        entries.map(
          (e) => _Row(e.key, e.value, usesSelect: widget.valueOptions != null),
        ),
      );
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _emit() {
    final pairs = [
      for (final row in _rows)
        if (row.key.text.trim().isNotEmpty)
          SettingsKeyValuePair(row.key.text.trim(), row.value),
    ];
    _emitted = pairs;
    widget.onChanged(pairs);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_rows.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              widget.emptyLabel ?? l10n.settingsNoEntriesYet,
              style: CcTypography.caption.copyWith(color: tokens.textTertiary),
            ),
          ),
        for (var i = 0; i < _rows.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _buildRow(context, i, tokens, l10n),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: CcButton(
            variant: CcButtonVariant.secondary,
            size: CcButtonSize.sm,
            icon: AppIcons.plus,
            onPressed: widget.enabled
                ? () => setState(
                    () => _rows.add(
                      _Row(
                        '',
                        _defaultValue(),
                        usesSelect: widget.valueOptions != null,
                      ),
                    ),
                  )
                : null,
            child: Text(widget.addLabel ?? l10n.add),
          ),
        ),
      ],
    );
  }

  String _defaultValue() => widget.valueOptions?.first.value ?? '';

  Widget _buildRow(
    BuildContext context,
    int index,
    DesignSystemTokens tokens,
    AppLocalizations l10n,
  ) {
    final row = _rows[index];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 5,
          child: CcTextField(
            controller: row.key,
            hintText: widget.keyHint,
            size: CcTextFieldSize.sm,
            enabled: widget.enabled,
            onChanged: (_) => _emit(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Icon(
            AppIcons.arrowRight,
            size: 14,
            color: tokens.fgQuaternary,
          ),
        ),
        Expanded(
          flex: 4,
          child: widget.valueOptions == null
              ? CcTextField(
                  controller: row.valueController!,
                  hintText: widget.valueHint,
                  size: CcTextFieldSize.sm,
                  enabled: widget.enabled,
                  obscureText: widget.obscureValues,
                  onChanged: (_) => _emit(),
                )
              : CcSelect<String>(
                  options: widget.valueOptions!,
                  value: widget.valueOptions!.any((o) => o.value == row.value)
                      ? row.value
                      : null,
                  hintText: widget.valueHint,
                  enabled: widget.enabled,
                  onChanged: (v) {
                    setState(() => row.selected = v);
                    _emit();
                  },
                ),
        ),
        const SizedBox(width: AppSpacing.xs),
        CcIconButton(
          icon: AppIcons.x,
          size: CcButtonSize.sm,
          variant: CcButtonVariant.ghost,
          tooltip: l10n.remove,
          onPressed: widget.enabled
              ? () {
                  final removed = _rows[index];
                  setState(() => _rows.removeAt(index));
                  _emit();
                  // Disposed after the frame that drops it from the tree: a
                  // controller disposed while a field still references it
                  // throws on the next rebuild.
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => removed.dispose(),
                  );
                }
              : null,
        ),
      ],
    );
  }
}

/// One editable pair. Holds a controller for the key, and either a controller
/// (free text) or a plain string (select) for the value — a select has no
/// controller to own and giving it one would mean two sources of truth for the
/// same value.
class _Row {
  _Row(String key, String value, {required bool usesSelect})
    : key = TextEditingController(text: key),
      valueController = usesSelect ? null : TextEditingController(text: value),
      selected = value;

  final TextEditingController key;
  final TextEditingController? valueController;
  String selected;

  String get value => valueController?.text ?? selected;

  void dispose() {
    key.dispose();
    valueController?.dispose();
  }
}
