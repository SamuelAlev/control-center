import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/attachments.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/widgets/messaging/sent_attachments.dart';
import 'package:cc_remote/widgets/touch_target.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// Composer at the bottom of a space: attach, pending chips, send.
class SpaceComposerBar extends StatelessWidget {
  /// Creates a [SpaceComposerBar].
  const SpaceComposerBar({
    super.key,
    required this.controller,
    required this.sending,
    required this.pending,
    required this.attachError,
    required this.onAttach,
    required this.onSend,
    required this.onRemovePending,
  });

  /// Text field controller.
  final TextEditingController controller;

  /// True while a send is in flight.
  final bool sending;

  /// Files picked but not yet sent.
  final List<PickedAttachment> pending;

  /// Why the last attach or send left something out.
  final String? attachError;

  /// Opens the file picker.
  final VoidCallback onAttach;

  /// Sends the composed message.
  final VoidCallback onSend;

  /// Drops a pending attachment.
  final ValueChanged<PickedAttachment> onRemovePending;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.topbar,
        border: Border(top: BorderSide(color: t.borderSoft)),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (attachError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  attachError!,
                  style: TextStyle(fontSize: 12, color: t.danger),
                ),
              ),
            if (pending.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final attachment in pending)
                      PendingChip(
                        attachment: attachment,
                        onRemove: () => onRemovePending(attachment),
                      ),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                PhoneIconButton(
                  icon: AppIcons.plus,
                  semanticLabel: l10n.attachFile,
                  color: t.fgSecondary,
                  onPressed: sending ? null : onAttach,
                ),
                Expanded(
                  child: CcTextField(
                    controller: controller,
                    hintText: l10n.messageHint,
                    keyboardType: TextInputType.multiline,
                    onSubmitted: (_) => onSend(),
                  ),
                ),
                const SizedBox(width: 8),
                CcButton(
                  icon: AppIcons.send,
                  loading: sending,
                  onPressed: onSend,
                  child: Text(l10n.send),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
