// Onboarding step for the connected server's on-device voice model.
//
// The desktop and web are both thin clients: neither hosts a model itself —
// this step drives the connected `cc_server`'s model lifecycle over the
// `models.voice*` RPC ops (the same seam the Settings sections use), so the
// same widgets render identically on both platforms. The embedding and
// diarization models need no step of their own: the server force-installs them
// at boot.
//
// The server force-installs the SELECTED voice model at boot too, so by the
// time anyone reaches this step it is usually already downloading. The step is
// still worth walking: it is where the model is CHOSEN (a different pick
// supersedes the boot download) and where the transfer's progress is visible
// rather than silent. Its install button stays because a boot download can
// fail — `install()` is a no-op while one is in flight or already installed.
library;

import 'package:cc_domain/features/settings/domain/model_control.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/infrastructure/speech/voice_model_control.dart';
import 'package:control_center/features/auth/presentation/widgets/onboarding_step_layout.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/audio_input_row.dart'
    show AudioInputRow;
import 'package:control_center/features/settings/presentation/widgets/sections/system/audio_output_row.dart'
    show AudioOutputRow;
import 'package:control_center/features/settings/presentation/widgets/sections/system/voice_section_extras.dart'
    show VoiceModelPicker;
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/inline_load_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Onboarding step: install the server's voice (speech-to-text) model.
/// This is the final step; [onFinish] completes onboarding.
class OnboardingVoiceStep extends ConsumerWidget {
  /// Creates the voice onboarding step.
  const OnboardingVoiceStep({
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
    final statusAsync = ref.watch(voiceModelStatusSnapshotProvider);
    final l10n = AppLocalizations.of(context);

    return statusAsync.when(
      loading: () =>
          const OnboardingStepLayout(content: Center(child: CcSpinner())),
      error: (e, _) =>
          OnboardingStepLayout(content: InlineLoadError(e, center: false)),
      data: (status) {
        if (status == null) {
          return _ServerManagedPlaceholder(onBack: onBack, onForward: onFinish);
        }
        final control = ref.watch(voiceModelControlProvider);
        final theme = Theme.of(context);
        final tokens = context.designSystem;
        final isInstalled = status.status == ModelLifecycleStatus.installed;
        final isDownloading = status.status == ModelLifecycleStatus.downloading;
        final hasError = status.status == ModelLifecycleStatus.error;

        return OnboardingStepLayout(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Selectable DURING a download, not just when idle. The server
              // force-installs the selected model at boot, so on a slow link
              // this step is reached mid-transfer — disabling the picker then
              // meant the one screen for choosing a model never offered the
              // choice. Picking another supersedes the in-flight fetch
              // server-side (`select` cancels it and rebuilds the control).
              const VoiceModelPicker(enabled: true),
              const SizedBox(height: 16),
              Row(
                children: [
                  // A failed boot download reads as "never started" without its
                  // own glyph — the row would say "not installed" beside the
                  // same mic icon an untouched install shows, and the two need
                  // different actions (wait vs retry).
                  Icon(
                    isInstalled
                        ? AppIcons.circleCheck
                        : isDownloading
                        ? AppIcons.download
                        : hasError
                        ? AppIcons.alertTriangle
                        : AppIcons.mic,
                    size: 18,
                    color: isInstalled
                        ? theme.colorScheme.primary
                        : hasError
                        ? theme.colorScheme.error
                        : tokens?.textTertiary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isInstalled
                          ? l10n.voiceModelInstalled
                          : (isDownloading
                                ? (status.phase == 'extracting'
                                      ? l10n.extractingModel(
                                          (status.progress * 100).round(),
                                        )
                                      : l10n.downloadingModel(
                                          (status.progress * 100).round(),
                                        ))
                                : l10n.voiceModelNotInstalledLabel),
                      style: CcTypography.body.copyWith(
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
                  child: status.progress > 0
                      ? CcProgressBar(value: status.progress)
                      : const CcProgressBar(),
                ),
              ],
              if (hasError && status.error != null) ...[
                const SizedBox(height: 12),
                Text(
                  status.error!,
                  style: CcTypography.caption.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const AudioInputRow(),
              // Output has no picker on web (the browser routes audio), so the
              // row hides itself there rather than showing an inert select.
              if (AudioOutputRow.isSupported) ...[
                const SizedBox(height: 8),
                AudioOutputRow(title: l10n.audioOutput),
              ],
            ],
          ),
          footer: Row(
            children: [
              CcButton(
                onPressed: onBack,
                variant: CcButtonVariant.secondary,
                child: Text(l10n.back),
              ),
              const Spacer(),
              // A download must never trap someone on this step. The transfer
              // is the SERVER's — it started at boot and keeps running whatever
              // this client does — so "continue" is the primary action and the
              // model finishes arriving behind the rest of onboarding. Cancel
              // stays for anyone who does not want the ~600 MB at all. Without
              // the continue button a slow link left Back and Cancel as the
              // only ways off the final step.
              if (isDownloading) ...[
                CcButton(
                  onPressed: control.cancel,
                  variant: CcButtonVariant.secondary,
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 8),
                CcButton(onPressed: onFinish, child: Text(l10n.continueLabel)),
              ] else if (isInstalled)
                CcButton(onPressed: onFinish, child: Text(l10n.finish))
              else ...[
                CcButton(
                  onPressed: onFinish,
                  variant: CcButtonVariant.secondary,
                  child: Text(l10n.skipForNow),
                ),
                const SizedBox(width: 8),
                CcButton(
                  onPressed: control.install,
                  child: Text(l10n.download),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Shown when the connected server hosts no model control for this surface
/// (an older/headless server with no model lifecycle ops). Lets the user
/// continue past the step rather than blocking onboarding on it.
class _ServerManagedPlaceholder extends StatelessWidget {
  const _ServerManagedPlaceholder({
    required this.onBack,
    required this.onForward,
  });

  final VoidCallback onBack;
  final VoidCallback onForward;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    final l10n = AppLocalizations.of(context);
    return OnboardingStepLayout(
      content: Text(
        l10n.modelManagedOnServer,
        style: CcTypography.body.copyWith(
          color: tokens?.textPrimary,
          height: 1.5,
        ),
      ),
      footer: Row(
        children: [
          CcButton(
            onPressed: onBack,
            variant: CcButtonVariant.secondary,
            child: Text(l10n.back),
          ),
          const Spacer(),
          CcButton(onPressed: onForward, child: Text(l10n.finish)),
        ],
      ),
    );
  }
}
