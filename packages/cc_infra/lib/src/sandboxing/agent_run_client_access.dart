import 'dart:io';

import 'package:cc_domain/features/sandboxing/domain/sandbox_config.dart';

/// [config] with the agent run client runnable and unchangeable from inside
/// the sandbox. [files] are what the client runs from
/// (`AgentRunClientLauncher.files`), the executable first.
///
/// Every run's shims and Claude Code's hook start the client inside the
/// run's sandbox, and the hook of every other run trusts what it answers, so
/// no sandbox may change it:
///
/// * macOS: the executable is an exec literal
///   ([SandboxConfig.allowedExecutables]), never its directory: a directory
///   allow is emitted after the always-dangerous denies and would re-open
///   denied programs that sit beside the server.
/// * Linux: each file is bound read-only ([FilesystemConfig.allowRead]), so
///   it exists in the sandbox wherever it is installed.
/// * Both: each file is an install root of the host's executables
///   ([HostExecutableDirs.installRoots]), so inside a writable tree it can be
///   neither written nor moved away, nor can the directories above it.
///
/// Each path is used as written and as resolved: the kernel matches rules
/// against the resolved one.
SandboxConfig withAgentRunClient(SandboxConfig config, List<String> files) {
  if (files.isEmpty) {
    return config;
  }
  final executable = _spellings([files.first]);
  final all = _spellings(files);
  final fs = config.filesystem;
  final host = fs.hostExecutables;
  return config.copyWith(
    allowedExecutables: {
      ...config.allowedExecutables,
      ...executable,
    }.toList(),
    filesystem: fs.copyWith(
      allowRead: {...fs.allowRead, ...all}.toList(),
      hostExecutables: HostExecutableDirs(
        dirs: host.dirs,
        links: host.links,
        installRoots: {...host.installRoots, ...all}.toList(),
      ),
    ),
  );
}

List<String> _spellings(List<String> paths) {
  final out = <String>{};
  for (final path in paths) {
    out.add(path);
    try {
      out.add(File(path).resolveSymbolicLinksSync());
    } on FileSystemException {
      // Missing: the written spelling is all there is.
    }
  }
  return out.toList();
}
