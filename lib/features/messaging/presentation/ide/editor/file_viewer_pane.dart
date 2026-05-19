import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/providers/repo_file_content_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/syntax/syntax_languages.dart';
import 'package:control_center/shared/widgets/markdown/highlighted_code_lines.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Read-only file viewer editor tab. Fetches a single file's content via the
/// `repos.readFile` op and renders it syntax-highlighted in the app's own shiki
/// theme, with the language resolved from the file's path.
///
/// When opened from a conversation it reads that conversation's ISOLATED CoW
/// worktree ([spaceId]) — the same copy the Explorer listed it from, so a quick
/// view never shows the pristine linked checkout of a file an agent has since
/// rewritten.
///
/// A file past the tokenize budget renders plain rather than blocking the
/// frame; see [HighlightedCodeLines].
class FileViewerPane extends ConsumerWidget {
  /// Creates a [FileViewerPane].
  const FileViewerPane({
    super.key,
    required this.workspaceId,
    required this.repoId,
    required this.path,
    this.spaceId,
  });

  /// Workspace owning the repo (workspace isolation is enforced server-side).
  final String workspaceId;

  /// Repo the file belongs to.
  final String repoId;

  /// Repo-relative path of the file to render.
  final String path;

  /// The conversation whose isolated worktree holds the copy to read. Null
  /// reads the shared linked checkout.
  final String? spaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem!;
    final content = ref.watch(
      repoFileContentProvider((
        workspaceId: workspaceId,
        repoId: repoId,
        path: path,
        spaceId: spaceId,
      )),
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
                child: HighlightedCodeLines(
                  code: result.content,
                  languageId: shikiLangForPath(path),
                  // One `SelectableText.rich` over the whole file, not a
                  // widget per line: a per-line selection only ever copies
                  // the line the drag started on.
                  builder: (context, lines) => SelectableText.rich(
                    TextSpan(
                      style: CcFonts.code(),
                      children: joinCodeLineSpans(lines),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
