import 'package:cc_data/src/repositories/pr_dto_mapping.dart'
    show prCommitFromWireDto, prFileFromWireDto;
import 'package:cc_domain/cc_domain.dart' show PrCommitDto, PrFileDto;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/ports/forge_pr_client.dart'
    show ForgeBranchComparison;
import 'package:cc_rpc/cc_rpc.dart';

/// One pull-request template a repo offers: a display `name` (empty for the
/// single default), the markdown `body` it seeds and whether it is the repo's
/// one default.
typedef ForgePrTemplate = ({String name, String body, bool isDefault});

/// The compose-PR reads on a repo's own forge, over the `forge.*` ops.
///
/// The server answers on the caller's own credential for [Repo.forge]; the
/// client holds no token. Every call states the repo's forge, so a workspace
/// that links the same `owner/name` on two forges asks the right one.
class RemoteForgeCompose {
  /// Creates a [RemoteForgeCompose] over [_client].
  RemoteForgeCompose(this._client);

  final RemoteRpcClient _client;

  Map<String, dynamic> _coords(Repo repo) => {
    'owner': repo.remoteOwner,
    'repo': repo.remoteName,
    'forge': repo.forge.wire,
  };

  /// Branch names on [repo]'s remote, the caller's own first.
  Future<List<String>> branches(Repo repo) async {
    final data = await _client.call('forge.repoBranches', _coords(repo));
    return (data['branches'] as List? ?? const []).whereType<String>().toList();
  }

  /// [repo]'s default branch, or empty when the forge did not say.
  Future<String> defaultBranch(Repo repo) async {
    final data = await _client.call('forge.defaultBranch', _coords(repo));
    return data['branch'] as String? ?? '';
  }

  /// [repo]'s pull-request templates; empty on a forge without them.
  Future<List<ForgePrTemplate>> templates(Repo repo) async {
    final data = await _client.call('forge.prTemplates', _coords(repo));
    return [
      for (final t in (data['templates'] as List? ?? const [])
          .whereType<Map<Object?, Object?>>())
        (
          name: t['name'] as String? ?? '',
          body: t['body'] as String? ?? '',
          isDefault: t['is_default'] as bool? ?? false,
        ),
    ];
  }

  /// What a pull request from [head] into [base] on [repo] would contain, or
  /// null when the forge cannot compare them.
  Future<ForgeBranchComparison?> compare(
    Repo repo, {
    required String base,
    required String head,
  }) async {
    final data = await _client.call('forge.compareBranches', {
      ..._coords(repo),
      'base': base,
      'head': head,
    });
    final c = data['comparison'];
    if (c is! Map) {
      return null;
    }
    final m = c.cast<String, dynamic>();
    return ForgeBranchComparison(
      files: [
        for (final f in (m['files'] as List? ?? const []).whereType<Map>())
          prFileFromWireDto(PrFileDto.fromJson(f.cast<String, dynamic>())),
      ],
      commits: [
        for (final cm in (m['commits'] as List? ?? const []).whereType<Map>())
          prCommitFromWireDto(PrCommitDto.fromJson(cm.cast<String, dynamic>())),
      ],
      additions: (m['additions'] as num?)?.toInt() ?? 0,
      deletions: (m['deletions'] as num?)?.toInt() ?? 0,
      totalCommits: (m['total_commits'] as num?)?.toInt() ?? 0,
    );
  }
}
