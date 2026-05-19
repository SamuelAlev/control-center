import 'package:cc_rpc/cc_rpc.dart';

/// What `calendar.beginConnect` returns: the user code + URL to display and an
/// opaque handle the GUI polls with.
class CalendarConnectBeginDto {
  /// Creates a [CalendarConnectBeginDto].
  const CalendarConnectBeginDto({
    required this.handle,
    required this.userCode,
    required this.verificationUrl,
    required this.interval,
    required this.expiresIn,
  });

  /// Opaque handle for the pending flow.
  final String handle;

  /// The short code the user enters at [verificationUrl].
  final String userCode;

  /// Where the user approves the request.
  final String verificationUrl;

  /// Minimum delay the GUI should wait between [RemoteCalendarConnect.poll]s.
  final Duration interval;

  /// How long until the device code expires.
  final Duration expiresIn;
}

/// The status of a connect poll, mirroring the host's `CalendarConnectStatus`.
enum CalendarConnectPollStatus {
  /// Not yet approved — keep polling.
  pending,

  /// Approved + stored; [CalendarConnectPollDto.accountEmail] is set.
  connected,

  /// The user denied the request.
  denied,

  /// The device code expired before approval — restart.
  expired,

  /// The handle is unknown (expired/cleared) — restart.
  unknown,
}

/// What `calendar.pollConnect` returns.
class CalendarConnectPollDto {
  /// Creates a [CalendarConnectPollDto].
  const CalendarConnectPollDto(this.status, {this.accountEmail});

  /// The poll status.
  final CalendarConnectPollStatus status;

  /// The connected account email, set iff [status] is
  /// [CalendarConnectPollStatus.connected].
  final String? accountEmail;
}

/// Drives the GUI device-code Google Calendar connect over the RPC client.
///
/// The host owns the OAuth tokens + sync; this client only relays the user's
/// supplied client id + secret, surfaces the code + URL to approve, polls until
/// the host reports the result, and can disconnect an account. Mirrors the
/// `calendar.beginConnect` / `calendar.pollConnect` / `calendar.disconnect` ops.
class RemoteCalendarConnect {
  /// Creates a [RemoteCalendarConnect] over [_client].
  RemoteCalendarConnect(this._client);

  final RemoteRpcClient _client;

  /// Begins a device-code flow with the supplied [clientId] + [clientSecret].
  Future<CalendarConnectBeginDto> begin({
    required String clientId,
    required String clientSecret,
  }) async {
    final d = await _client.call('calendar.beginConnect', {
      'client_id': clientId,
      'client_secret': clientSecret,
    });
    return CalendarConnectBeginDto(
      handle: d['handle'] as String,
      userCode: d['user_code'] as String,
      verificationUrl: d['verification_url'] as String,
      interval: Duration(seconds: (d['interval_seconds'] as num?)?.toInt() ?? 5),
      expiresIn: Duration(
        seconds: (d['expires_in_seconds'] as num?)?.toInt() ?? 1800,
      ),
    );
  }

  /// Polls the pending flow [handle] once.
  Future<CalendarConnectPollDto> poll(String handle) async {
    final d = await _client.call('calendar.pollConnect', {'handle': handle});
    final status = switch (d['status'] as String?) {
      'pending' => CalendarConnectPollStatus.pending,
      'connected' => CalendarConnectPollStatus.connected,
      'denied' => CalendarConnectPollStatus.denied,
      'expired' => CalendarConnectPollStatus.expired,
      _ => CalendarConnectPollStatus.unknown,
    };
    return CalendarConnectPollDto(
      status,
      accountEmail: d['account_email'] as String?,
    );
  }

  /// Disconnects [accountId] (clears its tokens + removes its synced events).
  Future<void> disconnect(String accountId) =>
      _client.call('calendar.disconnect', {'account_id': accountId});
}
