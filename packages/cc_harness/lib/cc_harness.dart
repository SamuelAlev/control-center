/// The Control Center harness kernel — curated facade.
///
/// This is the small, stable surface most consumers need: the loop and its
/// events, the message/tool/provider contracts, credentials, slash commands,
/// and cancellation. It is deliberately NOT a dump of every kernel symbol —
/// an audited ratchet test holds it at ~40 symbols. The long tail lives in
/// the topic entrypoints (`loop.dart`, `provider.dart`, `tools.dart`,
/// `context.dart`, `messages.dart`, `slash_command.dart`, `cancellation.dart`);
/// deep `src/` imports from outside this package are forbidden by the same
/// ratchet. Every topic named here must exist as a file — a barrel that
/// advertises a surface it does not have is a documentation lie agents read as
/// ground truth, so a ratchet test asserts the list.
library;

export 'src/cancellation_token.dart'
    show CancellationToken, CancellationTokenSource;
export 'src/loop/agent_loop.dart'
    show
        AgentLoop,
        AgentLoopConfig,
        AgentLoopEvent,
        HarnessBudget,
        LoopDone,
        LoopDoneReason,
        LoopError,
        LoopTextDelta,
        ToolApprovalCallback,
        ToolGateDecision;
export 'src/loop/agent_loop_runner.dart' show AgentLoopRunner;
export 'src/loop/completion_contract.dart'
    show CompletionContract, ContractProbe;
export 'src/messages.dart'
    show HarnessContentBlock, HarnessMessage, HarnessRole, HarnessTextBlock;
export 'src/provider/harness_providers.dart'
    show HarnessProviderMeta, harnessProviderMetas, harnessSupportedProviderIds;
export 'src/provider/llm_provider_port.dart'
    show
        LlmCompleteConfig,
        LlmProviderPort,
        LlmToolSchema,
        LlmUsage,
        ProviderModel;
export 'src/provider/provider_credential.dart'
    show HarnessAuthMethod, ProviderCredential, ProviderCredentialStore;
export 'src/provider/reasoning_effort.dart' show ReasoningEffort;
export 'src/slash_command.dart'
    show ParsedSlashCommand, harnessBuiltinCommands, parseSlashCommand;
export 'src/tools/action_class.dart' show ActionClass, ActionDecisionDefault;
export 'src/tools/tool.dart'
    show HarnessTool, HarnessToolContext, HarnessToolResult, ToolApprovalTier;
export 'src/tools/tool_registry.dart' show HarnessToolRegistry;
export 'src/tools/tool_surface.dart' show ToolSurfaceReport, ToolSurfaceSpec;
