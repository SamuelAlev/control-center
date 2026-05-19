import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';

/// Pr commit.
class PrCommit {
  /// PrCommit.
  const PrCommit({
    required this.sha,
    required this.message,
    required this.author,
    required this.date,
  });

  /// sha.
  final String sha;

  /// message.
  final String message;

  /// Author of the commit.
  final PrUser? author;

  /// Commit date.
  final DateTime? date;

  /// Short sha.
  String get shortSha => sha.length >= 7 ? sha.substring(0, 7) : sha;

  /// Title.
  String get title {
    final newline = message.indexOf('\n');
    return newline == -1 ? message : message.substring(0, newline);
  }

  /// Equality comparison.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrCommit && runtimeType == other.runtimeType && sha == other.sha;

  /// Hash code.
  @override
  int get hashCode => sha.hashCode;
}
