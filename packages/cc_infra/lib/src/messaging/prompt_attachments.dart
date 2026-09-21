// Resolves message attachments to absolute paths an agent can open.
//
// Wire form is `blob:sha256:<hex>` — useless to adapters and meaningless across
// machines. Each upload is written once under the space's `attachments/` and
// each `@[file:<name>]` token is replaced in place by that absolute path
// (position is meaning; do not append a path list).
// Space dir: shared by agents in the conversation, deleted with the space,
// mounted read-only beside `repos`.
// Filenames are content-addressed so display-name collisions across messages
// cannot clobber and re-sends are idempotent.
// Exception: a non-picture whose sender path exists on this host resolves to
// that path (not a copy) so agents edit the live file, not a stale snapshot.
library;

import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/message_attachment.dart';
import 'package:cc_infra/src/blobs/blob_store.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:path/path.dart' as p;

/// Resolves a message's attachments to absolute paths an agent can open, keyed
/// by the `@[file:<name>]` name the prompt refers to them by.
///
/// A name missing from the result is one that could not be given a body; its
/// token is then left exactly as the person typed it, which is the truthful
/// outcome — better than a path that resolves to nothing.
typedef PromptAttachmentResolver =
    Future<Map<String, String>> Function({
      required String workspaceId,
      required String spaceId,
      required List<MessageAttachment> attachments,
    });

/// Writes a message's uploaded attachments into its space's `attachments/`
/// directory and reports where they landed.
class SpacePromptAttachments {
  /// Creates a [SpacePromptAttachments] over [blobStore], placing files under
  /// the directory [_spaceDir] resolves for a workspace/space pair.
  SpacePromptAttachments({
    required BlobStore blobStore,
    required this._spaceDir,
  }) : _blobs = blobStore;

  final BlobStore _blobs;
  final Future<String> Function(String workspaceId, String spaceId) _spaceDir;

  /// Directory name, under a space, holding what humans attached to its
  /// messages. Read by [SpacePromptAttachments] and mounted read-only into
  /// every dispatch, so the two must agree.
  static const String dirName = 'attachments';

  /// The `attachments/` directory under a space's root directory.
  static String dirFor(String spaceRoot) => p.join(spaceRoot, dirName);

  /// Materializes [attachments] and returns `name → absolute path`.
  ///
  /// Best-effort per attachment, deliberately: one that cannot be written is
  /// omitted and the rest of the message still runs. Losing a picture is bad;
  /// losing the question the person typed alongside it is worse.
  Future<Map<String, String>> resolve({
    required String workspaceId,
    required String spaceId,
    required List<MessageAttachment> attachments,
  }) async {
    if (attachments.isEmpty || workspaceId.isEmpty || spaceId.isEmpty) {
      return const {};
    }
    Directory? dir;
    final out = <String, String>{};
    for (final attachment in attachments) {
      final hash = attachment.blobHash;
      // A FILE the sender named on a filesystem this host shares resolves to
      // the real thing, not to a copy of it. That is the difference between an
      // agent editing `lib/foo.dart` and an agent editing a week-old snapshot
      // of it in a directory nobody reads — and picking a source file out of
      // the composer's `@` menu is one of the commonest ways a reference gets
      // written.
      //
      // A PICTURE never takes this path, deliberately. Nobody edits a
      // screenshot, and the sender's copy is often a temporary file the OS
      // deletes the moment the drag ends (macOS screenshot drags land in
      // `/var/folders/…/TemporaryItems`), so the stable blob is the better
      // answer even on one machine.
      final local = attachment.localPath ?? (hash == null ? attachment.path : '');
      if (!attachment.isImage && local.isNotEmpty && File(local).existsSync()) {
        out[attachment.name] = local;
        continue;
      }
      if (hash == null) {
        // Never uploaded — too large, or the upload failed — and its path is
        // not one this host can see. There is nothing to point at, and a path
        // off another machine is worse than none: the agent reports having
        // looked and found nothing.
        if (local.isNotEmpty && File(local).existsSync()) {
          out[attachment.name] = local;
        }
        continue;
      }
      try {
        dir ??= Directory(dirFor(await _spaceDir(workspaceId, spaceId)));
        final target = File(p.join(dir.path, _fileName(attachment, hash)));
        if (!target.existsSync()) {
          final bytes = await _blobs.read(workspaceId, hash);
          if (bytes == null || bytes.isEmpty) {
            continue;
          }
          await dir.create(recursive: true);
          // Write-then-rename, like the blob store itself: a crash mid-write
          // must not leave a truncated file at a name that claims to be this
          // content.
          final tmp = File('${target.path}.part');
          await tmp.writeAsBytes(bytes, flush: true);
          await tmp.rename(target.path);
        }
        out[attachment.name] = target.path;
      } on Object catch (e) {
        CcInfraLog.warning(
          'Failed to materialize attachment ${attachment.name}: $e',
        );
      }
    }
    return out;
  }

  /// `<hash8>-<safe name>` — collision-free across messages, still readable in
  /// a prompt, and carrying the ORIGINAL extension, which is how every adapter
  /// decides whether a path is a picture.
  static String _fileName(MessageAttachment attachment, String hash) {
    final safe = _sanitize(attachment.name);
    return '${hash.substring(0, 8)}-$safe';
  }

  /// Reduces a display name to something safe to join onto a path.
  ///
  /// The name is user-controlled and has already been through the composer's
  /// ellipsizer, so it can hold `…`, spaces, and — if someone typed the token
  /// by hand — separators and `..`. Only the basename survives, and only
  /// characters that cannot change what a path means.
  static String _sanitize(String name) {
    final base = p.basename(name.replaceAll(r'\', '/'));
    final cleaned = base.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
    // A name that is only dots is `.`/`..` under another spelling.
    final safe = cleaned.replaceAll(RegExp(r'^\.+$'), '');
    if (safe.isEmpty) {
      return 'attachment';
    }
    return safe.length <= 80 ? safe : safe.substring(safe.length - 80);
  }
}
