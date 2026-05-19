/// Model catalog & smart routing (PRD 05).
///
/// A pure-Dart model-management module: a unified provider/model catalog
/// (assembled from models.dev), provider-governance policy, credential ranking
/// and auth retry, rate-limit classification, context promotion, cross-provider
/// handoff, a small-model router, usage/quota tracking, and a thinking-loop
/// guard. No `dart:io` / `drift` / `dio` / Flutter — every piece is unit
/// testable in isolation.
library;

export 'package:cc_harness/provider.dart' show ReasoningEffort;

export 'domain/entities/credential_account.dart';
export 'domain/entities/model_info.dart';
export 'domain/entities/model_provider.dart';
export 'domain/entities/provider_policy.dart';
export 'domain/entities/rate_limit.dart';
export 'domain/entities/usage.dart';
export 'domain/ports/models_dev_source.dart';
export 'domain/repositories/provider_policy_repository.dart';
export 'domain/services/auth_retry.dart';
export 'domain/services/context_promotion.dart';
export 'domain/services/credential_ranking.dart';
export 'domain/services/message_handoff.dart';
export 'domain/services/model_catalog.dart';
export 'domain/services/model_fuzzy_search.dart';
export 'domain/services/models_dev_parser.dart';
export 'domain/services/provider_enablement.dart';
export 'domain/services/provider_policy_engine.dart';
export 'domain/services/rate_limit_classifier.dart';
export 'domain/services/small_model_router.dart';
export 'domain/services/thinking_loop_detector.dart';
export 'domain/services/usage_tracker.dart';
export 'domain/services/wildcard.dart';
