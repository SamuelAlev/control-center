import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Lookup table of GitHub mention keys → avatar URLs for the current surface.
///
/// Keys are lowercase logins (users) or team slugs / `org/slug` / display
/// names (teams). Empty URLs are omitted. Comment chips with no URL of their
/// own read this so `@org/team` can reuse a logo already loaded for reviewers.
class GitHubMentionAvatarScope extends InheritedWidget {
  /// Creates a [GitHubMentionAvatarScope].
  const GitHubMentionAvatarScope({
    super.key,
    required this.avatars,
    required super.child,
  });

  /// Lowercased mention key → avatar URL.
  final Map<String, String> avatars;

  /// Resolves [login] against the nearest scope, or `''` when none / unknown.
  static String lookup(
    BuildContext context, {
    required String login,
    required bool isTeam,
  }) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<GitHubMentionAvatarScope>();
    if (scope == null) {
      return '';
    }
    return resolveGitHubMentionAvatar(
      scope.avatars,
      login: login,
      isTeam: isTeam,
    );
  }

  @override
  bool updateShouldNotify(GitHubMentionAvatarScope oldWidget) =>
      !mapEquals(oldWidget.avatars, avatars);
}

/// Looks up [login] in [avatars]. Team mentions also try the slug after `/`.
String resolveGitHubMentionAvatar(
  Map<String, String> avatars, {
  required String login,
  required bool isTeam,
}) {
  if (login.isEmpty || avatars.isEmpty) {
    return '';
  }
  final lower = login.toLowerCase();
  final direct = avatars[lower];
  if (direct != null && direct.isNotEmpty) {
    return direct;
  }
  if (!isTeam) {
    return '';
  }
  final slash = lower.lastIndexOf('/');
  if (slash <= 0 || slash == lower.length - 1) {
    return '';
  }
  return avatars[lower.substring(slash + 1)] ?? '';
}
