import 'dart:typed_data';

import 'package:control_center/core/domain/entities/active_process_info.dart';
import 'package:control_center/core/domain/entities/git_repo_info.dart';
import 'package:control_center/core/domain/entities/ide_editor.dart';
import 'package:control_center/core/domain/entities/repo.dart';
import 'package:control_center/core/domain/notifications/notification_category.dart';
import 'package:control_center/core/domain/notifications/notification_sound.dart';
import 'package:control_center/core/domain/ports/agent_question_port.dart';
import 'package:control_center/core/domain/ports/confirmation_port.dart';
import 'package:control_center/core/domain/ports/conversation_mode_resolver.dart';
import 'package:control_center/core/domain/ports/credential_broker_port.dart';
import 'package:control_center/core/domain/ports/editor_launcher_port.dart';
import 'package:control_center/core/domain/ports/embedding_port.dart';
import 'package:control_center/core/domain/ports/git_command_port.dart';
import 'package:control_center/core/domain/ports/git_repo_inspector_port.dart';
import 'package:control_center/core/domain/ports/notification_port.dart';
import 'package:control_center/core/domain/ports/notification_preferences_port.dart';
import 'package:control_center/core/domain/ports/pr_worktree_port.dart';
import 'package:control_center/core/domain/ports/process_control_port.dart';
import 'package:control_center/core/domain/ports/process_detection_port.dart';
import 'package:control_center/core/domain/ports/repo_isolation_port.dart';
import 'package:control_center/core/domain/ports/repo_workspace_provisioner_port.dart';
import 'package:control_center/core/domain/ports/run_log_store_port.dart';
import 'package:control_center/core/domain/ports/sandbox_port.dart';
import 'package:control_center/core/domain/ports/system_audio_capture_port.dart';
import 'package:control_center/core/domain/value_objects/agent_capabilities.dart';
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:control_center/core/domain/value_objects/sandbox_backend.dart';
import 'package:control_center/core/domain/value_objects/sandbox_event.dart';
import 'package:control_center/core/domain/value_objects/sandbox_handle.dart';
import 'package:control_center/core/domain/value_objects/sandbox_spec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // SystemAudioSourceKind
  // ---------------------------------------------------------------------------
  group('SystemAudioSourceKind', () {
    test('all enum values are distinct', () {
      const values = SystemAudioSourceKind.values;
      expect(values.length, 4);
      expect(values.toSet().length, 4);
    });

    test('values have expected indices', () {
      expect(SystemAudioSourceKind.system.index, 0);
      expect(SystemAudioSourceKind.process.index, 1);
      expect(SystemAudioSourceKind.monitor.index, 2);
      expect(SystemAudioSourceKind.unknown.index, 3);
    });
  });

  // ---------------------------------------------------------------------------
  // SystemAudioSource
  // ---------------------------------------------------------------------------
  group('SystemAudioSource', () {
    test('constructs with all fields', () {
      const source = SystemAudioSource(
        id: 'monitor-1',
        name: 'Built-in Output',
        kind: SystemAudioSourceKind.monitor,
      );
      expect(source.id, 'monitor-1');
      expect(source.name, 'Built-in Output');
      expect(source.kind, SystemAudioSourceKind.monitor);
    });

    test('supports system source kind', () {
      const source = SystemAudioSource(
        id: 'system',
        name: 'System Audio',
        kind: SystemAudioSourceKind.system,
      );
      expect(source.id, 'system');
      expect(source.kind, SystemAudioSourceKind.system);
    });

    test('supports unknown kind', () {
      const source = SystemAudioSource(
        id: '?',
        name: 'Unknown',
        kind: SystemAudioSourceKind.unknown,
      );
      expect(source.kind, SystemAudioSourceKind.unknown);
    });
  });

  // ---------------------------------------------------------------------------
  // GitResult
  // ---------------------------------------------------------------------------
  group('GitResult', () {
    test('constructs with exitCode, stdout, stderr', () {
      const result = GitResult(
        exitCode: 0,
        stdout: 'refs/heads/main',
        stderr: '',
      );
      expect(result.exitCode, 0);
      expect(result.stdout, 'refs/heads/main');
      expect(result.stderr, '');
    });

    test('isSuccess is true when exitCode is 0', () {
      const result = GitResult(exitCode: 0, stdout: '', stderr: '');
      expect(result.isSuccess, isTrue);
    });

    test('isSuccess is false when exitCode is non-zero', () {
      const r1 = GitResult(exitCode: 1, stdout: '', stderr: 'error');
      const r2 = GitResult(exitCode: 128, stdout: '', stderr: 'fatal');
      expect(r1.isSuccess, isFalse);
      expect(r2.isSuccess, isFalse);
    });

    test('supports multiline stdout/stderr', () {
      const result = GitResult(
        exitCode: 0,
        stdout: 'line1\nline2\nline3',
        stderr: 'warning: something\nwarning: else',
      );
      expect(result.stdout, contains('\n'));
      expect(result.stderr, contains('\n'));
      expect(result.isSuccess, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // TimeOfDay
  // ---------------------------------------------------------------------------
  group('TimeOfDay', () {
    test('constructs with hour and minute', () {
      const tod = TimeOfDay(hour: 14, minute: 30);
      expect(tod.hour, 14);
      expect(tod.minute, 30);
    });

    test('totalMinutes computes correctly', () {
      expect(const TimeOfDay(hour: 0, minute: 0).totalMinutes, 0);
      expect(const TimeOfDay(hour: 1, minute: 0).totalMinutes, 60);
      expect(const TimeOfDay(hour: 1, minute: 30).totalMinutes, 90);
      expect(const TimeOfDay(hour: 23, minute: 59).totalMinutes, 1439);
    });

    test('equality when hour and minute match', () {
      const a = TimeOfDay(hour: 9, minute: 15);
      const b = TimeOfDay(hour: 9, minute: 15);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('not equal when hour differs', () {
      const a = TimeOfDay(hour: 8, minute: 0);
      const b = TimeOfDay(hour: 9, minute: 0);
      expect(a, isNot(equals(b)));
    });

    test('not equal when minute differs', () {
      const a = TimeOfDay(hour: 9, minute: 0);
      const b = TimeOfDay(hour: 9, minute: 1);
      expect(a, isNot(equals(b)));
    });

    test('midnight boundary', () {
      const midnight = TimeOfDay(hour: 0, minute: 0);
      expect(midnight.totalMinutes, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // QuietHoursConfig
  // ---------------------------------------------------------------------------
  group('QuietHoursConfig', () {
    test('constructs with enabled, start, end', () {
      const config = QuietHoursConfig(
        enabled: true,
        start: TimeOfDay(hour: 22, minute: 0),
        end: TimeOfDay(hour: 7, minute: 0),
      );
      expect(config.enabled, isTrue);
      expect(config.start, const TimeOfDay(hour: 22, minute: 0));
      expect(config.end, const TimeOfDay(hour: 7, minute: 0));
    });

    group('isQuiet', () {
      test('returns false when quiet hours are disabled', () {
        const config = QuietHoursConfig(
          enabled: false,
          start: TimeOfDay(hour: 22, minute: 0),
          end: TimeOfDay(hour: 7, minute: 0),
        );
        expect(config.isQuiet(DateTime(2026, 1, 1, 23, 0)), isFalse);
        expect(config.isQuiet(DateTime(2026, 1, 1, 12, 0)), isFalse);
      });

      test('wraps midnight — in quiet period after start', () {
        const config = QuietHoursConfig(
          enabled: true,
          start: TimeOfDay(hour: 22, minute: 0),
          end: TimeOfDay(hour: 7, minute: 0),
        );
        expect(config.isQuiet(DateTime(2026, 1, 1, 22, 0)), isTrue);
        expect(config.isQuiet(DateTime(2026, 1, 1, 23, 59)), isTrue);
        expect(config.isQuiet(DateTime(2026, 1, 1, 0, 0)), isTrue);
        expect(config.isQuiet(DateTime(2026, 1, 1, 1, 30)), isTrue);
        expect(config.isQuiet(DateTime(2026, 1, 1, 6, 59)), isTrue);
      });

      test('wraps midnight — outside quiet period', () {
        const config = QuietHoursConfig(
          enabled: true,
          start: TimeOfDay(hour: 22, minute: 0),
          end: TimeOfDay(hour: 7, minute: 0),
        );
        expect(config.isQuiet(DateTime(2026, 1, 1, 7, 0)), isFalse);
        expect(config.isQuiet(DateTime(2026, 1, 1, 12, 0)), isFalse);
        expect(config.isQuiet(DateTime(2026, 1, 1, 21, 59)), isFalse);
      });

      test('non-wrapping window (start <= end)', () {
        const config = QuietHoursConfig(
          enabled: true,
          start: TimeOfDay(hour: 1, minute: 0),
          end: TimeOfDay(hour: 5, minute: 0),
        );
        expect(config.isQuiet(DateTime(2026, 1, 1, 0, 59)), isFalse);
        expect(config.isQuiet(DateTime(2026, 1, 1, 1, 0)), isTrue);
        expect(config.isQuiet(DateTime(2026, 1, 1, 3, 30)), isTrue);
        expect(config.isQuiet(DateTime(2026, 1, 1, 4, 59)), isTrue);
        expect(config.isQuiet(DateTime(2026, 1, 1, 5, 0)), isFalse);
      });

      test('start equals end — empty window, never quiet', () {
        const config = QuietHoursConfig(
          enabled: true,
          start: TimeOfDay(hour: 12, minute: 0),
          end: TimeOfDay(hour: 12, minute: 0),
        );
        expect(config.isQuiet(DateTime(2026, 1, 1, 12, 0)), isFalse);
        expect(config.isQuiet(DateTime(2026, 1, 1, 11, 59)), isFalse);
        expect(config.isQuiet(DateTime(2026, 1, 1, 12, 1)), isFalse);
      });
    });
  });

  // ---------------------------------------------------------------------------
  // BatchDeliveryPolicy
  // ---------------------------------------------------------------------------
  group('BatchDeliveryPolicy', () {
    test('all enum values are distinct', () {
      const values = BatchDeliveryPolicy.values;
      expect(values.length, 3);
      expect(values.toSet().length, 3);
    });

    test('values include realtime, digest2h, digestDaily', () {
      expect(BatchDeliveryPolicy.values, containsAll([
        BatchDeliveryPolicy.realtime,
        BatchDeliveryPolicy.digest2h,
        BatchDeliveryPolicy.digestDaily,
      ]));
    });
  });

  // ---------------------------------------------------------------------------
  // ScopedCredentials
  // ---------------------------------------------------------------------------
  group('ScopedCredentials', () {
    test('constructs with required fields', () {
      const creds = ScopedCredentials(
        handle: 'h-1',
        environment: {'GITHUB_TOKEN': 'ghp_xxx'},
      );
      expect(creds.handle, 'h-1');
      expect(creds.environment, {'GITHUB_TOKEN': 'ghp_xxx'});
      expect(creds.expiresAt, isNull);
      expect(creds.notes, isEmpty);
    });

    test('constructs with optional fields', () {
      final exp = DateTime(2026, 6, 10, 15, 0);
      final c = ScopedCredentials(
        handle: 'h-3',
        environment: {},
        expiresAt: exp,
        notes: const ['Note 1', 'Note 2'],
      );
      expect(c.expiresAt, exp);
      expect(c.notes, ['Note 1', 'Note 2']);
    });

    test('multiple environment vars', () {
      const creds = ScopedCredentials(
        handle: 'h',
        environment: {
          'GITHUB_TOKEN': 't1',
          'TICKETING_API_KEY': 't2',
          'CUSTOM_VAR': 'v3',
        },
      );
      expect(creds.environment.length, 3);
    });
  });

  // ---------------------------------------------------------------------------
  // ConfirmationSeverity & ConfirmationRequest
  // ---------------------------------------------------------------------------
  group('ConfirmationSeverity', () {
    test('all enum values are distinct', () {
      const values = ConfirmationSeverity.values;
      expect(values.length, 3);
      expect(values.toSet().length, 3);
    });
  });

  group('ConfirmationRequest', () {
    test('constructs with required fields and default severity', () {
      const req = ConfirmationRequest(
        conversationId: 'conv-1',
        title: 'Push to main',
        detail: 'The agent wants to push to the main branch.',
      );
      expect(req.conversationId, 'conv-1');
      expect(req.title, 'Push to main');
      expect(req.detail, 'The agent wants to push to the main branch.');
      expect(req.severity, ConfirmationSeverity.warning);
      expect(req.command, isNull);
    });

    test('constructs with explicit severity and command', () {
      const req = ConfirmationRequest(
        conversationId: 'conv-2',
        title: 'Delete branch',
        detail: 'rm -rf all branches',
        severity: ConfirmationSeverity.destructive,
        command: 'git branch -D feature/x',
      );
      expect(req.severity, ConfirmationSeverity.destructive);
      expect(req.command, 'git branch -D feature/x');
    });

    test('constructs with info severity', () {
      const req = ConfirmationRequest(
        conversationId: 'conv-3',
        title: 'Network access',
        detail: 'Egress to api.example.com',
        severity: ConfirmationSeverity.info,
      );
      expect(req.severity, ConfirmationSeverity.info);
    });
  });

  // ---------------------------------------------------------------------------
  // AgentQuestionOption
  // ---------------------------------------------------------------------------
  group('AgentQuestionOption', () {
    test('constructs with label only', () {
      const option = AgentQuestionOption(label: 'Yes');
      expect(option.label, 'Yes');
      expect(option.description, isNull);
      expect(option.value, isNull);
    });

    test('effectiveValue returns value when provided', () {
      const option = AgentQuestionOption(label: 'Yes', value: 'yes_value');
      expect(option.effectiveValue, 'yes_value');
    });

    test('effectiveValue falls back to label when value is null', () {
      const option = AgentQuestionOption(label: 'No');
      expect(option.effectiveValue, 'No');
    });

    test('constructs with description', () {
      const option = AgentQuestionOption(
        label: 'Approve',
        description: 'Approve the pull request',
        value: 'approve',
      );
      expect(option.label, 'Approve');
      expect(option.description, 'Approve the pull request');
      expect(option.value, 'approve');
    });

    test('fromJson with all fields', () {
      final option = AgentQuestionOption.fromJson({
        'label': 'Skip',
        'description': 'Skip this step',
        'value': 'skip',
      });
      expect(option.label, 'Skip');
      expect(option.description, 'Skip this step');
      expect(option.value, 'skip');
    });

    test('fromJson with missing optional fields', () {
      final option = AgentQuestionOption.fromJson({'label': 'Only Label'});
      expect(option.label, 'Only Label');
      expect(option.description, isNull);
      expect(option.value, isNull);
    });

    test('fromJson with null label defaults to empty', () {
      final option = AgentQuestionOption.fromJson({});
      expect(option.label, '');
    });

    test('toJson includes all non-null fields', () {
      const option = AgentQuestionOption(label: 'Submit', value: 'submit');
      final json = option.toJson();
      expect(json['label'], 'Submit');
      expect(json['value'], 'submit');
      expect(json.containsKey('description'), isFalse);
    });

    test('toJson includes description when present', () {
      const option = AgentQuestionOption(
        label: 'Submit',
        description: 'Submit the form',
      );
      final json = option.toJson();
      expect(json['description'], 'Submit the form');
    });
  });

  // ---------------------------------------------------------------------------
  // AgentQuestionRequest
  // ---------------------------------------------------------------------------
  group('AgentQuestionRequest', () {
    test('constructs with required fields and defaults', () {
      const req = AgentQuestionRequest(
        conversationId: 'conv-1',
        question: 'Which branch?',
      );
      expect(req.conversationId, 'conv-1');
      expect(req.question, 'Which branch?');
      expect(req.context, isNull);
      expect(req.options, isEmpty);
      expect(req.allowFreeText, isFalse);
      expect(req.multiSelect, isFalse);
      expect(req.askedByAgentId, isNull);
      expect(req.askedByName, isNull);
    });

    test('constructs with options and agent info', () {
      final options = [
        const AgentQuestionOption(label: 'Main', value: 'main'),
        const AgentQuestionOption(label: 'Develop', value: 'develop'),
      ];
      final req = AgentQuestionRequest(
        conversationId: 'conv-2',
        question: 'Merge into which branch?',
        context: 'The PR has conflicts.',
        options: options,
        allowFreeText: true,
        askedByAgentId: 'agent-1',
        askedByName: 'CodeBot',
      );
      expect(req.options.length, 2);
      expect(req.allowFreeText, isTrue);
      expect(req.multiSelect, isFalse);
      expect(req.askedByAgentId, 'agent-1');
      expect(req.askedByName, 'CodeBot');
      expect(req.context, 'The PR has conflicts.');
    });

    test('multiSelect is configurable', () {
      const req = AgentQuestionRequest(
        conversationId: 'conv-3',
        question: 'Select files',
        multiSelect: true,
      );
      expect(req.multiSelect, isTrue);
    });

    test('empty options list by default', () {
      const req = AgentQuestionRequest(conversationId: 'c', question: 'q');
      expect(req.options, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // AgentQuestionAnswer
  // ---------------------------------------------------------------------------
  group('AgentQuestionAnswer', () {
    test('constructs with defaults', () {
      const answer = AgentQuestionAnswer();
      expect(answer.selectedLabels, isEmpty);
      expect(answer.freeText, isNull);
    });

    test('constructs with selected labels', () {
      const answer = AgentQuestionAnswer(
        selectedLabels: ['Option A', 'Option B'],
      );
      expect(answer.selectedLabels, ['Option A', 'Option B']);
      expect(answer.isEmpty, isFalse);
    });

    test('isEmpty is true when nothing selected and no free text', () {
      const answer = AgentQuestionAnswer();
      expect(answer.isEmpty, isTrue);
    });

    test('isEmpty is false when labels are selected', () {
      const answer = AgentQuestionAnswer(selectedLabels: ['X']);
      expect(answer.isEmpty, isFalse);
    });

    test('isEmpty is false when freeText is non-empty', () {
      const answer = AgentQuestionAnswer(freeText: 'my answer');
      expect(answer.isEmpty, isFalse);
    });

    test('isEmpty is true when freeText is whitespace only', () {
      const answer = AgentQuestionAnswer(freeText: '   ');
      expect(answer.isEmpty, isTrue);
    });

    test('fromJson with labels and freeText', () {
      final answer = AgentQuestionAnswer.fromJson({
        'selected': ['A', 'B'],
        'freeText': 'extra info',
      });
      expect(answer.selectedLabels, ['A', 'B']);
      expect(answer.freeText, 'extra info');
    });

    test('fromJson with missing fields', () {
      final answer = AgentQuestionAnswer.fromJson({});
      expect(answer.selectedLabels, isEmpty);
      expect(answer.freeText, isNull);
    });

    test('fromJson selected is not a list', () {
      final answer = AgentQuestionAnswer.fromJson({'selected': 'not-a-list'});
      expect(answer.selectedLabels, isEmpty);
    });

    test('fromJson selected is null', () {
      final answer = AgentQuestionAnswer.fromJson({'selected': null});
      expect(answer.selectedLabels, isEmpty);
    });

    test('toJson with labels and freeText', () {
      const answer = AgentQuestionAnswer(
        selectedLabels: ['A'],
        freeText: 'hello',
      );
      final json = answer.toJson();
      expect(json['selected'], ['A']);
      expect(json['freeText'], 'hello');
    });

    test('toJson excludes null/empty freeText', () {
      const answer = AgentQuestionAnswer(selectedLabels: ['B']);
      final json = answer.toJson();
      expect(json['selected'], ['B']);
      expect(json.containsKey('freeText'), isFalse);
    });

    test('toJson excludes empty string freeText', () {
      const answer = AgentQuestionAnswer(
        selectedLabels: ['B'],
        freeText: '',
      );
      final json = answer.toJson();
      expect(json.containsKey('freeText'), isFalse);
    });

    test('toPromptString with only labels', () {
      const answer = AgentQuestionAnswer(selectedLabels: ['main', 'develop']);
      expect(answer.toPromptString(), 'Selected: main, develop');
    });

    test('toPromptString with only freeText', () {
      const answer = AgentQuestionAnswer(freeText: 'use the feature branch');
      expect(answer.toPromptString(), 'Additional input: use the feature branch');
    });

    test('toPromptString with both', () {
      const answer = AgentQuestionAnswer(
        selectedLabels: ['Option 1'],
        freeText: 'some notes',
      );
      final result = answer.toPromptString();
      expect(result, contains('Selected: Option 1'));
      expect(result, contains('Additional input: some notes'));
    });

    test('toPromptString when empty returns placeholder', () {
      const answer = AgentQuestionAnswer();
      expect(answer.toPromptString(), '(no answer)');
    });

    test('toPromptString with empty labels and whitespace freeText', () {
      const answer = AgentQuestionAnswer(freeText: '   ');
      expect(answer.toPromptString(), '(no answer)');
    });
  });

  // ---------------------------------------------------------------------------
  // RepoIsolationResult
  // ---------------------------------------------------------------------------
  group('RepoIsolationResult', () {
    test('constructs with path and backend', () {
      const result = RepoIsolationResult(
        path: '/tmp/worktrees/ws-1/conv-1',
        backend: RepoIsolationBackend.rift,
      );
      expect(result.path, '/tmp/worktrees/ws-1/conv-1');
      expect(result.backend, RepoIsolationBackend.rift);
    });

    test('supports gitWorktree backend', () {
      const result = RepoIsolationResult(
        path: '/tmp/worktrees/git',
        backend: RepoIsolationBackend.gitWorktree,
      );
      expect(result.backend, RepoIsolationBackend.gitWorktree);
    });
  });

  // ---------------------------------------------------------------------------
  // SandboxBackendCapabilities
  // ---------------------------------------------------------------------------
  group('SandboxBackendCapabilities', () {
    test('constructs with required fields and defaults', () {
      const caps = SandboxBackendCapabilities(
        backend: SandboxBackend.native,
        available: true,
      );
      expect(caps.backend, SandboxBackend.native);
      expect(caps.available, isTrue);
      expect(caps.requiresInstall, isFalse);
      expect(caps.installHint, isNull);
      expect(caps.note, isNull);
    });

    test('constructs with all fields', () {
      const caps = SandboxBackendCapabilities(
        backend: SandboxBackend.native,
        available: false,
        requiresInstall: true,
        installHint: 'apt-get install bubblewrap',
        note: 'Requires Linux kernel 5.11+',
      );
      expect(caps.requiresInstall, isTrue);
      expect(caps.installHint, 'apt-get install bubblewrap');
      expect(caps.note, 'Requires Linux kernel 5.11+');
      expect(caps.available, isFalse);
    });

    test('none backend', () {
      const caps = SandboxBackendCapabilities(
        backend: SandboxBackend.none,
        available: false,
      );
      expect(caps.available, isFalse);
      expect(caps.backend, SandboxBackend.none);
    });
  });

  // ---------------------------------------------------------------------------
  // Port interface structure verification
  // ---------------------------------------------------------------------------
  group('Port interface contracts', () {
    test('NotificationPort contract is valid', () {
      final port = _TestNotificationPort();
      port.show(const AppNotification(
        category: NotificationCategory.agentRunCompleted,
        title: 'Test',
        body: 'Test body',
        route: '/test',
        workspaceId: 'ws-1',
      ));
    });

    test('ProcessControlPort contract is valid', () async {
      final port = _TestProcessControlPort();
      await port.kill(1234);
      expect(port.isPidAlive(42), isFalse);
    });

    test('GitCommandPort contract is valid', () async {
      final port = _TestGitCommandPort();
      final result = await port.run(['status'], workdir: '/tmp');
      expect(result, isA<GitResult>());
    });

    test('EmbeddingPort contract is valid', () {
      final port = _TestEmbeddingPort();
      expect(port.isReady, isTrue);
      expect(port.dimension, 384);
    });

    test('RunLogStorePort contract is valid', () async {
      final port = _TestRunLogStorePort();
      await port.writeChunk('run-1', 'output');
      final log = await port.readLog('run-1');
      expect(log, isNotEmpty);
      await port.compact('run-1');
    });

    test('ProcessDetectionPort contract is valid', () async {
      final port = _TestProcessDetectionPort();
      final procs = await port.detect();
      expect(procs, isEmpty);
      await port.killProcess(42);
    });

    test('GitRepoInspectorPort contract is valid', () async {
      final port = _TestGitRepoInspectorPort();
      final info = await port.inspect('/tmp/repo');
      expect(info, isNotNull);
    });

    test('ConversationModeResolver contract is valid', () async {
      final port = _TestConversationModeResolver();
      final mode = await port.resolveForConversation('conv-1');
      expect(mode, isNotNull);
    });

    test('NotificationPreferencesPort contract is valid', () async {
      final port = _TestNotificationPreferencesPort();
      expect(await port.isGlobalEnabled(), isTrue);
      expect(
        await port.isCategoryEnabled(NotificationCategory.agentRunCompleted),
        isTrue,
      );
      await port.setGlobalEnabled(enabled: false);
    });

    test('EditorLauncherPort contract is valid', () async {
      final port = _TestEditorLauncherPort();
      final editors = await port.detectEditors();
      expect(editors, isNotEmpty);
      await port.openDirectory(editorId: 'vscode', directoryPath: '/tmp');
    });

    test('PrWorktreePort contract is valid', () async {
      final port = _TestPrWorktreePort();
      final path = await port.ensureWorktree(
        workspaceId: 'ws-1',
        repo: _testRepo(),
        prNumber: 42,
        prHeadRef: 'refs/heads/feature',
      );
      expect(path, isNotEmpty);
    });

    test('RepoIsolationPort contract is valid', () async {
      final port = _TestRepoIsolationPort();
      expect(port.isCowAvailable, isTrue);
      final result = await port.provision(
        sourcePath: '/tmp/source',
        destParentDir: '/tmp/dest',
        name: 'worktree-1',
        branch: 'feature/x',
      );
      expect(result, isA<RepoIsolationResult>());
    });

    test('RepoWorkspaceProvisionerPort contract is valid', () async {
      final port = _TestRepoWorkspaceProvisionerPort();
      final dir = await port.ensureConversationWorkspace(
        workspaceId: 'ws-1',
        channelId: 'ch-1',
        fallbackDir: '/tmp/fallback',
        branchType: 'feature',
      );
      expect(dir, isNotEmpty);
    });

    test('SandboxPort contract is valid', () async {
      final port = _TestSandboxPort();
      expect(port.backend, SandboxBackend.native);
      final caps = await port.probe();
      expect(caps, isA<SandboxBackendCapabilities>());
    });

    test('CredentialBrokerPort contract is valid', () async {
      final port = _TestCredentialBrokerPort();
      final creds = await port.mint(
        conversationId: 'conv-1',
        capabilities: _testCapabilities(),
      );
      expect(creds, isA<ScopedCredentials>());
      await port.revoke(creds.handle);
    });

    test('ConfirmationPort contract is valid', () async {
      final port = _TestConfirmationPort();
      final approved = await port.requestApproval(
        const ConfirmationRequest(
          conversationId: 'conv-1',
          title: 'Test',
          detail: 'Test detail',
        ),
      );
      expect(approved, isTrue);
    });

    test('AgentQuestionPort contract is valid', () async {
      final port = _TestAgentQuestionPort();
      final answer = await port.ask(
        const AgentQuestionRequest(
          conversationId: 'conv-1',
          question: 'Test?',
        ),
      );
      expect(answer, isA<AgentQuestionAnswer>());
    });

    test('SystemAudioCapturePort contract is valid', () async {
      final port = _TestSystemAudioCapturePort();
      expect(await port.isSupported(), isTrue);
      expect(await port.requestPermission(), isTrue);
      final sources = await port.listSources();
      expect(sources, isA<List<SystemAudioSource>>());
    });
  });
}

// ---------------------------------------------------------------------------
// Minimal test implementations of each port interface
// ---------------------------------------------------------------------------

class _TestNotificationPort implements NotificationPort {
  @override
  void show(AppNotification notification) {}

  @override
  void dispose() {}
}

class _TestProcessControlPort implements ProcessControlPort {
  @override
  Future<void> kill(int pid) async {}

  @override
  bool isPidAlive(int pid) => false;
}

class _TestGitCommandPort implements GitCommandPort {
  @override
  Future<GitResult> run(
    List<String> args, {
    required String workdir,
    Map<String, String>? env,
    void Function(String line)? onProgress,
  }) async {
    return const GitResult(exitCode: 0, stdout: '', stderr: '');
  }

  @override
  Stream<String> runStreaming(
    List<String> args, {
    required String workdir,
    Map<String, String>? env,
  }) async* {
    yield 'done';
  }
}

class _TestEmbeddingPort implements EmbeddingPort {
  @override
  bool get isReady => true;

  @override
  int get dimension => 384;

  @override
  Future<Float32List> embed(String text) async => Float32List(384);
}

class _TestRunLogStorePort implements RunLogStorePort {
  final _logs = <String, String>{};

  @override
  Future<void> writeChunk(String runId, String chunk) async {
    _logs[runId] = (_logs[runId] ?? '') + chunk;
  }

  @override
  Future<String> readLog(String runId) async => _logs[runId] ?? '';

  @override
  Future<void> compact(String runId) async {}
}

class _TestProcessDetectionPort implements ProcessDetectionPort {
  @override
  Future<List<ActiveProcessInfo>> detect() async => [];

  @override
  Future<void> killProcess(int pid) async {}
}

class _TestGitRepoInspectorPort implements GitRepoInspectorPort {
  @override
  Future<GitRepoInfo> inspect(String path) async => GitRepoInfo(
        path: path,
        owner: 'acme',
        repoName: 'project',
        branch: 'main',
      );
}

class _TestConversationModeResolver implements ConversationModeResolver {
  @override
  Future<ConversationMode> resolveForConversation(
    String? conversationId,
  ) async =>
      ConversationMode.chat;
}

class _TestNotificationPreferencesPort
    implements NotificationPreferencesPort {
  @override
  Future<bool> isGlobalEnabled() async => true;

  @override
  Future<void> setGlobalEnabled({required bool enabled}) async {}

  @override
  Future<bool> isCategoryEnabled(NotificationCategory category) async => true;

  @override
  Future<void> setCategoryEnabled(
    NotificationCategory category, {
    required bool enabled,
  }) async {}

  @override
  Future<BatchDeliveryPolicy> getBatchDeliveryPolicy() async =>
      BatchDeliveryPolicy.realtime;

  @override
  Future<void> setBatchDeliveryPolicy(BatchDeliveryPolicy policy) async {}

  @override
  Future<QuietHoursConfig> getQuietHours() async => const QuietHoursConfig(
        enabled: false,
        start: TimeOfDay(hour: 22, minute: 0),
        end: TimeOfDay(hour: 7, minute: 0),
      );

  @override
  Future<void> setQuietHours(QuietHoursConfig config) async {}

  @override
  Future<NotificationSound> getNotificationSound() async =>
      NotificationSound.chime;

  @override
  Future<void> setNotificationSound(NotificationSound sound) async {}

  @override
  Future<double> getVolume() async => 1.0;

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<int> getCalendarAlertLeadMinutes() async => 5;

  @override
  Future<void> setCalendarAlertLeadMinutes(int minutes) async {}
}

class _TestEditorLauncherPort implements EditorLauncherPort {
  @override
  Future<List<IdeEditor>> detectEditors() async => [
        const IdeEditor(id: 'vscode', displayName: 'VS Code', installed: true),
      ];

  @override
  Future<void> openDirectory({
    required String editorId,
    required String directoryPath,
  }) async {}
}

class _TestPrWorktreePort implements PrWorktreePort {
  @override
  Future<String> ensureWorktree({
    required String workspaceId,
    required Repo repo,
    required int prNumber,
    required String prHeadRef,
  }) async =>
      '/tmp/worktree';

  @override
  Future<void> release({
    required String repoFullName,
    required int prNumber,
  }) async {}
}

class _TestRepoIsolationPort implements RepoIsolationPort {
  @override
  bool get isCowAvailable => true;

  @override
  Future<RepoIsolationResult> provision({
    required String sourcePath,
    required String destParentDir,
    required String name,
    required String branch,
    String baseRef = '',
    String? authUrl,
    String? headRef,
  }) async =>
      const RepoIsolationResult(
        path: '/tmp/isolated',
        backend: RepoIsolationBackend.rift,
      );

  @override
  Future<void> destroy({
    required String path,
    required String sourcePath,
    required RepoIsolationBackend backend,
    String? branch,
  }) async {}
}

class _TestRepoWorkspaceProvisionerPort
    implements RepoWorkspaceProvisionerPort {
  @override
  Future<String> ensureConversationWorkspace({
    required String workspaceId,
    required String channelId,
    required String fallbackDir,
    String? agentConfigDir,
    String? ticketId,
    String? ticketKey,
    String? ticketTitle,
    String branchType = 'feature',
  }) async =>
      '/tmp/conversation';

  @override
  Future<void> releaseConversation({
    required String workspaceId,
    required String channelId,
  }) async {}

  @override
  Future<void> releaseConversationAnyWorkspace({
    required String channelId,
  }) async {}

  @override
  Future<void> releaseTicket({required String ticketId}) async {}

  @override
  Future<int> releaseTicketInWorkspace({
    required String workspaceId,
    required String ticketId,
  }) async =>
      0;

  @override
  Future<int> sweepStale({required String workspaceId}) async => 0;
}

class _TestSandboxPort implements SandboxPort {
  @override
  SandboxBackend get backend => SandboxBackend.native;

  @override
  Future<SandboxBackendCapabilities> probe() async =>
      const SandboxBackendCapabilities(
        backend: SandboxBackend.native,
        available: true,
      );

  @override
  Future<SandboxHandle> launch(SandboxSpec spec) async =>
      SandboxHandle(sessionId: 'sandbox-1', backend: SandboxBackend.native);

  @override
  Future<bool> isAlive(SandboxHandle handle) async => true;

  @override
  Stream<SandboxEvent> events(SandboxHandle handle) =>
      const Stream<SandboxEvent>.empty();

  @override
  Future<int> exec(
    SandboxHandle handle,
    List<String> argv, {
    Map<String, String>? env,
    String? workdir,
    Duration? timeout,
    void Function(int pid)? onPid,
    String? stdinInput,
  }) async =>
      0;

  @override
  Future<void> pause(SandboxHandle handle) async {}

  @override
  Future<void> resume(SandboxHandle handle) async {}

  @override
  Future<void> destroy(SandboxHandle handle) async {}
}

class _TestCredentialBrokerPort implements CredentialBrokerPort {
  @override
  Future<ScopedCredentials> mint({
    required String conversationId,
    required AgentCapabilities capabilities,
    String? repoOwner,
    String? repoName,
  }) async =>
      const ScopedCredentials(handle: 'h', environment: {});

  @override
  Future<void> revoke(String handle) async {}
}

class _TestConfirmationPort implements ConfirmationPort {
  @override
  Future<bool> requestApproval(ConfirmationRequest request) async => true;
}

class _TestAgentQuestionPort implements AgentQuestionPort {
  @override
  Future<AgentQuestionAnswer?> ask(AgentQuestionRequest request) async =>
      const AgentQuestionAnswer(selectedLabels: ['Yes']);
}

class _TestSystemAudioCapturePort implements SystemAudioCapturePort {
  @override
  Future<bool> isSupported() async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<List<SystemAudioSource>> listSources() async => [];

  @override
  Stream<Uint8List> capture({String? sourceId}) =>
      const Stream<Uint8List>.empty();

  @override
  Future<void> stop() async {}
}

/// Helper: create a test Repo with the bare minimum fields.
Repo _testRepo() => Repo(
      id: 'repo-1',
      name: 'acme/project',
      path: '/tmp/acme/project',
      githubOwner: 'acme',
      githubRepoName: 'project',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

/// Helper: create minimal AgentCapabilities for testing.
AgentCapabilities _testCapabilities() => const AgentCapabilities(
      canPushToRepo: false,
      canCallTicketing: false,
    );
