import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';
import 'package:cc_natives/cc_natives.dart' show IsolatedGit;

/// A commit or annotated tag in a pushed pack, as far as attribution goes.
class PushedGitObject {
  /// Creates a [PushedGitObject].
  const PushedGitObject({
    required this.kind,
    required this.oid,
    required this.committerEmail,
    required this.signed,
    required this.signedOff,
    this.authorEmail,
  });

  /// `commit` or `tag`.
  final String kind;

  /// The object id.
  final String oid;

  /// The commit's author email; null for a tag.
  final String? authorEmail;

  /// The commit's committer or the tag's tagger email.
  final String committerEmail;

  /// Whether the object carries a signature.
  final bool signed;

  /// Whether the message carries a `Signed-off-by:` trailer.
  final bool signedOff;
}

/// Reads the commits and tags out of a pushed pack and checks them against a
/// run's [AgentCommitIdentity].
///
/// The pack is indexed in a scratch bare repository by the isolated git
/// helper, so nothing about the host's git config, hooks or object store is
/// involved. A thin pack cannot be indexed there; the push proxy advertises
/// `no-thin`, which git honors, so a well-behaved client never sends one.
// A namespace over one stateless check.
// ignore: avoid_classes_with_only_static_members
abstract final class PushedCommitInspector {
  static final RegExp _ident = RegExp(r'^[^<>\n]* <([^<>\n]*)> \d+ [+-]\d{4}$');
  static final RegExp _signedOff = RegExp(
    r'^signed-off-by:',
    caseSensitive: false,
    multiLine: true,
  );
  static final RegExp _tagSignature = RegExp(
    r'^-----BEGIN (?:PGP|SSH) SIGNATURE-----$|^-----BEGIN SIGNED MESSAGE-----$',
    multiLine: true,
  );

  /// Every commit and tag in [pack] (a raw `PACK` stream on disk). Throws
  /// [FormatException] when the pack cannot be indexed or read.
  static Future<List<PushedGitObject>> inspect(File pack) async {
    final scratch = await Directory.systemTemp.createTemp('cc-push-inspect-');
    try {
      final repo = '${scratch.path}/repo.git';
      await _git(['init', '--bare', '--quiet', repo]);
      final indexed = await _git([
        'index-pack',
        '-o',
        '${scratch.path}/pushed.idx',
        pack.path,
      ], workingDirectory: repo);
      if (indexed.exitCode != 0) {
        throw FormatException(
          'unreadable pack: ${(indexed.stderr as String).trim()}',
        );
      }
      // Point the scratch repo at the pack it just indexed.
      final packDir = Directory('$repo/objects/pack');
      await pack.copy('${packDir.path}/pack-pushed.pack');
      await File(
        '${scratch.path}/pushed.idx',
      ).copy('${packDir.path}/pack-pushed.idx');

      final listed = await _git([
        'cat-file',
        '--batch-all-objects',
        '--batch-check=%(objectname) %(objecttype)',
      ], workingDirectory: repo);
      if (listed.exitCode != 0) {
        throw FormatException(
          'unlistable pack: ${(listed.stderr as String).trim()}',
        );
      }
      final wanted = <(String, String)>[
        for (final line in LineSplitter.split(listed.stdout as String))
          if (line.split(' ') case [
            final oid,
            final type,
          ] when type == 'commit' || type == 'tag')
            (oid, type),
      ];
      final out = <PushedGitObject>[];
      if (wanted.isEmpty) {
        return out;
      }
      final batch = await IsolatedGit.start([
        'cat-file',
        '--batch',
      ], workingDirectory: repo);
      batch.stdin.write(wanted.map((w) => '${w.$1}\n').join());
      await batch.stdin.close();
      final bytesFuture = batch.stdout.fold<BytesBuilder>(
        BytesBuilder(copy: false),
        (b, chunk) => b..add(chunk),
      );
      final stderrFuture = batch.stderr.transform(utf8.decoder).join();
      final bytes = (await bytesFuture).takeBytes();
      if (await batch.exitCode != 0) {
        throw FormatException('unreadable objects: ${await stderrFuture}');
      }
      var offset = 0;
      for (final (oid, type) in wanted) {
        final newline = bytes.indexOf(0x0a, offset);
        if (newline < 0) {
          throw FormatException('truncated object $oid');
        }
        final header = ascii.decode(bytes.sublist(offset, newline)).split(' ');
        final size = header.length == 3 ? int.tryParse(header[2]) : null;
        if (header.first != oid || size == null) {
          throw FormatException('unexpected object for $oid');
        }
        final start = newline + 1;
        final raw = utf8.decode(
          bytes.sublist(start, start + size),
          allowMalformed: true,
        );
        out.add(parse(type, oid, raw));
        offset = start + size + 1;
      }
      return out;
    } finally {
      try {
        await scratch.delete(recursive: true);
      } on FileSystemException {
        // Best effort.
      }
    }
  }

