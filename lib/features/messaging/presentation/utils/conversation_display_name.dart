import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:control_center/l10n/app_localizations.dart';

/// The conversation's title, or the localized placeholder while it is empty.
///
/// Titles are optional at creation: the title model names a conversation once
/// its first human message lands (Settings → You → Conversation titles), so an
/// empty title is a real state the UI must render, not a bug.
String conversationDisplayName(
  Conversation conversation,
  AppLocalizations l10n,
) {
  final title = conversation.title.trim();
  return title.isNotEmpty ? title : l10n.untitledConversation;
}
