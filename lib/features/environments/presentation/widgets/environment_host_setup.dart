import 'package:cc_data/cc_data.dart' show RpcEnvironmentRepository;
import 'package:cc_domain/features/environments/domain/entities/environment_definition_record.dart';
import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_feedback.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_host.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether [record] can finish a stopped start on a terminal.
bool environmentCanSetUp(EnvironmentDefinitionRecord? record) {
  final definition = record == null ? null : environmentDefinitionOf(record);
  return definition?.hasSetupVerb ?? false;
}

/// Opens the terminal tab a stopped start finishes in.
///
/// The server runs the definition's `setup` verb there. The tool asks for its
/// password or whatever else it needs, and the start carries on by itself. A
/// surface with no editor has nowhere to show it and offers nothing.
Future<void> openHostSetup(
  BuildContext context,
  WidgetRef ref,
  EnvironmentSpaceKey key,
) => HostSetupFollowUp.of(context, ref).open(key);

/// What finishing a Start on a terminal needs, taken while the widget that was
/// pressed is still there.
///
/// It won't be there afterwards: the row a start creates replaces the Start
/// button long before `ensure` returns, so nothing here may go back to that
/// widget's context or ref.
class HostSetupFollowUp {
  /// Takes what it needs from the widget being pressed.
  HostSetupFollowUp.of(BuildContext context, WidgetRef ref)
    : _host = EnvironmentHostScope.maybeOf(context),
      _toasts = CcToastScope.maybeOf(context),
      _label = AppLocalizations.of(context).environmentSetupTab,
      _repository = ref.read(environmentRepositoryProvider);

  final EnvironmentHost? _host;
  final CcToastHandle? _toasts;
  final String _label;
  final RpcEnvironmentRepository _repository;

  /// Follows a Start someone just pressed: when it stopped for host setup and
  /// the definition can finish it on a terminal, goes straight there.
  ///
  /// Only a person's own press gets here. A start an agent made or a row that
  /// was already waiting never opens anything by itself.
  Future<void> after(
    EnvironmentSpaceKey key,
    SpaceEnvironment environment,
  ) async {
    if (!(environment.lastError?.needsHostSetup ?? false)) {
      return;
    }
    final List<EnvironmentDefinitionRecord> records;
    try {
      records = await _repository.listDefinitions(key.workspaceId);
    } on Object {
      return;
    }
    final record = records
        .where((item) => item.id == environment.definitionId)
        .firstOrNull;
    if (environmentCanSetUp(record)) {
      await open(key);
    }
  }

  /// Runs the `setup` verb and opens its terminal.
  ///
  /// Someone who has moved to another space gets neither: a tab would land in
  /// the wrong space, and nobody would be there to answer the prompt. The row
  /// keeps the way back for when they return.
  Future<void> open(EnvironmentSpaceKey key) async {
    final host = _host;
    if (host == null || !host.showsSpace(key.spaceId)) {
      return;
    }
    try {
      final sessionId = await _repository.startSetup(
        key.workspaceId,
        key.spaceId,
      );
      if (host.showsSpace(key.spaceId)) {
        host.openSetup(
          spaceId: key.spaceId,
          sessionId: sessionId,
          label: _label,
        );
      }
    } on Object catch (error) {
      _toasts?.show(
        environmentFailureMessage(error),
        variant: CcToastVariant.danger,
      );
    }
  }
}
