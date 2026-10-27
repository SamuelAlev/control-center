import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/general/settings_shared.dart';
import 'package:control_center/features/settings/providers/privacy_providers.dart';
import 'package:control_center/features/telemetry/providers/usage_analytics_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _llmDiffSharingProvider = NotifierProvider<_LlmDiffSharingNotifier, bool>(
  _LlmDiffSharingNotifier.new,
);

class _LlmDiffSharingNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.watch(privacyPreferencesProvider).llmDiffSharingEnabled;
  }

  Future<void> toggle({required bool value}) async {
    await ref
        .read(privacyPreferencesProvider)
        .setLlmDiffSharingEnabled(value: value);
    state = value;
  }
}

/// Privacy settings section exposed in General Settings.
///
/// Controls whether raw diff content may be forwarded to the agent LLM adapter
/// (default on; off limits agents to structured metadata), whether this
/// device shares crash reports, and the server-wide usage-analytics switch,
/// which only the server operator can change.
class PrivacySection extends ConsumerWidget {
  /// Creates a [PrivacySection].
  const PrivacySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diffSharingEnabled = ref.watch(_llmDiffSharingProvider);
    final errorReportingEnabled = ref.watch(errorReportingEnabledProvider);
    final usageAnalytics = ref.watch(usageAnalyticsProvider);
    final canManageUsageAnalytics = ref.watch(canManageUsageAnalyticsProvider);
    final l10n = AppLocalizations.of(context);

    return SectionCard(
      label: l10n.privacy,
      child: Column(
        children: [
          SettingsRow(
            icon: AppIcons.shield,
            title: l10n.sendDiffContentTitle,
            subtitle: diffSharingEnabled
                ? l10n.diffSharingOnSubtitle
                : l10n.diffSharingOffSubtitle,
            trailing: CcSwitch(
              value: diffSharingEnabled,
              onChanged: (v) =>
                  ref.read(_llmDiffSharingProvider.notifier).toggle(value: v),
            ),
          ),
          SettingsRow(
            icon: AppIcons.activity,
            title: l10n.errorReportingTitle,
            subtitle: errorReportingEnabled
                ? l10n.errorReportingOnSubtitle
                : l10n.errorReportingOffSubtitle,
            trailing: CcSwitch(
              value: errorReportingEnabled,
              onChanged: (v) => ref
                  .read(errorReportingEnabledProvider.notifier)
                  .setEnabled(value: v),
            ),
          ),
          SettingsRow(
            icon: AppIcons.barChart2,
            title: l10n.usageAnalyticsTitle,
            subtitle: switch ((
              usageAnalytics ?? false,
              canManageUsageAnalytics,
            )) {
              (true, true) => l10n.usageAnalyticsOnSubtitle,
              (false, true) => l10n.usageAnalyticsOffSubtitle,
              (true, false) => l10n.usageAnalyticsManagedOnSubtitle,
              (false, false) => l10n.usageAnalyticsManagedOffSubtitle,
            },
            trailing: CcSwitch(
              value: usageAnalytics ?? false,
              onChanged: usageAnalytics == null || !canManageUsageAnalytics
                  ? null
                  : (v) => ref
                        .read(usageAnalyticsProvider.notifier)
                        .setEnabled(value: v),
            ),
          ),
        ],
      ),
    );
  }
}
