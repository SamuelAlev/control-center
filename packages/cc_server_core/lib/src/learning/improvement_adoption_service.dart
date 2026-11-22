import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/cc_domain.dart'
    show ImprovementRefusedException, ValidationException;
import 'package:cc_domain/core/domain/entities/agent_working_memory.dart';
import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/core/domain/entities/memory_policy.dart';
import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/dispatch/domain/entities/improvement_proposal.dart';
import 'package:cc_domain/features/dispatch/domain/ports/improvement_apply_port.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/improvement_proposal_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/improvement_values.dart';
import 'package:cc_domain/features/evals/domain/entities/skill_evaluation_campaign.dart';
import 'package:cc_domain/features/memory/domain/repositories/agent_working_memory_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_policy_repository.dart';
import 'package:cc_domain/features/memory/domain/value_objects/memory_domain_scope.dart';
import 'package:cc_domain/features/skills/domain/ports/skill_scan_port.dart';
import 'package:cc_domain/features/skills/domain/scanner/skill_scan_types.dart';
import 'package:cc_server_core/src/evals/skill_evaluation_service.dart';
import 'package:cc_server_core/src/learning/improvement_evaluation.dart';
import 'package:cc_server_core/src/rpc_exception_mapper.dart'
    show storageBusyKind;

/// How many campaigns of one skill a dropped stage is checked against.
const int kSkillCampaignReferenceScan = 1000;

/// How long a move waits for boot recovery before it refuses: well inside
/// the improvement ops' handler timeout (60 seconds), so a caller is never
/// told a move failed that then runs once recovery finishes.
const Duration kImprovementRecoveryWait = Duration(seconds: 10);

/// The memory domain an accepted lesson is filed under when the proposal
/// names none (facts always; policies when the review gave no domain).
const String kLessonsDomain = 'lessons';

/// The provenance of everything an accepted proposal writes:
/// `refine:<proposalId>` (in a fact's `sourceObservationIds`, a policy's
/// `sourceFactIds`, a fact's `supersededBy`, a note's marker).
String improvementProvenance(String proposalId) => 'refine:$proposalId';

/// A person's decisions on improvement proposals (plan section 13,
/// "Adoption"): nothing changes until a person accepts.
///
/// - A memory fact, a policy or an agent note is written on accept, with the
///   provenance [improvementProvenance], in the claim's transaction and only
///   while the target is still the row the plan read
///   ([ImprovementApplyPort]); the proposal keeps `before_text`,
///   `after_text` and `applied_ref`.
/// - A skill change is never live before a person accepts it.
///   [startCampaign] claims the proposal (`campaign_state` `none|failed →
///   staging`), stages the candidate as a stored revision beside the live
///   one (through the same scan gate as `create_skill`) and has a
///   `SkillEvaluationService` campaign measure it against the live revision
///   (or the skill's absence). [accept] refuses
///   (`improvement_campaign_required`) until that campaign passed, then
///   writes the live `SKILL.md` while it is still the measured baseline and
///   marks the proposal applied ([recover] finishes or reports one whose
///   write did not). Reject, expiry and a failed campaign drop the stage;
///   reject and expiry also cancel a running campaign.
/// - [rollback] restores the earlier text while the current text is still
///   what the proposal wrote (`improvement_changed_since` otherwise).
///
/// Every move claims the proposal with a conditional status write first; a
/// lost race refuses with `improvement_already_decided`, and so does a
/// proposal past its `expires_at` that the daily sweep has not expired yet.
/// No move runs before [markRecovered]: boot recovery finishes or releases
/// what a crash left first, so it never meets a live start or accept. A
/// move that would wait longer than its bound refuses instead
/// (`storage.busy`, "try again in a moment"). The check, claim and write of
/// a skill's accept, rollback and recovery run one at a time per skill.
class ImprovementAdoptionService {
  /// Creates the service.
  ImprovementAdoptionService({
    required this._proposals,
    required this._apply,
    required this._facts,
    required this._policies,
    required this._notes,
    required this._repos,
    required this._filesystem,
    required this._scanner,
    required this._evaluation,
    required this._now,
    required this._recoveryWait,
  });

  final ImprovementProposalRepository _proposals;
  final ImprovementApplyPort _apply;
  final MemoryFactRepository _facts;
  final MemoryPolicyRepository _policies;
  final AgentWorkingMemoryRepository _notes;
  final RepoRepository _repos;
  final WorkspaceFilesystemPort _filesystem;
  final SkillScanPort? _scanner;
  final SkillEvaluationService? Function() _evaluation;
  final DateTime Function() _now;
  final Duration _recoveryWait;
  final Completer<void> _recovered = Completer<void>();
  final Map<String, Future<void>> _skillLocks = {};

  /// Opens the moves once boot recovery ran in every workspace (also after
  /// a recovery that failed: the moves still refuse what they must).
  void markRecovered() {
    if (!_recovered.isCompleted) {
      _recovered.complete();
    }
  }

  /// Waits for boot recovery at most [_recoveryWait], then refuses: a move
  /// the caller was told failed must not run later.
  Future<void> _ready() async {
    try {
      await _recovered.future.timeout(_recoveryWait);
    } on TimeoutException {
      throw const ImprovementRefusedException(
        'The server is still starting; try again in a moment',
        kind: storageBusyKind,
      );
    }
  }

