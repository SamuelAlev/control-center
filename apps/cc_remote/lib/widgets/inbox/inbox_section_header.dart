import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

class InboxSectionHeader extends StatelessWidget {
  const InboxSectionHeader({
    required this.label,
    required this.count,
    required this.icon,
    this.urgent = false,
    super.key,
  });
  final String label;
  final int count;
  final IconData icon;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final color = urgent ? t.textPrimary : t.textSecondary;
    return Row(
      children: [
        Icon(icon, size: 15, color: urgent ? t.accent : t.fgTertiary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          NumberFormat.decimalPattern(
            Localizations.localeOf(context).toLanguageTag(),
          ).format(count),
          style: TextStyle(fontSize: 12, color: t.textTertiary),
        ),
      ],
    );
  }
}
