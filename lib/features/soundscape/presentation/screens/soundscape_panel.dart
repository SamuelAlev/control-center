import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/soundscape/presentation/notifiers/soundscape_mini_player_controller.dart';
import 'package:control_center/features/soundscape/presentation/widgets/soundscape_controls.dart';
import 'package:control_center/features/soundscape/providers/soundscape_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows the soundscape control panel in a [CcDialog].
Future<void> showSoundscapePanel(BuildContext context) {
  return showCcDialog<void>(
    context: context,
    builder: (_) => const SoundscapePanel(),
  );
}

/// The soundscape control-panel dialog. A thin shell around
/// [SoundscapeControls]; the server owns generation, this only drives playback
/// preferences. Present it with [showSoundscapePanel].
class SoundscapePanel extends ConsumerWidget {
  /// Creates a [SoundscapePanel].
  const SoundscapePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final playing = ref.watch(soundscapeProvider.select((s) => s.playing));
    return CcDialog(
      maxWidth: 440,
      title: l10n.soundscapeTitle,
      content: const SizedBox(width: 420, child: SoundscapeControls()),
      actions: [
        if (playing)
          CcButton(
            variant: CcButtonVariant.ghost,
            size: CcButtonSize.sm,
            icon: AppIcons.pictureInPicture2,
            onPressed: () {
              ref.read(soundscapeMiniPlayerControllerProvider.notifier).open();
              Navigator.of(context).pop();
            },
            child: Text(l10n.soundscapePopOut),
          ),
      ],
    );
  }
}
