import 'package:cc_domain/cc_domain.dart' show NetworkException;
import 'package:cc_domain/features/skills/domain/ports/skill_registry_port.dart';
import 'package:cc_infra/src/network/error_mapper.dart';
import 'package:dio/dio.dart';

/// [SkillRegistryPort] over the skills.sh registry HTTP API (PRD 23 §1).
///
/// Server-side only (owns a `dio`). Treats ALL response metadata as untrusted
/// display data — the trusted artifact is the bytes returned by [resolve],
/// which the caller still runs through the mandatory scan gate. Trust content
/// hashes, not publisher names or a "verified" flag.
class SkillsShRegistryAdapter implements SkillRegistryPort {
  /// Creates a [SkillsShRegistryAdapter] backed by `dio` (built with the
  /// skills.sh base URL).
  SkillsShRegistryAdapter(this._dio);

  final Dio _dio;

  @override
  Future<List<SkillListing>> search(String query, {int limit = 25}) async {
    try {
      final response = await _dio.get<Object?>(
        '/skills',
        queryParameters: {'q': query, 'limit': limit},
      );
      final data = response.data;
      final rawList = data is Map ? data['skills'] : data;
      if (rawList is! List) {
        return const [];
      }
      return rawList
          .whereType<Map<String, dynamic>>()
          .map(_listingFromJson)
          .toList();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }
      throw mapDioException(e);
    }
  }

  @override
  Future<ResolvedSkill> resolve(String slug, {String? version}) async {
    try {
      final response = await _dio.get<Object?>(
        '/skills/$slug',
        queryParameters: {'version': ?version},
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const NetworkException(
          'skills.sh returned an unexpected shape',
          code: 'bad_registry_response',
        );
      }
      final files = <String, String>{};
      final rawFiles = data['files'];
      if (rawFiles is Map) {
        rawFiles.forEach((k, v) {
          if (v is String) {
            files[k.toString()] = v;
          }
        });
      }
      // Single-file fallback: some registries return just the SKILL.md body.
      if (files.isEmpty && data['content'] is String) {
        files['SKILL.md'] = data['content'] as String;
      }
      if (files.isEmpty) {
        throw const NetworkException(
          'skills.sh returned no skill content',
          code: 'empty_registry_bundle',
        );
      }
      return ResolvedSkill(
        slug: slug,
        files: files,
        version: (data['version'] as String?) ?? version ?? '',
        publisher:
            (data['publisher'] as String?) ?? (data['author'] as String?) ?? '',
        verifiedPublisher: data['verified'] == true,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }
      throw mapDioException(e);
    }
  }

  static SkillListing _listingFromJson(Map<String, dynamic> json) =>
      SkillListing(
        slug: (json['slug'] as String?) ?? (json['name'] as String?) ?? '',
        name: (json['name'] as String?) ?? (json['slug'] as String?) ?? '',
        description: (json['description'] as String?) ?? '',
        author:
            (json['author'] as String?) ?? (json['publisher'] as String?) ?? '',
        version: (json['version'] as String?) ?? '',
        installCount: (json['install_count'] as num?)?.toInt() ?? 0,
        verifiedPublisher: json['verified'] == true,
      );
}
