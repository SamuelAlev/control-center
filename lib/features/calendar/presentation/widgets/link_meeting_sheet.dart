import 'package:cc_domain/features/meetings/domain/entities/meeting.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/calendar/presentation/providers/record_and_link_provider.dart';
import 'package:control_center/features/meetings/providers/meeting_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// A dialog that links one of the workspace's recorded meetings to a calendar
/// event. Lists meetings around the event's time (closest first), with search;
/// picking one links it (the meeting adopts the event title when its own isn't
/// custom). Self-contained — it performs the link and pops itself.
class LinkMeetingSheet extends ConsumerStatefulWidget {
  /// Creates a [LinkMeetingSheet].
  const LinkMeetingSheet({
    super.key,
    required this.workspaceId,
    required this.eventId,
    required this.eventStartTime,
  });

  /// Owning workspace.
  final String workspaceId;

  /// The event being linked to.
  final String eventId;

  /// The event's start, used to surface the nearest recordings first.
  final DateTime eventStartTime;

  @override
  ConsumerState<LinkMeetingSheet> createState() => _LinkMeetingSheetState();
}

class _LinkMeetingSheetState extends ConsumerState<LinkMeetingSheet> {
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

  Future<void> _link(String meetingId) async {
    if (_busy) {
      return;
    }
    final toaster = CcToastScope.of(context);
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(linkMeetingToEventUseCaseProvider).link(
            workspaceId: widget.workspaceId,
            meetingId: meetingId,
            calendarEventId: widget.eventId,
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
    final t = context.designSystem ?? DesignSystemTokens.light();
    final locale = Localizations.localeOf(context).toString();

    final meetings = ref
            .watch(meetingsProvider(widget.workspaceId))
            .asData
            ?.value ??
        const <Meeting>[];
    final q = _query.trim().toLowerCase();
    final filtered = meetings
        .where((m) => q.isEmpty || m.title.toLowerCase().contains(q))
        .toList()
      ..sort((a, b) {
        final da = a.startedAt.difference(widget.eventStartTime).abs();
        final db = b.startedAt.difference(widget.eventStartTime).abs();
        return da.compareTo(db);
      });

    return Dialog(
      backgroundColor: t.bgPrimary,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.calendarLinkMeetingTitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: t.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              CcTextField(
                controller: _searchController,
                hintText: l10n.calendarLinkMeetingSearchHint,
                prefix: Icon(
                  AppIcons.search,
                  size: 14,
                  color: t.textTertiary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Flexible(
                child: filtered.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xxxl,
                        ),
                        child: Center(
                          child: Text(
                            l10n.calendarLinkMeetingEmpty,
                            style: TextStyle(color: t.textSecondary),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          color: t.borderSecondary,
                        ),
                        itemBuilder: (context, i) {
                          final m = filtered[i];
                          return _MeetingRow(
                            title: m.title,
                            subtitle:
                                '${DateFormat.MMMEd(locale).format(m.startedAt.toLocal())} · '
                                '${DateFormat.Hm(locale).format(m.startedAt.toLocal())}',
                            tokens: t,
                            onTap: _busy ? null : () => _link(m.id),
                          );
                        },
                      ),
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: CcButton(
                  variant: CcButtonVariant.secondary,
                  size: CcButtonSize.sm,
                  onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeetingRow extends StatelessWidget {
  const _MeetingRow({
    required this.title,
    required this.subtitle,
    required this.tokens,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final DesignSystemTokens tokens;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.brSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(AppIcons.audioLines, size: 15, color: tokens.fgBrandPrimary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: tokens.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
