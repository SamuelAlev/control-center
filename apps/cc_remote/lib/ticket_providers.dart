import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_remote/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The server-owned workspace ticket provider, never a device-wide preference.
/// A workspace with no configured provider uses the domain's local default.
final mobileTicketProvider = StreamProvider.family<TicketProvider, String>((
  ref,
  workspaceId,
) async* {
  final client = await ref.watch(rpcClientProvider.future);
  yield* RemoteWorkspaceSettingsRepository(client).watchAll(workspaceId).map((
    settings,
  ) {
    final raw = settings['ticketing_provider'];
    if (raw != null && !TicketProvider.values.any((p) => p.name == raw)) {
      throw StateError('Unsupported workspace ticket provider: $raw');
    }
    return TicketProvider.fromStorage(raw);
  });
});
