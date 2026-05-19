import 'dart:convert';
import 'dart:io';

import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_infra/src/harness/file_transcript_store.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory dataDir;
  late FileHarnessTranscriptStore store;

  setUp(() {
    dataDir = Directory.systemTemp.createTempSync('cc_transcripts');
    store = FileHarnessTranscriptStore(
      workspaceDir: (id) => p.join(dataDir.path, id),
    );
  });
  tearDown(() => dataDir.deleteSync(recursive: true));

  HarnessTranscript sample(String text) => HarnessTranscript(
    messages: [HarnessMessage.user(text)],
    checkpoints: const {'before': 0},
    turns: 2,
  );

  test('round-trips through disk', () async {
    const key = 'ws1/conv1#agent1';
    await store.save(key, sample('hello'));

    final loaded = await store.load(key);
    expect(loaded!.messages.single.textContent, 'hello');
    expect(loaded.checkpoints, {'before': 0});
    expect(loaded.turns, 2);
  });

  test('lands inside the workspace directory', () async {
    await store.save('ws1/conv1#agent1', sample('x'));
    expect(
      File(
        p.join(dataDir.path, 'ws1', 'transcripts', 'conv1#agent1.json'),
      ).existsSync(),
      isTrue,
      reason: 'beside the workspace database, so deleting the workspace '
          'deletes its transcripts too',
    );
  });

  test('a traversal attempt cannot escape the workspace directory', () async {
    // These ids reach the server from a client.
    await store.save('ws1/../../etc/passwd', sample('x'));
    expect(
      Directory(p.join(dataDir.path, 'ws1', 'transcripts')).existsSync(),
      isTrue,
    );
    expect(File(p.join(dataDir.path, '..', 'etc', 'passwd')).existsSync(),
        isFalse);
  });

  test('an unknown key loads as null, not an error', () async {
    expect(await store.load('ws1/nothing#here'), isNull);
    expect(await store.load('malformed-no-slash'), isNull);
  });

  test('a truncated file loads as null rather than throwing', () async {
    const key = 'ws1/conv1#agent1';
    await store.save(key, sample('hello'));
    final file = File(
      p.join(dataDir.path, 'ws1', 'transcripts', 'conv1#agent1.json'),
    );
    await file.writeAsString('{"messages": [{"role"');

    expect(await store.load(key), isNull);
  });

  test('a file over the size cap is skipped, not loaded', () async {
    final small = FileHarnessTranscriptStore(
      workspaceDir: (id) => p.join(dataDir.path, id),
      maxBytes: 64,
    );
    const key = 'ws1/conv1#agent1';
    await small.save(
      key,
      HarnessTranscript(messages: [HarnessMessage.user('x' * 500)]),
    );
    expect(await small.load(key), isNull);
  });

  test('concurrent saves do not interleave into an unparseable file', () async {
    const key = 'ws1/conv1#agent1';
    await Future.wait([
      for (var i = 0; i < 20; i++) store.save(key, sample('turn $i')),
    ]);

    final raw = await File(
      p.join(dataDir.path, 'ws1', 'transcripts', 'conv1#agent1.json'),
    ).readAsString();
    expect(() => jsonDecode(raw), returnsNormally);
    expect((await store.load(key))!.messages.single.textContent, 'turn 19');
  });

  test('clear removes it', () async {
    const key = 'ws1/conv1#agent1';
    await store.save(key, sample('hello'));
    await store.clear(key);
    expect(await store.load(key), isNull);
    await store.clear(key);
  });

  test('two agents in one conversation keep separate histories', () async {
    // They saw different tool results and were given different system prompts,
    // so merging would hand each the other's reasoning as its own.
    await store.save('ws1/conv1#a', sample('a saw this'));
    await store.save('ws1/conv1#b', sample('b saw that'));
    expect((await store.load('ws1/conv1#a'))!.messages.single.textContent,
        'a saw this');
    expect((await store.load('ws1/conv1#b'))!.messages.single.textContent,
        'b saw that');
  });

  group('prune', () {
    test('removes only what is older than the window', () async {
      await store.save('ws1/old#a', sample('old'));
      await store.save('ws1/new#a', sample('new'));
      final old = File(
        p.join(dataDir.path, 'ws1', 'transcripts', 'old#a.json'),
      );
      old.setLastModifiedSync(
        DateTime.now().subtract(const Duration(days: 60)),
      );

      final removed = await store.prune(workspaceId: 'ws1');
      expect(removed, 1);
      expect(await store.load('ws1/old#a'), isNull);
      expect(await store.load('ws1/new#a'), isNotNull);
    });

    test('pruneAll sweeps every workspace directory', () async {
      for (final ws in ['ws1', 'ws2']) {
        await store.save('$ws/conv#a', sample('x'));
        File(
          p.join(dataDir.path, ws, 'transcripts', 'conv#a.json'),
        ).setLastModifiedSync(
          DateTime.now().subtract(const Duration(days: 60)),
        );
      }
      expect(await store.pruneAll(dataDir: dataDir.path), 2);
    });

    test('a missing directory prunes nothing rather than failing', () async {
      expect(await store.prune(workspaceId: 'never-existed'), 0);
      expect(await store.pruneAll(dataDir: '/nonexistent/path'), 0);
    });
  });
}
