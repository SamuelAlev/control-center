import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/ports/forge_pr_client.dart';

/// Builds the [ForgePrClient] for [repo] in [workspaceId], acting as
/// [actingUserId].
///
/// The one shape every server path that needs a forge client takes. The repo
/// row decides the forge (and so the adapter); the workspace decides which
/// credentials and App lane apply; [actingUserId] decides whose name the calls
/// carry, and null means work no person is doing (pollers, automation). A
/// resolver whose transport is already bound to one actor (a per-actor PR
/// repository registry) ignores [actingUserId].
typedef ForgePrClientResolver =
    ForgePrClient Function(
      Repo repo, {
      required String workspaceId,
      String? actingUserId,
    });
