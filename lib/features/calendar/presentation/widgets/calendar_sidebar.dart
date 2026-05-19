import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/calendar/domain/entities/calendar_event.dart';
import 'package:control_center/features/calendar/presentation/calendar_view_mode.dart';
import 'package:control_center/features/calendar/presentation/providers/calendar_ui_providers.dart';
import 'package:control_center/features/calendar/presentation/utils/calendar_format.dart';
import 'package:control_center/features/calendar/providers/calendar_sync_providers.dart';
import 'package:control_center/features/calendar/providers/connect_account_provider.dart';
import 'package:control_center/features/calendar/providers/google_auth_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The calendar's left rail: a compact month navigator plus the connected
/// account and its calendars (with show/hide toggles). Drives
/// [selectedDateProvider] for navigation. Shown on wide layouts only.
class CalendarSidebar extends ConsumerWidget {
  /// Creates a [CalendarSidebar].
  const CalendarSidebar({super.key, required this.workspaceId});

  /// The active workspace whose account + selection this rail reflects.
  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      width: 248,
      decoration: BoxDecoration(
        color: t.sidebar,
        border: Border(right: BorderSide(color: t.borderSecondary)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 16, 14, 12),
            child: _MiniMonth(),
          ),
          Container(height: 1, color: t.borderSecondary),
          Expanded(child: _CalendarsSection(workspaceId: workspaceId)),
        ],
      ),
    );
  }
}

/// A 6-week mini calendar. Tapping a day focuses it; the chevrons page the
/// displayed month without moving the selection. The displayed month follows
/// [selectedDateProvider] when it changes elsewhere (header nav / Today).
class _MiniMonth extends ConsumerStatefulWidget {
  const _MiniMonth();

  @override
  ConsumerState<_MiniMonth> createState() => _MiniMonthState();
}

class _MiniMonthState extends ConsumerState<_MiniMonth> {
  late DateTime _displayMonth =
      startOfMonth(ref.read(selectedDateProvider));

