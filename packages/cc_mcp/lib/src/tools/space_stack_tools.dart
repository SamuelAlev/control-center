import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/messaging/domain/ports/space_stack_port.dart';
import 'package:cc_harness/tools.dart';

/// Reads the branch stack recorded for a space.
///
/// A space has one checkout per repo. Layers are branches inside that
/// checkout, not extra worktrees. Empty until the first [StackCutTool].
class StackStatusTool extends McpTool {
  /// Creates a [StackStatusTool].
  StackStatusTool({required this._stack});

  final SpaceStackPort _stack;

  @override
  String get name => 'stack_status';

  @override
  String get description =>
      'Lists the stacked branches in this space, bottom to top. Each layer '
      'is a branch in the one checkout for that repo. `current` marks the '
      'branch checked out now. Empty until stack_cut records the first part. '
      'A `git checkout -b` does not appear here.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {
        'type': 'string',
        'description': 'Workspace that owns the space.',
      },
      'space_id': {
        'type': 'string',
        'description': 'Space whose checkout holds the stack.',
      },
    },
    'required': ['workspace_id', 'space_id'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final (workspaceId, workspaceErr) = McpTool.requireString(
      arguments,
      'workspace_id',
    );
    if (workspaceErr != null) {
      return workspaceErr;
    }
    final (spaceId, spaceErr) = McpTool.requireString(arguments, 'space_id');
    if (spaceErr != null) {
      return spaceErr;
    }
    final view = await _stack.list(
      workspaceId: workspaceId!,
      spaceId: spaceId!,
    );
    return CallResult.success(jsonEncode(view.toWire()));
  }
}

/// Cuts the next stacked branch in the space's checkout.
///
/// Commit the current part first. Pass `at` only to split commits that are
/// already on the current branch: the current branch is reset to that commit
/// and the new branch keeps the commits above it.
class StackCutTool extends McpTool {
  /// Creates a [StackCutTool].
  StackCutTool({required this._stack});

  final SpaceStackPort _stack;

  @override
  String get name => 'stack_cut';

  @override
  String get description =>
      'Starts the next stacked part in this space. Commits on the current '
      'branch first, then call this — do not `git checkout -b`, which leaves '
      'the sidebar and the stack record unchanged. With no `at`, the new '
      'branch starts at HEAD and later commits land only on it. With `at` '
      '(an ancestor of HEAD), the current branch is reset to that commit and '
      'the new branch keeps the commits above it. Refuses a dirty worktree. '
      'The result says which branch is checked out afterwards.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {
        'type': 'string',
        'description': 'Workspace that owns the space.',
      },
      'space_id': {
        'type': 'string',
        'description': 'Space whose checkout holds the stack.',
      },
      'name': {
        'type': 'string',
        'description':
            'Short part name, such as "ui" or "migration". Appended to the '
            'bottom branch with "--", because git cannot store a branch '
            'underneath another branch\'s name.',
      },
      'repo_id': {
        'type': 'string',
        'description':
            'Repo to cut. Required when the space has more than one checkout.',
      },
      'at': {
        'type': 'string',
        'description':
            'Commit the current branch should end at. Omit to start the new '
            'part at HEAD. Must be an ancestor of HEAD.',
      },
    },
    'required': ['workspace_id', 'space_id', 'name'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final (workspaceId, workspaceErr) = McpTool.requireString(
      arguments,
      'workspace_id',
    );
    if (workspaceErr != null) {
      return workspaceErr;
    }
    final (spaceId, spaceErr) = McpTool.requireString(arguments, 'space_id');
    if (spaceErr != null) {
      return spaceErr;
    }
    final (name, nameErr) = McpTool.requireString(arguments, 'name');
    if (nameErr != null) {
      return nameErr;
    }
    final repoId = arguments['repo_id'];
    final at = arguments['at'];
    final view = await _stack.cut(
      workspaceId: workspaceId!,
      spaceId: spaceId!,
      name: name!,
      repoId: repoId is String && repoId.isNotEmpty ? repoId : null,
      at: at is String && at.isNotEmpty ? at : null,
    );
    if (!view.ok) {
      return CallResult.error(view.error ?? 'could not cut the next part');
    }
    return CallResult.success(jsonEncode(view.toWire()));
  }
}

