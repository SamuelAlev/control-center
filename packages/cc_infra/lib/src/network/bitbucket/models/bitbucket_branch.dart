import 'package:cc_infra/src/network/bitbucket/models/bitbucket_commit.dart';
import 'package:cc_infra/src/network/bitbucket/models/bitbucket_json.dart';

/// A branch ref (`GET /repositories/{workspace}/{repo}/refs/branches`).
///
/// The `target` is a full commit object, not a bare hash, so it is decoded
/// with [BitbucketCommit] rather than a near-duplicate DTO — the branch tip's
/// date and author are what the compose-PR picker orders and labels by.
class BitbucketBranch {
  /// Creates a [BitbucketBranch].
  const BitbucketBranch({required this.name, this.target});

  /// Decodes a Bitbucket `branch` object.
  factory BitbucketBranch.fromJson(Map<String, dynamic> json) {
    final target = asJsonMap(json['target']);
    return BitbucketBranch(
      name: json['name'] as String? ?? '',
      target: target == null ? null : BitbucketCommit.fromJson(target),
    );
  }

  /// Branch name, already without a `refs/heads/` prefix — Bitbucket returns
  /// the short form here.
  final String name;

  /// The commit the branch points at. Null when Bitbucket omitted it.
  final BitbucketCommit? target;
}
