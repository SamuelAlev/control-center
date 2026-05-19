import 'dart:typed_data';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:http/http.dart' as http;

/// Points [CcFontRegistry] at the connected host so user-selected fonts can
/// load, and clears it when there is no connection.
///
/// This is the client half of the font path: cc_ui decides WHICH variant it
/// needs during build and this supplies the bytes, fetched from the host's
/// `/proxy/font` route. `package:http` works on both web and native, so desktop
/// and the web client share one implementation.
///
/// Call it wherever the media proxy config is resolved — the two travel
/// together, since both are just "how this client reaches its host".
void installHostFontLoader(MediaProxyConfig? proxy) {
  if (proxy == null) {
    return;
  }
  CcFontRegistry.instance.install(
    fallbackFamily: CcFonts.uiFamily,
    loader: ({required family, required weight, required italic}) =>
        _fetchFont(proxy, family: family, weight: weight, italic: italic),
  );
}

Future<Uint8List?> _fetchFont(
  MediaProxyConfig proxy, {
  required String family,
  required int weight,
  required bool italic,
}) async {
  final url = proxy.fontUrl(family: family, weight: weight, italic: italic);
  final response = await http.get(Uri.parse(url));
  // 404 is the ordinary answer for a family the host does not catalogue (an
  // OS-installed font, say), so it is not worth surfacing: the registry keeps
  // rendering the family by name.
  if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
    return null;
  }
  return response.bodyBytes;
}
