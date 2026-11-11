import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';

/// The spaces of `workspaceId` an agent run may not read: those the person it
/// acts for may not read (a review space of a pull request they cannot see,
/// a space exposing a repository they cannot read).
///
/// `callerConversationId` names the calling run (the attested
/// `caller_conversation_id`; see `McpCallScope.callerConversationKey`). Null
/// when the caller is not a known run: every review space is then withheld.
typedef HiddenSpacesForCaller =
    Future<Set<String>> Function({
      required String workspaceId,
      required String? callerConversationId,
    });

/// The input-schema property a space tool declares so the harness fills in
/// the calling run ([McpCallScope.callerConversationKey]).
const Map<String, dynamic> callerConversationProperty = {
  'type': 'string',
  'description':
      'Set by Control Center to the calling run; any value you pass is '
      'replaced.',
};

/// The calling run named in [arguments], or null when none was attested.
String? callerConversationOf(Map<String, dynamic> arguments) {
  final value = arguments[McpCallScope.callerConversationKey];
  return value is String && value.isNotEmpty ? value : null;
}

/// Whether [spaceId] is withheld from the run calling with [arguments]: a
/// space the person it acts for may not read.
Future<bool> isSpaceHiddenFromCaller(
  HiddenSpacesForCaller hiddenSpaces,
  Map<String, dynamic> arguments, {
  required String workspaceId,
  required String spaceId,
}) async => (await hiddenSpaces(
  workspaceId: workspaceId,
  callerConversationId: callerConversationOf(arguments),
)).contains(spaceId);

/// The refusal a space tool returns for a hidden space.
const String hiddenSpaceRefusal =
    'The person this run acts for cannot read this space: it reviews a pull '
    'request or exposes a repository they cannot read.';
