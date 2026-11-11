import 'package:cc_domain/cc_domain.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/media/disk_cached_network_image.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/workspace/membership_formatting.dart';
import 'package:control_center/shared/utils/github_avatar_url.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A person's avatar: the image their profile names, falling back to
/// initials derived from [name].
///
/// Only the profile decides the picture. A forge login or a commit email is
/// never mined for one: a noreply address names a GitHub account, not a
/// person here, and a guessed login can belong to a stranger. The single
/// explicit fallback is the viewer's OWN GitHub sign-in, for their own row
/// while their profile has no picture.
class MemberAvatar extends ConsumerWidget {
  /// Creates a [MemberAvatar].
  const MemberAvatar({
    super.key,
    required this.name,
    this.user,
    this.imageUrl,
    this.size = 28,
  });

  /// The resolved display name (initials fallback).
  final String name;

  /// The person's user record, when known.
  final UserDto? user;

  /// An image to show instead of the profile's, such as one being typed
  /// into the profile form.
  final String? imageUrl;

  /// Diameter in logical pixels.
  final double size;

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
    final explicit = imageUrl ?? user?.avatarRef;
    if (explicit != null && explicit.startsWith('http')) {
      return explicit;
    }
    if (user != null && user.id == ref.watch(currentUserIdProvider)) {
      final gh = ref.watch(githubUserProvider).value;
      if (gh != null && gh.avatarUrl.isNotEmpty) {
        return gh.avatarUrl;
      }
    }
    return null;
  }
}
