part of 'agent_run_gateway.dart';

/// Whether an agent run for `actingUserId` (null: nobody asked for it) may
/// push to the GitHub repository `owner/name` in `workspaceId`. The server's
/// check requires the repository to be linked there and the requester to
/// hold Control Center's write grant on it.
typedef AgentPushRepoCheck =
    Future<bool> Function(
      String workspaceId,
      String owner,
      String name,
      String? actingUserId,
    );

/// Whether GitHub's `owner/name` has `oid` among the commits reachable from
/// `base` (`HEAD`: its default branch; or an object id): true, false, or null
/// when GitHub could not be asked. `token` is the credential the push itself
/// is forwarded with, which reads that repository.
typedef AgentPushAncestryCheck =
    Future<bool?> Function({
      required String owner,
      required String name,
      required String base,
      required String oid,
      required String token,
    });

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
  const _PushCommands(this.refs, this.capabilities, this.end, this.newIds);

  /// Full ref names being updated (`refs/heads/main`).
  final List<String> refs;

  /// The object id each of [refs] is set to (all zeros for a deletion).
  final Map<String, String> newIds;

  /// Capabilities the client sent on its first command.
  final Set<String> capabilities;

  /// Offset just past the flush that ends the commands: what follows (push
  /// options, then the pack) may already sit in the bytes that were parsed.
  final int end;

  /// Parses pkt-lines up to the first flush. Null while incomplete.
  static _PushCommands? parse(Uint8List bytes) {
    final refs = <String>[];
    final newIds = <String, String>{};
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
        return _PushCommands(refs, caps, offset + 4, newIds);
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
        newIds[parts[2]] = parts[1].toLowerCase();
      }
    }
    return null;
  }
}

/// What a push would publish without the proxy having seen it.
///
/// git sends every commit the remote's advertised refs do not reach, and
/// GitHub accepts any object it already stores, including one no ref of this
/// repository reaches (a commit of a fork, an unreferenced object). So a push
/// can publish commits it does not carry in two ways: a ref moved straight
/// onto one, and a carried commit (or tag) that stands on one. A forged
/// commit could reach a branch either way, uninspected.
///
/// Both are held to one rule: an object the push names but does not carry
/// must already be published in this repository. Published means a branch or
/// tag tip GitHub advertises for it or, for what a carried object stands on,
/// a commit on its default branch or below what a ref this push updates
/// points at today ([AgentPushAncestryCheck]). Anything else is refused.
/// Deletions carry nothing and are not checked.
extension _UninspectedObjects on AgentRunGateway {
  /// How many objects below a push are looked up on GitHub before the push
  /// is refused as too tangled to check.
  static const int _maxAncestryLookups = 16;

