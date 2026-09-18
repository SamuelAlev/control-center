import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/format.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/widgets/diff_view.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// One changed file: a tappable header carrying its path and churn, expanding
/// to the file's unified diff.
///
/// Collapsed by default, and that is the point rather than a compromise. The
/// header row is the scan — twenty files, what changed and by how much — and
/// expanding every one of them on open would build thousands of rows inside
/// the PR screen's own scroll view before the reader has looked at anything.
class FileDiffTile extends StatefulWidget {
  const FileDiffTile({super.key, required this.file});

  final PrFile file;

  @override
  State<FileDiffTile> createState() => _FileDiffTileState();
}

class _FileDiffTileState extends State<FileDiffTile> {
  bool _open = false;
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final file = widget.file;
    final slash = file.filename.lastIndexOf('/');
    final dir = slash <= 0 ? '' : file.filename.substring(0, slash + 1);
    final name = slash < 0 ? file.filename : file.filename.substring(slash + 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CcTappable(
          onPressed: () => setState(() => _open = !_open),
          semanticLabel: _open
              ? AppLocalizations.of(context).hideDiffFor(file.filename)
              : AppLocalizations.of(context).showDiffFor(file.filename),
          borderRadius: const BorderRadius.all(Radius.circular(6)),
          builder: (context, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    _open ? AppIcons.chevronDown : AppIcons.chevronRight,
                    size: 14,
                    color: t.fgTertiary,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    switch (file.status) {
                      PrFileStatus.added => AppIcons.circleCheck,
                      PrFileStatus.removed => AppIcons.minus,
                      PrFileStatus.renamed => AppIcons.arrowRight,
                      _ => AppIcons.fileText,
                    },
                    size: 14,
                    color: t.fgTertiary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        if (dir.isNotEmpty)
                          TextSpan(
                            text: dir,
                            style: TextStyle(color: t.textTertiary),
                          ),
                        TextSpan(
                          text: name,
                          style: TextStyle(
                            color: t.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    // RTL carve-out: file paths read LTR in every locale.
                    textDirection: TextDirection.ltr,
                    style: CcFonts.code(
                      textStyle: const TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  churn(file.additions, file.deletions),
                  style: TextStyle(fontSize: 11, color: t.textTertiary),
                ),
              ],
            ),
          ),
        ),
        if (_open)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: 4,
              bottom: 12,
              top: 2,
            ),
            child: DiffView(
              patch: file.patch,
              expanded: _showAll,
              onExpand: () => setState(() => _showAll = true),
            ),
          ),
      ],
    );
  }
}
