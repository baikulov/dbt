WITH
-- справочник по типам страниц
src_dict_page_type as (
  Select
    pagePath,
    pageType
  FROM {{ ref('dict_pagetype') }}
),
-- данные по хитам
src_hits as (
  Select
    date,
    sessionId,
    pagePath,
    eventCategory,
    eventAction,
    eventLabel,
    count(distinct hitId) as events,
    count(distinct sessionId) as uniqueEvents
  FROM {{ ref('presets_hits') }}
  WHERE hitType = 'event'
  GROUP BY
    date,
    sessionId,
    pagePath,
    eventCategory,
    eventAction,
    eventLabel
),
-- данные по каналу трафика
src_medium as (
  Select
    sessionId,
    medium
  FROM {{ ref('presets_sessions') }}
),
-- объединяем данные
jn as (
    SELECT
        date,
        src_hits.sessionId as sessionId,
        eventCategory,
        eventAction,
        eventLabel,
        src_hits.pagePath,
        events,
        uniqueEvents,
        pageType,
        medium
    FROM src_hits
    LEFT JOIN src_medium
    ON src_hits.sessionId = src_medium.sessionId
    LEFT JOIN src_dict_page_type
    ON src_hits.pagePath = src_dict_page_type.pagePath
),
-- финальная таблица
final as (
    SELECT
        date,
        sessionId,
        eventCategory,
        eventAction,
        eventLabel,
        SUM(events) as events,
        SUM(uniqueEvents) as uniqueEvents,
        pageType,
        medium
    FROM jn
    GROUP BY
         date,
        sessionId,
        eventCategory,
        eventAction,
        eventLabel,
        pageType,
        medium
)
-- результат
Select *
FROM final