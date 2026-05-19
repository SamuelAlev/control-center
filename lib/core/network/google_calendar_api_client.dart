import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/network/error_mapper.dart';
import 'package:control_center/core/network/models/google_calendar_event.dart';
import 'package:control_center/core/network/models/google_calendar_list_entry.dart';
import 'package:dio/dio.dart';

/// Read-only client for the Google Calendar API v3.
///
/// Mirrors the GitHub clients: every method wraps the call in try/catch,
/// re-throws cancellations, and maps any other [DioException] through
/// [mapDioException]. The [Dio] is expected to carry the OAuth Bearer +
/// refresh interceptor (see `googleCalendarDioProvider`). Pagination follows
/// Google's `nextPageToken` (not GitHub-style Link headers).
class GoogleCalendarApiClient {
  /// Creates a [GoogleCalendarApiClient] backed by [Dio].
  GoogleCalendarApiClient(this._dio);

  final Dio _dio;

  static const int _maxResults = 2500;

  /// Lists the calendars on [accountId]'s calendar list.
  Future<List<GoogleCalendarListEntry>> listCalendars({
    required String accountId,
    CancelToken? cancelToken,
  }) async {
    try {
      final entries = <GoogleCalendarListEntry>[];
      String? pageToken;
      do {
        final response = await _dio.get<dynamic>(
          '$googleCalendarApiBaseUrl/users/me/calendarList',
          queryParameters: <String, dynamic>{
            'pageToken': ?pageToken,
          },
          options: Options(extra: {googleAccountIdExtraKey: accountId}),
          cancelToken: cancelToken,
        );
        final body = _asMap(response.data);
        entries.addAll(
          _decodeList(body['items'], GoogleCalendarListEntry.fromJson),
        );
        pageToken = body['nextPageToken'] as String?;
      } while (pageToken != null && pageToken.isNotEmpty);
      return entries;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }
      throw mapDioException(e);
    }
  }

  /// Lists events on [calendarId] between [timeMin] and [timeMax].
  ///
  /// `singleEvents=true` + `orderBy=startTime` make Google expand recurrences
  /// server-side into concrete instances (so we never parse RRULEs ourselves).
  /// All pages are followed via `nextPageToken`.
  Future<List<GoogleCalendarEvent>> listEvents({
    required String accountId,
    String calendarId = 'primary',
    required DateTime timeMin,
    required DateTime timeMax,
    bool singleEvents = true,
    String orderBy = 'startTime',
    CancelToken? cancelToken,
  }) async {
    try {
      final events = <GoogleCalendarEvent>[];
      final encodedId = Uri.encodeComponent(calendarId);
      String? pageToken;
      do {
        final response = await _dio.get<dynamic>(
          '$googleCalendarApiBaseUrl/calendars/$encodedId/events',
          queryParameters: <String, dynamic>{
            'timeMin': timeMin.toUtc().toIso8601String(),
            'timeMax': timeMax.toUtc().toIso8601String(),
            'singleEvents': singleEvents,
            'orderBy': orderBy,
            'maxResults': _maxResults,
            'pageToken': ?pageToken,
          },
          options: Options(extra: {googleAccountIdExtraKey: accountId}),
          cancelToken: cancelToken,
        );
        final body = _asMap(response.data);
        events.addAll(
          _decodeList(body['items'], GoogleCalendarEvent.fromJson),
        );
        pageToken = body['nextPageToken'] as String?;
      } while (pageToken != null && pageToken.isNotEmpty);
      return events;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }
      throw mapDioException(e);
    }
  }

  /// Writes the user's RSVP by PATCHing the event's [attendees] array.
  ///
  /// Google merges arrays by replacement on PATCH, so callers must pass the
  /// full attendee list with the self attendee's `responseStatus` updated.
  /// Requires the `calendar.events` scope; accounts connected with only
  /// `calendar.readonly` will get a 403 (mapped to an [Exception]).
  Future<void> patchEventResponse({
    required String accountId,
    required String calendarId,
    required String eventId,
    required List<Map<String, dynamic>> attendees,
    CancelToken? cancelToken,
  }) async {
    try {
      final encodedCal = Uri.encodeComponent(calendarId);
      final encodedEvent = Uri.encodeComponent(eventId);
      await _dio.patch<dynamic>(
        '$googleCalendarApiBaseUrl/calendars/$encodedCal/events/$encodedEvent',
        data: <String, dynamic>{'attendees': attendees},
        options: Options(extra: {googleAccountIdExtraKey: accountId}),
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }
      throw mapDioException(e);
    }
  }

  List<T> _decodeList<T>(
    Object? data,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (data is! List) {
      return <T>[];
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList(growable: false);
  }

  static Map<String, dynamic> _asMap(Object? data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    return const <String, dynamic>{};
  }
}
