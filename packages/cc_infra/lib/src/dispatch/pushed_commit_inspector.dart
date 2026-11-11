import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';
import 'package:cc_infra/src/git/ssh_commit_signature.dart';
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
    this.signedBy,
    this.committerName = '',
    this.authorName,
    this.authorEmail,
    this.encoding,
    this.authorTime,
    this.committerTime,
    this.coAuthors = const [],
    this.creditedCoAuthors = const [],
    this.buildsOn = const [],
  });

  /// `commit` or `tag`.
  final String kind;

  /// The object id.
  final String oid;

  /// The commit's author name; null for a tag.
  final String? authorName;

  /// The commit's author email; null for a tag.
  final String? authorEmail;

  /// The commit's committer or the tag's tagger name.
  final String committerName;

  /// The commit's committer or the tag's tagger email.
  final String committerEmail;

  /// The object's `encoding` header, when it has one. Git and GitHub
  /// re-encode a message that declares another encoding, so a message that
  /// reads clean here could carry trailers once decoded there.
  final String? encoding;

  /// When the commit says it was authored, in seconds since the epoch; null
  /// for a tag.
  final int? authorTime;

  /// When the commit says it was committed (a tag: tagged), in seconds since
  /// the epoch.
  final int? committerTime;

  /// Whether the object carries a signature of any kind.
  final bool signed;

  /// The `ssh-ed25519 <base64>` key whose SSH signature of this commit
  /// verifies, or null: an unsigned object, a tag, or a signature that is not
  /// a valid Ed25519 SSH signature of exactly this commit.
  final String? signedBy;

  /// Whether the message carries a `Signed-off-by:` trailer.
  final bool signedOff;

  /// Every line of the message that reads like a `Co-authored-by:` line
  /// (any case, wherever it stands), trimmed, in order.
  final List<String> coAuthors;

  /// The `Co-authored-by:` lines that are trailers under the strictest
  /// reading, trimmed, in order: the message's last paragraph, when it is
  /// not also its first and every line of it is a `Token: value` trailer.
  /// Git reads trailers only there, and a forge that credits a co-author
  /// reads no more than git does.
  final List<String> creditedCoAuthors;

  /// The ids of the objects this one stands on: a commit's parents, a tag's
  /// target. A push that does not carry one of them publishes it unseen
  /// unless the repository already has it.
  final List<String> buildsOn;
}

/// Reads the commits and tags out of a pushed pack and checks them against a
/// run's [AgentCommitIdentity]: who they name, whom they credit and which
/// key signed them.
///
/// The pack is indexed in a scratch bare repository by the isolated git
/// helper, so nothing about the host's git config, hooks or object store is
/// involved. A thin pack cannot be indexed there; the push proxy advertises
/// `no-thin`, which git honors, so a well-behaved client never sends one.
// A namespace over one stateless check.
// ignore: avoid_classes_with_only_static_members
abstract final class PushedCommitInspector {
  static final RegExp _ident = RegExp(
    r'^([^<>\n]*) <([^<>\n]*)> (\d+) [+-]\d{4}$',
  );
  static final RegExp _signedOff = RegExp(
    r'^[ \t]*signed-off-by[ \t]*:',
    caseSensitive: false,
    multiLine: true,
  );
  static final RegExp _coAuthor = RegExp(
    r'^[ \t]*co-authored-by[ \t]*:.*$',
    caseSensitive: false,
    multiLine: true,
  );

  /// A line git reads as a trailer: a token of letters, digits and dashes,
  /// then the colon. A line that starts with whitespace continues the
  /// trailer above it in git's reading, and is not one here.
  static final RegExp _trailerLine = RegExp('^[A-Za-z0-9-]+:');
  static final RegExp _coAuthorTrailer = RegExp(
    '^co-authored-by:',
    caseSensitive: false,
  );

  static final RegExp _objectId = RegExp(r'^[0-9a-f]{40,64}$');

  /// A line git reads as blank: nothing but ASCII whitespace.
  static final RegExp _blankLine = RegExp(r'^[ \t\r\x0b\x0c]*$');

