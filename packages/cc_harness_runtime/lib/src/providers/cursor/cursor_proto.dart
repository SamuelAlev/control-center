import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_harness_runtime/src/providers/cursor/protobuf.dart';

/// Subset of `agent.v1` messages used by the Cursor harness provider.
///
/// Field numbers match Cursor's AgentService proto as reverse-engineered by
/// oh-my-pi. Unknown fields are skipped on decode.

/// AgentClientMessage.clientHeartbeat (field 7) — empty payload.
Uint8List encodeClientHeartbeat() {
  final heartbeat = ProtoWriter().take();
  return (ProtoWriter()..message(7, heartbeat)).take();
}

/// AgentClientMessage.runRequest wrapping [runRequest].
Uint8List encodeRunClientMessage(List<int> runRequest) =>
    (ProtoWriter()..message(1, runRequest)).take();

/// AgentRunRequest: conversationState + modelDetails + requestedModel +
/// conversationId + optional customSystemPrompt.
Uint8List encodeRunRequest({
  required List<int> conversationState,
  required List<int> modelDetails,
  required List<int> requestedModel,
  required String conversationId,
  String? customSystemPrompt,
  List<int>? action,
}) {
  final w = ProtoWriter()
    ..message(1, conversationState)
    ..message(3, modelDetails)
    ..string(5, conversationId)
    ..message(9, requestedModel);
  if (action != null) {
    w.message(2, action);
  }
  if (customSystemPrompt != null && customSystemPrompt.isNotEmpty) {
    w.string(8, customSystemPrompt);
  }
  return w.take();
}

/// ConversationStateStructure with blob-id history.
Uint8List encodeConversationState({
  required List<Uint8List> rootPromptMessagesJson,
}) {
  final w = ProtoWriter();
  for (final id in rootPromptMessagesJson) {
    w.bytes(1, id);
  }
  return w.take();
}

/// ModelDetails with a model id and optional max-mode flag.
Uint8List encodeModelDetails({
  required String modelId,
  String? displayName,
  bool maxMode = false,
}) {
  final w = ProtoWriter()..string(1, modelId);
  if (displayName != null && displayName.isNotEmpty) {
    w.string(4, displayName);
  }
  w.boolean(7, maxMode);
  return w.take();
}

/// RequestedModel with optional reasoning parameters.
Uint8List encodeRequestedModel({
  required String modelId,
  bool maxMode = false,
  List<(String id, String value)> parameters = const [],
}) {
  final w = ProtoWriter()
    ..string(1, modelId)
    ..boolean(2, maxMode);
  for (final (id, value) in parameters) {
    w.message(3, (ProtoWriter()
          ..string(1, id)
          ..string(2, value))
        .take());
  }
  return w.take();
}

/// ConversationAction.userMessageAction wrapping a UserMessage.
Uint8List encodeUserMessageAction({
  required String text,
  required String messageId,
}) {
  final user = (ProtoWriter()
        ..string(1, text)
        ..string(2, messageId))
      .take();
  final action = (ProtoWriter()..message(1, user)).take();
  return (ProtoWriter()..message(1, action)).take();
}

/// ConversationAction.resumeAction (empty).
Uint8List encodeResumeAction() {
  final resume = ProtoWriter().take();
  return (ProtoWriter()..message(2, resume)).take();
}

/// AgentClientMessage.kvClientMessage answering a blob get.
Uint8List encodeKvGetBlobResult({
  required int id,
  required List<int> blobData,
}) {
  final result = (ProtoWriter()..bytes(1, blobData)).take();
  final kv = (ProtoWriter()
        ..uint32(1, id)
        ..message(2, result))
      .take();
  return (ProtoWriter()..message(3, kv)).take();
}

/// AgentClientMessage.kvClientMessage acknowledging a blob set.
Uint8List encodeKvSetBlobResult({required int id}) {
  final result = ProtoWriter().take();
  final kv = (ProtoWriter()
        ..uint32(1, id)
        ..message(3, result))
      .take();
  return (ProtoWriter()..message(3, kv)).take();
}

