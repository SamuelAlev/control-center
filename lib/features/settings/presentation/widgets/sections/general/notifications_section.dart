import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/notifications/notification_category.dart';
import 'package:cc_domain/core/domain/notifications/notification_sound.dart';
import 'package:cc_domain/core/domain/ports/notification_preferences_port.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/notification_providers.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/general/settings_shared.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
            icon: AppIcons.bell,
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
            for (final group in NotificationCategoryGroup.values) ...[
              const SizedBox(height: 16),
              _GroupHeader(group: group),
              for (final cat in NotificationCategory.values.where(
                (c) => c.group == group,
              )) ...[
                const SizedBox(height: 8),
                _CategoryRow(category: cat),
              ],
              if (group == NotificationCategoryGroup.pullRequests) ...[
                const SizedBox(height: 8),
                const _MutedReposRow(),
              ],
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

/// A group heading in the category list.
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.group});

  final NotificationCategoryGroup group;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem;
    final label = switch (group) {
      NotificationCategoryGroup.agents => l10n.notificationGroupAgents,
      NotificationCategoryGroup.pullRequests =>
        l10n.notificationGroupPullRequests,
      NotificationCategoryGroup.messages => l10n.notificationGroupMessages,
      NotificationCategoryGroup.tickets => l10n.notificationGroupTickets,
      NotificationCategoryGroup.calendar => l10n.notificationGroupCalendar,
      NotificationCategoryGroup.machines => l10n.notificationGroupMachines,
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: CcTypography.caption.copyWith(
          color: tokens?.textTertiary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Per-repository mute, the undo surface for the in-flow "mute this
/// repository" action on a notification.
///
/// A mute you cannot find is a bug, so the same list that the bell's menu
/// writes to is editable here — and the count is on the collapsed row so a
/// forgotten mute is visible without expanding anything.
class _MutedReposRow extends ConsumerStatefulWidget {
  const _MutedReposRow();

  @override
  ConsumerState<_MutedReposRow> createState() => _MutedReposRowState();
}

class _MutedReposRowState extends ConsumerState<_MutedReposRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final muted =
        ref.watch(mutedReposProvider).asData?.value ?? const <String>{};
    // Read from the provider, not `context.currentWorkspaceId`: that getter
    // calls `GoRouterState.of`, which THROWS rather than returning null when
    // there is no route above — and this card is rendered directly in widget
    // tests and previews as well as under the settings route.
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final repos = workspaceId == null
        ? const <Repo>[]
        : (ref.watch(reposForWorkspaceProvider(workspaceId)).asData?.value ??
              const <Repo>[]);
    final forgeRepos = repos.where((r) => r.hasForgeRemote).toList()
      ..sort((a, b) => a.fullName.toLowerCase().compareTo(
        b.fullName.toLowerCase(),
      ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsRow(
          icon: AppIcons.bellOff,
          title: l10n.notificationsMutedRepos,
          subtitle: l10n.notificationsMutedReposCount(muted.length),
          trailing: CcButton(
            variant: CcButtonVariant.ghost,
            onPressed: forgeRepos.isEmpty
                ? null
                : () => setState(() => _expanded = !_expanded),
            child: Icon(
              _expanded ? AppIcons.chevronUp : AppIcons.chevronDown,
              size: 16,
            ),
          ),
        ),
        if (_expanded)
          for (final repo in forgeRepos) ...[
            const SizedBox(height: 8),
            _MutedRepoToggle(
              repoFullName: repo.fullName,
              muted: muted.contains(repo.fullName.toLowerCase()),
            ),
          ],
      ],
    );
  }
}

class _MutedRepoToggle extends ConsumerWidget {
  const _MutedRepoToggle({required this.repoFullName, required this.muted});

  final String repoFullName;
  final bool muted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(left: 24),
      child: SettingsRow(
        icon: AppIcons.gitBranch,
        title: repoFullName,
        subtitle: '',
        trailing: CcSwitch(
          value: muted,
          onChanged: (v) async {
            await ref
                .read(notificationPreferencesProvider)
                .setRepoMuted(repoFullName, muted: v);
            ref.invalidate(mutedReposProvider);
          },
        ),
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
    NotificationCategory.agentRunCompleted => AppIcons.bot,
    NotificationCategory.pullRequestPublished => AppIcons.gitPullRequest,
    NotificationCategory.prMerged => AppIcons.gitMerge,
    NotificationCategory.newMessage => AppIcons.messageSquare,
    NotificationCategory.prMentioned => AppIcons.gitPullRequestArrow,
    NotificationCategory.reviewRequested => AppIcons.gitPullRequestArrow,
    NotificationCategory.reviewStale => AppIcons.gitCommitHorizontal,
    NotificationCategory.prMergeReadiness => AppIcons.gitMerge,
    NotificationCategory.prReviewDecision => AppIcons.checkCheck,
    NotificationCategory.prChecksStatus => AppIcons.circleX,
    NotificationCategory.prThreadActivity => AppIcons.messageSquare,
    NotificationCategory.ticketAssigned => AppIcons.ticket,
    NotificationCategory.ticketStatusChanged => AppIcons.refreshCw,
    NotificationCategory.meetingStartsSoon => AppIcons.calendarClock,
    NotificationCategory.calendarAuthExpired => AppIcons.calendarX,
    NotificationCategory.rigStatusChanged => AppIcons.monitor,
  };

