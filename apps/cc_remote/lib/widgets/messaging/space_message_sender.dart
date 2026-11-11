import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/l10n/app_localizations.dart';

/// Who a space message row names: a teammate's display name (their
/// username when they have none), "System" for the server's own notices,
/// else the agent's name.
String spaceMessageSenderLabel(
  MessageDto m, {
  required Map<String, UserDto> users,
  required String? agentName,
  required AppLocalizations l10n,
}) {
  if (m.senderType == 'user') {
    final user = users[m.senderId];
    if (user != null && user.displayName.isNotEmpty) {
      return user.displayName;
    }
    if (user != null && user.handle.isNotEmpty) {
      return '@${user.handle}';
    }
    return l10n.teammate;
  }
  if (m.senderType == 'system') {
    return l10n.systemSender;
  }
  return agentName ?? m.senderType;
}

/// The username shown beside a teammate's display name, or null when the
/// row has no teammate or already names them by it.
String? spaceMessageSenderHandle(
  MessageDto m, {
  required Map<String, UserDto> users,
}) {
  if (m.senderType != 'user') {
    return null;
  }
  final user = users[m.senderId];
  if (user == null || user.handle.isEmpty || user.displayName.isEmpty) {
    return null;
  }
  return user.handle;
}
