import 'dart:math';

import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider.dart';

/// A one-time code a workspace member types into chat (`/cc link ABC123`) to
/// prove that a chat identity is theirs.
class ChatLinkCode {
  /// Creates a [ChatLinkCode].
  const ChatLinkCode({
    required this.code,
    required this.workspaceId,
    required this.provider,
    required this.userId,
    required this.expiresAt,
  });

  /// The code the user types in the chat app.
  final String code;

  /// The workspace whose chat app the link is for.
  final String workspaceId;

  /// The provider the code may be redeemed on.
  final ChatProvider provider;

  /// The Control Center user the code was minted for.
  final String userId;

  /// When the code stops being accepted.
  final DateTime expiresAt;
}

/// Short-lived, single-use codes for the chat↔Control Center link flow.
///
/// Deliberately **in memory**: a code lives for minutes and persisting it would
/// create a durable credential-shaped row for something that is meant to
/// evaporate. A server restart invalidating outstanding codes is the correct
/// behavior — the member presses "link" again.
///
/// The store spans workspaces and providers (one instance per server) but every
/// operation is scoped to both, so a code minted for one workspace's Slack app
/// cannot redeem in another workspace, or on another provider, even if the string
/// collides.
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

  /// Crockford-ish alphabet: no `0`/`O`, `1`/`I`, `U` — a code is read off one
  /// screen and typed into another, so ambiguous glyphs are a support ticket.
  static const _alphabet = '23456789ABCDEFGHJKLMNPQRSTVWXYZ';
  static const _length = 6;

  /// Mints a fresh code for [userId] on [provider] in [workspaceId], replacing
  /// any code that user already holds there (so a second "link" press
  /// invalidates the first).
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
    return minted;
  }

  /// Redeems [code] on [provider] in [workspaceId], removing it. Returns null
  /// when the code is unknown, belongs to another workspace or provider, or has
  /// expired — all of which are one indistinguishable failure to the chat user on
  /// purpose.
  ChatLinkCode? consume(
    String workspaceId,
    String code, {
    required ChatProvider provider,
  }) {
    _sweep();
    final key = _key(workspaceId, provider, code.trim().toUpperCase());
    final found = _codes[key];
    if (found == null || found.expiresAt.isBefore(_clock())) {
      _codes.remove(key);
      return null;
    }
    _codes.remove(key);
    return found;
  }

  /// Drops any outstanding code for [userId] in [workspaceId] (used when the
  /// link is established another way, e.g. by email match). Provider-scoped when
  /// [provider] is given, otherwise every provider's code for that user.
  void revokeForUser(
    String workspaceId,
    String userId, {
    ChatProvider? provider,
  }) => _codes.removeWhere(
    (_, c) =>
        c.workspaceId == workspaceId &&
        c.userId == userId &&
        (provider == null || c.provider == provider),
  );

  String _key(String workspaceId, ChatProvider provider, String code) =>
      '$workspaceId|${provider.wire}|$code';

  void _sweep() {
    final now = _clock();
    _codes.removeWhere((_, c) => c.expiresAt.isBefore(now));
  }
}
