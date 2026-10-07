import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_avatar.stories.g.dart';

/// Stories for [CcAvatar] — the design system's circular avatar.
///
/// It renders, in priority order: an image, then uppercased initials, then an
/// icon, falling back to an empty tinted disc. The builders return the
/// component directly — the gallery's theme addon supplies the [CcTheme] +
/// canvas.

const _path = '[Components]/Containers';

const component = ComponentMeta(name: 'CcAvatar', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcAvatarPlayground.new,
);

final $Playground = _PlaygroundStory(
  args: _PlaygroundArgs(
    size: DoubleArg(
      40,
      name: 'Size',
      style: const SliderDoubleArgStyle(min: 16, max: 96, divisions: 80),
    ),
    initials: StringArg('CC', name: 'Initials'),
    useInitials: BoolArg(true, name: 'Show initials'),
  ),
  builder: (context, args) =>
      Showcase.playground((context) => ccAvatarPlaygroundStory(context, args)),
);

final $CustomBackground = _Story(
  name: 'Custom background',
  args: _Args.fixed(preview: ccAvatarBackgroundStory),
);

final $FallbackContent = _Story(
  name: 'Fallback content',
  args: _Args.fixed(preview: ccAvatarFallbackStory),
);

final $Sizes = _Story(args: _Args.fixed(preview: ccAvatarSizesStory));

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcAvatarPlayground {
  CcAvatarPlayground({
    required this.size,
    required this.initials,
    required this.useInitials,
  });

  final double size;
  final String initials;
  final bool useInitials;
}

/// The three fallback content modes side by side: initials, icon, empty disc.
Widget ccAvatarFallbackStory(BuildContext context) {
  return const Center(
    child: Wrap(
      spacing: 16,
      runSpacing: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        CcAvatar(initials: 'SA'),
        CcAvatar(initials: 'CC'),
        CcAvatar(icon: CcIcons.bot),
        CcAvatar(icon: CcIcons.gitPullRequest),
        CcAvatar(),
      ],
    ),
  );
}

/// The size scale, from a dense inline marker up to a profile-sized disc.
Widget ccAvatarSizesStory(BuildContext context) {
  return const Center(
    child: Wrap(
      spacing: 16,
      runSpacing: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        CcAvatar(initials: 'CC', size: 20),
        CcAvatar(initials: 'CC', size: 28),
        CcAvatar(initials: 'CC', size: 40),
        CcAvatar(initials: 'CC', size: 56),
        CcAvatar(initials: 'CC', size: 72),
      ],
    ),
  );
}

/// A custom disc fill — useful for distinguishing agents, workspaces, or repos
/// by colour. The background is read from the design system tokens, never
/// hardcoded.
Widget ccAvatarBackgroundStory(BuildContext context) {
  final t = context.designSystem!;
  return Center(
    child: Wrap(
      spacing: 16,
      runSpacing: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        CcAvatar(initials: 'OP', size: 48, background: t.accent),
        CcAvatar(icon: CcIcons.bot, size: 48, background: t.bgSecondary),
        CcAvatar(initials: 'WS', size: 48, background: t.bgTertiary),
      ],
    ),
  );
}

/// Interactive playground — drive every arg to see the full state space.
Widget ccAvatarPlaygroundStory(
  BuildContext context,
  CcAvatarPlaygroundArgs args,
) {
  final size = args.size;
  final initials = args.initials;
  final useInitials = args.useInitials;
  return Center(
    child: CcAvatar(
      size: size,
      initials: useInitials ? initials : null,
      icon: CcIcons.bot,
    ),
  );
}
