import 'package:cc_domain/features/environments/domain/entities/environment_run.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_labels.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// What [run] did, in words: its own label, else what kind of run it was.
String environmentRunTitle(AppLocalizations l10n, EnvironmentRun run) {
  final label = run.label;
  if (label != null && label.isNotEmpty) {
    return label;
  }
  return switch (run.kind) {
    EnvironmentRunKind.start => l10n.startLabel,
    EnvironmentRunKind.stop => l10n.stop,
    EnvironmentRunKind.reset => l10n.environmentResetData,
    EnvironmentRunKind.refresh => l10n.refresh,
    EnvironmentRunKind.destroy => l10n.environmentDestroy,
    EnvironmentRunKind.task => l10n.environmentKindTask,
    EnvironmentRunKind.test => l10n.environmentsRunTest,
  };
}

/// One run: how it ended, what it was, when, and its output on demand.
///
/// The icon carries the result, so a list of runs reads down its first column.
/// A run that printed nothing has nothing to open.
class EnvironmentRunRow extends StatefulWidget {
  /// Creates an [EnvironmentRunRow].
  const EnvironmentRunRow({super.key, required this.run});

  /// The run.
  final EnvironmentRun run;

  @override
  State<EnvironmentRunRow> createState() => _EnvironmentRunRowState();
}

class _EnvironmentRunRowState extends State<EnvironmentRunRow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final run = widget.run;
    final (status, _) = environmentRunStatusDisplay(l10n, run.status);
    final title = environmentRunTitle(l10n, run);
    final caption = CcTypography.caption.copyWith(color: t.textTertiary);
    final exitCode = run.exitCode;
    final hasOutput = run.output.isNotEmpty;
    final error = run.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CcTappable(
          onPressed: hasOutput ? () => setState(() => _open = !_open) : null,
          semanticLabel: '$title, $status',
          builder: (context, states) => Container(
            color: states.contains(WidgetState.hovered) && hasOutput
                ? t.hover
                : null,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xxs),
                  child: _RunStatusIcon(status: run.status, label: status),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CcTypography.bodySm.copyWith(
                          color: t.textPrimary,
                        ),
                      ),
                      if (error != null && error.isNotEmpty)
                        Text(
                          error,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: caption,
                        )
                      else if (exitCode != null && exitCode != 0)
                        Text(
                          l10n.environmentExitCode(exitCode),
                          style: caption,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppTimestamp.relative(run.startedAt, style: caption),
                Container(
                  width: 16,
                  height: 18,
                  alignment: AlignmentDirectional.centerEnd,
                  child: hasOutput
                      ? CcIcon(
                          _open ? AppIcons.chevronDown : AppIcons.chevronRight,
                          size: 12,
                          color: t.fgTertiary,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
        CcCollapsible(
          expanded: _open,
          child: _RunOutput(run: run),
        ),
      ],
    );
  }
}

/// A run's result as a glyph, named for anyone who can't see it.
class _RunStatusIcon extends StatelessWidget {
  const _RunStatusIcon({required this.status, required this.label});

  final EnvironmentRunStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return switch (status) {
      EnvironmentRunStatus.running => const SizedBox(
        width: 14,
        height: 14,
        child: CcSpinner(size: 12),
      ),
      EnvironmentRunStatus.succeeded => CcIcon(
        AppIcons.check,
        size: 14,
        color: t.success,
        semanticLabel: label,
      ),
      EnvironmentRunStatus.failed || EnvironmentRunStatus.timedOut => CcIcon(
        AppIcons.x,
        size: 14,
        color: t.danger,
        semanticLabel: label,
      ),
    };
  }
}

/// A run's output as the terminal printed it: lines stay whole and scroll
/// sideways, because a wrapped log in a sidebar can't be read.
class _RunOutput extends StatelessWidget {
  const _RunOutput({required this.run});

  final EnvironmentRun run;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      // RTL carve-out: command output is a log.
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 220),
          decoration: BoxDecoration(
            color: t.bgSecondary,
            border: Border.all(color: t.borderPrimary),
          ),
          child: Stack(
            children: [
              SingleChildScrollView(
                reverse: true,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  // Copied with the button: selection widgets are Material.
                  child: Text(
                    run.output,
                    softWrap: false,
                    style: CcFonts.code(
                      textStyle: CcTypography.caption.copyWith(
                        color: t.textSecondary,
                        fontSize: 11,
                        height: 1.45,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: AppSpacing.xxs,
                right: AppSpacing.xxs,
                child: CcIconButton(
                  icon: AppIcons.copy,
                  size: CcButtonSize.sm,
                  tooltip: l10n.copy,
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: run.output)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
