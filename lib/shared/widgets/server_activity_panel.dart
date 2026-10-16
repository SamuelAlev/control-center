import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' hide TextDirection;

part 'server_activity_row.dart';

/// One active server operation or retained failure, never a synthetic log entry.
class ServerActivityEntry {
  /// Creates an activity row.
  const ServerActivityEntry({
    required this.id,
    required this.title,
    required this.message,
    this.busy = false,
    this.progress,
    this.error,
    this.onRetry,
  });

  /// Stable operation identity, preserving disclosure state across progress ticks.
  final String id;

  /// Model name or startup stage.
  final String title;

  /// Localized phase or recovery guidance.
  final String message;

  /// Whether work is in progress.
  final bool busy;

  /// Transfer fraction, or null before a total is known.
  final double? progress;

  /// Technical diagnostic, shown on request rather than as the headline.
  final String? error;

  /// Retries the failed operation; absent when setup owns recovery.
  final Future<void> Function()? onRetry;
}

/// A non-modal, collapsible activity surface shared by boot and connected UI.
class ServerActivityPanel extends StatefulWidget {
  /// Creates a panel. An empty list renders nothing and intercepts no input.
  const ServerActivityPanel({
    super.key,
    required this.entries,
    this.docked = false,
  });

  /// Current operations and failures. Completed operations are removed upstream.
  final List<ServerActivityEntry> entries;

  /// Reserves content height instead of filling an overlay on compact onboarding.
  final bool docked;

  @override
  State<ServerActivityPanel> createState() => _ServerActivityPanelState();
}

class _ServerActivityPanelState extends State<ServerActivityPanel> {
  late bool _expanded =
      !widget.docked || widget.entries.any((entry) => entry.error != null);

  @override
  void didUpdateWidget(ServerActivityPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.entries.isEmpty && !widget.docked) ||
        widget.entries.any(
          (entry) =>
              entry.error != null &&
              !oldWidget.entries.any(
                (old) => old.id == entry.id && old.error == entry.error,
              ),
        )) {
      _expanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.entries.isEmpty) {
      return const SizedBox.shrink();
    }
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final failed = widget.entries.any((entry) => entry.error != null);
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final expanded = _expanded && !(widget.docked && keyboardVisible);
    return SafeArea(
      minimum: const EdgeInsets.all(AppSpacing.lg),
      child: Align(
        alignment: AlignmentDirectional.bottomEnd,
        heightFactor: widget.docked ? 1 : null,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 360,
            maxHeight:
                MediaQuery.sizeOf(context).height * (widget.docked ? 0.3 : 0.5),
          ),
          child: DefaultTextStyle(
            style: CcFonts.ui(
              textStyle: CcTypography.bodySm,
            ).copyWith(color: t.textPrimary, decoration: TextDecoration.none),
            child: DecoratedBox(
              decoration: const BoxDecoration(boxShadow: CcElevation.floating),
              child: CcCard(
                padding: EdgeInsets.zero,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: AppSpacing.md,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            failed ? AppIcons.alertTriangle : AppIcons.download,
                            size: 16,
                            color: failed
                                ? t.textErrorPrimary
                                : t.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Semantics(
                              liveRegion: true,
                              child: Text(
                                l10n.serverActivityTitle,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            NumberFormat.decimalPattern(
                              Localizations.localeOf(context).toLanguageTag(),
                            ).format(widget.entries.length),
                            style: CcFonts.code(
                              textStyle: CcTypography.caption,
                            ),
                          ),
                          Semantics(
                            expanded: expanded,
                            child: CcIconButton(
                              icon: expanded
                                  ? AppIcons.chevronDown
                                  : AppIcons.chevronUp,
                              size: CcButtonSize.lg,
                              tooltip: expanded ? l10n.collapse : l10n.expand,
                              onPressed: () {
                                if (widget.docked && keyboardVisible) {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  setState(() => _expanded = true);
                                } else {
                                  setState(() => _expanded = !_expanded);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (expanded)
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            AppSpacing.md,
                            0,
                            AppSpacing.md,
                            AppSpacing.md,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (
                                var i = 0;
                                i < widget.entries.length;
                                i++
                              ) ...[
                                if (i > 0)
                                  const SizedBox(height: AppSpacing.lg),
                                _ServerActivityRow(
                                  key: ValueKey(widget.entries[i].id),
                                  entry: widget.entries[i],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
