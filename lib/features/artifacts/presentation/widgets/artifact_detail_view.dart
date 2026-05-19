import 'package:cc_domain/features/governance/domain/entities/work_product.dart';
import 'package:cc_domain/features/governance/domain/services/artifact_document_codec.dart';
import 'package:cc_domain/features/governance/domain/services/artifact_plain_text.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_text_styles.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/artifacts/presentation/widgets/artifact_revision_picker.dart';
import 'package:control_center/features/artifacts/presentation/widgets/artifact_view.dart';
import 'package:control_center/features/artifacts/providers/artifact_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One artifact, rendered at full size on a surface of its own: a title bar with
/// the revision history and a scrolling, non-compact body.
///
/// The conversation bubble and the sidebar card are both previews — height
/// capped, type tightened, sized to a column that is mostly chat. A table with
/// twelve columns or a flowchart with thirty nodes needs the whole pane, which is
/// what "open in tab" opens. Also the dialog fallback on surfaces that have no
/// host editor layout, so the action never dead-ends.
class ArtifactDetailView extends ConsumerStatefulWidget {
  /// Creates an [ArtifactDetailView].
  const ArtifactDetailView({
    super.key,
    required this.workProductId,
    this.showHeader = true,
  });

  /// The artifact (work product) to render.
  final String workProductId;

  /// Whether to draw the title bar. Off when the host already names the surface
  /// (a dialog with its own title).
  final bool showHeader;

  @override
  ConsumerState<ArtifactDetailView> createState() => _ArtifactDetailViewState();
}

class _ArtifactDetailViewState extends ConsumerState<ArtifactDetailView> {
  /// Null means "follow the head" — a new revision landing while the tab is open
  /// must move the view forward, not pin it to whatever was newest on open.
  int? _pinnedRevision;

  /// Reading measure for the body. An artifact is prose, tables and diagrams;
  /// letting a markdown paragraph run the full width of a 2000px pane is worse
  /// than the margin it costs.
  static const double _maxContentWidth = 940;

  @override
  Widget build(BuildContext context) {
    final tokens = resolveDesignTokens(context);
    final l10n = AppLocalizations.of(context);
    final artifact = ref.watch(artifactProvider(widget.workProductId));
    final revisions = ref.watch(
      artifactRevisionsProvider(widget.workProductId),
    );

    return artifact.when(
      loading: () => const Center(child: CcSpinner()),
      error: (e, _) => _Unavailable(message: l10n.artifactUnavailable),
      data: (product) {
        if (product == null) {
          return _Unavailable(message: l10n.artifactUnavailable);
        }
        return revisions.when(
          loading: () => const Center(child: CcSpinner()),
          error: (e, _) => _Unavailable(message: l10n.artifactUnavailable),
          data: (list) {
            if (list.isEmpty) {
              return _Unavailable(message: l10n.artifactUnavailable);
            }
            final shown = _pinnedRevision == null
                ? list.last
                : list.firstWhere(
                    (r) => r.revisionNumber == _pinnedRevision,
                    orElse: () => list.last,
                  );
            final document = decodeArtifactRevision(shown);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.showHeader)
                  _Header(
                    title: product.title,
                    tokens: tokens,
                    onCopy: () => _copy(document),
                  ),
                if (list.length > 1)
                  ArtifactRevisionPicker(
                    revisions: list,
                    selected: shown.revisionNumber,
                    isHead: shown.id == list.last.id,
                    padding: const EdgeInsets.fromLTRB(16, 10, 12, 0),
                    onSelect: (n) => setState(
                      () => _pinnedRevision = n == list.last.revisionNumber
                          ? null
                          : n,
                    ),
                    onRestore: () => _restore(shown),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _maxContentWidth,
                        ),
                        child: ArtifactView(document: document),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _copy(ArtifactDocument document) async {
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

  /// Restore is append-a-new-head, never a rewrite — the history stays an audit
  /// trail (see `WorkProductService.restoreRevision`).
  Future<void> _restore(WorkProductRevision revision) async {
    try {
      await ref
          .read(workProductRepositoryProvider)
          .restoreRevision(widget.workProductId, revision.id);
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

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.tokens,
    required this.onCopy,
  });

  final String title;
  final DesignSystemTokens tokens;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
      decoration: BoxDecoration(
        color: tokens.bgSecondary,
        border: Border(bottom: BorderSide(color: tokens.borderSecondary)),
      ),
      child: Row(
        children: [
          Icon(AppIcons.layoutTemplate, size: 15, color: tokens.fgBrandPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.bodyMedium(tokens).copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          CcIconButton(
            icon: AppIcons.copy,
            size: CcButtonSize.sm,
            color: tokens.textTertiary,
            tooltip: l10n.artifactCopy,
            onPressed: onCopy,
          ),
        ],
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final tokens = resolveDesignTokens(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium(
            tokens,
          ).copyWith(color: tokens.textTertiary),
        ),
      ),
    );
  }
}
