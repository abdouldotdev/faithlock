# First-value analytics contract (ABD-63)

Scope: FaithLock mobile app, PostHog product project. This contract measures first focus value and provides a deterministic sequence for a second completion within seven days.

Events

- `first_focus_started`: emitted once when the first prayer focus flow is opened. Properties: `schema_version` (integer `1`), `focus_kind` (`prayer`).
- `first_focus_completed`: emitted once when the first focus completes successfully. Properties: `schema_version` (integer `1`), `focus_kind` (`prayer`), `completion_number` (integer `1`).
- `focus_completed`: emitted for completions after the first. Properties: `schema_version` (integer `1`), `focus_kind` (`prayer`), `completion_number` (integer sequence starting at `2`), `first_completion_at` (UTC ISO-8601 timestamp copied from the first completion).

A second completion within seven days is computed in PostHog by selecting `focus_completed` with `completion_number = 2`, whose event timestamp is within seven days after the `first_focus_completed` event for the same distinct user. The timestamp is operational metadata only; no prayer text, verse reference, spiritual content, mood, score, or other sensitive content is sent by this contract.

Idempotency

- First-start and first-completion milestones are persisted in app-local SharedPreferences and emitted at most once per storage scope.
- The controller also guards a completion callback from being executed twice during one controller lifetime.
- Later `focus_completed` events are sequence-numbered so repeated app launches do not create another first milestone.

Existing `prayer_session_started` and `prayer_session_completed` remain separate legacy events and are not treated as a reliable first-value mapping.

Release build prerequisites

The analytics key is a build-time input, not a runtime setting:

- `lib/config/env.dart` reads `.env` through `envied` and declares `part 'env.g.dart'`. Both `.env` and `lib/config/env.g.dart` are git-ignored, so a fresh checkout must generate the constants before it can compile.
- `PostHogService.init` disables analytics when the API key is empty. A build with a missing or empty `POSTHOG_API_KEY` therefore compiles and runs while emitting no events at all, which would make a measurement test look like "no events received" instead of a broken build input.
- Use `./scripts/build_testflight.sh`. It runs a preflight first (Flutter SDK present, `.env` present, `POSTHOG_API_KEY` / `REVENUECAT_API_KEY` / `OPENAI_API_KEY` non-empty), then always runs code generation and fails if `lib/config/env.g.dart` is not produced. It prints the version/build number to record with any measurement test.
- `./scripts/build_testflight.sh --preflight-only` validates the build inputs without building.
