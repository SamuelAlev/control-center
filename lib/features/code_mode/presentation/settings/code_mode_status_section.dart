import 'package:cc_domain/cc_domain.dart' show CodeModeStatusDto;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Whether this server runs scripts (and, when it does not, why, in the
/// server's own words): every run here has `repl` exactly when it does.
class CodeModeStatusSection extends StatelessWidget {
  /// Creates the section for [status].
  const CodeModeStatusSection({
    super.key,
    required this.workspaceId,
    required this.status,
  });

  /// The workspace the status is for.
  final String workspaceId;

  /// What the server reported.
  final CodeModeStatusDto status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final version = status.runnerVersion;
    return SectionCard(
      label: l10n.codeModeStatusLabel,
      child: SettingsSummary(
        facts: [
          SettingsFact(
            label: l10n.codeModeFactAvailability,
            value: status.available
                ? l10n.codeModeAvailable
                : l10n.codeModeUnavailable,
            tone: status.available
                ? CcStatusTone.positive
                : CcStatusTone.negative,
          ),
          if (status.available && version != null && version.isNotEmpty)
            SettingsFact(label: l10n.codeModeFactRunner, value: version),
        ],
        note: status.available
            ? null
            : l10n.codeModeUnavailableNote(
                status.reason ?? l10n.codeModeNoReason,
              ),
        trailing: CcButton(
          variant: CcButtonVariant.secondary,
          size: CcButtonSize.sm,
          icon: AppIcons.scrollText,
          onPressed: () => context.go(codeExecutionsRoute(workspaceId)),
          child: Text(l10n.codeModeViewExecutions),
        ),
      ),
    );
  }
}
