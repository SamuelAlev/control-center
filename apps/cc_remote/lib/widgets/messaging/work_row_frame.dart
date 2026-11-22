import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// One work row: an icon, the app's sentence, what raised it, the details
/// under it and an optional action.
class WorkRowFrame extends StatelessWidget {
  const WorkRowFrame({
    super.key,
    required this.icon,
    required this.sentence,
    this.origin,
    this.detail = const [],
    this.action,
  });

  final IconData icon;
  final String sentence;
  final String? origin;
  final List<Widget> detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 10, start: 4, end: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 2),
            child: Icon(icon, size: 14, color: t.fgTertiary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sentence,
                  style: CcTypography.bodySm.copyWith(color: t.textSecondary),
                ),
                if (origin != null)
                  Text(
                    origin!,
                    style: CcTypography.caption.copyWith(color: t.textTertiary),
                  ),
                for (final d in detail)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: 4),
                    child: d,
                  ),
                ?action,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
