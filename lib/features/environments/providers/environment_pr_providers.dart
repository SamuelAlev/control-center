import 'package:cc_domain/features/environments/domain/entities/environment_definition_record.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:cc_domain/features/pr_review/domain/entities/deployment_preview.dart';
import 'package:collection/collection.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_space_provider.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The site name of the environment's preview tab, which keys its dedup.
const String kEnvironmentPreviewSite = 'environment';

/// The PR's space when it already has one, or null.
///
/// A lookup, never `pr.ensureSpace`: watching this must not provision a
/// worktree, so a PR that nobody started anything on stays free. Matched by repo
/// and number for the reason `prSpaceProvider`'s fallback gives.
final existingPrSpaceIdProvider = StreamProvider.autoDispose
    .family<String?, PrSpaceKey>((ref, pr) {
      final workspaceId = ref.watch(activeWorkspaceIdProvider);
      if (workspaceId == null || ref.watch(isDemoServerProvider)) {
        return Stream.value(null);
      }
      return ref
          .watch(reviewSpaceRepositoryProvider)
          .watchByWorkspace(workspaceId)
          .map(
            (associations) => associations
                .firstWhereOrNull(
                  (association) =>
                      association.repoFullName == pr.repoFullName &&
                      association.prNumber == pr.number,
                )
                ?.spaceId,
          );
    });

/// Whether a space on [repoId] could start [record].
bool environmentAnchoredOn(EnvironmentDefinitionRecord record, String? repoId) {
  final definition = environmentDefinitionOf(record);
  if (definition == null || repoId == null || !definition.hasStack) {
    return false;
  }
  return definition.repos.any((role) => role.anchor && role.repoId == repoId);
}

/// The primary endpoint of the PR's environment, as a preview.
///
/// Null on a remote client: the URL resolves on the server host only, so a
/// webview here would just show a failed connection.
final prEnvironmentPreviewProvider = Provider.autoDispose
    .family<DeploymentPreview?, PrSpaceKey>((ref, pr) {
      final workspaceId = ref.watch(activeWorkspaceIdProvider);
      final spaceId = ref.watch(existingPrSpaceIdProvider(pr)).value;
      if (workspaceId == null ||
          spaceId == null ||
          ref.watch(environmentEndpointsAreRemoteProvider)) {
        return null;
      }
      final environment = ref.watch(
        spaceEnvironmentProvider((workspaceId: workspaceId, spaceId: spaceId)),
      );
      final url = environment?.primaryEndpoint?.url;
      final status = environment?.status;
      if (url == null ||
          (status != EnvironmentStatus.ready &&
              status != EnvironmentStatus.degraded)) {
        return null;
      }
      return DeploymentPreview(
        siteName: kEnvironmentPreviewSite,
        url: url,
        source: DeploymentPreviewSource.commitStatus,
      );
    });
