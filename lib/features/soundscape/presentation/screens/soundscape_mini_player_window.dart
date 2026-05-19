// Uses Flutter's experimental windowing API (unlocked via the `windowing`
// feature flag). Confined to the window wrapper; the UI below is ordinary.
// ignore_for_file: invalid_use_of_internal_member, implementation_imports

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/app/window_chrome.dart';
import 'package:control_center/core/providers/locale_provider.dart';
import 'package:control_center/features/soundscape/presentation/notifiers/soundscape_mini_player_controller.dart';
import 'package:control_center/features/soundscape/providers/soundscape_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/window_drag_area.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/_window.dart'
    show Window, WindowController;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Design-system dark tokens, read directly: the mini-player renders in a bare,
/// frameless window with no [Theme]. Like the focus pill and meeting toolbar, it
/// floats over arbitrary desktop content and commits to the dark surface.
final _t = DesignSystemTokens.dark();

/// The floating soundscape mini-player window. A sibling window in the main
/// isolate, so it reads [soundscapeProvider] / [soundscapeSceneProvider]
/// directly — no cross-engine IPC. Shown / hidden by `AppWindows` as
/// [soundscapeMiniPlayerControllerProvider] flips.
class SoundscapeMiniPlayerWindow extends ConsumerStatefulWidget {
  /// Creates the [SoundscapeMiniPlayerWindow].
  const SoundscapeMiniPlayerWindow({super.key});

  @override
  ConsumerState<SoundscapeMiniPlayerWindow> createState() =>
      _SoundscapeMiniPlayerWindowState();
}

class _SoundscapeMiniPlayerWindowState
    extends ConsumerState<SoundscapeMiniPlayerWindow> {
  final WindowController _controller = WindowController(
    size: soundscapeMiniPlayerSize,
    constraints: BoxConstraints.tight(soundscapeMiniPlayerSize),
    title: soundscapeMiniPlayerWindowTitle,
  );

  @override
  void dispose() {
    _controller.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localeCode = ref.watch(localeProvider)?.languageCode;
    return Window(
      controller: _controller,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: localeCode != null ? Locale(localeCode) : null,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // This sibling window must ignore the engine's shared platform route
        // (the main window's deep link), so always render the mini-player.
        onGenerateInitialRoutes: (_) => [
          MaterialPageRoute<void>(builder: (_) => const _MiniPlayerView()),
        ],
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const _MiniPlayerView(),
        ),
      ),
    );
  }
}

class _MiniPlayerView extends ConsumerWidget {
  const _MiniPlayerView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final playing = ref.watch(soundscapeProvider.select((s) => s.playing));
    final mood = ref.watch(soundscapeProvider.select((s) => s.mood));
    final scene = ref.watch(soundscapeSceneProvider).value;
    final sceneName =
        (scene?['name'] as String?) ?? _moodLabel(l10n, mood.name);
    final weather = scene?['weather'] as String?;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: BoxDecoration(color: _t.panel),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(width: 6),
            _HudIconButton(
              icon: playing ? AppIcons.pause : AppIcons.play,
              color: playing ? _t.accent : _t.fg,
              tooltip: playing ? l10n.soundscapePause : l10n.soundscapePlay,
              onTap: () => ref.read(soundscapeProvider.notifier).toggle(),
            ),
            const SizedBox(width: 4),
            Icon(
              weather == 'clear' ? AppIcons.sun : AppIcons.cloud,
              size: 13,
              color: _t.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              // The row stretches its children to full height so the icon and
              // grip stay fully tappable/draggable; centre the label within that
              // height so it doesn't ride against the top edge.
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  sceneName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _t.fg,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ),
            _HudIconButton(
              icon: AppIcons.pictureInPicture2,
              color: _t.idle,
              tooltip: l10n.soundscapeReturnToApp,
              onTap: () => ref
                  .read(soundscapeMiniPlayerControllerProvider.notifier)
                  .close(),
            ),
            // Grip handle — the ONLY draggable region.
            WindowDragArea(
              child: MouseRegion(
                cursor: SystemMouseCursors.grab,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Center(
                    child: Icon(
                      AppIcons.gripVertical,
                      size: 14,
                      color: _t.idle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _moodLabel(AppLocalizations l10n, String mood) => switch (mood) {
    'relax' => l10n.soundscapeMoodRelax,
    'sleep' => l10n.soundscapeMoodSleep,
    _ => l10n.soundscapeMoodFocus,
  };
}

class _HudIconButton extends StatelessWidget {
  const _HudIconButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CcTooltip(
      message: tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Icon(icon, size: 16, color: color),
          ),
        ),
      ),
    );
  }
}
