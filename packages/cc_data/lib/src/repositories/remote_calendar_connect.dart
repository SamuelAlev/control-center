import 'package:cc_rpc/cc_rpc.dart';

/// Disconnects Google Calendar accounts over the RPC client.
///
/// Connecting one is not here: it is the generic browser sign-in on the
/// `google` lane (`RemoteProviderSignIn.begin` with the workspace the account
/// syncs into). The server, or Connect, runs the OAuth exchange and keeps the
/// refresh token; this client only ever sees the attempt's state.
///
/// Disconnecting is `calendar.disconnect`, which also drops the account's
/// synced events.
class RemoteCalendarConnect {
  /// Creates a [RemoteCalendarConnect] over [_client].
  RemoteCalendarConnect(this._client);

  final RemoteRpcClient _client;

  /// Disconnects [accountId] (clears its tokens + removes its synced events).
  Future<void> disconnect(String accountId) =>
      _client.call('calendar.disconnect', {'account_id': accountId});
}
