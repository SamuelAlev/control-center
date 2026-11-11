/// The environment of every child process the server spawns.
///
/// A child never sees the server's environment wholesale. It starts from an
/// explicit allowlist ([baseKeys], [basePrefixes]) read out of the host
/// environment, gains only the host variables its caller names (`inherit`,
/// `inheritPrefixes`, or one of the named groups such as [toolchainKeys]),
/// and then the caller's explicit values on top.
///
/// Whatever the caller asks to inherit, [isStripped] keys never cross from
/// the host: GitHub tokens, every provider secret family, Connect settings,
/// the SSH agent socket and dynamic-loader injection variables. A server
/// whose operator exported `GITHUB_CLIENT_SECRET` must not hand it to a pipeline
/// step, an agent or an MCP server. Explicit values are the caller's own
/// decision and are not filtered: that is how a broker-minted one-repo
/// `GH_TOKEN` reaches a pipeline shell step, and how the owner's commit signer
/// reaches their SSH agent.
///
/// Pure: the host map is passed in (`Platform.environment` in the infra
/// layer), so the policy itself has no `dart:io`.
final class ChildEnvironment {
  const ChildEnvironment._();

  /// Variables every child inherits when the host has them. Matched
  /// case-insensitively (Windows keys are case-insensitive).
  static const Set<String> baseKeys = {
    'PATH',
    'HOME',
    'USER',
    'LOGNAME',
    'SHELL',
    'TERM',
    'COLORTERM',
    'TMPDIR',
    'TMP',
    'TEMP',
    'LANG',
    'LANGUAGE',
    'TZ',
    'NO_COLOR',
    'FORCE_COLOR',
    'CLICOLOR',
    // Network plumbing an operator sets for every program on the host. The
    // agent sandbox replaces the proxy variables with its own.
    'HTTP_PROXY',
    'HTTPS_PROXY',
    'NO_PROXY',
    'ALL_PROXY',
    'SSL_CERT_FILE',
    'SSL_CERT_DIR',
    // Nix's CA bundle. Nix-packaged tools read their trust anchors from it:
    // the nixpkgs `claude` wrapper defaults to the macOS system store, which
    // cannot verify Anthropic's chain, and only adds this bundle when it sees
    // the variable. Without it every Claude Code run fails TLS before it
    // starts.
    'NIX_SSL_CERT_FILE',
    // macOS: the default text encoding CoreFoundation tools read.
    '__CF_USER_TEXT_ENCODING',
    // Windows: a process cannot start, resolve a program or find its profile
    // without these.
    'SYSTEMROOT',
    'WINDIR',
    'COMSPEC',
    'PATHEXT',
    'USERPROFILE',
    'USERNAME',
    'USERDOMAIN',
    'APPDATA',
    'LOCALAPPDATA',
    'PROGRAMDATA',
    'PROGRAMFILES',
    'PROGRAMFILES(X86)',
    'PROGRAMW6432',
    'COMMONPROGRAMFILES',
    'COMMONPROGRAMFILES(X86)',
    'SYSTEMDRIVE',
    'HOMEDRIVE',
    'HOMEPATH',
    'NUMBER_OF_PROCESSORS',
    'PROCESSOR_ARCHITECTURE',
    'OS',
  };

  /// Prefixes every child inherits (locale categories).
  static const Set<String> basePrefixes = {'LC_'};

  /// Where version and package managers keep their trees. Agents, pipeline
  /// steps, terminals and environment tasks build and test code, so they
  /// inherit these; system utilities do not need them.
  static const Set<String> toolchainKeys = {
    'COREPACK_HOME',
    'PNPM_HOME',
    'NVM_DIR',
    'NVM_BIN',
    'NVM_INC',
    'VOLTA_HOME',
    'BUN_INSTALL',
    'DENO_INSTALL',
    'DENO_DIR',
    'PLAYWRIGHT_BROWSERS_PATH',
    'CARGO_HOME',
    'RUSTUP_HOME',
    'RUSTUP_TOOLCHAIN',
    'GOPATH',
    'GOROOT',
    'GOBIN',
    'GOPROXY',
    'GOPRIVATE',
    'GONOSUMDB',
    'GOTOOLCHAIN',
    'GOCACHE',
    'GOMODCACHE',
    'FVM_CACHE_PATH',
    'PUB_CACHE',
    'FLUTTER_ROOT',
    'PYENV_ROOT',
    'PYENV_VERSION',
    'PIPX_HOME',
    'PIPX_BIN_DIR',
    'VIRTUAL_ENV',
    'RBENV_ROOT',
    'SDKMAN_DIR',
    'JAVA_HOME',
    'GRADLE_USER_HOME',
    'MISE_DATA_DIR',
    'ASDF_DIR',
    'ASDF_DATA_DIR',
    'DEVELOPER_DIR',
    'SDKROOT',
    'HOMEBREW_PREFIX',
    'HOMEBREW_CELLAR',
    'HOMEBREW_REPOSITORY',
  };

