/// Platform seam for the on-device-model onboarding steps (voice + embedding).
///
/// These steps install on-device models (cc_natives FFI, uncompilable by
/// dart2js) — desktop-only. The onboarding screen imports `OnboardingVoiceStep`
/// + `OnboardingEmbeddingStep` through this seam: the real download/install
/// steps on the VM, honest "desktop-only" placeholders on web.
library;

export 'onboarding_model_steps_io.dart'
    if (dart.library.js_interop) 'onboarding_model_steps_web.dart';