  /// Runs [body] alone among the moves on skill [slug] of [ws]: the check
  /// of the live skill, the claim and the file write of an accept, a
  /// rollback or a recovery never interleave with another's.
  Future<T> _underSkill<T>(String ws, String slug, Future<T> Function() body) {
    final key = '$ws\u0000$slug';
    final before = _skillLocks[key] ?? Future<void>.value();
    final done = Completer<void>();
    _skillLocks[key] = done.future;
    return before.then((_) => body()).whenComplete(() {
      done.complete();
      if (identical(_skillLocks[key], done.future)) {
        _skillLocks.remove(key);
      }
    });
  }

  /// What [p]'s campaign measured, once it ended (`passed` or `failed`):
  /// null before that, and while a start or a campaign is in flight.
  Future<ImprovementEvaluation?> evaluationOf(ImprovementProposal p) async =>
      p.isSkillChange &&
          (p.campaignState == ImprovementCampaignState.passed ||
              p.campaignState == ImprovementCampaignState.failed)
      ? ImprovementEvaluation.fromReport((await _campaignOf(p))?.report)
      : null;

  /// [workspaceId]'s proposals as they change, and also when a campaign
  /// ends: a running proposal's campaign that turns terminal has its
  /// outcome recorded ([refreshCampaign]), and that write is the next
  /// frame, so a watching page moves without a reload or a sweep.
  Stream<List<ImprovementProposal>> watchForWorkspace(String workspaceId) {
    final evaluation = _evaluation();
    if (evaluation == null) {
      return _proposals.watchForWorkspace(workspaceId);
    }
    StreamSubscription<List<ImprovementProposal>>? rows;
    StreamSubscription<List<SkillEvaluationCampaign>>? campaigns;
    var running = <String, ImprovementProposal>{};
    late final StreamController<List<ImprovementProposal>> out;
    out = StreamController<List<ImprovementProposal>>(
      onListen: () {
        rows = _proposals
            .watchForWorkspace(workspaceId)
            .listen(
              (list) {
                running = {
                  for (final p in list)
                    if (p.status == ImprovementStatus.proposed &&
                        p.campaignState == ImprovementCampaignState.running &&
                        p.campaignId != null)
                      p.campaignId!: p,
                };
                out.add(list);
              },
              onError: out.addError,
              onDone: out.close,
            );
        campaigns = evaluation.repository
            .watchSkillCampaigns(workspaceId)
            .listen((list) {
              for (final c in list) {
                final p = c.isTerminal ? running.remove(c.id) : null;
                if (p != null) {
                  // The next read or the sweep records it if this fails.
                  unawaited(
                    refreshCampaign(
                      p,
                    ).then<void>((_) {}, onError: (Object _) {}),
                  );
                }
              }
            }, onError: (Object _) {});
      },
      onCancel: () async {
        await campaigns?.cancel();
        await rows?.cancel();
      },
    );
    return out.stream;
  }

  /// Refuses `evals.cancelCampaign` on campaign [campaignId] when an
  /// improvement proposal owns it and the caller is not a workspace admin:
  /// the improvement's own rule ([needsAdmin]) decides who stops what it
  /// pays for, not the evaluation's member rule.
  Future<void> guardCampaignCancel(
    String workspaceId,
    String campaignId, {
    required bool isAdmin,
  }) async {
    if (isAdmin) {
      return;
    }
    for (final p in await _proposals.listForWorkspace(workspaceId)) {
      if (p.campaignId == campaignId && needsAdmin(p)) {
        throw const ImprovementRefusedException(
          'Only a workspace admin decides a workspace policy or a skill change',
          kind: ImprovementRefusedException.adminRequiredKind,
        );
      }
    }
  }

  /// Whether accepting (or measuring) [proposal] needs a workspace admin:
  /// a workspace-scoped policy and every skill change.
  static bool needsAdmin(ImprovementProposal proposal) =>
      proposal.isSkillChange ||
      (proposal.kind == ImprovementKind.policy &&
          proposal.scope == ImprovementScope.workspace);

  /// [id] in [workspaceId]; refuses an id of another workspace.
  Future<ImprovementProposal> require(String workspaceId, String id) async {
    final proposal = await _proposals.getById(workspaceId, id);
    if (proposal == null || proposal.workspaceId != workspaceId) {
      throw const ValidationException('Improvement proposal not found');
    }
    return proposal;
  }

  // ------------------------------------------------------------------ accept

  /// Applies [proposal] for [userId].
  Future<ImprovementProposal> accept(
    ImprovementProposal proposal, {
    required String userId,
  }) async {
    await _ready();
    _requireProposed(proposal);
    _requireLive(proposal);
    if (proposal.isSkillChange) {
      return _acceptSkill(proposal, userId: userId);
    }
    final plan = await _plan(proposal);
    await _decideAndWrite(
      proposal,
      to: ImprovementStatus.accepted,
      userId: userId,
      before: plan.before,
      after: plan.after,
      appliedRef: plan.appliedRef,
      now: plan.now,
      write: plan.write,
    );
    return require(proposal.workspaceId, proposal.id);
  }

