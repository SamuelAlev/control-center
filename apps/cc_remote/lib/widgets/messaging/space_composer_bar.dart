import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/conversation_drafts.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/widgets/touch_target.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

class SpaceComposerBar extends StatelessWidget {
  const SpaceComposerBar({
    required this.controller,
    required this.sending,
    required this.enabled,
    required this.ready,
    required this.pending,
    required this.attachError,
    required this.onAttach,
    required this.onSend,
    required this.onRemovePending,
    required this.onRetryPending,
    this.detailsMaxHeight = 120,
    this.maxLines = 5,
    super.key,
  });
  final TextEditingController controller;
  final bool sending;
  final bool enabled;
  final bool ready;
  final List<DraftAttachment> pending;
  final String? attachError;
  final VoidCallback onAttach;
  final VoidCallback onSend;
  final ValueChanged<DraftAttachment> onRemovePending;
  final ValueChanged<DraftAttachment> onRetryPending;
  final double detailsMaxHeight;
  final int maxLines;

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
            if (attachError != null || pending.isNotEmpty)
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: detailsMaxHeight),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (attachError != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: CcAlert(
                            title: l10n.mobileSendFailed,
                            description: Text(attachError!),
                            variant: CcAlertVariant.danger,
                          ),
                        ),
                      for (final file in pending)
                        Row(
                          children: [
                            Icon(
                              file.uploading
                                  ? AppIcons.loader
                                  : file.error != null
                                  ? AppIcons.triangleAlert
                                  : AppIcons.file,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                file.picked.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (file.error != null)
                              CcButton(
                                size: CcButtonSize.lg,
                                variant: CcButtonVariant.secondary,
                                onPressed: sending || !enabled
                                    ? null
                                    : () => onRetryPending(file),
                                child: Text(l10n.retry),
                              ),
                            PhoneIconButton(
                              icon: AppIcons.x,
                              semanticLabel: l10n.mobileRemove,
                              onPressed: sending || file.uploading || !enabled
                                  ? null
                                  : () => onRemovePending(file),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                PhoneIconButton(
                  icon: AppIcons.plus,
                  semanticLabel: l10n.attachFile,
                  color: t.fgSecondary,
                  onPressed: sending || !enabled ? null : onAttach,
                ),
                Expanded(
                  child: CcTextField(
                    controller: controller,
                    enabled: enabled && !sending,
                    hintText: l10n.messageHint,
                    minLines: 1,
                    maxLines: maxLines,
                    keyboardType: TextInputType.multiline,
                  ),
                ),
                const SizedBox(width: 8),
                CcButton(
                  icon: AppIcons.send,
                  size: CcButtonSize.lg,
                  loading: sending,
                  onPressed: ready && enabled ? onSend : null,
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
