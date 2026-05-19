import 'dart:async';

import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/features/sandboxing/domain/ports/sandbox_detector_port.dart';
import 'package:cc_infra/src/sandboxing/env_credential_broker.dart';
import 'package:cc_infra/src/sandboxing/native_sandbox_adapter.dart';
import 'package:cc_infra/src/sandboxing/no_sandbox_adapter.dart';
import 'package:cc_infra/src/sandboxing/sandbox_backend_detector.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';
import 'package:control_center/di/providers.dart' show credentialsRepositoryProvider;
import 'package:control_center/features/sandboxing/providers/sandboxing_providers.dart'
    show activeSandboxBackendProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── VM-only sandbox execution providers ──────────────────────────────────────
//
// Everything here constructs cc_infra adapters (`dart:io`: Process.start,
// File, Platform), so this file MUST NOT enter the web graph. It is read only
// by VM-only code: the dispatch composition root (`server_providers.dart`), the
// desktop interactive terminal, and the RPC host wiring. Web-reachable
// presentation reads the web-safe `sandboxing_providers.dart` instead.

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

/// The LOCAL OS-native sandbox detector (probes this machine via `dart:io`).
///
/// This is the canonical local [SandboxDetectorPort]: the `provider_bindings`
/// io seam binds the public `sandboxDetectorPortProvider` to it, and the RPC
/// host wiring serves it over the `sandbox.detect` op. The headless `cc_server`
/// builds its own equivalent (it has no Riverpod).
final localSandboxDetectorProvider = Provider<SandboxDetectorPort>((ref) {
  return SandboxBackendDetector(ref.watch(sandboxAdaptersPoolProvider));
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

