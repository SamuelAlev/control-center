import 'dart:convert';

import 'package:cc_domain/features/environments/domain/entities/environment_definition_record.dart';

const JsonEncoder _pretty = JsonEncoder.withIndent('  ');

/// What the editor opens on. Identity keys the editor's state, so opening a
/// definition again starts from what the server holds.
class EnvironmentEditorSeed {
  /// Creates an [EnvironmentEditorSeed].
  EnvironmentEditorSeed({
    required this.workspaceId,
    required this.draft,
    this.record,
    this.notes = const [],
  });

  /// Opens a stored definition.
  factory EnvironmentEditorSeed.record(EnvironmentDefinitionRecord record) =>
      EnvironmentEditorSeed(
        workspaceId: record.workspaceId,
        record: record,
        draft: Map<String, dynamic>.from(
          jsonDecode(record.definitionJson) as Map,
        ),
      );

  /// Opens an empty definition, bound to [repoId] when there is one.
  factory EnvironmentEditorSeed.blank(
    String workspaceId, {
    required String name,
    String? repoId,
  }) => EnvironmentEditorSeed(
    workspaceId: workspaceId,
    draft: {
      'contract': 1,
      'name': name,
      'repos': {
        'app': {'repoId': repoId ?? '', 'anchor': true, 'required': true},
      },
      'components': <Object?>[],
    },
  );

  /// The owning workspace.
  final String workspaceId;

  /// The stored row, or null for something not saved yet.
  final EnvironmentDefinitionRecord? record;

  /// The definition's JSON.
  final Map<String, dynamic> draft;

  /// What a repo scan wants the admin to know.
  final List<String> notes;
}

/// Pretty JSON, as the JSON view shows it.
String environmentPrettyJson(Object? value) => _pretty.convert(value);
