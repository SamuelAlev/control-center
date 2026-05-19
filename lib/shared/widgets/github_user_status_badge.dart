import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/network/models/github_user_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_emoji/flutter_emoji.dart';

final _emojiParser = EmojiParser();

/// Returns true if [status] has any visible content (emoji, message, or busy flag).
bool statusHasContent(GitHubUserStatus status) =>
    status.isBusy ||
    status.message?.isNotEmpty == true ||
    status.emoji?.isNotEmpty == true;

/// A pill badge that mirrors GitHub's user status display.
/// Shows an orange border when `status.isBusy` is true, neutral otherwise.
class GitHubUserStatusBadge extends StatelessWidget {
/// Creates a [GitHubUserStatusBadge].
  const GitHubUserStatusBadge({super.key, required this.status});

/// The GitHub user status to display.
  final GitHubUserStatus status;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();

    final rawEmoji = status.emoji;
    final resolvedEmoji =
        rawEmoji != null && rawEmoji.isNotEmpty
            ? _emojiParser.emojify(rawEmoji)
            : null;

    final parts = <String>[
      if (status.isBusy) 'Busy',
      if (resolvedEmoji != null && resolvedEmoji.isNotEmpty) resolvedEmoji,
      if (status.message?.isNotEmpty == true) status.message!,
    ];
    final label = parts.join(' ');

    final orange = tokens.accent;
    final isBusy = status.isBusy;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isBusy ? orange.withValues(alpha: 0.08) : tokens.bgSecondary,
        border: isBusy ? Border.all(color: orange.withValues(alpha: 0.6)) : null,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isBusy ? orange : tokens.textTertiary,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
