import 'package:nativeapi/nativeapi.dart' show UrlOpener;

/// Desktop implementation of the `openExternalUrl` seam: hands [url] to the OS
/// default handler via nativeapi's synchronous [UrlOpener].
bool openUrlImpl(String url) => UrlOpener.instance.open(url).success;
