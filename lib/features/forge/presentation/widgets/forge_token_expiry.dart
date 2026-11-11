import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' show DateFormat;

/// The row's summary line, then when its token expires: a warning once that
/// has passed.
class ForgeTokenExpiry extends StatelessWidget {
  /// Creates a [ForgeTokenExpiry].
  const ForgeTokenExpiry({
    super.key,
    required this.summary,
    required this.expiresAt,
    required this.expired,
  });

  /// The row's own summary line, kept above the expiry.
  final String summary;

  /// When the token stops working.
  final DateTime expiresAt;

  /// Whether [expiresAt] has passed.
  final bool expired;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final date = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    ).format(expiresAt.toLocal());
    final style = CcTypography.caption.copyWith(
      color: t.textTertiary,
      height: 1.45,
    );
    final warning = style.copyWith(color: t.textWarningPrimary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(summary, style: style),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (expired) ...[
              Icon(AppIcons.alertTriangle, size: 12, color: warning.color),
              const SizedBox(width: AppSpacing.xs),
            ],
            Flexible(
              child: AppTimestamp(
                dateTime: expiresAt,
                child: Text(
                  expired
                      ? l10n.forgeTokenExpiredOn(date)
                      : l10n.forgeTokenExpiresOn(date),
                  style: expired ? warning : style,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
