import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// The browser's PDF viewer consumes the same authenticated resource URL.
Widget webPdfPreview({required String url, required String title}) =>
    HtmlElementView.fromTagName(
      tagName: 'iframe',
      onElementCreated: (element) {
        final frame = element as web.HTMLIFrameElement;
        frame
          ..src = url
          ..title = title
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.border = '0';
      },
    );
