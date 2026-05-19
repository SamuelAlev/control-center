import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:flutter/widgets.dart';

/// A GitHub team logo: the forge avatar when [avatarUrl] is known, otherwise
/// the users-glyph disc used before we had a URL.
class GitHubTeamAvatar extends StatelessWidget {
  /// Creates a [GitHubTeamAvatar].
  const GitHubTeamAvatar({
    super.key,
    required this.name,
    this.avatarUrl = '',
    this.size = 24,
  });

  /// Display name, used for initials if the image fails.
  final String name;

  /// Team logo URL. Empty shows the glyph fallback (no network).
  final String avatarUrl;

  /// Diameter in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl.isNotEmpty) {
      return GitHubUserAvatar(
        login: name,
        avatarUrl: avatarUrl,
        size: size,
        showHoverCard: false,
      );
    }
    return _TeamGlyph(size: size);
  }
}

class _TeamGlyph extends StatelessWidget {
  const _TeamGlyph({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.bgSecondary,
          shape: BoxShape.circle,
          border: Border.all(color: t.borderSecondary),
        ),
        child: Center(
          child: Icon(
            AppIcons.users,
            size: (size * 0.54).clamp(8, 14),
            color: t.fgQuaternary,
          ),
        ),
      ),
    );
  }
}
