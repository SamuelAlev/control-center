import 'package:cc_domain/features/governance/domain/services/artifact_document_codec.dart';
import 'package:cc_remote/conversation_progress_artifacts.dart';
import 'package:cc_remote/conversation_progress_providers.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/widgets/conversation_progress/progress_artifact_block.dart';
import 'package:cc_remote/widgets/conversation_progress/progress_shared.dart';
import 'package:cc_remote/widgets/phone_markdown.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProgressArtifact extends ConsumerWidget {
  const ProgressArtifact({
    required this.scope,
    required this.artifactId,
    super.key,
  });

  final ProgressScope scope;
  final String artifactId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final args = (scope: scope, artifactId: artifactId);
    final artifact = ref.watch(progressArtifactProvider(args));
    if (artifact.hasError) {
      return progressError(
        l,
        artifact.error!,
        () => ref.invalidate(progressArtifactProvider(args)),
      );
    }
    if (artifact.isLoading) return const CcSpinner(size: 18);
    final product = artifact.value;
    if (product == null) {
      return Text(
        l.progressArtifactUnavailable,
        style: CcTypography.bodySm.copyWith(color: t.textSecondary),
      );
    }
    final content = product.content;
    final document = content == null
        ? null
        : ArtifactDocument.tryParseContent(content);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.title.trim().isEmpty ? l.progressArtifact : product.title,
            style: CcTypography.bodySm.copyWith(
              color: t.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (content != null) ...[
            if (document != null)
              for (final block in document.blocks.take(6))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ProgressArtifactBlock(block: block),
                )
            else
              PhoneMarkdown(data: progressPreview(content)),
            if (content.length > 6000 || (document?.blocks.length ?? 0) > 6)
              Text(
                l.progressArtifactPreviewLimited,
                style: CcTypography.caption.copyWith(color: t.textSecondary),
              ),
          ],
        ],
      ),
    );
  }
}
