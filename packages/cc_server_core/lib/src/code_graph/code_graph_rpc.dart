import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/code_edge_kind.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_symbol.dart';
import 'package:cc_domain/features/code_graph/domain/ports/code_graph_tree_port.dart';
import 'package:cc_domain/features/code_graph/domain/repositories/code_graph_repository.dart';
import 'package:cc_host/cc_host.dart';

/// Name-level code-graph lookup for the PR-diff symbol popover.
///
/// Workspace-scoped and membership-gated like sibling ops. Partition selection
/// (PR worktree vs linked checkout) mirrors the MCP code-graph tools: fail
/// open to the base when the worktree partition has no indexed files.
List<RepoOp> buildCodeGraphOps({
  required WorkspaceRepository workspaceRepository,
  required CodeGraphRepository codeGraph,
  CodeGraphTreePort? tree,
}) => [
  RepoOp(
    name: 'codeGraph.symbolLookup',
    kind: RepoOpKind.read,
    requiredArgs: ['workspace_id', 'repo_id', 'name'],
    repoAccess: RepoGrantLevel.read,
    handler: (ctx) async {
      final workspaceId = ctx.workspaceId!;
      final repoId = ctx.args['repo_id'] as String;
      final name = (ctx.args['name'] as String).trim();
      if (name.isEmpty) {
        throw const ValidationException('name must not be empty');
      }
      final linked = await workspaceRepository.isRepoLinkedToWorkspace(
        workspaceId,
        repoId,
      );
      if (!linked) {
        throw const WorkspaceMismatchException(
          'Repo is not linked to this workspace',
        );
      }
      final spaceRaw = ctx.args['space_id'];
      final spaceId = spaceRaw is String && spaceRaw.isNotEmpty
          ? spaceRaw
          : null;

      var fromBase = true;
      String? checkoutId;
      if (spaceId != null && tree != null) {
        try {
          checkoutId = await tree.checkoutIdFor(
            workspaceId: workspaceId,
            repoId: repoId,
            spaceId: spaceId,
          );
        } on Object {
          checkoutId = null;
        }
        if (checkoutId != null) {
          try {
            final built = await codeGraph.hasIndexedFiles(
              workspaceId,
              repoId,
              checkoutId: checkoutId,
            );
            if (built) {
              fromBase = false;
            } else {
              checkoutId = null;
            }
          } on Object {
            checkoutId = null;
          }
        }
      }

      final defs = await codeGraph.getByName(
        workspaceId,
        repoId,
        name,
        limit: 20,
        checkoutId: checkoutId,
      );

      const implementorKinds = {
        CodeEdgeKind.implementsType,
        CodeEdgeKind.extendsType,
        CodeEdgeKind.mixesIn,
      };

      final definitions = <Map<String, dynamic>>[];
      for (final def in defs) {
        final callers = await codeGraph.callers(
          workspaceId,
          def.id,
          limit: 100,
          checkoutId: checkoutId,
        );
        final implementors = await codeGraph.callers(
          workspaceId,
          def.id,
          kinds: implementorKinds,
          limit: 20,
          checkoutId: checkoutId,
        );
        definitions.add({
          ..._symbolJson(def),
          'caller_count': callers.length,
          'implementors': [for (final i in implementors) _symbolJson(i)],
        });
      }

      return {
        'from_base': fromBase,
        'definitions': definitions,
      };
    },
  ),
];

Map<String, dynamic> _symbolJson(CodeSymbol s) => {
  'id': s.id,
  'name': s.name,
  'qualified_name': s.qualifiedName,
  'kind': s.kind.name,
  'file_path': s.filePath,
  'start_line': s.startLine,
  'end_line': s.endLine,
  'parent_name': s.parentName,
  'signature': s.signature,
};
