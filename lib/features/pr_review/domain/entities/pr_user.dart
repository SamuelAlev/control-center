/// Pr user.
class PrUser {
  /// PrUser.
  const PrUser({required this.login, required this.avatarUrl});

  /// login.
  final String login;
  /// avatarUrl.
  final String avatarUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrUser &&
          runtimeType == other.runtimeType &&
          login == other.login;

  @override
  int get hashCode => login.hashCode;
}

