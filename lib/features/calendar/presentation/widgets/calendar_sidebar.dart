import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/calendar/presentation/providers/calendar_ui_providers.dart';
import 'package:control_center/features/calendar/presentation/widgets/calendar_mini_month.dart';
import 'package:control_center/features/calendar/presentation/widgets/google_calendar_connect_dialog.dart';
import 'package:control_center/features/calendar/providers/calendar_sync_providers.dart';
import 'package:control_center/features/calendar/providers/connect_account_provider.dart';
import 'package:control_center/features/calendar/providers/google_auth_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
        border: BorderDirectional(end: BorderSide(color: t.borderSecondary)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 16, 14, 12),
            child: CalendarMiniMonth(),
          ),
          Container(height: 1, color: t.borderSecondary),
          Expanded(child: _CalendarsSection(workspaceId: workspaceId)),
        ],
      ),
    );
  }
}

/// The connected accounts and their calendars: each account shows its email,
/// last-synced status, a disconnect action and its calendars with show/hide
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
    final accounts =
        ref.watch(googleAccountsProvider).asData?.value ?? const [];
    final hidden = ref.watch(hiddenCalendarsProvider);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        for (final account in accounts) ...[
          _AccountHeader(
            account: account,
            syncing: _syncing,
            onSync: _syncNow,
            onDisconnect: () => disconnectGoogleCalendar(
              ref,
              workspaceId: widget.workspaceId,
              accountId: account.id,
            ),
          ),
          for (final cal
              in ref
                      .watch(
                        calendarListProvider((
                          accountId: account.id,
                          accountEmail: account.accountEmail,
                        )),
                      )
                      .asData
                      ?.value ??
                  const <CalendarSourceView>[])
            _CalendarRow(
              source: cal,
              hidden: hidden.contains(cal.key),
              onToggle: () =>
                  ref.read(hiddenCalendarsProvider.notifier).toggle(cal.key),
            ),
          const SizedBox(height: 6),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 2, 14, 6),
          child: CcButton(
            variant: CcButtonVariant.ghost,
            size: CcButtonSize.sm,
            icon: AppIcons.plus,
            fullWidth: true,
            onPressed: () => showGoogleCalendarConnectDialog(
              context,
              ref,
              workspaceId: widget.workspaceId,
            ),
            child: Text(l10n.calendarAddAccount),
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
      status = l10n.calendarLastSynced(
        DateFormat.jm().format(lastSynced.toLocal()),
      );
    }

    final statusText = Text(
      status,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 11,
        color: needsReauth ? t.textWarningPrimary : t.textTertiary,
      ),
    );

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 6, 6, 4),
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
                // Only the "last synced" status is a concrete instant, so it
                // carries the accessibility timestamp card; the syncing /
                // never-synced / needs-reauth statuses stay bare.
                if (!syncing && !needsReauth && lastSynced != null)
                  AppTimestamp(dateTime: lastSynced, child: statusText)
                else
                  statusText,
              ],
            ),
          ),
          if (syncing)
            Padding(
              padding: const EdgeInsets.all(6),
              child: CcSpinner(size: 14, color: t.accent),
            )
          else
            CcIconButton(
              icon: AppIcons.refreshCw,
              variant: CcButtonVariant.ghost,
              size: CcButtonSize.sm,
              tooltip: l10n.calendarSyncNow,
              semanticLabel: l10n.calendarSyncNow,
              onPressed: onSync,
            ),
          CcIconButton(
            icon: AppIcons.unlink,
            variant: CcButtonVariant.ghost,
            size: CcButtonSize.sm,
            tooltip: l10n.calendarDisconnect,
            semanticLabel: l10n.calendarDisconnect,
            onPressed: onDisconnect,
          ),
        ],
      ),
    );
  }
}

class _CalendarRow extends StatefulWidget {
  const _CalendarRow({
    required this.source,
    required this.hidden,
    required this.onToggle,
  });

  final CalendarSourceView source;
  final bool hidden;
  final VoidCallback onToggle;

  @override
  State<_CalendarRow> createState() => _CalendarRowState();
}

class _CalendarRowState extends State<_CalendarRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final dotColor = widget.source.color ?? t.fgBrandPrimary;
    final toggleLabel = widget.hidden ? l10n.calendarShow : l10n.calendarHide;
    // The name is inert — visibility is toggled only through the eye. The eye
    // is hover-revealed for visible calendars, but its slot (one icon-button
    // box) is ALWAYS reserved, so nothing shifts when it appears. A hidden
    // calendar shows the crossed eye permanently: it is both the state
    // indicator and the re-show button.
    final showEye = _hovered || widget.hidden;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
            ? Duration.zero
            : const Duration(milliseconds: 90),
        decoration: BoxDecoration(
          // Alpha-0 at idle (not transparent-black) so the fade lerps only
          // alpha, matching CcSidebarItem's hover wash.
          color: _hovered ? t.hover : t.hover.withValues(alpha: 0),
        ),
        padding: const EdgeInsetsDirectional.fromSTEB(24, 1, 6, 1),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: widget.hidden ? null : dotColor,
                border: Border.all(color: dotColor, width: 1.5),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  widget.source.summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.hidden ? t.textTertiary : t.textPrimary,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 32,
              height: 32,
              child: showEye
                  ? CcIconButton(
                      icon: widget.hidden ? AppIcons.eyeOff : AppIcons.eye,
                      variant: CcButtonVariant.ghost,
                      size: CcButtonSize.sm,
                      tooltip: toggleLabel,
                      semanticLabel: toggleLabel,
                      onPressed: widget.onToggle,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
