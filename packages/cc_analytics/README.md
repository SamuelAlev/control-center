# cc_analytics

Analytics **provider adapters**: the `AnalyticsSink` implementations behind
`cc_domain`'s `Analytics` facade (`packages/cc_domain/lib/features/telemetry`).
Pure Dart and web-safe (`cc_domain` + `package:http`), so the desktop/web
client, the phone PWA and the server all use the same code.

## Layers

| Piece | Lives in | Job |
| --- | --- | --- |
| `AnalyticsEvents` | `cc_domain` | The tracking plan. Every event name and property is built here |
| `Analytics` | `cc_domain` | Consent gate on the server's `TelemetryConfig`, build-mode gate, PII policy, pseudonymization, pre-consent buffer |
| `AnalyticsSink` | `cc_domain` | The provider port |
| `UmamiAnalyticsSink` | here | Umami `/api/send` delivery: serial in-memory queue, backoff, 4xx drop |
| `AnalyticsDestination` | here | The one place that picks the provider and its host/website |

## Switching providers

Write a new `AnalyticsSink` here (e.g. `PostHogAnalyticsSink`) that maps an
`AnalyticsEnvelope` to the provider's wire format, then return it from
`AnalyticsDestination.createSink`. Call sites, the tracking plan, consent and
privacy rules do not change. A fan-out sink that wraps two providers works the
same way, for a migration period.

A sink must not add identifying fields of its own (IP, hostname, file paths,
user names); envelopes are already sanitized and pseudonymized.

## Configuration

The Umami instance and website default to Control Center's and can be
overridden at build time:

```bash
--dart-define=CC_ANALYTICS_HOST=https://analytics.example.com/
--dart-define=CC_ANALYTICS_WEBSITE_ID=<uuid>
```

Collection is decided at runtime by the server's opt-in **Share usage
analytics** switch (`telemetry.usage_analytics` in server settings). Debug and
profile builds log events through `LoggingAnalyticsSink` instead of sending,
unless the server runs with `CC_ANALYTICS_DEBUG=1` (environment or `.env`),
which lets debug builds of the server and its clients send for testing.
See the manual's telemetry reference for the event catalog.
