import 'dart:async';

import 'package:cc_domain/core/domain/entities/github_team_profile.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/providers/github_team_profile_provider.dart';
import 'package:control_center/shared/widgets/github_team_avatar.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Adds a lazy GitHub team hover card to [child].
///
/// The card stays informational and pointer-transparent. The wrapped target
/// owns navigation, so the same preview works for mentions, reviewer rows and
/// any future team chip without duplicating route behavior.
class GitHubTeamHoverTarget extends StatefulWidget {
  /// Creates a hover target for an organization team.
  const GitHubTeamHoverTarget({
    super.key,
    required this.organization,
    required this.slug,
    required this.child,
    this.showDelay = const Duration(milliseconds: 450),
    this.targetAnchor = AlignmentDirectional.bottomStart,
    this.followerAnchor = AlignmentDirectional.topStart,
  });

  /// Organization login that owns the team.
  final String organization;

  /// Team slug.
  final String slug;

  /// Interactive team surface wrapped by the preview.
  final Widget child;

  /// Hover dwell before the card appears.
  final Duration showDelay;

  /// Point on the target used for alignment.
  final AlignmentGeometry targetAnchor;

  /// Point on the card aligned to [targetAnchor].
  final AlignmentGeometry followerAnchor;

  @override
  State<GitHubTeamHoverTarget> createState() => _GitHubTeamHoverTargetState();
}

class _GitHubTeamHoverTargetState extends State<GitHubTeamHoverTarget> {
  final CcOverlayController _controller = CcOverlayController();
  Timer? _timer;

  bool get _active =>
      widget.organization.trim().isNotEmpty && widget.slug.trim().isNotEmpty;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onEnter() {
    if (!_active) {
      return;
    }
    _timer?.cancel();
    _timer = Timer(widget.showDelay, () {
      if (mounted) {
        _controller.show();
      }
    });
  }

  void _onExit() {
    _timer?.cancel();
    _timer = null;
    _controller.hide();
  }

  @override
  Widget build(BuildContext context) {
    if (!_active) {
      return widget.child;
    }
    return MouseRegion(
      onEnter: (_) => _onEnter(),
      onExit: (_) => _onExit(),
      child: CcOverlayAnchor(
        controller: _controller,
        targetAnchor: widget.targetAnchor,
        followerAnchor: widget.followerAnchor,
        offset: const Offset(0, 6),
        barrierDismissible: false,
        target: widget.child,
        overlayBuilder: (context, _) => _TeamHoverCard(
          organization: widget.organization,
          slug: widget.slug,
        ),
      ),
    );
  }
}

class _TeamHoverCard extends ConsumerWidget {
  const _TeamHoverCard({required this.organization, required this.slug});

  final String organization;
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final key = (organization: organization, slug: slug);
    final profile = ref.watch(githubTeamProfileProvider(key));
    return IgnorePointer(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 240, maxWidth: 320),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: t.bgPrimary,
            border: Border.all(color: t.borderSecondary),
            borderRadius: AppRadii.brSm,
            boxShadow: AppShadows.golden,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: profile.when(
              loading: () =>
                  _TeamCardBody(organization: organization, slug: slug),
              error: (_, _) =>
                  _TeamCardBody(organization: organization, slug: slug),
              data: (team) => _TeamCardBody(
                organization: organization,
                slug: slug,
                profile: team,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TeamCardBody extends StatelessWidget {
  const _TeamCardBody({
    required this.organization,
    required this.slug,
    this.profile,
  });

  final String organization;
  final String slug;
  final GitHubTeamProfile? profile;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final name = profile?.name ?? slug;
    final members = profile?.members ?? const <GitHubTeamMember>[];
    final memberCount = profile?.memberCount ?? members.length;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GitHubTeamAvatar(
              name: name,
              avatarUrl: profile?.avatarUrl ?? '',
              size: 40,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CcTypography.label.copyWith(color: t.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '@$organization/$slug',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CcTypography.caption.copyWith(color: t.textTertiary),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (profile?.description?.trim().isNotEmpty == true) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            profile!.description!.trim(),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: CcTypography.bodySm.copyWith(color: t.textSecondary),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            if (members.isNotEmpty) ...[
              for (final member in members.take(5)) ...[
                GitHubUserAvatar(
                  login: member.login,
                  avatarUrl: member.avatarUrl,
                  size: 24,
                  showHoverCard: false,
                ),
                const SizedBox(width: AppSpacing.xxs),
              ],
              const SizedBox(width: AppSpacing.xs),
            ],
            Expanded(
              child: Text(
                l10n.profileTeamMembers(memberCount),
                style: CcTypography.caption.copyWith(color: t.textSecondary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
