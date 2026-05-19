import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Per-login free-text search over a profile's PR titles. The profile is
/// already scoped to one author, so this filters the loaded set locally (by
/// title / number) rather than issuing a server search.
class UserProfileSearchNotifier extends Notifier<String> {
  /// Creates a [UserProfileSearchNotifier] for [login].
  UserProfileSearchNotifier(this.login);

  /// The GitHub login this search belongs to.
  final String login;

  @override
  String build() => '';

  /// Replaces the search text.
  void set(String value) => state = value;

  /// Clears the search text.
  void clear() => state = '';
}

/// Provides the profile search text, keyed by login.
final userProfileSearchProvider =
    NotifierProvider.family<UserProfileSearchNotifier, String, String>(
      UserProfileSearchNotifier.new,
    );
