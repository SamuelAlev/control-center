import 'package:control_center/core/network/models/github_user_profile.dart';
import 'package:control_center/core/theme/design_system_palette.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/shared/widgets/charts/activity_heatmap.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Renders a GitHub user's avatar, name, @login, bio, and optionally a
/// contribution heatmap. Shared between the hover card and the profile page.
class GitHubUserProfileHeader extends StatelessWidget {
/// Creates a [GitHubUserProfileHeader].
  const GitHubUserProfileHeader({
    super.key,
    required this.profile,
    this.avatarSize = 56,
    this.heatmapWeeks = 26,
    this.showHeatmap = true,
    // When true the heatmap sits beside the avatar/info block instead of
    // below it — suits wide layouts like the full profile page.
    this.heatmapInline = false,
    // Optional widget appended at the bottom of the name/bio column.
    this.infoFooter,
    // Optional widget rendered to the right of the display name.
    this.nameTrailing,
  });

/// The GitHub user profile data to display.
  final GitHubUserProfile profile;
/// The size of the avatar in logical pixels.
  final double avatarSize;
/// Number of weeks to show in the contribution heatmap.
  final int heatmapWeeks;
/// Whether to show the contribution heatmap.
  final bool showHeatmap;
/// When true, the heatmap sits beside the avatar/info block instead of below it.
  final bool heatmapInline;
/// Optional widget appended at the bottom of the name/bio column.
  final Widget? infoFooter;
/// Optional widget rendered to the right of the display name.
  final Widget? nameTrailing;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final initial =
        profile.login.isNotEmpty ? profile.login[0].toUpperCase() : '?';

    final avatar = profile.avatarUrl.isNotEmpty
        ? FAvatar(
            image: NetworkImage(profile.avatarUrl),
            size: avatarSize,
            fallback: FAvatar.raw(size: avatarSize, child: Text(initial)),
          )
        : FAvatar.raw(size: avatarSize, child: Text(initial));

    final infoBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (profile.name.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  profile.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (nameTrailing != null) ...[
                const SizedBox(width: 8),
                nameTrailing!,
              ],
            ],
          ),
        Text(
          '@${profile.login}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: tokens.textTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (profile.bio != null && profile.bio!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            profile.bio!,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: tokens.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (infoFooter != null) ...[
          const SizedBox(height: 10),
          infoFooter!,
        ],
      ],
    );

    final heatmap = showHeatmap && profile.contributionCalendar != null
        ? _buildHeatmap(tokens, theme, isDark, profile.contributionCalendar!)
        : null;

    if (heatmapInline && heatmap != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          avatar,
          const SizedBox(width: 16),
          Expanded(child: infoBlock),
          const SizedBox(width: 20),
          heatmap,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            avatar,
            const SizedBox(width: 12),
            Expanded(child: infoBlock),
          ],
        ),
        if (heatmap != null) ...[
          const SizedBox(height: 14),
          heatmap,
        ],
      ],
    );
  }

  Widget _buildHeatmap(
    DesignSystemTokens tokens,
    ThemeData theme,
    bool isDark,
    GitHubContributionCalendar calendar,
  ) {
    final data = <DateTime, ActivityCell>{};
    for (final week in calendar.weeks) {
      for (final day in week.contributionDays) {
        final key = DateTime(day.date.year, day.date.month, day.date.day);
        data[key] = ActivityCell(runsCompleted: day.contributionCount);
      }
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: tokens.bgSecondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ActivityHeatmap(
            data: data,
            weeks: heatmapWeeks,
            cellSize: 10,
            cellGap: 2,
            cellRadius: 2,
            showLegend: false,
            palette: isDark ? _brandBlueDark : _brandBlueLight,
            tooltipBuilder: _contributionTooltip,
          ),
          const SizedBox(height: 6),
          Text(
            '${_formatNumber(calendar.totalContributions)} contributions in the last year',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: tokens.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  static const _brandBlueLight = [
    DesignSystemPalette.gray100,
    DesignSystemPalette.brand100,
    DesignSystemPalette.brand300,
    DesignSystemPalette.brand500,
    DesignSystemPalette.brand600,
  ];

  static const _brandBlueDark = [
    DesignSystemPalette.gray800,
    DesignSystemPalette.brand950,
    DesignSystemPalette.brand700,
    DesignSystemPalette.brand500,
    DesignSystemPalette.brand400,
  ];

  static String _formatNumber(int n) {
    if (n >= 1000) {
      final k = n / 1000;
      return '${k.toStringAsFixed(k < 10 ? 1 : 0)}k';
    }
    return n.toString();
  }

  static String _contributionTooltip(DateTime date, ActivityCell cell) {
    final count = cell.runsCompleted;
    final formatted = _formatLongDate(date);
    if (count == 0) {
      return 'No contributions on $formatted';
    }
    return '$count ${count == 1 ? 'contribution' : 'contributions'} on $formatted';
  }

  static String _formatLongDate(DateTime d) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
