/// The steps of a `/loop` or `/schedule` after its name, offered in the
/// composer's own suggestion list: when it fires, then (on `--`) its limits.
///
/// Picking `/schedule` leads straight into the first step, and each pick
/// writes ordinary command text, so the message that is sent is the one the
/// server already reads.
library;

import 'package:cc_domain/features/dispatch/domain/services/wake_when.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_text.dart';
import 'package:control_center/features/messaging/providers/wake_command_arguments.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/composer/mention/mention_source.dart';
import 'package:flutter/widgets.dart';

/// Offers one step of a `/loop` or `/schedule`.
class WakeArgumentSource extends SyncMentionSource {
  /// Offers when it fires, under a "When it fires" heading.
  WakeArgumentSource.when({
    required AppLocalizations l10n,
    required String Function(DateTime at) timeLabel,
    DateTime Function()? now,
  }) : this._(WakeArgumentStep.when, l10n, timeLabel, now);

  /// Offers the limits (`--max`, `--days`, `--budget`).
  WakeArgumentSource.option({required AppLocalizations l10n})
    : this._(WakeArgumentStep.option, l10n, null, null);

  WakeArgumentSource._(this._step, this._l10n, this._timeLabel, this._now);

  final WakeArgumentStep _step;
  final AppLocalizations _l10n;
  final String Function(DateTime at)? _timeLabel;
  final DateTime Function()? _now;

  @override
  String get kind => 'wake_${_step.name}';

  @override
  Set<MentionTrigger> get triggers => const {MentionTrigger.argument};

  @override
  String? sectionLabel(BuildContext context) =>
      _step == WakeArgumentStep.when ? _l10n.scheduleWhenLabel : null;

  @override
  MentionQuery? detect(String text, int caret) {
    final query = wakeArgumentQuery(text, caret);
    return query?.step == _step ? query : null;
  }

  @override
  List<MentionSuggestion> suggestSync(MentionQuery query) {
    if (query is! WakeArgumentQuery || query.step != _step) {
      return const [];
    }
    return [
      for (final token in query.tokens)
        MentionSuggestion(
          id: '$kind:$token',
          kind: kind,
          label: token,
          description: _describe(token),
          icon: _icon(token),
          replacement: '$token ',
        ),
    ];
  }

  IconData _icon(String token) => switch (token.split(' ').first) {
    'in' || 'at' => AppIcons.calendarClock,
    'every' || 'cron' => AppIcons.repeat,
    _ => AppIcons.slidersHorizontal,
  };

  String? _describe(String token) {
    final space = token.indexOf(' ');
    final word = space < 0 ? token : token.substring(0, space);
    final value = space < 0 ? '' : token.substring(space + 1);
    switch (word) {
      case '--max':
        return _l10n.scheduleMaxRuns;
      case '--days':
        return _l10n.scheduleExpiresInDays;
      case '--budget':
        return _l10n.scheduleCostCap;
      case 'every':
        final d = parseWakeDuration(value);
        return d == null
            ? null
            : _l10n.scheduleTriggerEvery(workDurationLabel(d));
      case 'in':
        final d = parseWakeDuration(value);
        final now = (_now ?? DateTime.now)();
        return d == null
            ? null
            : _l10n.scheduleTriggerOnce(_timeLabel!(now.add(d)));
      case 'at':
        // The clock as written. Which day that is depends on the
        // workspace's zone, which the server knows: the composer's strip
        // says it once the time is picked.
        final clock = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(value);
        if (clock == null) {
          return null;
        }
        final now = (_now ?? DateTime.now)();
        final written = DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(clock[1]!),
          int.parse(clock[2]!),
        );
        return _l10n.scheduleTriggerOnce(_timeLabel!(written));
      default:
        return switch (value) {
          '"$wakeCronWeekdays"' => _l10n.schedulePresetWeekdays,
          '"$wakeCronDaily"' => _l10n.schedulePresetDaily,
          '"$wakeCronHourly"' => _l10n.schedulePresetHourly,
          _ => _l10n.scheduleWhenCron,
        };
    }
  }
}