  /// Parses one raw commit or tag object. Visible for tests.
  static PushedGitObject parse(String kind, String oid, String raw) {
    final split = raw.indexOf('\n\n');
    final headerBlock = split < 0 ? raw : raw.substring(0, split);
    final message = split < 0 ? '' : raw.substring(split + 2);
    String? author;
    String? committer;
    var authors = 0;
    var committers = 0;
    var signed = false;
    for (final line in headerBlock.split('\n')) {
      if (line.startsWith(' ')) {
        continue;
      }
      final space = line.indexOf(' ');
      final name = space < 0 ? line : line.substring(0, space);
      final value = space < 0 ? '' : line.substring(space + 1);
      switch (name) {
        case 'author':
          authors++;
          author = _ident.firstMatch(value)?.group(1);
        case 'committer' || 'tagger':
          committers++;
          committer = _ident.firstMatch(value)?.group(1);
        case 'gpgsig' || 'gpgsig-sha256':
          signed = true;
      }
    }
    if (kind == 'tag' && _tagSignature.hasMatch(message)) {
      signed = true;
    }
    // A repeated identity header is one git shows by its first occurrence:
    // never let the checked one differ from the displayed one.
    if (committer == null ||
        committers != 1 ||
        authors > 1 ||
        (kind == 'commit' && author == null)) {
      throw FormatException('malformed $kind $oid');
    }
    return PushedGitObject(
      kind: kind,
      oid: oid,
      authorEmail: author,
      committerEmail: committer,
      signed: signed,
      signedOff: _signedOff.hasMatch(message),
    );
  }

  /// Why [objects] break [identity]'s rule, or null when they all keep it.
  ///
  /// Every new commit must name the run's author and committer exactly; a tag
  /// its committer as tagger. Only a run whose identity may use the host key
  /// may push a signed object. No agent commit carries `Signed-off-by:`: the
  /// Developer Certificate of Origin is a human's statement.
  static String? violation(
    List<PushedGitObject> objects,
    AgentCommitIdentity identity,
  ) {
    String short(String oid) => oid.length > 12 ? oid.substring(0, 12) : oid;
    bool same(String? a, String b) =>
        a != null && a.trim().toLowerCase() == b.trim().toLowerCase();
    for (final object in objects) {
      final at = '${object.kind} ${short(object.oid)}';
      if (object.signedOff) {
        return '$at carries a Signed-off-by trailer; agent commits may not '
            'sign off on a human\'s behalf.';
      }
      if (object.signed && !identity.mayHostSign) {
        return '$at is signed, and this run may only push unsigned commits.';
      }
      if (!same(object.committerEmail, identity.committerEmail)) {
        return '$at is ${object.kind == 'tag' ? 'tagged' : 'committed'} by '
            '${object.committerEmail}; this run commits as '
            '${identity.committerEmail}.';
      }
      if (object.kind == 'commit' &&
          !same(object.authorEmail, identity.authorEmail)) {
        return '$at is authored by ${object.authorEmail}; this run authors '
            'as ${identity.authorEmail}.';
      }
    }
    return null;
  }

  static Future<ProcessResult> _git(
    List<String> args, {
    String? workingDirectory,
  }) => IsolatedGit.run(args, workingDirectory: workingDirectory);
}
