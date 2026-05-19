import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_scope.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Argument for [spaceSearchProvider]: the space to search and the raw
/// user query.
typedef SpaceSearchQuery = ({String spaceId, String query});

/// In-space full-text search results (§8.4), fetched over RPC
/// (`messaging.searchInSpace`, which validates space ownership). Returns an
/// empty list for a blank/stopword-only query so a search bar can bind to it
/// directly without special-casing the empty state.
final spaceSearchProvider = FutureProvider.autoDispose
    .family<List<Message>, SpaceSearchQuery>((ref, arg) async {
      final query = arg.query.trim();
      if (query.isEmpty) {
        return const [];
      }
      return ref
          .watch(messagingRepositoryProvider)
          .searchInSpace(ref.requireWorkspaceId(), arg.spaceId, query);
    });
