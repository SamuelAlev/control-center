import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/dispatch/presentation/schedule_text.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// The two delivery choices of a new schedule: what a fire does when the
/// agent is busy (null keeps the trigger's default) and what each fire
/// delivers.
class ScheduleDeliveryFields extends StatelessWidget {
  /// Creates the fields.
  const ScheduleDeliveryFields({
    super.key,
    required this.whenBusy,
    required this.deliver,
    required this.onWhenBusyChanged,
    required this.onDeliverChanged,
  });

  /// What a fire does when the agent is busy; null for the default.
  final WakeWhenBusy? whenBusy;

  /// What each fire delivers.
  final WakeDeliver deliver;

  /// Called with the new busy choice.
  final ValueChanged<WakeWhenBusy?> onWhenBusyChanged;

  /// Called with the new delivery choice.
  final ValueChanged<WakeDeliver> onDeliverChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: CcSelect<String>(
            label: l10n.scheduleWhenBusyLabel,
            value: whenBusy?.wire ?? '',
            options: [
              CcSelectOption(value: '', label: l10n.scheduleWhenBusyDefault),
              for (final w in WakeWhenBusy.values)
                CcSelectOption(
                  value: w.wire,
                  label: scheduleWhenBusyLabel(l10n, w),
                ),
            ],
            onChanged: (v) => onWhenBusyChanged(WakeWhenBusyWire.tryParse(v)),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: CcSelect<WakeDeliver>(
            label: l10n.scheduleDeliverLabel,
            value: deliver,
            options: [
              for (final d in WakeDeliver.values)
                CcSelectOption(value: d, label: scheduleDeliverLabel(l10n, d)),
            ],
            onChanged: onDeliverChanged,
          ),
        ),
      ],
    );
  }
}
