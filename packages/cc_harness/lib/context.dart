/// Context management: token estimation, compaction, tool-output truncation
/// and elision and harness token accounting.
library;

export 'src/context/compaction_config.dart';
export 'src/context/compaction_economics.dart';
export 'src/context/compaction_prompt.dart';
export 'src/context/harness_compaction.dart';
export 'src/context/harness_evidence.dart';
export 'src/context/harness_token_accounting.dart';
export 'src/context/provider_image_budget.dart';
export 'src/context/side_request.dart';
export 'src/context/token_calibration.dart';
export 'src/context/token_estimator.dart';
export 'src/context/tool_observation.dart';
export 'src/context/tool_output_reference.dart';
export 'src/context/tool_output_store.dart';
export 'src/context/tool_output_truncation.dart';
export 'src/context/tool_result_elision.dart';