/// Checks out a recorded stack layer in the space's one worktree.
class StackCheckoutTool extends McpTool {
  /// Creates a [StackCheckoutTool].
  StackCheckoutTool({required this._stack});

  final SpaceStackPort _stack;

  @override
  String get name => 'stack_checkout';

  @override
  String get description =>
      'Checks out a branch already in this space\'s stack. Refuses a dirty '
      'worktree and any branch stack_cut did not record. The result says '
      'which branch is current.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {
        'type': 'string',
        'description': 'Workspace that owns the space.',
      },
      'space_id': {
        'type': 'string',
        'description': 'Space whose checkout holds the stack.',
      },
      'branch': {
        'type': 'string',
        'description': 'Recorded stack branch to check out.',
      },
      'repo_id': {
        'type': 'string',
        'description':
            'Repo to switch. Required when more than one repo has that branch.',
      },
    },
    'required': ['workspace_id', 'space_id', 'branch'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final (workspaceId, workspaceErr) = McpTool.requireString(
      arguments,
      'workspace_id',
    );
    if (workspaceErr != null) {
      return workspaceErr;
    }
    final (spaceId, spaceErr) = McpTool.requireString(arguments, 'space_id');
    if (spaceErr != null) {
      return spaceErr;
    }
    final (branch, branchErr) = McpTool.requireString(arguments, 'branch');
    if (branchErr != null) {
      return branchErr;
    }
    final repoId = arguments['repo_id'];
    final view = await _stack.checkout(
      workspaceId: workspaceId!,
      spaceId: spaceId!,
      branch: branch!,
      repoId: repoId is String && repoId.isNotEmpty ? repoId : null,
    );
    if (!view.ok) {
      return CallResult.error(view.error ?? 'could not check out that part');
    }
    return CallResult.success(jsonEncode(view.toWire()));
  }
}

/// Pushes every stack layer and opens the missing pull requests.
///
/// Each pull request targets the branch below it. On GitHub the layers are
/// also grouped as a stack. Does not attach the space to a review room, so
/// merging one layer leaves the checkout in place.
class StackPublishTool extends McpTool {
  /// Creates a [StackPublishTool].
  StackPublishTool({required this._stack});

  final SpaceStackPort _stack;

  @override
  String get name => 'stack_publish';

  @override
  Set<ActionClass> get actionClasses => const {
    ActionClass.gitPush,
    ActionClass.prCreate,
  };

  @override
  String get description =>
      'Publishes this space\'s stack. Pushes every layer and opens a draft '
      'pull request for each one that does not have one yet. The bottom '
      'pull request targets the stack base; each later one targets the '
      'branch below it. On GitHub the pull requests are grouped as a stack. '
      'Pass draft false to open them ready for review. A layer with no '
      'commits of its own is pushed only when a part above it needs that '
      'branch as its base, and does not get a pull request.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {
        'type': 'string',
        'description': 'Workspace that owns the space.',
      },
      'space_id': {
        'type': 'string',
        'description': 'Space whose stack to publish.',
      },
      'repo_id': {
        'type': 'string',
        'description':
            'Repo to publish. Omit to publish every repo in the space that '
            'has a stack.',
      },
      'draft': {
        'type': 'boolean',
        'description': 'Open the new pull requests as drafts. Defaults to true.',
      },
    },
    'required': ['workspace_id', 'space_id'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final (workspaceId, workspaceErr) = McpTool.requireString(
      arguments,
      'workspace_id',
    );
    if (workspaceErr != null) {
      return workspaceErr;
    }
    final (spaceId, spaceErr) = McpTool.requireString(arguments, 'space_id');
    if (spaceErr != null) {
      return spaceErr;
    }
    final repoId = arguments['repo_id'];
    final draft = arguments['draft'];
    final view = await _stack.publish(
      workspaceId: workspaceId!,
      spaceId: spaceId!,
      repoId: repoId is String && repoId.isNotEmpty ? repoId : null,
      draft: draft is bool ? draft : true,
    );
    if (!view.ok) {
      return CallResult.error(view.error ?? 'could not publish the stack');
    }
    return CallResult.success(jsonEncode(view.toWire()));
  }
}
