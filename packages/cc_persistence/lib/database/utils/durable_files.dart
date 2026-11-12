import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

/// Flushes [path]'s contents to the disk (`fsync`).
void syncFile(String path) {
  final file = File(path).openSync(mode: FileMode.append);
  try {
    file.flushSync();
  } finally {
    file.closeSync();
  }
}

/// Flushes [path]'s directory entries to the disk, so a file created or
/// renamed into it survives a power loss.
///
/// `dart:io` cannot open a directory, so this calls `open`/`fsync` from the
/// C library. Windows has no directory sync: NTFS journals the rename.
void syncDirectory(String path) {
  if (Platform.isWindows) {
    return;
  }
  final open = _libc
      .lookupFunction<
        Int32 Function(Pointer<Uint8>, Int32),
        int Function(Pointer<Uint8>, int)
      >('open');
  final fsync = _libc.lookupFunction<Int32 Function(Int32), int Function(int)>(
    'fsync',
  );
  final close = _libc.lookupFunction<Int32 Function(Int32), int Function(int)>(
    'close',
  );
  // O_RDONLY is 0 on every POSIX system this server builds for.
  final fd = _withNativePath(path, (native) => open(native, 0));
  if (fd < 0) {
    throw FileSystemException('could not open the directory to sync it', path);
  }
  try {
    if (fsync(fd) != 0) {
      throw FileSystemException('could not sync the directory', path);
    }
  } finally {
    close(fd);
  }
}

/// Writes [contents] to [path] so that a reader sees either the old file or
/// the whole new one: a sibling temp file, flushed, renamed over [path], and
/// the directory synced.
Future<void> writeFileAtomically(String path, String contents) async {
  final staged = File('$path.writing');
  await staged.writeAsString(contents, flush: true);
  await staged.rename(path);
  syncDirectory(File(path).parent.path);
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
