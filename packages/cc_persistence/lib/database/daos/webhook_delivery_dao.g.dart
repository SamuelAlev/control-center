// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'webhook_delivery_dao.dart';

// ignore_for_file: type=lint
mixin _$WebhookDeliveryDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $WebhookDeliveriesTableTable get webhookDeliveriesTable =>
      attachedDatabase.webhookDeliveriesTable;
  WebhookDeliveryDaoManager get managers => WebhookDeliveryDaoManager(this);
}

class WebhookDeliveryDaoManager {
  final _$WebhookDeliveryDaoMixin _db;
  WebhookDeliveryDaoManager(this._db);
  $$WebhookDeliveriesTableTableTableManager get webhookDeliveriesTable =>
      $$WebhookDeliveriesTableTableTableManager(
        _db.attachedDatabase,
        _db.webhookDeliveriesTable,
      );
}