  /// Moves [p] and applies [write] in one transaction, or refuses.
  Future<void> _decideAndWrite(
    ImprovementProposal p, {
    ImprovementStatus from = ImprovementStatus.proposed,
    required ImprovementStatus to,
    required String userId,
    required String? before,
    required String? after,
    required String? appliedRef,
    required DateTime now,
    required ImprovementTextWrite write,
  }) async {
    switch (await _apply.decideAndWrite(
      p.workspaceId,
      id: p.id,
      from: from,
      to: to,
      decidedByUserId: userId,
      beforeText: before,
      afterText: after,
      appliedRef: appliedRef,
      now: now,
      write: write,
    )) {
      case ImprovementApplyOutcome.applied:
        return;
      case ImprovementApplyOutcome.alreadyDecided:
        throw const ImprovementRefusedException(
          'This proposal was decided meanwhile',
          kind: ImprovementRefusedException.alreadyDecidedKind,
        );
      case ImprovementApplyOutcome.changedSince:
        throw _changed();
    }
  }

  /// What accepting a text proposal writes, computed before anything is.
  Future<_Plan> _plan(ImprovementProposal p) async {
    final ws = p.workspaceId;
    final mark = improvementProvenance(p.id);
    final now = _now();
    switch (p.kind) {
      case ImprovementKind.memoryFact:
        if (p.operation == ImprovementOperation.add) {
          final fact = MemoryFact(
            id: _factId(p),
            workspaceId: ws,
            domain: await _domainOf(p, kLessonsDomain),
            topic: p.targetRef ?? kLessonsDomain,
            content: p.change,
            sourceObservationIds: [mark],
            authoredByAgentId: p.agentId,
            createdAt: now,
            updatedAt: now,
          );
          return _Plan(
            before: null,
            after: p.change,
            appliedRef: 'memory_fact:${fact.id}',
            now: now,
            write: ImprovementFactWrite(expected: null, fact: fact),
          );
        }
        final fact = await _facts.getById(ws, p.targetRef!);
        if (fact == null ||
            fact.workspaceId != ws ||
            fact.supersededBy != null) {
          throw _missing('The memory fact it changes is gone');
        }
        final remove = p.operation == ImprovementOperation.remove;
        return _Plan(
          before: fact.content,
          after: remove ? '' : p.change,
          appliedRef: 'memory_fact:${fact.id}',
          now: now,
          write: ImprovementFactWrite(
            expected: fact,
            fact: remove
                ? fact.copyWith(supersededBy: mark, updatedAt: now)
                : fact.copyWith(
                    content: p.change,
                    sourceObservationIds: [...fact.sourceObservationIds, mark],
                    updatedAt: now,
                  ),
          ),
        );
      case ImprovementKind.policy:
        if (p.operation == ImprovementOperation.add) {
          final policy = MemoryPolicy(
            id: _factId(p),
            workspaceId: ws,
            domain: await _domainOf(p, p.targetRef ?? kLessonsDomain),
            rule: p.change,
            sourceFactIds: [mark],
            createdAt: now,
            updatedAt: now,
          );
          return _Plan(
            before: null,
            after: p.change,
            appliedRef: 'memory_policy:${policy.id}',
            now: now,
            write: ImprovementPolicyWrite(expected: null, policy: policy),
          );
        }
        final policy = await _policies.getById(ws, p.targetRef!);
        if (policy == null || policy.workspaceId != ws || !policy.active) {
          throw _missing('The policy it changes is gone');
        }
        final remove = p.operation == ImprovementOperation.remove;
        return _Plan(
          before: policy.rule,
          after: remove ? '' : p.change,
          appliedRef: 'memory_policy:${policy.id}',
          now: now,
          write: ImprovementPolicyWrite(
            expected: policy,
            // A remove leaves its mark too, so its rollback re-enables only
            // the policy this proposal turned off.
            policy: policy.copyWith(
              active: !remove,
              rule: remove ? policy.rule : p.change,
              sourceFactIds: [...policy.sourceFactIds, mark],
              updatedAt: now,
            ),
          ),
        );
      case ImprovementKind.agentNote:
        final current = await _notes.getByAgent(ws, p.agentId);
        final before = current?.content ?? '';
        final after = editPassage(
          before,
          operation: p.operation,
          target: p.targetRef,
          change: '[$mark] ${p.change}',
        );
        if (after == null) {
          throw _missing("The passage it changes is not in the agent's notes");
        }
        return _Plan(
          before: before,
          after: after,
          appliedRef: 'agent_note:${p.agentId}',
          now: now,
          write: ImprovementNoteWrite(
            expected: current,
            note:
                current?.copyWith(content: after, updatedAt: now) ??
                AgentWorkingMemory(
                  id: _factId(p),
                  workspaceId: ws,
                  agentId: p.agentId,
                  content: after,
                  updatedAt: now,
                ),
          ),
        );
      case ImprovementKind.skillEdit:
      case ImprovementKind.skillNew:
        throw StateError('A skill change has no text plan');
    }
  }

  /// [text] with [change] added at the end (add), or put in place of the
  /// first [target] (replace), or [target] taken out (remove). Null when
  /// [target] is not in [text].
  static String? editPassage(
    String text, {
    required ImprovementOperation operation,
    required String? target,
    required String change,
  }) {
    switch (operation) {
      case ImprovementOperation.add:
        return text.trim().isEmpty ? change : '${text.trimRight()}\n\n$change';
      case ImprovementOperation.replace:
      case ImprovementOperation.remove:
        if (target == null || target.isEmpty || !text.contains(target)) {
          return null;
        }
        return text.replaceFirst(
          target,
          operation == ImprovementOperation.replace ? change : '',
        );
    }
  }

  String _factId(ImprovementProposal p) => 'refine-${p.id}';

