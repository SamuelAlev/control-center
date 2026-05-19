// Web embedding model: honest stubs.
//
// On-device embedding inference is cc_natives FFI (`dart:ffi`, uncompilable by
// dart2js), so on web the embedding port throws on use and the lifecycle
// controller reports a permanent "not installed" (desktop-only) state. Any UI
// that reads the model state still renders; install/uninstall throw.
library;

import 'package:cc_domain/core/domain/ports/embedding_port.dart';
import 'package:control_center/core/infrastructure/embedding/embedding_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Never _unsupported() => throw UnsupportedError(
  'On-device embeddings are not available on web (cc_natives runs on the '
  'desktop; the web client would reach embeddings over RPC in a later phase).',
);

class _WebEmbeddingPort implements EmbeddingPort {
  @override
  dynamic noSuchMethod(Invocation invocation) => _unsupported();
}

/// Honest stub: on-device embedding inference has no web path.
EmbeddingPort buildEmbeddingPort(Ref ref) => _WebEmbeddingPort();

/// Web lifecycle controller: permanently "not installed" (desktop-only).
EmbeddingModelController buildEmbeddingModelController() =>
    _WebEmbeddingModelController();

class _WebEmbeddingModelController extends EmbeddingModelController {
  @override
  EmbeddingModelState build() =>
      const EmbeddingModelState(status: EmbeddingModelStatus.notInstalled);

  @override
  Future<void> installIfNeeded() async => _unsupported();

  @override
  void cancel() {}

  @override
  Future<void> uninstall() async => _unsupported();
}
