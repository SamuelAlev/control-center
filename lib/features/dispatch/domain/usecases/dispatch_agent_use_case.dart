import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/ports/conversation_mode_resolver.dart';
import 'package:control_center/core/domain/repositories/agent_repository.dart';
import 'package:control_center/core/domain/value_objects/app_locale.dart';
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/core/domain/value_objects/wake_context.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/dispatch/domain/prompts/mode_prompts.dart';
import 'package:control_center/features/dispatch/domain/usecases/build_agent_prompt_use_case.dart';
import 'package:control_center/features/dispatch/domain/usecases/build_conversation_context_use_case.dart';
import 'package:control_center/features/dispatch/domain/usecases/build_memory_context_use_case.dart';
import 'package:control_center/features/settings/domain/entities/adapter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Locale;

class PreparedDispatch {
  const PreparedDispatch({
    required this.effectivePrompt,
    required this.effectiveConversationId,
    required this.agent,
    required this.mode,
    required this.resolvedAdapterId,
    required this.cliName,
  });

  final String effectivePrompt;
  final String? effectiveConversationId;
  final Agent? agent;
  final ConversationMode mode;
  final String? resolvedAdapterId;
  final String cliName;
}

class DispatchAgentUseCase {
  DispatchAgentUseCase({
    required AgentRepository agentRepo,
    BuildMemoryContextUseCase? memoryContextUseCase,
    BuildConversationContextUseCase? conversationContextUseCase,
    ConversationModeResolver? modeResolver,
    Locale? locale,
  })  : _agentRepo = agentRepo,
        _memoryContextUseCase = memoryContextUseCase,
        _conversationContextUseCase = conversationContextUseCase,
        _modeResolver = modeResolver,
        _locale = locale;

  final AgentRepository _agentRepo;
  final BuildMemoryContextUseCase? _memoryContextUseCase;
  final BuildConversationContextUseCase? _conversationContextUseCase;
  final ConversationModeResolver? _modeResolver;
  final Locale? _locale;
  final _buildPrompt = const BuildAgentPromptUseCase();

  void _log(String message) {
    if (kDebugMode) {
      AppLog.i('DispatchAgentUseCase', message);
    }
  }

  Future<PreparedDispatch> execute({
    required String agentId,
    required String prompt,
    String? channelId,
    String? conversationId,
    String? adapterId,
    String? workingDirectory,
    WakeContext? wakeContext,
    MentionContext? mentionContext,
  }) async {
    final agent = await _agentRepo.getById(agentId);
    final resolvedAdapterId = adapterId ?? agent?.adapterId;
    final resolvedAdapter = predefinedAdapters
        .where((a) => a.id == resolvedAdapterId)
        .firstOrNull;
    final cliName = resolvedAdapter?.cliName ?? 'pi';

    final effectiveConversationId = conversationId ?? channelId;

    final mode = await _modeResolver?.resolveForConversation(channelId) ??
        ConversationMode.chat;

    final effectivePrompt = await _buildEffectivePrompt(
      prompt: prompt,
      agent: agent,
      channelId: channelId,
      mode: mode,
      workingDirectory: workingDirectory,
      mentionContext: mentionContext,
    );

    return PreparedDispatch(
      effectivePrompt: effectivePrompt,
      effectiveConversationId: effectiveConversationId,
      agent: agent,
      mode: mode,
      resolvedAdapterId: resolvedAdapterId,
      cliName: cliName,
    );
  }

  Future<String> _buildEffectivePrompt({
    required String prompt,
    required Agent? agent,
    String? channelId,
    ConversationMode mode = ConversationMode.chat,
    String? workingDirectory,
    MentionContext? mentionContext,
  }) async {
    // The agent is the authority for its workspace (Agent.workspaceId is never
    // null), so memory is scoped to the agent's own workspace whenever the
    // agent is known — no more "skipped because workspaceId was null".
    final agentId = agent?.id;
    String? memoryContext;
    if (_memoryContextUseCase == null) {
      _log('Memory context: skipped (use case not wired)');
    } else if (agent == null) {
      _log('Memory context: skipped (agent not found)');
    } else {
      final workspaceId = agent.workspaceId;
      try {
        memoryContext = await _memoryContextUseCase.execute(
          workspaceId: workspaceId,
          agentId: agent.id,
          taskDescription: prompt,
        );
        if (memoryContext.isEmpty) {
          _log('Memory context: returned empty for '
              'workspace=$workspaceId agent=${agent.id}');
        } else {
          _log('Memory context: ${memoryContext.length} chars loaded for '
              'workspace=$workspaceId agent=${agent.id}');
        }
      } catch (e, st) {
        _log('Memory context: build failed — $e\n$st');
      }
    }

    String? conversationContext;
    if (_conversationContextUseCase == null || channelId == null || agentId == null) {
      _log('Conversation context: skipped');
    } else {
      try {
        // Cap the eager verbatim window so dispatch stays small/fast and prompt
        // prefixes stay stable. Older history is retrieved on-demand via the
        // get_channel_messages MCP tool, and the use case still surfaces
        // semantically-relevant older messages. Without a cap this was up to
        // ~2 MB (contextSize * 2, default 1 MB).
        const maxConversationChars = 50000;
        final contextSize = agent?.contextSize ?? 1000000;
        final characterBudget = (contextSize * 2).clamp(0, maxConversationChars);
        conversationContext = await _conversationContextUseCase.execute(
          channelId: channelId,
          selfAgentId: agentId,
          selfAgentName: agent?.name ?? agentId,
          taskDescription: prompt,
          characterBudget: characterBudget,
        );
        if (conversationContext.isEmpty) {
          _log('Conversation context: empty');
        } else {
          _log('Conversation context: ${conversationContext.length} chars');
        }
      } catch (e, st) {
        _log('Conversation context: build failed — $e\n$st');
      }
    }

    final modeContext = mode == ConversationMode.plan
        ? ModePromptContext(
            planGoal: prompt,
            plansDirAbsolutePath: workingDirectory == null
                ? null
                : '$workingDirectory/plans',
          )
        : null;

    return _buildPrompt.execute(
      prompt: prompt,
      agent: agent,
      memoryContext: memoryContext,
      conversationContext: conversationContext,
      mode: mode,
      modeContext: modeContext,
      mentionContext: mentionContext,
      locale: _locale != null ? AppLocale(_locale.languageCode) : null,
    );
  }
}