  /// [name] as a domain slug, qualified by the proposal's repository when
  /// it is repository-scoped.
  Future<String> _domainOf(ImprovementProposal p, String name) async {
    if (p.scope != ImprovementScope.repository) {
      return name;
    }
    final repo = await _repos.getById(p.workspaceId, p.scopeRefId!);
    if (repo == null) {
      throw _missing('The repository it names is gone');
    }
    return MemoryDomainScope(name: name, repoSlug: repoSlugFor(repo)).slug;
  }

  // ------------------------------------------------------------------ reject

  /// Rejects [proposal]; a staged skill candidate is taken back.
  ///
  /// It acts on the row as it is after the claim: a start that launched
  /// meanwhile has its campaign cancelled and its stage dropped here; one
  /// still `staging` loses its own final write to the claim and cleans up
  /// after itself.
  Future<ImprovementProposal> reject(
    ImprovementProposal proposal, {
    required String userId,
  }) async {
    await _ready();
    _requireProposed(proposal);
    await _claim(proposal, to: ImprovementStatus.rejected, userId: userId);
    final fresh = await require(proposal.workspaceId, proposal.id);
    final campaignId = fresh.campaignId;
    if (fresh.campaignState == ImprovementCampaignState.running &&
        campaignId != null) {
      // Nobody adopts the candidate any more: stop paying for its measure.
      // The reject stands whatever the cancel does.
      await _quietly(() => _cancelCampaign(fresh.workspaceId, campaignId));
    }
    await _dropStage(fresh);
    return require(proposal.workspaceId, proposal.id);
  }

  // ---------------------------------------------------------------- rollback

  /// Restores what was there before [proposal] was accepted, while the
  /// current text is still what it wrote.
  Future<ImprovementProposal> rollback(
    ImprovementProposal proposal, {
    required String userId,
  }) async {
    await _ready();
    if (proposal.status != ImprovementStatus.accepted) {
      throw const ImprovementRefusedException(
        'Only an accepted proposal can be rolled back',
        kind: ImprovementRefusedException.alreadyDecidedKind,
      );
    }
    if (proposal.isSkillChange) {
      await _underSkill(proposal.workspaceId, proposal.scopeRefId!, () async {
        final undo = await _undoSkill(proposal);
        await _claim(
          proposal,
          from: ImprovementStatus.accepted,
          to: ImprovementStatus.rolledBack,
          userId: userId,
        );
        await undo();
      });
      return require(proposal.workspaceId, proposal.id);
    }
    final now = _now();
    await _decideAndWrite(
      proposal,
      from: ImprovementStatus.accepted,
      to: ImprovementStatus.rolledBack,
      userId: userId,
      before: null,
      after: null,
      appliedRef: null,
      now: now,
      write: await _undoText(proposal, now),
    );
    return require(proposal.workspaceId, proposal.id);
  }

  /// The write that undoes text proposal [p]; refuses when the text changed
  /// since.
  Future<ImprovementTextWrite> _undoText(
    ImprovementProposal p,
    DateTime now,
  ) async {
    final ws = p.workspaceId;
    final ref = p.appliedRef ?? '';
    final id = ref.substring(ref.indexOf(':') + 1);
    final mark = improvementProvenance(p.id);
    final remove = p.operation == ImprovementOperation.remove;
    switch (p.kind) {
      case ImprovementKind.memoryFact:
        final fact = await _facts.getById(ws, id);
        if (fact == null || fact.workspaceId != ws) {
          throw _changed();
        }
        if (remove) {
          if (fact.supersededBy != mark) {
            throw _changed();
          }
          return ImprovementFactWrite(
            expected: fact,
            fact: fact.copyWith(clearSupersededBy: true, updatedAt: now),
          );
        }
        if (fact.content != p.afterText || fact.supersededBy != null) {
          throw _changed();
        }
        return ImprovementFactWrite(
          expected: fact,
          fact: p.operation == ImprovementOperation.add
              ? null
              : fact.copyWith(content: p.beforeText, updatedAt: now),
        );
      case ImprovementKind.policy:
        final policy = await _policies.getById(ws, id);
        if (policy == null || policy.workspaceId != ws) {
          throw _changed();
        }
        if (remove) {
          // Re-enabled only while this proposal's turning off is the last
          // change: its mark is on the policy and nothing touched it since.
          final decided = p.decidedAt;
          if (policy.active ||
              !policy.sourceFactIds.contains(mark) ||
              decided == null ||
              !policy.updatedAt.isAtSameMomentAs(decided)) {
            throw _changed();
          }
          return ImprovementPolicyWrite(
            expected: policy,
            policy: policy.copyWith(
              active: true,
              sourceFactIds: [
                for (final source in policy.sourceFactIds)
                  if (source != mark) source,
              ],
              updatedAt: now,
            ),
          );
        }
        if (policy.rule != p.afterText || !policy.active) {
          throw _changed();
        }
        return ImprovementPolicyWrite(
          expected: policy,
          policy: p.operation == ImprovementOperation.add
              ? null
              : policy.copyWith(rule: p.beforeText, updatedAt: now),
        );
      case ImprovementKind.agentNote:
        final notes = await _notes.getByAgent(ws, p.agentId);
        if (notes == null || notes.content != p.afterText) {
          throw _changed();
        }
        return ImprovementNoteWrite(
          expected: notes,
          note: notes.copyWith(content: p.beforeText ?? '', updatedAt: now),
        );
      case ImprovementKind.skillEdit:
      case ImprovementKind.skillNew:
        throw StateError('A skill change has no text undo');
    }
  }

