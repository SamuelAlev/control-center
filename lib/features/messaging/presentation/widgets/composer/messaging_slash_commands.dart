/// The built-in slash commands a messaging composer advertises.
///
/// Split out of `messaging_mention_sources.dart`: this is a flat catalogue of
/// constants, while that file's job is resolving live workspace data into
/// mention sources. Keeping them together pushed that file past the
/// presentation size budget and buried the one interesting part of it under a
/// wall of literals.
///
/// The list is BUILT-INS ONLY. Skills are appended at the call site, under
/// their own `skill:` namespace, because they come from providers.
library;

import 'package:control_center/shared/widgets/composer/mention/sources/slash_command_source.dart';

/// The built-in commands, in the order the composer offers them.
const List<SlashCommand> kMessagingSlashCommands = <SlashCommand>[
  SlashCommand(
    name: 'plan',
    description: 'Switch to plan mode (read-only research, typed plan)',
  ),
  SlashCommand(
    name: 'goal',
    description: 'Work toward a goal until it is done',
  ),
  SlashCommand(name: 'loop', description: 'Iterate on a task until complete'),
  SlashCommand(name: 'tree', description: 'Show the conversation\'s branches'),
  SlashCommand(
    name: 'export',
    description: 'Write the conversation to a self-contained HTML file',
  ),
  SlashCommand(
    name: 'dump',
    description: 'Copy the transcript to the clipboard as markdown',
  ),
  SlashCommand(
    name: 'vibe',
    description: 'Direct background workers instead of doing the work',
  ),
  SlashCommand(
    name: 'compact',
    description: 'Compact the conversation history and continue',
  ),
  // The cheap alternative to /compact: no model call, no summary, every
  // word kept — only the bulk nobody will re-read is dropped.
  SlashCommand(
    name: 'shake',
    description: 'Drop heavy tool output without summarizing',
  ),
  SlashCommand(
    name: 'shake images',
    description: 'Drop old screenshots, keeping all the text',
  ),
  SlashCommand(
    name: 'context',
    description: "Open the agent's context window, segment by segment",
  ),
  // Side channels: one question about the conversation, never added to it.
  SlashCommand(
    name: 'handoff',
    description: 'Write a handoff document for whoever continues',
  ),
  SlashCommand(
    name: 'btw',
    description: 'Ask a side question without changing the conversation',
  ),
  // `/todo` and its subcommands manage this conversation's persisted todo
  // list locally (they never reach the agent). The mention system is flat,
  // so each subcommand is advertised as its own entry.
  SlashCommand(
    name: 'todo',
    description: 'View and edit the conversation todo list',
  ),
  SlashCommand(name: 'todo append', description: 'Add a todo item'),
  SlashCommand(name: 'todo start', description: 'Mark a todo as in progress'),
  SlashCommand(name: 'todo done', description: 'Mark a todo as done'),
  SlashCommand(
    name: 'todo drop',
    description: 'Remove a todo (or clear the list)',
  ),
  SlashCommand(name: 'todo edit', description: 'Open the todo editor'),
  SlashCommand(
    name: 'todo copy',
    description: 'Copy the todo list as markdown',
  ),
  SlashCommand(
    name: 'todo export',
    description: 'Export the todo list as markdown',
  ),
  SlashCommand(name: 'todo import', description: 'Import a markdown checklist'),
];
