part of 'team_profile_screen.dart';

class _TeamHeader extends StatelessWidget {
  const _TeamHeader({
    required this.organization,
    required this.slug,
    required this.profile,
  });

  final String organization;
  final String slug;
  final AsyncValue<GitHubTeamProfile?> profile;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final fallback = '@$organization/$slug';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.bgSecondary,
        border: Border.all(color: t.borderSecondary),
        borderRadius: AppRadii.brSm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: profile.when(
          loading: () =>
              const SizedBox(height: 88, child: Center(child: CcSpinner())),
          error: (_, _) => Text(
            fallback,
            style: CcTypography.body.copyWith(color: t.textPrimary),
          ),
          data: (team) => team == null
              ? Text(
                  fallback,
                  style: CcTypography.body.copyWith(color: t.textPrimary),
                )
              : _TeamHeaderData(profile: team),
        ),
      ),
    );
  }
}

class _TeamHeaderData extends StatelessWidget {
  const _TeamHeaderData({required this.profile});

  final GitHubTeamProfile profile;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final memberCount = profile.memberCount ?? profile.members.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GitHubTeamAvatar(
              name: profile.name,
              avatarUrl: profile.avatarUrl,
              size: 64,
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: CcTypography.title.copyWith(color: t.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '@${profile.organization}/${profile.slug}',
                    style: CcTypography.bodySm.copyWith(color: t.textSecondary),
                  ),
                  if (profile.description?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      profile.description!,
                      style: CcTypography.bodySm.copyWith(
                        color: t.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (profile.url.isNotEmpty)
              CcButton(
                variant: CcButtonVariant.secondary,
                size: CcButtonSize.sm,
                onPressed: () => openExternalUrl(profile.url),
                child: Text(l10n.openOnGithub),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.profileTeamMembers(memberCount),
          style: CcTypography.label.copyWith(color: t.textSecondary),
        ),
        if (profile.members.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: profile.members.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) =>
                  _MemberChip(member: profile.members[index]),
            ),
          ),
        ],
      ],
    );
  }
}

class _MemberChip extends StatelessWidget {
  const _MemberChip({required this.member});

  final GitHubTeamMember member;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final label = member.name.isNotEmpty ? member.name : member.login;
    return GitHubUserHoverTarget(
      login: member.login,
      child: CcTappable(
        onPressed: () => context.go(
          userProfileRoute(context.currentWorkspaceId!, member.login),
        ),
        semanticLabel: '@${member.login}',
        borderRadius: AppRadii.brSm,
        builder: (context, states) => DecoratedBox(
          decoration: BoxDecoration(
            color: states.contains(WidgetState.hovered)
                ? t.bgTertiary
                : t.bgPrimary,
            border: Border.all(color: t.borderSecondary),
            borderRadius: AppRadii.brSm,
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(6, 4, 10, 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GitHubUserAvatar(
                  login: member.login,
                  avatarUrl: member.avatarUrl,
                  size: 24,
                  showHoverCard: false,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label,
                  style: CcTypography.caption.copyWith(color: t.textPrimary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
