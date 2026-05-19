import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/app_spacing.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_theme.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';

/// The Decisions tab: a numbered list of the decisions the agent extracted.
/// Each decision's first sentence reads as a heading, the remainder as body.
class MeetingDecisionsTab extends StatelessWidget {
  /// Creates a [MeetingDecisionsTab].
  const MeetingDecisionsTab({super.key, required this.decisions});

  /// The extracted decision lines.
  final List<String> decisions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (decisions.isEmpty) {
      return SectionCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: Center(
            child: Text(
              l10n.meetingDecisionsEmpty,
              style: TextStyle(color: context.ds.muted),
            ),
          ),
        ),
      );
    }
    final ds = context.ds;
    return SectionCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: AppRadii.brLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < decisions.length; i++) ...[
              if (i > 0)
                Divider(height: 1, thickness: 1, color: ds.borderSecondary),
              _DecisionRow(index: i, text: decisions[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _DecisionRow extends StatelessWidget {
  const _DecisionRow({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final (heading, body) = _split(text);
    final number = (index + 1).toString().padLeft(2, '0');
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30,
            child: Text(
              number,
              style: meetingMono(context, fontSize: 14, color: ds.accent),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  heading,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: ds.fg,
                  ),
                ),
                if (body != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    body,
                    style: TextStyle(fontSize: 13, height: 1.5, color: ds.muted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Splits a decision into a heading (first sentence) and an optional body.
  static (String, String?) _split(String text) {
    final match = RegExp(r'^(.+?[.!?])\s+(.+)$', dotAll: true).firstMatch(text);
    if (match != null) {
      final head = match.group(1)!.trim();
      final rest = match.group(2)!.trim();
      // Only split when the heading is a reasonable, short lead.
      if (head.length <= 120 && rest.isNotEmpty) {
        return (head, rest);
      }
    }
    return (text, null);
  }
}
