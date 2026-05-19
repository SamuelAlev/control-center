import 'dart:async';

import 'package:cc_domain/features/settings/domain/model_control.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/constants/keybindings.dart';
import 'package:control_center/core/infrastructure/speech/dictation_controller.dart';
import 'package:control_center/core/infrastructure/speech/voice_model_control.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The command id of the push-to-talk keybinding (registered in
/// [KeybindingRegistry.messaging], owned by this widget's own hardware-keyboard
/// handler — no central dispatcher handler, so the dispatcher never consumes it).
const String dictationPushToTalkCommandId = 'dictation.pushToTalk';

/// Composer mic button — server-backed streaming dictation (PRD 25 §2).
///
/// The client owns no ASR model: pressing the button starts a
/// [DictationController] session that streams the mic to the host and receives
/// finalized transcript windows, which are forwarded to the composer via
/// [onPartial] (the composer applies them as an atomic pending-span
/// replacement). The button is enabled ONLY when the connected server reports
/// an installed voice model; otherwise it is disabled with a "set up a voice
/// model" tooltip.
///
/// Push-to-talk honours the stored [dictationHoldToTalkProvider] preference:
/// HOLD (press/hold the button or the shortcut to dictate, release to stop) or
/// TOGGLE (press once to start, again to stop). The keyboard shortcut is the
/// [dictationPushToTalkCommandId] chord; it is handled here (only while the
/// owning composer is focused) rather than the central dispatcher so it can
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

  // Derived in build() for the hardware-key handler, which runs outside build.
  bool _enabled = false;
  bool _holdMode = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
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
    final started = await ref
        .read(dictationControllerProvider.notifier)
        .start();
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

  // ── Pointer push-to-talk ──────────────────────────────────────────────────

  void _onPointerDown(PointerDownEvent _) {
    if (!_enabled) {
      return;
    }
    if (_holdMode) {
      _pointerHold = true;
      unawaited(_start());
    }
  }

  void _onPointerUp(PointerUpEvent _) {
    if (!_enabled) {
      return;
    }
    if (_holdMode) {
      if (_pointerHold) {
        _pointerHold = false;
        unawaited(_stop());
      }
    } else {
      unawaited(_toggle());
    }
  }

  void _onPointerCancel(PointerCancelEvent _) {
    if (_holdMode && _pointerHold) {
      _pointerHold = false;
      unawaited(_stop());
    }
  }

  // ── Keyboard push-to-talk ─────────────────────────────────────────────────

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

  // ── Build ─────────────────────────────────────────────────────────────────

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
    final Color color;
    final String tooltip;
    if (!_enabled) {
      color = ds.textTertiary;
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
      color = ds.textTertiary;
      tooltip = _holdMode ? l10n.dictationHoldToTalkTitle : l10n.dictationStart;
    }

    return CcTooltip(
      message: tooltip,
      child: MouseRegion(
        cursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _onPointerDown,
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerCancel,
          child: Semantics(
            button: true,
            enabled: _enabled,
            label: tooltip,
            child: SizedBox(
              // 36px box (matching CcIconButton md) around a 16px glyph — a
              // comfortable click/touch target that lines up with its toolbar
              // siblings.
              width: 36,
              height: 36,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(AppIcons.mic, size: 16, color: color),
                  if (listening)
                    Positioned(
                      top: 5,
                      right: 5,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
