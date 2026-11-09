import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:test/test.dart';

/// [ChatTicketDraftStore]: `/cc ticket` only drafts; the reporter creates the
/// ticket in Control Center. A draft is the reporter's alone, in one
/// workspace, for a day.
void main() {
  late DateTime now;
  late ChatTicketDraftStore store;
  var ids = 0;

  setUp(() {
    now = DateTime.utc(2026, 11, 8);
    ids = 0;
    store = ChatTicketDraftStore(
      maxPerWorkspace: 3,
      clock: () => now,
      newId: () => 'd-${++ids}',
    );
  });

  ChatTicketDraft add({String workspaceId = 'w-1', String userId = 'u-1'}) =>
      store.add(
        workspaceId: workspaceId,
        provider: ChatProvider.slack,
        reporterUserId: userId,
        title: 'Fix the flaky login test',
        externalUserId: 'U1',
        externalChannelId: 'C1',
      );

  test('a draft is listed for its reporter in its workspace only', () {
    final draft = add();

    expect(store.forUser('w-1', 'u-1'), [draft]);
    expect(store.forUser('w-1', 'u-2'), isEmpty);
    expect(store.forUser('w-2', 'u-1'), isEmpty);
    expect(draft.expiresAt, now.add(const Duration(hours: 24)));
  });

  test('only the reporter takes it, once, in its workspace', () {
    final draft = add();

    expect(store.take('w-1', 'u-2', draft.id), isNull);
    expect(store.take('w-2', 'u-1', draft.id), isNull);
    expect(store.take('w-1', 'u-1', draft.id), draft);
    expect(store.take('w-1', 'u-1', draft.id), isNull);
  });

  test('a draft expires after a day', () {
    final draft = add();
    now = now.add(const Duration(hours: 24));

    expect(store.forUser('w-1', 'u-1'), isEmpty);
    expect(store.take('w-1', 'u-1', draft.id), isNull);
  });

  test('a workspace keeps only its newest drafts', () {
    final first = add();
    add();
    add();
    add(workspaceId: 'w-2');

    add();

    final ids = store.forUser('w-1', 'u-1').map((d) => d.id);
    expect(ids, isNot(contains(first.id)));
    expect(ids, hasLength(3));
    // Another workspace's drafts do not count against this one.
    expect(store.forUser('w-2', 'u-1'), hasLength(1));
  });

  test('every change is announced for the reporter', () async {
    final changes = <({String workspaceId, String userId})>[];
    final sub = store.changes.listen(changes.add);
    addTearDown(sub.cancel);

    final draft = add();
    store.take('w-1', 'u-1', draft.id);
    await pumpEventQueue();

    expect(changes, [
      (workspaceId: 'w-1', userId: 'u-1'),
      (workspaceId: 'w-1', userId: 'u-1'),
    ]);
  });
}
