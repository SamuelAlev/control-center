import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/calendar/domain/entities/calendar_event.dart';
import 'package:control_center/features/calendar/presentation/providers/calendar_ui_providers.dart';
import 'package:control_center/features/calendar/presentation/providers/record_and_link_provider.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_theme.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A dialog that links a recorded meeting to one of the workspace's calendar
/// events. Lists events around the meeting's time (closest first), with search;
/// picking one links it (adopting the event title when the meeting title isn't
/// custom). If already linked, offers to remove the link. Self-contained — it
/// performs the link/unlink and pops itself.
class LinkEventSheet extends ConsumerStatefulWidget {
  /// Creates a [LinkEventSheet].
  const LinkEventSheet({
    super.key,
    required this.workspaceId,
    required this.meetingId,
    required this.meetingStartedAt,
    this.currentEventId,
  });

  /// Owning workspace.
  final String workspaceId;

  /// The meeting being linked.
  final String meetingId;

  /// The meeting's start, used to surface the nearest events first.
  final DateTime meetingStartedAt;

  /// The currently-linked event id, if any (enables "remove link").
  final String? currentEventId;

  @override
  ConsumerState<LinkEventSheet> createState() => _LinkEventSheetState();
}

class _LinkEventSheetState extends ConsumerState<LinkEventSheet> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_query != _searchController.text) {
        setState(() => _query = _searchController.text);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _link(String eventId) async {
    if (_busy) {
      return;
    }
    final toaster = CcToastScope.of(context);
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(linkMeetingToEventUseCaseProvider).link(
            workspaceId: widget.workspaceId,
            meetingId: widget.meetingId,
            calendarEventId: eventId,
          );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on Object {
      if (mounted) {
        setState(() => _busy = false);
        toaster.show(
          l10n.calendarLinkUpdateFailed,
          variant: CcToastVariant.danger,
        );
      }
    }
  }

  Future<void> _unlink() async {
    if (_busy) {
      return;
    }
    final toaster = CcToastScope.of(context);
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(linkMeetingToEventUseCaseProvider).unlink(
            workspaceId: widget.workspaceId,
            meetingId: widget.meetingId,
          );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on Object {
      if (mounted) {
        setState(() => _busy = false);
        toaster.show(
          l10n.calendarLinkUpdateFailed,
          variant: CcToastVariant.danger,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.ds;
    final locale = Localizations.localeOf(context).toString();

    // A wide window around the meeting so events just before/after surface.
    final range = DateTimeRange(
      start: widget.meetingStartedAt.subtract(const Duration(days: 7)),
      end: widget.meetingStartedAt.add(const Duration(days: 7)),
    );
    final events = ref
            .watch(eventsInRangeProvider(
              (workspaceId: widget.workspaceId, range: range),
            ))
            .asData
            ?.value ??
        const <CalendarEvent>[];
    final q = _query.trim().toLowerCase();
    final filtered = events
        .where((e) => q.isEmpty || e.title.toLowerCase().contains(q))
        .toList()
      ..sort((a, b) {
        final da = a.startTime.difference(widget.meetingStartedAt).abs();
        final db = b.startTime.difference(widget.meetingStartedAt).abs();
        return da.compareTo(db);
      });

    return CcDialog(
      title: l10n.meetingLinkEventTitle,
      maxWidth: 460,
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CcTextField(
              controller: _searchController,
              hintText: l10n.meetingLinkEventSearchHint,
              prefix: Icon(LucideIcons.search, size: 14, color: ds.muted),
            ),
            const SizedBox(height: AppSpacing.md),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xxxl,
                      ),
                      child: Center(
                        child: Text(
                          l10n.meetingLinkEventEmpty,
                          style: TextStyle(color: ds.muted),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const CcDivider(),
                      itemBuilder: (context, i) {
                        final e = filtered[i];
                        final selected = e.id == widget.currentEventId;
                        return _EventRow(
                          title: e.title,
                          subtitle:
                              '${DateFormat.MMMEd(locale).format(e.startTime.toLocal())} · '
                              '${DateFormat.Hm(locale).format(e.startTime.toLocal())}',
                          selected: selected,
                          onTap: _busy ? null : () => _link(e.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.currentEventId != null)
          CcButton(
            variant: CcButtonVariant.ghost,
            size: CcButtonSize.sm,
            onPressed: _busy ? null : _unlink,
            child: Text(l10n.meetingUnlinkEvent),
          ),
        CcButton(
          variant: CcButtonVariant.secondary,
          size: CcButtonSize.sm,
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return CcTile(
      onTap: onTap,
      selected: selected,
      leading: Icon(LucideIcons.calendar, size: 15, color: ds.accent),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14,
          color: ds.fg,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(subtitle, style: meetingMono(context, fontSize: 11)),
      trailing:
          selected ? Icon(LucideIcons.check, size: 16, color: ds.accent) : null,
    );
  }
}
