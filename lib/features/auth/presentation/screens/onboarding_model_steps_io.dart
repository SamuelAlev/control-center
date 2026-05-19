// Desktop onboarding steps for the on-device models (voice + embedding +
// optional diarization).
//
// These steps download/install on-device models (cc_natives FFI, cached to the
// local app-support directory) — desktop-only. They are extracted behind a seam
// (`onboarding_model_steps.dart`) so the web onboarding renders honest
// "desktop-only" placeholders instead, keeping cc_natives off the web compile.
library;

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/infrastructure/embedding/embedding_providers.dart';
import 'package:control_center/core/infrastructure/speech/diarization_model_providers.dart';
import 'package:control_center/core/infrastructure/speech/voice_model_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/audio_input_row.dart'
    show AudioInputRow;
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Onboarding step: install the on-device voice (speech-to-text) model.
class OnboardingVoiceStep extends ConsumerWidget {
  /// Creates the voice onboarding step.
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
    final state = ref.watch(voiceModelStateProvider);
    final notifier = ref.read(voiceModelStateProvider.notifier);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final isInstalled = state.status == VoiceModelStatus.installed;
    final isDownloading = state.status == VoiceModelStatus.downloading;
    final hasError = state.status == VoiceModelStatus.error;

    final tokens = context.designSystem;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              isInstalled
                  ? AppIcons.circleCheck
                  : (isDownloading ? AppIcons.download : AppIcons.mic),
              size: 18,
              color: isInstalled
                  ? theme.colorScheme.primary
                  : tokens?.textTertiary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isInstalled
                    ? 'Voice model installed and ready to use.'
                    : (isDownloading
                        ? (state.phase == 'extracting'
                            ? l10n.extractingModel((state.progress * 100).round())
                            : l10n.downloadingModel((state.progress * 100).round()))
                        : l10n.voiceModelNotInstalledLabel),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: tokens?.textPrimary,
                ),
              ),
            ),
          ],
        ),
        if (isDownloading) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: state.progress > 0
                ? CcProgressBar(value: state.progress)
                : const CcProgressBar(),
          ),
        ],
        if (hasError && state.error != null) ...[
          const SizedBox(height: 12),
          Text(
            state.error!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: 16),
        const AudioInputRow(),
        const SizedBox(height: 20),
        Row(
          children: [
            CcButton(
              onPressed: onBack,
              variant: CcButtonVariant.secondary,
              child: Text(l10n.back),
            ),
            const Spacer(),
            if (isDownloading)
              CcButton(
                onPressed: notifier.cancel,
                variant: CcButtonVariant.secondary,
                child: Text(l10n.cancel),
              )
            else if (isInstalled)
              CcButton(
                onPressed: onContinue,
                child: Text(l10n.continueLabel),
              )
            else ...[
              CcButton(
                onPressed: onContinue,
                variant: CcButtonVariant.secondary,
                child: Text(l10n.skipForNow),
              ),
              const SizedBox(width: 8),
              CcButton(
                onPressed: notifier.installIfNeeded,
                child: Text(l10n.download),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Onboarding step: install the on-device embedding model (+ optional
/// diarization). This is the final step; [onFinish] completes onboarding.
class OnboardingEmbeddingStep extends ConsumerWidget {
  /// Creates the embedding onboarding step.
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
    final state = ref.watch(embeddingModelStateProvider);
    final notifier = ref.read(embeddingModelStateProvider.notifier);
    final theme = Theme.of(context);
    final tokens = context.designSystem;
    final l10n = AppLocalizations.of(context);

    final isInstalled = state.status == EmbeddingModelStatus.installed;
    final isDownloading = state.status == EmbeddingModelStatus.downloading;
    final hasError = state.status == EmbeddingModelStatus.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Optional, non-blocking speaker-diarization download. Finishing
        // onboarding is never gated on this — the buttons below stay wired
        // to the embedding model only.
        const _DiarizationOptionalBlock(),
        const SizedBox(height: 20),
        Divider(
          height: 1,
          thickness: 1,
          color: tokens?.borderSoft ??
              theme.colorScheme.onSurface.withValues(alpha: 0.12),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Icon(
              isInstalled
                  ? AppIcons.circleCheck
                  : (isDownloading
                      ? AppIcons.download
                      : AppIcons.brain),
              size: 18,
              color: isInstalled
                  ? theme.colorScheme.primary
                  : tokens?.textTertiary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isInstalled
                    ? 'Embedding model installed and ready to use.'
                    : (isDownloading
                        ? 'Downloading… ${(state.progress * 100).toStringAsFixed(0)}%'
                        : 'Embedding model not installed.'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: tokens?.textPrimary,
                ),
              ),
            ),
          ],
        ),
        if (isDownloading) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: state.progress > 0
                ? CcProgressBar(value: state.progress)
                : const CcProgressBar(),
          ),
        ],
        if (hasError && state.error != null) ...[
          const SizedBox(height: 12),
          Text(
            state.error!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            CcButton(
              onPressed: onBack,
              variant: CcButtonVariant.secondary,
              child: Text(l10n.back),
            ),
            const Spacer(),
            if (isDownloading)
              CcButton(
                onPressed: notifier.cancel,
                variant: CcButtonVariant.secondary,
                child: Text(l10n.cancel),
              )
            else if (isInstalled)
              CcButton(
                onPressed: onFinish,
                child: Text(l10n.finish),
              )
            else ...[
              CcButton(
                onPressed: onFinish,
                variant: CcButtonVariant.secondary,
                child: Text(l10n.skipForNow),
              ),
              const SizedBox(width: 8),
              CcButton(
                onPressed: notifier.installIfNeeded,
                child: Text(l10n.download),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Optional speaker-diarization model download surfaced on the final
/// onboarding step. It is intentionally additive and never gates Finish/Skip:
/// the user can install it now or later from Settings → Advanced.
class _DiarizationOptionalBlock extends ConsumerWidget {
  const _DiarizationOptionalBlock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(diarizationModelStateProvider);
    final notifier = ref.read(diarizationModelStateProvider.notifier);
    final theme = Theme.of(context);
    final tokens = context.designSystem;
    final l10n = AppLocalizations.of(context);

    final isInstalled = state.status == DiarizationModelStatus.installed;
    final isDownloading = state.status == DiarizationModelStatus.downloading;
    final hasError = state.status == DiarizationModelStatus.error;

    final accent = theme.colorScheme.primary;

    final status = switch (state.status) {
      DiarizationModelStatus.installed => l10n.diarizationInstalled,
      DiarizationModelStatus.downloading =>
        l10n.downloadingModel((state.progress * 100).round()),
      DiarizationModelStatus.error =>
        l10n.diarizationInstallFailed(state.error ?? 'unknown error'),
      DiarizationModelStatus.notInstalled => l10n.diarizationNotInstalled,
      DiarizationModelStatus.unknown => l10n.checkingEllipsis,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isInstalled
                  ? AppIcons.circleCheck
                  : (isDownloading
                      ? AppIcons.download
                      : AppIcons.users),
              size: 18,
              color: isInstalled ? accent : tokens?.textTertiary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.onboardingDiarizationTitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: tokens?.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.onboardingDiarizationSubtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tokens?.textTertiary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    status,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: hasError
                          ? theme.colorScheme.error
                          : tokens?.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (isDownloading)
              CcButton(
                onPressed: notifier.cancel,
                variant: CcButtonVariant.secondary,
                child: Text(l10n.cancel),
              )
            else if (!isInstalled)
              CcButton(
                onPressed: notifier.installIfNeeded,
                variant: CcButtonVariant.secondary,
                child: Text(l10n.download),
              ),
          ],
        ),
        if (isDownloading) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: state.progress > 0
                ? CcProgressBar(value: state.progress)
                : const CcProgressBar(),
          ),
        ],
      ],
    );
  }
}
