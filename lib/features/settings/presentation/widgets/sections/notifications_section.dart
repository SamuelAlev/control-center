import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/domain/notifications/notification_category.dart';
import 'package:control_center/core/domain/notifications/notification_sound.dart';
import 'package:control_center/core/domain/ports/notification_preferences_port.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/settings_shared.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

final _globalEnabledFutureProvider = FutureProvider<bool>((ref) {
  return ref.watch(notificationPreferencesProvider).isGlobalEnabled();
});

final _categoryEnabledFutureProvider =
    FutureProvider.family<bool, NotificationCategory>((ref, cat) {
  return ref.watch(notificationPreferencesProvider).isCategoryEnabled(cat);
});

final _batchPolicyProvider = FutureProvider<BatchDeliveryPolicy>((ref) {
  return ref.watch(notificationPreferencesProvider).getBatchDeliveryPolicy();
});
final _soundProvider = FutureProvider<NotificationSound>((ref) {
  return ref.watch(notificationPreferencesProvider).getNotificationSound();
});
final _volumeProvider = FutureProvider<double>((ref) {
  return ref.watch(notificationPreferencesProvider).getVolume();
});

final _quietHoursProvider = FutureProvider<QuietHoursConfig>((ref) {
  return ref.watch(notificationPreferencesProvider).getQuietHours();
});

final _calendarLeadProvider = FutureProvider<int>((ref) {
  return ref
      .watch(notificationPreferencesProvider)
      .getCalendarAlertLeadMinutes();
});

/// Settings section for notification preferences.
class NotificationsSection extends ConsumerWidget {
  /// Creates a [NotificationsSection].
  const NotificationsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final globalEnabled = ref.watch(_globalEnabledFutureProvider);
    final isOn = globalEnabled.asData?.value ?? true;

    final l10n = AppLocalizations.of(context);
    return SectionCard(
      label: l10n.notifications,
      child: Column(
        children: [
          SettingsRow(
            icon: LucideIcons.bell,
            title: l10n.enableNotifications,
            subtitle: l10n.showNativeNotifications,
            trailing: CcSwitch(
              value: isOn,
              onChanged: (v) async {
                final prefs = ref.read(notificationPreferencesProvider);
                await prefs.setGlobalEnabled(enabled: v);
                ref.invalidate(_globalEnabledFutureProvider);
              },
            ),
          ),
          if (isOn) ...[
            const SizedBox(height: 8),
            for (final cat in NotificationCategory.values) ...[
              _CategoryRow(category: cat),
              if (cat != NotificationCategory.values.last)
                const SizedBox(height: 8),
            ],
            const SizedBox(height: 16),
            const _BatchPolicyRow(),
            const SizedBox(height: 8),
            const _SoundRow(),
            const SizedBox(height: 8),
            const _QuietHoursRow(),
            const SizedBox(height: 8),
            const _CalendarAlertLeadRow(),
          ],
        ],
      ),
    );
  }
}

class _CategoryRow extends ConsumerWidget {
  const _CategoryRow({required this.category});

  final NotificationCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(_categoryEnabledFutureProvider(category));
    final isOn = enabled.asData?.value ?? true;

