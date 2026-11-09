import 'dart:math';

import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:test/test.dart';

/// [ChatLinkCodeStore] binds a chat identity to a Control Center user: the
/// member sends the code to the bot, then confirms the profile that sent it.
/// The properties below are what keep it from being an account-takeover
/// primitive: first claim wins, confirmation names the profile, one use, a hard
/// expiry, and no reach across workspaces or providers.
void main() {
  const slack = ChatProvider.slack;
  var now = DateTime.utc(2026, 8, 13, 12);
  late ChatLinkCodeStore store;

  setUp(() {
    now = DateTime.utc(2026, 8, 13, 12);
    store = ChatLinkCodeStore(
      ttl: const Duration(minutes: 15),
      clock: () => now,
      random: Random(7),
    );
  });

  ChatLinkClaim claimBy(String externalUserId, {String team = 'T1'}) =>
      ChatLinkClaim(
        externalTeamId: team,
        externalUserId: externalUserId,
        label: externalUserId,
        conversationId: 'D-$externalUserId',
        claimedAt: now,
      );

  test('a claimed code is taken once, for the profile that claimed it', () {
    final minted = store.mint(
      workspaceId: 'ws-1',
      provider: slack,
      userId: 'user-1',
    );

    final claimed = store.claim(
      'ws-1',
      minted.code,
      provider: slack,
      claim: claimBy('U1'),
    );
    expect(claimed?.claim?.externalUserId, 'U1');
    // Claiming links nothing: the member still has to confirm, and only the
    // profile they saw.
    expect(
      store.takeClaimed('ws-1', 'user-1', provider: slack, externalUserId: 'U2'),
      isNull,
    );
    final taken = store.takeClaimed(
      'ws-1',
      'user-1',
      provider: slack,
      externalUserId: 'U1',
    );
    expect(taken?.userId, 'user-1');
    // Replay is refused.
    expect(
      store.takeClaimed('ws-1', 'user-1', provider: slack, externalUserId: 'U1'),
      isNull,
    );
  });

  test('the first claim wins; a second sender cannot re-point the code', () {
    final minted = store.mint(
      workspaceId: 'ws-1',
      provider: slack,
      userId: 'user-1',
    );

    store.claim('ws-1', minted.code, provider: slack, claim: claimBy('U1'));

    expect(
      store.claim('ws-1', minted.code, provider: slack, claim: claimBy('U2')),
      isNull,
    );
    // The same sender sending it twice is not a second claim.
    expect(
      store.claim('ws-1', minted.code, provider: slack, claim: claimBy('U1')),
      isNotNull,
    );
    expect(
      store.pendingFor('ws-1', 'user-1', provider: slack)?.claim?.externalUserId,
      'U1',
    );
  });

  test('a code is typed by a human, so case, padding and ticks are forgiven', () {
    final minted = store.mint(
      workspaceId: 'ws-1',
      provider: slack,
      userId: 'user-1',
    );
    final sloppy = ' `${minted.code.toLowerCase()}` ';

    expect(ChatLinkCodeStore.looksLikeCode(sloppy), isTrue);
    expect(store.lookup('ws-1', sloppy, provider: slack)?.userId, 'user-1');
    expect(ChatLinkCodeStore.looksLikeCode('summarize the PRs'), isFalse);
  });

  test('an expired code is refused', () {
    final minted = store.mint(
      workspaceId: 'ws-1',
      provider: slack,
      userId: 'user-1',
    );

    now = now.add(const Duration(minutes: 15, seconds: 1));

    expect(
      store.claim('ws-1', minted.code, provider: slack, claim: claimBy('U1')),
      isNull,
    );
    expect(store.pendingFor('ws-1', 'user-1', provider: slack), isNull);
    expect(minted.expiresAt, DateTime.utc(2026, 8, 13, 12, 15));
  });

  test('a code cannot be claimed from another workspace or provider', () {
    final minted = store.mint(
      workspaceId: 'ws-1',
      provider: slack,
      userId: 'user-1',
    );

    // Two workspaces may each have a chat app; a code minted in one must not
    // link an identity in the other.
    expect(
      store.claim('ws-2', minted.code, provider: slack, claim: claimBy('U1')),
      isNull,
    );
    expect(store.lookup('ws-2', minted.code, provider: slack), isNull);
    expect(store.lookup('ws-1', minted.code, provider: slack), isNotNull);
  });

  test('minting again invalidates the code the user was shown before', () {
    final first = store.mint(
      workspaceId: 'ws-1',
      provider: slack,
      userId: 'user-1',
    );
    store.claim('ws-1', first.code, provider: slack, claim: claimBy('U1'));
    final second = store.mint(
      workspaceId: 'ws-1',
      provider: slack,
      userId: 'user-1',
    );

    expect(second.code, isNot(first.code));
    expect(store.lookup('ws-1', first.code, provider: slack), isNull);
    // The new code starts unclaimed: a claim never carries over.
    expect(store.pendingFor('ws-1', 'user-1', provider: slack)?.claim, isNull);
  });

  test('revoking (a decline) drops the code and its claim', () async {
    final changes = <ChatLinkCodeChange>[];
    final sub = store.changes.listen(changes.add);
    final minted = store.mint(
      workspaceId: 'ws-1',
      provider: slack,
      userId: 'user-1',
    );
    store.claim('ws-1', minted.code, provider: slack, claim: claimBy('U1'));

    store.revokeForUser('ws-1', 'user-1');

    expect(
      store.takeClaimed('ws-1', 'user-1', provider: slack, externalUserId: 'U1'),
      isNull,
    );
    await pumpEventQueue();
    await sub.cancel();
    // Minted, claimed, revoked: each reaches a watcher.
    expect(changes, hasLength(3));
    expect(changes.every((c) => c.userId == 'user-1'), isTrue);
  });

  test('codes avoid glyphs that are misread off a screen', () {
    for (var i = 0; i < 50; i++) {
      final code = store
          .mint(workspaceId: 'ws-1', provider: slack, userId: 'user-$i')
          .code;
      expect(code, hasLength(6));
      expect(code, matches(RegExp(r'^[23456789ABCDEFGHJKLMNPQRSTVWXYZ]+$')));
    }
  });
}
