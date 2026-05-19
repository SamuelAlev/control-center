import 'package:cc_domain/features/pr_review/domain/entities/workflow_graph.dart';
import 'package:yaml/yaml.dart';

/// Parses a workflow YAML document into its job graph. Returns null for
/// malformed YAML or a file without a `jobs` map — the caller falls back to
/// the flat job list. Job display name = `name:` when present, else the job
/// id. `needs:` accepts both the scalar and list forms.
WorkflowGraph? workflowGraphFromYaml(String source) {
  final Object? doc;
  try {
    doc = loadYaml(source);
  } on Object {
    return null;
  }
  if (doc is! YamlMap) {
    return null;
  }
  final jobs = doc['jobs'];
  if (jobs is! YamlMap) {
    return null;
  }
  final nodes = <WorkflowJobNode>[];
  for (final entry in jobs.entries) {
    final id = '${entry.key}';
    final body = entry.value;
    if (body is! YamlMap) {
      continue;
    }
    final rawName = body['name'];
    final name = rawName == null ? id : '$rawName';
    final rawNeeds = body['needs'];
    final List<String> needs;
    if (rawNeeds is String) {
      needs = <String>[rawNeeds];
    } else if (rawNeeds is YamlList) {
      needs = rawNeeds.map((e) => '$e').toList(growable: false);
    } else {
      needs = const <String>[];
    }
    nodes.add(WorkflowJobNode(id: id, name: name, needs: needs));
  }
  return WorkflowGraph(name: '${doc['name'] ?? ''}', jobs: nodes);
}
