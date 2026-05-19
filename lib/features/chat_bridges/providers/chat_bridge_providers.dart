import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_app_creation.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_bot_profile.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_bridge_connection.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The chat-bridge surface (`chat.*` ops) over the RPC client.
///
/// Everything provider-related lives on the server: the credentials, the
/// transport, the bridge. This client only reads status and pushes actions.
final chatClientProvider = Provider<RpcChatClient>(
  (ref) => RpcChatClient(ref.watch(rpcClientProvider)),
);

/// Every chat provider this server offers, with the active workspace's status.
///
/// The one read the settings surface renders from: a card per entry, its boxes
/// and buttons generated from the descriptor. Watches [activeWorkspaceIdProvider]
/// so switching workspaces re-reads — a chat app belongs to one workspace and
/// showing another's bot as connected here would be a lie.
final chatProvidersProvider = FutureProvider<List<ChatProviderView>>((
  ref,
) async {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return const [];
  }
  return ref.watch(chatClientProvider).listProviders(workspaceId);
});

/// The workspace's chat↔Control Center identity links (the settings roster).
///
/// One roster across providers: a member's Slack and Discord links are two rows
/// in the same table, so the surface does not fragment per provider.
///
/// Watched rather than fetched, because a link is made in the *chat app*: the
/// member types the one-time code into the bot and no client request returns
/// while that happens. The roster and the open link dialog both follow this
/// stream so the moment the row lands, both say so.
final chatUserLinksProvider = StreamProvider<List<ChatUserLinkView>>((ref) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return Stream.value(const []);
  }
  return ref.watch(chatClientProvider).watchUserLinks(workspaceId);
});

/// The workspace's provider-side app as the provider itself describes it, for the
/// customize dialog.
///
/// Reads the live app rather than a local copy, so a change made in the
/// provider's own UI is what the dialog edits. Costs a management-credential
/// rotation, which is why it is not part of [chatProvidersProvider] — the
/// settings card must not pay for it on every visit.
final chatBotProfileProvider =
    FutureProvider.family<ChatBotProfile, ChatProvider>((ref, provider) async {
      final workspaceId = ref.watch(activeWorkspaceIdProvider);
      if (workspaceId == null) {
        return ChatBotProfile.initial();
      }
      return ref.watch(chatClientProvider).botProfile(workspaceId, provider);
    });

