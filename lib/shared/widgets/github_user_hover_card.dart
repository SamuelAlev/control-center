import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/providers/github_user_profile_provider.dart';
import 'package:control_center/shared/widgets/github_user_profile_header.dart';
import 'package:control_center/shared/widgets/github_user_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A hover card that displays a GitHub user's profile summary.
class GitHubUserHoverCard extends ConsumerWidget {
/// Creates a [GitHubUserHoverCard].
  const GitHubUserHoverCard({
    super.key,
    required this.login,
    this.onClose,
  });

/// The GitHub login (username) of the user to display.
  final String login;

  /// Called when the card should close itself (e.g. before navigating away).
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.designSystem!;
    final theme = Theme.of(context);
    final profileAsync = ref.watch(githubUserProfileProvider(login));

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      color: tokens.bgPrimary,
      child: Container(
        width: 400,
        constraints: const BoxConstraints(maxHeight: 480),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tokens.borderSecondary),
        ),
        child: profileAsync.when(
          loading: () => const SizedBox(
            height: 120,
            child: Center(child: FCircularProgress()),
          ),
          error: (err, _) => SizedBox(
            height: 80,
            child: Center(
              child: Text(
                err.toString(),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: tokens.textTertiary,
                ),
              ),
            ),
          ),
          data: (profile) {
            if (profile == null) {
              return SizedBox(
                height: 80,
                child: Center(
                  child: Text(
                    'User not found',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tokens.textTertiary,
                    ),
                  ),
                ),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GitHubUserProfileHeader(
                    profile: profile,
                    nameTrailing: profile.status != null &&
                            statusHasContent(profile.status!)
                        ? GitHubUserStatusBadge(status: profile.status!)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  FTappable.static(
                    onPress: () {
                      onClose?.call();
                      GoRouter.of(context).go(userProfileRoute(profile.login));
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppLocalizations.of(context).viewProfile,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: tokens.textTertiary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          LucideIcons.arrowUpRight,
                          size: 12,
                          color: tokens.textTertiary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
