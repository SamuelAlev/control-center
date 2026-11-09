import 'package:cc_domain/features/calendar/domain/entities/calendar_event_draft.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/calendar/presentation/providers/calendar_event_write_provider.dart';
import 'package:control_center/features/calendar/presentation/providers/calendar_ui_providers.dart';
import 'package:control_center/features/calendar/presentation/widgets/calendar_composer_fields.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The floating card that turns a drawn span into a Google Calendar event.
///
/// The span lives in [calendarComposerProvider], so editing a time here moves
/// the placeholder tile on the grid too. Saving books the event on the host
/// and opens it in the detail pane; Escape or the close button drops it.
class CalendarEventComposer extends ConsumerStatefulWidget {
  /// Creates a [CalendarEventComposer] for [slot].
  const CalendarEventComposer({super.key, required this.slot});

  /// The span being composed.
  final CalendarSlot slot;

  @override
  ConsumerState<CalendarEventComposer> createState() => _ComposerState();
}

class _ComposerState extends ConsumerState<CalendarEventComposer> {
  final _title = TextEditingController();
  final _guests = TextEditingController();
  final _location = TextEditingController();
  final _description = TextEditingController();
  String? _calendarKey;
  bool _meet = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_title, _guests, _location, _description]) {
      c.dispose();
    }
    super.dispose();
  }

  CalendarComposerNotifier get _composer =>
      ref.read(calendarComposerProvider.notifier);

  void _set(CalendarSlot next) {
    setState(() => _error = null);
    _composer.update(next);
  }

  Future<void> _save(CalendarSourceView calendar) async {
    final l10n = AppLocalizations.of(context);
    final slot = widget.slot;
    final CalendarEventDraft draft;
    try {
      draft = CalendarEventDraft(
        accountId: calendar.accountId,
        calendarId: calendar.id,
        title: _title.text,
        start: slot.start,
        end: slot.end,
        isAllDay: slot.allDay,
        location: _location.text,
        description: _description.text,
        attendeeEmails: _guests.text.split(RegExp(r'[,;\s]+')),
        addConference: _meet,
      );
    } on ArgumentError catch (e) {
      setState(() {
        _error = switch (e.name) {
          'title' => l10n.calendarComposerTitleRequired,
          'attendees' => l10n.calendarComposerInvalidGuests,
          _ => l10n.calendarComposerEndBeforeStart,
        };
      });
      return;
    }
    final workspaceId = context.currentWorkspaceId!;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final id = await ref
          .read(calendarEventWriteServiceProvider)
          .create(workspaceId, draft);
      if (!mounted) {
        return;
      }
      _composer.close();
      context.go(calendarDetailRoute(workspaceId, id));
    } on Object {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = l10n.calendarComposerSaveFailed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final slot = widget.slot;
    final calendars = ref.watch(writableCalendarsProvider);
    if (calendars.isEmpty) {
      return const SizedBox.shrink();
    }
    final calendar = calendars.firstWhere(
      (c) => c.key == _calendarKey,
      orElse: () => calendars.first,
    );
    final lastDay = slot.end.subtract(const Duration(days: 1));

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _composer.close,
      },
      child: Semantics(
        container: true,
        label: l10n.calendarNewEvent,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: CcTextField(
                      controller: _title,
                      autofocus: true,
                      chromeless: true,
                      hintText: l10n.calendarComposerTitleHint,
                      textStyle: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: t.textPrimary,
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _save(calendar),
                    ),
                  ),
                  CcIconButton(
                    icon: AppIcons.x,
                    variant: CcButtonVariant.ghost,
                    size: CcButtonSize.sm,
                    tooltip: l10n.close,
                    semanticLabel: l10n.close,
                    onPressed: _composer.close,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ComposerRow(
                      icon: AppIcons.clock,
                      child: ComposerWhenFields(
                        slot: slot,
                        lastDay: lastDay,
                        onStart: (start) => _set(slot.withStart(start)),
                        onEnd: (end) => _set(slot.withEnd(end)),
                        onDay: (day) => _set(slot.onDay(day)),
                        onLastDay: (day) => _set(slot.through(day)),
                        onAllDay: (allDay) => _set(slot.asAllDay(allDay)),
                      ),
                    ),
                    ComposerRow(
                      icon: AppIcons.users,
                      chromeless: true,
                      child: CcTextField(
                        controller: _guests,
                        chromeless: true,
                        hintText: l10n.calendarComposerGuestsHint,
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    ComposerRow(
                      icon: AppIcons.video,
                      child: CcCheckbox(
                        value: _meet,
                        onChanged: (v) => setState(() => _meet = v),
                        label: Text(l10n.calendarComposerMeet),
                      ),
                    ),
                    ComposerRow(
                      icon: AppIcons.mapPin,
                      chromeless: true,
                      child: CcTextField(
                        controller: _location,
                        chromeless: true,
                        hintText: l10n.calendarComposerLocationHint,
                      ),
                    ),
                    ComposerRow(
                      icon: AppIcons.alignJustify,
                      chromeless: true,
                      child: CcTextField(
                        controller: _description,
                        chromeless: true,
                        hintText: l10n.calendarComposerDescriptionHint,
                        minLines: 1,
                        maxLines: 6,
                        keyboardType: TextInputType.multiline,
                      ),
                    ),
                    ComposerRow(
                      icon: AppIcons.calendar,
                      child: CcSelect<String>(
                        semanticLabel: l10n.calendarComposerCalendar,
                        value: calendar.key,
                        options: [
                          for (final c in calendars)
                            CcSelectOption(
                              value: c.key,
                              label: calendars.length > 1 && !c.primary
                                  ? '${c.summary} · ${c.accountEmail}'
                                  : c.summary,
                            ),
                        ],
                        onChanged: (key) => setState(() => _calendarKey = key),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: t.textErrorPrimary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _guests.text.trim().isEmpty
                                ? ''
                                : l10n.calendarComposerGuestsNotified,
                            style: TextStyle(
                              fontSize: 12,
                              color: t.textTertiary,
                            ),
                          ),
                        ),
                        CcButton(
                          size: CcButtonSize.sm,
                          loading: _saving,
                          onPressed: _saving ? null : () => _save(calendar),
                          child: Text(l10n.save),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
