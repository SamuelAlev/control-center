import 'package:cc_remote/app_connection.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/pr_providers.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/screens/workspace_switcher.dart';
import 'package:cc_remote/update/remote_update.dart';
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
              _FailedBanner(reason: uiState.reason ?? 'Connection failed'),
            if (uiState.status == RemoteStatus.identityMismatch)
              const _IdentityMismatchBanner(),
            Expanded(child: navigationShell),
            _BottomTabs(shell: navigationShell),
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
              semanticLabel: 'Settings',
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
  const _FailedBanner({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.warnSoft,
        border: Border(bottom: BorderSide(color: t.borderSoft)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        child: Row(
          children: [
            Icon(AppIcons.wifiOff, size: 16, color: t.textWarningPrimary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                reason,
                style: TextStyle(fontSize: 13, color: t.textPrimary),
              ),
            ),
            CcButton(
              variant: CcButtonVariant.secondary,
              size: CcButtonSize.sm,
              onPressed: () => ref.read(remoteSessionProvider).retry(),
              child: const Text('Retry'),
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
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        child: Row(
          children: [
            Icon(AppIcons.triangleAlert, size: 16, color: t.textErrorPrimary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Server identity changed — connection stopped. Re-pair this '
                'device to continue.',
                style: TextStyle(fontSize: 13, color: t.textPrimary),
              ),
            ),
            CcButton(
              variant: CcButtonVariant.destructive,
              size: CcButtonSize.sm,
              onPressed: () => ref.read(remoteSessionProvider).unpair(),
              child: const Text('Remove pairing'),
            ),
          ],
        ),
      ),
    );
  }
}

/// The tab bar's destinations, in order. Must match the branch order in
/// `appRouterProvider` — `StatefulNavigationShell` addresses branches by index.
const List<_TabSpec> _kTabs = <_TabSpec>[
  _TabSpec(icon: AppIcons.inbox, label: 'Inbox'),
  _TabSpec(icon: AppIcons.ticket, label: 'Tickets'),
  _TabSpec(icon: AppIcons.messageCircle, label: 'Chat'),
  _TabSpec(icon: AppIcons.gitPullRequest, label: 'PRs'),
  _TabSpec(icon: AppIcons.calendarDays, label: 'Calendar'),
  _TabSpec(icon: AppIcons.newspaper, label: 'News'),
];

/// The narrowest a labelled tab can get before its label starts truncating.
const double _kMinTabWidth = 58;

class _BottomTabs extends ConsumerWidget {
  const _BottomTabs({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final inboxCount = ref.watch(inboxAttentionCountProvider);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.topbar,
        border: Border(top: BorderSide(color: t.borderSoft)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          // Six destinations do fit a modern phone, but not a 320pt one — and
          // a tab bar that silently ellipsises its labels is worse than one
          // that scrolls. So the row divides the width evenly when every tab
          // clears [_kMinTabWidth] and falls back to a horizontal scroll when
          // it cannot, instead of shrinking below the readable floor.
          child: LayoutBuilder(
            builder: (context, constraints) {
              final fits =
                  constraints.maxWidth / _kTabs.length >= _kMinTabWidth;
              final buttons = [
                for (var i = 0; i < _kTabs.length; i++)
                  _TabButton(
                    spec: _kTabs[i],
                    selected: shell.currentIndex == i,
                    badge: i == 0 ? inboxCount : 0,
                    onTap: () => shell.goBranch(
                      i,
                      initialLocation: i == shell.currentIndex,
                    ),
                  ),
              ];
              if (fits) {
                return Row(
                  children: [
                    for (final button in buttons) Expanded(child: button),
                  ],
                );
              }
              return ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final button in buttons)
                    SizedBox(width: _kMinTabWidth, child: button),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.spec,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  final _TabSpec spec;
  final bool selected;
  final VoidCallback onTap;

  /// Count shown on the icon; 0 hides it.
  final int badge;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final color = selected ? t.accent : t.fgTertiary;
    return CcTappable(
      onPressed: onTap,
      // The count belongs in the accessible name too — a dot a screen reader
      // never announces is decoration, not a signal.
      semanticLabel: badge > 0
          ? '${spec.label}, $badge waiting'
          : spec.label,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(spec.icon, size: 21, color: color),
                if (badge > 0)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: _Badge(count: badge),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              spec.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The count pill on a tab icon.
class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.accent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        child: Text(
          count > 9 ? '9+' : '$count',
          style: TextStyle(
            fontSize: 9,
            height: 1.2,
            fontWeight: FontWeight.w700,
            color: t.textPrimaryOnBrand,
          ),
        ),
      ),
    );
  }
}
