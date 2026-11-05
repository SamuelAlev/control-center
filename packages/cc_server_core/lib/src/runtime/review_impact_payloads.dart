import 'package:cc_persistence/cc_persistence.dart';

Map<String, dynamic> _rootJson(CodeSymbolsTableData symbol) => {
  'id': symbol.id,
  'name': symbol.name,
  'qualifiedName': symbol.qualifiedName,
  'filePath': symbol.filePath,
};

/// The symbols a file's largest declaration reaches, for the review studio's
/// blast-radius view. A file with no indexed symbols reports `indexed: false`.
Future<Map<String, dynamic>> fileBlastRadiusPayload({
  required CodeGraphDao dao,
  required String workspaceId,
  required String repoId,
  required String filePath,
  required int depth,
}) async {
  final symbols = await dao.getSymbolsByFiles(workspaceId, repoId, [filePath]);
  if (symbols.isEmpty) {
    return {'nodes': const [], 'edges': const [], 'indexed': false};
  }
  symbols.sort((a, b) => (b.endLine - b.startLine) - (a.endLine - a.startLine));
  final root = symbols.first;
  final impact = await dao.getImpactRadius(workspaceId, root.id, depth: depth);
  return {
    'indexed': true,
    'root': _rootJson(root),
    'nodes': [
      for (final n in impact.nodes)
        {
          'id': n.id,
          'name': n.name,
          'qualifiedName': n.qualifiedName,
          'filePath': n.filePath,
          'kind': n.kind,
          'depth': impact.depthById[n.id] ?? 0,
        },
    ],
    'edges': [
      for (final e in impact.edges)
        {
          'source': e.sourceSymbolId,
          'target': e.targetSymbolId,
          'kind': e.kind,
        },
    ],
  };
}

/// The merged impact of a review cohort: each file's largest declaration is a
/// root, and a symbol reached from several keeps its shortest distance.
Future<Map<String, dynamic>> cohortImpactPayload({
  required CodeGraphDao dao,
  required String workspaceId,
  required String repoId,
  required List<String> filePaths,
  required String cohortKey,
  required int depth,
}) async {
  final symbols = await dao.getSymbolsByFiles(workspaceId, repoId, filePaths);
  if (symbols.isEmpty) {
    return {'indexed': false, 'nodes': const [], 'edges': const []};
  }
  final files = filePaths.toSet();
  final dominantByFile = <String, CodeSymbolsTableData>{};
  for (final s in symbols) {
    if (!files.contains(s.filePath)) {
      continue;
    }
    final current = dominantByFile[s.filePath];
    if (current == null ||
        (s.endLine - s.startLine) > (current.endLine - current.startLine)) {
      dominantByFile[s.filePath] = s;
    }
  }
  final nodes = <String, Map<String, dynamic>>{};
  final edges = <String, Map<String, dynamic>>{};
  for (final dominant in dominantByFile.values) {
    final impact = await dao.getImpactRadius(
      workspaceId,
      dominant.id,
      depth: depth,
    );
    for (final n in impact.nodes) {
      final hop = impact.depthById[n.id] ?? 0;
      final existing = nodes[n.id];
      if (existing == null) {
        nodes[n.id] = {
          'id': n.id,
          'name': n.name,
          'qualifiedName': n.qualifiedName,
          'filePath': n.filePath,
          'kind': n.kind,
          'depth': hop,
        };
      } else if (hop < (existing['depth'] as num)) {
        existing['depth'] = hop;
      }
    }
    for (final e in impact.edges) {
      edges['${e.sourceSymbolId}->${e.targetSymbolId}'] = {
        'source': e.sourceSymbolId,
        'target': e.targetSymbolId,
        'kind': e.kind,
      };
    }
  }
  return {
    'indexed': true,
    'cohort_key': cohortKey,
    'roots': [for (final r in dominantByFile.values) _rootJson(r)],
    'nodes': nodes.values.toList(),
    'edges': edges.values.toList(),
  };
}