    return SettingsRow(
      icon: _icon,
      title: _title(context),
      subtitle: _subtitle(context),
      trailing: CcSwitch(
        value: isOn,
        onChanged: (v) async {
          final prefs = ref.read(notificationPreferencesProvider);
          await prefs.setCategoryEnabled(category, enabled: v);
          ref.invalidate(_categoryEnabledFutureProvider(category));
        },
      ),
    );
  }

  IconData get _icon => switch (category) {
        NotificationCategory.agentRunCompleted => LucideIcons.bot,
        NotificationCategory.pullRequestPublished => LucideIcons.gitPullRequest,
        NotificationCategory.prMerged => LucideIcons.gitMerge,
        NotificationCategory.newMessage => LucideIcons.messageSquare,
        NotificationCategory.externalPr => LucideIcons.gitPullRequestDraft,
        NotificationCategory.ticketAssigned => LucideIcons.ticket,
        NotificationCategory.ticketStatusChanged => LucideIcons.refreshCw,
        NotificationCategory.meetingStartsSoon => LucideIcons.calendarClock,
        NotificationCategory.calendarAuthExpired => LucideIcons.calendarX,
      };

  String _title(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (category) {
      NotificationCategory.agentRunCompleted => l10n.notificationAgentFinished,
      NotificationCategory.pullRequestPublished => l10n.notificationPrPublished,
      NotificationCategory.prMerged => l10n.notificationPrMerged,
      NotificationCategory.newMessage => l10n.notificationNewMessages,
      NotificationCategory.externalPr => l10n.notificationExternalPr,
      NotificationCategory.ticketAssigned => l10n.notificationTicketAssigned,
      NotificationCategory.ticketStatusChanged =>
        l10n.notificationTicketStatusChanged,
      NotificationCategory.meetingStartsSoon =>
        l10n.notificationMeetingStartsSoon,
      NotificationCategory.calendarAuthExpired =>
        l10n.notificationCalendarAuthExpiredTitle,
    };
  }

  String _subtitle(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (category) {
      NotificationCategory.agentRunCompleted =>
        l10n.notifyAgentRunCompleted,
      NotificationCategory.pullRequestPublished =>
        l10n.notifyPrPublished,
      NotificationCategory.prMerged =>
        l10n.notifyPrMerged,
      NotificationCategory.newMessage =>
        l10n.notifyNewMessages,
      NotificationCategory.externalPr =>
        l10n.notifyExternalPr,
      NotificationCategory.ticketAssigned =>
        l10n.notificationTicketAssigned,
      NotificationCategory.ticketStatusChanged =>
        l10n.notificationTicketStatusChanged,
      NotificationCategory.meetingStartsSoon =>
        l10n.notifyMeetingStartsSoon,
      NotificationCategory.calendarAuthExpired =>
        l10n.notifyCalendarAuthExpired,
    };
  }
}

class _BatchPolicyRow extends ConsumerWidget {
  const _BatchPolicyRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policy =
        ref.watch(_batchPolicyProvider).asData?.value ??
        BatchDeliveryPolicy.digest2h;

