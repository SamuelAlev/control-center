import 'dart:async';

import 'package:control_center/features/pr_review/domain/sources/pr_diff_source.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Blocking progress card shown while a large-PR local clone is running.
///
/// Several git phases (clone finalisation, the promisor blob fetch a `git diff`
/// triggers on a blobless clone) emit no output for tens of seconds, which
/// makes the card look frozen. A live elapsed-time counter reassures the user
/// that work is still in progress.
class PrCloneProgressCard extends StatefulWidget {
  /// Creates a [PrCloneProgressCard].
  const PrCloneProgressCard({
    super.key,
    required this.phase,
    this.message = '',
    this.fileCount = 0,
  });

  /// Current phase of the clone operation.
  final ClonePhase phase;

  /// Optional progress message, e.g. live git output.
  final String message;

  /// Number of changed files reported by GitHub. Used in the subtitle.
  final int fileCount;

  @override
  State<PrCloneProgressCard> createState() => _PrCloneProgressCardState();
}

class _PrCloneProgressCardState extends State<PrCloneProgressCard> {
  late final DateTime _start;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _start = DateTime.now();
    // Rebuild once a second so the elapsed counter advances even while git is
    // silent. Cheap for a single card; cancelled in dispose().
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// Formats a duration as `42s` or `2m 05s`.
  static String _formatElapsed(Duration d) {
    final totalSeconds = d.inSeconds;
    if (totalSeconds < 60) {
      return '${totalSeconds}s';
    }
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = context.theme;

    String title;
    // The live git output message (if any), shown as a monospace log line.
    // Falls back to a static hint. For the initial "Cloning into..." period
    // git is silent (connecting + enumerating on the server) — show a patience
    // note as the hint so the user knows it's not frozen.
    String hint;
    switch (widget.phase) {
      case ClonePhase.cloning:
        title = l10n.prCloneProgressCloningTitle;
        hint = widget.fileCount > 0
            ? l10n.prCloneProgressCloningSubtitle(widget.fileCount)
            : l10n.prCloneProgressCloningSubtitleNoCount;
      case ClonePhase.fetching:
        title = l10n.prCloneProgressFetchingTitle;
        hint = l10n.prCloneProgressFetchingSubtitle;
      case ClonePhase.computing:
        title = l10n.prCloneProgressComputingTitle;
        hint = l10n.prCloneProgressComputingSubtitle;
      case ClonePhase.error:
        title = l10n.prCloneProgressErrorTitle;
        hint = widget.message.isNotEmpty
            ? widget.message
            : l10n.prCloneProgressErrorSubtitle;
      case ClonePhase.ready:
        return const SizedBox.shrink();
    }

    final isError = widget.phase == ClonePhase.error;
    // Only surface the elapsed counter once a second has passed so it doesn't
    // flash "0s" on first paint.
    final elapsed = DateTime.now().difference(_start);
    final showElapsed = !isError && elapsed.inSeconds >= 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colors.secondary.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: isError
                      ? Icon(
                          LucideIcons.alertTriangle,
                          size: 32,
                          color: theme.colors.destructive,
                        )
                      : const FCircularProgress(),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    hint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Live git output — shown once git starts writing progress.
                // Hidden while message is empty (e.g. initial "Cloning into..."
                // silent period while git connects to the server).
                if (widget.message.isNotEmpty && !isError) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colors.secondary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.message,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: theme.colors.mutedForeground,
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                // Elapsed-time heartbeat so silent git phases never look frozen.
                if (showElapsed) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      l10n.prCloneProgressElapsed(_formatElapsed(elapsed)),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
