import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/features/environments/domain/entities/environment_definition_record.dart';
import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_host_approval.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/environments/presentation/environment_setup_prompt.dart';
import 'package:control_center/features/environments/presentation/settings/environment_editor_seed.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether [error] is the refusal to run, on the server itself, a definition
/// the current server owner has not approved (`data.kind`
/// `environment.host_unapproved` with the unauthorized code). Read by kind,
/// never by message.
bool isEnvironmentHostUnapproved(Object error) =>
    error is RemoteRpcException &&
    error.code == RpcErrorCodes.unauthorized &&
    error.data is Map &&
    (error.data as Map)['kind'] == environmentHostUnapprovedKind;

/// The words for an unapproved definition that refused to run: the owner is
/// told it waits on them, anyone else that it waits on the owner.
String environmentHostUnapprovedMessage(
  AppLocalizations l10n, {
  required bool owner,
}) => owner
    ? l10n.environmentHostUnapprovedOwner
    : l10n.environmentHostUnapproved;

/// Approves [record]'s host work by saving it unchanged as the server owner:
/// the definition, or for a file-linked one its overrides pinned to the blob
/// already approved, so approving never also approves a newer file.
///
/// Returns null on success, else what to say.
Future<String?> approveEnvironmentHost(
  WidgetRef ref,
  AppLocalizations l10n,
  EnvironmentDefinitionRecord record,
) async {
  final overridesJson = record.overridesJson;
  final overrides = overridesJson == null
      ? null
      : Map<String, dynamic>.from(jsonDecode(overridesJson) as Map);
  final definition = Map<String, dynamic>.from(
    jsonDecode(record.definitionJson) as Map,
  );
  // A redacted copy saved back would overwrite the real values with
  // placeholders; only an admin's full copy may be saved.
  if (environmentHoldsRedaction(definition) ||
      environmentHoldsRedaction(overrides)) {
    return l10n.environmentHostApproveNeedsAdmin;
  }
  final repository = ref.read(environmentRepositoryProvider);
  try {
    if (record.hasSource) {
      await repository.approveSource(
        record.workspaceId,
        definitionId: record.id,
        repoId: record.sourceRepoId!,
        path: record.sourcePath!,
        overrides: overrides,
        blobHash: record.approvedBlobHash,
      );
    } else {
      await repository.setDefinition(
        record.workspaceId,
        definition,
        definitionId: record.id,
      );
    }
    ref.invalidate(environmentDefinitionsProvider(record.workspaceId));
    return null;
  } on RemoteRpcException catch (error) {
    return error.message;
  } on Object catch (error) {
    return '$error';
  }
}

/// [record] as the server lists it now, so an approval made since it was
/// opened clears its notice; [record] itself until the list loads.
EnvironmentDefinitionRecord? watchStoredEnvironmentRecord(
  WidgetRef ref,
  EnvironmentDefinitionRecord? record,
) => record == null
    ? null
    : ref.watch(
            environmentDefinitionRecordProvider((
              workspaceId: record.workspaceId,
              definitionId: record.id,
            )),
          ) ??
          record;

/// The quiet line under a definition that runs on the server itself but has
/// no approval from the current server owner. The owner gets **Approve**,
/// which saves it unchanged; anyone else is told the owner has to. Nothing
/// for a definition that needs none.
class EnvironmentHostApprovalNotice extends ConsumerStatefulWidget {
  /// Creates the notice for [record].
  const EnvironmentHostApprovalNotice({
    super.key,
    required this.record,
    this.padding = const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 10),
  });

  /// The definition.
  final EnvironmentDefinitionRecord record;

  /// Space around the notice.
  final EdgeInsetsDirectional padding;

  @override
  ConsumerState<EnvironmentHostApprovalNotice> createState() =>
      _EnvironmentHostApprovalNoticeState();
}

class _EnvironmentHostApprovalNoticeState
    extends ConsumerState<EnvironmentHostApprovalNotice> {
  bool _busy = false;
  String? _failure;

  Future<void> _approve() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _failure = null;
    });
    final failure = await approveEnvironmentHost(ref, l10n, widget.record);
    if (mounted) {
      setState(() {
        _busy = false;
        _failure = failure;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.record.awaitsHostApproval) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final owner = ref.watch(canUseHostProvider);
    final failure = _failure;
    const caption = CcTypography.caption;
    return Padding(
      padding: widget.padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 1),
            child: Icon(AppIcons.info, size: 14, color: t.fgWarningPrimary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  owner
                      ? l10n.environmentHostApprovalOwner
                      : l10n.environmentHostApprovalMember,
                  style: caption.copyWith(color: t.textSecondary),
                ),
                if (failure != null)
                  Text(
                    failure,
                    style: caption.copyWith(color: t.textErrorPrimary),
                  ),
              ],
            ),
          ),
          if (owner) ...[
            const SizedBox(width: AppSpacing.sm),
            CcButton(
              size: CcButtonSize.sm,
              variant: CcButtonVariant.secondary,
              loading: _busy,
              onPressed: _busy ? null : () => unawaited(_approve()),
              child: Text(l10n.environmentHostApprove),
            ),
          ],
        ],
      ),
    );
  }
}

/// An environment held because its definition waits on the server owner's
/// approval (`lastError.code` `environment.host_unapproved`), in the app's
/// words. The owner gets the way to the definition, where they approve it.
class EnvironmentHostUnapprovedAlert extends ConsumerWidget {
  /// Creates the alert for [environment] in [spaceKey].
  const EnvironmentHostUnapprovedAlert({
    super.key,
    required this.spaceKey,
    required this.environment,
  });

  /// The space it runs in.
  final EnvironmentSpaceKey spaceKey;

  /// The held environment.
  final SpaceEnvironment environment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final owner = ref.watch(canUseHostProvider);
    final record = ref.watch(
      environmentDefinitionRecordProvider((
        workspaceId: spaceKey.workspaceId,
        definitionId: environment.definitionId,
      )),
    );
    return CcAlert(
      variant: CcAlertVariant.warning,
      title: environmentHostUnapprovedMessage(l10n, owner: owner),
      action: owner && record != null
          ? Align(
              alignment: AlignmentDirectional.centerStart,
              child: CcButton(
                size: CcButtonSize.sm,
                variant: CcButtonVariant.secondary,
                onPressed: () => openEnvironmentEditor(
                  context,
                  ref,
                  EnvironmentEditorSeed.record(record),
                ),
                child: Text(l10n.environmentHostApprovalReview),
              ),
            )
          : null,
    );
  }
}
