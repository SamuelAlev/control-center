import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/calendar/presentation/calendar_view_mode.dart';
import 'package:control_center/features/calendar/presentation/providers/calendar_event_cache.dart';
import 'package:control_center/features/calendar/presentation/providers/calendar_ui_providers.dart';
import 'package:control_center/features/calendar/presentation/providers/record_and_link_provider.dart';
import 'package:control_center/features/calendar/presentation/utils/calendar_format.dart';
import 'package:control_center/features/calendar/presentation/widgets/agenda_panel.dart';
import 'package:control_center/features/calendar/presentation/widgets/calendar_event_detail_panel.dart';
import 'package:control_center/features/calendar/presentation/widgets/calendar_kalender_host.dart';
import 'package:control_center/features/calendar/presentation/widgets/calendar_sidebar.dart';
import 'package:control_center/features/calendar/presentation/widgets/google_calendar_connect_dialog.dart';
import 'package:control_center/features/calendar/providers/calendar_sync_providers.dart';
import 'package:control_center/features/calendar/providers/google_auth_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Minimum width at which the left navigator rail is shown alongside the views.
const double _kRailBreakpoint = 900;

/// The calendar screen: month / week (kalender) + agenda views of synced Google
/// Calendar events, with connect-account and record-and-link flows.
class CalendarScreen extends ConsumerWidget {
  /// Creates a [CalendarScreen].
  const CalendarScreen({super.key, this.selectedEventId});

  /// The event opened in the detail pane (from the route), or null.
  final String? selectedEventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final workspaceId = ref.watch(activeWorkspaceIdProvider);

    if (workspaceId == null) {
      return _CenteredMessage(message: l10n.calendarNoWorkspace);
    }

    // The connected Google accounts are backed by a DB stream that hasn't
    // emitted its first value on the very first build. Treating that initial
    // loading window as "no accounts" is what flashed the connect CTA before
    // the stream resolved — so only show it once we KNOW there are none.
    //
    // `unwrapPrevious()` strips the value Riverpod carries over during a
    // dependency-driven reload: switching workspace recomputes this provider,
    // and without the strip the gate (and the reauth banner below) would read
    // the PREVIOUS workspace's accounts for a frame or two — surfacing another
    // workspace's state, which the workspace-isolation invariant forbids even
    // momentarily. Stripped, a mid-switch reload reads as plain loading.
    final accountsAsync = ref.watch(googleAccountsProvider).unwrapPrevious();
    if (!accountsAsync.hasValue) {
      // No value yet: either the first load is still in flight (show a quiet
      // loader, not the CTA) or the stream errored (fall back to the CTA, which
      // lets the user retry — mirrors the pre-fix terminal behaviour).
      return accountsAsync.hasError
          ? const _ConnectState()
          : const _LoadingState();
    }
    if (accountsAsync.requireValue.isEmpty) {
      return const _ConnectState();
    }

    // Lazily fetch events for the framed range as the user navigates months.
    ref.watch(calendarRangeLoaderProvider);