  /// The write that undoes skill proposal [p]: the earlier text back while
  /// the live `SKILL.md` is still what it wrote.
  Future<Future<void> Function()> _undoSkill(ImprovementProposal p) async {
    final ws = p.workspaceId;
    final slug = p.scopeRefId!;
    final current = await _filesystem.readSkillFile(ws, slug);
    if (current == null || current != p.afterText) {
      throw _changed();
    }
    return p.kind == ImprovementKind.skillNew
        ? () => _filesystem.deleteSkillDir(ws, slug)
        : () => _filesystem.writeSkillFile(ws, slug, p.beforeText ?? '');
  }

  // ------------------------------------------------------------------ skills

  /// Claims [proposal] (`none|failed → staging`), stages its skill
  /// candidate as a stored revision (never the live `SKILL.md`) and
  /// launches its campaign for [actor] with the person's chosen corpus,
  /// model and spending limit ([settings]: `corpus_id`, `provider_id`,
  /// `model_id`, `repetitions`, `budget_micros`, optional `adapter`). The
  /// skill, the comparison and the baseline are the server's: the staged
  /// candidate is measured against the live revision, a new skill against
  /// its absence. A failure releases the claim and drops the stage.
  Future<ImprovementProposal> startCampaign(
    ImprovementProposal proposal, {
    required Principal actor,
    required Map<String, dynamic> settings,
  }) async {
    await _ready();
    _requireProposed(proposal);
    _requireLive(proposal);
    if (!proposal.isSkillChange) {
      throw const ValidationException('Only a skill change has a campaign');
    }
    final evaluation = _evaluation();
    if (evaluation == null) {
      throw StateError('Skill evaluation is not available on this server');
    }
    final ws = proposal.workspaceId;
    final released = proposal.campaignState;
    if (!_startable.contains(released) ||
        !await _proposals.setCampaign(
          ws,
          id: proposal.id,
          from: _startable,
          // A start from `failed` keeps nothing of the previous campaign.
          campaignId: null,
          state: ImprovementCampaignState.staging,
          candidateRevisionId: null,
        )) {
      throw const ImprovementRefusedException(
        'A campaign for this proposal is already starting, running or passed',
        kind: ImprovementRefusedException.campaignStateKind,
      );
    }
    final slug = proposal.scopeRefId!;
    String? baselineHash;
    String? stagedHash;
    String? campaignId;
    var launched = false;
    try {
      final isNew = proposal.kind == ImprovementKind.skillNew;
      final current = await _filesystem.readSkillFile(ws, slug);
      if (isNew != (current == null)) {
        throw _missing(
          isNew ? 'A skill with that name exists now' : 'The skill is gone',
        );
      }
      final candidate = isNew
          ? newSkillText(slug, proposal)
          : editPassage(
              current!,
              operation: proposal.operation,
              target: proposal.targetRef,
              change: proposal.change,
            );
      if (candidate == null) {
        throw _missing('The passage it changes is not in the skill');
      }
      if (candidate == current) {
        throw const ValidationException('The change leaves the skill as it is');
      }
      final chosen = _chosenSettings(slug, isNew: isNew, settings: settings);
      await _scan(ws, slug, candidate);
      final baseline = isNew
          ? null
          : await evaluation.snapshots.capture(workspaceId: ws, slug: slug);
      baselineHash = baseline?.package.packageHash;
      final staged = await evaluation.snapshots.stage(
        workspaceId: ws,
        slug: slug,
        base: baseline,
        skillMd: candidate,
      );
      stagedHash = staged.package.packageHash;
      final campaign = await evaluation.launch(
        workspaceId: ws,
        actor: actor,
        settings: SkillEvaluationSettings(
          skillSlug: slug,
          corpusId: chosen.corpusId,
          providerId: chosen.providerId,
          modelId: chosen.modelId,
          adapter: chosen.adapter,
          comparison: chosen.comparison,
          repetitions: chosen.repetitions,
          budgetMicros: chosen.budgetMicros,
          baselineHash: baselineHash,
          candidateHash: stagedHash,
        ),
      );
      campaignId = campaign.id;
      launched = await _proposals.setCampaign(
        ws,
        id: proposal.id,
        from: const {ImprovementCampaignState.staging},
        campaignId: campaign.id,
        state: ImprovementCampaignState.running,
        candidateRevisionId: stagedHash,
      );
      if (!launched) {
        throw const ImprovementRefusedException(
          'The proposal was decided meanwhile',
          kind: ImprovementRefusedException.alreadyDecidedKind,
        );
      }
    } on Object {
      if (!launched) {
        final launchedId = campaignId;
        if (launchedId != null) {
          await _quietly(() => _cancelCampaign(ws, launchedId));
        }
        await _quietly(
          () => _discard(
            ws,
            slug,
            stagedHash,
            keep: baselineHash,
            proposalId: proposal.id,
            campaignId: campaignId,
          ),
        );
        // Whatever the status: a reject that won still lets go of `staging`.
        await _proposals.releaseStaging(ws, id: proposal.id, to: released);
      }
      rethrow;
    }
    return require(ws, proposal.id);
  }

  /// The campaign states a start may claim from.
  static const Set<ImprovementCampaignState> _startable = {
    ImprovementCampaignState.none,
    ImprovementCampaignState.failed,
  };

