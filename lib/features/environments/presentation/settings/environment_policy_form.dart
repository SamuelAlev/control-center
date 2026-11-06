import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/environments/presentation/settings/environment_form_fields.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Where a definition runs and when it starts and stops on its own.
class EnvironmentPolicyForm extends StatelessWidget {
  /// Creates an [EnvironmentPolicyForm].
  const EnvironmentPolicyForm({super.key, required this.form});

  /// The draft.
  final EnvironmentForm form;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EnvironmentSelectField(
          form: form,
          path: const ['placement'],
          label: l10n.environmentsPlacement,
          fallback: 'host',
          options: [
            CcSelectOption(
              value: 'host',
              label: l10n.environmentsPlacementHost,
            ),
            CcSelectOption(value: 'rig', label: l10n.environmentsPlacementRig),
          ],
        ),
        environmentFieldGap,
        EnvironmentSelectField(
          form: form,
          path: const ['policy', 'autoCreate'],
          label: l10n.environmentsAutoCreate,
          fallback: 'off',
          options: [
            CcSelectOption(value: 'off', label: l10n.environmentsAutoCreateOff),
            CcSelectOption(
              value: 'prSpaces',
              label: l10n.environmentsAutoCreatePrs,
            ),
            CcSelectOption(
              value: 'allSpaces',
              label: l10n.environmentsAutoCreateAll,
            ),
          ],
        ),
        environmentFieldGap,
        EnvironmentSelectField(
          form: form,
          path: const ['policy', 'forkPrs'],
          label: l10n.environmentsForkPrs,
          // Unset still means something: show what would actually happen.
          fallback: form.state.parsed?.forkPolicy.name,
          options: [
            CcSelectOption(value: 'rig', label: l10n.environmentsForkRig),
            CcSelectOption(
              value: 'approval',
              label: l10n.environmentsForkApproval,
            ),
            CcSelectOption(value: 'deny', label: l10n.environmentsForkDeny),
          ],
        ),
        environmentFieldGap,
        EnvironmentCheckField(
          form: form,
          path: const ['policy', 'followPrHead'],
          label: l10n.environmentsFollowPrHead,
          description: l10n.environmentsFollowPrHeadHelp,
          fallback: true,
        ),
        environmentFieldGap,
        EnvironmentNumberField(
          form: form,
          path: const ['policy', 'idleStopMinutes'],
          label: l10n.environmentsIdleStop,
          description: l10n.environmentsIdleStopHelp,
          fallback: 240,
        ),
        environmentFieldGap,
        EnvironmentNumberField(
          form: form,
          path: const ['policy', 'maxRunning'],
          label: l10n.environmentsMaxRunning,
          fallback: 6,
        ),
        environmentFieldGap,
        EnvironmentNumberField(
          form: form,
          path: const ['policy', 'rigTtlHours'],
          label: l10n.environmentsRigTtl,
          fallback: 24,
        ),
      ],
    );
  }
}
