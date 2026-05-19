import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/features/settings/domain/entities/claude_account.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Repository for the host's Claude Code logins.
final claudeAccountsRepositoryProvider = Provider<RpcClaudeAccountsRepository>(
  (ref) => RpcClaudeAccountsRepository(ref.watch(rpcClientProvider)),
);

/// Every Claude Code account on the host, with live status and plan usage.
///
/// A single fetch, not a stream: the underlying `claude auth status` probe
/// spawns the CLI once per account, so this refreshes when a surface opens or
/// after a mutation — never on a timer. `ref.invalidate` after create / remove
/// / rename / setDefault, and after a login terminal closes.
final claudeAccountsProvider = FutureProvider<List<ClaudeAccountView>>(
  (ref) => ref.watch(claudeAccountsRepositoryProvider).list(),
);

/// Whether this install manages any Claude Code accounts at all.
///
/// The composer's picker hides itself when this is false, so an install that
/// never configured one (or a non-macOS host happily using `~/.claude`) sees no
/// new chrome.
final hasClaudeAccountsProvider = Provider<bool>(
  (ref) => ref.watch(claudeAccountsProvider).asData?.value.isNotEmpty ?? false,
);

/// How many Claude Code accounts this install manages.
///
/// Zero while the probe is still in flight, which is the right way round for
/// the surfaces that gate on "more than one": chrome that appears a beat late
/// is a smaller lie than chrome that appears and then vanishes.
final claudeAccountCountProvider = Provider<int>(
  (ref) => ref.watch(claudeAccountsProvider).asData?.value.length ?? 0,
);
