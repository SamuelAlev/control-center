import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/soundscape/providers/soundscape_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 2D tune pad: drag the puck to shape the running mix.
///
/// X runs mellow (left) to energetic (right) — melodic density, neural-AM
/// depth, gusts; Y runs spacy (bottom) to bright (top) — reverb space traded
/// against filter openness. The puck follows the pointer immediately while
/// the provider debounces the server push; the audio glides over ~1.5 s, so
/// dragging feels live but never clicks. Double-tap resets to the neutral
/// center. Keyboard-first: focus the pad and nudge with the arrow keys.
class SoundscapeTunePad extends ConsumerStatefulWidget {
  /// Creates a [SoundscapeTunePad].
  const SoundscapeTunePad({super.key});

  @override
  ConsumerState<SoundscapeTunePad> createState() => _SoundscapeTunePadState();
}

class _SoundscapeTunePadState extends ConsumerState<SoundscapeTunePad> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'SoundscapeTunePad');

  /// Arrow-key nudge per press.
  static const double _keyStep = 0.05;

  static const double _puckSize = 18.0;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _setFromLocal(Offset local, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }
    ref
        .read(soundscapeProvider.notifier)
        .setTune(
          energy: local.dx / size.width,
          brightness: 1.0 - local.dy / size.height,
        );
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) {
      return KeyEventResult.ignored;
    }
    final state = ref.read(soundscapeProvider);
    final controller = ref.read(soundscapeProvider.notifier);
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        controller.setTune(
          energy: state.tuneEnergy - _keyStep,
          brightness: state.tuneBrightness,
        );
      case LogicalKeyboardKey.arrowRight:
        controller.setTune(
          energy: state.tuneEnergy + _keyStep,
          brightness: state.tuneBrightness,
        );
      case LogicalKeyboardKey.arrowUp:
        controller.setTune(
          energy: state.tuneEnergy,
          brightness: state.tuneBrightness + _keyStep,
        );
      case LogicalKeyboardKey.arrowDown:
        controller.setTune(
          energy: state.tuneEnergy,
          brightness: state.tuneBrightness - _keyStep,
        );
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final state = ref.watch(soundscapeProvider);
    final controller = ref.read(soundscapeProvider.notifier);
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final labelStyle = CcTypography.caption.copyWith(
      color: t.textTertiary,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.2,
    );

    return Semantics(
      label: l10n.soundscapeTuneLabel,
      value:
          '${l10n.soundscapeTuneEnergetic} ${(state.tuneEnergy * 100).round()}%, '
          '${l10n.soundscapeTuneBright} ${(state.tuneBrightness * 100).round()}%',
      child: FocusRing(
        focusNode: _focusNode,
        borderRadius: AppRadii.brMd,
        child: Focus(
          focusNode: _focusNode,
          onKeyEvent: _onKeyEvent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: AspectRatio(
              aspectRatio: 1.0,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = constraints.biggest;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (d) {
                      _focusNode.requestFocus();
                      _setFromLocal(d.localPosition, size);
                    },
                    onPanStart: (d) {
                      _focusNode.requestFocus();
                      _setFromLocal(d.localPosition, size);
                    },
                    onPanUpdate: (d) => _setFromLocal(d.localPosition, size),
                    onDoubleTap: () =>
                        controller.setTune(energy: 0.5, brightness: 0.5),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: t.bgSecondary,
                        borderRadius: AppRadii.brMd,
                        // The frame + crosshair are the coordinate grid, so they
                        // must read — but quietly. Derived from `fg` (adapts per
                        // theme) at ~22%: clearly visible on the dark pad (~2:1)
                        // without the heaviness of a full 3:1 line, and a step up
                        // from the near-invisible `borderSecondary` hairline.
                        border: Border.all(color: t.fg.withValues(alpha: 0.22)),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Center guides — subtler than the frame.
                          Align(
                            child: Container(
                              width: 1,
                              height: double.infinity,
                              color: t.fg.withValues(alpha: 0.13),
                            ),
                          ),
                          Align(
                            child: Container(
                              height: 1,
                              width: double.infinity,
                              color: t.fg.withValues(alpha: 0.13),
                            ),
                          ),
                          // Edge labels: bright / spacy / mellow / energetic.
                          Align(
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                l10n.soundscapeTuneBright.toUpperCase(),
                                style: labelStyle,
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                l10n.soundscapeTuneSpacy.toUpperCase(),
                                style: labelStyle,
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: RotatedBox(
                                quarterTurns: 3,
                                child: Text(
                                  l10n.soundscapeTuneMellow.toUpperCase(),
                                  style: labelStyle,
                                ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: RotatedBox(
                                quarterTurns: 1,
                                child: Text(
                                  l10n.soundscapeTuneEnergetic.toUpperCase(),
                                  style: labelStyle,
                                ),
                              ),
                            ),
                          ),
                          // The puck.
                          AnimatedAlign(
                            alignment: FractionalOffset(
                              state.tuneEnergy,
                              1.0 - state.tuneBrightness,
                            ),
                            duration: reducedMotion
                                ? Duration.zero
                                : const Duration(milliseconds: 120),
                            curve: Curves.easeOut,
                            child: Container(
                              width: _puckSize,
                              height: _puckSize,
                              decoration: BoxDecoration(
                                color: t.accent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: t.bgPrimary,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: t.accent.withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
