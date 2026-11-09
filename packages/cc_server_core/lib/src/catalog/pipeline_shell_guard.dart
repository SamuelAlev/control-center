import 'package:cc_domain/cc_domain.dart' show AuthException;
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart'
    show BuiltInBodyKeys;
import 'package:cc_host/cc_host.dart' show RepoOpContext;

/// Whether [template] runs a shell step.
bool hasShellStep(PipelineDefinition? template) =>
    template != null &&
    template.steps.any((step) => step.bodyKey == BuiltInBodyKeys.bashScript);

/// A trigger fires its pipeline with no RPC behind it, so arming one that
/// runs a shell step — or editing one that does — is an admin decision, the
/// same as authoring the step.
Future<void> requireAdminForShellTriggers(
  RepoOpContext ctx,
  PipelineTemplateRepository templates,
  List<String> templateIds,
) async {
  if (ctx.role?.isAdmin ?? false) {
    return;
  }
  for (final id in templateIds.toSet()) {
    if (id.isNotEmpty &&
        hasShellStep(await templates.getById(ctx.workspaceId!, id))) {
      throw const AuthException(
        'Only a workspace admin can schedule or arm a pipeline with a shell '
        'step',
      );
    }
  }
}
