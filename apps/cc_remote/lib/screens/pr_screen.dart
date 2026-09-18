import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/classify_pr_inbox_use_case.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/pr_needs_your_review.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/pr_providers.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/pr/pr_notices.dart';
import 'package:cc_remote/widgets/pr_row.dart';
import 'package:cc_remote/widgets/touch_target.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The lenses the phone's PR queue offers.
enum PrLens { all, needsMe, mine, blocked }

extension _PrLensLabel on PrLens {
  String label(AppLocalizations l10n) => switch (this) {
    PrLens.all => l10n.all,
    PrLens.needsMe => l10n.lensNeedsMe,
    PrLens.mine => l10n.lensMine,
    PrLens.blocked => l10n.blocked,
  };
}

/// PRs tab: every open pull request across EVERY repo linked to the active
/// workspace, from the server's own poller snapshot.
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
      await RpcOpenPrListRepository(
        client,
      ).refreshOpenForWorkspace(workspaceId);
    } catch (_) {
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
            const NoForgeNotice()
          else
            InaccessibleReposNotice(
              repos: snapshot.value?.inaccessibleRepos ?? const [],
            ),
          Expanded(
            child: items.when(
              loading: () => const Center(child: CcSpinner(size: 24)),
              error: (e, _) => CcEmptyState(
                icon: AppIcons.triangleAlert,
                message: AppLocalizations.of(context).prsLoadFailed,
                description: e.toString(),
              ),
              data: (all) {
                final l10n = AppLocalizations.of(context);
                final visible = _apply(_lens, all, logins, teams);
                if (visible.isEmpty) {
                  return CcEmptyState(
                    icon: AppIcons.gitPullRequest,
                    message: switch (_lens) {
                      PrLens.all => l10n.noOpenPullRequests,
                      PrLens.needsMe => l10n.nothingWaitingOnReview,
                      PrLens.mine => l10n.noOwnOpenPullRequests,
                      PrLens.blocked => l10n.nothingBlocked,
                    },
                    description: _lens == PrLens.all
                        ? l10n.prsEmptyDescription
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
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 4, 0),
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
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: CcChip(
                        label: lens.label(l10n),
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
            semanticLabel: l10n.refreshPullRequests,
            onPressed: _refreshing ? null : _refresh,
            color: _refreshing ? t.fgDisabled : t.fgSecondary,
            iconSize: 18,
          ),
        ],
      ),
    );
  }

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
