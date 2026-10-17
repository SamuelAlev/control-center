import 'package:cc_domain/cc_domain.dart';
import 'package:cc_host/cc_host.dart' show RepoOp;
import 'package:cc_server_core/src/push/web_push_service.dart';

/// Device-global (CROSS-WORKSPACE BY DESIGN): the authenticated session's own
/// device owns one subscription spanning only its *current* workspace grants.
/// No client-provided user_id or device_id is accepted as an authority.
List<RepoOp> buildWebPushOps(WebPushService push) => [
  RepoOp(
    name: 'push.status',
    kind: RepoOpKind.read,
    workspaceScoped: false,
    handler: (ctx) => push.status(ctx.userId, ctx.deviceId),
  ),
  RepoOp(
    name: 'push.register',
    kind: RepoOpKind.mutate,
    workspaceScoped: false,
    requiredArgs: const ['endpoint', 'p256dh', 'auth', 'categories', 'quiet'],
    handler: (ctx) async {
      final args = ctx.args;
      final endpoint = args['endpoint'];
      final p256dh = args['p256dh'];
      final auth = args['auth'];
      final categories = args['categories'];
      final quiet = args['quiet'];
      if (endpoint is! String ||
          p256dh is! String ||
          auth is! String ||
          categories is! List ||
          categories.any((e) => e is! String) ||
          quiet is! bool) {
        throw const ValidationException('Invalid WebPush subscription');
      }
      try {
        return await push.register(
          userId: ctx.userId,
          deviceId: ctx.deviceId,
          endpoint: endpoint,
          p256dh: p256dh,
          auth: auth,
          categories: categories.cast<String>().toSet(),
          quiet: quiet,
        );
      } on FormatException {
        throw const ValidationException('Invalid WebPush subscription');
      }
    },
  ),
  RepoOp(
    name: 'push.remove',
    kind: RepoOpKind.mutate,
    workspaceScoped: false,
    handler: (ctx) async {
      await push.remove(ctx.userId, ctx.deviceId);
      return {'ok': true};
    },
  ),
];
