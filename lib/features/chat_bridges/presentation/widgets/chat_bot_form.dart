import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_bot_profile.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// The editable face of the workspace's chat bot, shared by the create and
/// customize dialogs.
///
/// Owns its text controllers and reports the whole profile on every keystroke, so
/// the dialogs stay thin: they decide what "save" means, not what a bot is.
class ChatBotForm extends StatefulWidget {
  /// Creates a [ChatBotForm] seeded with [initial].
  const ChatBotForm({
    required this.initial,
    required this.providerName,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  /// The profile the fields start from.
  final ChatBotProfile initial;

  /// The provider's product name, for the copy that has to name it.
  final String providerName;

  /// Called with the edited profile whenever a field changes.
  final ValueChanged<ChatBotProfile> onChanged;

  /// Whether the fields accept input (false while a save is in flight).
  final bool enabled;

  @override
  State<ChatBotForm> createState() => _ChatBotFormState();
}

class _ChatBotFormState extends State<ChatBotForm> {
  late final TextEditingController _appName;
  late final TextEditingController _botName;
  late final TextEditingController _description;
  late final TextEditingController _agentDescription;
  late final TextEditingController _command;
  late bool _agentEnabled;

  @override
  void initState() {
    super.initState();
    _appName = TextEditingController(text: widget.initial.appName);
    _botName = TextEditingController(text: widget.initial.botDisplayName);
    _description = TextEditingController(text: widget.initial.description);
    _agentDescription = TextEditingController(
      text: widget.initial.agentDescription,
    );
    _command = TextEditingController(text: widget.initial.command);
    _agentEnabled = widget.initial.agentEnabled;
  }

  @override
  void dispose() {
    _appName.dispose();
    _botName.dispose();
    _description.dispose();
    _agentDescription.dispose();
    _command.dispose();
    super.dispose();
  }

  void _emit() => widget.onChanged(
    ChatBotProfile(
      appName: _appName.text.trim(),
      botDisplayName: _botName.text.trim(),
      description: _description.text.trim(),
      agentDescription: _agentDescription.text.trim(),
      // Normalized here so the field can show what a provider will actually
      // accept rather than silently diverging from it.
      command: ChatBotProfile.normalizeCommand(_command.text),
      agentEnabled: _agentEnabled,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final hint = CcTypography.caption.copyWith(
      color: t.textTertiary,
      height: 1.45,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CcTextField(
          controller: _appName,
          label: l10n.chatAppNameLabel,
          enabled: widget.enabled,
          maxLength: 35,
          autofocus: true,
          onChanged: (_) => _emit(),
        ),
        const SizedBox(height: 12),
        CcTextField(
          controller: _botName,
          label: l10n.chatBotDisplayNameLabel,
          enabled: widget.enabled,
          maxLength: 80,
          onChanged: (_) => _emit(),
        ),
        const SizedBox(height: 12),
        CcTextField(
          controller: _description,
          label: l10n.chatDescriptionLabel,
          enabled: widget.enabled,
          maxLength: 140,
          onChanged: (_) => _emit(),
        ),
        const SizedBox(height: 12),
        CcTextField(
          controller: _agentDescription,
          label: l10n.chatAgentDescriptionLabel,
          enabled: widget.enabled,
          maxLength: 300,
          minLines: 2,
          maxLines: 4,
          onChanged: (_) => _emit(),
        ),
        const SizedBox(height: 12),
        CcTextField(
          controller: _command,
          label: l10n.chatCommandLabel,
          // The provider owns the slash; the field owns the name after it.
          prefix: Text(
            '/',
            style: CcFonts.code(
              textStyle: CcTypography.bodySm.copyWith(color: t.textTertiary),
            ),
          ),
          enabled: widget.enabled,
          maxLength: 32,
          onChanged: (_) => _emit(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.chatDirectMessages,
                    style: CcTypography.bodySm.copyWith(color: t.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.chatDirectMessagesHint(widget.providerName),
                    style: hint,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            CcSwitch(
              value: _agentEnabled,
              onChanged: widget.enabled
                  ? (value) {
                      setState(() => _agentEnabled = value);
                      _emit();
                    }
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(l10n.chatIconNotEditable(widget.providerName), style: hint),
      ],
    );
  }
}
