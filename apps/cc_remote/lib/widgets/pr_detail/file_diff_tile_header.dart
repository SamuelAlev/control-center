part of 'file_diff_tile.dart';

class _FileDiffHeader extends StatelessWidget {
  const _FileDiffHeader({
    required this.file,
    required this.open,
    required this.tokens,
    required this.onToggle,
  });

  final PrFile file;
  final bool open;
  final DesignSystemTokens tokens;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final slash = file.filename.lastIndexOf('/');
    final dir = slash <= 0 ? '' : file.filename.substring(0, slash + 1);
    final name = slash < 0 ? file.filename : file.filename.substring(slash + 1);

    return CcTappable(
      onPressed: onToggle,
      semanticLabel: open
          ? AppLocalizations.of(context).hideDiffFor(file.filename)
          : AppLocalizations.of(context).showDiffFor(file.filename),
      borderRadius: const BorderRadius.all(Radius.circular(6)),
      builder: (context, _) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  open ? AppIcons.chevronDown : AppIcons.chevronRight,
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
    );
  }
}
