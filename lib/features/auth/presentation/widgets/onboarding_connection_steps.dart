import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/auth/presentation/widgets/api_keys_panel.dart';
import 'package:control_center/features/auth/presentation/widgets/onboarding_step_layout.dart';
import 'package:control_center/features/workspaces/presentation/widgets/add_workspace_form.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Connects a forge before advancing through first-run setup.
class OnboardingConnectStep extends StatelessWidget {
  /// Creates the forge connection step.
  const OnboardingConnectStep({
    required this.isAuthed,
    required this.onContinue,
    super.key,
  });

  /// Whether at least one forge is connected.
  final bool isAuthed;

  /// Advances after a forge is connected.
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return OnboardingStepLayout(
      content: const ApiKeysPanel(),
      footer: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: CcButton(
          onPressed: isAuthed ? onContinue : null,
          child: Text(l10n.continueLabel),
        ),
      ),
    );
  }
}

/// Creates the first workspace, then refreshes the workspace list.
class OnboardingWorkspaceStep extends ConsumerWidget {
  /// Creates the workspace step.
  const OnboardingWorkspaceStep({
    required this.onBack,
    required this.onContinue,
    super.key,
  });

  /// Returns to the previous step, if one exists.
  final VoidCallback? onBack;

  /// Advances after workspace creation.
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return AddWorkspaceForm(
      onCreated: (_) {
        ref.invalidate(workspacesProvider);
        onContinue();
      },
      onCancel: onBack,
      submitLabel: l10n.continueLabel,
      // The form owns its submit state, so it keeps building its own actions —
      // onboarding only re-composes where they sit: pinned under the scroll.
      layout: (fields, actions) =>
          OnboardingStepLayout(content: fields, footer: actions),
    );
  }
}
