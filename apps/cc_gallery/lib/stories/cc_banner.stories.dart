import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_banner.stories.g.dart';

/// Stories for [CcBanner] — a floating, ambient banner for a time-critical,
/// actionable event. Louder than an inline [CcAlert]: it lifts with the golden
/// float shadow and stacks into the shell's ambient rail. Intent reads from the
/// glyph, tint and copy together (never color alone) and the entrance
/// slide/fade collapses under reduced motion.

const _path = '[Components]/Feedback';

const component = ComponentMeta(name: 'CcBanner', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcBannerPlayground.new,
);

final $Playground = _PlaygroundStory(
  args: _PlaygroundArgs(
    variant: EnumArg<CcBannerVariant>(
      CcBannerVariant.values.first,
      name: 'Variant',
      values: CcBannerVariant.values,
    ),
    title: StringArg('Standup starting soon', name: 'Title'),
    body: StringArg('Daily sync starts in 2 minutes.', name: 'Body'),
    withPrimary: BoolArg(true, name: 'Primary action'),
    withSecondary: BoolArg(true, name: 'Secondary action'),
    dismissible: BoolArg(true, name: 'Dismissible'),
  ),
  builder: (context, args) =>
      Showcase.playground((context) => ccBannerPlaygroundStory(context, args)),
);

final $Variants = _Story(args: _Args.fixed(preview: ccBannerVariantsStory));

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcBannerPlayground {
  CcBannerPlayground({
    required this.variant,
    required this.title,
    required this.body,
    required this.withPrimary,
    required this.withSecondary,
    required this.dismissible,
  });

  final CcBannerVariant variant;
  final String title;
  final String body;
  final bool withPrimary;
  final bool withSecondary;
  final bool dismissible;
}

/// Every semantic variant stacked, each with a matching glyph and actions.
Widget ccBannerVariantsStory(BuildContext context) {
  return Center(
    child: SizedBox(
      width: 560,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CcBanner(
            title: 'Standup starting soon',
            body: 'Daily sync starts in 2 minutes.',
            icon: CcIcons.calendarClock,
            actions: [
              CcBannerAction(label: 'Join', onPressed: () {}, primary: true),
              CcBannerAction(label: 'Record & link', onPressed: () {}),
            ],
            onDismiss: () {},
          ),
          const SizedBox(height: 12),
          CcBanner(
            title: 'Calendar disconnected',
            body: 'Reconnect sam@usectrl.dev to resume syncing.',
            variant: CcBannerVariant.warning,
            icon: CcIcons.calendarX,
            actions: [
              CcBannerAction(
                label: 'Reconnect',
                onPressed: () {},
                primary: true,
              ),
            ],
            onDismiss: () {},
          ),
          const SizedBox(height: 12),
          CcBanner(
            title: 'Workspace seeded',
            body: 'The CEO agent created three starter tickets.',
            variant: CcBannerVariant.success,
            onDismiss: () {},
          ),
          const SizedBox(height: 12),
          CcBanner(
            title: 'Sync failed',
            body: 'GitHub returned 503 — retrying shortly.',
            variant: CcBannerVariant.danger,
            onDismiss: () {},
          ),
        ],
      ),
    ),
  );
}

/// Interactive playground — drive every arg to see the full state space.
Widget ccBannerPlaygroundStory(
  BuildContext context,
  CcBannerPlaygroundArgs args,
) {
  final variant = args.variant;
  final title = args.title;
  final body = args.body;
  final withPrimary = args.withPrimary;
  final withSecondary = args.withSecondary;
  final dismissible = args.dismissible;

  return Center(
    child: SizedBox(
      width: 560,
      child: CcBanner(
        variant: variant,
        title: title,
        body: body.isEmpty ? null : body,
        actions: [
          if (withPrimary)
            CcBannerAction(label: 'Join', onPressed: () {}, primary: true),
          if (withSecondary)
            CcBannerAction(label: 'Record & link', onPressed: () {}),
        ],
        onDismiss: dismissible ? () {} : null,
      ),
    ),
  );
}
