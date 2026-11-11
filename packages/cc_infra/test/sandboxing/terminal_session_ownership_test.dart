@TestOn('mac-os || linux')
library;

import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart'
    show NotFoundException, WorkspaceMismatchException;
import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';
import 'package:cc_infra/src/sandboxing/terminal_session_service.dart';
import 'package:cc_natives/cc_natives.dart';
import 'package:test/test.dart';

/// A workspace whose directory is a real one.
class _RootedFs implements WorkspaceFilesystemPort {
  _RootedFs(this.root);

  final String root;

  @override
  Future<String> workspaceDir(String workspaceId) async => root;

  @override
  Future<void> ensureWorkspaceDirs(String workspaceId) async {}

  @override
  Future<String> ensureSpaceDir(String workspaceId, String spaceId) async =>
      root;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

DynamicLibrary? _openPty() {
  final home = Platform.environment['HOME'] ?? '';
  for (final path in [
    ?Platform.environment[ptyLibraryEnvVar],
    '$home/Library/Application Support/com.alev.control-center/libccpty.dylib',
    '$home/.local/share/control_center/libccpty.so',
  ]) {
    if (File(path).existsSync()) {
      return DynamicLibrary.open(path);
    }
  }
  return null;
}

/// A terminal belongs to the person who opened it: on a real PTY, another
/// member of the same workspace can neither read, type into, resize nor end
/// it, and learns nothing a wrong id would not tell them.
void main() {
  Pty.libraryResolver = _openPty;
  tearDownAll(() => Pty.libraryResolver = defaultPtyLibraryResolver);
  final skip = Pty.isAvailable ? false : 'libccpty is not built here';

  late Directory root;
  late TerminalSessionService terminals;

  setUp(() {
    root = Directory.systemTemp.createTempSync('cc-term-own-');
    terminals = TerminalSessionService(
      manager: SandboxManager.test(),
      filesystem: _RootedFs(root.path),
    );
    addTearDown(() async {
      await terminals.disposeAll();
      root.deleteSync(recursive: true);
    });
  });

  /// The server owner's host shell: the one backend a test can start without
  /// a sandbox around it.
  Future<String> open(String userId) => terminals.spawn(
    workspaceId: 'ws-1',
    actingUserId: userId,
    hostShellAllowed: true,
    rows: 24,
    cols: 80,
    spaceId: 'space-1',
    backend: 'none',
  );

  Future<String> read(Stream<List<int>> output, String marker) async {
    final bytes = <int>[];
    final subscription = output.listen(bytes.addAll);
    final deadline = DateTime.now().add(const Duration(seconds: 3));
    while (!String.fromCharCodes(bytes).contains(marker) &&
        DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    await subscription.cancel();
    return String.fromCharCodes(bytes);
  }

  test('session ids are random and name no workspace or space', () async {
    final first = await open('ada');
    final second = await open('ada');
    expect(first, matches(RegExp(r'^tty-[0-9a-f]{24}$')));
    expect(second, matches(RegExp(r'^tty-[0-9a-f]{24}$')));
    expect(first, isNot(second));
  }, skip: skip);

  test(
    'another member cannot read it: the same answer as no session',
    () async {
      final id = await open('ada');
      Object? caught(void Function() call) {
        try {
          call();
        } on Object catch (e) {
          return e;
        }
        return null;
      }

      final foreign = caught(
        () =>
            terminals.output(workspaceId: 'ws-1', userId: 'eve', sessionId: id),
      );
      final missing = caught(
        () => terminals.output(
          workspaceId: 'ws-1',
          userId: 'eve',
          sessionId: 'tty-000000000000000000000000',
        ),
      );
      expect(foreign, isA<NotFoundException>());
      expect(missing, isA<NotFoundException>());
      expect(
        () =>
            terminals.titles(workspaceId: 'ws-1', userId: 'eve', sessionId: id),
        throwsA(isA<NotFoundException>()),
      );
    },
    skip: skip,
  );

  test('another member cannot type into it, resize it or end it', () async {
    final id = await open('ada');
    final adaSees = read(
      terminals.output(workspaceId: 'ws-1', userId: 'ada', sessionId: id),
      'EVE_WAS_HERE',
    );
    final sent = await terminals.write(
      workspaceId: 'ws-1',
      userId: 'eve',
      sessionId: id,
      data: 'echo EVE_WAS_HERE\r'.codeUnits,
    );
    expect(sent.sent, isFalse);
    await terminals.resize(
      workspaceId: 'ws-1',
      userId: 'eve',
      sessionId: id,
      rows: 10,
      cols: 10,
    );
    await terminals.kill(workspaceId: 'ws-1', userId: 'eve', sessionId: id);

    expect(await adaSees, isNot(contains('EVE_WAS_HERE')));
    expect(terminals.backendOf(id), 'none', reason: 'still running');
  }, skip: skip);

  test('the person who opened it uses and ends it', () async {
    final id = await open('ada');
    final adaSees = read(
      terminals.output(workspaceId: 'ws-1', userId: 'ada', sessionId: id),
      'ADA_MARK',
    );
    final sent = await terminals.write(
      workspaceId: 'ws-1',
      userId: 'ada',
      sessionId: id,
      data: 'echo ADA_MARK\r'.codeUnits,
    );
    expect(sent.sent, isTrue);
    expect(await adaSees, contains('ADA_MARK'));

    await terminals.kill(workspaceId: 'ws-1', userId: 'ada', sessionId: id);
    expect(terminals.backendOf(id), isNull);
  }, skip: skip);

  test('another workspace is refused loudly', () async {
    final id = await open('ada');
    await expectLater(
      terminals.kill(workspaceId: 'ws-2', userId: 'ada', sessionId: id),
      throwsA(isA<WorkspaceMismatchException>()),
    );
    expect(
      () => terminals.output(workspaceId: 'ws-2', userId: 'ada', sessionId: id),
      throwsA(isA<WorkspaceMismatchException>()),
    );
  }, skip: skip);

  test('a session no person opened stays open to the workspace', () async {
    final session = await terminals.spawnOwned(
      workspaceId: 'ws-1',
      owner: 'environment:env-1/web',
      executable: '/bin/sh',
      arguments: const ['-c', r'read line; echo "got $line"; sleep 5'],
      cwd: root.path,
    );
    final seen = read(
      terminals.output(
        workspaceId: 'ws-1',
        userId: 'eve',
        sessionId: session.sessionId,
      ),
      'got hi',
    );
    await terminals.write(
      workspaceId: 'ws-1',
      userId: 'eve',
      sessionId: session.sessionId,
      data: 'hi\n'.codeUnits,
    );
    expect(await seen, contains('got hi'));
    expect(session.sessionId, matches(RegExp(r'^tty-[0-9a-f]{24}$')));
  }, skip: skip);

  test('an owned session names its space so the caller can check the grant '
      'that drives it', () async {
    final owned = await terminals.spawnOwned(
      workspaceId: 'ws-1',
      owner: 'environment:env-1/setup',
      executable: '/bin/sh',
      arguments: const ['-c', 'sleep 5'],
      cwd: root.path,
      spaceId: 'space-1',
    );
    expect(terminals.ownedSessionOf(owned.sessionId), (spaceId: 'space-1'));
    expect(terminals.ownedSessionOf(await open('ada')), isNull);
    expect(terminals.ownedSessionOf('tty-unknown'), isNull);
  }, skip: skip);
}
