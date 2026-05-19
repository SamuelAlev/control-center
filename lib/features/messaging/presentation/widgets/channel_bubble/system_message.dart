import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/channel_bubble_shared.dart';
import 'package:flutter/widgets.dart';

/// Renders a centered system message with divider lines.
class SystemMessage extends StatelessWidget {
  /// Creates a [SystemMessage].
  const SystemMessage({super.key, required this.content});

  /// The system message content.
  final String content;

  @override
  Widget build(BuildContext context) {
    final tokens = resolveTokens(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Semantics(
        label: 'System: $content',
        child: Row(
          children: [
            Expanded(child: CcDivider(color: tokens.borderSecondary)),
            const SizedBox(width: 12),
            Text(
              content,
              style: CcTypography.caption.copyWith(color: tokens.textTertiary),
            ),
            const SizedBox(width: 12),
            Expanded(child: CcDivider(color: tokens.borderSecondary)),
          ],
        ),
      ),
    );
  }
}
