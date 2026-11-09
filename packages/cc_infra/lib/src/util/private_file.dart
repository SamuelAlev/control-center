import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';

// Server-side twin of apps/cc_connect/lib/src/private_file.dart. cc_connect is
// a standalone service that depends only on the pure-Dart cc_connect_core
// (no dart:io/FFI allowed there) and must not pull in cc_infra, so the ~60
// lines are duplicated rather than shared. Keep the two in step.

/// Writes [bytes] to [path] so no other account can ever read them, and so a
/// reader never sees a half-written file.
///
/// The bytes go to a fresh temporary file beside [path] that is created
/// owner-only: `creat(2)` with mode `0600` (the umask can only remove bits),
/// so there is no instant at which it exists with a wider mode, and no
/// `chmod` runs after the fact. It is then renamed over [path]. On Windows a
/// new file takes the directory's ACL; there is no mode to set.
///
/// With [overwrite] false an existing [path] is refused
/// ([FileSystemException]) instead of replaced.
Future<void> writePrivateFile(
  String path,
  List<int> bytes, {
  bool overwrite = true,
}) async {
  final target = File(path);
  if (!overwrite && target.existsSync()) {
    throw FileSystemException('refusing to overwrite', path);
  }
  final suffix = List<String>.generate(
    16,
    (_) => _random.nextInt(16).toRadixString(16),
  ).join();
  final staged = File('$path.tmp-$suffix');
  try {
    if (!Platform.isWindows) {
      _createOwnerOnly(staged.path);
    }
    await staged.writeAsBytes(bytes, flush: true);
    if (!overwrite && target.existsSync()) {
      throw FileSystemException('refusing to overwrite', path);
    }
    await staged.rename(path);
  } on Object {
    try {
      if (staged.existsSync()) {
        staged.deleteSync();
      }
    } on Object {
      // Nothing secret is lost by leaving an owner-only temporary file.
    }
    rethrow;
  }
}

final Random _random = Random.secure();

/// `creat(path, 0600)` then `close`: an empty owner-only file.
void _createOwnerOnly(String path) {
  final libc = DynamicLibrary.process();
  final creat = libc
      .lookupFunction<
        Int32 Function(Pointer<Uint8>, Uint32),
        int Function(Pointer<Uint8>, int)
      >('creat');
  final close = libc.lookupFunction<Int32 Function(Int32), int Function(int)>(
    'close',
  );
  final malloc = libc
      .lookupFunction<
        Pointer<Uint8> Function(IntPtr),
        Pointer<Uint8> Function(int)
      >('malloc');
  final free = libc
      .lookupFunction<
        Void Function(Pointer<Uint8>),
        void Function(Pointer<Uint8>)
      >('free');
  // dart:io names files by their UTF-8 bytes on POSIX.
  final encoded = [...utf8.encode(path), 0];
  final native = malloc(encoded.length);
  if (native == nullptr) {
    throw FileSystemException('out of memory', path);
  }
  try {
    native.asTypedList(encoded.length).setAll(0, encoded);
    final fd = creat(native, 384); // 0600
    if (fd < 0) {
      throw FileSystemException('could not create an owner-only file', path);
    }
    close(fd);
  } finally {
    free(native);
  }
}
