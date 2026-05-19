import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_app_creation.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider_descriptor.dart';
import 'package:control_center/l10n/app_localizations.dart';

/// Localizes the descriptor-driven parts of the chat-bridge UI.
///
/// The descriptor is server data: its labels and hints are authored in English,
/// like an MCP tool description. The client localizes what it *recognizes* — by
/// the stable field/step **id**, never by matching text — and falls back to the
/// server's English for anything it has never heard of.
///
/// That fallback is what keeps a new provider from needing a client release: its
/// dialog renders immediately in English, and translating it later is adding a
/// case here.
extension ChatCredentialFieldL10n on ChatCredentialField {
  /// The field's label, translated when this client knows the id.
  String localizedLabel(AppLocalizations l10n) {
    final base = switch (id) {
      'botToken' => l10n.chatFieldBotToken,
      'appToken' => l10n.chatFieldAppToken,
      'configRefreshToken' => l10n.chatFieldConfigRefreshToken,
      _ => label,
    };
    return required ? base : l10n.chatFieldOptional(base);
  }
}

/// The same seam for the steps a provider has no API for.
extension ChatSetupStepL10n on ChatSetupStep {
  /// The step's title, translated when this client knows the id.
  String localizedTitle(AppLocalizations l10n) => switch (id) {
    'appToken' => l10n.chatStepAppToken,
    'install' => l10n.chatStepInstall,
    _ => title,
  };
}
