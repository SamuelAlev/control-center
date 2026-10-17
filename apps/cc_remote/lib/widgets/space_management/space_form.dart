import 'dart:async';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/space_management_providers.dart';
import 'package:cc_remote/widgets/space_management/space_form_content.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SpaceForm extends ConsumerStatefulWidget {
  const SpaceForm({
    required this.workspaceId,
    required this.space,
    required this.role,
    required this.selfId,
    required this.agents,
    required this.members,
    required this.repos,
    required this.participants,
    required this.selectedRepos,
    required this.baseBranches,
    required this.autonomy,
    super.key,
  });

  final String workspaceId;
  final SpaceDto? space;
  final WorkspaceRole role;
  final String? selfId;
  final List<AgentDto> agents;
  final List<WorkspaceMemberDto> members;
  final List<Repo> repos;
  final List<SpaceParticipantDto> participants;
  final List<String>? selectedRepos;
  final Map<String, String> baseBranches;
  final Map<String, String> autonomy;

  @override
  ConsumerState<SpaceForm> createState() => _SpaceFormState();
}

class _SpaceFormState extends ConsumerState<SpaceForm> {
  final _name = TextEditingController();
  final _agents = <String>{};
  final _people = <String>{};
  final _repos = <String>{};
  final _branches = <String, TextEditingController>{};
  final _addedPeople = <String>{};
  List<String>? _savedRepos;
  bool _allRepos = true;
  bool _busy = false;
  String? _error;
  String? _createdSpaceId;
  Mode _mode = Mode.chat;

  @override
  void initState() {
    super.initState();
    _name.text = widget.space?.name ?? '';
    _mode = widget.space == null
        ? Mode.chat
        : Mode.fromDbValue(widget.space!.mode);
    _allRepos = widget.selectedRepos == null;
    _repos.addAll(widget.selectedRepos ?? const []);
    _savedRepos = widget.selectedRepos;
  }

  @override
  void dispose() {
    _name.dispose();
    for (final controller in _branches.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _current =>
      mounted &&
      ref.read(activeWorkspaceIdProvider).value == widget.workspaceId;

  SpaceManagementCommands get _commands {
    final client = ref.read(rpcClientProvider).value;
    if (client == null) throw StateError('Disconnected');
    return SpaceManagementCommands(client);
  }

  Future<void> _run(
    Future<void> Function() action, {
    bool admin = false,
  }) async {
    if (_busy || !_current) return;
    final role = ref.read(workspaceRoleProvider).value;
    if (role?.canWrite != true || (admin && role?.isAdmin != true)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (_current) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<String>? get _repoSelection => _allRepos ? null : _repos.toList();

  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(
        () => _error = AppLocalizations.of(context).mobileSpacesEmptyName,
      );
      return;
    }
    await _run(() async {
      final commands = _commands;
      if (_createdSpaceId == null) {
        final selected = _repoSelection;
        final branches = <String, String>{
          for (final entry in _branches.entries)
            if ((selected == null || selected.contains(entry.key)) &&
                entry.value.text.trim().isNotEmpty)
              entry.key: entry.value.text.trim(),
        };
        _createdSpaceId = await commands.create(
          widget.workspaceId,
          name,
          _agents.toList(),
          mode: _mode,
          repoIds: selected,
          repoBranches: branches,
        );
      }
      for (final userId in _people) {
        if (!_current) return;
        if (_addedPeople.contains(userId)) continue;
        await commands.addHuman(widget.workspaceId, _createdSpaceId!, userId);
        _addedPeople.add(userId);
      }
      if (_current) _manageCreated();
    });
  }

  void _manageCreated() {
    final spaceId = _createdSpaceId;
    if (spaceId == null || !_current) return;
    context.go(
      remoteWorkspaceLocation(
        '/spaces/${Uri.encodeComponent(spaceId)}/manage',
        widget.workspaceId,
      ),
    );
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(
        () => _error = AppLocalizations.of(context).mobileSpacesEmptyName,
      );
      return;
    }
    await _run(() async {
      final space = widget.space!;
      await _commands.save(
        widget.workspaceId,
        space,
        name: name,
        mode: _mode,
        repoIds: _repoSelection,
        originalRepos: _savedRepos,
        stillCurrent: () => _current,
      );
      if (_current) _savedRepos = _repoSelection;
    });
  }

  void _participant(String id, {required bool human}) {
    final space = widget.space;
    if (space == null) {
      setState(() {
        final selected = human ? _people : _agents;
        if (!selected.add(id)) selected.remove(id);
      });
      return;
    }
    final selected = widget.participants.any(
      (participant) =>
          participant.principalId == id &&
          participant.participantType == (human ? 'user' : 'agent'),
    );
    unawaited(
      _run(
        () => _commands.changeParticipant(
          widget.workspaceId,
          space.id,
          id,
          add: !selected,
          human: human,
        ),
      ),
    );
  }

  TextEditingController _branchController(String id) =>
      _branches.putIfAbsent(id, TextEditingController.new);

  @override
  Widget build(BuildContext context) => SpaceFormContent(
    workspaceId: widget.workspaceId,
    space: widget.space,
    role: widget.role,
    selfId: widget.selfId,
    agents: widget.agents,
    members: widget.members,
    repos: widget.repos,
    participants: widget.participants,
    baseBranches: widget.baseBranches,
    autonomy: widget.autonomy,
    name: _name,
    mode: _mode,
    allRepos: _allRepos,
    selectedRepos: _repos,
    selectedAgents: _agents,
    selectedPeople: _people,
    busy: _busy,
    error: _error,
    createdSpaceId: _createdSpaceId,
    branchController: _branchController,
    onClearError: () => setState(() => _error = null),
    onManageCreated: _manageCreated,
    onMode: (value) => setState(() => _mode = value),
    onAgent: (id) => _participant(id, human: false),
    onHuman: (id) => _participant(id, human: true),
    onAllRepos: () => setState(() => _allRepos = true),
    onClearRepos: () => setState(_repos.clear),
    onRepo: (id) => setState(() {
      if (!_repos.add(id)) _repos.remove(id);
    }),
    onBranch: (id, branch) =>
        setState(() => _branchController(id).text = branch),
    onAutonomy: (id, level) => unawaited(
      _run(
        () =>
            _commands.autonomy(widget.workspaceId, widget.space!.id, id, level),
        admin: true,
      ),
    ),
    onSubmit: () => unawaited(widget.space == null ? _create() : _save()),
    onArchive: () => unawaited(
      _run(() => _commands.archive(widget.workspaceId, widget.space!)),
    ),
  );
}
