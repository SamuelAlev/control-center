import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/relative_time.dart';
import 'package:flutter/material.dart';

/// A muted "Checked {time}" freshness label paired with a refresh icon button.
///
/// Mirrors the GitHub status indicator pattern (`Updated {time}` + refresh)
/// so every remote-data surface reports how stale its data is at a glance.
///
/// The label only renders when [lastChecked] is non-null, and the refresh
/// button only renders when [onRefresh] is non-null — passing `onRefresh: null`
/// yields a label-only control for surfaces whose refresh lives elsewhere
/// (e.g. a menu item).
class RefreshControl extends StatefulWidget {
  /// Creates a [RefreshControl].
  const RefreshControl({
    super.key,
    this.onRefresh,
    this.lastChecked,
    this.isLoading = false,
    this.tooltip,
    this.variant = CcButtonVariant.ghost,
  });

  /// Invoked when the refresh button is pressed. When null, no button renders.
  final VoidCallback? onRefresh;

  /// When the data was last successfully fetched. When null, no label renders.
  final DateTime? lastChecked;

  /// Whether a refresh is in flight; swaps the icon for a spinner and disables
  /// the button.
  final bool isLoading;

  /// Optional tooltip shown on the refresh button.
  final String? tooltip;

  /// Button variant, to match the surrounding toolbar (e.g. ghost).
  /// Defaults to [CcButtonVariant.ghost].
  final CcButtonVariant variant;

  @override
  State<RefreshControl> createState() => _RefreshControlState();
}

class _RefreshControlState extends State<RefreshControl> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Advance the relative label ("just now" -> "1 minute ago") without a data
    // refresh.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();

    final onPress = widget.isLoading ? null : widget.onRefresh;
    final Widget? button = widget.onRefresh == null
        ? null
        : widget.isLoading
            ? const SizedBox(
                width: 36,
                height: 36,
                child: Center(
                  child: SizedBox(width: 16, height: 16, child: CcSpinner()),
                ),
              )
            : CcIconButton(
                icon: AppIcons.refreshCw,
                variant: widget.variant,
                onPressed: onPress,
              );

    // Minute-granularity only — under a minute reads "Checked recently" rather
    // than counting seconds.
    final lastChecked = widget.lastChecked;
    final String? label = lastChecked == null
        ? null
        : DateTime.now().difference(lastChecked).inMinutes < 1
            ? l10n.lastCheckedRecently
            : l10n.lastChecked(formatRelativeTime(context, lastChecked));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: tokens.textTertiary,
              height: 1.2,
            ),
          ),
        if (button != null) ...[
          if (label != null) const SizedBox(width: AppSpacing.sm),
          if (widget.tooltip != null)
            CcTooltip(message: widget.tooltip!, child: button)
          else
            button,
        ],
      ],
    );
  }
}
