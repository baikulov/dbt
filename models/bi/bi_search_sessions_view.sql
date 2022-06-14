WITH
ses as (
  Select
    date,
    sessionId,
    source,
    medium,
    deviceCategory,
    region,
    city
  FROM {{ ref('presets_sessions') }}
  WHERE date >= toDate(NOW())-28
),
landing as (
  SELECT
    sessionId,
    pageUrl as landingPage
  FROM {{ ref('presets_hits') }}
  WHERE date >= toDate(NOW())-28
  AND hitType = 'pageview'
  AND hits_sequence = 1
),
pgvs as (
  SELECT
    sessionId,
    count(distinct hitId) as pageviews
  FROM {{ ref('presets_hits') }}
  WHERE date >= toDate(NOW())-28
  AND hitType = 'pageview'
  GROUP BY sessionId
),
adds as (
  SELECT
    sessionId,
    count(distinct sessionId) as addToCart_step
  FROM {{ ref('presets_hits') }}
  WHERE date >= toDate(NOW())-28
  AND eventAction like '%addToCart%'
  GROUP BY sessionId
),
checkout as (
  SELECT
    sessionId,
    count(distinct sessionId) as chekoutView_step
  FROM {{ ref('presets_hits') }}
  WHERE date >= toDate(NOW())-28
  AND pageUrl like '%checkout/contacts%'
  GROUP BY sessionId
),
purchase as (
  SELECT
    sessionId,
    count(distinct sessionId) as purchase_step
  FROM {{ ref('presets_hits') }}
  WHERE date >= toDate(NOW())-28
  AND pageUrl like '%/checkout/success%'
  GROUP BY sessionId
),
srch as (
  SELECT
    sessionId,
    count(distinct sessionId) as isSearch
  FROM {{ ref('presets_hits') }}
  WHERE date >= toDate(NOW())-28
  AND eventAction like '%search_%'
  GROUP BY sessionId
)
SELECT
  date,
  ses.sessionId,
  source,
  medium,
  landingPage,
  deviceCategory,
  region,
  city,
  IFNULL(pageviews, 0) as pageviews,
  IFNULL(addToCart_step, 0) as addToCart_step,
  IFNULL(chekoutView_step, 0) as chekoutView_step,
  IFNULL(purchase_step, 0) as purchase_step,
  IFNULL(isSearch, 0) as  isSearch
FROM ses
LEFT JOIN landing as l ON ses.sessionId = l.sessionId
LEFT JOIN pgvs ON ses.sessionId = pgvs.sessionId
LEFT JOIN adds as a ON ses.sessionId = a.sessionId
LEFT JOIN checkout as ch ON ses.sessionId = ch.sessionId
LEFT JOIN purchase as p ON ses.sessionId = p.sessionId
LEFT JOIN srch ON ses.sessionId = srch.sessionId