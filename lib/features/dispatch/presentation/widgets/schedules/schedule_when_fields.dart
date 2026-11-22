import 'package:cc_domain/features/dispatch/domain/services/wake_when.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_trigger.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/dispatch/presentation/schedule_text.dart';
import 'package:control_center/features/dispatch/providers/long_work_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_text.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How a new schedule fires.
enum ScheduleWhenKind {
  /// Once, after a delay (`in:<duration>`).
  onceIn,

  /// Once, at the next such wall-clock time (hour and minute).
  onceAt,

  /// Repeatedly (`every:<duration>`).
  every,

  /// On a cron schedule in a time zone (`cron:<five fields>`).
  cron,
}

/// The `when` a person typed, held by the create dialog.
class ScheduleWhenDraft {
  /// The kind.
  ScheduleWhenKind kind = ScheduleWhenKind.every;

  /// The duration (`20m`, `1h30m`) of [ScheduleWhenKind.onceIn] and
  /// [ScheduleWhenKind.every].
  final duration = TextEditingController(text: '1h');

  /// The clock of [ScheduleWhenKind.onceAt].
  final hour = TextEditingController(text: '9');

  /// The clock's minute.
  final minute = TextEditingController(text: '0');

  /// The five fields of [ScheduleWhenKind.cron].
  final cron = TextEditingController(text: '0 9 * * 1-5');

  /// The zone of a cron or a clock.
  final zone = TextEditingController();

  /// The `when` text, or null for a clock or an unreadable field.
  String? get when => switch (kind) {
    ScheduleWhenKind.onceIn =>
      _duration == null ? null : 'in:${duration.text.trim()}',
    ScheduleWhenKind.every =>
      _duration == null ? null : 'every:${duration.text.trim()}',
    ScheduleWhenKind.cron =>
      cronTrigger == null ? null : 'cron:${cron.text.trim()}',
    ScheduleWhenKind.onceAt => null,
  };

  Duration? get _duration => parseWakeDuration(duration.text.trim());

  /// The clock's hour, when in range.
  int? get clockHour => _ranged(hour.text, 23);

  /// The clock's minute, when in range.
  int? get clockMinute => _ranged(minute.text, 59);

  static int? _ranged(String text, int max) {
    final v = int.tryParse(text.trim());
    return v != null && v >= 0 && v <= max ? v : null;
  }

  /// The cron trigger the fields describe, or null when they do not parse.
  Cron? get cronTrigger {
    final reading = parseWakeWhen(
      'cron:${cron.text.trim()}',
      now: DateTime.now().toUtc(),
      timeZone: zone.text.trim(),
    );
    return reading is WakeWhenTrigger && reading.trigger is Cron
        ? reading.trigger as Cron
        : null;
  }

  /// Whether the fields describe a `when`.
  bool get valid =>
      looksLikeZoneName(zone.text) &&
      (kind == ScheduleWhenKind.onceAt
          ? clockHour != null && clockMinute != null
          : when != null);

  /// Releases the controllers.
  void dispose() {
    for (final c in [duration, hour, minute, cron, zone]) {
      c.dispose();
    }
  }
}

/// The fields of a [ScheduleWhenDraft]: the kind, then its duration, clock
/// or cron with zone. A cron previews its next three fire times in the
/// viewer's zone, as the server computes them ([cronPreviewProvider]).
class ScheduleWhenFields extends ConsumerWidget {
  /// Creates the fields.
  const ScheduleWhenFields({
    super.key,
    required this.workspaceId,
    required this.draft,
    required this.onChanged,
  });

  /// The workspace the schedule is made in (its zone is a cron's default).
  final String workspaceId;

  /// The draft.
  final ScheduleWhenDraft draft;

