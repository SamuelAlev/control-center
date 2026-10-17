import 'dart:convert';

import 'package:cc_domain/features/governance/domain/value_objects/artifact_block.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/widgets/conversation_progress/progress_shared.dart';
import 'package:cc_remote/widgets/phone_markdown.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

class ProgressArtifactBlock extends StatelessWidget {
  const ProgressArtifactBlock({required this.block, super.key});

  final ArtifactBlock block;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final textStyle = CcTypography.bodySm.copyWith(color: t.textSecondary);
    switch (block) {
      case ArtifactMarkdownBlock(:final text):
        return PhoneMarkdown(data: progressPreview(text));
      case ArtifactCodeBlock(:final code, :final title, :final language):
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Text(
                title,
                textDirection: TextDirection.ltr,
                style: CcTypography.bodySm.copyWith(color: t.textPrimary),
              ),
            if (language != null) Text(language, style: textStyle),
            Directionality(
              textDirection: TextDirection.ltr,
              child: SelectableRegion(
                selectionControls: emptyTextSelectionControls,
                child: Text(
                  progressPreview(code),
                  style: CcFonts.code(
                    textStyle: CcTypography.monoNum.copyWith(
                      color: t.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      case ArtifactTableBlock(:final columns, :final rows):
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final row in rows.take(12))
              for (var i = 0; i < row.length && i < columns.length; i++)
                Text('${columns[i].label}: ${row[i]}', style: textStyle),
          ],
        );
      case ArtifactChartBlock(:final title, :final series):
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) Text(title, style: textStyle),
            for (final entry in series)
              for (final point in entry.points.take(12))
                Text(
                  '${entry.label} · ${point.x}: ${point.y}',
                  style: textStyle,
                ),
          ],
        );
      case ArtifactMermaidBlock(:final source):
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.progressDiagramSource, style: textStyle),
            Directionality(
              textDirection: TextDirection.ltr,
              child: SelectableRegion(
                selectionControls: emptyTextSelectionControls,
                child: Text(
                  progressPreview(source),
                  style: CcFonts.code(
                    textStyle: CcTypography.monoNum.copyWith(
                      color: t.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      case ArtifactDataBlock(:final json):
        return Directionality(
          textDirection: TextDirection.ltr,
          child: SelectableRegion(
            selectionControls: emptyTextSelectionControls,
            child: Text(
              progressPreview(const JsonEncoder.withIndent('  ').convert(json)),
              style: CcFonts.code(
                textStyle: CcTypography.monoNum.copyWith(color: t.textPrimary),
              ),
            ),
          ),
        );
    }
  }
}
