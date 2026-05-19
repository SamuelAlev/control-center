import 'dart:async';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_server_core/cc_server_core.dart';

/// Entrypoint for the Control Center **public demo** server.
///
/// It is the real `cc_server` composition — the real RPC catalog, the real
/// client — booted with [buildDemoWiring]. What a visitor sees is the product,
/// not a mock of it, and there is no second UI to maintain.
///
/// ## Why a separate binary rather than `cc_server --demo`
///
/// Two reasons, and both are load-bearing:
///
///  1. **The fixtures would ship to every desktop install.** The demo's run
///     scripts and its pull-request world compile INTO the binary (a demo whose
///     data lives in a sibling directory fails as an empty demo, which is the
///     worst failure shape). A runtime `if (demoMode)` branch inside
///     `runCcServer` is reachable code, so tree-shaking could not remove any of
///     it. With a separate entrypoint that `cc_server`'s `main` never
///     references, the entire subtree is shaken out of the production binary.
///
///  2. **A flag can be forgotten.** A public endpoint whose lockdown depends on
///     `CC_SERVER_DEMO=1` becomes a fully armed server on the internet the first
///     time someone drops that variable from a deployment. A demo-only artifact
///     makes that failure impossible: deploying this image IS the lockdown.
///
/// ## What the demo removes
///
/// Structurally, by passing `null` for every execution port — so the ops are
/// never built and `RepoOpDispatcher` answers `opUnknown`, exactly as it would
/// for an op that does not exist:
///
///  * terminals, rigs (enclosures), the code-server proxy, the filesystem
///    surface, process control, repo scripts and every git-mutating verb;
///  * MCP server + client control (so `/mcp` and `/sse` are never mounted);
///  * OAuth, the provider app identity, forge and per-user credentials;
///  * SSO (OIDC/SAML/SCIM), inbound webhooks, database backup/export;
///  * the media and font proxies — the last outbound HTTP a demo container
///    could have made.
///
/// On top of that, `DemoProfile` is a default-deny name allowlist over the
/// remaining ops, and a ratchet test forces every op added to the catalog in
/// future to be consciously classified.
///
/// Agent runs are real runs with a scripted brain: a `ScriptedAgentLoop` is
/// injected into the dispatch adapter, so **zero** tools execute and no model
/// is ever called, while run logs, transcript segments, the live stream, cost
/// accounting and `AgentRunCompleted` all behave exactly as they do in
/// production.
///
/// ## Configuration
///
/// Standard `CC_SERVER_*` process configuration applies (`--data-dir`,
/// `--port`, `--bind`, `--insecure`, TLS). The demo adds, all optional:
///
/// ```
/// CC_SERVER_DEMO_TTL_MINUTES     45     how long a visitor's workspace lives
/// CC_SERVER_DEMO_MAX_VISITORS    60     live visitors before redemption 503s
/// CC_SERVER_DEMO_POOL_SIZE       4      workspaces seeded and kept warm
/// CC_SERVER_DEMO_DISK_BUDGET_MB  8192   data-directory ceiling
/// CC_SERVER_DEMO_MAX_PER_IP      3      concurrent sessions from one address
/// CC_SERVER_DEMO_INVITE_CODE     demo   the code the public entry URL carries
/// ```
Future<void> main(List<String> args) async {
  if (args.isNotEmpty && (args.first == '--version' || args.first == '-v')) {
    stdout.writeln(
      'cc_demo_server ${BuildInfo.buildVersion} (${BuildInfo.buildGitSha})',
    );
    exit(0);
  }

  // Same guarded zone as cc_server: an uncaught async error in a reaper or a
  // pool fill is recorded to the rotating on-disk log instead of vanishing.
  await runZonedGuarded(() => _run(args), recordUncaughtServerError);
}

Future<void> _run(List<String> args) async {
  final CcServer server;
  try {
    server = await runCcServer(args: args, demoBuilder: buildDemoWiring);
  } on SocketException catch (e) {
    stderr.writeln(
      'cc_demo_server: cannot start — ${e.osError?.message ?? e.message} '
      '(${e.address?.host}:${e.port}). Another server is already on that '
      'port — stop it, or pass --port.',
    );
    exit(1);
  }

  final done = Completer<void>();
  void requestShutdown() {
    if (!done.isCompleted) {
      done.complete();
    }
  }

  for (final sig in [ProcessSignal.sigint, ProcessSignal.sigterm]) {
    sig.watch().listen((_) => requestShutdown());
  }

  await done.future;
  // Watching the signals overrides their default terminate behaviour, so we
  // must exit ourselves; the reconcilers and drift's isolate otherwise keep
  // the event loop alive forever. Teardown reaps every live visitor first.
  try {
    await server.shutdown().timeout(const Duration(seconds: 12));
  } on Object catch (e) {
    stderr.writeln('cc_demo_server: shutdown did not complete cleanly: $e');
  }
  await stdout.flush();
  exit(0);
}
