import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/open_pr_list_repository.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/classify_pr_inbox_use_case.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/pr_needs_your_review.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/pr_providers.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/pr_row.dart';
import 'package:cc_remote/widgets/touch_target.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The lenses the phone's PR queue offers.
///
/// Deliberately four, not the desktop's full filter menu: a phone is where
/// you triage, and the questions that get asked standing up are "what wants
/// me", "where are mine" and "what is red". The rest of the axes (labels,
/// date windows, reviewer facets) stay on the desk.
enum PrLens {
  /// Every open PR in the workspace, across every linked repo.
  all,

  /// Open PRs whose review request names the operator (or a team they are
  /// still pending on).
  needsMe,

  /// The operator's own open PRs.
  mine,

  /// Open PRs with failing checks or changes requested.
  blocked,
}

extension _PrLensLabel on PrLens {
  String get label => switch (this) {
    PrLens.all => 'All',
    PrLens.needsMe => 'Needs me',
    PrLens.mine => 'Mine',
    PrLens.blocked => 'Blocked',
  };
}

/// PRs tab: every open pull request across EVERY repo linked to the active
/// workspace, from the server's own poller snapshot
/// (`pr.watchOpenForWorkspace`) — the same feed the desktop queue renders, so
/// the two never disagree about what is open.
class PrScreen extends ConsumerStatefulWidget {
  /// Creates a [PrScreen].
  const PrScreen({super.key});

  @override
  ConsumerState<PrScreen> createState() => _PrScreenState();
}

class _PrScreenState extends ConsumerState<PrScreen> {
  PrLens _lens = PrLens.all;
  bool _refreshing = false;

  Future<void> _refresh() async {
    final client = ref.read(rpcClientProvider).value;
    final workspaceId = ref.read(activeWorkspaceIdProvider).value;
    if (client == null || workspaceId == null || _refreshing) {
      return;
    }
    setState(() => _refreshing = true);
    try {
      await RpcOpenPrListRepository(client).refreshOpenForWorkspace(
        workspaceId,
      );
    } catch (_) {
      // The live snapshot keeps rendering — a failed sweep is not a reason to
      // blank the list, and the server retries on its own cadence.
    } finally {
      if (mounted) {
        setState(() => _refreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final snapshot = ref.watch(openPrsProvider);
    final items = ref.watch(flatOpenPrsProvider);
    final logins = ref.watch(viewerLoginsProvider).value ?? const {};
    final teams = ref.watch(viewerTeamsProvider).value ?? const {};

    return ColoredBox(
      color: t.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _toolbar(t),
          if (snapshot.value?.authenticated == false)
            const _NoForgeNotice()
          else if (snapshot.value?.inaccessibleRepos.isNotEmpty ?? false)
            _InaccessibleNotice(repos: snapshot.value!.inaccessibleRepos),
          Expanded(
            child: items.when(
              loading: () => const Center(child: CcSpinner(size: 24)),
              error: (e, _) => CcEmptyState(
                icon: AppIcons.triangleAlert,
                message: "Couldn't load pull requests",
                description: e.toString(),
              ),
              data: (all) {
                final visible = _apply(_lens, all, logins, teams);
                if (visible.isEmpty) {
                  return CcEmptyState(
                    icon: AppIcons.gitPullRequest,
                    message: switch (_lens) {
                      PrLens.all => 'No open pull requests',
                      PrLens.needsMe => 'Nothing waiting on your review',
                      PrLens.mine => 'You have no open pull requests',
                      PrLens.blocked => 'Nothing blocked',
                    },
                    description: _lens == PrLens.all
                        ? 'Pull requests across this workspace’s repos '
                              'appear here.'
                        : null,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => PrRow(item: visible[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolbar(DesignSystemTokens t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final lens in PrLens.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: CcChip(
                        label: lens.label,
                        selected: _lens == lens,
                        onPressed: () => setState(() => _lens = lens),
                      ),
                    ),
                ],
              ),
            ),
          ),
          PhoneIconButton(
            icon: AppIcons.refreshCw,
            semanticLabel: 'Refresh pull requests',
            onPressed: _refreshing ? null : _refresh,
            color: _refreshing ? t.fgDisabled : t.fgSecondary,
            iconSize: 18,
          ),
        ],
      ),
    );
  }

  /// Narrows [all] through [lens]. "Mine" and "Needs me" resolve the operator
  /// PER FORGE — the same human has a different login on each, so one global
  /// name would silently drop every PR on the other forges.
  List<PrInboxItem> _apply(
    PrLens lens,
    List<PrInboxItem> all,
    Map<ForgeHost, String> logins,
    Map<String, Set<String>> teams,
  ) {
    switch (lens) {
      case PrLens.all:
        return all;
      case PrLens.mine:
        return [
          for (final i in all)
            if ((logins[i.repo.forge] ?? '').isNotEmpty &&
                i.pr.author?.login.toLowerCase() == logins[i.repo.forge])
              i,
        ];
      case PrLens.needsMe:
        return [
          for (final i in all)
            if (prNeedsYourReview(
              isDraft: i.pr.isDraft,
              authorLogin: i.pr.author?.login,
              viewerLogin: logins[i.repo.forge] ?? '',
              requestedUserLogins: i.pr.requestedReviewers.map((u) => u.login),
              requestedTeamSlugs: i.pr.requestedTeamSlugs,
              repoFullName: i.pr.repoFullName,
              viewerTeamsByOrg: teams,
            ))
              i,
        ];
      case PrLens.blocked:
        return [
          for (final i in all)
            if (i.pr.checksStatus == PrChecksStatus.failing ||
                i.pr.reviewDecision == PrReviewDecision.changesRequested)
              i,
        ];
    }
  }
}

/// No forge credential reached the server, so the poller has nothing to poll.
/// Says so instead of rendering a convincing "no open pull requests".
class _NoForgeNotice extends StatelessWidget {
  const _NoForgeNotice();

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.warnSoft,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(AppIcons.cloudOff, size: 16, color: t.textWarningPrimary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'No forge is connected on the server, so no pull requests '
                  'can be fetched. Connect one from the desktop app.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: t.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Repos the poller parked as unreachable — typically the app is not installed
/// on that org. Naming them is the difference between "this repo has no open
/// PRs" and "this repo was never asked".
class _InaccessibleNotice extends StatelessWidget {
  const _InaccessibleNotice({required this.repos});

  final List<InaccessibleRepo> repos;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final names = repos.map((r) => r.repoFullName).where((n) => n.isNotEmpty);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.warnSoft,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                AppIcons.triangleAlert,
                size: 16,
                color: t.textWarningPrimary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  names.isEmpty
                      ? '${repos.length} repo(s) could not be read.'
                      : 'Not readable: ${names.join(', ')}',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: t.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
