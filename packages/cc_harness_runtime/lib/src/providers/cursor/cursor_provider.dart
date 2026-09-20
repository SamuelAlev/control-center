import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/src/oauth/cursor_oauth.dart';
import 'package:cc_harness_runtime/src/providers/cursor/connect_framing.dart';
import 'package:cc_harness_runtime/src/providers/cursor/cursor_history.dart';
import 'package:cc_harness_runtime/src/providers/cursor/cursor_http2.dart';
import 'package:cc_harness_runtime/src/providers/cursor/cursor_proto.dart';
import 'package:cc_harness_runtime/src/providers/cursor/cursor_transport.dart';

final _resourceExhausted = RegExp(r'resource.?exhausted', caseSensitive: false);

/// Cursor AgentService as an [LlmProviderPort].
///
/// Talks HTTP/2 Connect+protobuf to `api2.cursor.sh`. Tools are advertised
/// over the in-stream `requestContext` handshake as MCP definitions; native
/// Cursor execs (shell/read/write) are declined so the harness loop stays the
/// executor. A new `conversationId` is minted per [complete] so a poisoned
/// conversation cannot stick `resource_exhausted` on later turns.
class CursorProvider implements LlmProviderPort {
  /// Creates a [CursorProvider].
  CursorProvider({
    this._accessToken,
    this._tokenResolver,
    String? baseUrl,
    this._defaultModel = 'auto',
    CursorAgentTransport? transport,
  }) : _baseUrl = Uri.parse(baseUrl ?? CursorOAuth.defaultApiBase),
       _transport = transport ?? const Http2CursorAgentTransport();

  final String? _accessToken;
  final ProviderTokenResolver? _tokenResolver;
  final Uri _baseUrl;
  final String _defaultModel;
  final CursorAgentTransport _transport;

  @override
  String get displayName => 'Cursor';

  @override
  String get defaultModel => _defaultModel;

  Future<String> _bearer({bool force = false}) async {
    if (_tokenResolver != null) {
      return await _tokenResolver(force: force) ?? _accessToken ?? '';
    }
    return _accessToken ?? '';
  }

