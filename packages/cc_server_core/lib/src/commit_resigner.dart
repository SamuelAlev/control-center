import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/features/dispatch/domain/ports/commit_signing_port.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';
// Narrow on purpose: the IDE service imports this file and must not drag the
// package-wide cc_infra barrel into every compile.
// ignore: implementation_imports
import 'package:cc_infra/src/dispatch/agent_run_gateway.dart'
    show AgentRunLease;
// ignore: implementation_imports
import 'package:cc_infra/src/dispatch/pushed_commit_inspector.dart';
import 'package:cc_natives/cc_natives.dart' show IsolatedGit, RigWorktreeGuard;

/// Signs the commits a person made in a server-run checkout (an IDE commit,
/// the rebase of a sync) with their own commit signing key, before they are
/// pushed.
///
/// A sandboxed run's git signs through the agent run gateway as it commits.
/// Server-run git has no such signer and must not get one: its hooks run on
/// the host with git's environment, so a signing token there would be theirs
/// to use. Instead the commits are made unsigned and re-created here with
/// plumbing only (`cat-file`, `hash-object`, `update-ref`): the same tree,
/// parents, author, committer and message, plus the `gpgsig` header git
/// itself would have written.
///
/// Only the person's own commits are signed: author and committer are their
/// identity and the commit passes the agent push rule for it
/// ([PushedCommitInspector.objectViolation]). Anyone else's commit keeps its
/// bytes; one above a re-created commit is re-parented, unsigned as it was. A
/// commit carrying a signature this key did not make is never rewritten, and
/// neither is any commit of the range below it, so no one's signature is ever
/// stripped. Every git call runs with replace refs and grafts off, so what is
/// read and signed is the repository's real history.
final class CommitResigner {
  /// Creates the signer over [_signing].
  CommitResigner(this._signing);

  final CommitSigningPort _signing;

  /// `git -c` arguments that keep a commit or rebase from signing with
  /// whatever the host's git config names; the signature is added here.
  static final List<String> unsignedGitArgs = [
    for (final (key, value) in AgentRunLease.unsignedGitConfig) ...[
      '-c',
      '$key=$value',
    ],
  ];

  /// Signs, as [userId] with [identity]'s key, every commit of the range
  /// [revisions] names (`rev-list` arguments the server builds, never a
  /// person's or an agent's text; `HEAD` alone when empty) that
  /// is the person's own and not yet signed by that key, oldest first,
  /// re-parenting the commits above a re-created one, and moves `HEAD` to the
  /// result.
  ///
  /// Returns the new `HEAD`. Throws [CommitSigningUnavailable] when the key
  /// is gone or is no longer [identity]'s, and [ProcessException] when git
  /// fails; `HEAD` is moved only after every commit was written.
  Future<String> sign({
    required String root,
    required String userId,
    required AgentCommitIdentity identity,
    List<String> revisions = const [],
  }) async {
    final key = identity.signingKey;
    if (key == null) {
      throw ArgumentError.value(identity, 'identity', 'has no signing key');
    }
    final head = await _head(root);
    final range = await _range(root, revisions, head);
    final commits = {
      for (final oid in range) oid: await _Commit.read(root, oid, identity),
    };
    // Children before parents: a commit that must keep its signature freezes
    // every commit of the range below it.
    final frozen = <String>{};
    for (final oid in range.reversed) {
      final commit = commits[oid]!;
      if (frozen.contains(oid) ||
          (commit.object.signed &&
              !(commit.own && commit.object.signedBy == key))) {
        frozen
          ..add(oid)
          ..addAll(commit.raw.parents.where(commits.containsKey));
      }
    }
    final recreated = <String, String>{};
    for (final oid in range) {
      final commit = commits[oid]!;
      final reparented = commit.raw.parents.any(recreated.containsKey);
      if (frozen.contains(oid) ||
          (!reparented && (!commit.own || commit.object.signedBy == key))) {
        continue;
      }
      final unsigned = commit.raw.unsigned(recreated);
      final bytes = commit.own
          ? _RawCommit.withSignature(
              unsigned,
              await _signing.sign(userId, key, unsigned),
            )
          : unsigned;
      recreated[oid] = (await _text(root, [
        'hash-object',
        '-t',
        'commit',
        '-w',
        '--stdin',
      ], stdin: bytes)).trim();
    }
    final signedHead = recreated[head];
    if (signedHead == null) {
      return head;
    }
    await _text(root, [
      'update-ref',
      '-m',
      'commit: sign',
      'HEAD',
      signedHead,
      head,
    ]);
    return signedHead;
  }

  /// The commits of the range [revisions] names (as for [sign]) that are
  /// [identity]'s own and not signed by its key. Empty when every one of them
  /// is signed, or [identity] has no key.
  Future<List<String>> unsignedOwn({
    required String root,
    required AgentCommitIdentity identity,
    List<String> revisions = const [],
  }) async {
    final key = identity.signingKey;
    if (key == null) {
      return const [];
    }
    final head = await _head(root);
    return [
      for (final oid in await _range(root, revisions, head))
        if (await _Commit.read(root, oid, identity) case final commit
            when commit.own && commit.object.signedBy != key)
          oid,
    ];
  }

  static Future<String> _head(String root) async => (await _text(root, [
    'rev-parse',
    '--verify',
    '--end-of-options',
    'HEAD^{commit}',
  ])).trim();

  /// Oldest first, parents before children.
  static Future<List<String>> _range(
    String root,
    List<String> revisions,
    String head,
  ) async => revisions.isEmpty
      ? [head]
      : [
          for (final line in const LineSplitter().convert(
            await _text(root, [
              'rev-list',
              '--reverse',
              '--topo-order',
              ...revisions,
            ]),
          ))
            if (line.trim().isNotEmpty) line.trim(),
        ];