  String _title(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (category) {
      NotificationCategory.agentRunCompleted => l10n.notificationAgentFinished,
      NotificationCategory.pullRequestPublished => l10n.notificationPrPublished,
      NotificationCategory.prMerged => l10n.notificationPrMerged,
      NotificationCategory.newMessage => l10n.notificationNewMessages,
      NotificationCategory.prMentioned => l10n.notificationPrMentioned,
      NotificationCategory.reviewRequested => l10n.notificationReviewRequested,
      NotificationCategory.reviewStale => l10n.notificationReviewStale,
      NotificationCategory.prMergeReadiness =>
        l10n.notificationPrMergeReadiness,
      NotificationCategory.prReviewDecision =>
        l10n.notificationPrReviewDecision,
      NotificationCategory.prChecksStatus => l10n.notificationPrChecksStatus,
      NotificationCategory.prThreadActivity =>
        l10n.notificationPrThreadActivity,
      NotificationCategory.ticketAssigned => l10n.notificationTicketAssigned,
      NotificationCategory.ticketStatusChanged =>
        l10n.notificationTicketStatusChanged,
      NotificationCategory.meetingStartsSoon =>
        l10n.notificationMeetingStartsSoon,
      NotificationCategory.calendarAuthExpired =>
        l10n.notificationCalendarAuthExpiredTitle,
      NotificationCategory.rigStatusChanged =>
        l10n.notificationRigStatusChanged,
    };
  }

  String _subtitle(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (category) {
      NotificationCategory.agentRunCompleted => l10n.notifyAgentRunCompleted,
      NotificationCategory.pullRequestPublished => l10n.notifyPrPublished,
      NotificationCategory.prMerged => l10n.notifyPrMerged,
      NotificationCategory.newMessage => l10n.notifyNewMessages,
      NotificationCategory.prMentioned => l10n.notifyPrMentioned,
      NotificationCategory.reviewRequested => l10n.notifyReviewRequested,
      NotificationCategory.reviewStale => l10n.notifyReviewStale,
      NotificationCategory.prMergeReadiness => l10n.notifyPrMergeReadiness,
      NotificationCategory.prReviewDecision => l10n.notifyPrReviewDecision,
      NotificationCategory.prChecksStatus => l10n.notifyPrChecksStatus,
      NotificationCategory.prThreadActivity => l10n.notifyPrThreadActivity,
      NotificationCategory.ticketAssigned => l10n.notificationTicketAssigned,
      NotificationCategory.ticketStatusChanged =>
        l10n.notificationTicketStatusChanged,
      NotificationCategory.meetingStartsSoon => l10n.notifyMeetingStartsSoon,
      NotificationCategory.calendarAuthExpired =>
        l10n.notifyCalendarAuthExpired,
      NotificationCategory.rigStatusChanged => l10n.notifyRigStatusChanged,
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
      icon: AppIcons.clock,
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
          icon: AppIcons.volume2,
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
                style: CcTypography.caption.copyWith(
                  color: context.ds.textTertiary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 160,
              child: CcSlider(
                value: volume,
                divisions: 20,
                semanticLabel: l10n.notificationVolume,
                onChanged: (v) async {
                  await ref.read(notificationPreferencesProvider).setVolume(v);
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
    final config =
        ref.watch(_quietHoursProvider).asData?.value ??
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
      icon: AppIcons.moonStar,
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
              onChanged: (t) => update(
                QuietHoursConfig(
                  enabled: config.enabled,
                  start: t,
                  end: config.end,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text('–'),
            ),
            _TimeInput(
              value: config.end,
              onChanged: (t) => update(
                QuietHoursConfig(
                  enabled: config.enabled,
                  start: config.start,
                  end: t,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          CcSwitch(
            value: config.enabled,
            onChanged: (v) => update(
              QuietHoursConfig(
                enabled: v,
                start: config.start,
                end: config.end,
              ),
            ),
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
      child: CcTextField(
        controller: _ctrl,
        textAlign: TextAlign.center,
        textStyle: CcTypography.caption.copyWith(
          color: context.ds.textTertiary,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d:]')),
          LengthLimitingTextInputFormatter(5),
        ],
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
      icon: AppIcons.calendarClock,
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
