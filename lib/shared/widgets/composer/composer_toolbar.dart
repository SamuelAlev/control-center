import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/composer/voice/voice_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// The composer's bottom row: host widgets at the start, then expand, attach,
/// dictate and send (or stop) at the end.
class ComposerToolbar extends StatelessWidget {
  /// Creates a [ComposerToolbar].
  const ComposerToolbar({
    super.key,
    required this.leading,
    required this.trailing,
    required this.sending,
    required this.canSend,
    required this.showStop,
    required this.onStop,
    required this.enableFilePicker,
    required this.onPickFiles,
    required this.onSubmit,
    required this.blockedMessage,
    required this.composerFocused,
    required this.onDictationPartial,
    required this.expanded,
    required this.onToggleExpanded,
  });

  /// Host widgets before the spacer (mode picker, enforcement badge).
  final Widget? leading;

  /// Host widget just before the built-in actions.
  final Widget? trailing;

  /// A submit is in flight; the send button shows a spinner.
  final bool sending;

  /// The draft holds something to send. Without it the send button rests
  /// disabled, so the strongest fill in the box only appears once pressing it
  /// would do something.
  final bool canSend;

  /// Replace send with stop (an agent is working and the draft is empty).
  final bool showStop;

  /// Stops the running agent.
  final Future<void> Function()? onStop;

  /// Whether the attach button is offered.
  final bool enableFilePicker;

  /// Opens the file picker.
  final VoidCallback onPickFiles;

  /// Sends the draft.
  final VoidCallback onSubmit;

  /// Why sending is blocked (uploads pending or failed), shown as the send
  /// button's tooltip. Null when nothing blocks it.
  final String? blockedMessage;

  /// Forwarded to dictation, which only listens while the field is focused.
  final bool composerFocused;

  /// Receives dictation partials and finals.
  final void Function(String text, {required bool isFinal}) onDictationPartial;

  /// The composer currently fills its pane.
  final bool expanded;

  /// Toggles [expanded]; null hides the button (the host does not support an
  /// expanded composer, or the draft is too short to need one).
  final VoidCallback? onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sendButton = CcButton(
      onPressed: sending || blockedMessage != null || !canSend
          ? null
          : onSubmit,
      semanticLabel: l10n.sendMessage,
      child: sending
          ? const CcSpinner(size: 14)
          : const Icon(AppIcons.arrowUp, size: 16),
    );
    final shortcut = defaultTargetPlatform == TargetPlatform.macOS
        ? '${CcKeys.cmdOrCtrl}${CcKeys.shift}E'
        : '${CcKeys.cmdOrCtrl}+${CcKeys.shift}+E';
    final toggle = onToggleExpanded;
    return Row(
      children: [
        ?leading,
        const Spacer(),
        if (trailing != null) ...[trailing!, const SizedBox(width: 6)],
        if (toggle != null)
          CcIconButton(
            icon: expanded ? AppIcons.minimize2 : AppIcons.maximize2,
            onPressed: toggle,
            tooltip: expanded
                ? l10n.composerCollapse(shortcut)
                : l10n.composerExpand(shortcut),
          ),
        if (enableFilePicker)
          CcIconButton(
            icon: AppIcons.plus,
            onPressed: onPickFiles,
            // Names the drag-and-drop affordance too. A drop target that only
            // announces itself once a drag is already in flight is one nobody
            // discovers on a quiet screen.
            tooltip: l10n.attachFilesOrDrop,
          ),
        VoiceButton(
          onPartial: onDictationPartial,
          composerFocused: composerFocused,
        ),
        const SizedBox(width: 6),
        if (showStop)
          CcTooltip(
            message: l10n.stopAgent,
            child: CcButton(
              variant: CcButtonVariant.destructive,
              onPressed: onStop,
              child: const Icon(AppIcons.square, size: 14),
            ),
          )
        else if (blockedMessage != null)
          CcTooltip(message: blockedMessage!, child: sendButton)
        else
          sendButton,
      ],
    );
  }
}
