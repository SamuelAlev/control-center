import 'package:cc_natives/cc_natives.dart' show IsolatedGit;

/// Reads [key] from the host user's global git config, top level only.
///
/// `--no-includes`: an included file can live anywhere, including somewhere a
/// sandbox may write. The global files themselves are write-denied to every
/// sandbox (`SandboxPolicyResolver.homeMandatoryDenyRels`), so what this
/// returns is the user's own setting. [environment] is the host environment
/// git locates that file from (`Platform.environment` by default).
Future<String?> readGlobalGitConfig(
  String key, {
  Map<String, String>? environment,
}) => IsolatedGit.readHostGlobalConfig(key, host: environment);

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
