import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/soundscape/presentation/screens/soundscape_panel.dart';
import 'package:control_center/features/soundscape/providers/soundscape_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global-sidebar footer entry to the soundscape panel. The brand accent
/// reports live playback.
class SoundscapeSidebarEntry extends ConsumerWidget
    implements CcFluidHoverTarget {
  /// Creates a [SoundscapeSidebarEntry].
  const SoundscapeSidebarEntry({super.key});

  @override
  bool get fluidHoverEnabled => true;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playing = ref.watch(soundscapeProvider.select((s) => s.playing));
    final accent = context.designSystem?.accent;
    return CcSidebarItem(
      icon: AppIcons.volume2,
      label: AppLocalizations.of(context).soundscapeTitle,
      iconBuilder: playing
          ? (_, size) => Icon(AppIcons.audioLines, size: size, color: accent)
          : null,
      onPressed: () => showSoundscapePanel(context),
    );
  }
}
