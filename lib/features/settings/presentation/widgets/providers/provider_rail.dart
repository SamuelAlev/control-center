import 'package:cc_harness/provider.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// The left rail of the providers master-detail: every provider the harness
/// knows, connected ones first, each with a live status dot, and the
/// custom-provider group with its "Add provider" row at the bottom.
///
/// The rail answers "what can agents here run on?" at a glance — the detail
/// pane only ever answers for ONE provider, so selection state lives with the
/// list.
class ProviderRail extends StatelessWidget {
  /// Creates a [ProviderRail].
  const ProviderRail({
    super.key,
    required this.providers,
    required this.deniedIds,
    required this.query,
    required this.onQueryChanged,
    required this.selectedId,
    required this.addingProvider,
    required this.onSelected,
    required this.onAddProvider,
  });

  /// Every provider (built-in and custom), unsorted.
  final List<HarnessProviderInfo> providers;

  /// Provider ids denied by a workspace `provider.use` policy.
  final Set<String> deniedIds;

  /// The live rail search text.
  final String query;

  /// Fired on every keystroke.
  final ValueChanged<String> onQueryChanged;

  /// The selected provider id; null while the add-provider pane is showing.
  final String? selectedId;

  /// Whether the add-provider pane is showing.
  final bool addingProvider;

  /// Fired when a provider row is activated.
  final ValueChanged<String> onSelected;

  /// Fired when the "Add provider" row is activated.
  final VoidCallback onAddProvider;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final q = query.trim().toLowerCase();
    bool matches(HarnessProviderInfo p) =>
        q.isEmpty ||
        p.displayName.toLowerCase().contains(q) ||
        p.id.contains(q);

    final builtins = providers.where((p) => !p.isCustom && matches(p)).toList()
      ..sort((a, b) {
        final byState = _rank(b) - _rank(a);
        return byState != 0
            ? byState
            : a.displayName.toLowerCase().compareTo(
                b.displayName.toLowerCase(),
              );
      });
    final customs = providers.where((p) => p.isCustom && matches(p)).toList()
      ..sort(
        (a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        CcTextField(
          hintText: l10n.providersFilterHint,
          size: CcTextFieldSize.sm,
          prefix: Icon(AppIcons.search, size: 15, color: tokens.fgQuaternary),
          onChanged: onQueryChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        SettingsRailGroupLabel(label: l10n.railProvidersGroup),
        const SizedBox(height: AppSpacing.xs),
        if (builtins.isEmpty && q.isNotEmpty)
          SettingsRailEmptyNote(message: l10n.providersNoneMatch)
        else
          for (final p in builtins)
            SettingsRailItem(
              label: p.displayName,
              tone: _tone(p, deniedIds.contains(p.id)),
              statusLabel: _statusLabel(l10n, p, deniedIds.contains(p.id)),
              selected: selectedId == p.id && !addingProvider,
              onPressed: () => onSelected(p.id),
            ),
        const SizedBox(height: AppSpacing.lg),
        SettingsRailGroupLabel(label: l10n.railCustomProvidersGroup),
        const SizedBox(height: AppSpacing.xs),
        if (customs.isEmpty && q.isEmpty)
          SettingsRailEmptyNote(message: l10n.noCustomProviders)
        else
          for (final p in customs)
            SettingsRailItem(
              label: p.displayName,
              tone: _tone(p, deniedIds.contains(p.id)),
              statusLabel: _statusLabel(l10n, p, deniedIds.contains(p.id)),
              selected: selectedId == p.id && !addingProvider,
              onPressed: () => onSelected(p.id),
            ),
        const SizedBox(height: AppSpacing.xs),
        SettingsRailItem(
          label: l10n.addProvider,
          icon: AppIcons.plus,
          selected: addingProvider,
          onPressed: onAddProvider,
        ),
      ],
    );
  }

  /// Connected (1) sorts above unconnected (0); denied-ness is a marker, not a
  /// sort key — a denied-but-connected provider is still what agents would run
  /// on in another workspace.
  static int _rank(HarnessProviderInfo p) =>
      p.enabled == HarnessProviderEnabled.disabled ? 0 : 1;

  static CcStatusTone _tone(HarnessProviderInfo p, bool denied) {
    if (denied) {
      return CcStatusTone.negative;
    }
    return p.enabled == HarnessProviderEnabled.disabled
        ? CcStatusTone.neutral
        : CcStatusTone.positive;
  }

  static String _statusLabel(
    AppLocalizations l10n,
    HarnessProviderInfo p,
    bool denied,
  ) {
    if (denied) {
      return l10n.denied;
    }
    return p.enabled == HarnessProviderEnabled.disabled
        ? l10n.providerNotConnected
        : l10n.connectedLabel;
  }
}
