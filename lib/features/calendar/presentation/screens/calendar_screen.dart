import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/calendar/presentation/calendar_view_mode.dart';
import 'package:control_center/features/calendar/presentation/providers/calendar_event_write_provider.dart';
import 'package:control_center/features/calendar/presentation/providers/calendar_ui_providers.dart';
import 'package:control_center/features/calendar/presentation/utils/calendar_format.dart';
import 'package:control_center/features/calendar/presentation/widgets/agenda_panel.dart';
import 'package:control_center/features/calendar/presentation/widgets/calendar_composer_layer.dart';
import 'package:control_center/features/calendar/presentation/widgets/calendar_connect_prompts.dart';
import 'package:control_center/features/calendar/presentation/widgets/calendar_event_actions.dart';
import 'package:control_center/features/calendar/presentation/widgets/calendar_event_detail_panel.dart';
import 'package:control_center/features/calendar/presentation/widgets/calendar_header_actions.dart';
import 'package:control_center/features/calendar/presentation/widgets/calendar_kalender_host.dart';
import 'package:control_center/features/calendar/presentation/widgets/calendar_sidebar.dart';
import 'package:control_center/features/calendar/providers/google_auth_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/inline_load_error.dart';
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
    // `unwrapPrevious()` strips the value Riverpod carries over during a
    // dependency-driven reload: switching workspace recomputes this provider,
    // and without the strip the gate (and the reauth banner below) would read
    // the PREVIOUS workspace's accounts for a frame or two — surfacing another
    // workspace's state, which the workspace-isolation invariant forbids even
    // momentarily. Stripped, a mid-switch reload reads as plain loading.
    final accountsAsync = ref.watch(googleAccountsProvider).unwrapPrevious();
    if (accountsAsync.hasError) {
      return InlineLoadError(accountsAsync.error!);
    }
    if (!accountsAsync.hasValue) {
      return const _LoadingState();
    }
    if (accountsAsync.requireValue.isEmpty) {
      return CalendarConnectState(workspaceId: workspaceId);
    }

    // Lazily fetch events for the framed range as the user navigates months.
    ref.watch(calendarRangeLoaderProvider);

    final viewMode = ref.watch(calendarViewModeProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final range = visibleRangeFor(viewMode, selectedDate);
    final eventsAsync = ref.watch(
      eventsInRangeProvider((workspaceId: workspaceId, range: range)),
    );
    if (eventsAsync.hasError) {
      return InlineLoadError(eventsAsync.error!);
    }
    // The RPC subscription replays the last authenticated snapshot before
    // refreshing; a first-ever range has no rows until its first emission.
    final allEvents = eventsAsync.value ?? const <CalendarEvent>[];
    final hidden = ref.watch(hiddenCalendarsProvider);
    final events = hidden.isEmpty
        ? allEvents
        : allEvents
              .where(
                (e) => !hidden.contains(calendarKey(e.accountId, e.calendarId)),
              )
              .toList(growable: false);
    final calendarColors = ref.watch(calendarColorsProvider);
    final writable = ref.watch(writableCalendarsProvider);
    final composer = ref.read(calendarComposerProvider.notifier);
    final canCreate = !ref.watch(isDemoServerProvider) && writable.isNotEmpty;

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
              CalendarReauthBanner(workspaceId: workspaceId),
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
                  onOpenEvent: (e) {
                    composer.close();
                    context.go(calendarDetailRoute(workspaceId, e.id));
                  },
                  onCreate: canCreate ? composer.open : null,
                  canMove: canCreate
                      ? (e) => canMoveCalendarEvent(e, writable)
                      : null,
                  onMove: (e, to) => moveCalendarEvent(context, ref, e, to),
                  composing: ref.watch(calendarComposerProvider),
                  draft: composerDraft(
                    ref,
                    workspaceId: workspaceId,
                    title: l10n.calendarNewEvent,
                  ),
                  onStartRecording: (e) =>
                      startCalendarRecording(context, ref, e),
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
    required this.onCreate,
    required this.composing,
    required this.canMove,
    required this.onMove,
    required this.draft,
  });

  final String workspaceId;
  final CalendarViewMode viewMode;
  final DateTime selectedDate;
  final List<CalendarEvent> events;
  final Map<String, Color> calendarColors;
  final String? selectedEventId;
  final ValueChanged<CalendarEvent> onOpenEvent;
  final ValueChanged<CalendarEvent> onStartRecording;
  final ValueChanged<CalendarSlot>? onCreate;
  final CalendarSlot? composing;
  final bool Function(CalendarEvent event)? canMove;
  final Future<bool> Function(CalendarEvent event, CalendarSlot to) onMove;
  final CalendarEvent? Function(CalendarSlot slot) draft;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final main = CalendarComposerLayer(
      child: switch (viewMode) {
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
          onCreate: onCreate,
          composing: composing,
          canMove: canMove,
          onMove: onMove,
          draft: draft,
        ),
      },
    );

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
/// (previous / today / next), a compact view selector and a sync-now action
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
      padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 12, 12),
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
                CalendarNewEventButton(),
                SizedBox(width: 8),
                _ViewMenu(),
                SizedBox(width: 8),
                CalendarSyncButton(),
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

/// The sync-now action, with an in-flight spinner.
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
      followerAnchor: AlignmentDirectional.topEnd,
      targetAnchor: AlignmentDirectional.bottomEnd,
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
      trailing: Icon(
        AppIcons.chevronDown,
        size: 13,
        color: _iconColor(context),
      ),
      child: Text(label),
    );
  }

  Color _iconColor(BuildContext context) =>
      (context.designSystem ?? DesignSystemTokens.light()).textTertiary;
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
