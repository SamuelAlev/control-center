import 'dart:convert';

import 'package:cc_domain/features/pr_review/domain/repositories/review_studio_repository.dart';
import 'package:cc_domain/features/pr_review/domain/services/api_contract_differ.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/api_contract_diff.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:yaml/yaml.dart';

/// Reads a repository file's content at a given git ref (SHA/branch). Returns
/// null when the file is absent at that ref. Backed by the GitHub content API
/// on the server, or `git show <ref>:<path>` in tests.
typedef ContentReader =
    Future<String?> Function({required String path, required String ref});

/// Detects changed OpenAPI spec files in a PR and computes a swagger-style
/// contract diff (PRD 18 §5). Reads each spec's base + head content via a
/// [ContentReader], parses YAML/JSON and runs the pure
/// [OpenApiContractDiffer]. Only EXPLICIT specs matching the configured globs
/// are diffed — deriving a contract from handler code is out of scope
/// (advisory-only if ever).
class ApiContractDiffService {
  /// Creates an [ApiContractDiffService].
  ApiContractDiffService({
    required ApiContractDiffRepository repository,
    List<String>? specGlobs,
  }) : _repository = repository,
       _specGlobs = specGlobs ?? defaultSpecGlobs;

  final ApiContractDiffRepository _repository;
  final List<String> _specGlobs;

  static const _differ = OpenApiContractDiffer();

  /// Default spec globs (per PRD 18 clarifications). GraphQL specs are detected
  /// but the deterministic diff engine here handles OpenAPI/Swagger JSON+YAML.
  static const List<String> defaultSpecGlobs = [
    'openapi.yaml',
    'openapi.yml',
    'openapi.json',
    'swagger.yaml',
    'swagger.yml',
    'swagger.json',
  ];

  /// Which of [changedFiles] look like OpenAPI spec files.
  List<String> matchingSpecs(List<String> changedFiles) => [
    for (final f in changedFiles)
      if (_isSpec(f)) f,
  ];

  bool _isSpec(String path) {
    final name = path.split('/').last.toLowerCase();
    if (_specGlobs.any((g) => name == g.toLowerCase())) {
      return true;
    }
    // Also match `*openapi*.{yaml,yml,json}` / `*swagger*.{...}` anywhere.
    final isSpecName = name.contains('openapi') || name.contains('swagger');
    final isSpecExt =
        name.endsWith('.yaml') ||
        name.endsWith('.yml') ||
        name.endsWith('.json');
    return isSpecName && isSpecExt;
  }

  /// Computes + persists contract diffs for the changed spec files. Returns the
  /// persisted diffs (empty when no spec changed). [changedFiles] are the PR's
  /// repository-relative changed paths.
  Future<List<ApiContractDiff>> compute({
    required String workspaceId,
    required String repoId,
    required String prExternalId,
    required String baseSha,
    required String headSha,
    required List<String> changedFiles,
    required ContentReader readContent,
  }) async {
    final specs = matchingSpecs(changedFiles);
    final diffs = <ApiContractDiff>[];
    for (final spec in specs) {
      final before = await _readAt(readContent, baseSha, spec);
      final after = await _readAt(readContent, headSha, spec);
      final beforeDoc = _parse(before);
      final afterDoc = _parse(after);
      if (beforeDoc == null && afterDoc == null) {
        continue; // Neither side parseable (binary/absent) — skip honestly.
      }
      final changes = _differ.diff(beforeDoc ?? const {}, afterDoc ?? const {});
      final diff = ApiContractDiff(
        // Deterministic id per (pr, spec) → PK upsert dedupes across pushes.
        id: '$prExternalId:$spec',
        workspaceId: workspaceId,
        repoId: repoId,
        prExternalId: prExternalId,
        specPath: spec,
        changes: changes,
        headSha: headSha,
      );
      await _repository.upsert(workspaceId, diff);
      diffs.add(diff);
    }
    return diffs;
  }

  /// Reads a file's content at [ref], or null when absent at that revision.
  Future<String?> _readAt(ContentReader read, String ref, String path) async {
    try {
      return await read(path: path, ref: ref);
    } catch (e) {
      CcInfraLog.warning('api_contract: read $ref:$path failed: $e');
      return null;
    }
  }

  /// Parses spec text (JSON first, then YAML) into a plain map, or null.
  Map<String, dynamic>? _parse(String? text) {
    if (text == null || text.trim().isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map) {
        return decoded.cast<String, dynamic>();
      }
    } catch (_) {
      // Not JSON — fall through to YAML.
    }
    try {
      final yaml = loadYaml(text);
      final converted = _yamlToDart(yaml);
      if (converted is Map) {
        return converted.cast<String, dynamic>();
      }
    } catch (e) {
      CcInfraLog.warning('api_contract: spec parse failed: $e');
    }
    return null;
  }

  Object? _yamlToDart(Object? node) {
    if (node is YamlMap) {
      return {
        for (final entry in node.nodes.entries)
          entry.key.toString(): _yamlToDart(entry.value.value),
      };
    }
    if (node is YamlList) {
      return [for (final item in node.nodes) _yamlToDart(item.value)];
    }
    if (node is YamlNode) {
      return node.value;
    }
    return node;
  }
}