    final viewMode = ref.watch(calendarViewModeProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final range = visibleRangeFor(viewMode, selectedDate);
    final eventsAsync = ref.watch(
      eventsInRangeProvider((workspaceId: workspaceId, range: range)),
    );
    // Stale-while-revalidate: until the RPC stream emits (and during any
    // refresh gap), render the last-known events for this range from the
    // cache. `.value` keeps the previous list through same-instance
    // reloads (reconnects, recomputes); the cache covers new range keys
    // (navigation, cold start). Without both, the all-day header pops open
    // late and shoves the calendar body down.
    final allEvents =
        eventsAsync.value ??
        ref
            .read(calendarEventCacheProvider)
            .overlapping(workspaceId, range.start, range.end) ??
        const <CalendarEvent>[];
    final hidden = ref.watch(hiddenCalendarsProvider);
    final events = hidden.isEmpty
        ? allEvents
        : allEvents
              .where(
                (e) => !hidden.contains(calendarKey(e.accountId, e.calendarId)),
              )
              .toList(growable: false);
    final calendarColors = ref.watch(calendarColorsProvider);

    return ColoredBox(
      color: t.canvas,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Header + view body, stacked. The header is scoped to this column so
          // it begins at the right edge of the rail rather than spanning the
          // full width above it.
          final main = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _ReauthBanner(),
              const _Header(),
              Container(height: 1, color: t.borderSecondary),
              Expanded(
                child: _Body(
                  workspaceId: workspaceId,
                  viewMode: viewMode,
                  selectedDate: selectedDate,
                  events: events,
                  calendarColors: calendarColors,
                  selectedEventId: selectedEventId,
                  onOpenEvent: (e) => context.go(
                    calendarDetailRoute(context.currentWorkspaceId!, e.id),
                  ),
                  onStartRecording: (e) => _startRecording(context, ref, e),
                ),
              ),
            ],
          );
          // The rail stays put when an event is selected — only hidden when the
          // pane is genuinely too narrow to fit it. It now runs full height,
          // with the header sitting beside its month navigator.
          final showRail = constraints.maxWidth >= _kRailBreakpoint;
          if (!showRail) {
            return main;
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CalendarSidebar(workspaceId: workspaceId),
              Expanded(child: main),
            ],
          );
        },
      ),
    );
  }

  Future<void> _startRecording(
    BuildContext context,
    WidgetRef ref,
    CalendarEvent event,
  ) async {
    final l10n = AppLocalizations.of(context);
    final ws = context.currentWorkspaceId!;
    final result = await ref
        .read(calendarRecordAndLinkProvider)
        .startRecordingForEvent(event);
    if (!context.mounted) {
      return;
    }
    if (result.meetingId != null) {
      context.go(meetingsRecordRoute(ws));
    } else {
      CcToastScope.of(context).show(
        result.error ?? l10n.calendarConnectError,
        variant: CcToastVariant.danger,
      );
    }
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.workspaceId,
    required this.viewMode,
    required this.selectedDate,
    required this.events,
    required this.calendarColors,
    required this.selectedEventId,
    required this.onOpenEvent,
    required this.onStartRecording,
  });

  final String workspaceId;
  final CalendarViewMode viewMode;
  final DateTime selectedDate;
  final List<CalendarEvent> events;
  final Map<String, Color> calendarColors;
  final String? selectedEventId;
  final ValueChanged<CalendarEvent> onOpenEvent;
  final ValueChanged<CalendarEvent> onStartRecording;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final Widget main = switch (viewMode) {
      CalendarViewMode.agenda => AgendaPanel(
        events: events,
        now: now,
        calendarColors: calendarColors,
        onOpenEvent: onOpenEvent,
        onStartRecording: onStartRecording,
      ),
      CalendarViewMode.month ||
      CalendarViewMode.week ||
      CalendarViewMode.day => CalendarKalenderHost(
        mode: viewMode,
        focusedDate: selectedDate,
        events: events,
        now: now,
        calendarColors: calendarColors,
        onOpenEvent: onOpenEvent,
      ),
    };

    final detail = CalendarEventDetailPanel(
      key: ValueKey(selectedEventId),
      workspaceId: workspaceId,
      eventId: selectedEventId,
      onStartRecording: onStartRecording,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final total = constraints.maxWidth;
        // The detail pane is a narrow inspector — only a little wider than the
        // left navigator rail (248px) — rather than a half-screen split. It
        // stays resizable; this is just its resting width.
        const detailWidth = 320.0;
        const detailMin = 288.0;
        const masterMin = 420.0;

        final showDetail = selectedEventId != null;
        // Too narrow to fit master + detail side by side: show the detail
        // full-screen. This is a genuinely different layout (the calendar is
        // unmounted here), so it only engages well below the working width.
        if (showDetail && total < masterMin + detailWidth) {
          return detail;
        }

        // The master (calendar/agenda) ALWAYS occupies region 0, whether or not
        // a detail panel is open. Keeping it at a stable position in the tree
        // means toggling the detail on/off resizes the master in place rather
        // than remounting it — so its scroll position and view state survive,
        // the way an outlet preserves a mounted sibling in React. Opening the
        // detail simply pushes the master narrower and slides the inspector in
        // beside it.
        final regions = <CcResizableRegion>[
          CcResizableRegion(
            initialExtent: showDetail ? total - detailWidth : total,
            minExtent: masterMin,
            builder: (context) => main,
          ),
          if (showDetail)
            CcResizableRegion(
              initialExtent: detailWidth,
              minExtent: detailMin,
              builder: (context) => detail,
            ),
        ];

        return CcResizable(axis: Axis.horizontal, regions: regions);
      },
    );
  }
}