  /// Prefixes of [toolchainKeys]' families.
  static const Set<String> toolchainPrefixes = {
    'XDG_',
    'FNM_',
    'UV_',
    'ANDROID_',
  };

  /// What a program that opens a window or talks to the session's audio
  /// server needs (Linux desktops; `XDG_RUNTIME_DIR` is in [toolchainPrefixes]'
  /// `XDG_` family and must be inherited alongside).
  static const Set<String> displayKeys = {
    'DISPLAY',
    'WAYLAND_DISPLAY',
    'XAUTHORITY',
    'DBUS_SESSION_BUS_ADDRESS',
    'PULSE_SERVER',
    'PULSE_RUNTIME_PATH',
    'XDG_RUNTIME_DIR',
    'XDG_SESSION_TYPE',
    'XDG_CURRENT_DESKTOP',
  };

  /// Host variables that never cross into a child, whatever it asks for.
  static const Set<String> strippedKeys = {
    // GitHub credentials. Server-run work authenticates with a broker-minted
    // one-repo token passed explicitly, never the host's.
    'GH_TOKEN',
    'GITHUB_TOKEN',
    'GH_ENTERPRISE_TOKEN',
    'GITHUB_ENTERPRISE_TOKEN',
    'GH_CONFIG_DIR',
    // The operator's SSH agent: whoever can reach it can authenticate as them.
    'SSH_AUTH_SOCK',
    'SSH_AGENT_PID',
    // Code-injection vectors that run before any sandbox or program logic.
    'BASH_ENV',
    'ENV',
    'PERL5OPT',
    'PERL_MM_OPT',
    'PYTHONPATH',
    'PYTHONSTARTUP',
    'NODE_OPTIONS',
    'NODE_EXTRA_CA_CERTS',
    'RUBYOPT',
    'GIT_SSH',
    'GIT_SSH_COMMAND',
    'GIT_ASKPASS',
    'SSH_ASKPASS',
  };

  /// Host variable families that never cross into a child.
  static const Set<String> strippedPrefixes = {
    'GITHUB_APP_',
    'GITHUB_CLIENT_',
    'GOOGLE_OAUTH_',
    'LINEAR_',
    'SLACK_',
    'KLIPY_',
    'CC_CONNECT_',
    // Dynamic-linker injection (`LD_PRELOAD`, `DYLD_INSERT_LIBRARIES`, …).
    'LD_',
    'DYLD_',
  };

  /// Whether host variable [key] is barred from every child.
  static bool isStripped(String key) {
    final upper = key.toUpperCase();
    if (strippedKeys.contains(upper)) {
      return true;
    }
    for (final prefix in strippedPrefixes) {
      if (upper.startsWith(prefix)) {
        return true;
      }
    }
    return false;
  }

  /// The environment for one child.
  ///
  /// From [host]: [baseKeys]/[basePrefixes] (unless [inheritBase] is false),
  /// plus [inherit]/[inheritPrefixes], plus the [toolchainKeys] family when
  /// [toolchain] is set and [displayKeys] when [display] is set — never a
  /// [isStripped] key. Then [overrides], verbatim, on top.
  static Map<String, String> build(
    Map<String, String> host, {
    Iterable<String> inherit = const [],
    Iterable<String> inheritPrefixes = const [],
    bool toolchain = false,
    bool display = false,
    bool inheritBase = true,
    Map<String, String>? overrides,
  }) {
    final keys = <String>{
      if (inheritBase) ...baseKeys,
      if (toolchain) ...toolchainKeys,
      if (display) ...displayKeys,
      for (final key in inherit) key.toUpperCase(),
    };
    final prefixes = <String>{
      if (inheritBase) ...basePrefixes,
      if (toolchain) ...toolchainPrefixes,
      for (final prefix in inheritPrefixes) prefix.toUpperCase(),
    };
    final out = <String, String>{};
    for (final entry in host.entries) {
      final upper = entry.key.toUpperCase();
      if (isStripped(upper)) {
        continue;
      }
      if (keys.contains(upper) || prefixes.any(upper.startsWith)) {
        out[entry.key] = entry.value;
      }
    }
    if (overrides != null) {
      out.addAll(overrides);
    }
    return out;
  }
}
