/// Re-export shim: the browser-rig defaults moved into the domain
/// (`cc_domain/features/rigs/domain/value_objects/browser_defaults.dart`) so
/// the `browser_use` MCP tool — which must not depend on `cc_infra` — applies
/// the same default egress the `rig.open` RPC op does. Existing imports of
/// this path keep working.
library;

export 'package:cc_domain/features/rigs/domain/value_objects/browser_defaults.dart';
