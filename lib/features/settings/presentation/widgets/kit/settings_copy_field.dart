import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// A read-only value the operator has to hand to something else: an ACS URL, a
/// SCIM endpoint, a redirect URI, a base URL.
///
/// These were previously rendered as a row subtitle in tertiary 12px text —
/// unselectable, untruncated, and indistinguishable from the explanatory prose
/// two lines above. But this is the single value the reader came to the page to
/// collect, and it has to survive being pasted into an identity provider's
/// console with no character lost.
///
/// So it reads as a value: mono face, field fill, one copy button, and a toast
/// confirming the copy happened. When there is nothing to show yet it says so
/// in words rather than rendering an empty well.
///
/// Copy, not selection: `SelectableText` and `SelectionArea` are Material, and
/// the whole value is what gets pasted into an IdP console anyway — a partial
/// selection of an ACS URL is never what anyone wanted.
class SettingsCopyField extends StatelessWidget {
  /// Creates a [SettingsCopyField].
  const SettingsCopyField({
    super.key,
    required this.value,
    this.emptyLabel,
    this.copiedMessage,
    this.maxLines = 1,
  });

  /// The value. Null or empty renders [emptyLabel] instead of a copy target.
  final String? value;

  /// What to say when there is no value yet, and why.
  final String? emptyLabel;

  /// Toast shown after a successful copy. Defaults to the shared "Copied".
  final String? copiedMessage;

  /// Lines to show before truncating. A PEM block or an XML blob wants more.
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return Text(
        emptyLabel ?? l10n.settingsValueNotAvailable,
        style: CcTypography.caption.copyWith(color: tokens.textTertiary),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: tokens.bgSecondary,
        borderRadius: AppRadii.brSm,
        border: Border.all(color: tokens.borderSecondary),
      ),
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 6, 6, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              text,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: CcFonts.code(
                textStyle: CcTypography.caption.copyWith(
                  color: tokens.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          CcIconButton(
            icon: AppIcons.copy,
            size: CcButtonSize.sm,
            variant: CcButtonVariant.ghost,
            tooltip: l10n.copy,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));
              if (context.mounted) {
                CcToastScope.maybeOf(
                  context,
                )?.show(copiedMessage ?? l10n.copied);
              }
            },
          ),
        ],
      ),
    );
  }
}