  @override
  Future<List<ProviderModel>> listModels() async {
    try {
      final token = await _bearer();
      if (token.isEmpty) {
        return const [];
      }
      final payload = await _transport.getUsableModels(
        accessToken: token,
        request: encodeGetUsableModelsRequest(),
        baseUrl: _baseUrl,
      );
      return [
        for (final model in decodeGetUsableModelsResponse(payload))
          ProviderModel(
            id: model.modelId,
            displayName: model.displayName,
            contextWindow: _contextWindowFor(model),
          ),
      ];
    } on Object {
      return const [];
    }
  }

  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema> tools = const [],
    LlmCompleteConfig config = const LlmCompleteConfig(),
  }) async* {
    final token = await _bearer();
    if (token.isEmpty) {
      yield const LlmError(
        'Cursor is not signed in. Connect a Cursor account in Settings.',
        code: 'authentication_error',
      );
      yield const LlmDone(stopReason: LlmStopReason.unknown);
      return;
    }

    final modelId = config.model ?? _defaultModel;
    final wire = normalizeCursorWireModel(modelId, effort: config.effort);
    final packed = packCursorHistory(
      messages,
      systemPrompt: config.systemPrompt,
    );
    final conversationId = _uuidV4();
    final action = packed.liveUserText == null
        ? encodeResumeAction()
        : encodeUserMessageAction(
            text: packed.liveUserText!,
            messageId: _uuidV4(),
          );
    final run = encodeRunRequest(
      conversationState: encodeConversationState(
        rootPromptMessagesJson: packed.blobIds,
      ),
      modelDetails: encodeModelDetails(
        modelId: wire.modelId,
        displayName: modelId,
        maxMode: wire.maxMode,
      ),
      requestedModel: encodeRequestedModel(
        modelId: wire.modelId,
        maxMode: wire.maxMode,
        parameters: wire.parameters,
      ),
      conversationId: conversationId,
      customSystemPrompt: config.systemPrompt,
      action: action,
    );

    final CursorRunSession session;
    try {
      session = await _transport.openRun(
        accessToken: token,
        baseUrl: _baseUrl,
      );
    } on CursorTransportException catch (e) {
      yield _mapTransportError(e);
      yield const LlmDone(stopReason: LlmStopReason.unknown);
      return;
    } on Object catch (e) {
      yield LlmError('Cursor request failed: $e', retryable: true);
      yield const LlmDone(stopReason: LlmStopReason.unknown);
      return;
    }

    final mcpTools = [
      for (final tool in tools)
        CursorMcpTool(
          name: tool.name,
          description: tool.description,
          inputSchema: tool.inputSchema,
        ),
    ];
    final systemRules = [
      if ((config.systemPrompt ?? '').trim().isNotEmpty)
        config.systemPrompt!.trim(),
    ];

    var inputTokens = 0;
    var outputTokens = 0;
    var stopReason = LlmStopReason.endTurn;
    var sawToolUse = false;
    Timer? heartbeat;

    try {
      session.send(encodeRunClientMessage(run));
      heartbeat = Timer.periodic(const Duration(seconds: 5), (_) {
        session.send(encodeClientHeartbeat());
      });

      await for (final frame in session.frames) {
        if (frame.isEndStream) {
          final error = parseConnectEndStreamError(frame.payload);
          if (error != null) {
            yield _mapConnectError(error);
            stopReason = LlmStopReason.unknown;
          }
          break;
        }
        if (frame.payload.isEmpty) {
          continue;
        }
        final message = decodeAgentServerMessage(frame.payload);
        switch (message.kind) {
          case CursorServerKind.interaction:
            final update = message.interaction;
            if (update == null) {
              break;
            }
            if (update.isTextDelta && update.text.isNotEmpty) {
              yield LlmTextDelta(update.text);
            } else if (update.isThinkingDelta && update.text.isNotEmpty) {
              yield LlmThinkingDelta(update.text);
            } else if (update.isTokenDelta) {
              outputTokens = int.tryParse(update.text) ?? outputTokens;
            } else if (update.isTurnEnded) {
              stopReason = sawToolUse
                  ? LlmStopReason.toolUse
                  : LlmStopReason.endTurn;
            } else if (update.isHeartbeat) {
              session.send(encodeClientHeartbeat());
            }
          case CursorServerKind.kv:
            final kv = message.kv;
            if (kv == null) {
              break;
            }
            if (kv.isGet) {
              final data = packed.store[blobIdHex(kv.blobId)] ?? Uint8List(0);
              session.send(
                encodeKvGetBlobResult(id: kv.id, blobData: data),
              );
            } else {
              packed.store[blobIdHex(kv.blobId)] = Uint8List.fromList(
                kv.blobData,
              );
              session.send(encodeKvSetBlobResult(id: kv.id));
            }
          case CursorServerKind.exec:
            final exec = message.exec;
            if (exec == null) {
              break;
            }
            if (exec.isRequestContext) {
              session.send(
                encodeRequestContextReply(
                  id: exec.id,
                  execId: exec.execId,
                  requestContext: encodeRequestContext(
                    systemRules: systemRules,
                    tools: mcpTools,
                  ),
                ),
              );
            } else if (exec.isMcpState) {
              session.send(
                encodeMcpStateEmptyReply(id: exec.id, execId: exec.execId),
              );
            } else if (exec.isMcp) {
              final call = exec.mcp;
              if (call == null) {
                break;
              }
              if (call.approvalOnly) {
                session.send(
                  encodeMcpApprovedReply(id: exec.id, execId: exec.execId),
                );
                break;
              }
              final id = call.toolCallId.isEmpty
                  ? _uuidV4()
                  : normalizeCursorToolCallId(call.toolCallId);
              yield LlmToolUseDelta(
                id: id,
                name: call.toolName.isEmpty ? call.name : call.toolName,
                argumentsJson: jsonEncode(call.args),
              );
              sawToolUse = true;
              stopReason = LlmStopReason.toolUse;
              await session.close();
              break;
            } else if (exec.isNativeExec) {
              session.send(
                encodeExecThrow(
                  id: exec.id,
                  error:
                      'Native Cursor tools are not implemented by this client. '
                      'Use the advertised MCP tools.',
                ),
              );
              session.send(encodeExecStreamClose(id: exec.id));
            } else {
              session.send(
                encodeExecThrow(
                  id: exec.id,
                  error: 'Unknown exec message variant',
                  errorCode: 'unknown_exec_variant',
                ),
              );
              session.send(encodeExecStreamClose(id: exec.id));
            }
          case CursorServerKind.interactionQuery:
            final query = message.interactionQuery;
            if (query == null) {
              break;
            }
            if (query.isAskQuestion || query.caseNumber == 4) {
              session.send(encodeAskQuestionRejected(id: query.id));
            } else {
              session.send(
                encodeInteractionApproved(
                  id: query.id,
                  resultField: query.caseNumber == 0 ? 2 : query.caseNumber,
                ),
              );
            }
          case CursorServerKind.checkpoint:
            if (message.usedTokens > 0) {
              inputTokens = message.usedTokens;
            }
          case CursorServerKind.other:
            break;
        }
      }
    } on CursorTransportException catch (e) {
      yield _mapTransportError(e);
      stopReason = LlmStopReason.unknown;
    } on Object catch (e) {
      yield LlmError('Cursor request failed: $e', retryable: true);
      stopReason = LlmStopReason.unknown;
    } finally {
      heartbeat?.cancel();
      await session.close();
    }

    yield LlmUsage(inputTokens: inputTokens, outputTokens: outputTokens);
    yield LlmDone(stopReason: stopReason);
  }

  static int? _contextWindowFor(CursorUsableModel model) {
    final name = model.displayName ?? '';
    if (RegExp(r'\b1m\b', caseSensitive: false).hasMatch(name) ||
        model.maxMode) {
      return 1000000;
    }
    return 200000;
  }

  static LlmError _mapTransportError(CursorTransportException e) {
    final status = e.statusCode;
    final retryable = status == 429 || (status != null && status >= 500);
    return LlmError(
      e.message,
      code: status == null ? null : 'http_$status',
      retryable: retryable || status == 464,
    );
  }

  static LlmError _mapConnectError(String error) {
    final exhausted = _resourceExhausted.hasMatch(error);
    return LlmError(
      error,
      code: exhausted ? 'resource_exhausted' : 'provider_error',
      retryable: exhausted,
    );
  }
}

String _uuidV4() {
  final rnd = Random.secure();
  final bytes = Uint8List.fromList(
    List<int>.generate(16, (_) => rnd.nextInt(256)),
  );
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hex(int i) => bytes[i].toRadixString(16).padLeft(2, '0');
  return '${hex(0)}${hex(1)}${hex(2)}${hex(3)}-'
      '${hex(4)}${hex(5)}-'
      '${hex(6)}${hex(7)}-'
      '${hex(8)}${hex(9)}-'
      '${hex(10)}${hex(11)}${hex(12)}${hex(13)}${hex(14)}${hex(15)}';
}
