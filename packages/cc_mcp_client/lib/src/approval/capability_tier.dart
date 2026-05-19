/// Re-exports the capability-tier value objects (PRD 01 phase 1.5).
///
/// The types themselves live in `cc_domain` because the `McpTool` port and the
/// `McpToolDispatcher` (in `cc_mcp`) both need them — the per-args approval tier
/// is a property of every tool, not just bridged external ones. This package
/// surfaces them through its barrel so client-side callers (the tool bridge,
/// the settings UI) import from one place.
library;

export 'package:cc_domain/features/mcp/domain/value_objects/capability_tier.dart';
