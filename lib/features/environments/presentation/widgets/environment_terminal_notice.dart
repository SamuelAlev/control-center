import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_host.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// Says a start is waiting for someone on a terminal, with the way to it.
///
/// The person who pressed Start gets that terminal opened for them. This is
/// for everyone else looking at the environment, and for that person once
/// they have closed the tab or come back to the space: the start is still
/// going, and here is where it waits.
class EnvironmentTerminalNotice extends StatelessWidget {
  /// Creates an [EnvironmentTerminalNotice] for [component].
  const EnvironmentTerminalNotice({
    super.key,
    required this.spaceKey,
    required this.component,
  });

  /// The space the environment runs in.
  final EnvironmentSpaceKey spaceKey;

  /// The component whose verb runs on a terminal.
  final EnvironmentComponentState component;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final host = EnvironmentHostScope.maybeOf(context);
    final sessionId = component.sessionId;
    return CcAlert(
      variant: CcAlertVariant.warning,
      title: l10n.environmentWaitingInTerminal,
      description: Text(
        [?component.detail, l10n.environmentStartTerminalHint].join('\n'),
      ),
      // A surface with no editor has nowhere to open it.
      action: host == null || sessionId == null
          ? null
          : Align(
              alignment: AlignmentDirectional.centerStart,
              child: CcButton(
                size: CcButtonSize.sm,
                variant: CcButtonVariant.primary,
                icon: AppIcons.terminal,
                onPressed: () => host.openStartTerminal(
                  spaceId: spaceKey.spaceId,
                  sessionId: sessionId,
                  label: l10n.environmentStartTerminalTab,
                ),
                child: Text(l10n.environmentOpenTerminal),
              ),
            ),
    );
  }
}
