import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/pr_providers.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The tab bar's destinations, in order. Must match the branch order in
/// `appRouterProvider` — `StatefulNavigationShell` addresses branches by index.
List<TabSpec> tabs(AppLocalizations l10n) => <TabSpec>[
  TabSpec(icon: AppIcons.inbox, label: l10n.tabInbox),
  TabSpec(icon: AppIcons.ticket, label: l10n.tabTickets),
  TabSpec(icon: AppIcons.messageCircle, label: l10n.tabChat),
  TabSpec(icon: AppIcons.gitPullRequest, label: l10n.tabPrs),
  TabSpec(icon: AppIcons.calendarDays, label: l10n.tabCalendar),
  TabSpec(icon: AppIcons.newspaper, label: l10n.tabNews),
];

/// The narrowest a labelled tab can get before its label starts truncating.
const double kMinTabWidth = 58;

/// Data class describing one tab's icon and label.
class TabSpec {
  const TabSpec({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// The bottom tab bar for the remote app shell.
class BottomTabs extends ConsumerWidget {
  const BottomTabs({required this.shell, super.key});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final inboxCount = ref.watch(inboxAttentionCountProvider);
    final tabList = tabs(AppLocalizations.of(context));

    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.topbar,
        border: Border(top: BorderSide(color: t.borderSoft)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final fits =
                  constraints.maxWidth / tabList.length >= kMinTabWidth;
              final buttons = [
                for (var i = 0; i < tabList.length; i++)
                  _TabButton(
                    spec: tabList[i],
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
                    SizedBox(width: kMinTabWidth, child: button),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.spec,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  final TabSpec spec;
  final bool selected;
  final VoidCallback onTap;

  final int badge;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final color = selected ? t.accent : t.fgTertiary;
    return CcTappable(
      onPressed: onTap,
      semanticLabel: badge > 0
          ? AppLocalizations.of(context).tabWaitingCount(spec.label, badge)
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
                  PositionedDirectional(
                    top: -4,
                    end: -8,
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
