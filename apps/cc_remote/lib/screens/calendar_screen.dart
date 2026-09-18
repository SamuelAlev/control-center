import 'dart:async';

import 'package:cc_data/cc_data.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/calendar_providers.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/calendar/agenda_event_row.dart';
import 'package:cc_remote/widgets/calendar/calendar_notices.dart';
import 'package:cc_remote/widgets/calendar/up_next_card.dart';
import 'package:cc_remote/widgets/touch_target.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Calendar tab: the synced agenda for the active workspace.
///
/// An AGENDA, not a month grid. The desktop's calendar is a planning surface —
/// you drag, you compare weeks, you see shape. A phone calendar answers a
/// narrower question, usually while walking: what is next, where is it, and
/// what is the join link. So the phone renders one scrolling list of days with
/// an "up next" card pinned on top, over exactly the same synced rows
/// (`calendar.watchEventsInRange`) the desktop reads.
///
/// Connecting an account stays on the desktop: the OAuth device-code flow
/// stores a refresh token server-side, and a phone that could add accounts
/// but not manage their scopes would be a half-feature. The phone says so
/// rather than showing an empty week that looks like a free schedule.
class CalendarScreen extends ConsumerStatefulWidget {
  /// Creates a [CalendarScreen].
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  bool _refreshing = false;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // "In 45m" and "Happening now" are computed from `DateTime.now()`, and
    // nothing else on this screen changes while a meeting approaches — the
    // event stream only emits when the SYNC changes. Without a clock the card
    // would still read "In 45m" when the call has already started, which is
    // the one thing a calendar must not do. Half a minute is finer than the
    // labels' own resolution, so no minute is ever shown late.
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final client = ref.read(rpcClientProvider).value;
    final workspaceId = ref.read(activeWorkspaceIdProvider).value;
    if (client == null || workspaceId == null || _refreshing) {
      return;
    }
    setState(() => _refreshing = true);
    try {
      await RemoteCalendarRepository(
        client,
      ).refreshNow(workspaceId: workspaceId);
    } catch (_) {
      // The synced rows keep rendering; the host re-syncs on its own cadence.
    } finally {
      if (mounted) {
        setState(() => _refreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final accounts = ref.watch(calendarAccountsProvider);
    final days = ref.watch(agendaDaysProvider);
    final next = ref.watch(nextEventProvider);

    return ColoredBox(
      color: t.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _toolbar(t),
          if (accounts.hasValue && accounts.value!.isEmpty)
            const CalendarNoAccountsNotice()
          else if (accounts.value?.any((a) => a.authExpiredAt != null) ?? false)
            const CalendarReauthNotice(),
          Expanded(
            child: days.when(
              loading: () => const Center(child: CcSpinner(size: 24)),
              error: (e, _) => CcEmptyState(
                icon: AppIcons.triangleAlert,
                message: AppLocalizations.of(context).calendarLoadFailed,
                description: e.toString(),
              ),
              data: (agenda) {
                if (agenda.isEmpty) {
                  return CcEmptyState(
                    icon: AppIcons.calendarDays,
                    message: AppLocalizations.of(context).nothingScheduled,
                    description: AppLocalizations.of(
                      context,
                    ).calendarEmptyDescription,
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    if (next != null) ...[
                      UpNextCard(event: next),
                      const SizedBox(height: 20),
                    ],
                    for (final day in agenda) ...[
                      AgendaDayHeader(day: day.day),
                      const SizedBox(height: 8),
                      for (final event in day.events)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: AgendaEventRow(event: event),
                        ),
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolbar(DesignSystemTokens t) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 4, 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.agenda,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: t.textPrimary,
              ),
            ),
          ),
          PhoneIconButton(
            icon: AppIcons.refreshCw,
            semanticLabel: l10n.syncCalendarsNow,
            onPressed: _refreshing ? null : _refresh,
            color: _refreshing ? t.fgDisabled : t.fgSecondary,
            iconSize: 18,
          ),
        ],
      ),
    );
  }
}
