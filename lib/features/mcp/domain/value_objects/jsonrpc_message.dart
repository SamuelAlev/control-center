/// Json rpc request.
class JsonRpcRequest {
  /// Deserializes a [JsonRpcRequest] from a JSON map.
  factory JsonRpcRequest.fromJson(Map<String, dynamic> json) {
    return JsonRpcRequest(
      jsonrpc: json['jsonrpc'] as String? ?? '2.0',
      method: json['method'] as String? ?? '',
      params: json['params'] as Map<String, dynamic>? ?? {},
      id: json['id'],
    );
  }
  /// Creates a new [Json rpc request].
  JsonRpcRequest({
    this.jsonrpc = '2.0',
    required this.method,
    this.params = const {},
    this.id,
  }) : assert(method.isNotEmpty, 'JsonRpcRequest method must not be empty');

  /// JSON-RPC protocol version (usually '2.0').
  final String jsonrpc;
  /// RPC method name.
  final String method;
  /// Named parameters for the RPC call.
  final Map<String, dynamic> params;
  /// Request identifier used to correlate responses.
  final dynamic id;

  /// To json.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'jsonrpc': jsonrpc,
    'method': method,
    'params': params,
    'id': id,
  };

  /// Copy with.
  JsonRpcRequest copyWith({
    String? jsonrpc,
    String? method,
    Map<String, dynamic>? params,
    dynamic id,
    bool removeId = false,
  }) {
    return JsonRpcRequest(
      jsonrpc: jsonrpc ?? this.jsonrpc,
      method: method ?? this.method,
      params: params ?? this.params,
      id: removeId ? null : (id ?? this.id),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JsonRpcRequest &&
          runtimeType == other.runtimeType &&
          jsonrpc == other.jsonrpc &&
          method == other.method &&
          _mapEquals(params, other.params) &&
          id == other.id;

  @override
  int get hashCode =>
      Object.hash(jsonrpc, method, Object.hashAll(params.entries), id);

  @override
  String toString() =>
      'JsonRpcRequest(jsonrpc: $jsonrpc, method: $method, params: $params, id: $id)';
}

/// Json rpc response.
class JsonRpcResponse {
  /// Deserializes a [JsonRpcResponse] from a JSON map.
  factory JsonRpcResponse.fromJson(Map<String, dynamic> json) {
    return JsonRpcResponse(
      jsonrpc: json['jsonrpc'] as String? ?? '2.0',
      result: json['result'] as Map<String, dynamic>? ?? {},
      id: json['id'],
    );
  }
  /// Creates a new [Json rpc response].
  JsonRpcResponse({this.jsonrpc = '2.0', required this.result, this.id})
    : assert(result.isNotEmpty, 'JsonRpcResponse result must not be empty');

  /// JSON-RPC protocol version (usually '2.0').
  final String jsonrpc;
  /// Result payload returned by the method.
  final Map<String, dynamic> result;
  /// Response identifier correlating to the request.
  final dynamic id;

  /// To json.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'jsonrpc': jsonrpc,
    'result': result,
    'id': id,
  };

  /// Copy with.
  JsonRpcResponse copyWith({
    String? jsonrpc,
    Map<String, dynamic>? result,
    dynamic id,
    bool removeId = false,
  }) {
    return JsonRpcResponse(
      jsonrpc: jsonrpc ?? this.jsonrpc,
      result: result ?? this.result,
      id: removeId ? null : (id ?? this.id),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JsonRpcResponse &&
          runtimeType == other.runtimeType &&
          jsonrpc == other.jsonrpc &&
          _mapEquals(result, other.result) &&
          id == other.id;

  @override
  int get hashCode => Object.hash(jsonrpc, Object.hashAll(result.entries), id);

  @override
  String toString() =>
      'JsonRpcResponse(jsonrpc: $jsonrpc, result: $result, id: $id)';
}

/// Json rpc error.
class JsonRpcError {
  /// Deserializes a [JsonRpcError] from a JSON map.
  factory JsonRpcError.fromJson(Map<String, dynamic> json) {
    return JsonRpcError(
      jsonrpc: json['jsonrpc'] as String? ?? '2.0',
      code: json['code'] as int? ?? -1,
      message: json['message'] as String? ?? '',
      data: json['data'],
      id: json['id'],
    );
  }
  /// Creates a new [Json rpc error].
  JsonRpcError({
    this.jsonrpc = '2.0',
    required this.code,
    required this.message,
    this.data,
    this.id,
  }) : assert(message.isNotEmpty, 'JsonRpcError message must not be empty');

  /// JSON-RPC protocol version (usually '2.0').
  final String jsonrpc;
  /// Error code.
  final int code;
  /// Human-readable error message.
  final String message;
  /// Optional additional error data.
  final dynamic data;
  /// Error identifier correlating to the request.
  final dynamic id;

  /// To json.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'jsonrpc': jsonrpc,
    'code': code,
    'message': message,
    'data': data,
    'id': id,
  };

  /// Copy with.
  JsonRpcError copyWith({
    String? jsonrpc,
    int? code,
    String? message,
    dynamic data,
    bool removeData = false,
    dynamic id,
    bool removeId = false,
  }) {
    return JsonRpcError(
      jsonrpc: jsonrpc ?? this.jsonrpc,
      code: code ?? this.code,
      message: message ?? this.message,
      data: removeData ? null : (data ?? this.data),
      id: removeId ? null : (id ?? this.id),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JsonRpcError &&
          runtimeType == other.runtimeType &&
          jsonrpc == other.jsonrpc &&
          code == other.code &&
          message == other.message &&
          data == other.data &&
          id == other.id;

  @override
  int get hashCode => Object.hash(jsonrpc, code, message, data, id);

  @override
  String toString() =>
      'JsonRpcError(jsonrpc: $jsonrpc, code: $code, message: $message, data: $data, id: $id)';
}

/// Json rpc notification.
class JsonRpcNotification {
  /// Deserializes a [JsonRpcNotification] from a JSON map.
  factory JsonRpcNotification.fromJson(Map<String, dynamic> json) {
    return JsonRpcNotification(
      jsonrpc: json['jsonrpc'] as String? ?? '2.0',
      method: json['method'] as String? ?? '',
      params: json['params'] as Map<String, dynamic>? ?? {},
    );
  }
  /// Creates a new [Json rpc notification].
  JsonRpcNotification({
    this.jsonrpc = '2.0',
    required this.method,
    this.params = const {},
  }) : assert(
         method.isNotEmpty,
         'JsonRpcNotification method must not be empty',
       );

  /// JSON-RPC protocol version (usually '2.0').
  final String jsonrpc;
  /// Notification method name.
  final String method;
  /// Named parameters for the notification.
  final Map<String, dynamic> params;

  /// To json.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'jsonrpc': jsonrpc,
    'method': method,
    'params': params,
  };

  /// Copy with.
  JsonRpcNotification copyWith({
    String? jsonrpc,
    String? method,
    Map<String, dynamic>? params,
  }) {
    return JsonRpcNotification(
      jsonrpc: jsonrpc ?? this.jsonrpc,
      method: method ?? this.method,
      params: params ?? this.params,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JsonRpcNotification &&
          runtimeType == other.runtimeType &&
          jsonrpc == other.jsonrpc &&
          method == other.method &&
          _mapEquals(params, other.params);

  @override
  int get hashCode =>
      Object.hash(jsonrpc, method, Object.hashAll(params.entries));

  @override
  String toString() =>
      'JsonRpcNotification(jsonrpc: $jsonrpc, method: $method, params: $params)';
}

bool _mapEquals(Map<dynamic, dynamic> a, Map<dynamic, dynamic> b) {
  if (identical(a, b)) {
    return true;
  }

  if (a.length != b.length) {
    return false;
  }

  for (final key in a.keys) {
    if (!b.containsKey(key)) {
      return false;
    }

    if (a[key] != b[key]) {
      return false;
    }
  }
  return true;
}

