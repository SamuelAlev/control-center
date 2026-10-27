/// Prefixes of command-palette IDs that carry an entity after a `-`
/// (`pr-123`, `member-<login>`, `ticket-<id>`).
const _dynamicDashPrefixes = {
  'entry',
  'eval',
  'goal',
  'member',
  'pr',
  'server',
  'thread',
  'ticket',
};

/// The part of a command ID that is safe to report.
///
/// Static commands (`inbox`, `new-ticket`, `toggle-focus-mode`) report as
/// themselves. Entries built per entity (`space:<ws>:<space>`,
/// `member-<login>`, `pr-42`) report only their kind (`space`, `member`,
/// `pr`), because the rest is an identifier, a login or a number.
String commandAnalyticsId(String id) {
  final colon = id.indexOf(':');
  if (colon > 0) {
    return id.substring(0, colon);
  }
  final dash = id.indexOf('-');
  if (dash > 0 && _dynamicDashPrefixes.contains(id.substring(0, dash))) {
    return id.substring(0, dash);
  }
  return RegExp(r'^[A-Za-z][A-Za-z0-9_.-]{0,60}$').hasMatch(id) &&
          !RegExp('[0-9]').hasMatch(id)
      ? id
      : 'other';
}
