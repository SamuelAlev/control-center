import 'package:cc_markdown/cc_markdown.dart' show CcSelectionRegion;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The link dialog's first step: the one-time code, where to send it, and
/// that the dialog is listening for it to arrive.
class ChatLinkCodeStep extends StatelessWidget {
  /// Creates a [ChatLinkCodeStep].
  const ChatLinkCodeStep({
    super.key,
    required this.providerName,
    required this.code,
  });

  /// The chat provider's display name.
  final String providerName;

  /// The code the member sends to the bot.
  final String code;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.chatLinkCodeInstruction(providerName),
          style: CcTypography.bodySm.copyWith(
            height: 1.4,
            color: t.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _CodeBox(code: code),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            CcSpinner(size: 12, color: t.textTertiary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l10n.chatLinkWaiting,
                style: CcTypography.caption.copyWith(color: t.textSecondary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The code to send to the bot, prominent and copyable.
class _CodeBox extends StatelessWidget {
  const _CodeBox({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      color: t.bgSecondary,
      child: Row(
        children: [
          Expanded(
            // Selectable as well as copyable: the code is often retyped into
            // the chat app on a phone, from a screen the copy button cannot
            // reach.
            child: CcSelectionRegion(
              child: Text(
                code,
                style: CcFonts.code(
                  textStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                    color: t.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          CcIconButton(
            size: CcButtonSize.sm,
            icon: AppIcons.copy,
            tooltip: l10n.copy,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (context.mounted) {
                CcToastScope.of(
                  context,
                ).show(l10n.copied, variant: CcToastVariant.success);
              }
            },
          ),
        ],
      ),
    );
  }
}
