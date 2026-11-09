import 'dart:async';
import 'dart:math';

import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider.dart';

/// The chat identity that sent a link code to the bot, waiting for the member
/// who minted the code to confirm it in Control Center.
class ChatLinkClaim {
  /// Creates a [ChatLinkClaim].
  const ChatLinkClaim({
    required this.externalTeamId,
    required this.externalUserId,
    required this.label,
    required this.conversationId,
    required this.claimedAt,
  });

  /// The provider-side team the sender belongs to.
  final String externalTeamId;

  /// The provider-side member who sent the code.
  final String externalUserId;

  /// Their display label, so the person confirming can recognize the profile.
  final String label;

  /// The direct-message conversation the code arrived in, where the bot
  /// confirms the link once it is made.
  final String conversationId;

  /// When the code arrived.
  final DateTime claimedAt;

  /// The wire shape (never carries the code).
  Map<String, Object?> toJson() => {
    'externalTeamId': externalTeamId,
    'externalUserId': externalUserId,
    'label': label,
    'claimedAt': claimedAt.toUtc().toIso8601String(),
  };
}

/// A one-time code a workspace member sends to the chat bot in a direct
/// message to prove that a chat identity is theirs.
///
/// Sending the code only *claims* it ([claim]); the link is made when the
/// member confirms that exact profile inside Control Center. Neither half alone
/// links anything: the code proves the Control Center side, the direct message
/// the chat side, and the confirmation that the two are the same person.
class ChatLinkCode {
  /// Creates a [ChatLinkCode].
  const ChatLinkCode({
    required this.code,
    required this.workspaceId,
    required this.provider,
    required this.userId,
    required this.expiresAt,
    this.claim,
  });

  /// The code the user sends to the bot.
  final String code;

  /// The workspace whose chat app the link is for.
  final String workspaceId;

  /// The provider the code may be redeemed on.
  final ChatProvider provider;

  /// The Control Center user the code was minted for.
  final String userId;

  /// When the code stops being accepted.
  final DateTime expiresAt;

  /// Who sent the code to the bot, once somebody has.
  final ChatLinkClaim? claim;

  /// A copy carrying [claim].
  ChatLinkCode claimedBy(ChatLinkClaim claim) => ChatLinkCode(
    code: code,
    workspaceId: workspaceId,
    provider: provider,
    userId: userId,
    expiresAt: expiresAt,
    claim: claim,
  );
}

/// A change to one member's outstanding code, for watchers.
typedef ChatLinkCodeChange = ({
  String workspaceId,
  ChatProvider provider,
  String userId,
});

/// Short-lived, single-use codes for the chat↔Control Center link flow.
///
/// Deliberately **in memory**: a code lives for minutes and persisting it would
/// create a durable credential-shaped row for something that is meant to
/// evaporate. A server restart invalidating outstanding codes is the correct
/// behavior — the member presses "link" again.
///
/// The store spans workspaces and providers (one instance per server) but every
/// operation is scoped to both, so a code minted for one workspace's Slack app
/// cannot redeem in another workspace, or on another provider, even if the
/// string collides.
class ChatLinkCodeStore {
  /// Creates a [ChatLinkCodeStore]. [ttl] is how long a minted code lives.
  ChatLinkCodeStore({
    this.ttl = const Duration(minutes: 15),
    Random? random,
    DateTime Function()? clock,
  }) : _random = random ?? Random.secure(),
       _clock = clock ?? DateTime.now;

  /// How long a minted code stays valid.
  final Duration ttl;

  final Random _random;
  final DateTime Function() _clock;

  /// Keyed by `workspaceId|provider|code`.
  final Map<String, ChatLinkCode> _codes = {};

  final StreamController<ChatLinkCodeChange> _changes =
      StreamController<ChatLinkCodeChange>.broadcast();

  /// Crockford-ish alphabet: no `0`/`O`, `1`/`I`, `U` — a code is read off one
  /// screen and typed into another, so ambiguous glyphs are a support ticket.
  static const _alphabet = '23456789ABCDEFGHJKLMNPQRSTVWXYZ';
  static const _length = 6;

  static final RegExp _shape = RegExp('^[$_alphabet]{$_length}\$');

  /// Whether [text] has the shape of a code (after trimming and upper-casing),
  /// so a direct message can be recognized as a link attempt.
  static bool looksLikeCode(String text) =>
      _shape.hasMatch(normalize(text));

  /// [text] as a code is stored: trimmed, without surrounding backticks,
  /// upper-cased.
  static String normalize(String text) =>
      text.trim().replaceAll('`', '').trim().toUpperCase();

  /// Every change to an outstanding code (minted, claimed, confirmed,
  /// declined, revoked).
  Stream<ChatLinkCodeChange> get changes => _changes.stream;

