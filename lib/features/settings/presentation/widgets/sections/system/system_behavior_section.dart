import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/providers/agent_awake_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/general/settings_shared.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// System-behavior settings exposed in General Settings.
///
/// Currently the "keep computer awake while agents run" toggle, which drives the
/// `AgentAwakeService` (an `NSProcessInfo` activity assertion on macOS).
class SystemBehaviorSection extends ConsumerWidget {
  /// Creates a [SystemBehaviorSection].
  const SystemBehaviorSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keepAwake = ref.watch(keepComputerAwakeProvider);
    final l10n = AppLocalizations.of(context);

    return SectionCard(
      label: l10n.systemBehavior,
      child: Column(
        children: [
          SettingsRow(
            icon: AppIcons.activity,
            title: l10n.keepAwakeTitle,
            subtitle: keepAwake
                ? l10n.keepAwakeOnSubtitle
                : l10n.keepAwakeOffSubtitle,
            trailing: CcSwitch(
              value: keepAwake,
              onChanged: (v) => ref
                  .read(keepComputerAwakeProvider.notifier)
                  .setEnabled(value: v),
            ),
          ),
        ],
      ),
    );
  }
}
