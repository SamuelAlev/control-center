// Web onboarding steps for the on-device models.
//
// The voice + embedding (+ diarization) models are on-device inference
// (cc_natives FFI, uncompilable by dart2js) installed into the local
// app-support directory — desktop-only. On web these onboarding steps render an
// honest "desktop-only" message and let the user continue/finish; the models are
// simply unavailable.
library;

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _ModelStepPlaceholder extends StatelessWidget {
  const _ModelStepPlaceholder({
    required this.message,
    required this.onBack,
    required this.onForward,
    required this.forwardLabel,
  });

  final String message;
  final VoidCallback onBack;
  final VoidCallback onForward;
  final String forwardLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.designSystem;
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: tokens?.textPrimary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            CcButton(
              onPressed: onBack,
              variant: CcButtonVariant.secondary,
              child: Text(l10n.back),
            ),
            const Spacer(),
            CcButton(onPressed: onForward, child: Text(forwardLabel)),
          ],
        ),
      ],
    );
  }
}

/// Web placeholder for the desktop voice-model onboarding step.
class OnboardingVoiceStep extends ConsumerWidget {
  /// Creates the web placeholder.
  const OnboardingVoiceStep({
    required this.onBack,
    required this.onContinue,
    super.key,
  });

  /// Goes back to the previous step.
  final VoidCallback onBack;

  /// Advances to the next step.
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return _ModelStepPlaceholder(
      message: 'The voice (speech-to-text) model runs on-device — a '
          'desktop-only feature, not available on web.',
      onBack: onBack,
      onForward: onContinue,
      forwardLabel: l10n.continueLabel,
    );
  }
}

/// Web placeholder for the desktop embedding-model onboarding step (final step).
class OnboardingEmbeddingStep extends ConsumerWidget {
  /// Creates the web placeholder.
  const OnboardingEmbeddingStep({
    required this.onBack,
    required this.onFinish,
    super.key,
  });

  /// Goes back to the previous step.
  final VoidCallback onBack;

  /// Completes onboarding.
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return _ModelStepPlaceholder(
      message: 'The embedding and diarization models run on-device — a '
          'desktop-only feature, not available on web.',
      onBack: onBack,
      onForward: onFinish,
      forwardLabel: l10n.finish,
    );
  }
}
