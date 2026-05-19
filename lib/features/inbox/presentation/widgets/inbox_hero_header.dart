import 'package:cc_domain/features/pr_review/domain/usecases/classify_pr_inbox_use_case.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/inbox/providers/inbox_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:control_center/shared/widgets/shader_background.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Asset path for the dark-mode golden-hour cloudscape shader.
const String _heroShaderDark = 'assets/shaders/hero_background_dark.frag';

/// Asset path for the light-mode golden-hour cloudscape shader.
const String _heroShaderLight = 'assets/shaders/hero_background_light.frag';

/// Opacity of the animated cloudscape over the panel canvas. Kept below 1 so
/// the warm canvas reads through and the title stays high-contrast; tuned to
/// keep the day-to-day surface quiet while the shapes still breathe.
const double _shaderVeil = 0.6;

/// The inbox hero — the page's earned brand moment. A warm panel with the
/// golden-hour cloudscape breathing behind the title and the page actions.
/// The subtitle reports real state: how many pull requests need the
/// operator's review and how many came back to them, falling back to a
/// one-line description while the snapshot loads (or when nothing is
/// pending). `prefers-reduced-motion` renders the shader frozen (speed 0) so
/// the shapes stay but the motion stops.
class InboxHeroHeader extends ConsumerWidget {
  /// Creates an [InboxHeroHeader].
  const InboxHeroHeader({super.key, this.actions});

  /// The page actions (filter, display options, refresh) rendered at the
  /// right end of the title row.
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ds = context.designSystem ?? DesignSystemTokens.light();

    final data = ref.watch(inboxDataProvider).value;
    final needsReview = data?.of(PrInboxSection.needsYourReview).length ?? 0;
    final returned = data?.of(PrInboxSection.returnedToYou).length ?? 0;

    final subtitle = (needsReview == 0 && returned == 0)
        ? l10n.inboxHeroSubtitle
        : [
            if (needsReview > 0) l10n.inboxHeroNeedsReview(needsReview),
            if (returned > 0) l10n.inboxHeroReturnedToYou(returned),
          ].join(' · ');

    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final shaderAsset = (context.ccTheme?.isDark ?? false)
        ? _heroShaderDark
        : _heroShaderLight;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: ds.canvas,
        border: Border(bottom: BorderSide(color: ds.borderPrimary)),
        boxShadow: AppShadows.soft,
        gradient: RadialGradient(
          center: const Alignment(0.7, -1.1),
          radius: 1.1,
          colors: [
            ds.surface.withValues(alpha: 0.65),
            ds.canvas.withValues(alpha: 0),
          ],
        ),
      ),
      // Full-bleed: the panel spans the page's full width with a single
      // bottom border. Content keeps the same 24px horizontal inset as the
      // rail/list body below so the title aligns with the columns it heads.
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              // The cloudscape shader breathes the panel. Under
              // prefers-reduced-motion it renders frozen (speed 0) — the
              // shapes stay, the motion stops.
              child: Opacity(
                opacity: _shaderVeil,
                child: ShaderBackground(
                  shaderAsset: shaderAsset,
                  animate: !reduceMotion,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xxl,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final titleSize = (constraints.maxWidth * 0.072).clamp(
                  38.0,
                  60.0,
                );
                // The panel keeps its hero stature: reserve exactly the
                // vertical space the old display-size title (titleSize at
                // height 1.0), the 12px gap, and the 18px/1.4 subtitle line
                // occupied, while the text itself drops to the standard
                // page-header typography (PageHeaderText, same as the pull
                // request and pipeline pages). Top-anchored so the slack
                // collects at the bottom.
                return SizedBox(
                  height: titleSize + AppSpacing.md + 18 * 1.4,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: PageHeaderText(
                            title: l10n.inboxTitle,
                            subtitle: subtitle,
                          ),
                        ),
                        ...?actions,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