/// Connect / disconnect / unlink, plus minting a personal link code.
///
/// A [Notifier] rather than plain calls from the widget because each action has
/// to invalidate the two reads above: the provider cards and the roster are
/// server-owned, so nothing is optimistic here.
///
/// Every method takes the [ChatProvider] it acts on. The controller is shared
/// across cards on purpose — its `AsyncValue` is the *last action's* state and a
/// settings screen only ever has one action in flight.
class ChatConnectionController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  String? get _workspaceId => ref.read(activeWorkspaceIdProvider);

  RpcChatClient get _client => ref.read(chatClientProvider);

  /// Forgets the last failure, so reopening a dialog does not greet the user
  /// with the error from a previous attempt.
  void reset() => state = const AsyncData(null);

  /// Stores the pasted credentials and opens the connection.
  ///
  /// [credentials] is keyed by the descriptor's field ids, so the dialog that
  /// collected them never had to know which provider it was rendering.
  Future<void> connect({
    required ChatProvider provider,
    required Map<String, String> credentials,
  }) async {
    final workspaceId = _workspaceId;
    if (workspaceId == null) {
      return;
    }
    state = const AsyncLoading();
    try {
      await _client.connect(
        workspaceId: workspaceId,
        provider: provider,
        credentials: credentials,
      );
      state = const AsyncData(null);
    } on Object catch (e, st) {
      state = AsyncError(e, st);
      // The caller (the connect dialog) renders the message; rethrowing would
      // also surface it as an unhandled provider error.
      return;
    }
    _refresh();
  }

  /// Closes the connection and forgets the credentials.
  Future<void> disconnect(ChatProvider provider) async {
    final workspaceId = _workspaceId;
    if (workspaceId == null) {
      return;
    }
    state = const AsyncLoading();
    try {
      await _client.disconnect(workspaceId, provider);
      state = const AsyncData(null);
    } on Object catch (e, st) {
      state = AsyncError(e, st);
      return;
    }
    _refresh();
  }

  /// Mints the one-time code for the caller's own `/cc link CODE`.
  Future<ChatLinkCodeView?> beginMyLink(ChatProvider provider) async {
    final workspaceId = _workspaceId;
    if (workspaceId == null) {
      return null;
    }
    return _client.beginUserLink(workspaceId, provider);
  }

  /// Removes a member's link on [provider].
  Future<void> unlink(ChatProvider provider, String userId) async {
    final workspaceId = _workspaceId;
    if (workspaceId == null) {
      return;
    }
    await _client.unlinkUser(workspaceId, provider, userId: userId);
    _refresh();
  }

  /// Creates the workspace's provider-side app from [profile].
  ///
  /// Returns whatever the provider has no API for (generating a socket token,
  /// installing the app); the dialog walks the user through those steps and they
  /// finish in [connect].
  Future<ChatAppCreation?> createApp({
    required ChatProvider provider,
    required String managementCredential,
    required ChatBotProfile profile,
  }) async {
    final workspaceId = _workspaceId;
    if (workspaceId == null) {
      return null;
    }
    state = const AsyncLoading();
    try {
      final creation = await _client.createApp(
        workspaceId: workspaceId,
        provider: provider,
        managementCredential: managementCredential,
        profile: profile,
        workspaceName: ref.read(activeWorkspaceProvider)?.name,
      );
      state = const AsyncData(null);
      return creation;
    } on Object catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  /// The provider-console link that creates the app with [profile] pre-filled.
  ///
  /// The credential-free counterpart to [createApp]: nothing is stored and the
  /// provider is not dialed, so there is nothing to invalidate afterwards — the
  /// user finishes in the provider's UI and comes back through [connect].
  Future<String?> setupLink({
    required ChatProvider provider,
    required ChatBotProfile profile,
  }) async {
    final workspaceId = _workspaceId;
    if (workspaceId == null) {
      return null;
    }
    state = const AsyncLoading();
    try {
      final url = await _client.setupLink(
        workspaceId: workspaceId,
        provider: provider,
        profile: profile,
        workspaceName: ref.read(activeWorkspaceProvider)?.name,
      );
      state = const AsyncData(null);
      return url;
    } on Object catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  /// Applies [profile] to the workspace's provider-side app.
  ///
  /// Returns a [ChatBotUpdate]: whether the write happened at all and the step
  /// left to finish when the provider needs one (a permission change stays inert
  /// until the app is reinstalled, so the caller has to say so instead of
  /// implying the edit is fully live).
  Future<ChatBotUpdate> updateBotProfile({
    required ChatProvider provider,
    required ChatBotProfile profile,
  }) async {
    final workspaceId = _workspaceId;
    if (workspaceId == null) {
      return const ChatBotUpdate.failed();
    }
    state = const AsyncLoading();
    try {
      final remaining = await _client.updateBotProfile(
        workspaceId: workspaceId,
        provider: provider,
        profile: profile,
      );
      state = const AsyncData(null);
      _refresh();
      ref.invalidate(chatBotProfileProvider(provider));
      return ChatBotUpdate.saved(remaining);
    } on Object catch (e, st) {
      state = AsyncError(e, st);
      return const ChatBotUpdate.failed();
    }
  }

  /// Re-reads the provider cards after an action changed them.
  ///
  /// The roster is deliberately not invalidated: it is a live stream and
  /// dropping it would flick the settings surface back to a spinner for a change
  /// the server is already pushing.
  void _refresh() => ref.invalidate(chatProvidersProvider);
}

/// The outcome of a bot-profile save.
///
/// Distinguishes "saved, nothing left to do" from "saved, but the provider needs
/// a step finished" from "did not save" — three states a nullable step alone
/// cannot carry and the dialog behaves differently in each.
class ChatBotUpdate {
  /// The write landed, with [remainingStep] left to finish when non-null.
  const ChatBotUpdate.saved(this.remainingStep) : didSave = true;

  /// The write did not happen; the controller's error state says why.
  const ChatBotUpdate.failed() : didSave = false, remainingStep = null;

  /// Whether the provider accepted the edit.
  final bool didSave;

  /// What the user must still do for the edit to take effect, if anything.
  final ChatSetupStep? remainingStep;
}

/// Actions on the workspace's chat connections.
final chatConnectionControllerProvider =
    NotifierProvider<ChatConnectionController, AsyncValue<void>>(
      ChatConnectionController.new,
    );

/// A provider's status without waiting on the whole list, for a dialog that was
/// opened from a card that already had it.
ChatConnectionStatus chatStatusFor(
  List<ChatProviderView> views,
  ChatProvider provider,
) =>
    views
        .where((v) => v.provider == provider)
        .map((v) => v.status)
        .firstOrNull ??
    ChatConnectionStatus.none(provider);
