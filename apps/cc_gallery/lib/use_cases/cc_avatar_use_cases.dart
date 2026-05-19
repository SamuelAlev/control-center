import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcAvatar] — the design system's circular avatar.
///
/// It renders, in priority order: an image, then uppercased initials, then an
/// icon, falling back to an empty tinted disc. The builders return the
/// component directly — the gallery's theme addon supplies the [CcTheme] +
/// canvas.

const _path = '[Components]/Containers';

/// The three fallback content modes side by side: initials, icon, empty disc.
@widgetbook.UseCase(name: 'Fallback content', type: CcAvatar, path: _path)
Widget ccAvatarFallbackUseCase(BuildContext context) {
  return const Center(
    child: Wrap(
      spacing: 16,
      runSpacing: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        CcAvatar(initials: 'SA'),
        CcAvatar(initials: 'CC'),
        CcAvatar(icon: LucideIcons.bot),
        CcAvatar(icon: LucideIcons.gitPullRequest),
        CcAvatar(),
      ],
    ),
  );
}

/// The size scale, from a dense inline marker up to a profile-sized disc.
@widgetbook.UseCase(name: 'Sizes', type: CcAvatar, path: _path)
Widget ccAvatarSizesUseCase(BuildContext context) {
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
@widgetbook.UseCase(name: 'Custom background', type: CcAvatar, path: _path)
Widget ccAvatarBackgroundUseCase(BuildContext context) {
  final t = context.designSystem!;
  return Center(
    child: Wrap(
      spacing: 16,
      runSpacing: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        CcAvatar(initials: 'OP', size: 48, background: t.accent),
        CcAvatar(icon: LucideIcons.bot, size: 48, background: t.bgSecondary),
        CcAvatar(initials: 'WS', size: 48, background: t.bgTertiary),
      ],
    ),
  );
}

/// Interactive playground — drive every knob to see the full state space.
@widgetbook.UseCase(name: 'Playground', type: CcAvatar, path: _path)
Widget ccAvatarPlaygroundUseCase(BuildContext context) {
  final size = context.knobs.double.slider(
    label: 'Size',
    initialValue: 40,
    min: 16,
    max: 96,
  );
  final initials = context.knobs.string(
    label: 'Initials',
    initialValue: 'CC',
  );
  final useInitials = context.knobs.boolean(
    label: 'Show initials',
    initialValue: true,
  );
  return Center(
    child: CcAvatar(
      size: size,
      initials: useInitials ? initials : null,
      icon: LucideIcons.bot,
    ),
  );
}
