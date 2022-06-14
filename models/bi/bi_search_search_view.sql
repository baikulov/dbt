{{
    config(
        tags=['hits', 'presets'],
        engine='MergeTree()'
    )
}}

WITH
t1 as (
  SELECT
    date,
    sessionId,
    eventCategory,
    eventAction,
    eventLabel,
    count(hitId) as unique_events
  FROM {{ ref('presets_hits') }} 
  WHERE hitType = 'event'
  GROUP BY
    date,
    sessionId,
    eventCategory,
    eventAction,
    eventLabel
)
SELECT *
FROM t1