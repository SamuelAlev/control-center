import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_tab_kinds.dart';
import 'package:control_center/shared/editor/host/editor_layout_codec.dart';

/// The PR workbench's [EditorLayoutCodec] configuration.
///
/// Restorable kinds cover every PR tab; the legacy `pr.aiReview` /
/// `pr.reviewStudio` kinds alias onto the merged `pr.review` on decode so an
/// old persisted layout restores onto the unified tab. A restored `pr.file`
/// needs its `path`; terminal/browser/code-server come back blank (their live
/// state is never persisted).
const EditorLayoutCodec prLayoutCodec = EditorLayoutCodec(
  restorableKinds: {
    PrTabKinds.overview,
    PrTabKinds.diff,
    PrTabKinds.sourceControl,
    PrTabKinds.actions,
    PrTabKinds.review,
    PrTabKinds.chat,
    PrTabKinds.terminal,
    PrTabKinds.file,
    PrTabKinds.codeServer,
    PrTabKinds.browser,
    // NB: `PrTabKinds.preview` is deliberately NOT restorable — preview tabs
    // are wholly derived from live detection and re-injected after Diff on
    // each load, so persisting one would only risk a blank/duplicate tab.
  },
  requiredStringArgs: {
    PrTabKinds.file: ['path'],
  },
  aliasKind: _aliasLegacyReview,
  iconFor: PrTabKinds.iconFor,
);

String _aliasLegacyReview(String kind) =>
    (kind == PrTabKinds.aiReview || kind == PrTabKinds.reviewStudio)
    ? PrTabKinds.review
    : kind;
