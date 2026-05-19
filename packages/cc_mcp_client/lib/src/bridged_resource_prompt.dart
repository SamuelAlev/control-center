import 'package:cc_domain/features/mcp/domain/ports/mcp_resource_prompt_ports.dart';
import 'package:cc_mcp_client/src/connection_manager.dart';

/// Re-exposes resources advertised by EXTERNAL MCP servers through CC's own MCP
/// server (PRD 01 feature 4). External URIs are wrapped as
/// `mcpext://<server>/?uri=<encoded original>` so a read routes deterministically
/// back to the owning server.
class BridgedResourceProvider implements McpResourceProvider {
  /// Creates a [BridgedResourceProvider] over a connection manager.
  BridgedResourceProvider(this._manager);

  final ConnectionManager _manager;

  static const String _scheme = 'mcpext';

  @override
  Future<List<McpResourceDescriptor>> listResources() async {
    return [
      for (final entry in _manager.resources)
        McpResourceDescriptor(
          uri: _wrap(entry.server, entry.resource.uri),
          name: '${entry.server}/${entry.resource.name}',
          title: entry.resource.title,
          description: entry.resource.description,
          mimeType: entry.resource.mimeType,
        ),
    ];
  }

  @override
  Future<McpResourceContents?> readResource(String uri) async {
    final parsed = _unwrap(uri);
    if (parsed == null) {
      return null;
    }
    final result = await _manager.readResource(parsed.server, parsed.uri);
    final contents = result['contents'];
    final buffer = StringBuffer();
    String mime = 'text/plain';
    if (contents is List) {
      for (final c in contents) {
        if (c is Map && c['text'] != null) {
          buffer.writeln(c['text'].toString());
          mime = c['mimeType']?.toString() ?? mime;
        }
      }
    }
    return McpResourceContents(uri: uri, text: buffer.toString().trimRight(), mimeType: mime);
  }

  String _wrap(String server, String originalUri) =>
      '$_scheme://${Uri.encodeComponent(server)}/'
      '?uri=${Uri.encodeQueryComponent(originalUri)}';

  ({String server, String uri})? _unwrap(String wrapped) {
    final parsed = Uri.tryParse(wrapped);
    if (parsed == null || parsed.scheme != _scheme) {
      return null;
    }
    final server = Uri.decodeComponent(parsed.host);
    final original = parsed.queryParameters['uri'];
    if (original == null) {
      return null;
    }
    return (server: server, uri: original);
  }
}

/// Re-exposes prompts advertised by EXTERNAL MCP servers through CC's own MCP
/// server (PRD 01 feature 4), surfaced to agents as slash commands. Names are
/// namespaced `<server>::<promptName>`; a `prompts/get` re-derives the owning
/// server from the live manager state (no persistent map needed).
class BridgedPromptProvider implements McpPromptProvider {
  /// Creates a [BridgedPromptProvider] over a connection manager.
  BridgedPromptProvider(this._manager);

  final ConnectionManager _manager;

  static const String _separator = '::';

  @override
  Future<List<McpPromptDescriptor>> listPrompts() async {
    return [
      for (final entry in _manager.prompts)
        McpPromptDescriptor(
          name: '${entry.server}$_separator${entry.prompt.name}',
          title: entry.prompt.title,
          description: entry.prompt.description,
          arguments: [
            for (final a in entry.prompt.arguments)
              {
                'name': a.name,
                if (a.description != null) 'description': a.description,
                'required': a.required,
              },
          ],
        ),
    ];
  }

  @override
  Future<McpPromptResult?> getPrompt(
    String name,
    Map<String, String> arguments,
  ) async {
    final idx = name.indexOf(_separator);
    if (idx == -1) {
      return null;
    }
    final server = name.substring(0, idx);
    final promptName = name.substring(idx + _separator.length);
    final result = await _manager.getPrompt(
      server,
      promptName,
      arguments: arguments,
    );
    final messages = (result['messages'] as List?)
            ?.whereType<Map>()
            .map((m) => m.cast<String, dynamic>())
            .toList() ??
        const <Map<String, dynamic>>[];
    return McpPromptResult(
      description: result['description'] as String?,
      messages: messages,
    );
  }
}
