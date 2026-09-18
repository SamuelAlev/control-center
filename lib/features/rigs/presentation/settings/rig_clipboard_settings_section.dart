import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/rigs/providers/rig_clipboard_permissions.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_toggle.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// User-scoped defaults for clipboard transfers across enclosure boundaries.
class RigClipboardSettingsSection extends ConsumerWidget {
  /// Creates the clipboard settings section.
  const RigClipboardSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final preferences = ref.watch(rigClipboardPreferencesProvider);
    final notifier = ref.read(rigClipboardPreferencesProvider.notifier);

    return SectionCard(
      label: l10n.rigClipboardSettingsTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.rigClipboardSettingsHint,
            style: CcTypography.caption.copyWith(color: tokens.textTertiary),
          ),
          const SizedBox(height: AppSpacing.sm),
          SettingsToggle(
            title: l10n.rigClipboardAlwaysPasteTitle,
            description: l10n.rigClipboardAlwaysPasteDescription,
            value: preferences.alwaysAllowHostToRig,
            onChanged: (allowed) => unawaited(
              notifier.setAlwaysAllowed(
                RigClipboardDirection.hostToRig,
                allowed: allowed,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SettingsToggle(
            title: l10n.rigClipboardAlwaysCopyTitle,
            description: l10n.rigClipboardAlwaysCopyDescription,
            value: preferences.alwaysAllowRigToHost,
            onChanged: (allowed) => unawaited(
              notifier.setAlwaysAllowed(
                RigClipboardDirection.rigToHost,
                allowed: allowed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