  SkillEvaluationSettings _chosenSettings(
    String slug, {
    required bool isNew,
    required Map<String, dynamic> settings,
  }) {
    try {
      return SkillEvaluationSettings.fromJson({
        ...settings,
        'skill_slug': slug,
        'comparison': isNew
            ? SkillEvaluationComparison.absent.wire
            : SkillEvaluationComparison.previous.wire,
        // The real baseline is the live revision, captured after this check.
        'baseline_hash': isNew ? null : '0' * 64,
      });
    } on TypeError {
      throw const ValidationException(
        'Choose a corpus, provider, model, repeats and a budget',
      );
    } on ArgumentError catch (e) {
      throw ValidationException('${e.message}');
    }
  }

  /// The `SKILL.md` of a new skill [slug] proposed by [p].
  static String newSkillText(String slug, ImprovementProposal p) =>
      '---\nname: $slug\ndescription: ${jsonEncode(p.expected)}\n---\n\n'
      '${p.change}\n';

  Future<void> _scan(String ws, String slug, String content) async {
    final scanner = _scanner;
    if (scanner == null) {
      return;
    }
    final result = await scanner.scan(
      SkillBundle.single(slug, content),
      workspaceId: ws,
      trustTier: SkillTrustTier.workspace,
      runLlmReview: false,
    );
    if (result.verdict == SkillScanVerdict.quarantine) {
      throw const ValidationException(
        'The skill candidate was quarantined by the scan',
      );
    }
  }

  /// Accepts a skill change whose campaign passed: claims it, writes the
  /// staged candidate to the live `SKILL.md` while the live skill is still
  /// the baseline it was measured against, then marks it applied.
  Future<ImprovementProposal> _acceptSkill(
    ImprovementProposal p, {
    required String userId,
  }) => _underSkill(
    p.workspaceId,
    p.scopeRefId!,
    () => _acceptSkillAlone(p, userId: userId),
  );

  Future<ImprovementProposal> _acceptSkillAlone(
    ImprovementProposal p, {
    required String userId,
  }) async {
    final settled = await refreshCampaign(p);
    if (settled.campaignState != ImprovementCampaignState.passed) {
      throw const ImprovementRefusedException(
        'A skill change is accepted after its campaign reported no '
        'regression',
        kind: ImprovementRefusedException.campaignRequiredKind,
      );
    }
    final ws = p.workspaceId;
    final slug = p.scopeRefId!;
    final candidate = await _stagedText(settled);
    if (candidate == null) {
      throw _missing('The measured candidate is no longer stored');
    }
    final current = await _filesystem.readSkillFile(ws, slug);
    if (!await _isBaseline(settled, current)) {
      // What passed was measured against a skill that is no longer live:
      // the result says nothing about the change on today's skill. Failed
      // is startable, so the change can be measured again.
      if (await _proposals.setCampaign(
        ws,
        id: p.id,
        from: const {ImprovementCampaignState.passed},
        campaignId: settled.campaignId,
        state: ImprovementCampaignState.failed,
        candidateRevisionId: null,
      )) {
        await _dropStage(settled);
      }
      throw const ImprovementRefusedException(
        'The skill changed after this change was measured; run the '
        'evaluation again',
        kind: ImprovementRefusedException.campaignRequiredKind,
      );
    }
    await _claim(
      p,
      to: ImprovementStatus.accepted,
      userId: userId,
      before: current,
      after: candidate,
    );
    try {
      await _filesystem.writeSkillFile(ws, slug, candidate);
    } on Object {
      // The change is not in place: the record says so instead of claiming
      // an accepted change that was never written.
      await _proposals.decide(
        ws,
        id: p.id,
        from: ImprovementStatus.accepted,
        to: ImprovementStatus.rolledBack,
        decidedByUserId: userId,
        now: _now(),
      );
      rethrow;
    }
    if (!await _liveIsStaged(settled)) {
      // Something else wrote the skill around this write: what is live is
      // not the measured candidate, so the record does not claim it.
      await _proposals.decide(
        ws,
        id: p.id,
        from: ImprovementStatus.accepted,
        to: ImprovementStatus.rolledBack,
        decidedByUserId: userId,
        now: _now(),
      );
      throw _changed();
    }
    await _proposals.markApplied(ws, id: p.id, appliedRef: _skillRef(settled));
    return require(ws, p.id);
  }

  /// Whether the live skill of [p], captured again, is its staged candidate
  /// (true when it cannot be captured: the write itself landed).
  Future<bool> _liveIsStaged(ImprovementProposal p) async {
    final evaluation = _evaluation();
    if (evaluation == null) {
      return true;
    }
    final String live;
    try {
      live = (await evaluation.snapshots.capture(
        workspaceId: p.workspaceId,
        slug: p.scopeRefId!,
      )).package.packageHash;
    } on Object {
      return true;
    }
    return live == p.candidateRevisionId;
  }

  static String _skillRef(ImprovementProposal p) =>
      'skill:${p.scopeRefId}@${p.candidateRevisionId}';

  /// Whether [current] (the live `SKILL.md`, null when there is none) is
  /// still what [p]'s campaign measured against: the live revision's hash
  /// equals the campaign's baseline, or there is no skill for a new one.
  Future<bool> _isBaseline(ImprovementProposal p, String? current) async {
    if (p.kind == ImprovementKind.skillNew) {
      return current == null;
    }
    final evaluation = _evaluation();
    final campaign = await _campaignOf(p);
    final baseline = campaign?.baselineHash;
    if (current == null || evaluation == null || baseline == null) {
      return false;
    }
    final live = await evaluation.snapshots.capture(
      workspaceId: p.workspaceId,
      slug: p.scopeRefId!,
    );
    return live.package.packageHash == baseline;
  }

