/// The advisor/watchdog secondary reviewer (PRD 01 feature 9).
///
/// A second, cheap LLM watches the primary agent's transcript (delta-rendered,
/// secret-obfuscated) and surfaces `nit | concern | blocker` advice; concern/
/// blocker interrupt via the steering channel. `WATCHDOG.md` files declare what
/// to scrutinise per project. The runtime, obfuscator, and discovery are pure-
/// Dart and unit-testable; only the `AdvisorModel` is host-wired.
library;

export 'advisor_models.dart';
export 'advisor_runtime.dart';
export 'secret_obfuscator.dart';
export 'watchdog_discovery.dart';
