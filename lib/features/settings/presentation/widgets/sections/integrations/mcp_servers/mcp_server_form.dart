import 'package:cc_domain/features/mcp/domain/entities/mcp_server_definition.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_server_draft.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_key_value_pair.dart';
import 'package:flutter/foundation.dart';

/// The write-only values of one kind (environment variables or headers) as
/// the editor holds them: the names already stored, which of those are being
/// replaced or removed, and new name/value pairs.
///
/// Stored values are never read back, so a stored name can only be kept,
/// given a new value, or dropped.
class McpSecretEdits extends ChangeNotifier {
  /// Creates the edits over [stored], the names the server already holds.
  McpSecretEdits(List<String> stored) : stored = List.unmodifiable(stored);

  /// The names the server holds a value for.
  final List<String> stored;

  final Map<String, String> _replacing = {};
  final Set<String> _removed = {};
  List<SettingsKeyValuePair> _added = const [];

  /// Whether [name]'s value is being replaced.
  bool isReplacing(String name) => _replacing.containsKey(name);

  /// Whether [name] will be dropped.
  bool isRemoved(String name) => _removed.contains(name);

  /// The new pairs, in the order typed.
  List<SettingsKeyValuePair> get added => _added;

  /// Opens a new value for [name].
  void replace(String name) {
    _removed.remove(name);
    _replacing[name] = '';
    notifyListeners();
  }

  /// Sets the new value for [name] while it is being replaced.
  void setReplacement(String name, String value) {
    if (_replacing.containsKey(name)) {
      _replacing[name] = value;
    }
  }

  /// Marks [name] to be dropped.
  void remove(String name) {
    _replacing.remove(name);
    _removed.add(name);
    notifyListeners();
  }

  /// Keeps [name] as stored: undoes a replace or a remove.
  void keep(String name) {
    _replacing.remove(name);
    _removed.remove(name);
    notifyListeners();
  }

  /// Replaces the new pairs.
  void setAdded(List<SettingsKeyValuePair> pairs) {
    _added = List.unmodifiable(pairs);
  }

  /// The values to write: replacements that hold a value (an empty one keeps
  /// what is stored) and every named new pair. With [keepStored] false (the
  /// transport changed, so nothing stored carries over) only the new pairs.
  Map<String, String> toSet({required bool keepStored}) => {
    if (keepStored)
      for (final e in _replacing.entries)
        if (e.value.isNotEmpty) e.key: e.value,
    for (final pair in _added)
      if (pair.key.trim().isNotEmpty) pair.key.trim(): pair.value,
  };

  /// The stored names to drop; none when [keepStored] is false.
  Set<String> toRemove({required bool keepStored}) =>
      keepStored ? Set.of(_removed) : const {};

  /// The new names, trimmed, empty ones skipped.
  Iterable<String> get addedNames =>
      _added.map((pair) => pair.key.trim()).where((name) => name.isNotEmpty);
}

/// What the editor found wrong before sending anything; all null/false when
/// the form can be saved.
@immutable
class McpServerFormErrors {
  /// Creates the errors.
  const McpServerFormErrors({
    this.name = false,
    this.command = false,
    this.url = false,
    this.envName,
    this.headerName,
  });

  /// The name is not a valid server name.
  final bool name;

  /// A command server has no command.
  final bool command;

  /// A remote server's URL cannot be dialled.
  final bool url;

  /// The first new environment variable name that is not valid.
  final String? envName;

  /// The first new header name that is not valid or is reserved.
  final String? headerName;

  /// Whether nothing is wrong.
  bool get isEmpty =>
      !name && !command && !url && envName == null && headerName == null;
}

/// The editor's fields as typed.
@immutable
class McpServerFormInput {
  /// Creates the input.
  const McpServerFormInput({
    required this.name,
    required this.transport,
    required this.command,
    required this.argsText,
    required this.url,
    required this.enabled,
    required this.env,
    required this.headers,
  });

  /// The server name.
  final String name;

  /// The transport picked.
  final McpServerTransport transport;

  /// The command (stdio).
  final String command;

  /// The arguments, one per line (stdio).
  final String argsText;

  /// The endpoint (http, sse).
  final String url;

  /// Whether it is dialled.
  final bool enabled;

  /// Environment variable edits (stdio).
  final McpSecretEdits env;

  /// Header edits (http, sse).
  final McpSecretEdits headers;
}

/// Splits the arguments field: one argument per line, blank lines skipped,
/// everything else kept exactly as typed (spaces can matter).
List<String> parseMcpServerArgs(String text) => [
  for (final raw in text.split('\n'))
    if (raw.replaceAll('\r', '').trim().isNotEmpty) raw.replaceAll('\r', ''),
];

/// The arguments as the field shows them.
String formatMcpServerArgs(List<String> args) => args.join('\n');

/// Checks [input] with the same rules the server applies.
McpServerFormErrors validateMcpServerForm(McpServerFormInput input) {
  final stdio = input.transport == McpServerTransport.stdio;
  String? firstBad(Iterable<String> names, bool Function(String) ok) {
    for (final name in names) {
      if (!ok(name)) {
        return name;
      }
    }
    return null;
  }

  return McpServerFormErrors(
    name: !McpServerNames.server.hasMatch(input.name.trim()),
    command: stdio && input.command.trim().isEmpty,
    url: !stdio && !McpServerDefinition.isDialableUrl(input.url),
    envName: stdio
        ? firstBad(input.env.addedNames, McpServerNames.env.hasMatch)
        : null,
    headerName: stdio
        ? null
        : firstBad(input.headers.addedNames, McpServerNames.isAllowedHeader),
  );
}

/// The draft [input] makes of [existing] (null when adding). Only the fields
/// of the picked transport are sent; stored values carry over only when the
/// transport is unchanged, as the server keeps them only then.
McpServerDraft buildMcpServerDraft(
  McpServerFormInput input, {
  required McpServerDefinition? existing,
}) {
  final stdio = input.transport == McpServerTransport.stdio;
  final keepStored = existing != null && existing.transport == input.transport;
  return McpServerDraft(
    id: existing?.id,
    name: input.name.trim(),
    transport: input.transport,
    command: stdio ? input.command.trim() : null,
    args: stdio ? parseMcpServerArgs(input.argsText) : const [],
    url: stdio ? null : input.url.trim(),
    enabled: input.enabled,
    envSet: stdio ? input.env.toSet(keepStored: keepStored) : const {},
    envRemove: stdio ? input.env.toRemove(keepStored: keepStored) : const {},
    headerSet: stdio ? const {} : input.headers.toSet(keepStored: keepStored),
    headerRemove: stdio
        ? const {}
        : input.headers.toRemove(keepStored: keepStored),
  );
}

/// The draft that changes only whether [definition] is dialled: no launch
/// field or stored value changes, so an approval stands.
McpServerDraft mcpServerEnabledDraft(
  McpServerDefinition definition, {
  required bool enabled,
}) => McpServerDraft(
  id: definition.id,
  name: definition.name,
  transport: definition.transport,
  command: definition.command,
  args: definition.args,
  url: definition.url,
  enabled: enabled,
);
