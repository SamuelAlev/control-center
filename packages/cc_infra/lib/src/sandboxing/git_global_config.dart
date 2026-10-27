import 'dart:io';

/// Reads [key] from the host user's global git config, top level only.
///
/// `--no-includes`: an included file can live anywhere, including somewhere a
/// sandbox may write. The global files themselves are write-denied to every
/// sandbox (`SandboxPolicyResolver.homeMandatoryDenyRels`), so what this
/// returns is the user's own setting.
Future<String?> readGlobalGitConfig(
  String key, {
  Map<String, String>? environment,
}) async {
  final ProcessResult result;
  try {
    result = await Process.run('git', [
      'config',
      '--global',
      '--no-includes',
      '--get',
      key,
    ], environment: environment);
  } on ProcessException {
    return null;
  }
  if (result.exitCode != 0) {
    return null;
  }
  final value = (result.stdout as String).trim();
  return value.isEmpty ? null : value;
}

/// The user's `gpg.ssh.program` when their global config signs with SSH
/// (`gpg.format=ssh`), defaulting like git to `ssh-keygen`; null otherwise.
Future<String?> globalSshSigningProgram({
  Map<String, String>? environment,
}) async {
  if (await readGlobalGitConfig('gpg.format', environment: environment) !=
      'ssh') {
    return null;
  }
  return await readGlobalGitConfig(
        'gpg.ssh.program',
        environment: environment,
      ) ??
      'ssh-keygen';
}