Uint8List _encodeExecClient({
  required int id,
  required String execId,
  required int resultField,
  required List<int> result,
}) {
  final exec = ProtoWriter()..uint32(1, id);
  if (execId.isNotEmpty) {
    exec.string(15, execId);
  }
  exec.message(resultField, result);
  return (ProtoWriter()..message(2, exec.take())).take();
}

/// AgentClientMessage.execClientMessage with a requestContextResult.
Uint8List encodeRequestContextReply({
  required int id,
  String execId = '',
  required List<int> requestContext,
}) {
  final success = (ProtoWriter()..message(1, requestContext)).take();
  final result = (ProtoWriter()..message(1, success)).take();
  return _encodeExecClient(
    id: id,
    execId: execId,
    resultField: 10,
    result: result,
  );
}

/// MCP approval-probe reply (`McpResult.approved`).
Uint8List encodeMcpApprovedReply({required int id, String execId = ''}) {
  final approved = ProtoWriter().take();
  final result = (ProtoWriter()..message(7, approved)).take();
  return _encodeExecClient(
    id: id,
    execId: execId,
    resultField: 11,
    result: result,
  );
}

/// Empty MCP-state listing (tools already live in requestContext).
Uint8List encodeMcpStateEmptyReply({required int id, String execId = ''}) {
  final success = ProtoWriter().take();
  final result = (ProtoWriter()..message(1, success)).take();
  return _encodeExecClient(
    id: id,
    execId: execId,
    resultField: 36,
    result: result,
  );
}

/// Approve a hosted interaction query (web search / fetch / Exa).
Uint8List encodeInteractionApproved({
  required int id,
  required int resultField,
}) {
  final approved = ProtoWriter().take();
  final inner = (ProtoWriter()..message(1, approved)).take();
  final response = (ProtoWriter()
        ..uint32(1, id)
        ..message(resultField, inner))
      .take();
  return (ProtoWriter()..message(6, response)).take();
}

/// Reject an interactive question Cursor cannot ask this client.
Uint8List encodeAskQuestionRejected({
  required int id,
  String reason = 'Interactive questions are not implemented by this client',
}) {
  final rejected = (ProtoWriter()..string(1, reason)).take();
  final result = (ProtoWriter()..message(3, rejected)).take();
  final response = (ProtoWriter()..message(1, result)).take();
  final interaction = (ProtoWriter()
        ..uint32(1, id)
        ..message(3, response))
      .take();
  return (ProtoWriter()..message(6, interaction)).take();
}

/// RequestContext: global rules + MCP tool definitions.
Uint8List encodeRequestContext({
  required List<String> systemRules,
  required List<CursorMcpTool> tools,
}) {
  final w = ProtoWriter();
  for (var i = 0; i < systemRules.length; i++) {
    w.message(2, encodeCursorRule(systemRules[i], index: i));
  }
  for (final tool in tools) {
    w.message(7, encodeMcpToolDefinition(tool));
  }
  return w.take();
}

/// A global always-apply Cursor rule.
Uint8List encodeCursorRule(String content, {int index = 0}) {
  final global = ProtoWriter().take();
  final type = (ProtoWriter()..message(1, global)).take();
  return (ProtoWriter()
        ..string(1, '/cc-harness/system-prompt/$index.mdc')
        ..string(2, content)
        ..message(3, type)
        ..int32(4, 2))
      .take();
}

/// One MCP tool advertised in requestContext.
class CursorMcpTool {
  /// Creates a tool definition.
  const CursorMcpTool({
    required this.name,
    required this.description,
    required this.inputSchema,
  });

  /// Tool name.
  final String name;

  /// Description shown to the model.
  final String description;

  /// JSON Schema object.
  final Map<String, dynamic> inputSchema;
}

/// McpToolDefinition encoding.
Uint8List encodeMcpToolDefinition(CursorMcpTool tool) {
  final schemaJson = jsonEncode(tool.inputSchema);
  final schemaBytes = utf8.encode(schemaJson);
  return (ProtoWriter()
        ..string(1, tool.name)
        ..string(2, tool.description)
        ..bytes(3, schemaBytes)
        ..string(4, 'cc-harness')
        ..string(5, tool.name)
        ..string(6, schemaJson))
      .take();
}

