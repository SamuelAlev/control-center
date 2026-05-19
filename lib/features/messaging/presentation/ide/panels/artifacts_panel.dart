import 'package:cc_domain/features/governance/domain/entities/work_product.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_text_styles.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/artifacts/presentation/widgets/artifact_revision_picker.dart';
import 'package:control_center/features/artifacts/presentation/widgets/artifact_view.dart';
import 'package:control_center/features/artifacts/providers/artifact_providers.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/artifact_tab.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Every artifact published into this conversation, with its revision history.
///
/// The conversation feed shows an artifact at the moment it lands; this panel is
/// where an operator goes back to one — including to an earlier revision, since
/// the work-product store has kept the full history all along and nothing in the
/// client could read it until now.
class ArtifactsPanel extends ConsumerWidget {
  /// Creates an [ArtifactsPanel].
  const ArtifactsPanel({super.key, required this.spaceId});

  /// The conversation whose artifacts are listed.
  final String spaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(spaceArtifactsProvider(spaceId));

    return async.when(
      loading: () => const Center(child: CcSpinner()),
      error: (e, _) => _Empty(title: l10n.artifactUnavailable, body: '$e'),
      data: (artifacts) {
        if (artifacts.isEmpty) {
          return _Empty(
            title: l10n.artifactsEmptyTitle,
            body: l10n.artifactsEmptyBody,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: artifacts.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) => _ArtifactCard(artifact: artifacts[i]),
        );
      },
    );
  }
}

class _ArtifactCard extends ConsumerStatefulWidget {
  const _ArtifactCard({required this.artifact});

  final WorkProduct artifact;

  @override
  ConsumerState<_ArtifactCard> createState() => _ArtifactCardState();
}

class _ArtifactCardState extends ConsumerState<_ArtifactCard> {
  bool _open = false;

  /// Null means "the head revision" — the common case and it must keep
  /// following the head as new revisions land rather than pinning to whatever
  /// was newest when the card was built.
  int? _pinnedRevision;

  @override
  Widget build(BuildContext context) {
    final tokens = resolveDesignTokens(context);
    final l10n = AppLocalizations.of(context);
    final revisions = ref.watch(artifactRevisionsProvider(widget.artifact.id));

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.bgPrimary,
        borderRadius: AppRadii.brMd,
        border: Border.all(color: tokens.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // The disclosure row and the open-in-tab button are SIBLINGS, not
          // nested: a button inside the tappable would put two tap recognizers
          // on the same pixels and the wrong one wins often enough to feel
          // broken.
          Row(
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  expanded: _open,
                  child: CcTappable(
                    onPressed: () => setState(() => _open = !_open),
                    builder: (context, states) => Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                      child: Row(
                        children: [
                          Icon(
                            _open
                                ? AppIcons.chevronDown
                                : AppIcons.chevronRight,
                            size: 14,
                            color: tokens.fgQuaternary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.artifact.title,
                              style: AppTextStyles.bodySmall(tokens).copyWith(
                                color: tokens.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: CcIconButton(
                  icon: AppIcons.externalLink,
                  size: CcButtonSize.sm,
                  color: tokens.textTertiary,
                  tooltip: l10n.artifactOpenInTab,
                  onPressed: () => openArtifact(
                    context,
                    workspaceId: widget.artifact.workspaceId,
                    workProductId: widget.artifact.id,
                    title: widget.artifact.title,
                  ),
                ),
              ),
            ],
          ),
          if (_open)
            revisions.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(14),
                child: Center(child: CcSpinner()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(12),
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
                final shown = _pinnedRevision == null
                    ? list.last
                    : list.firstWhere(
                        (r) => r.revisionNumber == _pinnedRevision,
                        orElse: () => list.last,
                      );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const CcDivider(),
                    if (list.length > 1)
                      ArtifactRevisionPicker(
                        revisions: list,
                        selected: shown.revisionNumber,
                        isHead: shown.id == list.last.id,
                        onSelect: (n) => setState(
                          () => _pinnedRevision = n == list.last.revisionNumber
                              ? null
                              : n,
                        ),
                        onRestore: () => _restore(shown),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: ArtifactView(
                        document: decodeArtifactRevision(shown),
                        compact: true,
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _restore(WorkProductRevision revision) async {
    // Restore is append-a-new-head, never a rewrite: the history stays an
    // audit trail (that is what `WorkProductService.restoreRevision` does
    // server-side).
    try {
      await ref
          .read(workProductRepositoryProvider)
          .restoreRevision(widget.artifact.id, revision.id);
      if (mounted) {
        setState(() => _pinnedRevision = null);
      }
    } on Object catch (e) {
      if (mounted) {
        CcToastScope.maybeOf(
          context,
        )?.show('$e', variant: CcToastVariant.danger);
      }
    }
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final tokens = resolveDesignTokens(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(AppIcons.layoutTemplate, size: 26, color: tokens.fgQuaternary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium(tokens).copyWith(
                color: tokens.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall(
                tokens,
              ).copyWith(color: tokens.textTertiary, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}