  /// The staged candidate's `SKILL.md`, or null when it is not stored.
  Future<String?> _stagedText(ImprovementProposal p) async {
    final evaluation = _evaluation();
    final hash = p.candidateRevisionId;
    if (evaluation == null || hash == null) {
      return null;
    }
    final staged = await evaluation.snapshots.previous(
      workspaceId: p.workspaceId,
      skillKey: 'workspace:${p.scopeRefId}',
      hash: hash,
    );
    final bytes = staged?.package.files['SKILL.md'];
    return bytes == null ? null : utf8.decode(bytes);
  }

  Future<SkillEvaluationCampaign?> _campaignOf(ImprovementProposal p) async {
    final evaluation = _evaluation();
    final campaignId = p.campaignId;
    if (evaluation == null || campaignId == null) {
      return null;
    }
    return evaluation.repository.skillCampaignById(p.workspaceId, campaignId);
  }

  /// Reads [p]'s campaign and records its outcome: `passed` when it
  /// completed and its report passes ([ImprovementEvaluation.passes]),
  /// `failed` otherwise (and the stage is dropped). Returns the proposal as
  /// stored.
  Future<ImprovementProposal> refreshCampaign(ImprovementProposal p) async {
    final campaignId = p.campaignId;
    if (p.campaignState != ImprovementCampaignState.running ||
        campaignId == null) {
      return p;
    }
    final campaign = await _campaignOf(p);
    if (campaign == null) {
      return p;
    }
    final state = campaignOutcome(campaign);
    if (state == ImprovementCampaignState.running) {
      return p;
    }
    final failed = state == ImprovementCampaignState.failed;
    final recorded = await _proposals.setCampaign(
      p.workspaceId,
      id: p.id,
      from: const {ImprovementCampaignState.running},
      campaignId: campaignId,
      state: state,
      candidateRevisionId: failed ? null : p.candidateRevisionId,
    );
    if (recorded && failed) {
      await _dropStage(p);
    }
    return require(p.workspaceId, p.id);
  }

  /// A campaign's state for a proposal ([ImprovementEvaluation.outcomeOf]).
  static ImprovementCampaignState campaignOutcome(
    SkillEvaluationCampaign campaign,
  ) => ImprovementEvaluation.outcomeOf(campaign);

  /// Deletes [p]'s staged candidate, unless anything else refers to it
  /// ([_discard]). The live skill is never touched: nothing was written
  /// there.
  Future<void> _dropStage(ImprovementProposal p) async {
    final slug = p.scopeRefId;
    if (!p.isSkillChange || slug == null) {
      return;
    }
    await _discard(
      p.workspaceId,
      slug,
      p.candidateRevisionId,
      keep: (await _campaignOf(p))?.baselineHash,
      proposalId: p.id,
      campaignId: p.campaignId,
    );
  }

  /// Deletes the stored revision [hash] of skill [slug] when nothing else
  /// refers to it. Revisions are content-addressed, so one file may be
  /// another proposal's candidate or a campaign's baseline: it is kept while
  /// [keep] names it, another undecided or accepted proposal than
  /// [proposalId] holds it as its candidate, any campaign of the skill measured against it, or a campaign
  /// other than [campaignId] that has not ended measures it.
  Future<void> _discard(
    String ws,
    String slug,
    String? hash, {
    required String? keep,
    required String? proposalId,
    required String? campaignId,
  }) async {
    final evaluation = _evaluation();
    if (evaluation == null || hash == null || hash == keep) {
      return;
    }
    for (final other in await _proposals.listForWorkspace(
      ws,
      // A rejected, expired or rolled back proposal holds nothing any more.
      statuses: const {ImprovementStatus.proposed, ImprovementStatus.accepted},
    )) {
      if (other.id != proposalId &&
          other.isSkillChange &&
          other.scopeRefId == slug &&
          other.candidateRevisionId == hash) {
        return;
      }
    }
    for (final campaign in await evaluation.repository.skillCampaigns(
      ws,
      skillKey: 'workspace:$slug',
      limit: kSkillCampaignReferenceScan,
    )) {
      if (campaign.baselineHash == hash ||
          (campaign.id != campaignId &&
              !campaign.isTerminal &&
              campaign.skillHash == hash)) {
        return;
      }
    }
    await evaluation.snapshots.discard(
      workspaceId: ws,
      skillKey: 'workspace:$slug',
      hash: hash,
    );
  }

  /// Cancels campaign [campaignId] on the server's authority: the
  /// proposal's own move decided it, whether or not the person who started
  /// the campaign may still act. An ended or unknown campaign has nothing
  /// to cancel.
  Future<void> _cancelCampaign(String ws, String campaignId) async {
    await _evaluation()?.cancelAsServer(ws, campaignId);
  }

  /// Runs a cleanup step whose failure must not stop the next one.
  static Future<void> _quietly(Future<void> Function() step) async {
    try {
      await step();
    } on Object {
      // The boot recovery or the next sweep meets what is left.
    }
  }

  // ------------------------------------------------------------------ expiry

