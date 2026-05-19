import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_detection_controller.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_recorder_controller.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_theme.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// A banner offered when automatic detection thinks a meeting is underway:
/// "Looks like '<title>' is happening — record it?" with Record / Dismiss.
/// Renders nothing unless the controller is prompting.
class MeetingDetectionBanner extends ConsumerWidget {
  /// Creates a [MeetingDetectionBanner].
  const MeetingDetectionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detection = ref.watch(meetingDetectionControllerProvider);
    if (!detection.showPrompt) {
      return const SizedBox.shrink();
    }
    final ds = context.ds;
    final l10n = AppLocalizations.of(context);
    final label = detection.candidate?.label;

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.lg),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: ds.accentSoft,
        borderRadius: AppRadii.brMd,
        border: Border.all(color: ds.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(AppIcons.radio, size: 18, color: ds.accent),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.meetingDetectedTitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ds.fg,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label == null || label.isEmpty
                      ? l10n.meetingDetectedSubtitleGeneric
                      : l10n.meetingDetectedSubtitle(label),
                  style: TextStyle(fontSize: 12, color: ds.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          CcButton(
            variant: CcButtonVariant.ghost,
            size: CcButtonSize.sm,
            onPressed: () =>
                ref.read(meetingDetectionControllerProvider.notifier).dismiss(),
            child: Text(l10n.meetingDetectedDismiss),
          ),
          const SizedBox(width: AppSpacing.sm),
          CcButton(
            size: CcButtonSize.sm,
            icon: AppIcons.circleDot,
            onPressed: () => _record(context, ref, label),
            child: Text(l10n.meetingDetectedRecord),
          ),
        ],
      ),
    );
  }

  Future<void> _record(
    BuildContext context,
    WidgetRef ref,
    String? title,
  ) async {
    final toaster = CcToastScope.of(context);
    final router = GoRouter.of(context);
    final ws = context.currentWorkspaceId!;
    final detection = ref.read(meetingDetectionControllerProvider.notifier);
    final recorder = ref.read(meetingRecorderControllerProvider.notifier);

    await recorder.start(title: title);
    final state = ref.read(meetingRecorderControllerProvider);
    if (state.isRecording) {
      detection.accept();
      router.go(meetingsRecordRoute(ws));
    } else if (state.error != null) {
      toaster.show(state.error!, variant: CcToastVariant.danger);
    }
  }
}
