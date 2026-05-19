import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:control_center/shared/widgets/markdown/highlighted_code_lines.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The human-readable name of a finding's concern.
String reviewCategoryLabel(BuildContext context, ReviewFindingCategory c) {
  final l10n = AppLocalizations.of(context);
  return switch (c) {
    ReviewFindingCategory.security => l10n.reviewCategorySecurity,
    ReviewFindingCategory.stability => l10n.reviewCategoryStability,
    ReviewFindingCategory.dataIntegrity => l10n.reviewCategoryDataIntegrity,
    ReviewFindingCategory.correctness => l10n.reviewCategoryCorrectness,
    ReviewFindingCategory.performance => l10n.reviewCategoryPerformance,
    ReviewFindingCategory.maintainability => l10n.reviewCategoryMaintainability,
  };
}

/// The human-readable name of what acting on a finding costs.
String reviewEffortLabel(BuildContext context, ReviewFindingEffort e) {
  final l10n = AppLocalizations.of(context);
  return switch (e) {
    ReviewFindingEffort.quickWin => l10n.reviewEffortQuickWin,
    ReviewFindingEffort.moderate => l10n.reviewEffortModerate,
    ReviewFindingEffort.heavyLift => l10n.reviewEffortHeavyLift,
  };
}

/// A collapsed block holding one piece of supporting material for a finding —
/// the proposed patch, or the prompt that hands it to a coding agent.
///
/// Collapsed by default and on purpose: both are longer than the sentence that
/// explains why the finding exists, and rendering either expanded buries the
/// reasoning under its own remedy.
class ReviewFindingAttachment extends StatefulWidget {
  /// Creates a [ReviewFindingAttachment].
  const ReviewFindingAttachment({
    super.key,
    required this.title,
    required this.body,
    required this.mono,
    this.languageId,
    this.copyLabel,
  });

  /// The disclosure label.
  final String title;

  /// The content revealed when expanded. This is also exactly what a copy
  /// affordance puts on the clipboard.
  final String body;

  /// Whether to render [body] in the code face.
  final bool mono;

  /// Canonical shiki id for [body], when it is code we can name. Null renders
  /// plain — the agent prompt is prose, not a program.
  final String? languageId;

  /// When set, a copy affordance is offered with this label.
  final String? copyLabel;

  @override
  State<ReviewFindingAttachment> createState() =>
      _ReviewFindingAttachmentState();
}

class _ReviewFindingAttachmentState extends State<ReviewFindingAttachment> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CcButton(
          onPressed: () => setState(() => _open = !_open),
          size: CcButtonSize.sm,
          variant: CcButtonVariant.ghost,
          icon: _open ? AppIcons.chevronDown : AppIcons.chevronRight,
          child: Text(widget.title),
        ),
        if (_open) ...[
          const SizedBox(height: AppSpacing.xs),
          // The embedded-artifact anatomy from DESIGN.md: surface fill, square
          // hairline frame, no radius. Rounded corners here were the loudest
          // thing marking this surface as off-system.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: tokens.surface,
              border: Border.all(color: tokens.borderSecondary),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.mono)
                  HighlightedCodeLines(
                    code: widget.body,
                    languageId: widget.languageId,
                    builder: (context, lines) => Text.rich(
                      TextSpan(
                        style: CcFonts.code(
                          textStyle: CcTypography.caption,
                        ).copyWith(color: tokens.textPrimary, height: 1.5),
                        children: joinCodeLineSpans(lines),
                      ),
                    ),
                  )
                else
                  Text(
                    widget.body,
                    style: CcTypography.caption.copyWith(
                      color: tokens.textPrimary,
                      height: 1.5,
                    ),
                  ),
                if (widget.copyLabel != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  CcButton(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: widget.body));
                      if (context.mounted) {
                        CcToastScope.maybeOf(context)?.show(
                          AppLocalizations.of(context).copied,
                          variant: CcToastVariant.success,
                        );
                      }
                    },
                    size: CcButtonSize.sm,
                    variant: CcButtonVariant.secondary,
                    icon: AppIcons.copy,
                    child: Text(widget.copyLabel!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// The attribution line above a finding's body: who filed it, on which triage
/// axes, and against which line of which file.
///
/// It carries only what the header row above it does NOT. It used to restate
/// the priority, the confidence, the status and the anchor that were already on
/// that row, so every open finding showed its own metadata twice, four words
/// apart, in two different visual languages. What is left is the author (the
/// header has no room for a name), the two triage axes, and the FULL path (the
/// header shows the basename so the finding's headline gets the width).
class ReviewFindingMetaRow extends ConsumerWidget {
  /// Creates a [ReviewFindingMetaRow].
  const ReviewFindingMetaRow({
    super.key,
    required this.msg,
    required this.payload,
  });

  /// The finding's message.
  final Message msg;

  /// The finding's parsed payload.
  final ReviewNodePayload payload;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.designSystem!;
    final agent = ref.watch(agentDetailProvider(msg.senderId)).value;
    final agentName = agent?.name ?? msg.senderId;
    final path = payload.anchor.filePath;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GitHubUserAvatar(login: agentName, size: 16, showHoverCard: false),
            const SizedBox(width: AppSpacing.xs),
            Text(
              agentName,
              style: CcTypography.caption.copyWith(color: tokens.textSecondary),
            ),
          ],
        ),
        // The triage axes, when the reviewer classified the finding. Each is
        // labelled with its own noun rather than colour-coded alone, so the
        // classification survives a greyscale screenshot.
        if (payload.category != null)
          CcBadge(label: reviewCategoryLabel(context, payload.category!)),
        if (payload.effort != null)
          CcBadge(label: reviewEffortLabel(context, payload.effort!)),
        if (path != null)
          Text(
            '$path${payload.anchor.lineNumber != null ? ':${payload.anchor.lineNumber}' : ''}',
            style: CcFonts.code(
              textStyle: CcTypography.caption,
            ).copyWith(color: tokens.textTertiary),
          ),
      ],
    );
  }
}
