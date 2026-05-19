/// Flutter-free worker entrypoint that parses GitHub-flavored markdown off the
/// main thread.
///
/// Imports only `package:cc_markdown/parser.dart` (the Flutter-free parse island
/// + AST codec), never the render/widget layers, so it compiles to a Web Worker
/// via `dart compile js` (see `tool/gen_workers.sh` → `web/markdownWorker.js`).
///
/// The profile is fixed to the plugin-free GitHub register (`CcPluginSet.empty`
/// + default `CcParseOptions`): those are the surfaces with genuinely large
/// one-shot documents (PR bodies, tickets, meeting notes) and, being plugin-
/// free, they never produce custom AST nodes the primitive codec can't carry.
/// Chat/streaming markdown (AI plugins) stays on the synchronous main-thread
/// path and is never routed here.
library;

import 'dart:convert';

import 'package:cc_markdown/parser.dart';
import 'package:isolate_manager/isolate_manager.dart';

/// Parses the markdown [source] and returns the JSON-encoded primitive
/// [CcDocument] (see `encodeCcDocument`).
///
/// BOTH the parameter and the result are plain **strings**, never Maps: a Web
/// Worker (js_interop) cannot transfer a Dart Map — passing one makes the web
/// converter throw (isolate_manager issue #31), which is exactly what silently
/// broke the diff worker on web. The source is passed verbatim; the parsed
/// document comes back as JSON. Native isolates would copy a Map fine, but one
/// code path must satisfy both. `workerName: 'markdownWorker'` in
/// `MarkdownParsePool` must match this function name.
@pragma('vm:entry-point')
@isolateManagerWorker
String markdownWorker(String source) {
  const parser = CcParser(
    plugins: CcPluginSet.empty,
    options: CcParseOptions(),
  );
  return jsonEncode(encodeCcDocument(parser.parseDocument(source)));
}
