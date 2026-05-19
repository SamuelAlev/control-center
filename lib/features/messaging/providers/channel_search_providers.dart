import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_scope.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Argument for [channelSearchProvider]: the channel to search and the raw
/// user query.
typedef ChannelSearchQuery = ({String channelId, String query});

/// In-channel full-text search results (§8.4), fetched over RPC
/// (`messaging.searchInChannel`, which validates channel ownership). Returns an
/// empty list for a blank/stopword-only query so a search bar can bind to it
/// directly without special-casing the empty state.
final channelSearchProvider = FutureProvider.autoDispose
    .family<List<ChannelMessage>, ChannelSearchQuery>((ref, arg) async {
      final query = arg.query.trim();
      if (query.isEmpty) {
        return const [];
      }
      return ref
          .watch(messagingRepositoryProvider)
          .searchInChannel(ref.requireWorkspaceId(), arg.channelId, query);
    });