/// AgentClientMessage.execClientControlMessage.throw.
Uint8List encodeExecThrow({
  required int id,
  required String error,
  String errorCode = 'exec_variant_unsupported',
}) {
  final thrown = (ProtoWriter()
        ..uint32(1, id)
        ..string(2, error)
        ..string(4, errorCode))
      .take();
  final control = (ProtoWriter()..message(2, thrown)).take();
  return (ProtoWriter()..message(5, control)).take();
}

/// AgentClientMessage.execClientControlMessage.streamClose.
Uint8List encodeExecStreamClose({required int id}) {
  final close = (ProtoWriter()..uint32(1, id)).take();
  final control = (ProtoWriter()..message(1, close)).take();
  return (ProtoWriter()..message(5, control)).take();
}

/// Empty GetUsableModelsRequest.
Uint8List encodeGetUsableModelsRequest() => ProtoWriter().take();

/// A model advertised by GetUsableModels.
class CursorUsableModel {
  /// Creates a usable-model row.
  const CursorUsableModel({
    required this.modelId,
    this.displayName,
    this.supportsThinking = false,
    this.maxMode = false,
  });

  /// Provider-native model id.
  final String modelId;

  /// Friendly name, when present.
  final String? displayName;

  /// Whether the catalog advertised thinking details.
  final bool supportsThinking;

  /// Whether max-mode is on by default.
  final bool maxMode;
}

/// Parses GetUsableModelsResponse.
List<CursorUsableModel> decodeGetUsableModelsResponse(List<int> payload) {
  final fields = ProtoReader(payload).collect();
  final out = <CursorUsableModel>[];
  for (final model in fields[1] ?? const <ProtoField>[]) {
    final inner = model.asMessage.collect();
    final id = protoString(inner, 1);
    if (id.isEmpty) {
      continue;
    }
    final display = protoString(inner, 4);
    out.add(
      CursorUsableModel(
        modelId: id,
        displayName: display.isEmpty ? protoString(inner, 3) : display,
        supportsThinking: inner.containsKey(2),
        maxMode: protoVarint(inner, 7) != 0,
      ),
    );
  }
  return out;
}

/// Kind of inbound AgentServerMessage.
enum CursorServerKind {
  /// Interaction text/thinking/turn/token updates.
  interaction,

  /// Exec handshake (tools, requestContext, native tools).
  exec,

  /// Blob store get/set.
  kv,

  /// Conversation checkpoint (ignored except for usage).
  checkpoint,

  /// Permission / hosted-search query that must be answered in-band.
  interactionQuery,

  /// Anything else.
  other,
}

/// A decoded inbound AgentServerMessage.
class CursorServerMessage {
  /// Creates a decoded server message.
  const CursorServerMessage({
    required this.kind,
    this.interaction,
    this.exec,
    this.kv,
    this.interactionQuery,
    this.usedTokens = 0,
  });

  /// Discriminator.
  final CursorServerKind kind;

  /// Interaction update, when [kind] is [CursorServerKind.interaction].
  final CursorInteractionUpdate? interaction;

  /// Exec frame, when [kind] is [CursorServerKind.exec].
  final CursorExecMessage? exec;

  /// KV frame, when [kind] is [CursorServerKind.kv].
  final CursorKvMessage? kv;

  /// Interaction query, when [kind] is [CursorServerKind.interactionQuery].
  final CursorInteractionQuery? interactionQuery;

  /// Token count from a conversation checkpoint, when present.
  final int usedTokens;
}

/// A decoded `interactionQuery` (hosted search / fetch / ask-question).
class CursorInteractionQuery {
  /// Creates a query.
  const CursorInteractionQuery({required this.id, required this.caseNumber});

  /// Correlation id the response must echo.
  final int id;

  /// Field number of the query oneof (2 = web search, 3 = ask, 9 = web fetch).
  final int caseNumber;

