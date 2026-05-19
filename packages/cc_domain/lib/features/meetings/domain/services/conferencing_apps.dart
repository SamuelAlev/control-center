/// Catalog of known video-conferencing apps and meeting URLs, used by the
/// signal collectors to recognize a meeting in progress. Pure data + matching
/// so it unit-tests cleanly and is shared by every per-OS collector.
library;

/// One conferencing product and how to recognize it.
class ConferencingApp {
  /// Creates a [ConferencingApp].
  const ConferencingApp({
    required this.name,
    this.processNames = const [],
    this.urlHosts = const [],
    this.persistent = false,
  });

  /// Display name (used as the signal label).
  final String name;

  /// Lower-case substrings to match against a running process / executable name.
  final List<String> processNames;

  /// Host substrings that identify a meeting URL for this product.
  final List<String> urlHosts;

  /// Whether the desktop app typically runs in the background all day (Teams,
  /// Slack, Discord). The process collector ignores these — a running process
  /// is NOT evidence of a live meeting for them; they need the native
  /// frontmost-window / audio seam to be detected reliably.
  final bool persistent;
}

/// The known conferencing apps. Per-meeting clients (Zoom, Webex, …) are
/// launched for a call and quit afterward, so their mere presence is a usable
/// signal. Persistent clients are flagged so the process collector skips them.
const List<ConferencingApp> conferencingApps = [
  ConferencingApp(
    name: 'Zoom',
    processNames: ['zoom.us', 'zoom', 'caphost', 'aomhost'],
    urlHosts: ['zoom.us'],
  ),
  ConferencingApp(
    name: 'Google Meet',
    urlHosts: ['meet.google.com'],
  ),
  ConferencingApp(
    name: 'Microsoft Teams',
    processNames: ['teams', 'msteams', 'ms-teams'],
    urlHosts: ['teams.microsoft.com', 'teams.live.com'],
    persistent: true,
  ),
  ConferencingApp(
    name: 'Webex',
    processNames: ['webex', 'ciscowebex', 'webexmta', 'webexhost'],
    urlHosts: ['webex.com'],
  ),
  ConferencingApp(
    name: 'Slack',
    processNames: ['slack'],
    urlHosts: ['app.slack.com'],
    persistent: true,
  ),
  ConferencingApp(
    name: 'Discord',
    processNames: ['discord'],
    urlHosts: ['discord.com/channels'],
    persistent: true,
  ),
  ConferencingApp(
    name: 'GoTo Meeting',
    processNames: ['gotomeeting', 'g2mstart', 'g2mcomm'],
    urlHosts: ['gotomeeting.com'],
  ),
  ConferencingApp(
    name: 'BlueJeans',
    processNames: ['bluejeans'],
    urlHosts: ['bluejeans.com'],
  ),
  ConferencingApp(
    name: 'Around',
    processNames: ['around'],
    urlHosts: ['around.co'],
  ),
];

/// Returns the per-meeting (non-[ConferencingApp.persistent]) app whose process
/// name matches [processLine] (case-insensitive substring), or null. Persistent
/// apps are intentionally excluded — see [ConferencingApp.persistent].
ConferencingApp? matchPerMeetingProcess(String processLine) {
  final hay = processLine.toLowerCase();
  for (final app in conferencingApps) {
    if (app.persistent) {
      continue;
    }
    for (final needle in app.processNames) {
      if (hay.contains(needle)) {
        return app;
      }
    }
  }
  return null;
}

/// Returns the conferencing app whose URL host matches [url], or null. Includes
/// persistent apps (a meeting URL IS evidence even for Teams/Slack).
ConferencingApp? matchMeetingUrl(String url) {
  final hay = url.toLowerCase();
  for (final app in conferencingApps) {
    for (final host in app.urlHosts) {
      if (hay.contains(host)) {
        return app;
      }
    }
  }
  return null;
}
