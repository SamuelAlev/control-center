import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_text.dart';
import 'package:flutter/widgets.dart';

/// The shape every long-running-work row in the conversation shares: a small
/// glyph, one sentence, an optional chip after it, an optional detail line
/// under it and an optional trailing action. Quiet by design: these rows say
/// what the machinery did, they are not the conversation.
class WorkRowFrame extends StatelessWidget {
  /// Creates the row.
  const WorkRowFrame({
    super.key,
    required this.icon,
    required this.sentence,
    this.chip,
    this.detail,
    this.trailing,
  });

  /// The glyph naming what happened.
  final IconData icon;

  /// The sentence.
  final String sentence;

  /// A chip after the sentence (what raised a wake).
  final Widget? chip;

  /// A line under the sentence (the reason, the headline, a quotation).
  final Widget? detail;

  /// A trailing action.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Semantics(
      container: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 2),
              child: Icon(icon, size: 14, color: ds.textTertiary),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        sentence,
                        style: CcTypography.caption.copyWith(
                          color: ds.textSecondary,
                        ),
                      ),
                      ?chip,
                    ],
                  ),
                  if (detail != null)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(top: 2),
                      child: detail,
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.xs),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Words someone else wrote (an agent's note to itself, a person's
/// reminder), set off as a quotation and shown exactly as plain text.
class WorkQuote extends StatelessWidget {
  /// Creates the quotation.
  const WorkQuote({super.key, required this.text});

  /// The quoted words.
  final String text;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Container(
      margin: const EdgeInsetsDirectional.only(top: 2),
      padding: const EdgeInsetsDirectional.only(start: AppSpacing.sm),
      decoration: BoxDecoration(
        border: BorderDirectional(start: BorderSide(color: ds.borderSecondary)),
      ),
      child: Text(
        inertText(text),
        maxLines: 12,
        overflow: TextOverflow.ellipsis,
        style: CcTypography.bodySm.copyWith(color: ds.textSecondary),
      ),
    );
  }
}
