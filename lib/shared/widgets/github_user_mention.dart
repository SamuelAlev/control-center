import 'package:cc_domain/core/domain/entities/github_user.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/github_mention_avatar_scope.dart';
import 'package:control_center/shared/widgets/github_team_avatar.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:control_center/shared/widgets/github_user_hover_target.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Inline GitHub identity: a reserved-size avatar plus a name, tappable to
/// the in-app profile.
///
/// The avatar is a fixed [avatarSize] box from the first frame (initials or
/// an empty disc, then [CcAvatar]'s fade). The photo paints into that box, so
/// a late image cannot reflow the surrounding sentence.
class GitHubUserMention extends StatelessWidget {
  /// Creates a [GitHubUserMention].
  const GitHubUserMention({
    super.key,
    required this.login,
    this.avatarUrl = '',
    this.isTeam = false,
    this.style,
  });

  /// Diameter of the leading disc, matched to [CcTypography.caption]'s 16px
  /// line box so a [WidgetSpan] does not grow the event-row line height.
  static const double avatarSize = 16;

  /// GitHub login, or a team name when [isTeam].
  final String login;

  /// Avatar URL when known. Empty falls back to initials (users) or the
  /// team glyph (teams) — no network.
  final String avatarUrl;

  /// Team mentions use the team logo (or glyph) and are not profile links.
  final bool isTeam;

  /// Name style; defaults to semibold caption on `textPrimary`.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final resolvedAvatar = avatarUrl.isNotEmpty
        ? avatarUrl
        : GitHubMentionAvatarScope.lookup(
            context,
            login: login,
            isTeam: isTeam,
          );
    final displayLogin = isGitHubBotLogin(login)
        ? login.substring(0, login.length - '[bot]'.length)
        : login;
    final textStyle =
        style ??
        CcTypography.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: t.textPrimary,
          height: 1,
        );

    final canOpenProfile =
        !isTeam && login.isNotEmpty && !isGitHubBotLogin(login);

    Widget chip() {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: avatarSize,
            height: avatarSize,
            child: isTeam
                ? GitHubTeamAvatar(
                    name: login,
                    avatarUrl: resolvedAvatar,
                    size: avatarSize,
                  )
                : GitHubUserAvatar(
                    login: login,
                    avatarUrl: resolvedAvatar,
                    size: avatarSize,
                    showHoverCard: false,
                  ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(displayLogin, style: textStyle, maxLines: 1, softWrap: false),
        ],
      );
    }

    if (!canOpenProfile) {
      return chip();
    }

    return GitHubUserHoverTarget(
      login: login,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _openProfile(context),
          behavior: HitTestBehavior.opaque,
          child: Semantics(button: true, label: displayLogin, child: chip()),
        ),
      ),
    );
  }

  void _openProfile(BuildContext context) {
    final workspaceId = context.currentWorkspaceId;
    if (workspaceId == null) {
      return;
    }
    GoRouter.of(context).go(userProfileRoute(workspaceId, login));
  }
}
