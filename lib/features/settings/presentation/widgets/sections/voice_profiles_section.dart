import 'package:cc_domain/features/meetings/domain/entities/voice_profile.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/meetings/providers/meeting_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings section that manages persistent, cross-meeting voice profiles: the
/// named voiceprints used to auto-recognize a speaker in future meetings.
/// Profiles are created from the meeting transcript ("Save voice profile" after
/// naming a speaker); here the user can rename or delete them.
class VoiceProfilesSection extends ConsumerWidget {
  /// Creates a [VoiceProfilesSection].
  const VoiceProfilesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem;
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final profiles = workspaceId == null
        ? const AsyncValue<List<VoiceProfile>>.data([])
        : ref.watch(voiceProfilesProvider(workspaceId));

    return SectionCard(
      label: l10n.voiceProfilesSection,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.voiceProfilesDescription,
            style: TextStyle(fontSize: 12.5, color: tokens?.textTertiary),
          ),
          const SizedBox(height: 12),
          profiles.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CcProgressBar()),
            ),
            error: (_, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                l10n.voiceProfilesEmpty,
                style: TextStyle(fontSize: 13, color: tokens?.textTertiary),
              ),
            ),
            data: (list) {
              if (list.isEmpty || workspaceId == null) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    l10n.voiceProfilesEmpty,
                    style: TextStyle(fontSize: 13, color: tokens?.textTertiary),
                  ),
                );
              }
              return Column(
                children: [
                  for (final profile in list)
                    _ProfileRow(workspaceId: workspaceId, profile: profile),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends ConsumerWidget {
  const _ProfileRow({required this.workspaceId, required this.profile});

  final String workspaceId;
  final VoiceProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(AppIcons.userRound, size: 18, color: tokens?.fgTertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: tokens?.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.voiceProfileSamples(profile.sampleCount),
                  style: TextStyle(fontSize: 12, color: tokens?.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CcButton(
            variant: CcButtonVariant.ghost,
            size: CcButtonSize.sm,
            onPressed: () => _rename(context, ref),
            child: Text(l10n.rename),
          ),
          const SizedBox(width: 4),
          CcButton(
            variant: CcButtonVariant.ghost,
            size: CcButtonSize.sm,
            onPressed: () => _delete(context, ref),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final newName = await showCcDialog<String>(
      context: context,
      builder: (_) => _RenameProfileDialog(currentName: profile.displayName),
    );
    final trimmed = newName?.trim() ?? '';
    if (trimmed.isEmpty || trimmed == profile.displayName) {
      return;
    }
    await ref.read(voiceProfileRepositoryProvider).rename(
          workspaceId: workspaceId,
          id: profile.id,
          displayName: trimmed,
        );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showCcDialog<bool>(
      context: context,
      builder: (dialogContext) => CcDialog(
        title: l10n.deleteVoiceProfileTitle,
        content: Text(l10n.deleteVoiceProfileBody(profile.displayName)),
        actions: [
          CcButton(
            variant: CcButtonVariant.secondary,
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          CcButton(
            variant: CcButtonVariant.destructive,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok != true) {
      return;
    }
    await ref
        .read(voiceProfileRepositoryProvider)
        .delete(workspaceId, profile.id);
  }
}

/// A small text dialog to rename a voice profile. Returns the entered text on
/// confirm, or null on cancel.
class _RenameProfileDialog extends StatefulWidget {
  const _RenameProfileDialog({required this.currentName});

  final String currentName;

  @override
  State<_RenameProfileDialog> createState() => _RenameProfileDialogState();
}

class _RenameProfileDialogState extends State<_RenameProfileDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.currentName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CcDialog(
      title: l10n.renameVoiceProfileTitle,
      maxWidth: 420,
      content: SizedBox(
        width: 380,
        child: CcTextField(
          controller: _controller,
          autofocus: true,
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.secondary,
          size: CcButtonSize.sm,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        CcButton(
          size: CcButtonSize.sm,
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
