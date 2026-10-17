import 'package:cc_remote/conversation_progress_providers.dart';
import 'package:cc_remote/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Loads one artifact only after its id appeared in this conversation's
/// server-windowed message metadata. Both reads explicitly carry the workspace;
/// the work-product adapter's ambient-workspace methods cannot do that.
final progressArtifactProvider = FutureProvider.autoDispose
    .family<
      ({String title, String? content})?,
      ({ProgressScope scope, String artifactId})
    >((ref, args) async {
      final scope = args.scope;
      final conversation = await ref.watch(
        progressConversationProvider(scope).future,
      );
      final client = ref.watch(rpcClientProvider).value;
      final active = ref.watch(activeWorkspaceIdProvider).value;
      if (conversation == null ||
          active != scope.workspaceId ||
          client == null) {
        return null;
      }
      final result = await client.call('workProduct.getById', {
        'workspace_id': scope.workspaceId,
        'work_product_id': args.artifactId,
      });
      final raw = result['work_product'];
      if (raw is! Map ||
          raw['id'] != args.artifactId ||
          raw['workspace_id'] != scope.workspaceId) {
        return null;
      }
      final revisionId = raw['current_revision_id'];
      if (revisionId is! String || revisionId.isEmpty) {
        return (title: raw['title'] as String? ?? '', content: null);
      }
      if (ref.read(activeWorkspaceIdProvider).value != scope.workspaceId) {
        return null;
      }
      final history = await client.call('workProduct.revisions', {
        'workspace_id': scope.workspaceId,
        'work_product_id': args.artifactId,
      });
      for (final revision in history['revisions'] as List? ?? const []) {
        if (revision is Map &&
            revision['id'] == revisionId &&
            revision['work_product_id'] == args.artifactId &&
            revision['workspace_id'] == scope.workspaceId) {
          return (
            title: raw['title'] as String? ?? '',
            content: revision['content'] as String?,
          );
        }
      }
      return (title: raw['title'] as String? ?? '', content: null);
    });
