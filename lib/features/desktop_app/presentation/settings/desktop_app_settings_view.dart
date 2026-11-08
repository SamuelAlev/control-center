import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/desktop/desktop_shell.dart';
import 'package:control_center/features/desktop_app/providers/desktop_app_preferences.dart';
import 'package:control_center/features/desktop_app/providers/desktop_shell_state_providers.dart';
import 'package:control_center/features/settings/presentation/screens/settings_page.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/open_url.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// System Settings → General → Login Items, where macOS asks the operator to
/// approve an app that registered itself.
const String _macLoginItemsUrl =
    'x-apple.systempreferences:com.apple.LoginItems-Settings.extension';

bool get _isMac => defaultTargetPlatform == TargetPlatform.macOS;

/// Settings → You → Desktop app: the tray (menu bar) icon, what closing the
/// window does, and opening at login.
class DesktopAppSettingsView extends ConsumerStatefulWidget {
  /// Creates a [DesktopAppSettingsView].
  const DesktopAppSettingsView({super.key});

  @override
  ConsumerState<DesktopAppSettingsView> createState() =>
      _DesktopAppSettingsViewState();
}

class _DesktopAppSettingsViewState
    extends ConsumerState<DesktopAppSettingsView> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // System Settings, Task Manager or a session manager may change the login
    // item while this page is up; coming back to the app is when to look.
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.read(launchAtLoginProvider.notifier).refresh(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsPage(
      title: l10n.navDesktopApp,
      subtitle: l10n.desktopAppSettingsSubtitle,
      sections: const [_TraySection(), _ClosingSection(), _LoginSection()],
    );
  }
}

class _TraySection extends ConsumerWidget {
  const _TraySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final host = ref.watch(trayHostStateProvider);
    final wanted = ref.watch(trayIconVisibleProvider);
    return SectionCard(
      label: _isMac ? l10n.desktopSectionMenuBar : l10n.desktopSectionTray,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsToggle(
            icon: AppIcons.appWindow,
            title: _isMac ? l10n.desktopTrayTitleMac : l10n.desktopTrayTitle,
            description: l10n.desktopTraySubtitle,
            value: wanted && host == TrayHostState.available,
            onChanged: host == TrayHostState.available
                ? (value) => unawaited(
                    ref
                        .read(trayIconVisibleProvider.notifier)
                        .set(value: value),
                  )
                : null,
          ),
          if (host == TrayHostState.missing) ...[
            const SizedBox(height: AppSpacing.md),
            CcAlert(
              variant: CcAlertVariant.warning,
              title: l10n.desktopTrayMissingTitle,
              description: Text(l10n.desktopTrayMissingBody),
            ),
          ],
        ],
      ),
    );
  }
}

class _ClosingSection extends ConsumerWidget {
  const _ClosingSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final possible = ref.watch(canKeepRunningProvider);
    // With nothing left on screen to bring the window back, closing quits
    // whatever was chosen; the choice is kept for when the icon returns.
    final action = possible ? ref.watch(closeActionProvider) : CloseAction.quit;
    return SectionCard(
      label: l10n.desktopSectionClosing,
      child: SettingsField(
        label: l10n.desktopCloseTitle,
        description: switch ((possible, action)) {
          (false, _) => l10n.desktopCloseNeedsTray,
          (true, CloseAction.keepRunning) =>
            _isMac
                ? l10n.desktopCloseKeepRunningSubtitleMac
                : l10n.desktopCloseKeepRunningSubtitle,
          (true, CloseAction.quit) => l10n.desktopCloseQuitSubtitle,
        },
        trailingControl: true,
        controlWidth: 300,
        child: CcSegmentedToggle<CloseAction>(
          value: action,
          semanticLabel: l10n.desktopCloseTitle,
          onChanged: possible
              ? (value) =>
                    unawaited(ref.read(closeActionProvider.notifier).set(value))
              : null,
          fullWidth: true,
          segments: [
            CcSegment(
              value: CloseAction.keepRunning,
              label: l10n.desktopCloseKeepRunning,
            ),
            CcSegment(value: CloseAction.quit, label: l10n.desktopCloseQuit),
          ],
        ),
      ),
    );
  }
}

class _LoginSection extends ConsumerWidget {
  const _LoginSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final login = ref.watch(launchAtLoginProvider);
    final supported = login.state != LaunchAtLoginState.unsupported;
    // Starting hidden needs a way back: the Dock on macOS, the tray icon
    // elsewhere. Without one the app opens its window as usual.
    final canStartHidden = _isMac || ref.watch(trayIconShownProvider);
    final startHidden = ref.watch(startHiddenAtLoginProvider);
    return SectionCard(
      label: l10n.desktopSectionLogin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsToggle(
            icon: AppIcons.power,
            title: l10n.desktopLoginTitle,
            description: supported
                ? l10n.desktopLoginSubtitle
                : l10n.desktopLoginUnsupported,
            value: login.enabled,
            onChanged: supported
                ? (value) => ref
                      .read(launchAtLoginProvider.notifier)
                      .set(enabled: value)
                : null,
          ),
          if (login.refused) ...[
            const SizedBox(height: AppSpacing.md),
            CcAlert(
              variant: CcAlertVariant.warning,
              title: _isMac
                  ? l10n.desktopLoginNeedsApproval
                  : l10n.desktopLoginRefused,
              action: _isMac
                  ? CcButton(
                      variant: CcButtonVariant.secondary,
                      size: CcButtonSize.sm,
                      icon: AppIcons.externalLink,
                      onPressed: () => openExternalUrl(_macLoginItemsUrl),
                      child: Text(l10n.desktopLoginOpenLoginItems),
                    )
                  : null,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SettingsToggle(
            icon: AppIcons.layers,
            title: l10n.desktopLoginStartHiddenTitle,
            description: canStartHidden
                ? (_isMac
                      ? l10n.desktopLoginStartHiddenSubtitleMac
                      : l10n.desktopLoginStartHiddenSubtitle)
                : l10n.desktopLoginStartHiddenNeedsTray,
            value: startHidden && login.enabled && canStartHidden,
            onChanged: login.enabled && canStartHidden
                ? (value) => unawaited(
                    ref
                        .read(startHiddenAtLoginProvider.notifier)
                        .set(value: value),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
