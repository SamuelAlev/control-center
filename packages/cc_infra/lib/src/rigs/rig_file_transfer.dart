import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/features/rigs/domain/value_objects/rig_clipboard.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_file_transfer.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/rigs/worktree_sync.dart';

/// A file could not be moved in or out of a guest, and the message says why in
/// terms the person who dragged it can act on.
class RigFileTransferException implements Exception {
  /// Creates a [RigFileTransferException].
  const RigFileTransferException(this.message);

  /// What went wrong.
  final String message;

  @override
  String toString() => 'RigFileTransferException: $message';
}

/// Moves files between the host and a rig's guest, over whatever channel that
/// rig already has.
///
/// **Why this rides [WorktreeTransport] and not the guest agent.** Three
/// reasons, and the third is the one that decided it:
///
///  1. Every surface has a transport (SSH into a QEMU rig, `machine exec` into
///     a microVM) — but only the DESKTOP has a guest agent. A terminal rig has
///     no agent and no driver, and dropping a file into a shell is exactly the
///     same operation as dropping one onto a desktop.
///  2. The transport is a stream, so a 200 MB file is piped rather than
///     base64'd into a JSON body the server holds whole.
///  3. It needs no new guest endpoint, so it works on images that were built
///     before this feature existed. The clipboard could not avoid a new
///     endpoint; this could, and one forced image rebuild is enough.
///
/// Everything here is bounded: a guest that never closes its stdout, a `cat`
/// that streams forever, a path that resolves to `/dev/zero`. The host holds
/// these bytes in its own heap, so "the guest decides how many" is not an
/// option.
class RigFileTransfer {
  /// Creates a [RigFileTransfer] over [transport], landing dropped files in
  /// [dropDirectory] inside the guest.
  const RigFileTransfer({
    required WorktreeTransport transport,
    required String dropDirectory,
  }) : _transport = transport,
       _dropDirectory = dropDirectory;

  final WorktreeTransport _transport;
  final String _dropDirectory;

  /// Where dropped files land inside the guest.
  String get dropDirectory => _dropDirectory;

  /// How long one file's transfer may take before the guest is considered
  /// wedged. Generous, because the ceiling is a 256 MB file over a virtio
  /// channel — but finite, because a hung `cat` otherwise holds a process and
  /// a pending request forever.
  static const Duration _perFileTimeout = Duration(minutes: 5);

  /// How long a small metadata command (a `stat`) may take.
  static const Duration _probeTimeout = Duration(seconds: 20);

  /// Writes [files] into the guest's drop directory and returns them as they
  /// now exist there.
  ///
  /// Names collide constantly in practice (two screenshots, the same
  /// `report.pdf` twice), so the guest picks a free name rather than
  /// overwriting: dropping a file must never destroy one that is already
  /// there, and a silent overwrite is the kind of data loss nobody attributes
  /// to a drag.
  Future<List<RigGuestFile>> put(List<RigFilePayload> files) async {
    final landed = <RigGuestFile>[];
    for (final file in files) {
      landed.add(await _putOne(file));
    }
    return landed;
  }

