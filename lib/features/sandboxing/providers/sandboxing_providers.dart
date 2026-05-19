import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_detection_result.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/storage/sandbox_preferences.dart';
import 'package:control_center/di/providers.dart' show sandboxDetectorPortProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Web-safe sandbox providers ───────────────────────────────────────────────
//
// These providers contain NO `dart:io` — they read user preferences (backed by
// shared_preferences on desktop / localStorage on web) and the host-sourced
// detection result. They are imported by web-reachable presentation (the
// Settings → Sandboxing page, the onboarding sandbox step, the agent form).
//
// The genuinely-local execution providers (the adapter pool, the active
// SandboxPort, the session manager, the credential broker) live in
// `sandboxing_providers_server.dart`, which imports cc_infra (`dart:io`) and is
// therefore reachable ONLY from VM-only code (the dispatch composition root and
// the desktop terminal). Keeping them out of this file is what lets the web
// build open the sandboxing settings without crashing.

/// User preferences for the sandbox subsystem (master toggle, chosen backend,
/// default capabilities for new conversations). Client-local key/value.
final sandboxPreferencesProvider = Provider<SandboxPreferences>((ref) {
  return SandboxPreferences(ref.watch(appPreferencesProvider));
});

/// Detects the sandbox environment of the HOST that actually runs agents.
///
/// The sandbox executes on the host, not the client, so detection is sourced
/// from [sandboxDetectorPortProvider]: on the desktop self-serve build that is
/// the local machine; on a thin/web client it is the connected `cc_server`,
/// resolved over the `sandbox.detect` RPC op. It NEVER probes the browser.
final sandboxDetectionProvider = FutureProvider<SandboxDetectionResult>((ref) {
  return ref.watch(sandboxDetectorPortProvider).detect();
});

/// Backend currently in effect — honours the master toggle and the user's
/// explicit pick before falling back to the detector's recommendation.
final activeSandboxBackendProvider = Provider<SandboxBackend>((ref) {
  final prefs = ref.watch(sandboxPreferencesProvider);
  if (!prefs.isEnabled) {
    return SandboxBackend.none;
  }
  final pinned = prefs.backend;
  if (pinned != null) {
    return pinned;
  }
  return ref.watch(sandboxDetectionProvider).maybeWhen(
        data: (r) => r.recommendation,
        orElse: () => SandboxBackend.none,
      );
});

/// Default capabilities applied to new conversations.
final defaultCapabilitiesProvider = Provider<AgentCapabilities>((ref) {
  return ref.watch(sandboxPreferencesProvider).defaultCapabilities;
});
