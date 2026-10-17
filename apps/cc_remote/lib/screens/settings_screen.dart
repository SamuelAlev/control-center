import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/l10n/remote_locales.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/push/push_settings_section.dart';
import 'package:cc_remote/widgets/disconnect_card.dart';
import 'package:cc_remote/widgets/operation_links.dart';
import 'package:cc_remote/widgets/touch_target.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// `/settings` — appearance (theme + language) and account (disconnect this
/// device from the Mac).
class SettingsScreen extends ConsumerStatefulWidget {
  /// Creates a [SettingsScreen].
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final theme = ref.watch(themePreferenceProvider);
    final locale = ref.watch(appLocaleProvider);

    return SafeArea(
      child: ColoredBox(
        color: t.canvas,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(t, l10n),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const OperationLinks(),
                  const SizedBox(height: 16),
                  _sectionLabel(t, l10n.appearance),
                  const SizedBox(height: 8),
                  _card(t, child: _themeRow(t, l10n, theme)),
                  const SizedBox(height: 18),
                  _sectionLabel(t, l10n.language),
                  const SizedBox(height: 8),
                  _card(t, child: _languageRow(t, l10n, locale)),
                  const SizedBox(height: 24),
                  const PushSettingsSection(),
                  const SizedBox(height: 24),
                  _sectionLabel(t, l10n.device),
                  const SizedBox(height: 8),
                  DisconnectCard(onConfirm: _disconnect),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(DesignSystemTokens t, AppLocalizations l10n) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.topbar,
        border: Border(bottom: BorderSide(color: t.borderSoft)),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 16, 8),
        child: Row(
          children: [
            PhoneIconButton(
              icon: AppIcons.arrowLeft,
              semanticLabel: l10n.back,
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/inbox'),
              color: t.fgSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.settings,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: t.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(DesignSystemTokens t, String text) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: t.fgTertiary,
        ),
      ),
    );
  }

  Widget _card(DesignSystemTokens t, {required Widget child}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.bgSecondary,
        borderRadius: const BorderRadius.all(Radius.circular(2)),
      ),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }

  Widget _themeRow(
    DesignSystemTokens t,
    AppLocalizations l10n,
    ThemePreference current,
  ) {
    final options = <(ThemePreference, IconData, String)>[
      (ThemePreference.system, AppIcons.monitor, l10n.themeSystem),
      (ThemePreference.light, AppIcons.sun, l10n.themeLight),
      (ThemePreference.dark, AppIcons.moon, l10n.themeDark),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (pref, icon, label) in options)
          CcChip(
            label: label,
            leadingIcon: icon,
            selected: current == pref,
            onPressed: () =>
                ref.read(themePreferenceProvider.notifier).set(pref),
          ),
      ],
    );
  }

  Widget _languageRow(
    DesignSystemTokens t,
    AppLocalizations l10n,
    String? current,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        CcChip(
          label: l10n.languageSystem,
          selected: current == null,
          onPressed: () => ref.read(appLocaleProvider.notifier).set(null),
        ),
        for (final lang in kRemoteLanguages)
          CcChip(
            label: lang.label,
            selected: current == lang.code,
            onPressed: () =>
                ref.read(appLocaleProvider.notifier).set(lang.code),
          ),
      ],
    );
  }

  Future<void> _disconnect() async {
    await ref.read(remoteSessionProvider).unpair();
  }
}
