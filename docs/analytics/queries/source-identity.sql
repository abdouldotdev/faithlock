-- FaithLock analytics — Q0 SOURCE IDENTITY PREFLIGHT
--
-- Run this block FIRST, before Q1..Q4 of attribution-28d.sql, in any tool that
-- reads PostHog. The shared PostHog connector is bound to exactly one project,
-- and more than one mobile app can live in the same PostHog organisation.
--
-- Decision rule (fail closed):
--   * every sentinel below returns events > 0  -> the project is FaithLock's
--     product project; Q1..Q4 may run and may be published.
--   * any sentinel returns 0                   -> STOP. The connector is bound
--     to another project. Numbers from Q1..Q4 would describe a different app.
--     Classify CONNECTOR_UNHEALTHY (mis-scoped source), not DATA_ABSENT.
--
-- Rationale: on 2026-11-10 the same connector returned a mobile-money app's
-- taxonomy (transfer_*, airtime_*, fastcash_*, auth_pin_*, revenue,
-- appsflyer_first_launch_attributed) and zero FaithLock events. An empty result
-- from that project is indistinguishable from a genuine zero unless identity is
-- asserted first.

SELECT 'prayer_session_completed' AS sentinel_event, count() AS events
FROM events
WHERE event = 'prayer_session_completed'
UNION ALL
SELECT 'install_attributed', count()
FROM events
WHERE event = 'install_attributed'
UNION ALL
SELECT 'paywall_purchase_completed', count()
FROM events
WHERE event = 'paywall_purchase_completed';

-- Negative control. If the block above returns any 0 row, run this to name the
-- project actually bound to the connector. Foreign fingerprints observed on
-- 2026-11-10: fastcash_*, transfer_*, airtime_*, auth_pin_*, appsflyer_first_launch_attributed.
SELECT event, count() AS events
FROM events
WHERE timestamp > now() - INTERVAL 30 DAY
GROUP BY event
ORDER BY events DESC
LIMIT 25;
