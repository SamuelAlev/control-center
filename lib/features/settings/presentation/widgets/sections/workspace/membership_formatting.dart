import 'package:control_center/l10n/app_localizations.dart';

export 'package:control_center/shared/utils/avatar_initials.dart'
    show avatarInitials;

/// Localized label for a workspace-role wire name (`owner`, `admin`, `member`,
/// `viewer`, `guest`). Unknown values fall back to the raw wire string so a
/// newer server never renders an empty chip.
String workspaceRoleLabel(AppLocalizations l10n, String wireRole) =>
    switch (wireRole) {
      'owner' => l10n.roleOwner,
      'admin' => l10n.roleAdmin,
      'member' => l10n.roleMember,
      'viewer' => l10n.roleViewer,
      'guest' => l10n.roleGuest,
      _ => wireRole,
    };

/// Localized coarse "N ago" label for [dt] (relative to now).
String relativeTimeLabel(AppLocalizations l10n, DateTime dt) {
  final diff = DateTime.now().difference(dt.toLocal());
  if (diff.inMinutes < 1) {
    return l10n.relativeJustNow;
  }
  if (diff.inMinutes < 60) {
    return l10n.relativeMinutesAgo(diff.inMinutes);
  }
  if (diff.inHours < 24) {
    return l10n.relativeHoursAgo(diff.inHours);
  }
  return l10n.relativeDaysAgo(diff.inDays);
}

/// Formats [dt] (converted to local time) as a compact `yyyy-MM-dd` date.
String shortDateLabel(DateTime dt) {
  final local = dt.toLocal();
  final mo = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '${local.year}-$mo-$d';
}
