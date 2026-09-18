import 'package:cc_remote/app_connection.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/screens/session_utils.dart';
import 'package:cc_remote/screens/workspace_switcher.dart';
import 'package:cc_remote/update/remote_update.dart';
import 'package:cc_remote/widgets/app_shell_bottom_tabs.dart';
import 'package:cc_remote/widgets/connection_chip.dart';
import 'package:cc_remote/widgets/touch_target.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The mobile-first root shell: a header (workspace switcher + connection
/// chip), an optional connection-failed banner, the active tab body and a
/// bottom tab bar. Material-free — built on cc_ui primitives.
class AppShell extends ConsumerWidget {
  /// Creates an [AppShell] hosting [navigationShell].
  const AppShell({required this.navigationShell, super.key});

  /// The go_router shell that owns the tab branches.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final asyncState = ref.watch(remoteUiStateProvider);
    final session = ref.read(remoteSessionProvider);
    final uiState = asyncState.value ?? session.currentUiState;

    return SafeArea(
      top: true,
      child: ColoredBox(
        color: t.canvas,
        child: Column(
          children: [
            _Header(),
            const RemoteUpdateBanner(),
            if (uiState.status == RemoteStatus.connectionFailed)
              _FailedBanner(
                reason: uiState.reason,
                debugDetail: uiState.debugDetail,
              ),
            if (uiState.status == RemoteStatus.identityMismatch)
              const _IdentityMismatchBanner(),
            Expanded(child: navigationShell),
            BottomTabs(shell: navigationShell),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.topbar,
        border: Border(bottom: BorderSide(color: t.borderSoft)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            const WorkspaceSwitcherButton(),
            const Spacer(),
            const ConnectionChip(),
            const SizedBox(width: 4),
            PhoneIconButton(
              icon: AppIcons.settings,
              semanticLabel: AppLocalizations.of(context).settings,
              onPressed: () => context.push('/settings'),
              color: t.fgSecondary,
              iconSize: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _FailedBanner extends ConsumerWidget {
  const _FailedBanner({required this.reason, this.debugDetail});

  final RemoteFailureReason? reason;

  /// The raw error, debug builds only.
  final String? debugDetail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final label = reason == null
        ? l10n.connectionFailed
        : failureReasonLabel(l10n, reason!);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.warnSoft,
        border: Border(bottom: BorderSide(color: t.borderSoft)),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 8, 10),
        child: Row(
          children: [
            Icon(AppIcons.wifiOff, size: 16, color: t.textWarningPrimary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                debugDetail == null ? label : '$label  [$debugDetail]',
                style: TextStyle(fontSize: 13, color: t.textPrimary),
              ),
            ),
            CcButton(
              variant: CcButtonVariant.secondary,
              size: CcButtonSize.sm,
              onPressed: () => ref.read(remoteSessionProvider).retry(),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

/// A mid-session identity mismatch is terminal: the supervisor stopped
/// reconnecting because the server's identity no longer matches the pinned
/// fingerprint. Surface it loudly with the only way forward — re-pairing.
class _IdentityMismatchBanner extends ConsumerWidget {
  const _IdentityMismatchBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.dangerSoft,
        border: Border(bottom: BorderSide(color: t.borderSoft)),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 8, 10),
        child: Row(
          children: [
            Icon(AppIcons.triangleAlert, size: 16, color: t.textErrorPrimary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                AppLocalizations.of(context).identityMismatchBanner,
                style: TextStyle(fontSize: 13, color: t.textPrimary),
              ),
            ),
            CcButton(
              variant: CcButtonVariant.destructive,
              size: CcButtonSize.sm,
              onPressed: () => ref.read(remoteSessionProvider).unpair(),
              child: Text(AppLocalizations.of(context).removePairing),
            ),
          ],
        ),
      ),
    );
  }
}
