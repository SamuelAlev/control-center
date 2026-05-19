import 'package:cc_domain/core/domain/entities/github_user.dart';

/// Pr user.
class PrUser {
  /// PrUser.
  const PrUser({required this.login, required this.avatarUrl, this.name});

  /// login.
  final String login;

  /// avatarUrl.
  final String avatarUrl;

  /// GitHub display name, when the API provided one.
  final String? name;

  /// [login], plus display name in parentheses when it differs from [login].
  String get displayLabel => formatGitHubLoginWithName(login, name);

  /// Whether [login] or [name] contains [query] (case-insensitive).
  bool matchesQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return true;
    }
    if (login.toLowerCase().contains(q)) {
      return true;
    }
    final n = name?.trim().toLowerCase();
    return n != null && n.contains(q);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrUser &&
          runtimeType == other.runtimeType &&
          login == other.login;

  @override
  int get hashCode => login.hashCode;
}