  Future<RigGuestFile> _putOne(RigFilePayload file) async {
    final name = file.sanitizedName;
    // The whole write is one shell script so the naming and the copy cannot
    // disagree: the guest chooses a free path, writes to THAT path, and
    // prints it back. A host that picked the name first would race every
    // other drop into the same directory.
    //
    // The claim is made with noclobber inside a subshell, which is the only
    // way to say "create this, atomically, only if it does not exist" in
    // POSIX sh. `[ -e ]` then `>` is a check-then-act with a window in it,
    // and losing that race means overwriting a file the user still wanted —
    // data loss nobody would ever attribute to a drag. The bound on the
    // counter is for the OTHER reason a create fails: an unwritable
    // directory, where an unbounded loop would spin forever holding a
    // process open inside the guest.
    //
    // `umask 077` first, `chmod 0644` after: the file exists and is
    // incomplete for as long as the copy takes, and it should not be
    // world-readable in that window.
    const script =
        'set -e; '
        'umask 077; '
        r'mkdir -p "$0"; '
        r'p="$0/$1"; i=1; '
        r'until (set -C; : > "$p") 2>/dev/null; do '
        r'  i=$((i+1)); '
        r'  if [ "$i" -gt 200 ]; then '
        r'    echo "cannot create a file in $0" >&2; exit 1; '
        r'  fi; '
        r'  p="$0/$i-$1"; '
        'done; '
        r'cat > "$p"; chmod 0644 "$p"; printf %s "$p"';

    final process = await _transport.start(
      // The directory and the name are POSITIONAL, never interpolated into
      // the script: they then need one round of quoting instead of two, and
      // nothing inside them can be read as shell syntax at all.
      'sh -c ${shellQuoteForGuest(script)} '
      '${shellQuoteForGuest(_dropDirectory)} ${shellQuoteForGuest(name)}',
    );

    final stdoutFuture = process.stdout
        .transform(utf8.decoder)
        .join()
        .timeout(_perFileTimeout);
    final stderrFuture = process.stderr
        .transform(utf8.decoder)
        .join()
        .timeout(_perFileTimeout, onTimeout: () => '');

    try {
      process.stdin.add(file.bytes);
      await process.stdin.flush();
      await process.stdin.close();
    } on Object catch (e) {
      // A guest that died mid-write closes the pipe; writing into it throws a
      // SocketException that is not the interesting half of the story.
      CcInfraLog.warning('rig/files: stdin closed early for $name: $e');
    }

    final int exitCode;
    try {
      exitCode = await process.exitCode.timeout(_perFileTimeout);
    } on TimeoutException {
      process.kill(ProcessSignal.sigkill);
      throw RigFileTransferException(
        'Copying "$name" into the machine timed out after '
        '${_perFileTimeout.inMinutes} minutes.',
      );
    }

    final out = (await stdoutFuture).trim();
    final err = (await stderrFuture).trim();
    if (exitCode != 0 || out.isEmpty || !out.startsWith('/')) {
      throw RigFileTransferException(
        'Could not copy "$name" into the machine'
        '${err.isEmpty ? '' : ': ${_firstLine(err)}'}.',
      );
    }
    return RigGuestFile(
      name: basenameOfGuestPath(out),
      guestPath: out,
      sizeBytes: file.sizeBytes,
      mediaType: file.mediaType,
    );
  }

  /// Reads the file at [guestPath] out of the guest, or null when it is not a
  /// readable regular file.
  ///
  /// Null covers the whole "you cannot have this" family — missing, a
  /// directory, a device, unreadable — on purpose: the caller is a drag that
  /// either produces a file or does not, and four different errors would all
  /// be rendered the same way anyway.
  Future<RigFileBytes?> get(String guestPath) async {
    final rejection = rejectGuestPath(guestPath);
    if (rejection != null) {
      CcInfraLog.warning(
        'rig/files: refusing to read "$guestPath": $rejection',
      );
      return null;
    }
    final quoted = shellQuoteForGuest(guestPath);

    // Probe first, and probe for the TYPE as well as the size. Streaming
    // straight into a buffer would happily read /dev/zero until the cap, and
    // report a 256 MB file to the person who dragged it.
    final WorktreeCommandResult probe;
    try {
      probe = await _transport
          // `%s %F` — size then the human type word ("regular file",
          // "directory", "character special file").
          .capture('stat -c "%s %F" -- $quoted')
          .timeout(_probeTimeout);
    } on Object catch (e) {
      CcInfraLog.warning('rig/files: stat failed for "$guestPath": $e');
      return null;
    }
    if (probe.exitCode != 0) {
      return null;
    }
    final parts = probe.stdout.trim().split(' ');
    final size = parts.isEmpty ? null : int.tryParse(parts.first);
    final kind = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    if (size == null || !kind.startsWith('regular')) {
      return null;
    }
    if (size > RigFilePayload.maxFileBytes) {
      throw RigFileTransferException(
        '"${basenameOfGuestPath(guestPath)}" is '
        '${(size / (1024 * 1024)).toStringAsFixed(0)} MB, over the '
        '${RigFilePayload.maxFileBytes ~/ (1024 * 1024)} MB limit for a '
        'transfer out of a machine.',
      );
    }

    final process = await _transport.start('cat -- $quoted');
    final builder = BytesBuilder(copy: false);
    var overflowed = false;
    try {
      await process.stdout
          .forEach((chunk) {
            if (overflowed) {
              return;
            }
            builder.add(chunk);
            if (builder.length > RigFilePayload.maxFileBytes) {
              // The stat said one thing and the stream is saying another
              // (a file that grew, or one that was never a plain file).
              // Stop accumulating rather than trusting the earlier answer.
              overflowed = true;
              process.kill(ProcessSignal.sigkill);
            }
          })
          .timeout(_perFileTimeout);
    } on TimeoutException {
      process.kill(ProcessSignal.sigkill);
      throw RigFileTransferException(
        'Reading "${basenameOfGuestPath(guestPath)}" out of the machine timed '
        'out.',
      );
    }
    // Drained so the process can exit; the content is not interesting here.
    unawaited(process.stderr.drain<void>().catchError((_) {}));
    final exitCode = await process.exitCode.timeout(
      _probeTimeout,
      onTimeout: () => -1,
    );
    if (overflowed || exitCode != 0) {
      return null;
    }
    return RigFileBytes(
      name: basenameOfGuestPath(guestPath),
      bytes: builder.takeBytes(),
      mediaType: guessMediaType(guestPath),
    );
  }

