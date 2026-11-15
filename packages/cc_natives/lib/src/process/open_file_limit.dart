import 'dart:ffi';
import 'dart:io';
import 'dart:math' as math;

import 'package:ffi/ffi.dart';

/// `struct rlimit`: two `rlim_t` (64-bit on every platform this runs on).
final class _RLimit extends Struct {
  @Uint64()
  external int current;

  @Uint64()
  external int maximum;
}

typedef _RLimitNative = Int32 Function(Int32 resource, Pointer<_RLimit> limit);
typedef _RLimitDart = int Function(int resource, Pointer<_RLimit> limit);

/// The process's soft limit on open files after [raiseOpenFileLimit], or
/// null where it was not read (Windows, or libc refused).
typedef OpenFileLimit = ({int before, int after});

/// Raises this process's soft limit on open file descriptors to its hard
/// limit, as far as the kernel allows one process.
///
/// macOS starts a process launched from Finder or a terminal at a soft limit
/// of 256. A server that keeps SQLite files, sockets, file watchers and a
/// dozen git children (three pipes each) open reaches that during ordinary
/// polling and then fails with "Too many open files". The hard limit is
/// what the operator allows; the soft one is only a default, which any
/// process may raise up to it. Children inherit the raised limit.
///
/// macOS refuses a soft limit above `OPEN_MAX` (10240) through this call,
/// whatever the hard limit says. Returns the limit before and after, or null
/// on Windows (no such limit) or when libc refuses to read it. Never throws.
OpenFileLimit? raiseOpenFileLimit() {
  if (!(Platform.isMacOS || Platform.isLinux)) {
    return null;
  }
  try {
    final libc = DynamicLibrary.process();
    final getrlimit = libc.lookupFunction<_RLimitNative, _RLimitDart>(
      'getrlimit',
    );
    final setrlimit = libc.lookupFunction<_RLimitNative, _RLimitDart>(
      'setrlimit',
    );
    // RLIMIT_NOFILE: 8 on Darwin, 7 on Linux.
    final resource = Platform.isMacOS ? 8 : 7;
    return using((arena) {
      final limit = arena<_RLimit>();
      if (getrlimit(resource, limit) != 0) {
        return null;
      }
      final before = limit.ref.current;
      // RLIM_INFINITY is all ones, which reads back as -1 here.
      final hard = limit.ref.maximum < 0
          ? _kernelCeiling
          : math.min(limit.ref.maximum, _kernelCeiling);
      if (before < 0 || before >= hard) {
        return (before: before, after: before);
      }
      limit.ref.current = hard;
      if (setrlimit(resource, limit) != 0) {
        return (before: before, after: before);
      }
      return (before: before, after: hard);
    });
  } on Object {
    return null;
  }
}

/// macOS's `OPEN_MAX`; Linux's default `fs.nr_open`.
int get _kernelCeiling => Platform.isMacOS ? 10240 : 1 << 20;
