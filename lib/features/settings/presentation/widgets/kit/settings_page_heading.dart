import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// A heading between a settings page's cards: it names the cards under it.
///
/// A page that holds two subjects (who you are, then the accounts you
/// connect) says where the second one starts. It is text on the page, not a
/// card: a box around the cards it introduces would nest them.
///
/// It sits one step under the page title and one above a card's label, and
/// keeps more room above itself than below so it reads as the start of what
/// follows, not the end of what came before.
class SettingsPageHeading extends StatelessWidget {
  /// Creates a [SettingsPageHeading].
  const SettingsPageHeading({super.key, required this.title, this.description});

  /// The heading. Sentence case.
  final String title;

  /// One or two sentences on what the cards under it are for.
  final String? description;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final description = this.description;
    return Padding(
      // The page already puts one card gap above; this doubles it.
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: CcTypography.title.copyWith(color: t.textPrimary),
            ),
          ),
          if (description != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              description,
              style: CcTypography.bodySm.copyWith(
                color: t.textTertiary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
