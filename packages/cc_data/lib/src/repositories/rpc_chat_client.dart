import 'package:cc_data/src/absent_op.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_app_creation.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_bot_profile.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_bridge_connection.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider_descriptor.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// One chat provider the server offers, plus this workspace's standing with it.
///
/// The pair is what the settings surface renders a card from: the descriptor says
/// what the provider needs and can do, the status says whether this workspace has
/// wired it up. A client that renders from this needs no per-provider code, which
/// is the whole point of the abstraction.
class ChatProviderView {
  /// Creates a [ChatProviderView].
  const ChatProviderView({required this.descriptor, required this.status});

  /// Parses one entry of the `chat.providers` wire list.
  factory ChatProviderView.fromWire(Map<String, dynamic> w) {
    final descriptor = ChatProviderDescriptor.fromJson(
      (w['descriptor'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
    final status = (w['status'] as Map?)?.cast<String, dynamic>();
    return ChatProviderView(
      descriptor: descriptor,
      status: status == null
          ? ChatConnectionStatus.none(descriptor.provider)
          : ChatConnectionStatus.fromJson(status),
    );
  }

  /// What the provider needs and can do.
  final ChatProviderDescriptor descriptor;

  /// Whether this workspace is connected and to what.
  final ChatConnectionStatus status;

  /// Which provider this is.
  ChatProvider get provider => descriptor.provider;
}

/// One chat↔Control Center identity link, as the settings roster shows it.
class ChatUserLinkView {
  /// Creates a [ChatUserLinkView].
  const ChatUserLinkView({
    required this.id,
    required this.provider,
    required this.externalUserId,
    required this.userId,
    required this.method,
    this.userHandle,
    this.userDisplayName,
    this.linkedAt,
  });

  /// Parses from the `chat.listUserLinks` wire map.
  factory ChatUserLinkView.fromWire(Map<String, dynamic> w) => ChatUserLinkView(
    id: w['id'] as String? ?? '',
    provider: ChatProvider.fromWire(w['provider'] as String?),
    externalUserId: w['externalUserId'] as String? ?? '',
    userId: w['userId'] as String? ?? '',
    method: w['method'] as String? ?? 'code',
    userHandle: w['userHandle'] as String?,
    userDisplayName: w['userDisplayName'] as String?,
    linkedAt: DateTime.tryParse(w['linkedAt'] as String? ?? ''),
  );

  /// Link row id.
  final String id;

  /// Which chat app the link is on.
  final ChatProvider provider;

  /// The provider-side member id (Slack `U…`, Discord snowflake).
  final String externalUserId;

  /// The Control Center user the chat member acts as.
  final String userId;

  /// How the link was established (`email` or `code`).
  final String method;

  /// The linked user's handle, when the server could resolve it.
  final String? userHandle;

  /// The linked user's display name, when the server could resolve it.
  final String? userDisplayName;

  /// When the link was made.
  final DateTime? linkedAt;

  /// The best label for the Control Center side of the link.
  String get userLabel => userDisplayName ?? userHandle ?? userId;
}

/// The chat profile that sent a member's link code to the bot, waiting for
/// that member to confirm it is theirs.
///
/// Sending the code only *claims* it. Nothing is linked until the member who
/// minted the code recognizes this profile in Control Center and confirms it.
class ChatLinkClaimView {
  /// Creates a [ChatLinkClaimView].
  const ChatLinkClaimView({
    required this.externalTeamId,
    required this.externalUserId,
    required this.label,
    this.claimedAt,
  });

  /// Parses the `claim` map of a pending link.
  factory ChatLinkClaimView.fromWire(Map<String, dynamic> w) =>
      ChatLinkClaimView(
        externalTeamId: w['externalTeamId'] as String? ?? '',
        externalUserId: w['externalUserId'] as String? ?? '',
        label: w['label'] as String? ?? '',
        claimedAt: DateTime.tryParse(w['claimedAt'] as String? ?? ''),
      );

  /// The provider-side team the sender belongs to.
  final String externalTeamId;

  /// The provider-side member who sent the code (Slack `U…`).
  final String externalUserId;

  /// Their display label as the provider reports it.
  final String label;

  /// When the code arrived.
  final DateTime? claimedAt;

  /// The best name for the profile: its label, else its id.
  String get displayName => label.isEmpty ? externalUserId : label;
}

/// A one-time code the member sends to the bot in a direct message, plus the
/// profile that sent it once somebody has.
class ChatLinkCodeView {
  /// Creates a [ChatLinkCodeView].
  const ChatLinkCodeView({
    required this.code,
    required this.expiresAt,
    this.claim,
  });

  /// Parses the `chat.beginUserLink` response.
  factory ChatLinkCodeView.fromWire(Map<String, dynamic> w) => ChatLinkCodeView(
    code: w['code'] as String? ?? '',
    expiresAt:
        DateTime.tryParse(w['expires_at'] as String? ?? '') ?? DateTime.now(),
  );

  /// Parses the `pending` map of `chat.pendingUserLink` /
  /// `chat.watchPendingUserLink`, which also carries the claim.
  factory ChatLinkCodeView.fromPendingWire(Map<String, dynamic> w) {
    final claim = (w['claim'] as Map?)?.cast<String, dynamic>();
    return ChatLinkCodeView(
      code: w['code'] as String? ?? '',
      expiresAt:
          DateTime.tryParse(w['expiresAt'] as String? ?? '') ?? DateTime.now(),
      claim: claim == null ? null : ChatLinkClaimView.fromWire(claim),
    );
  }

  /// The code to send to the bot.
  final String code;

  /// When it stops working.
  final DateTime expiresAt;

  /// Who sent it to the bot, once somebody has.
  final ChatLinkClaimView? claim;
}

/// A ticket a member drafted from chat (`/cc ticket …`), waiting for them to
/// create it in Control Center.
///
/// A draft is a proposal, never a ticket: it fires no ticket trigger and lives
/// only in the server's memory until its reporter creates or discards it.
class ChatTicketDraftView {
  /// Creates a [ChatTicketDraftView].
  const ChatTicketDraftView({
    required this.id,
    required this.provider,
    required this.title,
    this.description,
    this.createdAt,
    this.expiresAt,
  });

  /// Parses one entry of the `drafts` wire list.
  factory ChatTicketDraftView.fromWire(Map<String, dynamic> w) =>
      ChatTicketDraftView(
        id: w['id'] as String? ?? '',
        provider: ChatProvider.fromWire(w['provider'] as String?),
        title: w['title'] as String? ?? '',
        description: w['description'] as String?,
        createdAt: DateTime.tryParse(w['createdAt'] as String? ?? ''),
        expiresAt: DateTime.tryParse(w['expiresAt'] as String? ?? ''),
      );

  /// Opaque draft id.
  final String id;

  /// The chat app the command came from.
  final ChatProvider provider;

  /// The proposed ticket title.
  final String title;

  /// The proposed description, when one was given.
  final String? description;

  /// When the command arrived.
  final DateTime? createdAt;

  /// When the draft is dropped unconfirmed.
  final DateTime? expiresAt;
}

/// The backlog ticket a confirmed draft became.
class ChatCreatedTicket {
  /// Creates a [ChatCreatedTicket].
  const ChatCreatedTicket({
    required this.id,
    required this.key,
    required this.title,
  });

  /// Parses the `ticket` map of `chat.confirmTicketDraft`.
  factory ChatCreatedTicket.fromWire(Map<String, dynamic> w) =>
      ChatCreatedTicket(
        id: w['id'] as String? ?? '',
        key: w['key'] as String? ?? '',
        title: w['title'] as String? ?? '',
      );

  /// Ticket id.
  final String id;

  /// The ticket's display key (`CC-12`).
  final String key;

  /// The title it was created with.
  final String title;
}

/// Drives the workspace's chat-provider connections over RPC.
///
/// Credentials travel one way only: the client hands them to the server, which
/// stores them beside the workspace's database and dials the provider itself.
/// Nothing here ever reads one back — [status] carries connection *metadata*, so
/// a compromised client cannot lift a bot token out of a settings screen.
///
/// Every method takes a [ChatProvider]; none of them names one. A provider added
/// server-side shows up in [listProviders] and works through the same calls.
class RpcChatClient {
  /// Creates an [RpcChatClient] over [_client].
  RpcChatClient(this._client);

  final RemoteRpcClient _client;

  /// Every provider this server offers, with the workspace's status for each.
  Future<List<ChatProviderView>> listProviders(String workspaceId) async {
    final data = await _client.call('chat.providers', {
      'workspace_id': workspaceId,
    });
    return ((data['providers'] as List?) ?? const [])
        .whereType<Map>()
        .map((m) => ChatProviderView.fromWire(m.cast<String, dynamic>()))
        .toList();
  }

  /// The workspace's status on [provider] (credentials excluded).
  Future<ChatConnectionStatus> status(
    String workspaceId,
    ChatProvider provider,
  ) async {
    final data = await _client.readOr('chat.status', {
      'workspace_id': workspaceId,
      'provider': provider.wire,
    }, const {});
    return ChatConnectionStatus.fromJson(
      (data['status'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  /// Stores the workspace's credentials for [provider] and opens the connection.
  ///
  /// [credentials] is keyed by the descriptor's credential field ids, so the
  /// connect dialog can be generated from the descriptor and posted back as-is.
  Future<ChatConnectionStatus> connect({
    required String workspaceId,
    required ChatProvider provider,
    required Map<String, String> credentials,
  }) async {
    final data = await _client.call('chat.connect', {
      'workspace_id': workspaceId,
      'provider': provider.wire,
      'credentials': credentials,
    });
    return ChatConnectionStatus.fromJson(
      (data['status'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  /// Closes the connection and forgets the workspace's credentials.
  Future<void> disconnect(String workspaceId, ChatProvider provider) =>
      _client.call('chat.disconnect', {
        'workspace_id': workspaceId,
        'provider': provider.wire,
      });

  /// Every chat↔user link in the workspace, or only [provider]'s when given.
  Future<List<ChatUserLinkView>> userLinks(
    String workspaceId, {
    ChatProvider? provider,
  }) async {
    final data = await _client.readOr('chat.listUserLinks', {
      'workspace_id': workspaceId,
      'provider': ?provider?.wire,
    }, const {});
    return ((data['links'] as List?) ?? const [])
        .whereType<Map>()
        .map((m) => ChatUserLinkView.fromWire(m.cast<String, dynamic>()))
        .toList();
  }

  /// Watches the same roster, so a link made elsewhere (another client, an
  /// email match, an admin unlinking someone) shows up here without asking
  /// again.
  Stream<List<ChatUserLinkView>> watchUserLinks(
    String workspaceId, {
    ChatProvider? provider,
  }) => _client
      .subscribe('chat.watchUserLinks', {
        'workspace_id': workspaceId,
        'provider': ?provider?.wire,
      })
      .map(
        (data) => ((data['links'] as List?) ?? const [])
            .whereType<Map>()
            .map((m) => ChatUserLinkView.fromWire(m.cast<String, dynamic>()))
            .toList(),
      );

  /// Mints a one-time code for the CALLER to link their own chat account.
  Future<ChatLinkCodeView> beginUserLink(
    String workspaceId,
    ChatProvider provider,
  ) async {
    final data = await _client.call('chat.beginUserLink', {
      'workspace_id': workspaceId,
      'provider': provider.wire,
    });
    return ChatLinkCodeView.fromWire(data);
  }

  /// The caller's outstanding link code on [provider], with the profile that
  /// claimed it once one has, or null when there is none.
  Future<ChatLinkCodeView?> pendingUserLink(
    String workspaceId,
    ChatProvider provider,
  ) async {
    final data = await _client.call('chat.pendingUserLink', {
      'workspace_id': workspaceId,
      'provider': provider.wire,
    });
    return _pendingFromWire(data);
  }

  /// Watches the caller's outstanding code on [provider].
  ///
  /// The claim arrives from the chat app — the member sends the code to the
  /// bot in a direct message — so no client call could carry it back.
  Stream<ChatLinkCodeView?> watchPendingUserLink(
    String workspaceId,
    ChatProvider provider,
  ) => _client
      .subscribe('chat.watchPendingUserLink', {
        'workspace_id': workspaceId,
        'provider': provider.wire,
      })
      .map(_pendingFromWire);

  /// Links the caller to [externalUserId], the profile that claimed their
  /// code on [provider]. The server refuses any other profile.
  Future<ChatUserLinkView> confirmUserLink({
    required String workspaceId,
    required ChatProvider provider,
    required String externalUserId,
  }) async {
    final data = await _client.call('chat.confirmUserLink', {
      'workspace_id': workspaceId,
      'provider': provider.wire,
      'external_user_id': externalUserId,
    });
    return ChatUserLinkView.fromWire(
      (data['link'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  /// Refuses the claim on the caller's code on [provider]; the code is
  /// revoked with it.
  Future<void> declineUserLink(String workspaceId, ChatProvider provider) =>
      _client.call('chat.declineUserLink', {
        'workspace_id': workspaceId,
        'provider': provider.wire,
      });

  /// The caller's ticket drafts from chat, oldest first.
  Future<List<ChatTicketDraftView>> ticketDrafts(String workspaceId) async =>
      _draftsFromWire(
        await _client.call('chat.ticketDrafts', {'workspace_id': workspaceId}),
      );

  /// Watches the caller's ticket drafts: they arrive from a chat command.
  Stream<List<ChatTicketDraftView>> watchTicketDrafts(String workspaceId) =>
      _client
          .subscribe('chat.watchTicketDrafts', {'workspace_id': workspaceId})
          .map(_draftsFromWire);

  /// Creates the backlog ticket [draftId] proposes, with the [title] and
  /// [description] the caller corrected. An empty [description] clears it.
  Future<ChatCreatedTicket> confirmTicketDraft({
    required String workspaceId,
    required String draftId,
    String? title,
    String? description,
  }) async {
    final data = await _client.call('chat.confirmTicketDraft', {
      'workspace_id': workspaceId,
      'draft_id': draftId,
      'title': ?title,
      'description': ?description,
    });
    return ChatCreatedTicket.fromWire(
      (data['ticket'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  /// Drops [draftId] without creating anything.
  Future<void> discardTicketDraft(String workspaceId, String draftId) =>
      _client.call('chat.discardTicketDraft', {
        'workspace_id': workspaceId,
        'draft_id': draftId,
      });

  /// Unlinks [userId] on [provider] (the caller themselves when omitted; anyone
  /// else needs an admin role, which the server enforces).
  Future<void> unlinkUser(
    String workspaceId,
    ChatProvider provider, {
    String? userId,
  }) => _client.call('chat.unlinkUser', {
    'workspace_id': workspaceId,
    'provider': provider.wire,
    'user_id': ?userId,
  });

  /// Creates the workspace's provider-side app from [profile].
  ///
  /// [managementCredential] is the app-management secret the user pastes once. It
  /// goes to the server, which rotates it (a provider typically invalidates the
  /// presented one on every use) and keeps the replacement — so this is the only
  /// time the client ever handles one.
  Future<ChatAppCreation> createApp({
    required String workspaceId,
    required ChatProvider provider,
    required String managementCredential,
    required ChatBotProfile profile,
    String? workspaceName,
  }) async {
    final data = await _client.call('chat.createApp', {
      'workspace_id': workspaceId,
      'provider': provider.wire,
      'management_credential': managementCredential,
      'profile': profile.toJson(),
      'workspace_name': ?workspaceName,
    });
    return ChatAppCreation.fromJson(
      (data['creation'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  /// A link into the provider's own console that creates the app with [profile]
  /// pre-filled — the setup path that needs no credential at all.
  ///
  /// The server composes it (the manifest shape is its business, not the
  /// client's) but makes no request: the user's browser does, by following the
  /// URL this returns.
  Future<String> setupLink({
    required String workspaceId,
    required ChatProvider provider,
    required ChatBotProfile profile,
    String? workspaceName,
  }) async {
    final data = await _client.call('chat.setupLink', {
      'workspace_id': workspaceId,
      'provider': provider.wire,
      'profile': profile.toJson(),
      'workspace_name': ?workspaceName,
    });
    return data['url'] as String? ?? '';
  }

  /// The customizable fields of the workspace's provider-side app, read live.
  Future<ChatBotProfile> botProfile(
    String workspaceId,
    ChatProvider provider,
  ) async {
    final data = await _client.call('chat.botProfile', {
      'workspace_id': workspaceId,
      'provider': provider.wire,
    });
    return ChatBotProfile.fromJson(
      (data['profile'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  /// Applies [profile] to the workspace's provider-side app.
  ///
  /// Returns the step left to finish — a permission change usually needs the app
  /// reinstalled before it does anything — or null when the edit is live. The
  /// step carries its own link, so the caller shows a reinstall button without
  /// knowing which provider it belongs to.
  Future<ChatSetupStep?> updateBotProfile({
    required String workspaceId,
    required ChatProvider provider,
    required ChatBotProfile profile,
  }) async {
    final data = await _client.call('chat.updateBotProfile', {
      'workspace_id': workspaceId,
      'provider': provider.wire,
      'profile': profile.toJson(),
    });
    final step = (data['remaining_step'] as Map?)?.cast<String, dynamic>();
    return step == null ? null : ChatSetupStep.fromJson(step);
  }

  static ChatLinkCodeView? _pendingFromWire(Map<String, dynamic> data) {
    final pending = (data['pending'] as Map?)?.cast<String, dynamic>();
    return pending == null ? null : ChatLinkCodeView.fromPendingWire(pending);
  }

  static List<ChatTicketDraftView> _draftsFromWire(Map<String, dynamic> data) =>
      ((data['drafts'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => ChatTicketDraftView.fromWire(m.cast<String, dynamic>()))
          .toList();
}