  /// Called after any change.
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ds = context.ds;
    final caption = CcTypography.caption.copyWith(color: ds.textSecondary);
    final cron = draft.kind == ScheduleWhenKind.cron ? draft.cronTrigger : null;
    final zoneText = draft.zone.text.trim();
    final zoneShaped = looksLikeZoneName(zoneText);
    // The server previews a cron and judges a typed zone (an empty
    // expression asks about the zone alone). While it answers, the shape
    // check alone judges the zone and no times show (as for a cron that
    // never fires); times already past are dropped.
    final asks =
        zoneShaped &&
        (cron != null ||
            (draft.kind == ScheduleWhenKind.onceAt && zoneText.isNotEmpty));
    final answer = asks
        ? ref
              .watch(
                cronPreviewProvider((
                  workspaceId: workspaceId,
                  expression: cron == null ? '' : draft.cron.text.trim(),
                  timeZone: zoneText,
                )),
              )
              .value
        : null;
    final zoneBad = !zoneShaped || answer?.zoneKnown == false;
    final now = DateTime.now().toUtc();
    final fires = cron == null
        ? const <DateTime>[]
        : [
            for (final f in answer?.nextFires ?? const <DateTime>[])
              if (f.isAfter(now)) f,
          ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        CcSelect<ScheduleWhenKind>(
          label: l10n.scheduleWhenLabel,
          value: draft.kind,
          options: [
            CcSelectOption(
              value: ScheduleWhenKind.every,
              label: l10n.scheduleWhenEvery,
            ),
            CcSelectOption(
              value: ScheduleWhenKind.cron,
              label: l10n.scheduleWhenCron,
            ),
            CcSelectOption(
              value: ScheduleWhenKind.onceIn,
              label: l10n.scheduleWhenOnceIn,
            ),
            CcSelectOption(
              value: ScheduleWhenKind.onceAt,
              label: l10n.scheduleWhenOnceAt,
            ),
          ],
          onChanged: (v) {
            draft.kind = v;
            onChanged();
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        switch (draft.kind) {
          ScheduleWhenKind.onceIn || ScheduleWhenKind.every => CcTextField(
            key: const ValueKey('schedule-duration'),
            controller: draft.duration,
            label: l10n.scheduleDurationLabel,
            hintText: '30m',
            helperText: l10n.scheduleDurationHelp,
            errorText: draft.when == null ? l10n.scheduleDurationInvalid : null,
            onChanged: (_) => onChanged(),
          ),
          ScheduleWhenKind.onceAt => Row(
            children: [
              for (final (ctrl, label) in [
                (draft.hour, l10n.scheduleHour),
                (draft.minute, l10n.scheduleMinute),
              ]) ...[
                SizedBox(
                  width: 96,
                  child: CcTextField(
                    controller: ctrl,
                    label: label,
                    maxLength: 2,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: _ZoneField(
                  draft: draft,
                  bad: zoneBad,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
          ScheduleWhenKind.cron => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                // RTL carve-out: a cron expression is code; its fields read
                // left to right in every locale.
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: CcTextField(
                    key: const ValueKey('schedule-cron'),
                    controller: draft.cron,
                    label: l10n.scheduleCronLabel,
                    errorText: cron == null ? l10n.scheduleCronInvalid : null,
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ZoneField(
                  draft: draft,
                  bad: zoneBad,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        },
        if (fires.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.scheduleNextFires(
              fires.map((f) => workTimeLabel(context, f)).join(' · '),
            ),
            style: caption,
          ),
        ],
      ],
    );
  }
}

class _ZoneField extends StatelessWidget {
  const _ZoneField({
    required this.draft,
    required this.bad,
    required this.onChanged,
  });

  final ScheduleWhenDraft draft;

  /// Whether the zone fails the shape check or the server called it
  /// unknown.
  final bool bad;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // RTL carve-out: an IANA zone name is an identifier.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: CcTextField(
        key: const ValueKey('schedule-zone'),
        controller: draft.zone,
        label: l10n.scheduleZoneLabel,
        hintText: 'Europe/Berlin',
        helperText: l10n.scheduleZoneHelp,
        errorText: bad ? l10n.scheduleZoneInvalid : null,
        onChanged: (_) => onChanged(),
      ),
    );
  }
}
