import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// The standard inline failure state for an `AsyncValue.error` branch.
///
/// Replaces the `Text('$e')` dumps that used to sit in `.when(error: …)`
/// callbacks: those printed an untranslated (often Dart-shaped) exception
/// string as the entire UI. The headline is localized; the raw detail stays,
/// but as secondary text, because it is what makes a bug report useful.
class InlineLoadError extends StatelessWidget {
  /// Creates an [InlineLoadError] for [error].
  const InlineLoadError(
    this.error, {
    super.key,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.center = true,
  });

  /// The failure to present.
  final Object error;

  /// Padding around the message.
  final EdgeInsetsGeometry padding;

  /// Whether to center the message in the available space.
  final bool center;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final content = Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: center
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Text(
            l10n.failedToLoad,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: CcTypography.bodySm.copyWith(color: tokens.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '$error',
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: CcTypography.caption.copyWith(color: tokens.textTertiary),
          ),
        ],
      ),
    );
    return center ? Center(child: content) : content;
  }
}
