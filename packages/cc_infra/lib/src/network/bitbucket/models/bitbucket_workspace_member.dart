import 'package:cc_infra/src/network/bitbucket/models/bitbucket_json.dart';
import 'package:cc_infra/src/network/bitbucket/models/bitbucket_user.dart';

/// One row of `GET /workspaces/{workspace}/members`.
///
/// Bitbucket has no per-repository assignee or reviewer roster: the pool of
/// people who can be asked to review anything in a repository is the workspace
/// membership, so this is the candidate list every picker is built from. It is
/// also the only place to resolve a human-readable handle back to the
/// `BitbucketUser.uuid` that the reviewer write API insists on.
class BitbucketWorkspaceMember {
  /// Creates a [BitbucketWorkspaceMember].
  const BitbucketWorkspaceMember({required this.user, this.workspaceSlug = ''});

  /// Decodes a Bitbucket `workspace_membership` object.
  factory BitbucketWorkspaceMember.fromJson(Map<String, dynamic> json) {
    final user = asJsonMap(json['user']);
    return BitbucketWorkspaceMember(
      user: user == null ? null : BitbucketUser.fromJson(user),
      workspaceSlug: asJsonMap(json['workspace'])?['slug'] as String? ?? '',
    );
  }

  /// The member's account. Null when Bitbucket omitted it.
  final BitbucketUser? user;

  /// Slug of the workspace this membership belongs to.
  final String workspaceSlug;
}
