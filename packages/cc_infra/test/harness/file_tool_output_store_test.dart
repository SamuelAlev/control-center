import 'dart:convert';
import 'dart:io';

import 'package:cc_harness/context.dart';
import 'package:cc_infra/src/harness/file_tool_output_store.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory dataDir;
  late FileToolOutputStore store;

  setUp(() {
    dataDir = Directory.systemTemp.createTempSync('cc_tool_outputs_');
    store = FileToolOutputStore(workspaceDir: (id) => p.join(dataDir.path, id));
  });

  tearDown(() {
    if (dataDir.existsSync()) {
      dataDir.deleteSync(recursive: true);
    }
  });

  const scope = ToolOutputScope(
    workspaceId: 'ws1',
    conversationId: 'c1',
    agentId: 'a1',
  );

  String scopeDir(String workspace, ToolOutputScope at) =>
      p.join(dataDir.path, workspace, 'outputs', at.storageKey);

  Future<ToolOutputReference> put(
    String content, {
    ToolOutputScope? at,
    String toolName = 'bash',
    ToolOutputStore? into,
  }) async {
    final reference = await (into ?? store).put(
      ToolOutputWrite(scope: at ?? scope, toolName: toolName, content: content),
    );
    expect(reference, isNotNull, reason: 'the store should accept $toolName');
    return reference!;
  }

  String sampleText({int lines = 500}) =>
      List.generate(lines, (i) => 'line $i: some content').join('\n');

  String unicodeText() {
    final buffer = StringBuffer();
    for (var i = 0; i < 4000; i++) {
      buffer.write('a$i é✓🙂 ');
    }
    return buffer.toString();
  }

  /// Reads the whole original back through bounded slices.
  Future<String> recover(
    ToolOutputStore from,
    ToolOutputReference reference, {
    ToolOutputScope at = scope,
  }) async {
    final buffer = StringBuffer();
    var offset = 0;
    while (true) {
      final result = await from.read(
        at,
        reference.handle,
        offsetChars: offset,
        limitChars: kToolOutputReadMaxChars,
      );
      expect(result.status, ToolOutputReadStatus.ok);
      final chunk = result.chunk!;
      buffer.write(chunk.text);
      if (!chunk.hasMore) {
        break;
      }
      offset = chunk.nextOffsetChars;
    }
    return buffer.toString();
  }

  test('round-trips an exact character range through disk', () async {
    final content = sampleText();
    final reference = await put(content);

    expect(reference.handle, startsWith('out_'));
    expect(reference.charLength, content.length);
    expect(reference.byteLength, utf8LengthOf(content));
    expect(reference.toolName, 'bash');

    final result = await store.read(
      scope,
      reference.handle,
      offsetChars: 7,
      limitChars: 11,
    );
    expect(result.status, ToolOutputReadStatus.ok);
    final chunk = result.chunk!;
    expect(chunk.text, content.substring(7, 18));
    expect(chunk.offsetChars, 7);
    expect(chunk.totalChars, content.length);
    expect(chunk.toolName, 'bash');
    expect(chunk.hasMore, isTrue);
    expect(chunk.nextOffsetChars, 18);
  });

  test('the last slice reports no more content', () async {
    final reference = await put('x' * 50);
    final result = await store.read(scope, reference.handle, limitChars: 50);
    expect(result.chunk!.hasMore, isFalse);
  });

  test('lands under the workspace directory, outside the agent cwd', () async {
    final reference = await put('hello');
    final textFile = File(
      p.join(scopeDir('ws1', scope), '${reference.handle}.txt'),
    );
    expect(textFile.existsSync(), isTrue);
    expect(textFile.readAsStringSync(), 'hello');
    // The agent never receives this path; only a handle addresses the file.
    expect(textFile.path, contains(p.join('ws1', 'outputs')));
  });

  test('survives a new store instance (durable across restarts)', () async {
    final reference = await put('persisted original');
    final reopened = FileToolOutputStore(
      workspaceDir: (id) => p.join(dataDir.path, id),
    );
    final result = await reopened.read(scope, reference.handle);
    expect(result.status, ToolOutputReadStatus.ok);
    expect(result.chunk!.text, 'persisted original');
  });

  test('reports the original UTF-8 byte length in the chunk', () async {
    final reference = await put('héllo ✓');
    final result = await store.read(scope, reference.handle);
    expect(result.chunk!.text, 'héllo ✓');
    expect(result.chunk!.byteLength, utf8LengthOf('héllo ✓'));
  });

  test('clamps limit to the retrieval ceiling', () async {
    final reference = await put('y' * (kToolOutputReadMaxChars + 500));
    final result = await store.read(
      scope,
      reference.handle,
      limitChars: 999999,
    );
    expect(result.chunk!.text.length, kToolOutputReadMaxChars);
    expect(result.chunk!.hasMore, isTrue);
  });

  test('an offset past the end yields an empty, complete slice', () async {
    final reference = await put('short');
    final result = await store.read(scope, reference.handle, offsetChars: 99);
    expect(result.chunk!.text, isEmpty);
    expect(result.chunk!.totalChars, 5);
    expect(result.chunk!.hasMore, isFalse);
  });

  group('bounded ranged access', () {
    test('a narrow read does not decode the whole original', () async {
      final content = sampleText(lines: 20000);
      final reference = await put(content);
      final fileBytes = File(
        p.join(scopeDir('ws1', scope), '${reference.handle}.txt'),
      ).lengthSync();
      final before = store.decodedBytes;

      final result = await store.read(
        scope,
        reference.handle,
        offsetChars: 100000,
        limitChars: 2000,
      );

      expect(result.chunk!.text, content.substring(100000, 102000));
      final decoded = store.decodedBytes - before;
      expect(
        decoded,
        lessThan(fileBytes ~/ 10),
        reason: 'a 2KB slice must not decode the whole ${fileBytes}B original',
      );
      expect(decoded, greaterThanOrEqualTo(2000));
    });

    test('paging across multi-byte text stays exact', () async {
      final content = unicodeText();
      final reference = await put(content);
      expect(await recover(store, reference), content);

      // A slice whose bounds land inside a surrogate pair must return exactly
      // the code units the string has there (a lone surrogate included).
      final emoji = content.indexOf('🙂');
      final result = await store.read(
        scope,
        reference.handle,
        offsetChars: emoji + 1,
        limitChars: 5,
      );
      expect(result.chunk!.text, content.substring(emoji + 1, emoji + 6));
    });

    test('a single-character read at a checkpoint boundary is exact', () async {
      final content = unicodeText();
      final reference = await put(content);
      for (final at in const [0, 4095, 4096, 4097, 8192, 20000]) {
        final result = await store.read(
          scope,
          reference.handle,
          offsetChars: at,
          limitChars: 3,
        );
        expect(
          result.chunk!.text,
          content.substring(at, at + 3),
          reason: 'offset $at',
        );
      }
    });

    test(
      'a checkpoint through a surrogate pair stays readable after restart',
      () async {
        final content = '${'a' * 4095}🙂${'b' * 4095}🙂tail';
        final reference = await put(content);
        final reopened = FileToolOutputStore(
          workspaceDir: (id) => p.join(dataDir.path, id),
        );
        for (final offset in [4095, 4096, 4097, 8192, content.length - 4]) {
          final result = await reopened.read(
            scope,
            reference.handle,
            offsetChars: offset,
            limitChars: 4,
          );
          expect(
            result.chunk!.text,
            content.substring(
              offset,
              offset + 4 < content.length ? offset + 4 : content.length,
            ),
            reason: 'offset $offset',
          );
        }
        expect(await recover(reopened, reference), content);
      },
    );

    test(
      'unpaired surrogates are indexed as their UTF-8 replacement',
      () async {
        final original =
            '${'a' * 4095}'
            '${String.fromCharCodes([0xd800])}🙂'
            '${'b' * 4095}${String.fromCharCodes([0xdc00])}';
        final stored = utf8.decode(utf8.encode(original));
        final reference = await put(original);
        final reopened = FileToolOutputStore(
          workspaceDir: (id) => p.join(dataDir.path, id),
        );
        expect(reference.byteLength, utf8.encode(original).length);
        expect(await recover(reopened, reference), stored);
        final last = await reopened.read(
          scope,
          reference.handle,
          offsetChars: original.length - 3,
          limitChars: 3,
        );
        expect(last.chunk!.text, stored.substring(stored.length - 3));
        expect(last.chunk!.hasMore, isFalse);
      },
    );
  });

  group('isolation', () {
    test(
      'foreign and absent handles are indistinguishable across conversations',
      () async {
        const otherScope = ToolOutputScope(
          workspaceId: 'ws1',
          conversationId: 'c2',
          agentId: 'a1',
        );
        await put('conversation two output', at: otherScope);
        final reference = await put('conversation one secret');
        final result = await store.read(otherScope, reference.handle);
        expect(result.status, ToolOutputReadStatus.notFound);
        expect(result.chunk, isNull);
        // Knowing a handle must not reveal whether another scope stores it.
        await store.clearScope(scope);
        final absent = await store.read(otherScope, reference.handle);
        expect(absent.status, result.status);
        expect(absent.chunk, isNull);
        expect(absent.message, result.message);
      },
    );

    test('another agent\'s handle is unknown here', () async {
      final reference = await put('agent one secret');
      final result = await store.read(
        const ToolOutputScope(
          workspaceId: 'ws1',
          conversationId: 'c1',
          agentId: 'a2',
        ),
        reference.handle,
      );
      expect(result.status, ToolOutputReadStatus.notFound);
    });

    test('a null conversation is a distinct scope, not a wildcard', () async {
      final reference = await put(
        'no-agent secret',
        at: const ToolOutputScope(workspaceId: 'ws1', conversationId: 'c1'),
      );
      final result = await store.read(scope, reference.handle);
      expect(result.status, ToolOutputReadStatus.notFound);
    });

    test('another workspace\'s handle is unknown here', () async {
      final reference = await put(
        'ws2 secret',
        at: const ToolOutputScope(workspaceId: 'ws2', conversationId: 'c1'),
      );
      final result = await store.read(scope, reference.handle);
      expect(result.status, ToolOutputReadStatus.notFound);
    });

    test(
      'two ids that a lossy sanitizer would merge keep separate storage',
      () async {
        // `.` and `_` used to be rewritten to the same character, so these two
        // scopes would have shared a directory and read each other's outputs.
        final dotted = await put(
          'dotted secret',
          at: const ToolOutputScope(
            workspaceId: 'ws1',
            conversationId: 'c.1',
            agentId: 'a1',
          ),
        );
        final underscored = await put(
          'underscored secret',
          at: const ToolOutputScope(
            workspaceId: 'ws1',
            conversationId: 'c_1',
            agentId: 'a1',
          ),
        );
        expect(
          scopeDir(
            'ws1',
            const ToolOutputScope(
              workspaceId: 'ws1',
              conversationId: 'c.1',
              agentId: 'a1',
            ),
          ),
          isNot(
            scopeDir(
              'ws1',
              const ToolOutputScope(
                workspaceId: 'ws1',
                conversationId: 'c_1',
                agentId: 'a1',
              ),
            ),
          ),
        );
        final foreign = await store.read(
          const ToolOutputScope(
            workspaceId: 'ws1',
            conversationId: 'c.1',
            agentId: 'a1',
          ),
          underscored.handle,
        );
        expect(foreign.status, ToolOutputReadStatus.notFound);
        final own = await store.read(
          const ToolOutputScope(
            workspaceId: 'ws1',
            conversationId: 'c.1',
            agentId: 'a1',
          ),
          dotted.handle,
        );
        expect(own.chunk!.text, 'dotted secret');
      },
    );

    test('a tampered scope in the metadata file is denied', () async {
      final reference = await put('tamper me');
      final metaFile = File(
        p.join(scopeDir('ws1', scope), '${reference.handle}.json'),
      );
      final meta = jsonDecode(metaFile.readAsStringSync()) as Map;
      meta['scope'] = const ToolOutputScope(
        workspaceId: 'ws1',
        conversationId: 'other',
      ).toJson();
      metaFile.writeAsStringSync(jsonEncode(meta));

      final result = await store.read(scope, reference.handle);
      expect(result.status, ToolOutputReadStatus.denied);
      expect(result.message, isNot(contains('other')));
    });
  });

  group('retrieval boundaries', () {
    test(
      'rejects a path-shaped handle without touching the filesystem',
      () async {
        for (final handle in const [
          '../../etc/passwd',
          'out_../x',
          'out_',
          'out_short',
          'out_%2e%2e',
          '',
        ]) {
          final result = await store.read(scope, handle);
          expect(
            result.status,
            ToolOutputReadStatus.invalid,
            reason: 'handle "$handle" must not be resolved',
          );
        }
      },
    );

    test('refuses a scope whose ids are path-like', () async {
      for (final bad in const [
        ToolOutputScope(workspaceId: 'ws/../other', conversationId: 'c'),
        ToolOutputScope(workspaceId: 'ws1', conversationId: '../c'),
        ToolOutputScope(
          workspaceId: 'ws1',
          conversationId: 'c',
          agentId: 'a/../b',
        ),
        ToolOutputScope(workspaceId: 'ws1', conversationId: 'c\u0000x'),
      ]) {
        final reference = await store.put(
          ToolOutputWrite(scope: bad, toolName: 'bash', content: 'x'),
        );
        expect(reference, isNull, reason: '$bad must be refused');
        final read = await store.read(bad, 'out_${'a' * 22}');
        expect(read.status, ToolOutputReadStatus.invalid);
      }
      // Nothing was written outside the data dir.
      expect(Directory(p.join(dataDir.path, 'other')).existsSync(), isFalse);
    });

    test('an unknown handle is not found, not an error', () async {
      final result = await store.read(scope, 'out_${'z' * 22}');
      expect(result.status, ToolOutputReadStatus.notFound);
    });

    test('missing metadata is not found', () async {
      final reference = await put('vanishing');
      File(
        p.join(scopeDir('ws1', scope), '${reference.handle}.json'),
      ).deleteSync();
      final result = await store.read(scope, reference.handle);
      expect(result.status, ToolOutputReadStatus.notFound);
    });

    test('unparseable metadata is not found', () async {
      final reference = await put('vanishing');
      File(
        p.join(scopeDir('ws1', scope), '${reference.handle}.json'),
      ).writeAsStringSync('{not json');
      final result = await store.read(scope, reference.handle);
      expect(result.status, ToolOutputReadStatus.notFound);
    });

    test('a missing text file is not found', () async {
      final reference = await put('vanishing');
      File(
        p.join(scopeDir('ws1', scope), '${reference.handle}.txt'),
      ).deleteSync();
      final result = await store.read(scope, reference.handle);
      expect(result.status, ToolOutputReadStatus.notFound);
    });

    test('a symlinked text file is refused', () async {
      final reference = await put('real');
      final textPath = p.join(
        scopeDir('ws1', scope),
        '${reference.handle}.txt',
      );
      final outside = File(p.join(dataDir.path, 'outside.txt'))
        ..writeAsStringSync('outside secret');
      File(textPath).deleteSync();
      Link(textPath).createSync(outside.path);

      final result = await store.read(scope, reference.handle);
      expect(result.status, ToolOutputReadStatus.notFound);
    });

    test('a symlinked scope directory is refused', () async {
      final outside = Directory(p.join(dataDir.path, 'elsewhere'))
        ..createSync(recursive: true);
      final dir = scopeDir('ws1', scope);
      Directory(p.dirname(dir)).createSync(recursive: true);
      Link(dir).createSync(outside.path);

      final reference = await store.put(
        const ToolOutputWrite(
          scope: scope,
          toolName: 'bash',
          content: 'through a link',
        ),
      );
      expect(reference, isNull);
      expect(outside.listSync(), isEmpty);
      expect(
        (await store.read(scope, 'out_${'a' * 22}')).status,
        ToolOutputReadStatus.notFound,
      );
    });

    test(
      'a linked outputs root cannot expose or retire an outside entry',
      () async {
        final reference = await put('private original');
        final root = p.join(dataDir.path, 'ws1', 'outputs');
        final outside = Directory(p.join(dataDir.path, 'elsewhere'));
        Directory(root).renameSync(outside.path);
        Link(root).createSync(outside.path);

        expect(
          (await store.read(scope, reference.handle)).status,
          ToolOutputReadStatus.notFound,
        );
        expect(
          await store.put(
            const ToolOutputWrite(
              scope: scope,
              toolName: 'bash',
              content: 'new output',
            ),
          ),
          isNull,
        );
        await store.clearScope(scope);
        expect(
          File(
            p.join(outside.path, scope.storageKey, '${reference.handle}.txt'),
          ).readAsStringSync(),
          'private original',
        );
      },
    );

    test('a corrupt index still reads exactly', () async {
      final content = sampleText(lines: 20000);
      final reference = await put(content);
      final metaFile = File(
        p.join(scopeDir('ws1', scope), '${reference.handle}.json'),
      );
      final meta = jsonDecode(metaFile.readAsStringSync()) as Map;
      meta['index'] = {
        'interval': 4096,
        'offsets': [0, 1, 2],
      };
      metaFile.writeAsStringSync(jsonEncode(meta));

      final result = await store.read(
        scope,
        reference.handle,
        offsetChars: 50000,
        limitChars: 100,
      );
      expect(result.status, ToolOutputReadStatus.ok);
      expect(result.chunk!.text, content.substring(50000, 50100));
    });

    test(
      'a byte-ceiling breach refuses the write and stores nothing',
      () async {
        final small = FileToolOutputStore(
          workspaceDir: (id) => p.join(dataDir.path, id),
          maxBytes: 16,
        );
        final reference = await small.put(
          const ToolOutputWrite(
            scope: scope,
            toolName: 'bash',
            content: 'this is definitely longer than sixteen bytes',
          ),
        );
        expect(reference, isNull);
        expect(Directory(scopeDir('ws1', scope)).existsSync(), isFalse);
      },
    );
  });

  group('capacity retention', () {
    test(
      'at the entry cap the NEW write is refused, old handles stay readable',
      () async {
        final capped = FileToolOutputStore(
          workspaceDir: (id) => p.join(dataDir.path, id),
          maxEntriesPerScope: 2,
        );
        final first = await put('first', into: capped);
        final second = await put('second', into: capped);
        final third = await capped.put(
          const ToolOutputWrite(
            scope: scope,
            toolName: 'bash',
            content: 'third',
          ),
        );
        expect(third, isNull);
        expect((await capped.read(scope, first.handle)).chunk!.text, 'first');
        expect((await capped.read(scope, second.handle)).chunk!.text, 'second');
      },
    );

    test(
      'at the byte cap the new write is refused, old handles stay readable',
      () async {
        final capped = FileToolOutputStore(
          workspaceDir: (id) => p.join(dataDir.path, id),
          maxBytesPerScope: 40,
        );
        final first = await put('a' * 30, into: capped);
        final refused = await capped.put(
          ToolOutputWrite(scope: scope, toolName: 'bash', content: 'b' * 30),
        );
        expect(refused, isNull);
        expect((await capped.read(scope, first.handle)).chunk!.text, 'a' * 30);
      },
    );

    test(
      'the cap is enforced across a fresh instance (seeded from disk)',
      () async {
        final capped = FileToolOutputStore(
          workspaceDir: (id) => p.join(dataDir.path, id),
          maxEntriesPerScope: 1,
        );
        await put('first', into: capped);
        final reopened = FileToolOutputStore(
          workspaceDir: (id) => p.join(dataDir.path, id),
          maxEntriesPerScope: 1,
        );
        final refused = await reopened.put(
          const ToolOutputWrite(
            scope: scope,
            toolName: 'bash',
            content: 'second',
          ),
        );
        expect(refused, isNull);
      },
    );

    test('simultaneous writes cannot jointly exceed the cap', () async {
      final capped = FileToolOutputStore(
        workspaceDir: (id) => p.join(dataDir.path, id),
        maxEntriesPerScope: 3,
      );
      final references = await Future.wait([
        for (var i = 0; i < 12; i++)
          capped.put(
            ToolOutputWrite(scope: scope, toolName: 'bash', content: 'text $i'),
          ),
      ]);
      final accepted = references.whereType<ToolOutputReference>().toList();
      expect(accepted.length, 3);
      for (final reference in accepted) {
        expect(
          (await capped.read(scope, reference.handle)).status,
          ToolOutputReadStatus.ok,
        );
      }
      final dir = Directory(scopeDir('ws1', scope));
      expect(
        dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.txt'))
            .length,
        3,
      );
      expect(
        dir.listSync().where((f) => f.path.endsWith('.stage')),
        isEmpty,
        reason: 'no staging file may survive a write',
      );
    });

    test(
      'clearConversation retires every agent scope of one conversation',
      () async {
        const otherAgent = ToolOutputScope(
          workspaceId: 'ws1',
          conversationId: 'c1',
          agentId: 'a2',
        );
        const longerConversation = ToolOutputScope(
          workspaceId: 'ws1',
          conversationId: 'c1x',
          agentId: 'a1',
        );
        final mine = await put('mine');
        final sibling = await put('sibling', at: otherAgent);
        final extended = await put('extended', at: longerConversation);

        await store.clearConversation(scope);

        expect(
          (await store.read(scope, mine.handle)).status,
          ToolOutputReadStatus.notFound,
        );
        expect(
          (await store.read(otherAgent, sibling.handle)).status,
          ToolOutputReadStatus.notFound,
        );
        expect(
          (await store.read(longerConversation, extended.handle)).chunk!.text,
          'extended',
        );
        expect(Directory(scopeDir('ws1', scope)).existsSync(), isFalse);
        expect(Directory(scopeDir('ws1', otherAgent)).existsSync(), isFalse);
        expect(
          Directory(scopeDir('ws1', longerConversation)).existsSync(),
          isTrue,
          reason: 'a conversation whose id extends this one must survive',
        );
      },
    );

    test('clearScope retires exactly one scope', () async {
      const other = ToolOutputScope(
        workspaceId: 'ws1',
        conversationId: 'c1',
        agentId: 'a2',
      );
      final mine = await put('mine');
      final theirs = await put('theirs', at: other);

      await store.clearScope(scope);

      expect(
        (await store.read(scope, mine.handle)).status,
        ToolOutputReadStatus.notFound,
      );
      expect((await store.read(other, theirs.handle)).chunk!.text, 'theirs');
      expect(Directory(scopeDir('ws1', scope)).existsSync(), isFalse);
    });
  });

  group('atomicity', () {
    test('nothing is published when the metadata rename fails', () async {
      const handle = 'out_atomicityprobe00000';
      final failing = FileToolOutputStore(
        workspaceDir: (id) => p.join(dataDir.path, id),
        newHandle: () => handle,
      );
      final dir = Directory(scopeDir('ws1', scope))
        ..createSync(recursive: true);
      // A directory where the metadata file must land makes the second rename
      // fail after the text file is already in place.
      Directory(p.join(dir.path, '$handle.json')).createSync();

      final reference = await failing.put(
        const ToolOutputWrite(
          scope: scope,
          toolName: 'bash',
          content: 'half published',
        ),
      );

      expect(reference, isNull);
      expect(
        File(p.join(dir.path, '$handle.txt')).existsSync(),
        isFalse,
        reason: 'the half-published text file must be rolled back',
      );
      expect(dir.listSync().where((f) => f.path.endsWith('.stage')), isEmpty);
      expect(
        (await failing.read(scope, handle)).status,
        ToolOutputReadStatus.notFound,
      );
    });

    test(
      'a published entry is complete: both files, no staging litter',
      () async {
        final reference = await put(sampleText(lines: 20));
        final dir = Directory(scopeDir('ws1', scope));
        final names = [
          for (final entity in dir.listSync()) p.basename(entity.path),
        ]..sort();
        expect(names, ['${reference.handle}.json', '${reference.handle}.txt']);
      },
    );
  });

  group('index', () {
    test(
      'buildUtf8Index matches the encoder and checkpoints char boundaries',
      () {
        final content = unicodeText();
        final index = buildUtf8Index(content, interval: 4096);
        expect(index.bytes, utf8LengthOf(content));
        expect(index.offsets.first, 0);
        expect(index.chars.first, 0);
        expect(index.offsets.length, 1 + content.length ~/ 4096);
        expect(index.chars.length, index.offsets.length);
        // Every checkpoint points to a code-point boundary (which may precede
        // its nominal UTF-16 slot when that slot splits a surrogate pair).
        for (var slot = 1; slot < index.offsets.length; slot++) {
          final char = index.chars[slot];
          expect(char, inInclusiveRange(slot * 4096 - 1, slot * 4096));
          final bytes = utf8.encode(content.substring(0, char));
          expect(bytes.length, index.offsets[slot], reason: 'slot $slot');
        }
      },
    );
    test('a checkpoint inside a surrogate pair points before the pair', () {
      final content = '${'x' * 4095}🙂tail';
      final index = buildUtf8Index(content);
      expect(index.chars, [0, 4095]);
      expect(index.offsets, [0, 4095]);
      expect(index.bytes, utf8.encode(content).length);
    });
  });
}