  static String _firstLine(String text) {
    final line = text.split('\n').first.trim();
    return line.length > 200 ? '${line.substring(0, 200)}…' : line;
  }
}

/// Why [guestPath] may not be read out of a guest, or null when it may.
///
/// The path round-tripped through a client, so it is untrusted even though it
/// was produced by a listing this server generated. The checks are about what
/// can be expressed on a shell command line, not about which directories are
/// private: the caller can already open a terminal in this machine, so
/// restricting them to a subtree would be theatre. Refusing a path that could
/// end a command line is not.
String? rejectGuestPath(String guestPath) {
  if (guestPath.isEmpty) {
    return 'the path is empty';
  }
  if (!guestPath.startsWith('/')) {
    return 'the path is not absolute';
  }
  if (guestPath.length > 4096) {
    return 'the path is longer than PATH_MAX';
  }
  for (final rune in guestPath.runes) {
    // C0 controls, DEL, and NUL. A newline inside a path would end the shell
    // line it is interpolated into; the quoting already handles it, and this
    // refuses it anyway, because a real path has none of them.
    if (rune < 0x20 || rune == 0x7F) {
      return 'the path contains a control character';
    }
  }
  return null;
}

/// Where a host-side drop lands inside a guest, per surface.
///
/// Chosen by the SERVER, never by the caller: a host that could name the
/// destination could write `~/.ssh/authorized_keys` or a systemd unit into a
/// machine an agent then drives.
///
/// One directory per surface, and each one is somewhere that surface can
/// actually see:
///
///  * The desktop uses `~/Drops` under the `cc` user's home, so the file
///    manager already lists it. Deliberately NOT the worktree — a dropped
///    file must never turn up as an untracked change in somebody's repo.
///  * A terminal rig gets `~/drops` beside its worktree, for the same reason
///    and with the lowercase name shells are used to.
///  * The browser image is `chromedp/headless-shell`, which has no home
///    directory worth speaking of and runs as root; `/tmp` is the one place
///    that is guaranteed writable and reachable by the browser process.
String rigDropDirectory({required RigSurface surface, required bool exec}) {
  if (exec) {
    return '/home/cc/drops';
  }
  return switch (surface) {
    RigSurface.computer => '/home/cc/Drops',
    RigSurface.browser => '/tmp/cc-drops',
    // Never reached: the mobile driver refuses drops outright, because an
    // Android device has no drop target a host can address. Named anyway so
    // the switch is exhaustive rather than defaulting into a wrong path.
    RigSurface.mobile => '/sdcard/Download',
  };
}

/// The directory part of a POSIX guest path, or `/` when it has none.
///
/// POSIX regardless of what the HOST runs: guests are Linux on every surface,
/// so using the host's separator would produce nonsense on Windows.
String guestDirectoryOf(String path) {
  final slash = path.lastIndexOf('/');
  if (slash <= 0) {
    return '/';
  }
  return path.substring(0, slash);
}

/// A MIME type guessed from [path]'s extension, or null.
///
/// Extension-based on purpose: the alternative is reading the file's first
/// bytes, which means a second trip into the guest to answer a question no
/// caller has ever needed exactly right. Wrong here costs a generic icon.
String? guessMediaType(String path) {
  final name = basenameOfGuestPath(path).toLowerCase();
  final dot = name.lastIndexOf('.');
  if (dot < 0 || dot == name.length - 1) {
    return null;
  }
  return switch (name.substring(dot)) {
    '.png' => 'image/png',
    '.jpg' || '.jpeg' => 'image/jpeg',
    '.gif' => 'image/gif',
    '.webp' => 'image/webp',
    '.svg' => 'image/svg+xml',
    '.pdf' => 'application/pdf',
    '.json' => 'application/json',
    '.txt' || '.log' || '.md' => 'text/plain',
    '.csv' => 'text/csv',
    '.html' || '.htm' => 'text/html',
    '.zip' => 'application/zip',
    '.gz' || '.tgz' => 'application/gzip',
    '.tar' => 'application/x-tar',
    '.mp4' => 'video/mp4',
    '.mp3' => 'audio/mpeg',
    '.wav' => 'audio/wav',
    _ => null,
  };
}
