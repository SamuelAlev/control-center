import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/providers/repo_file_content_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Read-only file viewer editor tab. Fetches a single file's content via the
/// workspace-scoped `repos.readFile` op and renders it as monospaced text.
///
/// This is the v1 plain-text fallback (no syntax highlighting); a richer
/// single-file viewer can drop in here later.
class FileViewerPane extends ConsumerWidget {
  /// Creates a [FileViewerPane].
  const FileViewerPane({
    super.key,
    required this.workspaceId,
    required this.repoId,
    required this.path,
  });

  /// Workspace owning the repo (workspace isolation is enforced server-side).
  final String workspaceId;

  /// Repo the file belongs to.
  final String repoId;

  /// Repo-relative path of the file to render.
  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem!;
    final content = ref.watch(
      repoFileContentProvider(
        (workspaceId: workspaceId, repoId: repoId, path: path),
      ),
    );

    return Column(
      children: [
        // Header: file path + glyph.
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: t.bgSecondary,
            border: Border(bottom: BorderSide(color: t.lineStrong)),
          ),
          child: Row(
            children: [
              Icon(AppIcons.fileCode, size: 14, color: t.textTertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  path,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: t.fg,
                    fontFamily: CcFonts.codeFamily,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: content.when(
            loading: () => Center(child: Text(l10n.ideFileLoading)),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  error.toString(),
                  style: TextStyle(color: t.textTertiary),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            data: (result) {
              if (result.binary) {
                return Center(
                  child: Text(
                    l10n.ideFileBinary,
                    style: TextStyle(color: t.textTertiary),
                  ),
                );
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: SelectableText(
                  result.content,
                  style: CcFonts.code(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
