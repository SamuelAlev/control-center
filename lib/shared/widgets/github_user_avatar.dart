import 'package:cc_domain/core/domain/entities/github_user.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/media/disk_cached_network_image.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/utils/github_avatar_url.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Displays a GitHub user's avatar with optional hover-card navigation.
class GitHubUserAvatar extends ConsumerStatefulWidget {
  /// Creates a [GitHubUserAvatar].
  const GitHubUserAvatar({
    super.key,
    required this.login,
    this.avatarUrl,
    this.size = 24,
    this.showHoverCard = true,
  });

  /// The GitHub login (username) of the user.
  final String login;

  /// Optional URL to the user's avatar image.
  final String? avatarUrl;

  /// The size of the avatar in logical pixels.
  final double size;

  /// Whether to wrap the avatar in a [GestureDetector] that navigates to the user's profile on tap.
  final bool showHoverCard;

  @override
  ConsumerState<GitHubUserAvatar> createState() => _GitHubUserAvatarState();
}

class _GitHubUserAvatarState extends ConsumerState<GitHubUserAvatar> {
  void _navigateToProfile() {
    GoRouter.of(
      context,
    ).go(userProfileRoute(context.currentWorkspaceId!, widget.login));
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.login.isNotEmpty
        ? widget.login[0].toUpperCase()
        : '?';

    Widget avatar;
    if (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty) {
      final sized = sizedGitHubAvatarUrl(
        widget.avatarUrl!,
        widget.size,
        MediaQuery.devicePixelRatioOf(context),
      );
      avatar = CcAvatar(
        image: DiskCachedNetworkImage(MediaProxyScope.urlOf(context, sized)),
        size: widget.size,
        initials: initial,
      );
    } else {
      avatar = CcAvatar(size: widget.size, initials: initial);
    }

    if (!widget.showHoverCard || isGitHubBotLogin(widget.login)) {
      return avatar;
    }

    return GestureDetector(
      onTap: _navigateToProfile,
      behavior: HitTestBehavior.opaque,
      child: avatar,
    );
  }
}
