import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// Why a [FieldPlaceholder] stands in for its field.
enum FieldPlaceholderKind {
  /// Nothing to pick from yet, and only the user can change that (no adapter
  /// selected, or the adapter advertises no models). Wears disabled chrome.
  idle,

  /// The list is on its way. Wears the live field's chrome so resolving into
  /// the real field is not a visual jump.
  loading,

  /// The list could not be fetched.
  error,
}

/// The stand-in for a field that cannot render yet (no adapter selected,
/// models still loading, the fetch failed, or an empty list).
///
/// It must wear the cc_ui field box — a quiet fill closed by a 1px bottom
/// underline, 12/10 padding and `bodySm` text, no radius and no side chrome —
/// because it stands in a row beside real [CcSelect] triggers: anything else
/// reads as a different kind of control, and any hardcoded height drifts from
/// the trigger's as the tokens move.
///
/// [kind] carries the state in the chrome — a spinner while loading, the
/// field's error tint and outline on failure — so the reason is never left to
/// the sentence alone.
class FieldPlaceholder extends StatelessWidget {
  /// Creates a [FieldPlaceholder].
  const FieldPlaceholder({
    super.key,
    required this.text,
    this.kind = FieldPlaceholderKind.idle,
  });

  /// Placeholder text to display.
  final String text;

  /// Why the field is absent.
  final FieldPlaceholderKind kind;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final input = CcInputTokens.resolve(t);
    final isError = kind == FieldPlaceholderKind.error;
    final isIdle = kind == FieldPlaceholderKind.idle;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isError
            ? input.bgError
            : isIdle
            ? t.bgDisabled
            : input.bg,
        border: Border(
          bottom: BorderSide(
            color: isError
                ? input.borderError
                : isIdle
                ? t.borderDisabled
                : input.border,
          ),
        ),
      ),
      // The 2px danger outline the fields draw on error, over the whole box.
      foregroundDecoration: isError
          ? BoxDecoration(
              border: Border.all(color: input.borderError, width: 2),
            )
          : null,
      child: Row(
        children: [
          if (kind == FieldPlaceholderKind.loading) ...[
            CcSpinner(
              size: 13,
              strokeWidth: 1.5,
              color: t.fgTertiary,
              semanticLabel: text,
            ),
            AppSpacing.hGapSm,
          ] else if (isError) ...[
            Icon(CcIcons.circleX, size: 14, color: t.danger),
            AppSpacing.hGapSm,
          ],
          Expanded(
            // An adapter error carries the upstream message, which is long
            // more often than not: truncate and disclose the rest on hover
            // rather than letting it blow the row's height out.
            child: CcTruncatedText(
              text,
              style: CcTypography.bodySm.copyWith(
                // The field's own hint color, not `textDisabled`: this is
                // guidance the reader needs in order to act ("select an
                // adapter first"), so it holds the AA floor rather than taking
                // the contrast exemption an inert control would be allowed.
                color: isError ? t.danger : input.placeholder,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
