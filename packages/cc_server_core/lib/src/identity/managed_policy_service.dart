import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/entities/guard_decision.dart'
    show EnforcementLevel;
import 'package:cc_domain/features/guardrails/domain/value_objects/action_constraint.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:uuid/uuid.dart';

/// The MANAGED (install-wide) action-policy tier: the operator's clamp over
/// every workspace's guardrails.
///
/// Two sources, in precedence order:
///
///  1. **A pinned file** named by `CC_SERVER_MANAGED_POLICY`. When present it
///     is the WHOLE managed policy and the stored rows are ignored — so an
///     operator can pin a posture that no admin UI can flip, which is the
///     answer to procurement's "can I stop my developers from disabling the
///     safety controls?". Same precedence shape as `server_settings`.
///  2. **`managed_action_policies` rows** in `global.db`, edited by the server
///     owner in Settings.
///
/// Managed rules never widen anything: `PolicyResolver.resolveAction` merges
/// them most-restrictive with the workspace chain rather than putting them at
/// the head of it.
class ManagedPolicyService {
  /// Creates a [ManagedPolicyService].
  ManagedPolicyService({
    required GlobalDatabase global,
    String? policyFilePath,
    void Function(String message)? onWarn,
  }) : _global = global,
       _policyFilePath = policyFilePath,
       _onWarn = onWarn;

  /// The environment variable naming a pinned policy file.
  static const envVar = 'CC_SERVER_MANAGED_POLICY';

  final GlobalDatabase _global;
  final String? _policyFilePath;
  final void Function(String message)? _onWarn;
  static const _uuid = Uuid();

  List<ActionPolicyRule>? _fileRules;
  bool _fileLoaded = false;

  /// The stored rules, cached in memory.
  ///
  /// [rules] is consulted on the hot path of EVERY gated tool call, so
  /// reading `managed_action_policies` per call would put a query on the
  /// server's single shared connection in front of work that has not started
  /// — the same mistake the code-graph notes describe. Managed rules change
  /// only through [upsert]/[delete] (owner-only ops on this object), so the
  /// cache is invalidated structurally rather than by a TTL.
  List<ActionPolicyRule>? _storedRules;

  /// Whether a pinned file is in force (the UI renders the stored rules
  /// read-only when it is — editing rows nothing reads would be a lie).
  bool get isPinnedToFile => _pinnedFile != null;

  File? get _pinnedFile {
    final path = _policyFilePath;
    if (path == null || path.isEmpty) {
      return null;
    }
    final file = File(path);
    return file.existsSync() ? file : null;
  }

  /// The rules the resolver should clamp with.
  Future<List<ActionPolicyRule>> rules() async {
    final pinned = await _loadFileRules();
    if (pinned != null) {
      return pinned;
    }
    final cached = _storedRules;
    if (cached != null) {
      return cached;
    }
    final rows = await _global.managedActionPolicyDao.all();
    return _storedRules = [for (final r in rows) _fromRow(r)];
  }

  /// Drops the cached rules. Called by every mutation here; also exposed so a
  /// path that writes the table behind this object (a restore, an import) can
  /// say so.
  void invalidate() => _storedRules = null;

  /// Adds or replaces one stored managed rule (owner-only, enforced at the op).
  Future<void> upsert({
    required String? actionClass,
    required String? commandPrefix,
    required ActionDecision decision,
    EnforcementLevel enforcement = EnforcementLevel.hard,
    ActionConstraint? constraint,
    String? updatedBy,
    String? id,
  }) async {
    invalidate();
    await _global.managedActionPolicyDao.upsert(
    ManagedActionPoliciesTableCompanion.insert(
      id: id ?? _uuid.v4(),
      actionClass: Value(actionClass),
      commandPrefix: Value(commandPrefix),
      decision: Value(decision.wire),
      enforcement: Value(enforcement.wire),
      constraintJson: Value(constraint?.encode()),
        updatedBy: Value(updatedBy),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Removes one stored managed rule.
  Future<void> delete(String id) async {
    invalidate();
    await _global.managedActionPolicyDao.deleteById(id);
  }

  Future<List<ActionPolicyRule>?> _loadFileRules() async {
    final file = _pinnedFile;
    if (file == null) {
      return null;
    }
    // Re-read on every resolution would put a stat + parse on the hot path of
    // every gated tool call; the file is operator-pinned configuration, so it
    // is read once per process like the rest of the boot configuration.
    if (_fileLoaded) {
      return _fileRules;
    }
    _fileLoaded = true;
    try {
      final decoded = jsonDecode(await file.readAsString());
      final list = decoded is Map ? decoded['rules'] : decoded;
      if (list is! List) {
        throw const FormatException('expected a JSON array of rules');
      }
      _fileRules = [
        for (final entry in list)
          if (entry is Map<String, dynamic>) _fromJson(entry),
      ];
      return _fileRules;
    } catch (e) {
      // A malformed pinned policy must NOT silently fall back to the stored
      // rows — that would be a policy the operator believes is in force and
      // is not. Refuse the file and clamp everything the file could have
      // governed to deny is too blunt; instead the boot preflight surfaces
      // this loudly and the stored rows apply.
      _onWarn?.call(
        'managed policy file ${file.path} is unreadable ($e); falling back to '
        'the stored managed rules',
      );
      _fileRules = null;
      return null;
    }
  }

  ActionPolicyRule _fromRow(ManagedActionPoliciesTableData r) =>
      ActionPolicyRule(
        id: r.id,
        // Managed rules are matched at workspace scope with an empty scope id
        // by `_resolveManaged`; they are not part of any workspace's chain.
        workspaceId: '',
        scopeType: ActionScopeType.workspace,
        scopeId: '',
        actionClass: r.actionClass == null
            ? null
            : ActionClass.fromWire(r.actionClass!),
        commandPrefix: r.commandPrefix,
        decision: ActionDecision.fromWire(r.decision),
        constraint: ActionConstraint.decode(r.constraintJson),
        enforcement: EnforcementLevel.fromWire(r.enforcement),
        provenance: 'managed',
        createdBy: r.updatedBy,
        createdAt: r.updatedAt,
        updatedAt: r.updatedAt,
      );

  ActionPolicyRule _fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    final cls = json['actionClass'] ?? json['action_class'];
    final prefix = json['commandPrefix'] ?? json['command_prefix'];
    final rawConstraint = json['constraint'];
    return ActionPolicyRule(
      id: (json['id'] as String?) ?? _uuid.v4(),
      workspaceId: '',
      scopeType: ActionScopeType.workspace,
      scopeId: '',
      actionClass: cls is String ? ActionClass.fromWire(cls) : null,
      commandPrefix: prefix is String ? prefix : null,
      decision: ActionDecision.fromWire((json['decision'] as String?) ?? 'deny'),
      enforcement: EnforcementLevel.fromWire(json['enforcement'] as String?),
      constraint: rawConstraint is Map<String, dynamic>
          ? ActionConstraint.fromJson(rawConstraint)
          : null,
      provenance: 'managed',
      createdAt: now,
      updatedAt: now,
    );
  }
}
