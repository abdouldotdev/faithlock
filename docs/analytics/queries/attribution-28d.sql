-- FaithLock attribution baseline — rolling 28 days (PostHog HogQL)
-- Source: PostHog product project (com.appbiz.faithlock).
-- Run each block separately. Replace the interval only to change the window;
-- never sum revenue across currencies.
-- See docs/analytics/attribution-baseline-28d.md for definitions and limits.

-- Q1. Funnel top: attributed installs (proxy only, never a payer).
SELECT
  count() AS install_events,
  uniq(distinct_id) AS persons
FROM events
WHERE event = 'install_attributed'
  AND timestamp > now() - INTERVAL 28 DAY;

-- Q2. Purchases by currency and attribution bucket, charged vs trial start.
WITH p AS (
  SELECT
    distinct_id,
    toString(properties.currency) AS cur,
    sumIf(toFloat(properties.revenue), toString(properties.is_trial_start) = 'true') AS trial_value,
    sumIf(toFloat(properties.revenue), toString(properties.is_trial_start) <> 'true') AS charged_value,
    countIf(toString(properties.is_trial_start) = 'true') AS trial_events,
    countIf(toString(properties.is_trial_start) <> 'true') AS charged_events
  FROM events
  WHERE event = 'paywall_purchase_completed'
    AND timestamp > now() - INTERVAL 28 DAY
  GROUP BY distinct_id, cur
),
a AS (
  SELECT
    distinct_id,
    argMin(
      coalesce(toString(properties.af_media_source), toString(properties.af_status)),
      timestamp
    ) AS media
  FROM events
  WHERE event = 'install_attributed'
  GROUP BY distinct_id
)
SELECT
  p.cur AS currency,
  coalesce(a.media, 'no_install_attributed') AS attribution_bucket,
  count() AS persons,
  sum(p.charged_events) AS charged_events,
  round(sum(p.charged_value), 2) AS charged_value,
  sum(p.trial_events) AS trial_events,
  round(sum(p.trial_value), 2) AS trial_value
FROM p
LEFT JOIN a ON p.distinct_id = a.distinct_id
GROUP BY currency, attribution_bucket
ORDER BY currency, persons DESC;

-- Q3. North Star inputs: strict attributable payers and all charged payers.
WITH p AS (
  SELECT distinct_id
  FROM events
  WHERE event = 'paywall_purchase_completed'
    AND timestamp > now() - INTERVAL 28 DAY
    AND toString(properties.is_trial_start) <> 'true'
  GROUP BY distinct_id
),
a AS (
  SELECT
    distinct_id,
    argMin(
      coalesce(toString(properties.af_media_source), toString(properties.af_status)),
      timestamp
    ) AS media
  FROM events
  WHERE event = 'install_attributed'
  GROUP BY distinct_id
)
SELECT
  coalesce(a.media, 'no_install_attributed') AS attribution_bucket,
  count() AS charged_payers
FROM p
LEFT JOIN a ON p.distinct_id = a.distinct_id
GROUP BY attribution_bucket
ORDER BY charged_payers DESC;

-- Q4. First-value instrumentation presence (expected 0 until an instrumented
-- build ships; 0 here is INSTRUMENTATION_MISSING, not a measured zero).
SELECT
  event,
  count() AS events,
  uniq(distinct_id) AS persons
FROM events
WHERE event IN ('first_focus_started', 'first_focus_completed', 'focus_completed')
GROUP BY event;
