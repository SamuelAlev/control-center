import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// How a [SettingsGroup] separates its children.
enum SettingsGroupSeparator {
  /// A comfortable gap. The default — right for a stack of labelled controls,
  /// where a rule between every field would out-shout the fields.
  space,

  /// A hairline rule. Right for a list of repeating rows (entities, toggles),
  /// where the rule is what says "these are peers, this one ended".
  rule,

  /// Nothing at all. For children that already carry their own separation.
  none,
}

/// A titled block **inside** a `SectionCard` — the layer between "one card, one
/// subject" and "one row, one control".
///
/// A card that asks more than one question needs a way to say so. The obvious
/// move is another card, and that is exactly wrong: a box inside a box adds two
/// borders and a shadow to communicate one heading. So a group is a heading, an
/// optional sentence and (optionally) a rule above it — no fill, no border, no
/// nesting.
///
/// The heading is sentence-case semibold ink, deliberately *not* the card's
/// uppercase tracked eyebrow: the card label stays the strongest thing in the
/// card, and a group reads as a subdivision of it rather than a rival to it.
class SettingsGroup extends StatelessWidget {
  /// Creates a [SettingsGroup].
  const SettingsGroup({
    super.key,
    this.title,
    this.description,
    this.trailing,
    required this.children,
    this.separator = SettingsGroupSeparator.space,
    this.gap = AppSpacing.lg,
    this.showRule = false,
    this.padding = EdgeInsets.zero,
  });

  /// The group heading. Sentence case; omit for an untitled cluster.
  final String? title;

  /// One sentence saying what the group is for, or what changing it does.
  final String? description;

  /// Optional control aligned to the right of the heading (a status tag, a
  /// small action).
  final Widget? trailing;

  /// The group's rows, in display order.
  final List<Widget> children;

  /// How the children are separated.
  final SettingsGroupSeparator separator;

  /// Gap between children when [separator] is [SettingsGroupSeparator.space].
  final double gap;

  /// Draws a hairline above the group. Use it on every group after the first so
  /// the card reads as a sequence of blocks rather than one long column.
  final bool showRule;

  /// Padding around the whole group. Cards that go edge-to-edge (a row list)
  /// pass horizontal insets here so the rules can still span the full width.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final hasHeader = title != null || description != null || trailing != null;

    final body = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        switch (separator) {
          case SettingsGroupSeparator.space:
            body.add(SizedBox(height: gap));
          case SettingsGroupSeparator.rule:
            body.add(const CcDivider());
          case SettingsGroupSeparator.none:
            break;
        }
      }
      body.add(children[i]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showRule) ...[
          const CcDivider(),
          const SizedBox(height: AppSpacing.lg),
        ],
        Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasHeader) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (title != null)
                            Text(
                              title!,
                              style: CcTypography.bodySm.copyWith(
                                fontWeight: FontWeight.w600,
                                color: tokens.textPrimary,
                              ),
                            ),
                          if (description != null) ...[
                            if (title != null) const SizedBox(height: 3),
                            Text(
                              description!,
                              style: CcTypography.caption.copyWith(
                                color: tokens.textTertiary,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: AppSpacing.md),
                      trailing!,
                    ],
                  ],
                ),
                if (children.isNotEmpty) const SizedBox(height: AppSpacing.md),
              ],
              ...body,
            ],
          ),
        ),
      ],
    );
  }
}
