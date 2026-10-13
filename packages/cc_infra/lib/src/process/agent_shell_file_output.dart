import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/agent_shell_output.dart';
import 'package:ffi/ffi.dart';

/// Gets the descriptor listing for one command pid, never a client path.
typedef AgentShellDescriptors = Future<String> Function(int pid);

final _fdNumber = RegExp(r'^\d+');

/// Reads only regular stdout/stderr files held open by a validated command.
/// Pipes, terminals, sockets and unnamed/deleted descriptors are unavailable.
class AgentShellFileOutput {
  /// Creates a reader, optionally substituting descriptor discovery for tests.
  AgentShellFileOutput({AgentShellDescriptors? descriptors})
    : _descriptors = descriptors ?? _discover,
      _hostDescriptors = descriptors == null;

  final AgentShellDescriptors _descriptors;
  final bool _hostDescriptors;
  final Map<String, List<_NativeFileTail>> _retained = {};

  /// Maximum raw bytes retained from a command's regular output files.
  static const maxBytes = 65536;

  /// Releases verified descriptors when their output identity expires.
  void forget(String outputId) {
    for (final handle
        in _retained.remove(outputId) ?? const <_NativeFileTail>[]) {
      handle.close();
    }
  }

  /// Reads already verified descriptors even after their process exits.
  AgentShellOutput? readRetained(String outputId) =>
      _snapshot(_retained[outputId]);

  AgentShellOutput? _snapshot(List<_NativeFileTail>? handles) {
    if (handles == null || handles.isEmpty) {
      return null;
    }
    final chunks = <String>[];
    var truncated = false;
    for (final handle in handles) {
      final chunk = handle.read(maxBytes ~/ handles.length);
      if (chunk == null) {
        continue;
      }
      chunks.add(chunk.$1);
      truncated |= chunk.$2;
    }
    if (chunks.isEmpty) {
      return null;
    }
    return AgentShellOutput(
      output: chunks.join('\n'),
      state: AgentShellOutputState.running,
      truncated: truncated,
    );
  }

  /// Returns null where no safe regular descriptor exists.
  Future<AgentShellOutput?> read(int pid, {String? outputId}) async {
    if (Platform.isWindows || pid <= 0) {
      return null;
    }
    if (outputId != null && _retained.containsKey(outputId)) {
      return _snapshot(_retained[outputId]);
    }
    try {
      final listing = await _descriptors(pid);
      final paths = <({String path, int? inode, String? device})>[];
      int? fd;
      String? name;
      int? inode;
      String? device;
      var regular = false;
      var seenPid = false;
      void collect() {
        if (seenPid &&
            (fd == 1 || fd == 2) &&
            regular &&
            name != null &&
            name.startsWith('/') &&
            !name.contains(' (deleted)') &&
            !paths.any((p) => p.path == name)) {
          paths.add((path: name, inode: inode, device: device));
        }
      }

      for (final line in const LineSplitter().convert(listing)) {
        if (line.isEmpty) {
          continue;
        }
        switch (line[0]) {
          case 'p':
            if (int.tryParse(line.substring(1)) != pid) {
              return null;
            }
            seenPid = true;
          case 'f':
            collect();
            fd = int.tryParse(_fdNumber.stringMatch(line.substring(1)) ?? '');
            regular = false;
            name = null;
            inode = null;
            device = null;
          case 't':
            regular = line.substring(1) == 'REG';
          case 'i':
            inode = int.tryParse(line.substring(1));
          case 'D':
            device = line.substring(1);
          case 'n':
            name = line.substring(1);
        }
      }
      collect();
      if (paths.isEmpty) {
        return null;
      }
      final handles = <_NativeFileTail>[];
      for (final path in paths) {
        if (_hostDescriptors &&
            Platform.isMacOS &&
            (path.inode == null || path.device == null)) {
          continue;
        }
        final handle = await _NativeFileTail.open(
          path.path,
          expectedInode: path.inode,
          expectedDevice: path.device,
          procDescriptor: _hostDescriptors && Platform.isLinux,
        );
        if (handle != null) {
          handles.add(handle);
        }
      }
      if (handles.isEmpty) {
        return null;
      }
      final result = _snapshot(handles);
      if (outputId == null || result == null) {
        for (final handle in handles) {
          handle.close();
        }
      } else {
        _retained[outputId] = handles;
        while (_retained.length > 128) {
          forget(_retained.keys.first);
        }
      }
      return result;
    } on Object {
      return null;
    }
  }

  static Future<String> _discover(int pid) async {
    if (Platform.isMacOS) {
      final result = await Process.run('lsof', [
        '-nP',
        '-a',
        '-p',
        '$pid',
        '-d',
        '1,2',
        '-F',
        'pftniD',
      ]);
      return result.exitCode == 0 ? result.stdout as String : '';
    }
    if (Platform.isLinux) {
      final buffer = StringBuffer('p$pid\n');
      final seenTargets = <String>{};
      for (final fd in [1, 2]) {
        try {
          final path = '/proc/$pid/fd/$fd';
          final target = await Link(path).target();
          if (!target.startsWith('/') ||
              target.endsWith(' (deleted)') ||
              seenTargets.contains(target)) {
            continue;
          }
          if (File(path).statSync().type == FileSystemEntityType.file) {
            buffer.write('f$fd\ntREG\nn$path\n');
            seenTargets.add(target);
          }
        } on FileSystemException {
          // One closed/pipe descriptor does not hide another regular file.
        }
      }
      return buffer.toString();
    }
    return '';
  }
}

