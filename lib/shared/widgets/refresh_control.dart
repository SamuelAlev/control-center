import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/relative_time.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:flutter/widgets.dart';

/// A refresh icon button whose hover card reports data freshness.
///
/// Mirrors the GitHub status indicator pattern so every remote-data surface
/// reports how stale its data is — but the freshness lives in the button's
/// tooltip rather than beside it: hovering (or keyboard-focusing) the refresh
/// icon reveals the shared [AppTimestampDetails] card (absolute time, relative
/// phrasing, raw ISO). While [isLoading] the icon spins in place and the button
/// stops responding.
///
/// When [onRefresh] is null (surfaces whose refresh lives elsewhere, e.g. a
/// menu item) a quiet clock glyph wrapped in [AppTimestamp] carries the same
/// hover card instead; with neither [onRefresh] nor [lastChecked] nothing
/// renders.
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

  /// When the data was last successfully fetched. When null, the button's
  /// hover card degrades to a plain action tooltip.
  final DateTime? lastChecked;

  /// Whether a refresh is in flight; spins the icon and disables the button.
  final bool isLoading;

  /// The refresh action's name, used as the button's accessible name and as
  /// its plain tooltip when there is no [lastChecked] to report. Defaults to
  /// the localized "Refresh".
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
    // Advance the freshness phrasing in the button's accessible name ("Checked
    // recently" -> "Checked 1 minute ago") without a data refresh. The hover
    // card needs no ticker — it is built fresh each time it opens.
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
    final lastChecked = widget.lastChecked;

    if (widget.onRefresh == null) {
      if (lastChecked == null) {
        return const SizedBox.shrink();
      }
      final tokens = context.designSystem ?? DesignSystemTokens.light();
      // Freshness-only indicator: the shared timestamp hover card (and its
      // click-to-copy) on a quiet clock glyph.
      return AppTimestamp(
        dateTime: lastChecked,
        child: Icon(AppIcons.clock, size: 16, color: tokens.textTertiary),
      );
    }

    final actionLabel = widget.tooltip ?? l10n.refresh;
    final checkedLabel = lastChecked == null
        ? null
        : _checkedLabel(context, lastChecked);
    final button = CcIconButton(
      icon: AppIcons.refreshCw,
      variant: widget.variant,
      loading: widget.isLoading,
      // The freshness rides along in the accessible name — the hover card
      // itself is never read by assistive tech.
      semanticLabel: checkedLabel == null
          ? actionLabel
          : '$actionLabel. $checkedLabel',
      onPressed: widget.onRefresh,
    );

    if (lastChecked == null) {
      return CcTooltip(message: actionLabel, child: button);
    }
    return CcTooltip(
      maxWidth: 360,
      tip: AppTimestampDetails(dateTime: lastChecked),
      child: button,
    );
  }
}

/// Minute-granularity freshness phrasing — under a minute reads "Checked
/// recently" rather than counting seconds.
String _checkedLabel(BuildContext context, DateTime lastChecked) {
  final l10n = AppLocalizations.of(context);
  return DateTime.now().difference(lastChecked).inMinutes < 1
      ? l10n.lastCheckedRecently
      : l10n.lastChecked(formatRelativeTime(context, lastChecked));
}
