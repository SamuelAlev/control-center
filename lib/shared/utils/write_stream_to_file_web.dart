/// Web has no writable path, so this is never reached: the download path checks
/// `kIsWeb` first and hands the signed URL to the browser, whose own download
/// machinery saves the response (it already carries `Content-Disposition:
/// attachment`). The stub exists so the io implementation's `dart:io` import
/// stays off the web graph.
Future<void> writeStreamToFileImpl(Stream<List<int>> stream, String path) {
  throw UnsupportedError(
    'A browser tab has no writable path — downloads are handed to the browser.',
  );
}
