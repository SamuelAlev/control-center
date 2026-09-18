import 'package:cc_domain/core/domain/entities/github_team_profile.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/user_profiles/presentation/widgets/profile_delivery_scaffold.dart';
import 'package:control_center/features/user_profiles/presentation/widgets/user_profile_pr_queue.dart';
import 'package:control_center/features/user_profiles/presentation/widgets/user_profile_search_field.dart';
import 'package:control_center/features/user_profiles/providers/user_profile_pr_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/providers/github_team_profile_provider.dart';
import 'package:control_center/shared/providers/last_checked_provider.dart';
import 'package:control_center/shared/utils/open_url.dart';
import 'package:control_center/shared/widgets/github_team_avatar.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:control_center/shared/widgets/github_user_hover_target.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:control_center/shared/widgets/refresh_control.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
part 'team_profile_header.dart';

/// A GitHub team's identity, visible membership and aggregate PR delivery data.
class TeamProfileScreen extends ConsumerStatefulWidget {
  /// Creates a team profile screen.
  const TeamProfileScreen({
    super.key,
    required this.organization,
    required this.slug,
  });

  /// Organization login that owns the team.
  final String organization;

  /// Team slug.
  final String slug;

  @override
  ConsumerState<TeamProfileScreen> createState() => _TeamProfileScreenState();
}

class _TeamProfileScreenState extends ConsumerState<TeamProfileScreen> {
  final FocusNode _searchFocusNode = FocusNode(
    debugLabel: 'team-profile-pr-search',
  );
  bool _refreshing = false;

  ({String organization, String slug}) get _team =>
      (organization: widget.organization, slug: widget.slug);

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_refreshing) {
      return;
    }
    setState(() => _refreshing = true);
    try {
      await Future.wait([
        ref.refresh(githubTeamProfileProvider(_team).future),
        ref.refresh(teamProfileActivityProvider(_team).future),
      ]);
    } catch (_) {
      // Each surface retains its last data or renders its own error.
    } finally {
      if (mounted) {
        setState(() => _refreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(githubTeamProfileProvider(_team));
    final activityAsync = ref.watch(teamProfileActivityProvider(_team));
    final fallback = '@${widget.organization}/${widget.slug}';
    final displayName = profileAsync.value?.name ?? fallback;
    final freshnessKey =
        'team-profile:${widget.organization.toLowerCase()}/${widget.slug.toLowerCase()}';

    ref.listen(teamProfileActivityProvider(_team), (_, next) {
      if (next is AsyncData && !next.isLoading) {
        ref.read(lastCheckedProvider.notifier).stamp(freshnessKey);
      }
    });

    return PageWrapper(
      title: displayName,
      actions: [
        RefreshControl(
          lastChecked: ref.watch(
            lastCheckedProvider.select((value) => value[freshnessKey]),
          ),
          isLoading:
              _refreshing || profileAsync.isLoading || activityAsync.isLoading,
          tooltip: l10n.refresh,
          onRefresh: _refresh,
        ),
        ProfilePrSearchField(
          profileKey:
              'team:${widget.organization.toLowerCase()}/${widget.slug.toLowerCase()}',
          focusNode: _searchFocusNode,
        ),
      ],
      child: ProfileDeliveryScaffold(
        header: _TeamHeader(
          organization: widget.organization,
          slug: widget.slug,
          profile: profileAsync,
        ),
        activity: activityAsync,
        queue: TeamProfilePrQueue(
          organization: widget.organization,
          slug: widget.slug,
          searchFocusNode: _searchFocusNode,
        ),
      ),
    );
  }
}
