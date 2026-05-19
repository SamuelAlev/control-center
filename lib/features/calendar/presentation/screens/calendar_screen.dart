import 'dart:async';

import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/calendar/domain/entities/calendar_event.dart';
import 'package:control_center/features/calendar/presentation/calendar_view_mode.dart';
import 'package:control_center/features/calendar/presentation/providers/calendar_ui_providers.dart';
import 'package:control_center/features/calendar/presentation/providers/connect_account_provider.dart';
import 'package:control_center/features/calendar/presentation/providers/record_and_link_provider.dart';
import 'package:control_center/features/calendar/presentation/utils/calendar_format.dart';
import 'package:control_center/features/calendar/presentation/widgets/agenda_panel.dart';
import 'package:control_center/features/calendar/presentation/widgets/calendar_event_detail_panel.dart';
import 'package:control_center/features/calendar/presentation/widgets/calendar_kalender_host.dart';
import 'package:control_center/features/calendar/presentation/widgets/calendar_sidebar.dart';
import 'package:control_center/features/calendar/providers/calendar_sync_providers.dart';
import 'package:control_center/features/calendar/providers/google_auth_providers.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_recorder_controller.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
          ? _ConnectState(workspaceId: workspaceId)
          : const _LoadingState();
    }
    if (accountsAsync.requireValue.isEmpty) {
      return _ConnectState(workspaceId: workspaceId);
    }

    // Lazily fetch events for the framed range as the user navigates months.
    ref.watch(calendarRangeLoaderProvider);

    final viewMode = ref.watch(calendarViewModeProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final eventsAsync = ref.watch(
      eventsInRangeProvider((
        workspaceId: workspaceId,
        range: visibleRangeFor(viewMode, selectedDate),
      )),
    );
    final allEvents = eventsAsync.asData?.value ?? const <CalendarEvent>[];
    final hidden = ref.watch(hiddenCalendarsProvider);
    final events = hidden.isEmpty
        ? allEvents
        : allEvents
            .where((e) => !hidden.contains(calendarKey(e.accountId, e.calendarId)))
            .toList(growable: false);
    final calendarColors = ref.watch(calendarColorsProvider);

    return ColoredBox(
      color: t.bgPrimary,
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
                  onOpenEvent: (e) => context.go(calendarDetailRoute(e.id)),
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
    final meetingId = await ref
        .read(calendarRecordAndLinkProvider)
        .startRecordingForEvent(event);
    if (!context.mounted) {
      return;
    }
    if (meetingId != null) {
      context.go(meetingsRecordRoute);
    } else {
      final error = ref.read(meetingRecorderControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? l10n.calendarConnectError)),
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
      CalendarViewMode.day =>
        CalendarKalenderHost(
          mode: viewMode,
          focusedDate: selectedDate,
          events: events,
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
        if (selectedEventId == null) {
          return main;
        }
        // The detail pane is a narrow inspector — only a little wider than the
        // left navigator rail (248px) — rather than a half-screen split. It
        // stays resizable; this is just its resting width.
        const detailWidth = 320.0;
        const detailMin = 288.0;
        const masterMin = 420.0;
        // Reserve room for the master's minimum against the detail's *resting*
        // width (not its min) — otherwise the master region would be seeded with
        // initialExtent < minExtent in the 708–740px band, which FResizableRegion
        // asserts on.
        if (total < masterMin + detailWidth) {
          return detail;
        }
        return FResizable(
          axis: Axis.horizontal,
          divider: FResizableDivider.divider,
          children: [
            FResizableRegion.region(
              initialExtent: total - detailWidth,
              minExtent: masterMin,
              builder: (context, data, _) => main,
            ),
            FResizableRegion.region(
              initialExtent: detailWidth,
              minExtent: detailMin,
              builder: (context, data, _) => detail,
            ),
          ],
        );
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
          const Spacer(),
          _PeriodNav(viewMode: viewMode, selectedDate: selectedDate),
          const SizedBox(width: 10),
          const _ViewMenu(),
          const SizedBox(width: 8),
          const _SyncButton(),
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
        CalendarViewMode.month =>
          DateTime(selectedDate.year, selectedDate.month + direction),
        CalendarViewMode.day =>
          selectedDate.add(Duration(days: direction)),
        CalendarViewMode.week ||
        CalendarViewMode.agenda =>
          selectedDate.add(Duration(days: 7 * direction)),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    void select(DateTime date) =>
        ref.read(selectedDateProvider.notifier).select(date);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HeaderIconButton(
          icon: LucideIcons.chevronLeft,
          tooltip: l10n.calendarPreviousPeriod,
          onTap: () => select(_stepped(-1)),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => select(DateTime.now()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: t.bgSecondary,
                borderRadius: AppRadii.brSm,
              ),
              child: Text(
                l10n.calendarToday,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: t.textPrimary,
                ),
              ),
            ),
          ),
        ),
        _HeaderIconButton(
          icon: LucideIcons.chevronRight,
          tooltip: l10n.calendarNextPeriod,
          onTap: () => select(_stepped(1)),
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
    final connecting = ref.watch(connectGoogleCalendarProvider).isLoading;
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
          Icon(LucideIcons.calendarX, size: 18, color: t.textWarningPrimary),
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
          FButton(
            variant: FButtonVariant.primary,
            size: FButtonSizeVariant.sm,
            onPress: connecting
                ? null
                : () =>
                    ref.read(connectGoogleCalendarProvider.notifier).connect(),
            prefix: const Icon(LucideIcons.refreshCw, size: 14),
            child: Text(
              connecting ? l10n.calendarConnecting : l10n.calendarReconnect,
            ),
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
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: t.accent),
        ),
      );
    }
    return _HeaderIconButton(
      icon: LucideIcons.refreshCw,
      tooltip: l10n.calendarSyncNow,
      onTap: _sync,
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final button = InkWell(
      borderRadius: AppRadii.brSm,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: t.textSecondary),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
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

class _ViewMenuState extends ConsumerState<_ViewMenu>
    with SingleTickerProviderStateMixin {
  late final FPopoverController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FPopoverController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _select(CalendarViewMode mode) {
    ref.read(calendarViewModeProvider.notifier).setMode(mode);
    unawaited(_controller.hide());
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

    return FPopoverMenu.tiles(
      control: FPopoverControl.managed(controller: _controller),
      style: const FPopoverMenuStyleDelta.delta(maxWidth: 180),
      divider: FItemDivider.none,
      menu: [
        FTileGroup(
          children: [
            for (final mode in CalendarViewMode.values)
              FTile(
                title: Text(labels[mode]!),
                suffix: mode == viewMode
                    ? const Icon(LucideIcons.check, size: 14)
                    : null,
                selected: mode == viewMode,
                onPress: () => _select(mode),
              ),
          ],
        ),
      ],
      child: _ViewMenuButton(
        label: labels[viewMode]!,
        onTap: () => _controller.toggle(),
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
    final t = context.designSystem ?? DesignSystemTokens.light();
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 5, 6, 5),
          decoration: BoxDecoration(
            color: t.bgSecondary,
            borderRadius: AppRadii.brSm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: t.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(LucideIcons.chevronDown, size: 13, color: t.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectState extends ConsumerWidget {
  const _ConnectState({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final connectState = ref.watch(connectGoogleCalendarProvider);
    final connecting = connectState.isLoading;

    return ColoredBox(
      color: t.bgPrimary,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.calendar, size: 40, color: t.textTertiary),
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
                style: TextStyle(fontSize: 13, height: 1.4, color: t.textSecondary),
              ),
              const SizedBox(height: 20),
              FButton(
                variant: FButtonVariant.primary,
                size: FButtonSizeVariant.sm,
                onPress: connecting
                    ? null
                    : () => ref
                        .read(connectGoogleCalendarProvider.notifier)
                        .connect(),
                prefix: const Icon(LucideIcons.calendarPlus, size: 16),
                child: Text(
                  connecting ? l10n.calendarConnecting : l10n.calendarConnectGoogle,
                ),
              ),
              if (connectState.hasError) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.calendarConnectError,
                  style: TextStyle(fontSize: 12, color: t.bgErrorSolid),
                ),
              ],
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
    return ColoredBox(color: t.bgPrimary);
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return ColoredBox(
      color: t.bgPrimary,
      child: Center(
        child: Text(
          message,
          style: TextStyle(fontSize: 13, color: t.textTertiary),
        ),
      ),
    );
  }
}
