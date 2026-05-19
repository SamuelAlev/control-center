import 'dart:convert';

import 'package:cc_domain/features/model_routing/model_routing.dart';
import 'package:cc_infra/src/model_routing/models_dev_snapshot.dart';

/// A [ModelsDevSource] that serves a fixed in-memory document — by default the
/// bundled models.dev snapshot. Pure (no `dart:io`), so it is safe on web and
/// in tests; the disk/network-backed [ModelsDevSource] lives in
/// `file_models_dev_source.dart` (VM only).
class InMemoryModelsDevSource implements ModelsDevSource {
  /// Creates an [InMemoryModelsDevSource] over [document]; defaults to the
  /// bundled snapshot.
  InMemoryModelsDevSource([Map<String, dynamic>? document])
    : _document =
          document ??
          jsonDecode(bundledModelsDevSnapshotJson) as Map<String, dynamic>;

  final Map<String, dynamic> _document;

  @override
  Future<Map<String, dynamic>?> load() async => _document;

  @override
  Future<Map<String, dynamic>?> refresh({bool force = false}) async =>
      _document;
}
