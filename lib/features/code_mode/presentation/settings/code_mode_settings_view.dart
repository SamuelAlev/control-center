import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/code_mode/presentation/settings/code_mode_limits_section.dart';
import 'package:control_center/features/code_mode/presentation/settings/code_mode_status_section.dart';
import 'package:control_center/features/code_mode/providers/code_mode_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/presentation/screens/settings_page.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/utils/failure_message.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Workspace → Code mode.
///
/// Opens with whether this server runs scripts (every run here has `repl`
/// exactly when it does), then the limits, folded away because most
/// workspaces never touch them.
///
/// The status is read once here and handed down, so both cards always
/// describe the same answer. A demo server runs no scripts and refuses the
/// write, so the limits are not offered at all; the status still says why.
class CodeModeSettingsView extends ConsumerWidget {
  /// Creates a [CodeModeSettingsView].
  const CodeModeSettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    if (workspaceId == null || workspaceId.isEmpty) {
      return const SizedBox.shrink();
    }
    final status = ref.watch(codeModeStatusProvider(workspaceId));
    final isAdmin =
        ref.watch(myWorkspaceRoleProvider(workspaceId))?.isAdmin ?? false;
    final demo = ref.watch(isDemoServerProvider);

    final List<Widget> sections;
    if (status.value case final s?) {
      sections = [
        CodeModeStatusSection(workspaceId: workspaceId, status: s),
        if (!demo)
          CodeModeLimitsSection(
            workspaceId: workspaceId,
            status: s,
            canEdit: isAdmin,
          ),
      ];
    } else if (status.hasError) {
      sections = [
        SectionCard(
          child: CcAlert(
            title: failureMessage(l10n, status.error!),
            variant: CcAlertVariant.danger,
          ),
        ),
      ];
    } else {
      sections = const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
          child: Center(child: CcSpinner()),
        ),
      ];
    }
    return SettingsPage(
      title: l10n.codeModeTitle,
      subtitle: l10n.codeModeSubtitle,
      sections: sections,
    );
  }
}
