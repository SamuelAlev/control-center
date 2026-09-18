import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// Shared floating chrome for the regex tester and symbol popovers. Matches
/// [CcPopover] (panel fill, hairline, golden float shadow) and supplies a
/// complete [DefaultTextStyle] because this paints into the root overlay.
class DiffGotoPanel extends StatelessWidget {
  /// Creates a [DiffGotoPanel].
  const DiffGotoPanel({
    super.key,
    required this.child,
    this.width = 320,
  });

  /// Inner content.
  final Widget child;

  /// Panel width.
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = context.ccTheme;
    final t =
        context.designSystem ??
        (theme?.isDark == true
            ? DesignSystemTokens.dark()
            : DesignSystemTokens.light());
    final card = CcCardTokens.panel(t);
    final textStyle = CcFonts.ui(
      family: theme?.fontFamily,
      textStyle: CcTypography.body.copyWith(
        color: t.textPrimary,
        decoration: TextDecoration.none,
      ),
    );
    return DefaultTextStyle(
      style: textStyle,
      child: SizedBox(
        width: width,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: card.bg,
            borderRadius: AppRadii.brLg,
            border: Border.all(color: card.border),
            boxShadow: CcElevation.floating,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: child,
          ),
        ),
      ),
    );
  }
}
