import 'package:cc_domain/features/messaging/domain/value_objects/thread_summary.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/utils/avatar_initials.dart';
import 'package:control_center/shared/utils/relative_time.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The "N replies · last reply …" row under a message that started a thread.
///
/// Slack's affordance, and for the same reason: a thread is invisible from its
/// parent stream otherwise, so the anchor message has to say that the
/// conversation continued somewhere else and be the way in. Tapping the row
/// opens (or focuses) the thread's own tab.
///
/// Renders nothing when the message has no thread — the common case, so this
/// is deliberately cheap: the whole space's rollups arrive on one
/// subscription and this is a map lookup.
class ThreadIndicator extends ConsumerWidget {
  /// Creates a [ThreadIndicator] for [summary].
  const ThreadIndicator({
    super.key,
    required this.summary,
    required this.onOpen,
    this.alignEnd = false,
  });

  /// The thread's rollup: reply count, newest reply and who spoke.
  final ThreadSummary summary;

  /// Opens the thread — the host maps it to opening/focusing its tab.
  final void Function(String threadId) onOpen;

  /// Mirrors the row to the right, matching a user bubble's alignment.
  final bool alignEnd;

  /// A participant's display name, for the avatar's initials and its tooltip.
  ///
  /// Agents first (the common speaker in a thread), then the user directory.
  /// Falls back to a short id rather than an empty circle while either is
  /// still loading.
  String _displayName(WidgetRef ref, String principalId) {
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final agents = workspaceId == null
        ? null
        : ref.watch(workspaceAgentsProvider(workspaceId)).value;
    final agent = agents?.where((a) => a.id == principalId).firstOrNull;
    if (agent != null) {
      return agent.name;
    }
    final user = ref.watch(usersByIdProvider).value?[principalId];
    if (user != null) {
      return user.displayName;
    }
    return principalId.length > 8 ? principalId.substring(0, 8) : principalId;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final lastReplyAt = summary.lastReplyAt;

    // Overlapping faces, newest speaker on top — the stack reads left-to-right
    // as "who is in here" without costing a row of full-width chips.
    const double avatar = 18;
    const double overlap = 5;
    final faces = summary.participantIds.take(3).toList(growable: false);
    final stackWidth = faces.isEmpty
        ? 0.0
        : avatar + (faces.length - 1) * (avatar - overlap);

    return CcTappable(
      onPressed: () => onOpen(summary.threadId),
      semanticLabel:
          '${l10n.threadReplyCount(summary.replyCount)} — '
          '${summary.title}',
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 2, 8, 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: alignEnd
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (faces.isNotEmpty) ...[
                SizedBox(
                  width: stackWidth,
                  height: avatar,
                  child: Stack(
                    children: [
                      for (var i = 0; i < faces.length; i++)
                        Positioned(
                          left: i * (avatar - overlap),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              // A ring in the surface colour is what makes
                              // overlapping circles read as separate faces.
                              border: Border.all(color: ds.canvas, width: 1.5),
                            ),
                            child: CcAvatar(
                              size: avatar,
                              initials: avatarInitials(
                                _displayName(ref, faces[i]),
                                maxLetters: 1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                l10n.threadReplyCount(summary.replyCount),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: ds.accent,
                  decoration: hovered
                      ? TextDecoration.underline
                      : TextDecoration.none,
                  decorationColor: ds.accent,
                ),
              ),
              if (lastReplyAt != null) ...[
                const SizedBox(width: AppSpacing.xs),
                AppTimestamp(
                  dateTime: lastReplyAt,
                  child: Text(
                    l10n.threadLastReply(
                      formatRelativeTime(context, lastReplyAt),
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      color: ds.muted,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
