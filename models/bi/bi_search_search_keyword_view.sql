WITH
-- справочник по типам страниц
src_dict_page_type as (
  Select
    pagePath,
    pageType
  FROM {{ ref('dict_pagetype') }}
),
-- исходные данные по событиям поиска
src_search_hits as (
  Select
    date,
    sessionId,
    pagePath,
    eventCategory,
    eventAction,
    eventLabel as query,
    attributed_event + 1 as attributed_event
  FROM {{ ref('presets_hits') }}
  WHERE match(eventAction, 'search_.*')
),
-- исходные данные по просмотренным страницам
src_next_page as (
  Select
    sessionId as sesid,
    pagePath as after_search_pagePath,
    pageview_sequence
  FROM {{ ref('presets_hits') }}
  WHERE hitType = 'pageview'
),
-- объединяем поисковые хиты с просмотренными страницами
jn_hits as (
  Select *
  FROM src_search_hits
  LEFT JOIN src_next_page
  on sessionId = sesid
  AND attributed_event = pageview_sequence
),
-- находим тип страницы для текущей страницы
jn_page_type as (
  SELECT
    date,
    sessionId,
    query,
    jn_hits.pagePath as pagePath,
    pageType,
    eventCategory,
    eventAction,
    after_search_pagePath
  FROM jn_hits
  LEFT JOIN src_dict_page_type
  ON jn_hits.pagePath = src_dict_page_type.pagePath
),
-- находим тип страницы для следующей после поиска
jn_after_page_type as (
  SELECT
    date,
    sessionId,
    query,
    pagePath,
    pageType,
    eventCategory,
    eventAction,
    after_search_pagePath,
    src_dict_page_type.pageType as after_search_pageType
  FROM jn_page_type
  LEFT JOIN src_dict_page_type
  ON src_dict_page_type.pagePath = after_search_pagePath 
),
-- находим значение для isSearchPage поля
final as (
  SELECT
    date,
    sessionId,
    query,
    pagePath,
    pageType,
    eventCategory,
    eventAction,
    after_search_pagePath,
    after_search_pageType,
    IF(after_search_pageType = 'SearchResults', 1, 0) as isSearchPage
  FROM jn_after_page_type
)
-- выводим на печать
SELECT *
FROM final