  /// Hosted web search.
  bool get isWebSearch => caseNumber == 2;

  /// Interactive question (unsupported here).
  bool get isAskQuestion => caseNumber == 3;

  /// Hosted Exa search.
  bool get isExaSearch => caseNumber == 5;

  /// Hosted Exa fetch.
  bool get isExaFetch => caseNumber == 6;

  /// Hosted web fetch.
  bool get isWebFetch => caseNumber == 9;
}

/// InteractionUpdate oneof.
class CursorInteractionUpdate {
  /// Creates an interaction update.
  const CursorInteractionUpdate({
    required this.caseNumber,
    this.text = '',
  });

  /// Field number of the oneof variant.
  final int caseNumber;

  /// Text for textDelta (1) or thinkingDelta (4).
  final String text;

  /// `textDelta`.
  bool get isTextDelta => caseNumber == 1;

  /// `thinkingDelta`.
  bool get isThinkingDelta => caseNumber == 4;

  /// `tokenDelta`.
  bool get isTokenDelta => caseNumber == 8;

  /// `turnEnded`.
  bool get isTurnEnded => caseNumber == 14;

  /// `heartbeat`.
  bool get isHeartbeat => caseNumber == 13;
}

/// ExecServerMessage.
class CursorExecMessage {
  /// Creates an exec frame.
  const CursorExecMessage({
    required this.id,
    required this.execId,
    required this.caseNumber,
    this.mcp,
  });

  /// Correlation id.
  final int id;

  /// Opaque exec id.
  final String execId;

  /// Field number of the args oneof.
  final int caseNumber;

  /// Decoded MCP call, when [isMcp].
  final CursorMcpCall? mcp;

  /// `requestContextArgs`.
  bool get isRequestContext => caseNumber == 10;

  /// `mcpArgs`.
  bool get isMcp => caseNumber == 11;

  /// `mcpStateExecArgs` — list advertised MCP servers.
  bool get isMcpState => caseNumber == 36;

  /// Native shell/read/write/etc — must be declined.
  bool get isNativeExec =>
      !isRequestContext && !isMcp && !isMcpState && caseNumber != 0;
}

/// A decoded MCP tool call.
class CursorMcpCall {
  /// Creates an MCP call.
  const CursorMcpCall({
    required this.name,
    required this.toolName,
    required this.toolCallId,
    required this.args,
    this.approvalOnly = false,
  });

  /// MCP tool alias.
  final String name;

  /// Tool name the model asked for.
  final String toolName;

  /// Call id to pair with the result.
  final String toolCallId;

  /// Decoded JSON arguments.
  final Map<String, dynamic> args;

  /// Approval probe — must not run the tool.
  final bool approvalOnly;
}

/// KvServerMessage.
class CursorKvMessage {
  /// Creates a KV frame.
  const CursorKvMessage({
    required this.id,
    required this.isGet,
    required this.blobId,
    this.blobData = const [],
  });

  /// Correlation id.
  final int id;

  /// True for getBlobArgs, false for setBlobArgs.
  final bool isGet;

  /// Blob id (SHA-256 bytes).
  final Uint8List blobId;

  /// Blob payload on set.
  final List<int> blobData;
}

/// Decodes one AgentServerMessage payload.
CursorServerMessage decodeAgentServerMessage(List<int> payload) {
  final fields = ProtoReader(payload).collect();
  if (fields.containsKey(1)) {
    return CursorServerMessage(
      kind: CursorServerKind.interaction,
      interaction: _decodeInteraction(fields[1]!.first.bytesValue),
    );
  }
  if (fields.containsKey(2)) {
    return CursorServerMessage(
      kind: CursorServerKind.exec,
      exec: _decodeExec(fields[2]!.first.bytesValue),
    );
  }
  if (fields.containsKey(4)) {
    return CursorServerMessage(
      kind: CursorServerKind.kv,
      kv: _decodeKv(fields[4]!.first.bytesValue),
    );
  }
  if (fields.containsKey(7)) {
    return CursorServerMessage(
      kind: CursorServerKind.interactionQuery,
      interactionQuery: _decodeInteractionQuery(fields[7]!.first.bytesValue),
    );
  }
  if (fields.containsKey(3)) {
    final checkpoint = ProtoReader(fields[3]!.first.bytesValue).collect();
    final tokenDetails = checkpoint[5];
    var used = 0;
    if (tokenDetails != null && tokenDetails.isNotEmpty) {
      used = protoVarint(tokenDetails.first.asMessage.collect(), 1);
    }
    return CursorServerMessage(
      kind: CursorServerKind.checkpoint,
      usedTokens: used,
    );
  }
  return const CursorServerMessage(kind: CursorServerKind.other);
}

