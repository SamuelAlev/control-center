import 'dart:async';

import 'package:cc_domain/features/settings/domain/model_control.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/constants/keybindings.dart';
import 'package:control_center/core/infrastructure/speech/dictation_controller.dart';
import 'package:control_center/core/infrastructure/speech/voice_model_control.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The command id of the push-to-talk keybinding (registered in
/// [KeybindingRegistry.messaging], owned by this widget's own hardware-keyboard
/// handler — no central dispatcher handler, so the dispatcher never consumes it).
const String dictationPushToTalkCommandId = 'dictation.pushToTalk';

/// Composer mic button — server-backed streaming dictation (PRD 25 §2).
/// The button is enabled ONLY when the connected server reports an installed voice model;
/// otherwise it is disabled with a "set up a voice model" tooltip.
/// The keyboard shortcut is the [dictationPushToTalkCommandId] chord; it is handled here
/// (only while the owning composer is focused) rather than the central dispatcher so it can
/// observe key-up for hold mode and `preventDefault` the browser on web.
class VoiceButton extends ConsumerStatefulWidget {
  /// Creates a [VoiceButton].
  const VoiceButton({
    super.key,
    required this.onPartial,
    required this.composerFocused,
  });

  /// Forwards the accumulated dictation transcript to the composer. `isFinal`
  /// marks the session's terminal update (commit the pending span).
  final void Function(String text, {required bool isFinal}) onPartial;

  /// Whether the owning composer's text field is focused — gates the keyboard
  /// push-to-talk shortcut so only the active composer reacts.
  final bool composerFocused;

  @override
  ConsumerState<VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends ConsumerState<VoiceButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  /// This button started the currently-live session (so only it forwards that
  /// session's partials — a second composer's button stays quiet).
  bool _sessionActive = false;

  /// A keyboard hold-to-talk is in progress (started on key-down; ended on the
  /// trigger's key-up).
  bool _keyboardHold = false;

  /// A pointer hold-to-talk is in progress (started on pointer-down; ended on
  /// pointer-up / cancel).
  bool _pointerHold = false;

  /// The press now completing came from a pointer, whose down/up already
  /// started and stopped a hold session; the tap that follows must not toggle
  /// it again. Cleared once that pointer's events have been dispatched.
  bool _pointerPress = false;

  /// This button asked for a session that has not reported back yet, so the
  /// phase changes it causes are its own to announce.
  bool _starting = false;