  /// Records the outcome of running campaigns and expires every undecided
  /// proposal of [workspaceId] past its 30 days. An expiring skill change
  /// first has its running campaign cancelled (and recorded) and its stage
  /// dropped; one whose cleanup fails stays proposed for the next sweep.
  /// Returns how many expired.
  Future<int> sweep(String workspaceId) async {
    await _ready();
    final now = _now();
    final keep = <String>{};
    for (final listed in await _proposals.listForWorkspace(
      workspaceId,
      statuses: {ImprovementStatus.proposed},
    )) {
      try {
        final p = await refreshCampaign(listed);
        if (!p.isSkillChange || p.expiresAt.isAfter(now)) {
          continue;
        }
        final campaignId = p.campaignId;
        if (p.campaignState == ImprovementCampaignState.running &&
            campaignId != null) {
          await _quietly(() => _cancelCampaign(workspaceId, campaignId));
          await _proposals.setCampaign(
            workspaceId,
            id: p.id,
            from: const {ImprovementCampaignState.running},
            campaignId: campaignId,
            state: ImprovementCampaignState.failed,
            candidateRevisionId: null,
          );
        }
        await _dropStage(p);
      } on Object {
        keep.add(listed.id);
      }
    }
    return _proposals.expireDue(workspaceId, now: now, except: keep);
  }

  // ---------------------------------------------------------------- recovery

  /// At boot, before [markRecovered] lets anything else move a proposal (so
  /// no start of this process can be live): releases every start a crash
  /// left `staging`, whatever its status, and finishes each accepted skill
  /// change whose
  /// file write did not complete: re-applied while the live skill is still
  /// its baseline (or marked applied when it is already the candidate),
  /// otherwise rolled back and returned, for a row a person sees
  /// (`improvement_apply_incomplete`).
  Future<List<ImprovementProposal>> recover(String workspaceId) async {
    final incomplete = <ImprovementProposal>[];
    for (final p in await _proposals.listForWorkspace(workspaceId)) {
      if (p.campaignState == ImprovementCampaignState.staging) {
        await _proposals.releaseStaging(
          workspaceId,
          id: p.id,
          to: ImprovementCampaignState.none,
        );
        continue;
      }
      if (p.status != ImprovementStatus.accepted ||
          !p.isSkillChange ||
          p.appliedRef != null) {
        continue;
      }
      if (await _underSkill(workspaceId, p.scopeRefId!, () => _finish(p))) {
        incomplete.add(p);
      }
    }
    return incomplete;
  }

  /// Finishes accepted skill change [p] whose write did not complete
  /// ([recover]); true when it had to be rolled back.
  Future<bool> _finish(ImprovementProposal p) async {
    final workspaceId = p.workspaceId;
    final slug = p.scopeRefId!;
    final candidate = await _stagedText(p);
    final current = await _filesystem.readSkillFile(workspaceId, slug);
    if (candidate != null && current == candidate) {
      await _proposals.markApplied(
        workspaceId,
        id: p.id,
        appliedRef: _skillRef(p),
      );
      return false;
    }
    if (candidate != null && current == p.beforeText) {
      await _filesystem.writeSkillFile(workspaceId, slug, candidate);
      await _proposals.markApplied(
        workspaceId,
        id: p.id,
        appliedRef: _skillRef(p),
      );
      return false;
    }
    return _proposals.decide(
      workspaceId,
      id: p.id,
      from: ImprovementStatus.accepted,
      to: ImprovementStatus.rolledBack,
      decidedByUserId: p.decidedByUserId,
      now: _now(),
    );
  }

  // ----------------------------------------------------------------- helpers

  void _requireProposed(ImprovementProposal p) {
    if (p.status != ImprovementStatus.proposed) {
      throw ImprovementRefusedException(
        'This proposal was already ${p.status.wire}',
        kind: ImprovementRefusedException.alreadyDecidedKind,
      );
    }
  }

  /// Refuses a proposal past its `expires_at` that the sweep has not
  /// expired yet: a campaign started now would be cancelled by the sweep.
  void _requireLive(ImprovementProposal p) {
    if (!p.expiresAt.isAfter(_now())) {
      throw const ImprovementRefusedException(
        'This proposal expired',
        kind: ImprovementRefusedException.alreadyDecidedKind,
      );
    }
  }

  Future<void> _claim(
    ImprovementProposal p, {
    ImprovementStatus from = ImprovementStatus.proposed,
    required ImprovementStatus to,
    required String userId,
    String? before,
    String? after,
    String? appliedRef,
  }) async {
    final claimed = await _proposals.decide(
      p.workspaceId,
      id: p.id,
      from: from,
      to: to,
      decidedByUserId: userId,
      beforeText: before,
      afterText: after,
      appliedRef: appliedRef,
      now: _now(),
    );
    if (!claimed) {
      throw const ImprovementRefusedException(
        'This proposal was decided meanwhile',
        kind: ImprovementRefusedException.alreadyDecidedKind,
      );
    }
  }

  static ImprovementRefusedException _missing(String message) =>
      ImprovementRefusedException(
        message,
        kind: ImprovementRefusedException.targetMissingKind,
      );

  static ImprovementRefusedException _changed() =>
      const ImprovementRefusedException(
        'The text changed after this proposal was applied',
        kind: ImprovementRefusedException.changedSinceKind,
      );
}

class _Plan {
  _Plan({
    required this.before,
    required this.after,
    required this.appliedRef,
    required this.now,
    required this.write,
  });

  final String? before;
  final String after;
  final String appliedRef;

  /// The time the write stamps, recorded as the decision's time too.
  final DateTime now;
  final ImprovementTextWrite write;
}
