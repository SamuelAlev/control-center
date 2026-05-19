import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/features/governance/domain/entities/work_product.dart';
import 'package:cc_domain/features/governance/domain/services/artifact_document_codec.dart';
import 'package:cc_domain/features/governance/domain/services/artifact_plain_text.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_text_styles.dart';
import 'package:control_center/features/artifacts/presentation/widgets/artifact_view.dart';
import 'package:control_center/features/artifacts/providers/artifact_providers.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/artifact_tab.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/channel_bubble_shared.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renders an agent-published artifact inline in the conversation.
///
/// The message metadata carries only ids; the bubble watches the work-product
/// row, so a revision re-renders the card in place with zero feed churn (the
/// same shape `OrchestrationProposalBubble` and `PlanBubble` use).
///
/// This is the surface the artifact system exists for: an agent answering a
/// question with a table, a chart and a diagram gets a real rendered answer in
/// the room instead of a wall of markdown — and no HTML is involved anywhere.
class ArtifactBubble extends ConsumerStatefulWidget {
  /// Creates an [ArtifactBubble].
  const ArtifactBubble({super.key, required this.message});

  /// The artifact channel message.
  final ChannelMessage message;

  @override
  ConsumerState<ArtifactBubble> createState() => _ArtifactBubbleState();
}

class _ArtifactBubbleState extends ConsumerState<ArtifactBubble> {
  /// Collapsed height for the rendered blocks. A long artifact stays scannable
  /// in the feed; "show more" opens it in place.
  static const double _collapsedHeight = 360;

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final tokens = resolveTokens(context);
    final l10n = AppLocalizations.of(context);
    final workProductId = widget.message.metadata?['workProductId'] as String?;
    if (workProductId == null) {
      return const SizedBox.shrink();
    }

    final async = ref.watch(artifactProvider(workProductId));

    // `Container`, not `DecoratedBox`: a decoration is painted BEHIND the child,
    // so the header's opaque `bgSecondary` fill — which runs the full width of
    // the box — paints straight over the 1px side border and the card loses its
    // left and right edge along the header band. `Container` insets the child by
    // `decoration.padding` (i.e. the border's dimensions), so the fill stops
    // inside the border instead of on top of it.
    Widget shell(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: tokens.bgPrimary,
          borderRadius: AppRadii.brMd,
          border: Border.all(color: tokens.borderSecondary),
        ),
        child: ClipRRect(borderRadius: AppRadii.brMd, child: child),
      ),
    );

    Widget unavailable() => Padding(
      padding: const EdgeInsets.all(14),
      child: Text(
        l10n.artifactUnavailable,
        style: AppTextStyles.bodySmall(
          tokens,
        ).copyWith(color: tokens.textTertiary),
      ),
    );

    return shell(
      async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CcSpinner()),
        ),
        error: (e, _) => unavailable(),
        data: (artifact) =>
            artifact == null ? unavailable() : _body(context, artifact),
      ),
    );
  }

  Widget _body(BuildContext context, WorkProduct artifact) {
    final tokens = resolveTokens(context);
    final l10n = AppLocalizations.of(context);
    final revisions = ref.watch(artifactRevisionsProvider(artifact.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 8,
          ),
          // The footer is closed by a `CcDivider`; square corners leave the
          // header's tint and the body's ground meeting with nothing between
          // them, so the head needs the same hairline to read as a header.
          decoration: BoxDecoration(
            color: tokens.bgSecondary,
            border: Border(bottom: BorderSide(color: tokens.borderSecondary)),
          ),
          child: Row(
            children: [
              Icon(
                AppIcons.layoutTemplate,
                size: 14,
                color: tokens.fgBrandPrimary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  artifact.title,
                  style: AppTextStyles.labelSmall(tokens).copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              revisions.maybeWhen(
                data: (list) => list.length > 1
                    ? Text(
                        l10n.artifactRevisionLabel(list.length),
                        style: AppTextStyles.labelSmall(
                          tokens,
                        ).copyWith(color: tokens.textTertiary),
                      )
                    : const SizedBox.shrink(),
                orElse: () => const SizedBox.shrink(),
              ),
              const SizedBox(width: 4),
              // The bubble is a preview by construction (height capped, type
              // tightened, as wide as the chat column). A twelve-column table or
              // a thirty-node flowchart needs a pane, so every artifact carries
              // the way out to one.
              CcIconButton(
                icon: AppIcons.externalLink,
                size: CcButtonSize.sm,
                color: tokens.textTertiary,
                tooltip: l10n.artifactOpenInTab,
                onPressed: () => openArtifact(
                  context,
                  workspaceId: artifact.workspaceId,
                  workProductId: artifact.id,
                  title: artifact.title,
                ),
              ),
            ],
          ),
        ),
        revisions.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CcSpinner()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              l10n.artifactUnavailable,
              style: AppTextStyles.bodySmall(
                tokens,
              ).copyWith(color: tokens.textTertiary),
            ),
          ),
          data: (list) {
            if (list.isEmpty) {
              return const SizedBox.shrink();
            }
            final head = list.last;
            final document = decodeArtifactRevision(head);
            final content = Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: 12,
              ),
              child: ArtifactView(document: document, compact: true),
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_expanded)
                  content
                else
                  // A bare `maxHeight` puts the blocks' Column in an impossible
                  // box: it reports its natural height, so the flex overflows
                  // (and paints the debug stripes) even though the clip hides
                  // the remainder. ConstraintsTransformBox lifts the height
                  // limit for the CHILD's layout and then sizes ITSELF to
                  // `min(natural, _collapsedHeight)` — a short artifact still
                  // shrink-wraps, a long one is clipped with no overflow.
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: _collapsedHeight,
                    ),
                    child: ConstraintsTransformBox(
                      constraintsTransform:
                          ConstraintsTransformBox.maxHeightUnconstrained,
                      alignment: Alignment.topCenter,
                      clipBehavior: Clip.hardEdge,
                      child: content,
                    ),
                  ),
                _Actions(
                  onToggle: () => setState(() => _expanded = !_expanded),
                  expanded: _expanded,
                  onCopy: () => _copy(document),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _copy(ArtifactDocument document) async {
    // Copies a readable rendering rather than the JSON envelope: the operator is
    // pasting into a place with no block renderer, which is exactly what the
    // plain-text projection is for.
    await Clipboard.setData(
      ClipboardData(text: artifactDocumentToPlainText(document)),
    );
    if (mounted) {
      CcToastScope.maybeOf(context)?.show(
        AppLocalizations.of(context).artifactCopied,
        variant: CcToastVariant.neutral,
      );
    }
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.onToggle,
    required this.expanded,
    required this.onCopy,
  });

  final VoidCallback onToggle;
  final bool expanded;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        const CcDivider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
          child: Row(
            children: [
              CcButton(
                variant: CcButtonVariant.ghost,
                size: CcButtonSize.sm,
                icon: expanded ? AppIcons.chevronUp : AppIcons.chevronDown,
                onPressed: onToggle,
                child: Text(
                  expanded ? l10n.artifactShowLess : l10n.artifactShowMore,
                ),
              ),
              const Spacer(),
              CcButton(
                variant: CcButtonVariant.ghost,
                size: CcButtonSize.sm,
                icon: AppIcons.copy,
                onPressed: onCopy,
                child: Text(l10n.artifactCopy),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
