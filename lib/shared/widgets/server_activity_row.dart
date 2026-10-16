part of 'server_activity_panel.dart';

class _ServerActivityRow extends StatefulWidget {
  const _ServerActivityRow({super.key, required this.entry});

  final ServerActivityEntry entry;

  @override
  State<_ServerActivityRow> createState() => _ServerActivityRowState();
}

class _ServerActivityRowState extends State<_ServerActivityRow> {
  bool _details = false;
  bool _retrying = false;
  Object? _retryError;

  @override
  void didUpdateWidget(_ServerActivityRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entry.busy || widget.entry.error != oldWidget.entry.error) {
      _retryError = null;
    }
  }

  Future<void> _retry() async {
    setState(() {
      _retrying = true;
      _retryError = null;
    });
    try {
      await widget.entry.onRetry!();
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _retryError = error;
          _details = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _retrying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final diagnostic = _retryError?.toString() ?? entry.error;
    final failed = diagnostic != null;
    final progress = entry.progress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(entry.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (failed) ...[
              Icon(AppIcons.alertTriangle, size: 14, color: t.textErrorPrimary),
              const SizedBox(width: AppSpacing.xs),
            ],
            Expanded(
              child: Semantics(
                liveRegion: failed,
                child: Text(
                  entry.message,
                  style: CcTypography.caption.copyWith(
                    color: failed ? t.textErrorPrimary : t.textSecondary,
                  ),
                ),
              ),
            ),
            if (entry.busy && progress != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Text(
                NumberFormat.percentPattern(
                  Localizations.localeOf(context).toLanguageTag(),
                ).format(progress),
                style: CcFonts.code(textStyle: CcTypography.caption),
              ),
            ],
          ],
        ),
        if (entry.busy) ...[
          const SizedBox(height: AppSpacing.sm),
          CcProgressBar(
            value: progress,
            semanticLabel: '${entry.title}: ${entry.message}',
          ),
        ],
        if (failed) ...[
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              if (entry.onRetry != null)
                CcButton(
                  onPressed: _retrying ? null : _retry,
                  loading: _retrying,
                  variant: CcButtonVariant.secondary,
                  child: Text(l10n.retry),
                ),
              CcButton(
                onPressed: () => setState(() => _details = !_details),
                variant: CcButtonVariant.ghost,
                child: Text(l10n.serverSetupErrorDetails),
              ),
            ],
          ),
          if (_details)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: AppSpacing.sm),
              // RTL carve-out: raw server diagnostics contain paths, URLs and logs.
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  diagnostic,
                  style: CcFonts.code(textStyle: CcTypography.caption).copyWith(
                    color: t.textSecondary,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}