  void _page(int delta) {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final selected = ref.watch(selectedDateProvider);
    // In week view the rail mirrors the grid's framing: the whole week holding
    // the focused day is banded, not just the day, so the navigator reflects
    // what the body shows. Other views frame a single day (or month), so no band.
    final weekView = ref.watch(calendarViewModeProvider) == CalendarViewMode.week;
    final activeWeekStart = dayKey(startOfWeek(selected));

    // Keep the grid in sync when the focused date moves from outside the rail.
    ref.listen(selectedDateProvider, (_, next) {
      final month = startOfMonth(next);
      if (month != _displayMonth) {
        setState(() => _displayMonth = month);
      }
    });

    final today = dayKey(DateTime.now());
    final gridStart = startOfMonthGrid(_displayMonth);
    final days = [for (var i = 0; i < 42; i++) gridStart.add(Duration(days: i))];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                DateFormat.yMMMM().format(_displayMonth),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: t.textPrimary,
                ),
              ),
            ),
            _MiniIconButton(
              icon: LucideIcons.chevronLeft,
              onTap: () => _page(-1),
            ),
            _MiniIconButton(
              icon: LucideIcons.chevronRight,
              onTap: () => _page(1),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final label in _weekdayLabels())
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 10, color: t.textTertiary),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        for (var week = 0; week < 6; week++)
          DecoratedBox(
            decoration: BoxDecoration(
              color: weekView && dayKey(days[week * 7]) == activeWeekStart
                  ? t.bgQuaternary
                  : Colors.transparent,
              borderRadius: AppRadii.brLg,
            ),
            child: Row(
              children: [
                for (var d = 0; d < 7; d++)
                  Expanded(
                    child: _MiniDayCell(
                      day: days[week * 7 + d],
                      inMonth: days[week * 7 + d].month == _displayMonth.month,
                      isToday: dayKey(days[week * 7 + d]) == today,
                      isSelected: dayKey(days[week * 7 + d]) == dayKey(selected),
                      onTap: () => ref
                          .read(selectedDateProvider.notifier)
                          .select(days[week * 7 + d]),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  List<String> _weekdayLabels() {
    // Monday-first, short labels from the active locale.
    final monday = startOfWeek(DateTime.now());
    return [
      for (var i = 0; i < 7; i++)
        DateFormat.E().format(monday.add(Duration(days: i))),
    ];
  }
}

class _MiniDayCell extends StatelessWidget {
  const _MiniDayCell({
    required this.day,
    required this.inMonth,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime day;
  final bool inMonth;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();

    final Color textColor;
    if (isSelected) {
      textColor = t.textWhite;
    } else if (!inMonth) {
      textColor = t.textTertiary;
    } else if (isToday) {
      textColor = t.accent;
    } else {
      textColor = t.textPrimary;
    }

    return Padding(
      padding: const EdgeInsets.all(1),
      child: InkWell(
        borderRadius: AppRadii.brSm,
        onTap: onTap,
        child: Container(
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? t.accent
                : (isToday ? t.bgBrandPrimary : Colors.transparent),
            borderRadius: AppRadii.brSm,
          ),
          child: Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 12,
              fontWeight:
                  isSelected || isToday ? FontWeight.w600 : FontWeight.w400,
              color: textColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  const _MiniIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return InkWell(
      borderRadius: AppRadii.brSm,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 16, color: t.textSecondary),
      ),
    );
  }
}

/// The connected accounts and their calendars: each account shows its email,
/// last-synced status, a disconnect action, and its calendars with show/hide
/// toggles. A trailing action connects an additional account.
class _CalendarsSection extends ConsumerStatefulWidget {
  const _CalendarsSection({required this.workspaceId});

  final String workspaceId;

  @override
  ConsumerState<_CalendarsSection> createState() => _CalendarsSectionState();
}

class _CalendarsSectionState extends ConsumerState<_CalendarsSection> {
  bool _syncing = false;

  Future<void> _syncNow() async {
    if (_syncing) {
      return;
    }
    setState(() => _syncing = true);
    try {
      await ref.read(calendarSyncServiceProvider).refreshNow();
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final accounts =
        ref.watch(googleAccountsProvider).asData?.value ?? const [];
    final hidden = ref.watch(hiddenCalendarsProvider);
    final connecting = ref.watch(connectGoogleCalendarProvider).isLoading;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        for (final account in accounts) ...[
          _AccountHeader(
            account: account,
            syncing: _syncing,
            onSync: _syncNow,
            onDisconnect: () => ref
                .read(connectGoogleCalendarProvider.notifier)
                .disconnect(account.id),
          ),
          for (final cal in ref
                  .watch(calendarListProvider((
                    accountId: account.id,
                    accountEmail: account.accountEmail,
                  )))
                  .asData
                  ?.value ??
              const <CalendarSource>[])
            _CalendarRow(
              source: cal,
              hidden: hidden.contains(cal.key),
              onToggle: () =>
                  ref.read(hiddenCalendarsProvider.notifier).toggle(cal.key),
            ),
          const SizedBox(height: 6),
        ],
        InkWell(
          onTap: connecting
              ? null
              : () => ref.read(connectGoogleCalendarProvider.notifier).connect(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Icon(LucideIcons.plus, size: 15, color: t.textSecondary),
                const SizedBox(width: 8),
                Text(
                  l10n.calendarAddAccount,
                  style: TextStyle(fontSize: 12, color: t.textSecondary),
                ),
                if (connecting) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: t.accent,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Header row for one connected account: email + last-synced, with sync +
/// disconnect actions.
class _AccountHeader extends StatelessWidget {
  const _AccountHeader({
    required this.account,
    required this.syncing,
    required this.onSync,
    required this.onDisconnect,
  });

  final CalendarAccount account;
  final bool syncing;
  final VoidCallback onSync;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final lastSynced = account.lastSyncedAt;
    final String status;
    // A dead token takes precedence over the last-synced line: the sync is
    // broken until the user reconnects, so say so (in a warning colour).
    final bool needsReauth = account.needsReauth && !syncing;
    if (syncing) {
      status = l10n.calendarSyncing;
    } else if (needsReauth) {
      status = l10n.notificationCalendarAuthExpiredTitle;
    } else if (lastSynced == null) {
      status = l10n.calendarNeverSynced;
    } else {
      status = l10n.calendarLastSynced(DateFormat.jm().format(lastSynced.toLocal()));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.accountEmail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: t.textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: needsReauth ? t.textWarningPrimary : t.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          if (syncing)
            Padding(
              padding: const EdgeInsets.all(6),
              child: SizedBox(
                width: 14,
                height: 14,
                child:
                    CircularProgressIndicator(strokeWidth: 2, color: t.accent),
              ),
            )
          else
            Tooltip(
              message: l10n.calendarSyncNow,
              child: _MiniIconButton(icon: LucideIcons.refreshCw, onTap: onSync),
            ),
          Tooltip(
            message: l10n.calendarDisconnect,
            child: _MiniIconButton(icon: LucideIcons.unlink, onTap: onDisconnect),
          ),
        ],
      ),
    );
  }
}

class _CalendarRow extends StatelessWidget {
  const _CalendarRow({
    required this.source,
    required this.hidden,
    required this.onToggle,
  });

  final CalendarSource source;
  final bool hidden;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final dotColor = source.color ?? t.fgBrandPrimary;

    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 5, 14, 5),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: hidden ? Colors.transparent : dotColor,
                borderRadius: AppRadii.brXs,
                border: Border.all(color: dotColor, width: 1.5),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                source.summary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: hidden ? t.textTertiary : t.textPrimary,
                ),
              ),
            ),
            Tooltip(
              message: hidden ? l10n.calendarShow : l10n.calendarHide,
              child: Icon(
                hidden ? LucideIcons.eyeOff : LucideIcons.eye,
                size: 15,
                color: t.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
