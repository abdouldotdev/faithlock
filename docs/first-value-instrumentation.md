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