/// The verified regular file itself, not its mutable pathname.
class _NativeFileTail {
  _NativeFileTail(this.fd);

  final int fd;
  bool _closed = false;

  static Future<_NativeFileTail?> open(
    String path, {
    required int? expectedInode,
    required String? expectedDevice,
    required bool procDescriptor,
  }) async {
    final parts = path.split('/').where((p) => p.isNotEmpty).toList();
    if (!path.startsWith('/') ||
        parts.isEmpty ||
        parts.any((p) => p == '.' || p == '..')) {
      return null;
    }
    final directory = Platform.isMacOS ? 0x100000 : 0x10000;
    final noFollow = Platform.isMacOS ? 0x100 : 0x20000;
    final nonblock = Platform.isMacOS ? 0x4 : 0x800;
    // Captured output must not be inherited by subsequently spawned agents.
    final closeOnExec = Platform.isMacOS ? 0x1000000 : 0x80000;
    final atCwd = Platform.isMacOS ? -2 : -100;
    var parent = atCwd;
    var opened = -1;
    try {
      final root = '/'.toNativeUtf8();
      try {
        parent = _openat(atCwd, root, directory | noFollow | closeOnExec);
      } finally {
        calloc.free(root);
      }
      if (parent < 0) {
        return null;
      }
      for (var i = 0; i < parts.length; i++) {
        final component = parts[i].toNativeUtf8();
        int next;
        try {
          final leaf = i == parts.length - 1;
          next = _openat(
            parent,
            component,
            closeOnExec |
                (leaf
                    ? nonblock | (procDescriptor ? 0 : noFollow)
                    : directory | noFollow),
          );
        } finally {
          calloc.free(component);
          _closeFd(parent);
          parent = -1;
        }
        if (next < 0) {
          return null;
        }
        parent = next;
      }
      opened = parent;
      parent = -1;
      // lsof reports the kernel's actual open descriptor, not path metadata.
      // Comparing device AND inode rejects rename/replacement between the
      // command's lsof snapshot and our openat. Files of another type cannot
      // pass as output, even if replaced by a pipe before openat.
      if (Platform.isMacOS) {
        final result = await Process.run('lsof', [
          '-nP',
          '-a',
          '-p',
          '$pid',
          '-d',
          '$opened',
          '-F',
          'pftniD',
        ]);
        if (result.exitCode != 0) {
          return null;
        }
        final fields = const LineSplitter().convert(result.stdout as String);
        if (!fields.contains('p$pid') ||
            !fields.any(
              (field) =>
                  field.startsWith('f') &&
                  int.tryParse(
                        _fdNumber.stringMatch(field.substring(1)) ?? '',
                      ) ==
                      opened,
            ) ||
            !fields.contains('tREG') ||
            (expectedInode != null && !fields.contains('i$expectedInode')) ||
            (expectedDevice != null && !fields.contains('D$expectedDevice'))) {
          return null;
        }
      } else if (File('/proc/$pid/fd/$opened').statSync().type !=
          FileSystemEntityType.file) {
        return null;
      }
      final handle = _NativeFileTail(opened);
      opened = -1;
      return handle;
    } on Object {
      return null;
    } finally {
      if (parent >= 0) {
        _closeFd(parent);
      }
      if (opened >= 0) {
        _closeFd(opened);
      }
    }
  }

  (String, bool)? read(int cap) {
    if (_closed) {
      return null;
    }
    final length = _seekFd(fd, 0, 2);
    if (length < 0) {
      return null;
    }
    final start = length > cap ? length - cap : 0;
    if (_seekFd(fd, start, 0) < 0) {
      return null;
    }
    final buffer = calloc<Uint8>(cap);
    try {
      final count = _readFd(fd, buffer.cast<Void>(), cap);
      if (count < 0) {
        return null;
      }
      return (
        const Utf8Decoder(
          allowMalformed: true,
        ).convert(buffer.asTypedList(count)),
        length > cap,
      );
    } finally {
      calloc.free(buffer);
    }
  }

  void close() {
    if (_closed) {
      return;
    }
    _closed = true;
    _closeFd(fd);
  }
}

// POSIX file operations; no shell or client-supplied pathname is executed.
final _libc = DynamicLibrary.process();
final int Function(int, Pointer<Utf8>, int) _openat = _libc
    .lookupFunction<
      Int32 Function(Int32, Pointer<Utf8>, Int32),
      int Function(int, Pointer<Utf8>, int)
    >('openat');
final int Function(int, int, int) _seekFd = _libc
    .lookupFunction<
      Int64 Function(Int32, Int64, Int32),
      int Function(int, int, int)
    >('lseek');
final int Function(int, Pointer<Void>, int) _readFd = _libc
    .lookupFunction<
      IntPtr Function(Int32, Pointer<Void>, IntPtr),
      int Function(int, Pointer<Void>, int)
    >('read');
final int Function(int) _closeFd = _libc
    .lookupFunction<Int32 Function(Int32), int Function(int)>('close');
