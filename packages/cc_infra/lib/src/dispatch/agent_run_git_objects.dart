part of 'agent_run_gateway.dart';

/// A commit or tag object the gateway is willing to sign, parsed strictly.
///
/// Git hands its signer the object exactly as it will be stored, minus the
/// signature. Anything else (a push certificate, an already signed object,
/// bytes that merely start like a commit) is not something the user's key
/// signs on an agent's behalf.
class SignableGitObject {
  const SignableGitObject._(this.kind, this.signerEmail);

  /// `commit` or `tag`.
  final String kind;

  /// The committer's (commit) or tagger's (tag) email.
  final String signerEmail;

  static final RegExp _oid = RegExp(r'^(?:[0-9a-f]{40}|[0-9a-f]{64})$');

  // `Name <email> <seconds> <+hhmm>`, as git writes an ident line.
  static final RegExp _ident = RegExp(r'^[^<>\n]* <([^<>\n]+)> \d+ [+-]\d{4}$');

  static const Set<String> _tagTypes = {'commit', 'tree', 'blob', 'tag'};

  /// Parses [bytes], or returns null when they are not a signable object.
  static SignableGitObject? parse(List<int> bytes) {
    var split = -1;
    for (var i = 0; i + 1 < bytes.length; i++) {
      if (bytes[i] == 0x0a && bytes[i + 1] == 0x0a) {
        split = i;
        break;
      }
    }
    if (split <= 0 || bytes.contains(0)) {
      return null;
    }
    final String headerBlock;
    try {
      // Headers are UTF-8; an `encoding` header re-encodes only the message.
      headerBlock = utf8.decode(bytes.sublist(0, split));
    } on FormatException {
      return null;
    }
    // Continuation lines (a leading space) belong to the header above them;
    // only `mergetag` legitimately has them in an object being signed.
    final headers = <(String, String)>[];
    for (final line in headerBlock.split('\n')) {
      if (line.startsWith(' ')) {
        if (headers.isEmpty || headers.last.$1 != 'mergetag') {
          return null;
        }
        continue;
      }
      final space = line.indexOf(' ');
      if (space <= 0) {
        return null;
      }
      headers.add((line.substring(0, space), line.substring(space + 1)));
    }
    return switch (headers.first.$1) {
      'tree' => _commit(headers),
      'object' => _tag(headers),
      _ => null,
    };
  }

  // tree, parent*, author, committer, then only encoding/mergetag. A
  // `gpgsig` header means it is already signed: git strips signatures before
  // signing, so that is not an object git asked to sign.
  static SignableGitObject? _commit(List<(String, String)> headers) {
    var i = 0;
    if (!_oid.hasMatch(headers[i++].$2)) {
      return null;
    }
    while (i < headers.length && headers[i].$1 == 'parent') {
      if (!_oid.hasMatch(headers[i++].$2)) {
        return null;
      }
    }
    if (i + 1 >= headers.length ||
        headers[i].$1 != 'author' ||
        headers[i + 1].$1 != 'committer' ||
        !_ident.hasMatch(headers[i].$2)) {
      return null;
    }
    final committer = _ident.firstMatch(headers[i + 1].$2);
    if (committer == null) {
      return null;
    }
    for (final (name, _) in headers.skip(i + 2)) {
      if (name != 'encoding' && name != 'mergetag') {
        return null;
      }
    }
    return SignableGitObject._('commit', committer.group(1)!);
  }

  // object, type, tag, tagger: exactly what `git tag -s` writes.
  static SignableGitObject? _tag(List<(String, String)> headers) {
    if (headers.length != 4 ||
        !_oid.hasMatch(headers[0].$2) ||
        headers[1].$1 != 'type' ||
        !_tagTypes.contains(headers[1].$2) ||
        headers[2].$1 != 'tag' ||
        headers[2].$2.isEmpty ||
        headers[3].$1 != 'tagger') {
      return null;
    }
    final tagger = _ident.firstMatch(headers[3].$2);
    return tagger == null ? null : SignableGitObject._('tag', tagger.group(1)!);
  }
}

/// An operator's approval of a pushing shell command, for [AgentRunGateway]'s
/// push proxy to honor rather than ask again.
class _ShellPushApproval {
  const _ShellPushApproval({required this.refs, required this.until});

  /// The branches the approved command named, or null when it did not.
  final List<String>? refs;

  /// When the approval stops answering the gateway's ask.
  final DateTime until;
}

/// The ref updates at the front of a `git-receive-pack` request.
class _PushCommands {
  const _PushCommands(this.refs, this.capabilities, this.end);

  /// Full ref names being updated (`refs/heads/main`).
  final List<String> refs;

  /// Capabilities the client sent on its first command.
  final Set<String> capabilities;

  /// Offset just past the flush that ends the commands: what follows (push
  /// options, then the pack) may already sit in the bytes that were parsed.
  final int end;

  /// Parses pkt-lines up to the first flush. Null while incomplete.
  static _PushCommands? parse(Uint8List bytes) {
    final refs = <String>[];
    final caps = <String>{};
    var offset = 0;
    while (offset + 4 <= bytes.length) {
      final length = int.tryParse(
        ascii.decode(bytes.sublist(offset, offset + 4), allowInvalid: true),
        radix: 16,
      );
      if (length == null || (length > 0 && length < 4)) {
        throw const FormatException('Invalid push packet length.');
      }
      if (length == 0) {
        return _PushCommands(refs, caps, offset + 4);
      }
      if (offset + length > bytes.length) {
        return null;
      }
      var line = utf8.decode(
        bytes.sublist(offset + 4, offset + length),
        allowMalformed: true,
      );
      offset += length;
      final nul = line.indexOf('\u0000');
      if (nul >= 0) {
        caps.addAll(line.substring(nul + 1).trim().split(' '));
        line = line.substring(0, nul);
      }
      // `<old-oid> <new-oid> <ref>`; a signed push's certificate lines and
      // shallow lines carry no ref update.
      final parts = line.trim().split(' ');
      if (parts.length == 3 && parts[2].startsWith('refs/')) {
        refs.add(parts[2]);
      }
    }
    return null;
  }
}
