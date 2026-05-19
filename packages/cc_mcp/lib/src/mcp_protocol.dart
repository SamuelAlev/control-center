/// The MCP protocol version this server implements (date-based, per spec).
///
/// Relocated from the app's `app_constants.dart` into cc_mcp so the dispatcher
/// is self-contained and links into the Flutter-free server binary.
const String mcpProtocolVersion = '2024-11-05';
