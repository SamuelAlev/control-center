import 'dart:async';

import 'package:control_center/core/domain/ports/credential_broker_port.dart';
import 'package:control_center/core/domain/ports/sandbox_port.dart';
import 'package:control_center/core/domain/value_objects/agent_capabilities.dart';
import 'package:control_center/core/domain/value_objects/sandbox_backend.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/storage/sandbox_preferences.dart';
import 'package:control_center/di/providers.dart' show credentialsRepositoryProvider;
import 'package:control_center/features/sandboxing/data/adapters/native_sandbox_adapter.dart';
import 'package:control_center/features/sandboxing/data/adapters/no_sandbox_adapter.dart';
import 'package:control_center/features/sandboxing/data/brokers/env_credential_broker.dart';
import 'package:control_center/features/sandboxing/data/runtime/sandbox_manager.dart';
import 'package:control_center/features/sandboxing/data/services/sandbox_backend_detector.dart';
import 'package:control_center/features/sandboxing/data/services/sandbox_session_manager.dart';
import 'package:control_center/features/sandboxing/domain/sandbox_detection_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// User preferences for the sandbox subsystem.
final sandboxPreferencesProvider = Provider<SandboxPreferences>((ref) {
  return SandboxPreferences(ref.watch(sharedPreferencesProvider));
});

/// App-lifetime owner of the in-process sandbox runtime (HTTP/SOCKS proxies,
/// temp-file bookkeeping). Cheap to construct; resources are lazily acquired
/// on the first sandboxed `exec`. Disposed on Riverpod container teardown.
final sandboxManagerProvider = Provider<SandboxManager>((ref) {
  final manager = SandboxManager();
  ref.onDispose(() {
    unawaited(manager.reset());
  });
  return manager;
});

/// All sandbox adapter implementations relevant to the current OS. Used by
/// [SandboxBackendDetector] to probe each one.
final sandboxAdaptersPoolProvider = Provider<List<SandboxPort>>((ref) {
  return <SandboxPort>[
    NoSandboxAdapter(),
    NativeSandboxAdapter(manager: ref.watch(sandboxManagerProvider)),
  ];
});

/// Runs the detection probe once at app start (or when invalidated) and
/// caches the result.
final sandboxDetectionProvider = FutureProvider<SandboxDetectionResult>((ref) {
  final detector = SandboxBackendDetector(ref.watch(sandboxAdaptersPoolProvider));
  return detector.detect();
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

/// Resolves the [SandboxPort] adapter for the active backend.
final sandboxPortProvider = Provider<SandboxPort>((ref) {
  final backend = ref.watch(activeSandboxBackendProvider);
  final pool = ref.watch(sandboxAdaptersPoolProvider);
  return pool.firstWhere(
    (a) => a.backend == backend,
    orElse: () => pool.firstWhere((a) => a.backend == SandboxBackend.none),
  );
});

/// Credential broker that decides which secrets the sandbox sees.
final credentialBrokerProvider = Provider<CredentialBrokerPort>((ref) {
  // The fine-grained broker is a future opt-in; the env broker is the
  // default for Phase 1.
  return EnvCredentialBroker(ref.watch(credentialsRepositoryProvider));
});

/// Default capabilities applied to new conversations.
final defaultCapabilitiesProvider = Provider<AgentCapabilities>((ref) {
  return ref.watch(sandboxPreferencesProvider).defaultCapabilities;
});

/// Shared per-thread sandbox session registry. Owned by Riverpod for the app
/// lifetime — both the agent dispatcher and the terminal panel use it so
/// they target the same VM.
final sandboxSessionManagerProvider = Provider<SandboxSessionManager>((ref) {
  final manager = SandboxSessionManager(ref.watch(sandboxPortProvider));
  ref.onDispose(manager.destroyAll);
  return manager;
});
