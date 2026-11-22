import 'package:cc_domain/core/domain/value_objects/script_call_origin.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';

/// What the dispatcher knows about one call besides its arguments.
///
/// Most tools need nothing beyond their arguments, into which the dispatcher
/// has already forced the run's workspace and identity. A tool that acts for
/// the run as a whole (`repl` runs a script under the run's own gate) or that
/// must tell a person where a request came from (`ask_user` called from a
/// script) reads it from here instead.
class McpCallContext {
  /// Creates a context.
  const McpCallContext({this.scope, this.toolUseId, this.origin});

  /// The transport-derived scope: the run's attested grant, or null for a
  /// caller that proved no run.
  final McpCallScope? scope;

  /// The adapter's own id for this call, when the request carried one
  /// (Claude Code sends `_meta["claudecode/toolUseId"]`). It is the id the
  /// run's transcript knows the call by. Null when the adapter sends none,
  /// and for a nested call.
  final String? toolUseId;

  /// Set when a code mode script made this call: the `repl` call and the
  /// execution it belongs to.
  final ScriptCallOrigin? origin;
}

/// An [McpTool] that is handed the [McpCallContext] of each call.
///
/// The dispatcher calls [callScoped] instead of [McpTool.call]. Every other
/// host (the harness bridge, tests) reaches [run], which runs the tool with
/// an empty context.
abstract class McpScopedTool extends McpTool {
  /// Runs the tool with [context]. Like [McpTool.call], a throw becomes an
  /// error result.
  Future<CallResult> callScoped(
    Map<String, dynamic> arguments,
    McpCallContext context, {
    Future<void>? abandoned,
  }) async {
    try {
      return await runScoped(arguments, context, abandoned: abandoned);
    } catch (e) {
      return CallResult.error('$e');
    }
  }

  /// Runs the tool with [context]. [abandoned] completes when the caller
  /// stops waiting.
  Future<CallResult> runScoped(
    Map<String, dynamic> arguments,
    McpCallContext context, {
    Future<void>? abandoned,
  });

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) =>
      runScoped(arguments, const McpCallContext());

  @override
  Future<CallResult> runUntilAbandoned(
    Map<String, dynamic> arguments,
    Future<void> abandoned,
  ) => runScoped(arguments, const McpCallContext(), abandoned: abandoned);
}