  // Derived in build() for the hardware-key handler, which runs outside build.
  bool _enabled = false;
  bool _holdMode = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    HardwareKeyboard.instance.addHandler(_onHardwareKey);
  }

  @override
  void didUpdateWidget(covariant VoiceButton old) {
    super.didUpdateWidget(old);
    // Losing composer focus mid-hold (e.g. clicking elsewhere) must stop the
    // keyboard hold — its key-up may never reach us once focus moves.
    if (!widget.composerFocused && _keyboardHold) {
      _keyboardHold = false;
      unawaited(_stop());
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onHardwareKey);
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    _starting = true;
    final bool started;
    try {
      started = await ref.read(dictationControllerProvider.notifier).start();
    } finally {
      _starting = false;
    }
    if (!started || !mounted) {
      return;
    }
    setState(() => _sessionActive = true);
    // Pin the composer's pending-span anchor at the current caret immediately;
    // real windows replace this empty text as they arrive.
    widget.onPartial('', isFinal: false);
  }

  Future<void> _stop() async {
    if (!_sessionActive) {
      return;
    }
    final finalText = await ref
        .read(dictationControllerProvider.notifier)
        .stopAndDrain();
    widget.onPartial(finalText, isFinal: true);
    if (mounted) {
      setState(() => _sessionActive = false);
    } else {
      _sessionActive = false;
    }
  }

  Future<void> _toggle() async {
    if (_sessionActive) {
      await _stop();
    } else {
      await _start();
    }
  }

  void _onPointerDown(PointerDownEvent _) {
    if (!_enabled) {
      return;
    }
    if (_holdMode) {
      _pointerHold = true;
      _pointerPress = true;
      unawaited(_start());
    }
  }

  void _onPointerUp(PointerUpEvent _) {
    if (_pointerHold) {
      _pointerHold = false;
      unawaited(_stop());
    }
    // The button's tap fires later in this same dispatch, after this
    // listener; a microtask runs once that dispatch has finished.
    scheduleMicrotask(() => _pointerPress = false);
  }

  void _onPointerCancel(PointerCancelEvent _) {
    _pointerPress = false;
    if (_holdMode && _pointerHold) {
      _pointerHold = false;
      unawaited(_stop());
    }
  }

  /// A press that is not a pointer's (a screen reader's activate, Enter or
  /// Space on the focused button) cannot hold, so in hold mode it toggles.
  void _onHoldModePressed() {
    if (_pointerPress) {
      return;
    }
    unawaited(_toggle());
  }

  void _announce(String message) {
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        Directionality.of(context),
      ),
    );
  }

  /// Says a session starting, or failing to, out loud: the only other sign is
  /// the button's colour and tooltip.
  void _announcePhase(
    AppLocalizations l10n,
    DictationState? prev,
    DictationState next,
  ) {
    if (prev?.phase == next.phase) {
      return;
    }
    if (next.isListening) {
      _announce(l10n.dictationListening);
    } else if (next.hasError) {
      _announce(switch (next.errorKind) {
        DictationErrorKind.micDenied => l10n.microphonePermissionDenied,
        _ => l10n.dictationFailedToStart,
      });
    }
  }

  // The dot pulses only while it is shown, and holds still at full strength
  // when motion is reduced.
  void _syncPulse({required bool listening}) {
    if (!listening) {
      if (_pulse.isAnimating) {
        _pulse.stop();
      }
      return;
    }
    if (CcMotion.reduced(context)) {
      _pulse
        ..stop()
        ..value = 1;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  bool _onHardwareKey(KeyEvent event) {
    if (!_enabled || !widget.composerFocused) {
      return false;
    }
    final binding = KeybindingRegistry.find(dictationPushToTalkCommandId);
    if (binding == null || event.logicalKey != binding.key) {
      return false;
    }

    // Key-up ends a hold session (best-effort; macOS can drop a non-modifier
    // key's up event while ⌘ is held — the reason toggle is the default mode).
    if (event is KeyUpEvent) {
      if (_holdMode && _keyboardHold) {
        _keyboardHold = false;
        unawaited(_stop());
        return true;
      }
      return false;
    }

    if (!_chordModifiersMatch(binding)) {
      return false;
    }

    // Swallow ordinary auto-repeat of the chord (holding must not machine-gun).
    // On macOS a command-modified "repeat" is really a fresh press (Flutter
    // #136419), so it counts as a new press for toggle.
    final isMac = defaultTargetPlatform == TargetPlatform.macOS;
    final isMacFreshPress =
        event is KeyRepeatEvent &&
        isMac &&
        (binding.meta || binding.control || binding.alt);
    if (event is KeyRepeatEvent && !isMacFreshPress) {
      return true;
    }

    if (_holdMode) {
      if (!_sessionActive) {
        _keyboardHold = true;
        unawaited(_start());
      }
      return true;
    }
    unawaited(_toggle());
    return true;
  }

  /// Whether the modifiers currently held match [binding], resolving the
  /// primary command modifier the same way the keybinding layer does (⌘ on
  /// macOS, Ctrl elsewhere).
  bool _chordModifiersMatch(Keybinding binding) {
    final kb = HardwareKeyboard.instance;
    final isMac = defaultTargetPlatform == TargetPlatform.macOS;
    final cmdHeld = isMac ? kb.isMetaPressed : kb.isControlPressed;
    if (binding.meta != cmdHeld) {
      return false;
    }
    if (binding.shift != kb.isShiftPressed) {
      return false;
    }
    if (binding.alt != kb.isAltPressed) {
      return false;
    }
    // Literal Ctrl only applies on macOS (elsewhere Ctrl is the command modifier).
    if (isMac && binding.control && !kb.isControlPressed) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final status = ref.watch(voiceModelStatusSnapshotProvider).asData?.value;
    _enabled = status?.status == ModelLifecycleStatus.installed;
    _holdMode = ref.watch(dictationHoldToTalkProvider);
    final dictation = ref.watch(dictationControllerProvider);

    // Side-effect: forward this session's finalized-window updates to the
    // composer while listening; reset ownership when it ends elsewhere (e.g.
    // the composer force-finalized on send).
    ref.listen<DictationState>(dictationControllerProvider, (prev, next) {
      if (_sessionActive || _starting) {
        _announcePhase(l10n, prev, next);
      }
      if (!_sessionActive) {
        return;
      }
      if (next.phase == DictationPhase.listening) {
        if (next.transcript != (prev?.transcript ?? '')) {
          widget.onPartial(next.transcript, isFinal: false);
        }
      } else {
        // idle or error: the session ended without this button stopping it.
        setState(() => _sessionActive = false);
        _keyboardHold = false;
        _pointerHold = false;
      }
    });

    final listening = _sessionActive && dictation.isListening;
    _syncPulse(listening: listening);
    final Color? color;
    final String tooltip;
    if (!_enabled) {
      color = null;
      tooltip = l10n.dictationUnavailable;
    } else if (dictation.hasError) {
      color = ds.textErrorPrimary;
      tooltip = switch (dictation.errorKind) {
        DictationErrorKind.micDenied => l10n.microphonePermissionDenied,
        _ => l10n.dictationFailedToStart,
      };
    } else if (listening) {
      color = ds.textErrorPrimary;
      tooltip = l10n.dictationListening;
    } else {
      color = null;
      tooltip = _holdMode ? l10n.dictationHoldToTalkTitle : l10n.dictationStart;
    }

    // Hold-to-talk needs pointer-down/up, which a tap callback cannot see, so
    // the pointer handlers observe raw events around the button. In hold mode
    // a pointer's tap is a no-op (the Listener already started/stopped); any
    // other activation toggles.
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CcIconButton(
            icon: AppIcons.mic,
            onPressed: !_enabled
                ? null
                : _holdMode
                ? _onHoldModePressed
                : () => unawaited(_toggle()),
            color: color,
            tooltip: tooltip,
          ),
          if (listening)
            PositionedDirectional(
              top: 7,
              end: 7,
              // Decoration: the button's tooltip already says "listening".
              child: ExcludeSemantics(
                child: IgnorePointer(
                  child: FadeTransition(
                    opacity: _pulse,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: ds.textErrorPrimary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