CursorInteractionUpdate _decodeInteraction(List<int> payload) {
  final fields = ProtoReader(payload).collect();
  for (final entry in fields.entries) {
    final data = entry.value.first;
    if (data.wire != ProtoWire.bytes && data.wire != ProtoWire.varint) {
      continue;
    }
    var text = '';
    if (data.wire == ProtoWire.bytes) {
      final inner = data.asMessage.collect();
      text = protoString(inner, 1);
      if (entry.key == 8) {
        // tokenDelta.tokens is an int32 at field 1.
        text = protoVarint(inner, 1).toString();
      }
    }
    return CursorInteractionUpdate(caseNumber: entry.key, text: text);
  }
  return const CursorInteractionUpdate(caseNumber: 0);
}

CursorExecMessage _decodeExec(List<int> payload) {
  final fields = ProtoReader(payload).collect();
  final id = protoVarint(fields, 1);
  final execId = protoString(fields, 15);
  var caseNumber = 0;
  CursorMcpCall? mcp;
  for (final entry in fields.entries) {
    if (entry.key == 1 || entry.key == 15 || entry.key == 19 || entry.key == 55) {
      continue;
    }
    caseNumber = entry.key;
    if (entry.key == 11) {
      mcp = _decodeMcpArgs(entry.value.first.bytesValue);
    }
    break;
  }
  return CursorExecMessage(
    id: id,
    execId: execId,
    caseNumber: caseNumber,
    mcp: mcp,
  );
}

CursorMcpCall _decodeMcpArgs(List<int> payload) {
  final fields = ProtoReader(payload).collect();
  final name = protoString(fields, 1);
  final toolCallId = protoString(fields, 3);
  final toolName = protoString(fields, 5);
  final rawArgs = protoMapStringBytes(fields, 2);
  final args = <String, dynamic>{};
  rawArgs.forEach((key, value) {
    args[key] = _decodeMcpArgValue(value);
  });
  return CursorMcpCall(
    name: name,
    toolName: toolName.isEmpty ? name : toolName,
    toolCallId: toolCallId,
    args: args,
    approvalOnly: protoVarint(fields, 7) != 0,
  );
}

CursorInteractionQuery _decodeInteractionQuery(List<int> payload) {
  final fields = ProtoReader(payload).collect();
  final id = protoVarint(fields, 1);
  var caseNumber = 0;
  for (final entry in fields.entries) {
    if (entry.key == 1) {
      continue;
    }
    caseNumber = entry.key;
    break;
  }
  return CursorInteractionQuery(id: id, caseNumber: caseNumber);
}

Object? _decodeMcpArgValue(Uint8List value) {
  try {
    return jsonDecode(utf8.decode(value));
  } on Object {
    return utf8.decode(value, allowMalformed: true);
  }
}

CursorKvMessage _decodeKv(List<int> payload) {
  final fields = ProtoReader(payload).collect();
  final id = protoVarint(fields, 1);
  if (fields.containsKey(2)) {
    final args = fields[2]!.first.asMessage.collect();
    return CursorKvMessage(
      id: id,
      isGet: true,
      blobId: protoBytes(args, 1),
    );
  }
  final args = fields[3]?.first.asMessage.collect() ?? const {};
  return CursorKvMessage(
    id: id,
    isGet: false,
    blobId: protoBytes(args, 1),
    blobData: protoBytes(args, 2),
  );
}