/// The top bar: the focused-period label sits on the left; period navigation
/// (previous / today / next), a compact view selector, and a sync-now action
/// cluster quietly on the right.
class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final viewMode = ref.watch(calendarViewModeProvider);
    final selectedDate = ref.watch(selectedDateProvider);

    final label = viewMode == CalendarViewMode.day
        ? DateFormat.yMMMMd().format(selectedDate)
        : DateFormat.yMMMM().format(selectedDate);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      // Two equal Expanded zones flank the period nav so < Today > stays
      // centered in the bar no matter how wide the month label (or the
      // right-hand cluster) is — a plain Spacer lets the label's width push
      // the cluster around.
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                      color: t.textPrimary,
                    ),
                  ),
                ),
                if (viewMode == CalendarViewMode.week) ...[
                  const SizedBox(width: 8),
                  Text(
                    l10n.calendarWeekNumber(isoWeekNumber(selectedDate)),
                    style: TextStyle(fontSize: 13, color: t.textTertiary),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: _PeriodNav(viewMode: viewMode, selectedDate: selectedDate),
          ),
          const Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ViewMenu(),
                SizedBox(width: 8),
                _SyncButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodNav extends ConsumerWidget {
  const _PeriodNav({required this.viewMode, required this.selectedDate});

  final CalendarViewMode viewMode;
  final DateTime selectedDate;

  DateTime _stepped(int direction) => switch (viewMode) {
    CalendarViewMode.month => DateTime(
      selectedDate.year,
      selectedDate.month + direction,
    ),
    CalendarViewMode.day => selectedDate.add(Duration(days: direction)),
    CalendarViewMode.week ||
    CalendarViewMode.agenda => selectedDate.add(Duration(days: 7 * direction)),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    void select(DateTime date) =>
        ref.read(selectedDateProvider.notifier).select(date);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CcIconButton(
          icon: AppIcons.chevronLeft,
          variant: CcButtonVariant.ghost,
          size: CcButtonSize.sm,
          tooltip: l10n.calendarPreviousPeriod,
          semanticLabel: l10n.calendarPreviousPeriod,
          onPressed: () => select(_stepped(-1)),
        ),
        CcButton(
          variant: CcButtonVariant.ghost,
          size: CcButtonSize.sm,
          onPressed: () => select(DateTime.now()),
          child: Text(l10n.calendarToday),
        ),
        CcIconButton(
          icon: AppIcons.chevronRight,
          variant: CcButtonVariant.ghost,
          size: CcButtonSize.sm,
          tooltip: l10n.calendarNextPeriod,
          semanticLabel: l10n.calendarNextPeriod,
          onPressed: () => select(_stepped(1)),
        ),
      ],
    );
  }
}

/// A banner shown above the calendar when one or more connected accounts have a
/// dead OAuth token and need the user to reconnect. Hidden (zero-height) while
/// every account is healthy. The synced events stay visible underneath — we
/// only block on a full disconnect, not on a stale token.
class _ReauthBanner extends ConsumerWidget {
  const _ReauthBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stale = ref.watch(accountsNeedingReauthProvider);
    if (stale.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    // Name the account when exactly one is stale; otherwise stay generic.
    final subtitle = stale.length == 1 && stale.first.accountEmail.isNotEmpty
        ? l10n.notificationCalendarAuthExpiredBody(stale.first.accountEmail)
        : l10n.notificationCalendarAuthExpiredBodyNoEmail;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: t.bgWarningPrimary,
        border: Border(bottom: BorderSide(color: t.bgWarningSecondary)),
      ),
      child: Row(
        children: [
          Icon(AppIcons.calendarX, size: 18, color: t.textWarningPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.notificationCalendarAuthExpiredTitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: t.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: t.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CcButton(
            size: CcButtonSize.sm,
            onPressed: () => showGoogleCalendarConnectDialog(context),
            icon: AppIcons.refreshCw,
            child: Text(l10n.calendarReconnect),
          ),
        ],
      ),
    );
  }
}

