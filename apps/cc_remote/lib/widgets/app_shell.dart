import 'package:cc_remote/app_connection.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/screens/workspace_switcher.dart';
import 'package:cc_remote/widgets/connection_chip.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The mobile-first root shell: a header (workspace switcher + connection
/// chip), an optional connection-failed banner, the active tab body, and a
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
            if (uiState.status == RemoteStatus.connectionFailed)
              _FailedBanner(reason: uiState.reason ?? 'Connection failed'),
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
            CcTappable(
              onPressed: () => context.push('/settings'),
              semanticLabel: 'Settings',
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              builder: (context, _) => Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(AppIcons.settings, size: 18, color: t.fgSecondary),
              ),
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

class _BottomTabs extends StatelessWidget {
  const _BottomTabs({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final tabs = const <_TabSpec>[
      _TabSpec(icon: AppIcons.ticket, label: 'Tickets'),
      _TabSpec(icon: AppIcons.messageCircle, label: 'Messaging'),
      _TabSpec(icon: AppIcons.newspaper, label: 'Newsfeed'),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.topbar,
        border: Border(top: BorderSide(color: t.borderSoft)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: _TabButton(
                    spec: tabs[i],
                    selected: shell.currentIndex == i,
                    onTap: () => shell.goBranch(
                      i,
                      initialLocation: i == shell.currentIndex,
                    ),
                  ),
                ),
            ],
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
  });

  final _TabSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final color = selected ? t.accent : t.fgTertiary;
    return CcTappable(
      onPressed: onTap,
      semanticLabel: spec.label,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(spec.icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              spec.label,
              style: TextStyle(
                fontSize: 11,
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
