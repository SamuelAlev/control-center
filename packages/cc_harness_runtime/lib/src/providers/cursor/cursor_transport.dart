import 'package:cc_harness/provider.dart';

/// Cursor AgentService HTTP/2 paths.
abstract final class CursorAgentPaths {
  /// Bidirectional Run stream.
  static const String run = '/agent.v1.AgentService/Run';

  /// Unary model catalog.
  static const String getUsableModels = '/agent.v1.AgentService/GetUsableModels';
}

/// CLI-spoof client version Cursor's AgentService expects.
const String kCursorClientVersion = 'cli-2026.07.23-e383d2b';

/// One inbound Connect frame from a Run stream.
class CursorRunFrame {
  /// Creates a frame.
  const CursorRunFrame({required this.flags, required this.payload});

  /// Connect flags.
  final int flags;

  /// Protobuf (or JSON trailer) payload.
  final List<int> payload;

  /// End-stream trailer.
  bool get isEndStream => (flags & 0x02) != 0;
}

/// An open bidirectional Run stream.
class CursorRunSession {
  /// Creates a session.
  CursorRunSession({
    required this._send,
    required this.frames,
    required this._close,
  });

  final void Function(List<int> proto) _send;
  final Future<void> Function() _close;
  var _closed = false;

  /// Inbound Connect frames.
  final Stream<CursorRunFrame> frames;

  /// Sends an AgentClientMessage protobuf payload (framed by the transport).
  void send(List<int> proto) {
    if (_closed) {
      return;
    }
    _send(proto);
  }

  /// Closes the HTTP/2 stream.
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    await _close();
  }
}

/// Talks to Cursor AgentService over HTTP/2 Connect.
///
/// Implementations must speak HTTP/2; HTTP/1 is rejected by the host (464).
abstract class CursorAgentTransport {
  /// Opens a bidirectional Run stream.
  Future<CursorRunSession> openRun({
    required String accessToken,
    Uri? baseUrl,
  });

  /// Unary GetUsableModels. Returns the protobuf response body (Connect-decoded).
  Future<List<int>> getUsableModels({
    required String accessToken,
    required List<int> request,
    Uri? baseUrl,
  });
}

/// Effort-normalized Cursor model id + RequestedModel parameters.
class CursorWireModel {
  /// Creates a wire model.
  const CursorWireModel({
    required this.modelId,
    this.maxMode = false,
    this.parameters = const [],
  });

  /// Id to put on ModelDetails / RequestedModel.
  final String modelId;

  /// Cursor max-mode flag.
  final bool maxMode;

  /// Extra RequestedModel parameters (`reasoning`, `fast`, …).
  final List<(String id, String value)> parameters;
}

final _openaiFamily = RegExp(r'^(gpt-|o[1-9])');
final _effortSuffix = RegExp(
  r'-(minimal|low|medium|high|xhigh|none|off)(-fast)?$',
);

/// Splits OpenAI-family sibling ids (`gpt-5.6-sol-xhigh-fast`) into a base id
/// plus a `reasoning` parameter. Raw siblings 528384 (`resource_exhausted`).
CursorWireModel normalizeCursorWireModel(
  String id, {
  ReasoningEffort? effort,
}) {
  var modelId = id.trim();
  var maxMode = false;
  if (modelId.endsWith('-max')) {
    maxMode = true;
    modelId = modelId.substring(0, modelId.length - 4);
  }
  if (modelId == 'composer-2.5') {
    return CursorWireModel(
      modelId: modelId,
      maxMode: maxMode,
      parameters: const [('fast', 'false')],
    );
  }

  final match = _effortSuffix.firstMatch(modelId);
  String? suffixEffort;
  var base = modelId;
  if (match != null) {
    final rest = modelId.substring(0, match.start);
    if (_openaiFamily.hasMatch(rest)) {
      suffixEffort = match.group(1);
      base = match.group(2) == '-fast' ? '$rest-fast' : rest;
    }
  }

  String? reasoning;
  if (suffixEffort != null &&
      suffixEffort != 'none' &&
      suffixEffort != 'off' &&
      suffixEffort != 'minimal') {
    reasoning = suffixEffort;
  } else if (effort != null && _openaiFamily.hasMatch(base)) {
    reasoning = switch (effort) {
      ReasoningEffort.minimal => null,
      ReasoningEffort.low => 'low',
      ReasoningEffort.medium => 'medium',
      ReasoningEffort.high => 'high',
      ReasoningEffort.xhigh => 'xhigh',
    };
  }

  return CursorWireModel(
    modelId: base,
    maxMode: maxMode,
    parameters: [
      if (reasoning != null) ('reasoning', reasoning),
    ],
  );
}
