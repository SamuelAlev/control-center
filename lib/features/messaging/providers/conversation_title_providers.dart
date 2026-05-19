import 'package:cc_domain/features/messaging/domain/services/conversation_title_model.dart';
import 'package:control_center/features/settings/providers/workspace_settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The adapter that names the active workspace's new conversations (an
/// `Adapter.id` — `cc-harness`, `claude-code`, an ACP agent).
///
/// Null means automatic titling is OFF. The adapter is the switch, not the
/// model: a model id with nothing to run it on is not a runner, while an
/// adapter with no model means "use your own default".
///
/// Workspace-scoped rather than a per-user preference: the title is written
/// onto a conversation every member reads, so it cannot depend on who happened
/// to send the first message. Both keys ride the server-authoritative
/// `workspace_settings` lane, so an admin's change reaches every member live
/// and `ConversationTitleService` reads the same rows at generation time.
final conversationTitleAdapterProvider = Provider<String?>(
  (ref) => _nonEmpty(
    ref.watch(workspaceSettingProvider(kConversationTitleAdapterSettingKey)),
  ),
);

/// The model [conversationTitleAdapterProvider]'s adapter runs the titling
/// prompt on — a qualified `provider/model` id for `cc-harness`, whatever the
/// CLI advertises otherwise. Null lets the adapter pick its own default.
final conversationTitleModelProvider = Provider<String?>(
  (ref) => _nonEmpty(
    ref.watch(workspaceSettingProvider(kConversationTitleModelSettingKey)),
  ),
);

/// Persists the workspace's title adapter. A null/empty [adapterId] clears
/// both keys — titling off, and no orphan model id left naming a runner that
/// is no longer selected.
///
/// Writing null (rather than an empty string) deletes the row, so "off" is the
/// absence of a setting rather than a value the server has to special-case.
/// Admin-gated server-side by `workspace_settings.set`.
Future<void> setConversationTitleAdapter(
  WidgetRef ref,
  String? adapterId,
) async {
  final value = _nonEmpty(adapterId);
  // Re-picking the adapter already selected is not a change; treating it as
  // one would wipe a model the admin never touched.
  if (value == ref.read(conversationTitleAdapterProvider)) {
    return;
  }
  await setWorkspaceSetting(ref, kConversationTitleAdapterSettingKey, value);
  // Switching adapters invalidates the model too: model ids are per-adapter,
  // so carrying `anthropic/claude-haiku-4-5` over to Claude Code would name a
  // model that CLI has never heard of.
  await setWorkspaceSetting(ref, kConversationTitleModelSettingKey, null);
}

/// Persists the workspace's title model; a null/empty [modelId] clears it back
/// to the adapter's own default.
Future<void> setConversationTitleModel(WidgetRef ref, String? modelId) =>
    setWorkspaceSetting(
      ref,
      kConversationTitleModelSettingKey,
      _nonEmpty(modelId),
    );

String? _nonEmpty(String? raw) {
  final trimmed = raw?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}
