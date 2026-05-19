import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_mcp/src/tools/read/handlers/agent_protocol_handler.dart';
import 'package:cc_mcp/src/tools/read/handlers/artifact_protocol_handler.dart';
import 'package:cc_mcp/src/tools/read/handlers/gh_protocol_handler.dart';
import 'package:cc_mcp/src/tools/read/handlers/issue_protocol_handler.dart';
import 'package:cc_mcp/src/tools/read/handlers/local_protocol_handler.dart';
import 'package:cc_mcp/src/tools/read/handlers/mcp_protocol_handler.dart';
import 'package:cc_mcp/src/tools/read/handlers/memory_protocol_handler.dart';
import 'package:cc_mcp/src/tools/read/handlers/pr_protocol_handler.dart';
import 'package:cc_mcp/src/tools/read/handlers/rule_protocol_handler.dart';
import 'package:cc_mcp/src/tools/read/handlers/skill_protocol_handler.dart';
import 'package:cc_mcp/src/tools/read/internal_url.dart';

/// Per-read invocation context (workspace scope, etc.).
class ReadContext {
  /// Creates a [ReadContext].
  const ReadContext({this.workspaceId, this.conversationId});
  /// Optional workspace scope for memory://, file://, skill://, rule://, local:// URLs.
  final String? workspaceId;
  /// Optional conversation scope for local:// plan artifacts.
  final String? conversationId;
}

/// Dispatches a parsed [InternalUrl] to the right protocol handler.
class InternalUrlRouter {
  /// Creates an [InternalUrlRouter].
  InternalUrlRouter({
    required PrProtocolHandler pr,
    required IssueProtocolHandler issue,
    required GhProtocolHandler gh,
    this.skill,
    this.rule,
    this.local,
    this.agent,
    this.artifact,
    this.memory,
    this.mcp,
  })  : _pr = pr,
        _issue = issue,
        _gh = gh;

  final PrProtocolHandler _pr;
  final IssueProtocolHandler _issue;
  final GhProtocolHandler _gh;
  /// Handler for `skill://` URLs.
  final SkillProtocolHandler? skill;
  /// Handler for `rule://` URLs.
  final RuleProtocolHandler? rule;
  /// Handler for `local://` URLs.
  final LocalProtocolHandler? local;
  /// Handler for `agent://` URLs.
  final AgentProtocolHandler? agent;
  /// Handler for `artifact://` URLs.
  final ArtifactProtocolHandler? artifact;
  /// Handler for `memory://` URLs.
  final MemoryProtocolHandler? memory;
  /// Handler for `mcp://` URLs.
  final McpProtocolHandler? mcp;

  /// Routes [url] to the matching handler.
  Future<CallResult> dispatch(InternalUrl url, ReadContext context) async {
    switch (url) {
      case PrUrl():
        return _pr.handle(url, context);
      case IssueUrl():
        return _issue.handle(url, context);
      case GhBlobUrl():
        return _gh.handle(url, context);
      case MemoryUrl():
        if (memory == null) {
          return CallResult.error(
            'memory:// is not yet implemented in this build',
          );
        }
        return memory!.handle(url, context);
      case FileUrl():
        return CallResult.error(
          'file:// is not yet implemented in this build',
        );
      case SkillUrl():
        if (skill == null) {
          return CallResult.error(
            'skill:// handler not configured in this build',
          );
        }
        return skill!.handle(url, context);
      case RuleUrl():
        if (rule == null) {
          return CallResult.error(
            'rule:// handler not configured in this build',
          );
        }
        return rule!.handle(url, context);
      case LocalUrl():
        if (local == null) {
          return CallResult.error(
            'local:// handler not configured in this build',
          );
        }
        return local!.handle(url, context);
      case AgentUrl():
        if (agent == null) {
          return CallResult.error(
            'agent:// handler not configured in this build',
          );
        }
        return agent!.handle(url, context);
      case ArtifactUrl():
        if (artifact == null) {
          return CallResult.error(
            'artifact:// handler not configured in this build',
          );
        }
        return artifact!.handle(url, context);
      case McpUrl():
        if (mcp == null) {
          return CallResult.error(
            'mcp:// handler not configured in this build',
          );
        }
        return mcp!.handle(url, context);
    }
  }
}
