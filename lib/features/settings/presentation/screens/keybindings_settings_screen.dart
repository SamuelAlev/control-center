import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/constants/keybindings.dart';
import 'package:control_center/features/settings/presentation/widgets/settings_shortcuts.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/kbd.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Keybindings: read-only reference page for all shortcuts.
class KeybindingsSettingsScreen extends ConsumerStatefulWidget {
  /// Creates the keybindings settings page.
  const KeybindingsSettingsScreen({super.key});

  @override
  ConsumerState<KeybindingsSettingsScreen> createState() =>
      _KeybindingsSettingsScreenState();
}

class _KeybindingsSettingsScreenState
    extends ConsumerState<KeybindingsSettingsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final platform = defaultTargetPlatform;
    final all = KeybindingRegistry.all;
    final filtered = _query.isEmpty
        ? all
        : all.where((b) {
            final q = _query.toLowerCase();
            return b.resolvedLabel(l10n).toLowerCase().contains(q) ||
                b.resolvedDescription(l10n).toLowerCase().contains(q) ||
                b.id.toLowerCase().contains(q);
          }).toList();

    final grouped = <KeybindingCategory, List<Keybinding>>{};
    for (final b in filtered) {
      grouped.putIfAbsent(b.category, () => []).add(b);
    }
    final categories = grouped.entries.toList()
      ..sort((a, b) => a.key.index.compareTo(b.key.index));

    return SettingsShortcuts(
      child: PageWrapper(
      title: l10n.keybindings,
      subtitle: l10n.keybindingsDescription,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          _SearchField(
            query: _query,
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            _EmptyQuery(query: _query)
          else
            ...categories.expand((entry) {
              return [
                _CategoryHeader(label: _categoryLabel(entry.key)),
                const SizedBox(height: 4),
                ...entry.value.map((b) => _BindingRow(binding: b, platform: platform)),
                const SizedBox(height: 20),
              ];
            }),
        ],
      ),
    ),
    );
  }

  String _categoryLabel(KeybindingCategory category) {
    final l10n = AppLocalizations.of(context);
    return switch (category) {
      KeybindingCategory.navigation => l10n.categoryNavigation,
      KeybindingCategory.system => l10n.categorySystem,
      KeybindingCategory.creation => l10n.categoryCreation,
      KeybindingCategory.editing => l10n.categoryEditing,
      KeybindingCategory.deletion => l10n.categoryDeletion,
      KeybindingCategory.view => l10n.categoryView,
    };
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField({required this.query, required this.onChanged});

  final String query;
  final ValueChanged<String> onChanged;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
    _controller.addListener(() => widget.onChanged(_controller.text));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return CcTextField(
      controller: _controller,
      hintText: l10n.searchShortcuts,
      prefix: Icon(AppIcons.search, size: 16, color: tokens.textTertiary),
    );
  }
}

class _EmptyQuery extends StatelessWidget {
  const _EmptyQuery({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.searchX, size: 32, color: tokens.textTertiary),
            const SizedBox(height: 12),
            Text(
              l10n.noShortcutsMatch(query),
              style: TextStyle(color: tokens.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        label.toUpperCase(),
        style: CcTypography.body.copyWith(
          color: tokens.textTertiary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _BindingRow extends StatelessWidget {
  const _BindingRow({required this.binding, required this.platform});

  final Keybinding binding;
  final TargetPlatform platform;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  binding.resolvedLabel(l10n),
                  style: CcTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  binding.resolvedDescription(l10n),
                  style: CcTypography.caption.copyWith(
                    color: tokens.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (binding.scope != 'global') ...[
                  _ScopeChip(scope: binding.scope),
                  const SizedBox(width: 8),
                ],
                Kbd.key(
                  shortcutKey: binding.key,
                  meta: binding.meta,
                  control: binding.control,
                  shift: binding.shift,
                  alt: binding.alt,
                  compact: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({required this.scope});

  final String scope;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: tokens.bgSecondary,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: tokens.borderSecondary),
      ),
      child: Text(
        scope == 'global' ? 'global' : scope,
        style: CcTypography.caption.copyWith(
          color: tokens.textTertiary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
