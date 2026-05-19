import 'dart:math';

import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:test/test.dart';

/// [ChatLinkCodeStore] is the fallback path that binds a chat identity to a
/// Control Center user when email matching is unavailable, so a code is a
/// short-lived bearer credential for somebody's account. The properties below are
/// what keep it from being an account-takeover primitive: one use, a hard expiry,
/// and no reach across workspaces or providers.
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

  test('a code redeems once, for the user it was minted for', () {
    final minted = store.mint(
      workspaceId: 'ws-1',
      provider: slack,
      userId: 'user-1',
    );

    final redeemed = store.consume('ws-1', minted.code, provider: slack);
    expect(redeemed?.userId, 'user-1');
    expect(redeemed?.provider, slack);
    // Replay is refused: a code sent into a chat space is readable by everyone
    // in it.
    expect(store.consume('ws-1', minted.code, provider: slack), isNull);
  });

  test('a code is typed by a human, so case and padding are forgiven', () {
    final minted = store.mint(
      workspaceId: 'ws-1',
      provider: slack,
      userId: 'user-1',
    );

    expect(
      store
          .consume('ws-1', '  ${minted.code.toLowerCase()} ', provider: slack)
          ?.userId,
      'user-1',
    );
  });

  test('an expired code is refused', () {
    final minted = store.mint(
      workspaceId: 'ws-1',
      provider: slack,
      userId: 'user-1',
    );

    now = now.add(const Duration(minutes: 15, seconds: 1));

    expect(store.consume('ws-1', minted.code, provider: slack), isNull);
    expect(minted.expiresAt, DateTime.utc(2026, 8, 13, 12, 15));
  });

  test('a code cannot be redeemed from another workspace', () {
    final minted = store.mint(
      workspaceId: 'ws-1',
      provider: slack,
      userId: 'user-1',
    );

    // Two workspaces may each have a chat app; a code minted in one must not
    // link an identity in the other.
    expect(store.consume('ws-2', minted.code, provider: slack), isNull);
    expect(store.consume('ws-1', minted.code, provider: slack), isNotNull);
  });

  test('minting again invalidates the code the user was shown before', () {
    final first = store.mint(
      workspaceId: 'ws-1',
      provider: slack,
      userId: 'user-1',
    );
    final second = store.mint(
      workspaceId: 'ws-1',
      provider: slack,
      userId: 'user-1',
    );

    expect(second.code, isNot(first.code));
    expect(store.consume('ws-1', first.code, provider: slack), isNull);
    expect(
      store.consume('ws-1', second.code, provider: slack)?.userId,
      'user-1',
    );
  });

  test('revoking drops the outstanding code without redeeming it', () {
    final minted = store.mint(
      workspaceId: 'ws-1',
      provider: slack,
      userId: 'user-1',
    );

    store.revokeForUser('ws-1', 'user-1');

    expect(store.consume('ws-1', minted.code, provider: slack), isNull);
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
