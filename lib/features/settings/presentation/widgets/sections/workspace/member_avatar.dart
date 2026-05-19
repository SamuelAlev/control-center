import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/media/disk_cached_network_image.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/workspace/membership_formatting.dart';
import 'package:control_center/shared/utils/github_avatar_url.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A workspace member's avatar: the best available image for [user], falling
/// back to initials derived from [name].
///
/// Resolution order — first hit wins and every layer is verified identity
/// (a login is never guessed from the handle, which could belong to a
/// stranger on GitHub):
///
/// 1. An explicit `avatarRef` http(s) URL set on the profile.
/// 2. The GitHub login recovered from a `*@users.noreply.github.com` git
///    author email — GitHub issues that address itself, so the login it
///    embeds is verified.
/// 3. For the CURRENT user when they hold the workspace's owner role: the
///    host's authenticated GitHub user (`github.currentUser`). The server
///    holds one gh token — the host owner's — and the owner-role backfill
///    ties it to that user, so the avatar only lands on their row.
/// 4. Initials.
class MemberAvatar extends ConsumerWidget {
  /// Creates a [MemberAvatar].
  const MemberAvatar({
    super.key,
    required this.name,
    required this.workspaceId,
    this.user,
    this.size = 28,
  });

  /// The resolved display name (initials fallback).
  final String name;

  /// The member's user record, when known.
  final UserDto? user;

  /// The workspace whose roster/activity is rendered — scopes the owner-role
  /// check behind the host-GitHub-avatar layer.
  final String workspaceId;

  /// Diameter in logical pixels.
  final double size;

  /// GitHub noreply addresses: `login@users.noreply.github.com` and the
  /// numeric-id form `12345+login@users.noreply.github.com`.
  static final _noreplyGitHubEmail = RegExp(
    r'^(?:\d+\+)?([A-Za-z0-9](?:[A-Za-z0-9-]{0,37}[A-Za-z0-9])?)'
    r'@users\.noreply\.github\.com$',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initials = avatarInitials(name);
    final url = _resolveImageUrl(ref);
    if (url == null) {
      return CcAvatar(size: size, initials: initials);
    }
    final sized = sizedGitHubAvatarUrl(
      url,
      size,
      MediaQuery.devicePixelRatioOf(context),
    );
    return CcAvatar(
      image: DiskCachedNetworkImage(MediaProxyScope.urlOf(context, sized)),
      size: size,
      initials: initials,
    );
  }

  String? _resolveImageUrl(WidgetRef ref) {
    final user = this.user;
    final avatarRef = user?.avatarRef;
    if (avatarRef != null && avatarRef.startsWith('http')) {
      return avatarRef;
    }
    final noreply = _noreplyGitHubEmail.firstMatch(user?.gitAuthorEmail ?? '');
    if (noreply != null) {
      return 'https://github.com/${noreply.group(1)}.png';
    }
    if (user != null && user.id == ref.watch(currentUserIdProvider)) {
      final isOwner =
          ref.watch(myWorkspaceRoleProvider(workspaceId)) ==
          WorkspaceRole.owner;
      if (isOwner) {
        final gh = ref.watch(githubUserProvider).value;
        if (gh != null && gh.avatarUrl.isNotEmpty) {
          return gh.avatarUrl;
        }
      }
    }
    return null;
  }
}
