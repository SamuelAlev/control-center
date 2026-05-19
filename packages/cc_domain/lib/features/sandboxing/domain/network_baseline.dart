/// Network baseline domains for the sandboxed coding-agent profile.
///
/// These are the ONLY hosts a sandboxed coding agent may reach by default.
/// Everything else is denied unless an agent's capabilities or
/// `egressAllowlist` explicitly adds it.
///
/// Kept as a pure-Dart const (no `dart:io`) so it lives in the domain layer.
library;

/// Domains always allowed when network is on.
const List<String> kBaselineAllowedDomains = [
  // LLM API providers
  'api.openai.com',
  '*.anthropic.com',
  'api.githubcopilot.com',
  'generativelanguage.googleapis.com',
  'api.mistral.ai',
  'api.cohere.ai',
  'api.together.xyz',
  'openrouter.ai',
  'api.morphllm.com',
  '*.amazonaws.com',

  // OpenCode
  'opencode.ai',
  'api.opencode.ai',

  // Amp
  'ampcode.com',
  '*.ampcode.com',

  // Factory CLI (droid)
  '*.factory.ai',
  'api.workos.com',

  // Cursor API
  '*.cursor.sh',

  // Copilot
  '*.githubcopilot.com',

  // Git hosting
  'github.com',
  'api.github.com',
  'raw.githubusercontent.com',
  'codeload.github.com',
  'objects.githubusercontent.com',
  'release-assets.githubusercontent.com',
  'gitlab.com',

  // Package registries
  'registry.npmjs.org',
  '*.npmjs.org',
  'registry.yarnpkg.com',
  'pypi.org',
  'files.pythonhosted.org',
  'crates.io',
  'static.crates.io',
  'index.crates.io',
  'proxy.golang.org',
  'sum.golang.org',
  'formulae.brew.sh',

  // Model registry
  'models.dev',
];

/// Domains always denied — cloud metadata APIs (credential theft),
/// telemetry sinks. Denies take precedence over allows.
const List<String> kBaselineDeniedDomains = [
  // Cloud metadata APIs (prevent credential theft).
  '169.254.169.254',
  'metadata.google.internal',
  'instance-data.ec2.internal',

  // Telemetry.
  'statsig.anthropic.com',
  '*.sentry.io',
];

/// GitHub-specific domains added when the agent has GitHub capabilities.
const List<String> kGithubDomains = [
  'github.com',
  '*.github.com',
  'api.github.com',
  'codeload.github.com',
  'lfs.github.com',
  'objects.githubusercontent.com',
  'raw.githubusercontent.com',
  'release-assets.githubusercontent.com',
];