  /// Where git finds a tag's signature: a line that starts with one of the
  /// armor headers it knows, whatever follows on that line.
  static final RegExp _tagSignature = RegExp(
    '^-----BEGIN (?:PGP SIGNATURE|PGP MESSAGE|SSH SIGNATURE|SIGNED MESSAGE)'
    '-----',
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
      return await _read(repo, wanted);
    } finally {
      try {
        await scratch.delete(recursive: true);
      } on FileSystemException {
        // Best effort.
      }
    }
  }

  /// The commits [oids] of the repository at [gitDir] (a git dir, or a
  /// bare repository): how a server-side push that never passes the push
  /// proxy (a stack publish) reads what it is about to send. Throws
  /// [FormatException] when one is missing or is not a commit.
  static Future<List<PushedGitObject>> inspectCommits(
    String gitDir,
    List<String> oids,
  ) => _read(gitDir, [for (final oid in oids) (oid, 'commit')]);

  /// Reads [wanted] (`(oid, type)`) out of [repo] in one `cat-file --batch`.
  static Future<List<PushedGitObject>> _read(
    String repo,
    List<(String, String)> wanted,
  ) async {
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
      if (size == null || header.first != oid || header[1] != type) {
        throw FormatException('unexpected object for $oid');
      }
      final start = newline + 1;
      out.add(await read(type, oid, bytes.sublist(start, start + size)));
      offset = start + size + 1;
    }
    return out;
  }

  /// Parses the raw commit or tag object [bytes] and verifies a commit's
  /// SSH signature against the exact bytes it signed.
  static Future<PushedGitObject> read(
    String kind,
    String oid,
    List<int> bytes,
  ) async {
    final object = parse(kind, oid, utf8.decode(bytes, allowMalformed: true));
    if (kind != 'commit' || !object.signed) {
      return object;
    }
    final signature = _commitSignature(bytes);
    final signedBy = signature == null
        ? null
        : await SshSignature.signerOf(signature.armored, signature.payload);
    return PushedGitObject(
      kind: object.kind,
      oid: object.oid,
      authorName: object.authorName,
      authorEmail: object.authorEmail,
      committerName: object.committerName,
      committerEmail: object.committerEmail,
      encoding: object.encoding,
      authorTime: object.authorTime,
      committerTime: object.committerTime,
      signed: true,
      signedBy: signedBy,
      signedOff: object.signedOff,
      coAuthors: object.coAuthors,
      creditedCoAuthors: object.creditedCoAuthors,
    );
  }

  /// The one `gpgsig` header of the commit [bytes] and what it signed: the
  /// commit without that header, exactly as git builds it. Null when the
  /// commit has no `gpgsig` header, more than one, or a `gpgsig-sha256` one
  /// (no single signature then covers what git shows).
  static ({String armored, List<int> payload})? _commitSignature(
    List<int> bytes,
  ) {
    final payload = BytesBuilder(copy: false);
    final armored = StringBuffer();
    var signatures = 0;
    var inSignature = false;
    var offset = 0;
    while (offset < bytes.length) {
      var end = bytes.indexOf(0x0a, offset);
      end = end < 0 ? bytes.length : end + 1;
      final line = bytes.sublist(offset, end);
      offset = end;
      if (line.length == 1 && line.first == 0x0a) {
        // The blank line ends the headers; the message follows verbatim.
        payload
          ..add(line)
          ..add(bytes.sublist(offset));
        break;
      }
      final text = ascii.decode(line, allowInvalid: true);
      if (inSignature && text.startsWith(' ')) {
        armored.write(text.substring(1));
        continue;
      }
      inSignature = false;
      if (text.startsWith('gpgsig-sha256 ')) {
        return null;
      }
      if (text.startsWith('gpgsig ')) {
        signatures++;
        inSignature = true;
        armored.write(text.substring('gpgsig '.length));
        continue;
      }
      payload.add(line);
    }
    return signatures == 1
        ? (armored: armored.toString(), payload: payload.takeBytes())
        : null;
  }

  /// Parses the attribution of one raw commit or tag object, without
  /// verifying its signature ([read] does). Visible for tests.
  static PushedGitObject parse(String kind, String oid, String raw) {
    final split = raw.indexOf('\n\n');
    final headerBlock = split < 0 ? raw : raw.substring(0, split);
    final message = split < 0 ? '' : raw.substring(split + 2);
    RegExpMatch? author;
    RegExpMatch? committer;
    String? encoding;
    var authors = 0;
    var committers = 0;
    var encodings = 0;
    var signed = false;
    final buildsOn = <String>[];
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
          author = _ident.firstMatch(value);
        case 'committer' || 'tagger':
          committers++;
          committer = _ident.firstMatch(value);
        case 'parent' when kind == 'commit':
        case 'object' when kind == 'tag':
          buildsOn.add(value);
        case 'encoding':
          encodings++;
          encoding = value.trim();
        case 'gpgsig' || 'gpgsig-sha256':
          signed = true;
      }
    }
    if (kind == 'tag' && _tagSignature.hasMatch(message)) {
      signed = true;
    }
    // A repeated identity header is one git shows by its first occurrence:
    // never let the checked one differ from the displayed one.
    final authorTime = author == null ? null : int.tryParse(author.group(3)!);
    final committerTime = committer == null
        ? null
        : int.tryParse(committer.group(3)!);
    if (committer == null ||
        committerTime == null ||
        committers != 1 ||
        authors > 1 ||
        encodings > 1 ||
        !buildsOn.every(_objectId.hasMatch) ||
        (kind == 'tag' && buildsOn.length != 1) ||
        (kind == 'commit' && (author == null || authorTime == null))) {
      throw FormatException('malformed $kind $oid');
    }
    // Names are compared as git wrote them, not trimmed: git already strips
    // what it strips, and anything else is part of the name a forge shows.
    return PushedGitObject(
      kind: kind,
      oid: oid,
      authorName: author?.group(1),
      authorEmail: author?.group(2),
      committerName: committer.group(1)!,
      committerEmail: committer.group(2)!,
      encoding: encoding,
      authorTime: authorTime,
      committerTime: committerTime,
      signed: signed,
      signedOff: _signedOff.hasMatch(message),
      coAuthors: [
        for (final m in _coAuthor.allMatches(message)) m.group(0)!.trim(),
      ],
      creditedCoAuthors: _trailerCoAuthors(message),
      buildsOn: buildsOn,
    );
  }

  /// The co-author trailers of [message]: the `Co-authored-by:` lines of its
  /// last paragraph, when that paragraph is not the subject and holds
  /// nothing but trailer lines. Anything looser (a co-author line followed
  /// by prose, a continuation line, a block git would only accept by its
  /// 25% rule) credits nobody here, because readers disagree about it.
  static List<String> _trailerCoAuthors(String message) {
    final lines = message.split('\n');
    var end = lines.length;
    while (end > 0 && _blankLine.hasMatch(lines[end - 1])) {
      end--;
    }
    var start = end;
    while (start > 0 && !_blankLine.hasMatch(lines[start - 1])) {
      start--;
    }
    if (start == 0 || start == end) {
      return const [];
    }
    final block = lines.sublist(start, end);
    if (!block.every(_trailerLine.hasMatch)) {
      return const [];
    }
    return [
      for (final line in block)
        if (_coAuthorTrailer.hasMatch(line)) line.trim(),
    ];
  }

  /// A co-author line as compared: key and value case-insensitive, runs of
  /// whitespace collapsed.
  static String _normalizedCoAuthor(String line) {
    final colon = line.indexOf(':');
    final value = line
        .substring(colon + 1)
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
    return 'co-authored-by: ${value.toLowerCase()}';
  }

  /// Why [objects] break [identity]'s rule, or null when they all keep it.
  ///
  /// Every new commit names the identity's author as both author and
  /// committer (name and email); a tag names it as tagger. Every object is
  /// UTF-8: one that declares another `encoding` is refused, since git and
  /// GitHub re-encode its message and could find trailers this check never
  /// saw. None carries `Signed-off-by:`: the Developer Certificate of Origin
  /// is a statement only its human signer makes. Every new commit carries
  /// exactly the identity's `Co-Authored-By:` lines
  /// ([AgentCommitIdentity.coAuthorTrailers]) as trailers
  /// ([PushedGitObject.creditedCoAuthors]) and no line that reads like a
  /// co-author line anywhere else, so credit is neither dropped (a line
  /// git does not read as a trailer) nor borrowed (a forge shows any
  /// co-author it is given, unverified). Signing follows [AgentCommitIdentity.signingKey]:
  /// with a key, every commit carries a valid signature by exactly that key;
  /// without one, none is signed. Tags are never signed.
  static String? violation(
    List<PushedGitObject> objects,
    AgentCommitIdentity identity,
  ) => violationOfAny(objects, [identity]);

  /// [violation] for a push made for any of several runs (the open runs of
  /// one conversation, all for the same person): each object must keep at
  /// least one of [identities]' rules. With no identity, no commit passes.
  static String? violationOfAny(
    List<PushedGitObject> objects,
    List<AgentCommitIdentity> identities,
  ) {
    for (final object in objects) {
      String? problem = identities.isEmpty
          ? 'this run has no commit identity, so it cannot push commits.'
          : null;
      for (final identity in identities) {
        final found = objectViolation(object, identity);
        if (found == null) {
          problem = null;
          break;
        }
        problem ??= found;
      }
      if (problem != null) {
        return problem;
      }
    }
    return null;
  }

  /// Why the agent's objects among [objects] break the agent rule, for a
  /// push a person makes (a stack they publish).
  ///
  /// A commit whose author (a tag whose tagger) names one of [agents] by
  /// name or email is the agent's work from a run nobody asked for, and must
  /// be that agent throughout, UTF-8, unsigned and not signed off. Whom it
  /// credits is not compared: the people accountable for that run are not
  /// known here, and the person publishing vouches for what they publish.
  /// Any other object is the person's own: they push it under their own
  /// sign-in, as they would from their own clone, and it is not checked.
  static String? agentObjectViolation(
    List<PushedGitObject> objects,
    List<GitPerson> agents,
  ) {
    bool names(GitPerson agent, String? name, String? email) =>
        (name != null && name == agent.name) || _same(email, agent.email);
    for (final object in objects) {
      final agent = agents
          .where(
            (a) => object.kind == 'commit'
                ? names(a, object.authorName, object.authorEmail)
                : names(a, object.committerName, object.committerEmail),
          )
          .firstOrNull;
      if (agent == null) {
        continue;
      }
      final problem = objectViolation(
        object,
        AgentCommitIdentity.automation(agent: agent),
        coAuthors: false,
      );
      if (problem != null) {
        return problem;
      }
    }
    return null;
  }

  /// What to do about a commit that names someone else: never re-create it
  /// under this run's identity, which would take its author's credit.
  static const String _notThisRuns =
      'A run pushes only its own commits: leave this one for its author to '
      'publish, and do not re-create it under another name. If it is '
      'already on the remote, fetch the remote and push again so it is not '
      'sent.';

  /// How a refusal names [object]: its kind and the start of its id.
  static String at(PushedGitObject object) => _at(object);

  static String _at(PushedGitObject object) =>
      '${object.kind} ${object.oid.length > 12 ? object.oid.substring(0, 12) : object.oid}';

  static bool _same(String? a, String b) =>
      a != null && a.trim().toLowerCase() == b.trim().toLowerCase();

  /// Why [object] breaks [identity]'s rule, or null. With [coAuthors] false
  /// its co-author lines are not compared.
  static String? objectViolation(
    PushedGitObject object,
    AgentCommitIdentity identity, {
    bool coAuthors = true,
  }) {
    final at = _at(object);
    final who = '${identity.author.name} <${identity.author.email}>';
    final encoding = object.encoding?.toLowerCase();
    if (encoding != null && encoding != 'utf-8' && encoding != 'utf8') {
      return '$at declares the encoding "${object.encoding}"; commits here '
          'are UTF-8 only.';
    }
    if (object.signedOff) {
      return '$at carries a Signed-off-by trailer; an agent may not sign off '
          'on a human\'s behalf.';
    }
    if (!_same(object.committerEmail, identity.author.email) ||
        object.committerName != identity.author.name) {
      return '$at is ${object.kind == 'tag' ? 'tagged' : 'committed'} by '
          '${object.committerName} <${object.committerEmail}>; this run '
          'commits as $who. $_notThisRuns';
    }
    if (object.kind != 'commit') {
      return object.signed
          ? '$at is signed; tags here are never signed.'
          : null;
    }
    if (!_same(object.authorEmail, identity.author.email) ||
        object.authorName != identity.author.name) {
      return '$at is authored by ${object.authorName} '
          '<${object.authorEmail}>; this run authors as $who. $_notThisRuns';
    }
    final key = identity.signingKey;
    if (key == null) {
      if (object.signed) {
        return '$at is signed; this run\'s commits are not signed. Commit '
            'with the signing configuration this run was given.';
      }
    } else if (!object.signed) {
      return '$at is not signed; this run signs its commits. Re-create it '
          'with the signing configuration this run was given.';
    } else if (object.signedBy != key) {
      return '$at is not signed with the key of the person who asked for '
          'this run. Re-create it with the signing configuration this run '
          'was given.';
    }
    if (!coAuthors) {
      return null;
    }
    final required = identity.coAuthorTrailers;
    final wanted = {for (final line in required) _normalizedCoAuthor(line)};
    final other = object.coAuthors.firstWhere(
      (line) => !wanted.contains(_normalizedCoAuthor(line)),
      orElse: () => '',
    );
    if (other.isNotEmpty) {
      return '$at credits "$other"; '
          '${required.isEmpty ? 'this run credits no co-author' : 'the only co-author lines this run may carry are "${required.join('", "')}"'}.';
    }
    final credited = {
      for (final line in object.creditedCoAuthors) _normalizedCoAuthor(line),
    };
    // Every line that reads like a co-author line must be a trailer git
    // reads, and every required one must be among them.
    if (object.coAuthors.length != object.creditedCoAuthors.length ||
        !wanted.every(credited.contains)) {
      return '$at does not carry this run\'s co-author credit where git '
          'reads it: end its message with a blank line followed by exactly '
          '"${required.join('", "')}", one per line, each starting its line, '
          'with nothing but other "Key: value" trailer lines beside them.';
    }
    return null;
  }

  static Future<ProcessResult> _git(
    List<String> args, {
    String? workingDirectory,
  }) => IsolatedGit.run(args, workingDirectory: workingDirectory);
}
