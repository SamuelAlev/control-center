import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider.dart';
import 'package:control_center/features/chat_bridges/providers/chat_bridge_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The caller's outstanding link code on one provider, with the chat profile
/// that claimed it once somebody sent it to the bot.
///
/// Watched because the claim happens in the chat app: the member sends the
/// code to the bot in a direct message and no client request returns while
/// that happens. The open link dialog and the "link my account" row both
/// follow this, so a claim made after the dialog closed still waits for its
/// confirmation in settings.
final chatPendingLinkProvider =
    StreamProvider.family<ChatLinkCodeView?, ChatProvider>((ref, provider) {
      final workspaceId = ref.watch(activeWorkspaceIdProvider);
      if (workspaceId == null) {
        return Stream.value(null);
      }
      return ref
          .watch(chatClientProvider)
          .watchPendingUserLink(workspaceId, provider);
    });

/// How the member answered a claim on their code.
class ChatLinkResolution {
  /// The member confirmed the profile; [link] is the link that made.
  const ChatLinkResolution.confirmed(ChatUserLinkView this.link);

  /// The member refused the profile; the code was revoked with it.
  const ChatLinkResolution.declined() : link = null;

  /// The new link, or null when the claim was declined.
  final ChatUserLinkView? link;

  /// Whether the claim was declined.
  bool get declined => link == null;
}

/// Confirms or declines the claim on the caller's code for one provider.
///
/// The state is the last answer: null while undecided, loading while the
/// server decides, an error the panel shows in place, or the resolution the
/// link dialog turns into its final view.
class ChatLinkClaimController
    extends Notifier<AsyncValue<ChatLinkResolution?>> {
  /// Creates the controller for [provider].
  ChatLinkClaimController(this.provider);

  /// The chat provider whose claim this answers.
  final ChatProvider provider;

  @override
  AsyncValue<ChatLinkResolution?> build() => const AsyncData(null);

  RpcChatClient get _client => ref.read(chatClientProvider);

  /// Forgets the last answer, so a fresh code starts undecided.
  void reset() => state = const AsyncData(null);

  /// Links the caller to [externalUserId], the profile that claimed the code.
  Future<void> confirm(String externalUserId) async {
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null || state.isLoading) {
      return;
    }
    state = const AsyncLoading();
    try {
      final link = await _client.confirmUserLink(
        workspaceId: workspaceId,
        provider: provider,
        externalUserId: externalUserId,
      );
      state = AsyncData(ChatLinkResolution.confirmed(link));
    } on Object catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Refuses the claim; nothing is linked and the code stops working.
  Future<void> decline() async {
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null || state.isLoading) {
      return;
    }
    state = const AsyncLoading();
    try {
      await _client.declineUserLink(workspaceId, provider);
      state = const AsyncData(ChatLinkResolution.declined());
    } on Object catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

/// Answers to claims on the caller's link codes, per provider.
final chatLinkClaimControllerProvider =
    NotifierProvider.family<
      ChatLinkClaimController,
      AsyncValue<ChatLinkResolution?>,
      ChatProvider
    >(ChatLinkClaimController.new);
