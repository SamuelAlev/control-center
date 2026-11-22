import 'package:cc_domain/features/plan_studio/domain/entities/plan_document.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// The planner's clarifying questions and the answers it received.
class PlanClarifications extends StatelessWidget {
  /// Creates the list for [items].
  const PlanClarifications({super.key, required this.items});

  /// The questions, each with the answer it got (empty when it got none).
  final List<PlanClarification> items;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: ds.bgSecondary,
        border: Border(bottom: BorderSide(color: ds.borderSecondary)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final c in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.question,
                    style: TextStyle(
                      fontFamily: CcFonts.uiFamily,
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: ds.textSecondary,
                    ),
                  ),
                  if (c.answer.isNotEmpty)
                    Text(
                      c.answer,
                      style: TextStyle(
                        fontFamily: CcFonts.uiFamily,
                        fontSize: 12,
                        height: 1.45,
                        color: ds.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
