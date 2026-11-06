import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_status.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_step.dart';
import 'package:cc_persistence/cc_persistence.dart'
    show WorkspaceDatabaseManager;

/// Records a space's provisioning status on its row.
Future<void> Function(String, String, SpaceProvisioningStatus)
spaceProvisioningStatusWriter(WorkspaceDatabaseManager databases) =>
    (workspaceId, spaceId, status) => databases
        .of(workspaceId)
        .messagingDao
        .updateSpaceProvisioningStatus(spaceId, status.toDbValue());

/// Records granular progress ("cloning repo X", "setting up agent Y") on the
/// space's row, so it rides the same live space stream clients already watch
/// for the status. The status write clears it on ready/failed.
Future<void> Function(String, String, SpaceProvisioningStep)
spaceProvisioningStepWriter(WorkspaceDatabaseManager databases) =>
    (workspaceId, spaceId, step) => databases
        .of(workspaceId)
        .messagingDao
        .updateSpaceProvisioningStep(spaceId, step.toDbValue());