    return SettingsRow(
      icon: LucideIcons.clock,
      title: 'Delivery schedule',
      subtitle: 'How non-urgent notifications are batched and delivered.',
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 200),
        child: CcSelect<BatchDeliveryPolicy>(
          options: const [
            CcSelectOption(
              value: BatchDeliveryPolicy.realtime,
              label: 'Real-time',
            ),
            CcSelectOption(
              value: BatchDeliveryPolicy.digest2h,
              label: 'Every 2 hours',
            ),
            CcSelectOption(
              value: BatchDeliveryPolicy.digestDaily,
              label: 'Daily digest',
            ),
          ],
          value: policy,
          onChanged: (v) async {
            await ref
                .read(notificationPreferencesProvider)
                .setBatchDeliveryPolicy(v);
            ref.invalidate(_batchPolicyProvider);
          },
        ),
      ),
    );
  }
}
class _SoundRow extends ConsumerWidget {
  const _SoundRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sound =
        ref.watch(_soundProvider).asData?.value ?? NotificationSound.ping;
    final volume = ref.watch(_volumeProvider).asData?.value ?? 1.0;
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SettingsRow(
          icon: LucideIcons.volume2,
          title: l10n.notificationSound,
          subtitle: l10n.notificationSoundDescription,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: CcSelect<NotificationSound>(
                  // Flattened from the grouped sound list — the group
                  // section headers are dropped; options keep their original
                  // group order.
                  options: [
                    for (final group in NotificationSound.groups)
                      for (final s in NotificationSound.forGroup(group))
                        CcSelectOption(
                          value: s,
                          label: _labelForSound(l10n, s),
                        ),
                  ],
                  value: sound,
                  onChanged: (v) async {
                    await ref
                        .read(notificationPreferencesProvider)
                        .setNotificationSound(v);
                    ref.invalidate(_soundProvider);
                  },
                ),
              ),
              const SizedBox(width: 8),
              CcButton(
                onPressed: sound == NotificationSound.none
                    ? null
                    : () => ref
                        .read(notificationSoundServiceProvider)
                        .play(sound, volume: volume),
                child: Text(l10n.notificationSoundTest),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const SizedBox(width: 30),
            Expanded(
              child: Text(
                l10n.notificationVolume,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 160,
              child: Slider(
                value: volume,
                min: 0.0,
                max: 1.0,
                divisions: 20,
                onChanged: (v) async {
                  await ref
                      .read(notificationPreferencesProvider)
                      .setVolume(v);
                  ref.invalidate(_volumeProvider);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _labelForSound(AppLocalizations l10n, NotificationSound s) =>
      switch (s) {
        NotificationSound.none => l10n.notificationSoundNone,
        NotificationSound.ping => l10n.notificationSoundPing,
        NotificationSound.chime => l10n.notificationSoundChime,
        NotificationSound.pop => l10n.notificationSoundPop,
        NotificationSound.ding => l10n.notificationSoundDing,
        NotificationSound.whoosh => l10n.notificationSoundWhoosh,
        NotificationSound.migrosSoft => l10n.notificationSoundMigrosSoft,
        NotificationSound.migrosHard => l10n.notificationSoundMigrosHard,
        NotificationSound.sbb => l10n.notificationSoundSbb,
        NotificationSound.cff => l10n.notificationSoundCff,
        NotificationSound.ffs => l10n.notificationSoundFfs,
        NotificationSound.post => l10n.notificationSoundPost,
      };
}

class _QuietHoursRow extends ConsumerWidget {
  const _QuietHoursRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(_quietHoursProvider).asData?.value ??
        const QuietHoursConfig(
          enabled: false,
          start: TimeOfDay(hour: 22, minute: 0),
          end: TimeOfDay(hour: 8, minute: 0),
        );

    Future<void> update(QuietHoursConfig next) async {
      await ref.read(notificationPreferencesProvider).setQuietHours(next);
      ref.invalidate(_quietHoursProvider);
    }

    return SettingsRow(
      icon: LucideIcons.moonStar,
      title: 'Quiet hours',
      subtitle: config.enabled
          ? 'Non-urgent notifications suppressed '
              '${_fmt(config.start)}–${_fmt(config.end)}.'
          : 'Non-urgent notifications deliver at any time.',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (config.enabled) ...[
            _TimeInput(
              value: config.start,
              onChanged: (t) => update(QuietHoursConfig(
                enabled: config.enabled,
                start: t,
                end: config.end,
              )),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text('–'),
            ),
            _TimeInput(
              value: config.end,
              onChanged: (t) => update(QuietHoursConfig(
                enabled: config.enabled,
                start: config.start,
                end: t,
              )),
            ),
            const SizedBox(width: 12),
          ],
          CcSwitch(
            value: config.enabled,
            onChanged: (v) => update(QuietHoursConfig(
              enabled: v,
              start: config.start,
              end: config.end,
            )),
          ),
        ],
      ),
    );
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';
}

class _TimeInput extends StatefulWidget {
  const _TimeInput({required this.value, required this.onChanged});
  final TimeOfDay value;
  final ValueChanged<TimeOfDay> onChanged;

  @override
  State<_TimeInput> createState() => _TimeInputState();
}

class _TimeInputState extends State<_TimeInput> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _fmt(widget.value));
  }

  @override
  void didUpdateWidget(covariant _TimeInput old) {
    super.didUpdateWidget(old);
    final next = _fmt(widget.value);
    if (_ctrl.text != next) {
      _ctrl.text = next;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';

  void _commit(String v) {
    final parts = v.split(':');
    if (parts.length != 2) {
      return;
    }
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return;
    }
    widget.onChanged(TimeOfDay(hour: h, minute: m));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      child: TextField(
        controller: _ctrl,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d:]')),
          LengthLimitingTextInputFormatter(5),
        ],
        decoration: const InputDecoration(
          isCollapsed: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          border: OutlineInputBorder(borderRadius: AppRadii.brSm),
        ),
        onSubmitted: _commit,
        onEditingComplete: () => _commit(_ctrl.text),
      ),
    );
  }
}

class _CalendarAlertLeadRow extends ConsumerWidget {
  const _CalendarAlertLeadRow();

  static const _options = [5, 10, 15, 30];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final lead = ref.watch(_calendarLeadProvider).asData?.value ?? 5;

    return SettingsRow(
      icon: LucideIcons.calendarClock,
      title: l10n.calendarAlertLeadTime,
      subtitle: l10n.calendarAlertLeadTimeSubtitle,
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 160),
        child: CcSelect<int>(
          options: [
            for (final m in _options)
              CcSelectOption(
                value: m,
                label: l10n.calendarLeadMinutesOption(m),
              ),
          ],
          value: _options.contains(lead) ? lead : 5,
          onChanged: (v) async {
            await ref
                .read(notificationPreferencesProvider)
                .setCalendarAlertLeadMinutes(v);
            ref.invalidate(_calendarLeadProvider);
          },
        ),
      ),
    );
  }
}
