import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/l10n/app_localizations.dart';

/// Who a space message row names: a teammate's display name, "System" for
/// the server's own notices, else the agent's name. An older server wrote its
/// notices as `agent` from `system`, so the sender id decides too.
String spaceMessageSenderLabel(
  MessageDto m, {
  required Map<String, String> userNames,
  required String? agentName,
  required AppLocalizations l10n,
}) {
  if (m.senderType == 'user') {
    final name = userNames[m.senderId];
    return (name?.isNotEmpty ?? false) ? name! : l10n.teammate;
  }
  if (m.senderType == 'system' || m.senderId == 'system') {
    return l10n.systemSender;
  }
  return agentName ?? m.senderType;
}
