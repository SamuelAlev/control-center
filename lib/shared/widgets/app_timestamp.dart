import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/utils/relative_time.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Wraps any date/time display with the shared accessibility hover tooltip.
///
/// A relative label like "1m ago" is convenient but ambiguous — it hides the
/// absolute instant, the viewer's timezone, and the machine-readable value.
/// [AppTimestamp] keeps the compact display but, on hover or keyboard focus,
/// reveals a [CcTooltip] with three rows:
///
/// - the local zone (`GMT±H`) followed by the fully-resolved absolute time,
/// - the relative phrasing ("1 minute ago"),
/// - the raw ISO-8601 timestamp.
///
/// The tooltip is descriptive and non-interactive (per the tooltip contract);
/// **clicking the timestamp** copies the raw ISO value to the clipboard with a
/// confirmation toast. The absolute time is exposed to screen readers via
/// [Semantics] so the unambiguous value is available without a pointer.
///
/// Use [AppTimestamp.new] to wrap an existing display widget, or
/// [AppTimestamp.relative] to render the relative label itself.
class AppTimestamp extends StatelessWidget {
  /// Wraps [child] (the visible date display) with the tooltip for [dateTime].
  const AppTimestamp({super.key, required this.dateTime, required this.child})
    : _style = null,
      _relative = false;

  /// Renders the relative label for [dateTime] as the visible display, with the
  /// tooltip attached. [_style] styles the label text.
  const AppTimestamp.relative(this.dateTime, {super.key, this._style})
    : _relative = true,
      child = null;

  /// The instant this timestamp represents.
  final DateTime dateTime;

  /// The visible display. Null when [AppTimestamp.relative] renders its own.
  final Widget? child;

  final TextStyle? _style;
  final bool _relative;

  void _copy(BuildContext context) {
    final iso = dateTime.toUtc().toIso8601String();
    Clipboard.setData(ClipboardData(text: iso));
    CcToastScope.maybeOf(context)?.show(
      AppLocalizations.of(context).copiedTimestamp,
      variant: CcToastVariant.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final display = _relative
        ? Text(formatRelativeTime(context, dateTime), style: _style)
        : child!;

    // Announce the absolute, unambiguous time (plus the copy affordance) to
    // assistive tech regardless of hover — the relative label alone is not.
    final semanticLabel = '${_absoluteLabel(dateTime)}. ${l10n.copyTimestamp}';

    return CcTooltip(
      // A longer dwell than the default so casually sweeping the cursor across a
      // timestamp doesn't flash the card; keyboard focus still reveals it at
      // once (see CcTooltip).
      showDelay: const Duration(seconds: 1),
      maxWidth: 360,
      tip: AppTimestampDetails(dateTime: dateTime),
      child: Semantics(
        label: semanticLabel,
        button: true,
        container: true,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _copy(context),
            child: display,
          ),
        ),
      ),
    );
  }
}

/// The absolute label shown in the tooltip's first row and to screen readers,
/// e.g. `GMT+2  17 Jul 2026 19:40:05`.
String _absoluteLabel(DateTime dt) {
  final local = dt.toLocal();
  return '${_gmtLabel(local)}  ${DateFormat('d MMM y HH:mm:ss').format(local)}';
}

/// The local UTC offset as a `GMT±H[:MM]` label — the zone the time renders in.
String _gmtLabel(DateTime local) {
  final offset = local.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final hours = offset.inHours.abs();
  final minutes = offset.inMinutes.abs() % 60;
  return minutes == 0
      ? 'GMT$sign$hours'
      : 'GMT$sign$hours:${minutes.toString().padLeft(2, '0')}';
}

/// The three-row detail body (absolute, relative, raw ISO) rendered inside the
/// (dark) tooltip panel.
///
/// Public so other freshness surfaces can reuse the exact same card inside
/// their own [CcTooltip] `tip` (e.g. `RefreshControl`'s refresh-button hover);
/// use [AppTimestamp] itself whenever the trigger has no competing tap action.
class AppTimestampDetails extends StatelessWidget {
  /// Creates the detail rows for [dateTime].
  const AppTimestampDetails({super.key, required this.dateTime});

  /// The instant the rows describe.
  final DateTime dateTime;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final local = dateTime.toLocal();
    final iso = dateTime.toUtc().toIso8601String();
    // The tooltip panel is dark in both themes; label = dimmed white,
    // value = solid white.
    final labelColor = t.textWhite.withValues(alpha: 0.65);
    final valueColor = t.textWhite;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row(
          label: _gmtLabel(local),
          value: DateFormat('d MMM y HH:mm:ss').format(local),
          labelColor: labelColor,
          valueColor: valueColor,
        ),
        const SizedBox(height: AppSpacing.xs),
        _row(
          label: l10n.timestampRelativeLabel,
          value: formatRelativeTime(context, dateTime),
          labelColor: labelColor,
          valueColor: valueColor,
        ),
        const SizedBox(height: AppSpacing.xs),
        _row(
          label: l10n.timestampRawLabel,
          value: iso,
          labelColor: labelColor,
          valueColor: valueColor,
        ),
      ],
    );
  }

  Widget _row({
    required String label,
    required String value,
    required Color labelColor,
    required Color valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        SizedBox(
          width: 84,
          child: Text(
            label,
            textAlign: TextAlign.end,
            style: CcTypography.caption.copyWith(color: labelColor),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            value,
            style: CcTypography.bodySm.copyWith(color: valueColor),
          ),
        ),
      ],
    );
  }
}
