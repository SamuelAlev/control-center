// Turning what a human attached into something an agent can open.
//
// **Why this exists.** An attachment crosses the wire as a
// `blob:sha256:<hex>` reference: the composer uploads the bytes and the message
// row keeps a 71-character pointer. That is right for storage and right for the
// transcript, and it is useless to an agent — no adapter has ever heard of a
// blob reference, and the sender's own path means nothing on a server that is
// routinely a different machine. So a message that said "look at
// ⟦shot.png⟧" reached the model as those words and nothing else, and the honest
// answer came back: the screenshots are referenced but I need to locate them.
//
// The fix is to give the reference a body. Every uploaded attachment is written
// once into the SPACE's own `attachments/` directory and each `@[file:<name>]`
// token in the dispatched prompt is replaced, in place, by that file's absolute
// path. In place matters: the position is the meaning — "compare ⟦before.png⟧
// with ⟦after.png⟧" collapses into nonsense if the paths are appended as a list.
//
// **Why the space directory.** It is the one place every agent in the
// conversation can read, it is deleted with the space, and it sits beside
// `repos` — which the dispatch session already mounts, so adding this one is
// the same shape rather than a new kind of hole. Agents get it READ-ONLY: these
// are the human's inputs, not the agent's scratch.
//
// **Why content-addressed filenames.** The display name is unique within one
// message and nowhere else; two conversations attaching `shot.png` a week apart
// would otherwise fight over one path. Prefixing the content hash makes the
// write idempotent — re-sending the same picture reuses the same file — and
// makes a stale name impossible.
//
// **One exception, and it matters.** A non-picture whose sender path this host
// CAN see resolves to that path instead of to a copy. The commonest reference
// of all is a source file picked out of the composer's `@` menu on the machine
// the server runs on, and pointing an agent at a snapshot of the file it was
// asked to change is a bug that would look like the agent ignoring its edits.
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
  /// the directory [spaceDir] resolves for a workspace/space pair.
  SpacePromptAttachments({
    required BlobStore blobStore,
    required Future<String> Function(String workspaceId, String spaceId)
    spaceDir,
  }) : _blobs = blobStore,
       _spaceDir = spaceDir;

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
