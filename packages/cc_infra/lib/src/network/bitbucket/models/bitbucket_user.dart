import 'package:cc_infra/src/network/bitbucket/models/bitbucket_json.dart';

/// A Bitbucket Cloud account, as embedded in pull requests, commits, comments,
/// participants and workspace memberships.
///
/// Bitbucket identifies an account by [uuid] (the stable, opaque handle every
/// write API expects) and [accountId] (the Atlassian-wide id). There is no
/// GitHub-style immutable `login`: [nickname] is the user-changeable handle and
/// [displayName] their full name, and either may be withheld by the account's
/// privacy settings.
class BitbucketUser {
  /// Creates a [BitbucketUser].
  const BitbucketUser({
    required this.uuid,
    required this.accountId,
    required this.nickname,
    required this.displayName,
    required this.avatarUrl,
    this.htmlUrl = '',
  });

  /// Decodes a Bitbucket `user` / `account` object.
  factory BitbucketUser.fromJson(Map<String, dynamic> json) => BitbucketUser(
    uuid: json['uuid'] as String? ?? '',
    accountId: json['account_id'] as String? ?? '',
    nickname: json['nickname'] as String? ?? '',
    displayName: json['display_name'] as String? ?? '',
    avatarUrl: linkHref(json['links'], 'avatar'),
    htmlUrl: linkHref(json['links'], 'html'),
  );

  /// Braced opaque account id (`{9d0a4c6f-…}`). This is what the reviewer
  /// write APIs key on — never the [nickname].
  final String uuid;

  /// Atlassian account id (`557057:9d0a4c6f-…`).
  final String accountId;

  /// User-changeable handle. Empty when the account withholds it.
  final String nickname;

  /// Full name. Empty when the account withholds it.
  final String displayName;

  /// Avatar image URL (`links.avatar.href`).
  final String avatarUrl;

  /// Profile page URL (`links.html.href`).
  final String htmlUrl;

  /// The best available human-readable handle: [nickname] when the account
  /// publishes one, else [accountId].
  ///
  /// This is what maps onto the domain's `PrUser.login` — Bitbucket has no
  /// login, so the handle a human would type is the closest true equivalent
  /// and [accountId] is the stable fallback.
  String get handle => nickname.isNotEmpty ? nickname : accountId;

  /// Serializes back to the Bitbucket JSON shape.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'uuid': uuid,
    'account_id': accountId,
    'nickname': nickname,
    'display_name': displayName,
    'links': <String, dynamic>{
      'avatar': <String, dynamic>{'href': avatarUrl},
      'html': <String, dynamic>{'href': htmlUrl},
    },
  };
}
