import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/soundscape/presentation/widgets/soundscape_controls.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

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
class SoundscapePanel extends StatelessWidget {
  /// Creates a [SoundscapePanel].
  const SoundscapePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return CcDialog(
      maxWidth: 440,
      title: AppLocalizations.of(context).soundscapeTitle,
      content: const SizedBox(width: 420, child: SoundscapeControls()),
    );
  }
}
