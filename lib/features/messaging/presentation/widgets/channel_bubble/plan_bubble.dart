import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/channel_bubble_shared.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/markdown/markdown_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart' as sm;

/// A plan message rendered as a card with an orange header strip.
///
/// Three vertical sections share the same rounded-14 border:
///   * **Header strip** — orange-tinted band carrying the kind icon and the
///     uppercase status label (`PLAN` / `PLAN APPROVED` / `REFINING PLAN`).
///   * **Body** — plan content rendered as markdown.
///   * **Footer action bar** — `Approve` / `Compact` / `Refine` buttons while
///     the plan is pending; replaced by a status caption once approved or
///     while a refinement is in flight.
class PlanBubble extends StatelessWidget {
  /// Creates a [PlanBubble].
  const PlanBubble({
    super.key,
    required this.message,
    this.onApprove,
    this.onApproveCompacted,
    this.onRefine,
  });

  /// The plan channel message.
  final ChannelMessage message;

  /// Called when the user approves and wants to execute.
  final VoidCallback? onApprove;

  /// Called when the user approves with compacted context.
  final VoidCallback? onApproveCompacted;

  /// Called when the user wants to refine the plan.
  final VoidCallback? onRefine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = resolveTokens(context);
    final status = message.planStatus;
    final isPending = status == 'pending';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Semantics(
        label: 'Plan: ${message.content}',
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tokens.bgPrimary,
            borderRadius: BorderRadius.circular(bubbleRadius),
            border: Border.all(color: tokens.borderSecondary),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(bubbleRadius),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _HeaderStrip(status: status, tokens: tokens, theme: theme),
                if (message.content.isNotEmpty)
                  Padding(
                    padding: bubblePadding,
                    child: sm.SmoothMarkdown(
                      data: message.content,
                      selectable: true,
                      styleSheet: smMarkdownStyleSheet(context),
                      codeBuilder: (code, language) => buildSharedCodeBlock(
                        context,
                        code,
                        language,
                      ),
                      plugins: chatPlugins,
                      builderRegistry: chatBuilders,
                    ),
                  ),
                if (isPending)
                  _ActionBar(
                    tokens: tokens,
                    onApprove: onApprove,
                    onApproveCompacted: onApproveCompacted,
                    onRefine: onRefine,
                  )
                else
                  _StatusFooter(status: status, tokens: tokens, theme: theme),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderStrip extends StatelessWidget {
  const _HeaderStrip({
    required this.status,
    required this.tokens,
    required this.theme,
  });

  final String status;
  final DesignSystemTokens tokens;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bg = tokens.accentSoft;
    final (icon, label) = switch (status) {
      'approved' => (Icons.check_circle_outline, 'PLAN APPROVED'),
      'refining' => (Icons.edit_note, l10n.refiningPlan.toUpperCase()),
      _ => (Icons.architecture, l10n.planLabel.toUpperCase()),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          bottom: BorderSide(color: tokens.borderSecondary),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: tokens.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: tokens.accent,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
          if (status == 'refining')
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation(tokens.accent),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.tokens,
    this.onApprove,
    this.onApproveCompacted,
    this.onRefine,
  });

  final DesignSystemTokens tokens;
  final VoidCallback? onApprove;
  final VoidCallback? onApproveCompacted;
  final VoidCallback? onRefine;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: tokens.bgPrimary,
        border: Border(
          top: BorderSide(color: tokens.borderSecondary),
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          FilledButton.icon(
            onPressed: onApprove,
            icon: const Icon(Icons.play_arrow, size: 18),
            label: Text(l10n.approveAndExecute),
          ),
          FilledButton.tonalIcon(
            onPressed: onApproveCompacted,
            icon: const Icon(Icons.compress, size: 18),
            label: Text(l10n.approveAndCompact),
          ),
          TextButton.icon(
            onPressed: onRefine,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text(l10n.refinePlan),
            style: TextButton.styleFrom(
              foregroundColor: tokens.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusFooter extends StatelessWidget {
  const _StatusFooter({
    required this.status,
    required this.tokens,
    required this.theme,
  });

  final String status;
  final DesignSystemTokens tokens;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      'approved' => 'Plan approved — executing…',
      'refining' => 'Plan is being refined…',
      _ => '',
    };
    if (label.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      decoration: BoxDecoration(
        color: tokens.bgPrimary,
        border: Border(
          top: BorderSide(color: tokens.borderSecondary),
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: tokens.textQuaternary,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