  static Future<String> _text(
    String root,
    List<String> args, {
    List<int>? stdin,
  }) async => utf8.decode(await _bytes(root, args, stdin: stdin));

  /// Runs git with replace refs and grafts off and signing unconfigured: a
  /// `refs/replace/` entry or a graft file would otherwise have every read
  /// below see a history the repository does not hold.
  static Future<Uint8List> _bytes(
    String root,
    List<String> args, {
    List<int>? stdin,
  }) async {
    final process = await IsolatedGit.start(
      RigWorktreeGuard.gitArgs([
        ...unsignedGitArgs,
        '-c',
        'advice.graftFileDeprecated=false',
        ...args,
      ], workingDirectory: root),
      workingDirectory: root,
      environment: {
        'GIT_NO_REPLACE_OBJECTS': '1',
        'GIT_GRAFT_FILE': IsolatedGit.nullDevice,
      },
    );
    if (stdin != null) {
      process.stdin.add(stdin);
    }
    final closed = process.stdin.close();
    final out = process.stdout.fold<BytesBuilder>(
      BytesBuilder(copy: false),
      (b, chunk) => b..add(chunk),
    );
    final err = process.stderr.transform(utf8.decoder).join();
    final bytes = (await out).takeBytes();
    final code = await process.exitCode;
    try {
      await closed;
    } on Object {
      // git exited before reading its input; the exit code says why.
    }
    if (code != 0) {
      throw ProcessException('git', args, (await err).trim(), code);
    }
    return bytes;
  }
}

/// One commit of a range, as stored and as the push rule reads it.
final class _Commit {
  const _Commit(this.raw, this.object, {required this.own});

  /// Reads [oid] and decides whether it is [identity]'s own: authored and
  /// committed by it, and breaking none of the push rule's other terms once
  /// its signature (if any) is set aside.
  static Future<_Commit> read(
    String root,
    String oid,
    AgentCommitIdentity identity,
  ) async {
    final bytes = await CommitResigner._bytes(root, [
      'cat-file',
      'commit',
      oid,
    ]);
    final raw = _RawCommit.parse(bytes);
    final asUnsigned = await PushedCommitInspector.read(
      'commit',
      oid,
      raw.unsigned(const {}),
    );
    return _Commit(
      raw,
      await PushedCommitInspector.read('commit', oid, bytes),
      own:
          PushedCommitInspector.objectViolation(
            asUnsigned,
            identity.unsigned,
          ) ==
          null,
    );
  }

  final _RawCommit raw;
  final PushedGitObject object;
  final bool own;
}

/// A raw commit object, split where a signature goes.
class _RawCommit {
  const _RawCommit(this._headers, this._rest);

  /// Parses [raw] into its header lines (each with its line ending, a
  /// header's continuation lines kept with it) and everything from the blank
  /// line on.
  factory _RawCommit.parse(List<int> raw) {
    final headers = <List<int>>[];
    var offset = 0;
    while (offset < raw.length) {
      var end = raw.indexOf(0x0a, offset);
      end = end < 0 ? raw.length : end + 1;
      if (end - offset == 1 && raw[offset] == 0x0a) {
        break;
      }
      final line = raw.sublist(offset, end);
      if (line.first == 0x20 && headers.isNotEmpty) {
        headers.last.addAll(line);
      } else {
        headers.add(List.of(line));
      }
      offset = end;
    }
    return _RawCommit(headers, raw.sublist(offset));
  }

  final List<List<int>> _headers;
  final List<int> _rest;

  static final List<int> _parent = ascii.encode('parent ');
  static final List<int> _gpgsig = ascii.encode('gpgsig');

  /// The commit's parent ids.
  List<String> get parents => [
    for (final header in _headers)
      if (_startsWith(header, _parent))
        ascii.decode(header.sublist(_parent.length)).trim(),
  ];

  /// This commit without any signature header and with each parent that
  /// [recreated] replaces pointed at its replacement: exactly what a
  /// signature of it signs.
  Uint8List unsigned(Map<String, String> recreated) {
    final out = BytesBuilder();
    for (final header in _headers) {
      if (_startsWith(header, _gpgsig)) {
        continue;
      }
      if (_startsWith(header, _parent)) {
        final parent = ascii.decode(header.sublist(_parent.length)).trim();
        out.add(ascii.encode('parent ${recreated[parent] ?? parent}\n'));
        continue;
      }
      out.add(header);
    }
    out.add(_rest);
    return out.takeBytes();
  }

  /// [unsigned] with [armored] as its `gpgsig` header, where git writes it:
  /// after the other headers, every line after the first indented by one
  /// space.
  static Uint8List withSignature(List<int> unsigned, String armored) {
    final split = _headerEnd(unsigned);
    final lines = const LineSplitter().convert(armored.trimRight());
    return (BytesBuilder()
          ..add(unsigned.sublist(0, split))
          ..add(ascii.encode('gpgsig ${lines.join('\n ')}\n'))
          ..add(unsigned.sublist(split)))
        .takeBytes();
  }

  /// The offset of the blank line that ends the headers of [raw] (its
  /// length when it has none).
  static int _headerEnd(List<int> raw) {
    for (var i = 0; i + 1 < raw.length; i++) {
      if (raw[i] == 0x0a && raw[i + 1] == 0x0a) {
        return i + 1;
      }
    }
    return raw.length;
  }

  static bool _startsWith(List<int> bytes, List<int> prefix) {
    if (bytes.length < prefix.length) {
      return false;
    }
    for (var i = 0; i < prefix.length; i++) {
      if (bytes[i] != prefix[i]) {
        return false;
      }
    }
    return true;
  }
}
