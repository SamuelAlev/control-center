import 'package:cc_connect_core/cc_connect_core.dart'
    show isConnectSecretEnvKey;

/// Provider secrets the server takes only from its `.env` file or the settings
/// UI, never from the exported process environment.
///
/// An exported variable is inherited by everything the process starts and by
/// whatever started it: a shell profile, a launch agent, a CI job's other
/// steps. The `.env` file beside the server (or in its working directory) is
/// read into one in-memory map at boot and handed to nothing else.
const List<String> refusedProcessSecrets = [
  'GITHUB_APP_PRIVATE_KEY',
  'GITHUB_CLIENT_SECRET',
  'GOOGLE_OAUTH_CLIENT_SECRET',
  'LINEAR_API_KEY',
];

/// Whether [key] is a provider secret the server refuses to boot with when it
/// is exported: [refusedProcessSecrets], every `SLACK_*SECRET*`, and every
/// secret of an embedded Connect ([isConnectSecretEnvKey]).
bool isRefusedProcessSecret(String key) {
  final upper = key.toUpperCase();
  return refusedProcessSecrets.contains(upper) ||
      (upper.startsWith('SLACK_') && upper.contains('SECRET')) ||
      isConnectSecretEnvKey(upper);
}

/// Thrown by `runCcServer` when the process environment exports a provider
/// secret. The server does not start.
class ProviderSecretInEnvironmentException implements Exception {
  /// Creates the exception for the exported [keys].
  const ProviderSecretInEnvironmentException(this.keys);

  /// The exported secret names (never their values).
  final List<String> keys;

  /// What the operator reads.
  String get message =>
      'cc_server: refusing to start — ${keys.join(', ')} '
      '${keys.length == 1 ? 'is' : 'are'} exported in the process '
      'environment, where every child process and the shell that started '
      'this one can read ${keys.length == 1 ? 'it' : 'them'}.\n'
      "Unset ${keys.length == 1 ? 'it' : 'them'} and put the value in the "
      "server's .env file (in its working directory or beside the "
      'executable), or configure the provider in Settings.';

  @override
  String toString() => message;
}

/// Throws [ProviderSecretInEnvironmentException] when [processEnvironment] —
/// the REAL environment, before any `.env` is layered in — exports a refused
/// provider secret. Empty values are ignored, like the `.env` reader does.
void refuseExportedProviderSecrets(Map<String, String> processEnvironment) {
  final exported = [
    for (final entry in processEnvironment.entries)
      if (entry.value.isNotEmpty && isRefusedProcessSecret(entry.key))
        entry.key,
  ]..sort();
  if (exported.isNotEmpty) {
    throw ProviderSecretInEnvironmentException(exported);
  }
}
