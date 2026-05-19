import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/value_objects/message_attachment.dart';
import 'package:cc_infra/src/blobs/blob_store.dart';
import 'package:cc_infra/src/messaging/prompt_attachments.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory root;
  late BlobStore store;
  late SpacePromptAttachments attachments;

  setUp(() {
    root = Directory.systemTemp.createTempSync('cc_prompt_attachments');
    store = BlobStore(
      workspaceDir: (workspaceId) => p.join(root.path, workspaceId),
    );
    attachments = SpacePromptAttachments(
      blobStore: store,
      spaceDir: (workspaceId, spaceId) async =>
          p.join(root.path, workspaceId, 'spaces', spaceId),
    );
  });
  tearDown(() => root.deleteSync(recursive: true));

  Future<String> put(String content) async {
    final stored = await store.put(
      'ws',
      Uint8List.fromList(utf8.encode(content)),
      mediaType: 'image/png',
    );
    return stored!.ref;
  }

  MessageAttachment named(
    String name,
    String ref, {
    String? localPath,
    AttachmentKind kind = AttachmentKind.image,
  }) => MessageAttachment(
    id: name,
    path: ref,
    name: name,
    kind: kind,
    localPath: localPath,
  );

  Future<Map<String, String>> resolve(List<MessageAttachment> list) =>
      attachments.resolve(
        workspaceId: 'ws',
        spaceId: 'space-1',
        attachments: list,
      );

  group('resolve', () {
    test('writes an uploaded blob into the space and returns its path', () async {
      final ref = await put('pixels');
      final paths = await resolve([named('shot.png', ref)]);
      final path = paths['shot.png']!;
      expect(File(path).readAsStringSync(), 'pixels');
      expect(
        p.dirname(path),
        p.join(root.path, 'ws', 'spaces', 'space-1', 'attachments'),
      );
    });

    test('keeps the original extension, which is how an adapter reads it', () async {
      final paths = await resolve([named('shot.png', await put('a'))]);
      expect(p.extension(paths['shot.png']!), '.png');
    });

    test('is idempotent: the same bytes reuse the same file', () async {
      final ref = await put('same');
      final first = await resolve([named('shot.png', ref)]);
      final second = await resolve([named('shot.png', ref)]);
      expect(second['shot.png'], first['shot.png']);
      expect(
        Directory(p.dirname(first['shot.png']!)).listSync(),
        hasLength(1),
      );
    });

    test('two files that ellipsize alike do not collide', () async {
      // The composer de-duplicates names WITHIN a message; nothing does across
      // messages, and a content hash is what keeps a week-old `shot.png` from
      // being served for today's.
      final a = await resolve([named('shot.png', await put('one'))]);
      final b = await resolve([named('shot.png', await put('two'))]);
      expect(b['shot.png'], isNot(a['shot.png']));
      expect(File(a['shot.png']!).readAsStringSync(), 'one');
      expect(File(b['shot.png']!).readAsStringSync(), 'two');
    });

    test('a name that would escape the directory cannot', () async {
      // The name is user-controlled: it reaches here from a token somebody can
      // type by hand.
      final paths = await resolve([
        named('../../etc/passwd', await put('x')),
      ]);
      final path = paths['../../etc/passwd']!;
      expect(
        p.dirname(path),
        p.join(root.path, 'ws', 'spaces', 'space-1', 'attachments'),
      );
      expect(p.basename(path), endsWith('passwd'));
    });

    test('an ellipsized screenshot name survives as a usable filename', () async {
      const name = 'Screenshot 202… 17.55.49.png';
      final paths = await resolve([named(name, await put('x'))]);
      expect(paths[name], endsWith('.png'));
      expect(p.basename(paths[name]!), isNot(contains(' ')));
    });

    test('a blob that is not in the store is omitted, not guessed', () async {
      final paths = await resolve([
        named('missing.png', 'blob:sha256:${'f' * 64}'),
      ]);
      expect(paths, isEmpty);
    });

    test('one bad attachment does not take the others with it', () async {
      final ref = await put('good');
      final paths = await resolve([
        named('missing.png', 'blob:sha256:${'f' * 64}'),
        named('good.png', ref),
      ]);
      expect(paths.keys, ['good.png']);
    });
  });

  group('a shared filesystem', () {
    test('points a FILE at the real thing, not at a copy', () async {
      // The commonest reference of all: a source file picked out of the
      // composer's `@` menu, on the machine the server runs on. Handing the
      // agent a snapshot would look like the agent ignoring its own edits.
      final real = File(p.join(root.path, 'main.dart'))
        ..writeAsStringSync('void main() {}');
      final paths = await resolve([
        named(
          'main.dart',
          await put('void main() {}'),
          localPath: real.path,
          kind: AttachmentKind.file,
        ),
      ]);
      expect(paths['main.dart'], real.path);
    });

    test('still copies a PICTURE, whose sender path is often temporary', () async {
      // A macOS screenshot drag hands over a file in `TemporaryItems` that the
      // OS deletes when the drag ends, and nobody edits a screenshot anyway.
      final temp = File(p.join(root.path, 'shot.png'))
        ..writeAsStringSync('pixels');
      final paths = await resolve([
        named('shot.png', await put('pixels'), localPath: temp.path),
      ]);
      expect(paths['shot.png'], isNot(temp.path));
      expect(
        p.dirname(paths['shot.png']!),
        p.join(root.path, 'ws', 'spaces', 'space-1', 'attachments'),
      );
    });

    test('copies a FILE whose sender path this host cannot see', () async {
      final paths = await resolve([
        named(
          'spec.pdf',
          await put('%PDF'),
          localPath: '/definitely/not/here/spec.pdf',
          kind: AttachmentKind.file,
        ),
      ]);
      expect(File(paths['spec.pdf']!).readAsStringSync(), '%PDF');
    });
  });

  group('never uploaded', () {
    test('falls back to the sender path when this host shares it', () async {
      final local = File(p.join(root.path, 'huge.png'))
        ..writeAsStringSync('local');
      final paths = await resolve([named('huge.png', local.path)]);
      expect(paths['huge.png'], local.path);
    });

    test('drops a sender path this host cannot see', () async {
      // The whole point: a path off another machine is worse than no path,
      // because the agent will report having looked and found nothing.
      final paths = await resolve([
        named('huge.png', '/definitely/not/here/huge.png'),
      ]);
      expect(paths, isEmpty);
    });

    test('prefers the recorded localPath over a blob-less reference', () async {
      final local = File(p.join(root.path, 'notes.md'))
        ..writeAsStringSync('notes');
      final paths = await resolve([
        named(
          'notes.md',
          '/gone.md',
          localPath: local.path,
          kind: AttachmentKind.file,
        ),
      ]);
      expect(paths['notes.md'], local.path);
    });
  });

  test('nothing attached writes no directory', () async {
    expect(await resolve(const []), isEmpty);
    expect(
      Directory(
        p.join(root.path, 'ws', 'spaces', 'space-1', 'attachments'),
      ).existsSync(),
      isFalse,
    );
  });
}
