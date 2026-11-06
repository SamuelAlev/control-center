import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';

/// How environments are named.
class EnvironmentNaming {
  /// Creates an [EnvironmentNaming].
  const EnvironmentNaming({
    this.template = '{branch}',
    this.project,
    this.maxLength = 31,
    this.pool,
  });

  /// Parses a `naming` object.
  factory EnvironmentNaming.fromJson(Map<String, dynamic> json) =>
      EnvironmentNaming(
        template: (json['template'] as String?) ?? '{branch}',
        project: json['project'] as String?,
        maxLength: (json['maxLength'] as num?)?.toInt() ?? 31,
        pool: json['pool'] is Map
            ? EnvironmentNamePool.fromJson(
                Map<String, dynamic>.from(json['pool'] as Map),
              )
            : null,
      );

  /// The name template.
  final String template;

  /// Project label for router URLs.
  final String? project;

  /// The longest allowed name.
  final int maxLength;

  /// A fixed set of names, for URLs registered in advance.
  final EnvironmentNamePool? pool;

  /// JSON form.
  Map<String, dynamic> toJson() => {
    'template': template,
    if (project != null) 'project': project,
    'maxLength': maxLength,
    if (pool != null) 'pool': pool!.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is EnvironmentNaming &&
      const DeepCollectionEquality().equals(other.toJson(), toJson());

  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());
}

/// A fixed, known set of names.
class EnvironmentNamePool {
  /// Creates an [EnvironmentNamePool].
  const EnvironmentNamePool({required this.names, required this.size});

  /// Parses a `pool` object.
  factory EnvironmentNamePool.fromJson(Map<String, dynamic> json) =>
      EnvironmentNamePool(
        names: (json['names'] as String?) ?? '',
        size: (json['size'] as num?)?.toInt() ?? 0,
      );

  /// A template containing `{n}`.
  final String names;

  /// How many names exist.
  final int size;

  /// The name in [slot], counting from one.
  String nameFor(int slot) => names.replaceAll('{n}', '$slot');

  /// JSON form.
  Map<String, dynamic> toJson() => {'names': names, 'size': size};

  @override
  bool operator ==(Object other) =>
      other is EnvironmentNamePool &&
      const DeepCollectionEquality().equals(other.toJson(), toJson());

  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());
}

final _label = RegExp(r'^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$');

/// Whether [value] is a valid DNS label.
bool isValidEnvironmentLabel(String value) => _label.hasMatch(value);

/// A DNS-safe slug of [value], at most [maxLength] long.
///
/// Truncation appends a short hash of the whole input so two long branches
/// that differ only at the end stay different names.
String environmentSlug(String value, {int maxLength = 31}) {
  final slug = value
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp('^-+|-+\$'), '');
  final base = slug.isEmpty ? 'env' : slug;
  if (base.length <= maxLength) {
    return base;
  }
  final hash = sha1.convert(utf8.encode(value)).toString().substring(0, 6);
  final head = base
      .substring(0, maxLength - hash.length - 1)
      .replaceAll(RegExp(r'-+$'), '');
  return '$head-$hash';
}

/// The name for a space: `pr-<n>` for a PR space, else the slugged branch.
String environmentNameFor({
  required String template,
  required String branch,
  int? prNumber,
  int maxLength = 31,
}) {
  final source = prNumber != null
      ? 'pr-$prNumber'
      : template.replaceAll('{branch}', branch);
  return environmentSlug(source, maxLength: maxLength);
}

/// The single DNS label CC's router serves for an endpoint.
///
/// `<endpoint>--<name>--<project>` stays one label on purpose: the router's
/// domain rule and the `*.localhost` certificate only cover one label. The name
/// is shortened when the whole label would pass 63 characters.
String environmentRouterLabel({
  required String endpoint,
  required String name,
  required String project,
}) {
  final fixed = endpoint.length + project.length + 4;
  final budget = 63 - fixed;
  final fitted = name.length <= budget
      ? name
      : environmentSlug(name, maxLength: budget < 8 ? 8 : budget);
  return '$endpoint--$fitted--$project';
}
