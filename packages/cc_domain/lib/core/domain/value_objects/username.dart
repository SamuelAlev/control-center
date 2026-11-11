import 'package:cc_domain/src/errors/app_exceptions.dart';

/// Why a username was refused.
enum UsernameRefusal {
  /// Not 2 to 32 characters of `a-z0-9._-` starting and ending with `a-z0-9`.
  invalid('invalid', 'username_invalid'),

  /// One of [Username.reserved].
  reserved('reserved', 'username_reserved'),

  /// Another user already has it.
  taken('taken', 'username_taken');

  const UsernameRefusal(this.wire, this.errorKind);

  /// The `users.checkHandle` `reason` spelling.
  final String wire;

  /// The RPC error `data.kind` a refused write carries.
  final String errorKind;
}

/// A username a write refused. Clients localise it from [reason]
/// (RPC `data.kind`), never from [message].
class UsernameRefusedException extends ValidationException {
  /// Creates the refusal for [reason].
  UsernameRefusedException(this.reason) : super(_messageFor(reason));

  /// Why the name was refused.
  final UsernameRefusal reason;

  static String _messageFor(UsernameRefusal reason) => switch (reason) {
    UsernameRefusal.invalid =>
      'A username is 2 to 32 lowercase letters, digits, ".", "_" or "-", '
          'starting and ending with a letter or digit.',
    UsernameRefusal.reserved => 'That username is reserved.',
    UsernameRefusal.taken => 'That username is taken.',
  };
}

/// A person's username: the one rule for what `User.handle` may hold.
///
/// Lowercase; 2 to 32 characters; `a-z0-9`, `.`, `_` and `-`, starting and
/// ending with `a-z0-9`; never one of [reserved]. Every writer of a handle
/// goes through this type: a name a person types ([Username.parse]), a name
/// derived from free text such as an OS account, an IdP claim or an email
/// address ([Username.fromFreeText]), and the next free name when the wanted
/// one is taken ([candidates]). Uniqueness is the repository's to enforce.
final class Username {
  const Username._(this.value);

  /// Parses what a person typed: trimmed and lowercased
  /// ([normalizeInput]), then checked. Throws [UsernameRefusedException]
  /// ([UsernameRefusal.invalid] or [UsernameRefusal.reserved]).
  factory Username.parse(String raw) {
    final normalized = normalizeInput(raw);
    final refusal = check(normalized);
    if (refusal != null) {
      throw UsernameRefusedException(refusal);
    }
    return Username._(normalized);
  }

  /// Derives a username from free text (an OS account name, an IdP claim,
  /// a display name or an email address, whose local part is used). Never
  /// throws: when nothing usable is left, [fallback] (itself a valid
  /// username) is the answer.
  factory Username.fromFreeText(String text, {required String fallback}) {
    var s = text.trim();
    final at = s.indexOf('@');
    if (at > 0) {
      s = s.substring(0, at);
    }
    s = s
        .toLowerCase()
        .replaceAll(_outside, '-')
        .replaceAll(_edgePunctuation, '');
    if (s.length > maxLength) {
      s = s.substring(0, maxLength).replaceAll(_edgePunctuation, '');
    }
    return check(s) == null ? Username._(s) : Username.parse(fallback);
  }

  /// Shortest username.
  static const int minLength = 2;

  /// Longest username.
  static const int maxLength = 32;

  /// The whole syntax rule, length included.
  static final RegExp pattern = RegExp(r'^[a-z0-9][a-z0-9._-]{0,30}[a-z0-9]$');

  /// Names nobody may hold, because a mention of them means something else
  /// or would read as the product itself.
  static const Set<String> reserved = {
    'system',
    'agent',
    'everyone',
    'here',
    'channel',
    'usectrl',
    'me',
  };

  static final RegExp _outside = RegExp('[^a-z0-9._-]+');
  static final RegExp _edgePunctuation = RegExp(r'^[._-]+|[._-]+$');

  /// What a typed name is stored as before it is checked: trimmed and
  /// lowercased, nothing else rewritten.
  static String normalizeInput(String raw) => raw.trim().toLowerCase();

  /// Why [value] (already normalised) is not a username, or null when it is.
  /// Says nothing about uniqueness.
  static UsernameRefusal? check(String value) {
    if (!pattern.hasMatch(value)) {
      return UsernameRefusal.invalid;
    }
    if (reserved.contains(value)) {
      return UsernameRefusal.reserved;
    }
    return null;
  }

  /// Whether [value] is a valid, unreserved username as stored.
  static bool isValid(String value) => check(value) == null;

  /// The names to try, in order, when [base] may be taken: [base] itself,
  /// then `base2`, `base3` and so on, the base shortened so each candidate
  /// still fits [maxLength]. Endless; the caller stops at the first free one.
  static Iterable<Username> candidates(Username base) sync* {
    yield base;
    for (var n = 2; ; n++) {
      final suffix = '$n';
      final room = maxLength - suffix.length;
      final stem = base.value.length > room
          ? base.value.substring(0, room)
          : base.value;
      yield Username._('$stem$suffix');
    }
  }

  /// The stored spelling.
  final String value;

  @override
  bool operator ==(Object other) => other is Username && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
