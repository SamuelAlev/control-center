import 'package:cc_domain/core/domain/value_objects/username.dart';

/// The `users.checkHandle` answer.
class UsernameCheck {
  /// Creates a [UsernameCheck].
  const UsernameCheck({
    required this.available,
    required this.normalized,
    this.reason,
  });

  /// Decodes the `users.checkHandle` payload. An unknown `reason` on an
  /// unavailable name reads as [UsernameRefusal.invalid].
  factory UsernameCheck.fromJson(Map<String, dynamic> json) {
    final available = json['available'] == true;
    final reason = json['reason'];
    return UsernameCheck(
      available: available,
      normalized: json['normalized'] as String? ?? '',
      reason: available
          ? null
          : UsernameRefusal.values.where((r) => r.wire == reason).firstOrNull ??
                UsernameRefusal.invalid,
    );
  }

  /// Whether saving this name would succeed right now.
  final bool available;

  /// What would be stored: the input trimmed and lowercased.
  final String normalized;

  /// Why it is unavailable; null when [available].
  final UsernameRefusal? reason;

  @override
  bool operator ==(Object other) =>
      other is UsernameCheck &&
      other.available == available &&
      other.normalized == normalized &&
      other.reason == reason;

  @override
  int get hashCode => Object.hash(available, normalized, reason);
}
