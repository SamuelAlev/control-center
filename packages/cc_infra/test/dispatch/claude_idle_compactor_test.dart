import 'dart:async';

import 'package:cc_domain/features/settings/domain/entities/claude_session_settings.dart';
import 'package:cc_infra/src/dispatch/claude_idle_compactor.dart';
import 'package:test/test.dart';

ClaudeSettledTurn _turn({
  int contextTokens = ClaudeSessionSettings.minIdleCompactTokens,
  Duration? cacheTtl = Duration.zero,
  String conversationId = 'conv-1',
}) => ClaudeSettledTurn(
  workspaceId: 'ws-1',
  spaceId: 'space-1',
  conversationId: conversationId,
  agentId: 'agent-1',
  contextTokens: contextTokens,
  cacheTtl: cacheTtl,
  requestedByUserId: 'user-1',
);

/// Long enough for a due timer and its compaction to have run.
Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 30));

void main() {
  late List<ClaudeSettledTurn> compacted;
  late bool enabled;
  late ClaudeIdleCompactor compactor;

  setUp(() {
    compacted = [];
    enabled = true;
    compactor = ClaudeIdleCompactor(enabled: () => enabled)
      ..compact = (turn) async {
        compacted.add(turn);
        return null;
      };
  });

  tearDown(() => compactor.dispose());

  test('compacts a long conversation once its timer is due', () async {
    final turn = _turn();
    compactor.turnSettled(turn);

    await _settle();

    expect(compacted, [turn]);
  });

  test('waits until the lead before the cache expires', () async {
    compactor.turnSettled(
      _turn(
        cacheTtl: ClaudeIdleCompactor.lead + const Duration(milliseconds: 150),
      ),
    );

    await _settle();
    expect(compacted, isEmpty);

    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(compacted, hasLength(1));
  });

  test('a short conversation is left alone', () async {
    compactor.turnSettled(
      _turn(contextTokens: ClaudeSessionSettings.minIdleCompactTokens - 1),
    );

    await _settle();

    expect(compacted, isEmpty);
  });

  test('an unknown cache lifetime is left alone', () async {
    compactor.turnSettled(_turn(cacheTtl: null));

    await _settle();

    expect(compacted, isEmpty);
  });

  test('nothing is scheduled while the setting is off', () async {
    enabled = false;
    compactor.turnSettled(_turn());
    enabled = true;

    await _settle();

    expect(compacted, isEmpty);
  });

  test('turning the setting off stops what is waiting', () async {
    compactor.turnSettled(_turn());
    enabled = false;

    await _settle();

    expect(compacted, isEmpty);
  });

  test('a new run cancels the wait for that conversation only', () async {
    final other = _turn(conversationId: 'conv-2');
    compactor
      ..turnSettled(_turn())
      ..turnSettled(other)
      ..runStarted('ws-1', 'conv-1');

    await _settle();

    expect(compacted, [other]);
  });

  test('a later turn replaces the earlier wait', () async {
    final later = _turn();
    compactor
      ..turnSettled(_turn())
      ..turnSettled(later);

    await _settle();

    expect(compacted, [later]);
  });

  test('a failed compaction stays contained', () async {
    final failed = Completer<void>();
    compactor
      ..compact = (_) async {
        failed.complete();
        throw StateError('no capacity');
      }
      ..turnSettled(_turn());

    await failed.future;
    await _settle();
  });

  test('dispose cancels everything waiting', () async {
    compactor
      ..turnSettled(_turn())
      ..dispose();

    await _settle();

    expect(compacted, isEmpty);
  });
}
