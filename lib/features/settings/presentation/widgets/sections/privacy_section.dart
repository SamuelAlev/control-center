import 'package:control_center/di/providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/settings_shared.dart';
import 'package:control_center/features/settings/providers/privacy_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
/// Controls whether raw diff content may be forwarded to the agent LLM adapter.
/// Default on; turning it off limits agents to structured metadata only.
class PrivacySection extends ConsumerWidget {
  /// Creates a [PrivacySection].
  const PrivacySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diffSharingEnabled = ref.watch(_llmDiffSharingProvider);
    final errorReportingEnabled = ref.watch(errorReportingEnabledProvider);
    final l10n = AppLocalizations.of(context);

    return SectionCard(
      label: l10n.privacy,
      child: Column(
        children: [
          SettingsRow(
            icon: LucideIcons.shield,
            title: l10n.sendDiffContentTitle,
            subtitle: diffSharingEnabled
                ? l10n.diffSharingOnSubtitle
                : l10n.diffSharingOffSubtitle,
            trailing: FSwitch(
              value: diffSharingEnabled,
              onChange: (v) =>
                  ref.read(_llmDiffSharingProvider.notifier).toggle(value: v),
            ),
          ),
          SettingsRow(
            icon: LucideIcons.activity,
            title: l10n.errorReportingTitle,
            subtitle: errorReportingEnabled
                ? l10n.errorReportingOnSubtitle
                : l10n.errorReportingOffSubtitle,
            trailing: FSwitch(
              value: errorReportingEnabled,
              onChange: (v) => ref
                  .read(errorReportingEnabledProvider.notifier)
                  .setEnabled(value: v),
            ),
          ),
        ],
      ),
    );
  }
}
