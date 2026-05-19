import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_tab_kinds.dart';
import 'package:control_center/shared/editor/host/editor_layout_codec.dart';

/// The PR workbench's [EditorLayoutCodec] configuration.
///
/// Restorable kinds cover every PR tab; the legacy `pr.aiReview` /
/// `pr.reviewStudio` kinds alias onto the merged `pr.review` on decode so an
/// old persisted layout restores onto the unified tab. A restored `pr.file`
/// needs its `path` and a restored `pr.rig` its `surface`; terminal, browser
/// and code-server come back blank (their live state is never persisted). A
/// restored rig tab shows its start affordance rather than booting a VM —
/// three tabs auto-starting on every app launch would be an expensive
/// surprise.
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
    PrTabKinds.rig,
    // NB: `PrTabKinds.preview` is deliberately NOT restorable — preview tabs
    // are wholly derived from live detection and re-injected after Diff on
    // each load, so persisting one would only risk a blank/duplicate tab.
  },
  requiredStringArgs: {
    PrTabKinds.file: ['path'],
    // A rig tab with no surface has no machine to show; dropping it beats
    // restoring a tab that renders an empty desktop by default.
    PrTabKinds.rig: ['surface'],
  },
  aliasKind: _aliasLegacyReview,
  // An ENCLOSED terminal boots a VM on first attach, so a restored one gets the
  // same treatment as a restored rig tab: the badge comes back, the machine
  // does not. Otherwise reopening a PR page with a persisted `microvm` terminal
  // booted a VM before the user touched anything.
  rewriteArgsOnDecode: _deferEnclosedTerminalStart,
  transientArgs: {EditorLayoutCodec.deferStartArg},
  iconFor: PrTabKinds.iconFor,
);

/// Stamps a restored `microvm` terminal tab as "start on demand".
Map<String, Object?> _deferEnclosedTerminalStart(
  String kind,
  Map<String, Object?> args,
) => (kind == PrTabKinds.terminal && args['backend'] == 'microvm')
    ? {...args, EditorLayoutCodec.deferStartArg: true}
    : args;

String _aliasLegacyReview(String kind) =>
    (kind == PrTabKinds.aiReview || kind == PrTabKinds.reviewStudio)
    ? PrTabKinds.review
    : kind;