/// The sync-now action, with an in-flight spinner.
class _SyncButton extends ConsumerStatefulWidget {
  const _SyncButton();

  @override
  ConsumerState<_SyncButton> createState() => _SyncButtonState();
}

class _SyncButtonState extends ConsumerState<_SyncButton> {
  bool _syncing = false;

  Future<void> _sync() async {
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
    if (_syncing) {
      return Padding(
        padding: const EdgeInsets.all(6),
        child: CcSpinner(size: 16, color: t.accent),
      );
    }
    return CcIconButton(
      icon: AppIcons.refreshCw,
      variant: CcButtonVariant.ghost,
      size: CcButtonSize.sm,
      tooltip: l10n.calendarSyncNow,
      semanticLabel: l10n.calendarSyncNow,
      onPressed: _sync,
    );
  }
}

/// Compact view selector: a chip showing the active view that opens a popover
/// menu of the four views. Replaces the wide segmented toggle so the header
/// stays quiet on the right.
class _ViewMenu extends ConsumerStatefulWidget {
  const _ViewMenu();

  @override
  ConsumerState<_ViewMenu> createState() => _ViewMenuState();
}

class _ViewMenuState extends ConsumerState<_ViewMenu> {
  final CcOverlayController _controller = CcOverlayController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _select(CalendarViewMode mode) {
    ref.read(calendarViewModeProvider.notifier).setMode(mode);
    _controller.hide();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final viewMode = ref.watch(calendarViewModeProvider);
    final labels = {
      CalendarViewMode.month: l10n.calendarViewMonth,
      CalendarViewMode.week: l10n.calendarViewWeek,
      CalendarViewMode.day: l10n.calendarViewDay,
      CalendarViewMode.agenda: l10n.calendarViewAgenda,
    };

    return CcPopover(
      controller: _controller,
      toggleOnTargetTap: false,
      followerAnchor: Alignment.topRight,
      targetAnchor: Alignment.bottomRight,
      overlayBuilder: (context, _) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 180),
        // Flush rows (no panel padding) with a neutral gray selected wash —
        // Carbon-style, matching CcSelect's dropdown.
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final mode in CalendarViewMode.values)
              CcSelectRow<CalendarViewMode>(
                option: CcSelectOption(value: mode, label: labels[mode]!),
                selected: mode == viewMode,
                highlighted: false,
                checkIcon: AppIcons.check,
                onPressed: () => _select(mode),
              ),
          ],
        ),
      ),
      target: _ViewMenuButton(
        label: labels[viewMode]!,
        onTap: _controller.toggle,
      ),
    );
  }
}

class _ViewMenuButton extends StatelessWidget {
  const _ViewMenuButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CcButton(
      variant: CcButtonVariant.ghost,
      size: CcButtonSize.sm,
      onPressed: onTap,
      trailing: Icon(AppIcons.chevronDown, size: 13, color: _iconColor(context)),
      child: Text(label),
    );
  }

  Color _iconColor(BuildContext context) =>
      (context.designSystem ?? DesignSystemTokens.light()).textTertiary;
}

class _ConnectState extends StatelessWidget {
  const _ConnectState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();

    return ColoredBox(
      color: t.canvas,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.calendar, size: 40, color: t.textTertiary),
              const SizedBox(height: 16),
              Text(
                l10n.calendarSettingsTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: t.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.calendarConnectDescription,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: t.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              CcButton(
                size: CcButtonSize.sm,
                onPressed: () => showGoogleCalendarConnectDialog(context),
                icon: AppIcons.calendarPlus,
                child: Text(l10n.calendarConnectGoogle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown while the connected-accounts stream resolves its first value. It is a
/// bare canvas, not a spinner: the backing read is a local Drift `.watch()` that
/// settles in a frame or two, so a spinner would appear and vanish — a quieter
/// version of the very flash this fix removes. A static surface is flash-free
/// and reduced-motion-safe by construction.
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return ColoredBox(color: t.canvas);
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return ColoredBox(
      color: t.canvas,
      child: Center(
        child: Text(
          message,
          style: TextStyle(fontSize: 13, color: t.textTertiary),
        ),
      ),
    );
  }
}