  /// Mints a fresh code for [userId] on [provider] in [workspaceId], replacing
  /// any code that user already holds there (so a second "link" press
  /// invalidates the first, claimed or not).
  ChatLinkCode mint({
    required String workspaceId,
    required ChatProvider provider,
    required String userId,
  }) {
    _sweep();
    _codes.removeWhere(
      (_, c) =>
          c.workspaceId == workspaceId &&
          c.provider == provider &&
          c.userId == userId,
    );
    final code = String.fromCharCodes([
      for (var i = 0; i < _length; i++)
        _alphabet.codeUnitAt(_random.nextInt(_alphabet.length)),
    ]);
    final minted = ChatLinkCode(
      code: code,
      workspaceId: workspaceId,
      provider: provider,
      userId: userId,
      expiresAt: _clock().add(ttl),
    );
    _codes[_key(workspaceId, provider, code)] = minted;
    _notify(workspaceId, provider, userId);
    return minted;
  }

  /// Records that [claim]'s sender sent [code] to the bot on [provider] in
  /// [workspaceId]. Returns the claimed code, or null when the code is
  /// unknown, expired, or already claimed by somebody else — one
  /// indistinguishable failure to the sender on purpose. The first claim wins:
  /// a code read over someone's shoulder cannot be re-pointed at another
  /// profile after the owner sent it.
  ChatLinkCode? claim(
    String workspaceId,
    String code, {
    required ChatProvider provider,
    required ChatLinkClaim claim,
  }) {
    _sweep();
    final key = _key(workspaceId, provider, normalize(code));
    final found = _codes[key];
    if (found == null) {
      return null;
    }
    final existing = found.claim;
    if (existing != null) {
      final same =
          existing.externalUserId == claim.externalUserId &&
          existing.externalTeamId == claim.externalTeamId;
      return same ? found : null;
    }
    final claimed = found.claimedBy(claim);
    _codes[key] = claimed;
    _notify(workspaceId, provider, found.userId);
    return claimed;
  }

  /// The live code [code] on [provider] in [workspaceId], claimed or not, or
  /// null.
  ChatLinkCode? lookup(
    String workspaceId,
    String code, {
    required ChatProvider provider,
  }) {
    _sweep();
    return _codes[_key(workspaceId, provider, normalize(code))];
  }

  /// [userId]'s outstanding code on [provider] in [workspaceId], claimed or
  /// not, or null.
  ChatLinkCode? pendingFor(
    String workspaceId,
    String userId, {
    required ChatProvider provider,
  }) {
    _sweep();
    for (final code in _codes.values) {
      if (code.workspaceId == workspaceId &&
          code.provider == provider &&
          code.userId == userId) {
        return code;
      }
    }
    return null;
  }

  /// Takes [userId]'s claimed code when its claim names [externalUserId],
  /// removing it. Null when there is no such claim (expired, declined,
  /// re-minted, or claimed by a different profile than the one confirmed).
  ChatLinkCode? takeClaimed(
    String workspaceId,
    String userId, {
    required ChatProvider provider,
    required String externalUserId,
  }) {
    final pending = pendingFor(workspaceId, userId, provider: provider);
    if (pending == null || pending.claim?.externalUserId != externalUserId) {
      return null;
    }
    _codes.remove(_key(workspaceId, provider, pending.code));
    _notify(workspaceId, provider, userId);
    return pending;
  }

  /// Drops any outstanding code for [userId] in [workspaceId] (declined, or the
  /// link was established another way). Provider-scoped when [provider] is
  /// given, otherwise every provider's code for that user.
  void revokeForUser(
    String workspaceId,
    String userId, {
    ChatProvider? provider,
  }) {
    final dropped = <ChatProvider>{};
    _codes.removeWhere((_, c) {
      final match =
          c.workspaceId == workspaceId &&
          c.userId == userId &&
          (provider == null || c.provider == provider);
      if (match) {
        dropped.add(c.provider);
      }
      return match;
    });
    for (final p in dropped) {
      _notify(workspaceId, p, userId);
    }
  }

  String _key(String workspaceId, ChatProvider provider, String code) =>
      '$workspaceId|${provider.wire}|$code';

  void _notify(String workspaceId, ChatProvider provider, String userId) {
    if (!_changes.isClosed) {
      _changes.add((
        workspaceId: workspaceId,
        provider: provider,
        userId: userId,
      ));
    }
  }

  void _sweep() {
    final now = _clock();
    final expired = [
      for (final c in _codes.values)
        if (c.expiresAt.isBefore(now)) c,
    ];
    for (final c in expired) {
      _codes.remove(_key(c.workspaceId, c.provider, c.code));
      _notify(c.workspaceId, c.provider, c.userId);
    }
  }
}
