import 'dart:io';

import 'package:cc_persistence/cc_persistence.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

/// Review drafts must survive both an app restart and a server restart
/// (FINDINGS §11.3). A draft lives in the on-disk `review_drafts` table inside
/// its workspace's own database file; "restart" is a full close of the
/// [WorkspaceDatabase] and a fresh open of the SAME file (a new process would do
/// exactly this). An in-memory database can't prove this — it evaporates on
/// close — so this test is file-backed.
void main() {
  const owner = 'octocat';
  const repo = 'hello-world';
  const pr = 42;

  late Directory tmp;
  late File file;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('review_draft_persist');
    file = File('${tmp.path}/drafts.db');
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  test('a draft written before shutdown is readable after a restart', () async {
    // Session 1: write a draft, then shut down.
    final first = WorkspaceDatabase(NativeDatabase(file), workspaceId: 'ws-1');
    await first.reviewDao.upsertDraft(owner, repo, pr, 'work in progress');
    await first.close();

    // Session 2: fresh process opens the same file — the draft must be intact.
    final second = WorkspaceDatabase(NativeDatabase(file), workspaceId: 'ws-1');
    addTearDown(second.close);
    expect(
      await second.reviewDao.getDraft(owner, repo, pr),
      'work in progress',
    );
  });

  test(
    'an edit before shutdown replaces the draft (survives restart)',
    () async {
      final first = WorkspaceDatabase(
        NativeDatabase(file),
        workspaceId: 'ws-1',
      );
      await first.reviewDao.upsertDraft(owner, repo, pr, 'first pass');
      await first.reviewDao.upsertDraft(owner, repo, pr, 'second pass');
      await first.close();

      final second = WorkspaceDatabase(
        NativeDatabase(file),
        workspaceId: 'ws-1',
      );
      addTearDown(second.close);
      // Upsert-by-composite-key means one row, latest text — no duplicate draft.
      expect(await second.reviewDao.getDraft(owner, repo, pr), 'second pass');
    },
  );

  test('a cleared draft stays gone after a restart', () async {
    final first = WorkspaceDatabase(NativeDatabase(file), workspaceId: 'ws-1');
    await first.reviewDao.upsertDraft(owner, repo, pr, 'to be discarded');
    await first.reviewDao.clearDraft(owner, repo, pr);
    await first.close();

    final second = WorkspaceDatabase(NativeDatabase(file), workspaceId: 'ws-1');
    addTearDown(second.close);
    expect(await second.reviewDao.getDraft(owner, repo, pr), isNull);
  });

  test('drafts for different PRs are independent across a restart', () async {
    final first = WorkspaceDatabase(NativeDatabase(file), workspaceId: 'ws-1');
    await first.reviewDao.upsertDraft(owner, repo, 1, 'draft for #1');
    await first.reviewDao.upsertDraft(owner, repo, 2, 'draft for #2');
    await first.close();

    final second = WorkspaceDatabase(NativeDatabase(file), workspaceId: 'ws-1');
    addTearDown(second.close);
    expect(await second.reviewDao.getDraft(owner, repo, 1), 'draft for #1');
    expect(await second.reviewDao.getDraft(owner, repo, 2), 'draft for #2');
    expect(await second.reviewDao.getDraft(owner, repo, 3), isNull);
  });
}
