/// Every Control Center Connect environment variable that carries a secret
/// value, upper case: the dual secrets with their `_PREVIOUS` rotation, and
/// the single ones. Identifiers, flags, limits and `_FILE` paths are not in
/// it. `apps/cc_connect` pins it to what its configuration reads as a
/// secret, so a new secret variable cannot be added without it.
const Set<String> connectSecretEnvKeys = {
  'CONNECT_GITHUB_CLIENT_SECRET',
  'CONNECT_GITHUB_CLIENT_SECRET_PREVIOUS',
  'CONNECT_GITHUB_APP_PRIVATE_KEY',
  'CONNECT_GOOGLE_CLIENT_SECRET',
  'CONNECT_GOOGLE_CLIENT_SECRET_PREVIOUS',
  'CONNECT_SLACK_CLIENT_SECRET',
  'CONNECT_SLACK_CLIENT_SECRET_PREVIOUS',
  'CONNECT_SLACK_SIGNING_SECRET',
  'CONNECT_SLACK_SIGNING_SECRET_PREVIOUS',
  'CONNECT_KLIPY_APP_KEY',
  'CONNECT_KLIPY_APP_KEY_PREVIOUS',
  'CONNECT_SEAL_KEYS',
  'CONNECT_REDIS_URL',
  'CONNECT_LOG_HMAC_KEY',
  'CONNECT_SENTRY_DSN',
};

/// Whether the environment variable [key] (any case) carries a Connect
/// secret ([connectSecretEnvKeys]). False for identifiers, flags and the
/// `_FILE` path that points at a secret.
bool isConnectSecretEnvKey(String key) =>
    connectSecretEnvKeys.contains(key.toUpperCase());
