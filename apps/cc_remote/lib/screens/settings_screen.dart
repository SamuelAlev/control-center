import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Languages offered in the appearance settings. The phone PWA's chrome is
/// English today; selecting one persists the locale preference (and applies it)
/// so translated strings take effect as they are added.
const List<({String code, String label})> _languages = [
  (code: 'en', label: 'English'),
  (code: 'fr', label: 'Français'),
  (code: 'es', label: 'Español'),
  (code: 'it', label: 'Italiano'),
  (code: 'de', label: 'Deutsch'),
  (code: 'pt', label: 'Português'),
  (code: 'nl', label: 'Nederlands'),
];

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
    final theme = ref.watch(themePreferenceProvider);
    final locale = ref.watch(appLocaleProvider);

    return SafeArea(
      child: ColoredBox(
        color: t.canvas,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(t),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _sectionLabel(t, 'Appearance'),
                  const SizedBox(height: 8),
                  _card(t, child: _themeRow(t, theme)),
                  const SizedBox(height: 18),
                  _sectionLabel(t, 'Language'),
                  const SizedBox(height: 8),
                  _card(t, child: _languageRow(t, locale)),
                  const SizedBox(height: 24),
                  _sectionLabel(t, 'Device'),
                  const SizedBox(height: 8),
                  _DisconnectCard(onConfirm: _disconnect),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(DesignSystemTokens t) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.topbar,
        border: Border(bottom: BorderSide(color: t.borderSoft)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
        child: Row(
          children: [
            CcTappable(
              onPressed: () => context.pop(),
              semanticLabel: 'Back',
              builder: (context, _) => Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(AppIcons.arrowLeft, color: t.fgSecondary),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Settings',
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
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
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
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }

  Widget _themeRow(DesignSystemTokens t, ThemePreference current) {
    final options = <(ThemePreference, IconData, String)>[
      (ThemePreference.system, AppIcons.monitor, 'System'),
      (ThemePreference.light, AppIcons.sun, 'Light'),
      (ThemePreference.dark, AppIcons.moon, 'Dark'),
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
            onTap: () =>
                ref.read(themePreferenceProvider.notifier).set(pref),
          ),
      ],
    );
  }

  Widget _languageRow(DesignSystemTokens t, String? current) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        CcChip(
          label: 'System',
          selected: current == null,
          onTap: () => ref.read(appLocaleProvider.notifier).set(null),
        ),
        for (final lang in _languages)
          CcChip(
            label: lang.label,
            selected: current == lang.code,
            onTap: () => ref.read(appLocaleProvider.notifier).set(lang.code),
          ),
      ],
    );
  }

  Future<void> _disconnect() async {
    await ref.read(remoteSessionProvider).unpair();
  }
}

/// Destructive "disconnect this device" card with a two-tap inline confirm — a
/// stray tap must not drop the pairing. Clears the stored PSK and returns to the
/// connect screen.
class _DisconnectCard extends StatefulWidget {
  const _DisconnectCard({required this.onConfirm});

  final Future<void> Function() onConfirm;

  @override
  State<_DisconnectCard> createState() => _DisconnectCardState();
}

class _DisconnectCardState extends State<_DisconnectCard> {
  bool _armed = false;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.dangerSoft,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(AppIcons.logOut, size: 18, color: t.textErrorPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _armed
                    ? 'Tap again to disconnect this device from your Mac'
                    : 'Disconnect this device',
                style: TextStyle(fontSize: 15, color: t.textPrimary),
              ),
            ),
            const SizedBox(width: 8),
            CcButton(
              variant: CcButtonVariant.destructive,
              size: CcButtonSize.sm,
              loading: _busy,
              onPressed: _tap,
              child: Text(_armed ? 'Confirm' : 'Disconnect'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _tap() async {
    if (!_armed) {
      setState(() => _armed = true);
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.onConfirm();
    } finally {
      if (mounted) {
        setState(() {
          _armed = false;
          _busy = false;
        });
      }
    }
  }
}
