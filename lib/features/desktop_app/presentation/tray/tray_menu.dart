import 'package:control_center/core/desktop/desktop_shell.dart';
import 'package:control_center/features/desktop_app/providers/tray_status_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:intl/intl.dart' show NumberFormat;

/// Ids of the tray's native menu lines.
abstract final class TrayMenuIds {
  /// Show the main window.
  static const String open = 'open';

  /// Show the main window on the settings.
  static const String settings = 'settings';

  /// Show the main window on the inbox (where approvals wait).
  static const String inbox = 'inbox';

  /// Quit the app.
  static const String quit = 'quit';

  /// Prefix of a line opening one space: `space:<id>`.
  static const String spacePrefix = 'space:';
}

/// How many menu lines name individual spaces before the rest is left to
/// the panel and the app.
const int _maxSpaceLines = 5;

/// One line saying what the tray is about: the connection when it is down,
/// else what waits on the operator and what is working.
String trayStatusSummary(TrayStatus status, AppLocalizations l10n) {
  switch (status.connection) {
    case TrayConnection.offline:
      return l10n.trayStatusOffline;
    case TrayConnection.connecting:
      return l10n.trayStatusReconnecting;
    case TrayConnection.online:
      break;
  }
  final parts = [
    if (status.needsYou > 0) l10n.trayStatusNeedsYou(status.needsYou),
    if (status.workingSpaces > 0) l10n.trayStatusWorking(status.workingSpaces),
  ];
  return parts.isEmpty ? l10n.trayStatusAllQuiet : parts.join(' · ');
}

/// The tray icon for [status]: its glyph, hover text and, on macOS, the
/// count of waiting items beside the glyph.
TrayIconSpec trayIconSpecFor(TrayStatus status, AppLocalizations l10n) {
  final waiting =
      status.connection == TrayConnection.online && status.needsYou > 0;
  return TrayIconSpec(
    tone: status.tone,
    tooltip: l10n.trayTooltip(trayStatusSummary(status, l10n)),
    badge: waiting
        ? NumberFormat.decimalPattern(l10n.localeName).format(status.needsYou)
        : null,
  );
}

/// The tray's native context menu for [status].
///
/// The menu is the whole tray on hosts that never report a primary click
/// (GNOME's AppIndicator extension opens it on any click), so it carries what
/// waits on the operator, not only the app commands.
List<TrayMenuEntry> trayMenuFor(TrayStatus status, AppLocalizations l10n) => [
  TrayMenuCaption(trayStatusSummary(status, l10n)),
  if (status.connection == TrayConnection.online && status.needsYou > 0) ...[
    const TrayMenuSeparator(),
    for (final space in status.attention.take(_maxSpaceLines))
      TrayMenuAction(
        id: '${TrayMenuIds.spacePrefix}${space.spaceId}',
        label: l10n.trayMenuSpaceQuestions(
          space.name.isEmpty ? l10n.spaceLabel : space.name,
          space.openQuestions,
        ),
      ),
    if (status.approvals > 0)
      TrayMenuAction(
        id: TrayMenuIds.inbox,
        label: l10n.trayApprovalsWaiting(status.approvals),
      ),
  ],
  const TrayMenuSeparator(),
  TrayMenuAction(id: TrayMenuIds.open, label: l10n.trayMenuOpen),
  TrayMenuAction(id: TrayMenuIds.settings, label: l10n.trayMenuSettings),
  const TrayMenuSeparator(),
  TrayMenuAction(id: TrayMenuIds.quit, label: l10n.trayMenuQuit),
];