  /// Why this push would publish an object it does not carry and
  /// `owner/name` has not published, or null.
  ///
  /// [carried] are the commits and tags the pack holds; [builtOn] maps each
  /// object a carried one stands on (a commit's parents, a tag's target) to
  /// the carried object that names it.
  Future<String?> _uninspected(
    _PushCommands commands,
    Set<String> carried,
    Map<String, String> builtOn,
    String owner,
    String name,
    String token,
  ) async {
    final moved = {
      for (final MapEntry(key: ref, value: oid) in commands.newIds.entries)
        if (!_zeroOid.hasMatch(oid) && !carried.contains(oid)) ref: oid,
    };
    final below = {
      for (final MapEntry(key: oid, value: at) in builtOn.entries)
        if (!carried.contains(oid)) oid: at,
    };
    if (moved.isEmpty && below.isEmpty) {
      return null;
    }
    final advertised = await _advertisedRefs(owner, name, token);
    if (advertised == null) {
      return 'Control Center could not read the repository\'s refs to check '
          'this push.';
    }
    final tips = advertised.values.toSet();
    for (final MapEntry(key: ref, value: oid) in moved.entries) {
      if (!tips.contains(oid)) {
        return '${AgentRunGateway._shortRef(ref)} would point at '
            '${_short(oid)}, which this push does not carry and GitHub does '
            'not have as a branch or tag tip, so its commits cannot be '
            'inspected. Push new commits instead (to drop commits, revert '
            'them).';
      }
    }
    below.removeWhere((oid, _) => tips.contains(oid));
    if (below.isEmpty) {
      return null;
    }
    final ancestry = _ancestry;
    // Where a commit this push stands on may already be: the default branch,
    // or the history of a ref the push updates (an amended or rebased
    // branch stands on its own earlier commits).
    final bases = <String>{
      'HEAD',
      for (final ref in commands.refs) ?advertised[ref],
    };
    if (ancestry != null && below.length * bases.length > _maxAncestryLookups) {
      return 'this push stands on too many commits it does not carry for '
          'Control Center to check them. Push one branch at a time.';
    }
    for (final MapEntry(key: oid, value: at) in below.entries) {
      // Without a way to ask, nothing below a push counts as published.
      var published = false;
      if (ancestry != null) {
        for (final base in bases) {
          final answer = await ancestry(
            owner: owner,
            name: name,
            base: base,
            oid: oid,
            token: token,
          );
          if (answer == null) {
            return 'Control Center could not ask GitHub whether '
                '${_short(oid)} is already part of $owner/$name, so this '
                'push cannot be checked. Try again.';
          }
          if (answer) {
            published = true;
            break;
          }
        }
      }
      if (!published) {
        return '$at stands on ${_short(oid)}, which this push does not carry '
            'and $owner/$name has neither on its default branch, nor on the '
            'branch being pushed, nor as a branch or tag tip, so it cannot '
            'be inspected. If it is published on another branch, rebase onto '
            'that branch\'s current tip. A commit that is somebody else\'s '
            'is theirs to publish.';
      }
    }
    return null;
  }

  static final RegExp _zeroOid = RegExp(r'^0+$');
  static final RegExp _oid = RegExp(r'^[0-9a-f]{40,64}$');

  static String _short(String oid) =>
      oid.length > 12 ? oid.substring(0, 12) : oid;

  /// The branches and tags `owner/name` advertises to a push, by full
  /// ref name, or null when GitHub did not answer. Only `refs/heads/` and
  /// `refs/tags/` count: an advertisement also lists what the repository
  /// merely stores for others (`.have` lines for its fork network), which is
  /// exactly what must not pass as published here.
  Future<Map<String, String>?> _advertisedRefs(
    String owner,
    String name,
    String token,
  ) async {
    final client = _httpClient();
    try {
      final out = await client.getUrl(
        _upstream(
          ForgeHost.github,
          owner,
          name,
          'info/refs',
          service: 'git-receive-pack',
        ),
      );
      out.followRedirects = false;
      out.headers.set(
        HttpHeaders.authorizationHeader,
        forgeGitBasicAuthorization(ForgeHost.github, token),
      );
      final response = await out.close();
      final body = (await response.fold<BytesBuilder>(
        BytesBuilder(copy: false),
        (b, chunk) => b..add(chunk),
      )).takeBytes();
      if (response.statusCode != HttpStatus.ok) {
        return null;
      }
      final refs = <String, String>{};
      var offset = 0;
      while (offset + 4 <= body.length) {
        final length = int.tryParse(
          ascii.decode(body.sublist(offset, offset + 4), allowInvalid: true),
          radix: 16,
        );
        if (length == null || (length > 0 && length < 4)) {
          return null;
        }
        if (length == 0) {
          offset += 4;
          continue;
        }
        if (offset + length > body.length) {
          return null;
        }
        final line = utf8.decode(
          body.sublist(offset + 4, offset + length),
          allowMalformed: true,
        );
        offset += length;
        // `<oid> <ref>`, the first line followed by NUL and capabilities.
        final parts = line.split('\u0000').first.trim().split(' ');
        if (parts.length != 2) {
          continue;
        }
        final oid = parts[0].toLowerCase();
        final ref = parts[1];
        if ((ref.startsWith('refs/heads/') || ref.startsWith('refs/tags/')) &&
            _oid.hasMatch(oid) &&
            !_zeroOid.hasMatch(oid)) {
          refs[ref] = oid;
        }
      }
      return refs;
    } on Object {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}
