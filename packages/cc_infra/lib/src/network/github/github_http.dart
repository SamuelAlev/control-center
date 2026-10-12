import 'package:rhttp/rhttp.dart';

/// Whether [error] is the server answering [status] — a `404` a caller reads as
/// a miss, a `304` it reads as "unchanged" — rather than a transport failure.
bool isHttpStatus(RhttpException error, int status) =>
    error is RhttpStatusCodeException && error.statusCode == status;
