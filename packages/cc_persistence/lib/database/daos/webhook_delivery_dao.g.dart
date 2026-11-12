// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'webhook_delivery_dao.dart';

// ignore_for_file: type=lint
mixin _$WebhookDeliveryDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $PipelineTemplatesTableTable get pipelineTemplatesTable =>
      attachedDatabase.pipelineTemplatesTable;
  $PipelineTriggersTableTable get pipelineTriggersTable =>
      attachedDatabase.pipelineTriggersTable;
  $PipelineRunsTableTable get pipelineRunsTable =>
      attachedDatabase.pipelineRunsTable;
  $WebhookDeliveriesTableTable get webhookDeliveriesTable =>
      attachedDatabase.webhookDeliveriesTable;
  WebhookDeliveryDaoManager get managers => WebhookDeliveryDaoManager(this);
}

class WebhookDeliveryDaoManager {
  final _$WebhookDeliveryDaoMixin _db;
  WebhookDeliveryDaoManager(this._db);
  $$PipelineTemplatesTableTableTableManager get pipelineTemplatesTable =>
      $$PipelineTemplatesTableTableTableManager(
        _db.attachedDatabase,
        _db.pipelineTemplatesTable,
      );
  $$PipelineTriggersTableTableTableManager get pipelineTriggersTable =>
      $$PipelineTriggersTableTableTableManager(
        _db.attachedDatabase,
        _db.pipelineTriggersTable,
      );
  $$PipelineRunsTableTableTableManager get pipelineRunsTable =>
      $$PipelineRunsTableTableTableManager(
        _db.attachedDatabase,
        _db.pipelineRunsTable,
      );
  $$WebhookDeliveriesTableTableTableManager get webhookDeliveriesTable =>
      $$WebhookDeliveriesTableTableTableManager(
        _db.attachedDatabase,
        _db.webhookDeliveriesTable,
      );
}
