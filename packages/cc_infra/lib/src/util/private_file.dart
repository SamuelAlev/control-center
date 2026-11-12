import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';

// Server-side twin of apps/cc_connect/lib/src/private_file.dart and of
// packages/cc_harness_runtime/lib/src/private_file.dart. cc_connect is a
// standalone service that depends only on the pure-Dart cc_connect_core (no
// dart:io/FFI allowed there) and must not pull in cc_infra, and
// cc_harness_runtime is Control-Center-free, so the owner-only create is
// duplicated rather than shared. Keep the three in step.

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

/// The group and other permission bits (`0077`).
const int _groupOrOtherBits = 0x3f;

/// Makes [path] a directory that only its owner can enter.
///
/// A missing directory is created `0700` by `mkdir(2)` itself (its missing
/// parents are created normally), so it never exists with a wider mode. An
/// existing one that grants any group or other bit is tightened to `0700`.
/// If it is still not owner-only afterwards (another account owns it, or the
/// filesystem refused the `chmod`), [PrivateDirectoryException] is thrown so
/// the caller can refuse to keep secrets in it rather than carry on with a
/// directory anyone on the host may list or read.
///
/// POSIX only. On Windows the directory is only created: a new directory
/// takes its parent's ACL and there are no mode bits to inspect, so secrecy
/// there rests on the ACL of the directory above it.
void ensurePrivateDirectory(String path) {
  final dir = Directory(path);
  if (Platform.isWindows) {
    dir.createSync(recursive: true);
    return;
  }
  if (!dir.existsSync()) {
    dir.parent.createSync(recursive: true);
    // A concurrent creator wins the race harmlessly: the mode check below
    // judges whatever ended up there.
    _mkdirOwnerOnly(path);
  }
  if (!isOwnerOnly(path)) {
    try {
      _chmod(path, 448); // 0700
    } on FileSystemException {
      // Judged below: a refused chmod leaves the mode wide.
    }
  }
  if (!isOwnerOnly(path)) {
    throw PrivateDirectoryException(path, FileStat.statSync(path).mode);
  }
}

/// Tightens an existing [path] to owner-only (`0700` for a directory, `0600`
/// for a file) when it grants any group or other bit.
///
/// Returns false when there is nothing to tighten: [path] is absent, already
/// owner-only, or a symbolic link (whose target may live outside the
/// directory being secured, so it is left alone). Throws
/// [FileSystemException] when the `chmod` fails. No-op on Windows, where the
/// directory ACL governs.
bool tightenToOwnerOnly(String path) {
  if (Platform.isWindows) {
    return false;
  }
  final type = FileSystemEntity.typeSync(path, followLinks: false);
  if (type == FileSystemEntityType.notFound ||
      type == FileSystemEntityType.link ||
      isOwnerOnly(path)) {
    return false;
  }
  _chmod(path, type == FileSystemEntityType.directory ? 448 : 384);
  return true;
}

/// Whether [path] grants no permission bit to its group or to others.
///
/// Always true on Windows, which has no mode bits (see
/// [ensurePrivateDirectory]).
bool isOwnerOnly(String path) =>
    Platform.isWindows ||
    (FileStat.statSync(path).mode & _groupOrOtherBits) == 0;

/// A directory that should hold secrets could not be made owner-only.
class PrivateDirectoryException implements Exception {
  /// Creates the exception for [path], whose mode is [mode] after the attempt.
  const PrivateDirectoryException(this.path, this.mode);

  /// The directory that is not owner-only.
  final String path;

  /// Its permission bits after the attempt to tighten them.
  final int mode;

  /// The mode as the octal string `ls -l` users know (e.g. `755`).
  String get octalMode => (mode & 0x1ff).toRadixString(8);

  @override
  String toString() =>
      'PrivateDirectoryException: $path is mode $octalMode and could not be '
      'restricted to its owner (0700)';
}

/// `creat(path, 0600)` then `close`: an empty owner-only file.
void _createOwnerOnly(String path) {
  final close = _libc.lookupFunction<Int32 Function(Int32), int Function(int)>(
    'close',
  );
  final creat = _libc
      .lookupFunction<
        Int32 Function(Pointer<Uint8>, Uint32),
        int Function(Pointer<Uint8>, int)
      >('creat');
  final fd = _withNativePath(path, (native) => creat(native, 384)); // 0600
  if (fd < 0) {
    throw FileSystemException('could not create an owner-only file', path);
  }
  close(fd);
}

/// `mkdir(path, 0700)`: the directory never exists with a wider mode. An
/// existing [path] (a racing creator) is not an error here.
void _mkdirOwnerOnly(String path) {
  final mkdir = _libc
      .lookupFunction<
        Int32 Function(Pointer<Uint8>, Uint32),
        int Function(Pointer<Uint8>, int)
      >('mkdir');
  final result = _withNativePath(path, (native) => mkdir(native, 448));
  if (result != 0 && !Directory(path).existsSync()) {
    throw FileSystemException('could not create an owner-only directory', path);
  }
}

/// `chmod(path, mode)`; throws [FileSystemException] when it fails.
void _chmod(String path, int mode) {
  final chmod = _libc
      .lookupFunction<
        Int32 Function(Pointer<Uint8>, Uint32),
        int Function(Pointer<Uint8>, int)
      >('chmod');
  if (_withNativePath(path, (native) => chmod(native, mode)) != 0) {
    throw FileSystemException('could not restrict the mode', path);
  }
}

final DynamicLibrary _libc = DynamicLibrary.process();

/// Runs [call] with [path] as a NUL-terminated C string.
int _withNativePath(String path, int Function(Pointer<Uint8> native) call) {
  final malloc = _libc
      .lookupFunction<
        Pointer<Uint8> Function(IntPtr),
        Pointer<Uint8> Function(int)
      >('malloc');
  final free = _libc
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
    return call(native);
  } finally {
    free(native);
  }
}
