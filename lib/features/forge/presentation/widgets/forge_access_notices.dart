import 'package:cc_domain/core/domain/value_objects/repo_access.dart';
import 'package:control_center/features/forge/presentation/widgets/hidden_repos_notice.dart';
import 'package:control_center/features/forge/presentation/widgets/repo_access_banner.dart';
import 'package:flutter/widgets.dart';

/// Everything a pull request list leaves out, above the list: repositories
/// hidden from the reader ([HiddenReposNotice]) and repositories automation
/// cannot reach ([RepoAccessBanner]). Renders nothing when both are empty.
class ForgeAccessNotices extends StatelessWidget {
  /// Creates a [ForgeAccessNotices].
  const ForgeAccessNotices({
    super.key,
    required this.hidden,
    required this.repoAccess,
  });

  /// Repositories left out of the reader's view, as counts.
  final List<HiddenRepos> hidden;

  /// Repositories automation cannot reach.
  final List<RepoAccessIssue> repoAccess;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      HiddenReposNotice(hidden: hidden),
      RepoAccessBanner(issues: repoAccess),
    ],
  );
}
