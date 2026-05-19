import 'package:cc_infra/src/network/bitbucket/models/bitbucket_json.dart';
import 'package:cc_infra/src/network/bitbucket/models/bitbucket_user.dart';
import 'package:cc_infra/src/network/models/date_parser.dart';

/// A commit as returned by Bitbucket's commit endpoints.
///
/// The git identity (`author.raw`, `Name <email>`) and the Bitbucket account
/// (`author.user`) are separate: a commit authored with an email nobody has
/// registered has a [rawAuthor] but no [author].
class BitbucketCommit {
  /// Creates a [BitbucketCommit].
  const BitbucketCommit({
    required this.hash,
    required this.message,
    this.date,
    this.author,
    this.rawAuthor = '',
    this.htmlUrl = '',
  });

  /// Decodes a Bitbucket `commit` object.
  factory BitbucketCommit.fromJson(Map<String, dynamic> json) {
    final author = asJsonMap(json['author']);
    final user = asJsonMap(author?['user']);
    return BitbucketCommit(
      hash: json['hash'] as String? ?? '',
      message: json['message'] as String? ?? '',
      date: parseDate(json['date']),
      author: user == null ? null : BitbucketUser.fromJson(user),
      rawAuthor: author?['raw'] as String? ?? '',
      htmlUrl: linkHref(json['links'], 'html'),
    );
  }

  /// Full 40-character commit hash.
  final String hash;

  /// Full commit message (first line is the title).
  final String message;

  /// Commit timestamp.
  final DateTime? date;

  /// The Bitbucket account matching the commit's author email, when one is
  /// registered.
  final BitbucketUser? author;

  /// The raw git author string, `Name <email>`.
  final String rawAuthor;

  /// Web URL for the commit.
  final String htmlUrl;

  /// The name half of [rawAuthor] (everything before the `<email>`), used when
  /// the commit has no linked Bitbucket account.
  String get rawAuthorName {
    final bracket = rawAuthor.indexOf('<');
    if (bracket < 0) {
      return rawAuthor.trim();
    }
    return rawAuthor.substring(0, bracket).trim();
  }
}
